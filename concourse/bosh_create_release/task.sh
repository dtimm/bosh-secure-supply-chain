#!/usr/bin/env bash
set -eu

: "${COSIGN_KEY:?COSIGN_KEY must be set}"
: "${COSIGN_PASSWORD:?COSIGN_PASSWORD must be set}"
: "${BOSH_RELEASE_FILE:?BOSH_RELEASE_FILE must be set}"

echo "Creating BOSH release from ${BOSH_RELEASE_FILE}..."
pushd bosh-release
  bosh create-release "${BOSH_RELEASE_FILE}" --tarball ../build/bosh-release.tgz
popd

echo "Compiling build metadata..."
for f in $(ls build-metadata); do
  echo "{\"${f}\": \"$(cat build-metadata/${f})\"}"
done > build_metadata.json
build_metadata_json=$(jq -s add <build_metadata.json)
build_link="$(cat build-metadata/atc-external-url)/teams/$(cat build-metadata/build-team-name)/pipelines/$(cat build-metadata/build-pipeline-name)/jobs/$(cat build-metadata/build-job-name)/builds/$(cat build-metadata/build-name)"
pushd bosh-release
  bosh_release_metadata="{\"uri\": \"$(git remote get-url origin)\",\"digest\":{\"gitCommit\": \"$(git rev-parse HEAD)\"}}"
popd
pushd bosh-secure-supply-chain
  bssc_metadata="{\"uri\": \"$(git remote get-url origin)\",\"digest\":{\"gitCommit\": \"$(git rev-parse HEAD)\"}}"
popd

resolved_dependencies=$(jq -s . <(echo $bssc_metadata) <(echo $bosh_release_metadata))
cat >predicate.json <<EOL
{
  "buildDefinition": {
    "buildType": "https://github.com/dtimm/bosh-secure-supply-chain/tree/main/concourse/bosh_create_release",
    "externalParameters": {},
    "internalParameters": {
      "concourseBuildMetadata": ${build_metadata_json}
    },
    "resolvedDependencies": ${resolved_dependencies}
  },
  "runDetails": {
    "builder": {
      "id": "https://github.com/dtimm/bosh-secure-supply-chain/tree/main/concourse/bosh_create_release"
    },
    "metadata": {
      "invocationId": "${build_link}"
    }
  }
}
EOL

cosign attest-blob --type "https://slsa.dev/provenance/v1" --predicate predicate.json --key <(echo -e ${COSIGN_KEY}) --yes --tlog-upload=false "build/bosh-release.tgz" 

