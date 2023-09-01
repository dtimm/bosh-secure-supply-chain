#!/usr/bin/env bash
set -eu

echo "${COSIGN_KEY:?COSIGN_KEY must be set}"
echo "${COSIGN_PASSWORD:?COSIGN_PASSWORD must be set}"

gomods=()
pushd bosh-release
for package in $(ls packages); do
  spec_file="packages/${package}/spec"

  # Check if spec file exists
  if [[ ! -f "${spec_file}" ]]; then
    echo "spec file not found for ${package}."
  else
    for glob in $(bosh interpolate ${spec_file} --path /files); do
      for f in $(find . -type f -path "./src/${glob}"); do
        case `basename ${f}` in
        go.mod)
          echo "go.mod found: ${f}"
          gomods+=("${f}")
          ;;
        *)
          ;;
        esac
      done
    done
  fi
done
popd

uniq_files () {
  local files=("$@")
  local uniq_files=($(for g in "${files[@]}"; do echo "${g}"; done | sort -u))
  echo ${uniq_files}
}

for gomod in $(uniq_files "${gomods[@]}"); do
  echo "Verifying packages properly vendored for ${gomod}..."
  pushd $(dirname bosh-release/${gomod})
    go mod tidy
    go mod vendor
    if [[ `git status --porcelain` ]]; then
      echo "go.mod and/or go.sum do not match vendor/ directory"
      exit 1
    fi

    gomod_deps=$(go mod download -json | jq '{uri: (.Path + "@" + .Version), digest: {gosum: .Sum}}' | jq -s .)
  popd

  echo "Generating SBoM for ${gomod}..."
  package_sbom="$(syft packages "file:bosh-release/${gomod}" --output "cyclonedx-json")"

  jsonString=$(echo "${package_sbom}" | jq --join-output --compact-output .)

  echo "Generating attested SBoM for ${gomod}..."
  removed_slashes=${gomod//\//-}
  output_sbom="./attestations/${removed_slashes#.-src-}.cdx.intoto.json"
  cosign attest-blob --type "cyclonedx" --predicate <(echo ${jsonString}) --key <(echo -e ${COSIGN_KEY}) --yes --tlog-upload=false bosh-release/${gomod} --output-signature "${output_sbom}"

  echo "Generating attested provenance for ${output_sbom}..."
  build_metadata=()
  for f in $(ls build-metadata); do
    build_metadata+=(echo "${f}: $(cat build-metadata/${f})")
  done
  cat >predicate.json <<EOL
{
  "buildDefinition": {
    "buildType": "https://github.com/dtimm/bosh-secure-supply-chain/concourse/gomod_vendor_sbom@main",
    "externalParameters": {
      "inputs": {},
      "vars": {}
    },
    "internalParameters": {
      "concourse_stuff": ${build_metadata}
    },
    "resolvedDependencies": ${gomod_deps}
  },
  "runDetails": {
    "builder": {
      "id": "https://github.com/dtimm/bosh-secure-supply-chain/concourse/gomod_vendor_sbom/task.yml@refs/heads/main"
    },
    "metadata": {
      "invocationId": "link to concourse run???"
    }
  }
}
EOL

  output_provenance="./attestations/${removed_slashes#.-src-}.intoto.json"
  cosign attest-blob --type "https://slsa.dev/provenance/v1" --predicate predicate.json --key <(echo -e ${COSIGN_KEY}) --yes --tlog-upload=false ${output_sbom} --output-signature "${output_provenance}"
done
