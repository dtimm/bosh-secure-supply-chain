#!/usr/bin/env bash
set -eu

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
  popd

  echo "Generating SBoM for ${gomod}..."
  package_sbom="$(syft packages "file:bosh-release/${gomod}" --output "cyclonedx-json")"

  jsonString=$(echo "${package_sbom}" | jq --join-output --compact-output .)

  echo "Generating attested SBoM for ${gomod}..."
  output_file=${gomod//\//-}
  cosign attest-blob --type "cyclonedx" --predicate <(echo ${jsonString}) --key "signing-key/${SIGNING_KEY}" --yes --tlog-upload=false bosh-release/${gomod} --output-signature "./attestations/${output_file#.-src-}.cdx.intoto.json"
done
