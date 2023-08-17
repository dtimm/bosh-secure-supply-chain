#!/usr/bin/env bash
set -eux

echo "${GO_MOD_FILE:?GO_MOD_FILE must be set}"
sbom_format="${SBOM_FORMAT:-cyclonedx-json}"

echo "Generating SBoM for ${GO_MOD_FILE}"

package_sbom="$(syft packages "file:${GO_MOD_FILE}" --output "${sbom_format}")"
echo "Metadata for SBoM:"
echo "${package_sbom}" | jq .metadata

jsonString=$(echo "${package_sbom}" | jq --join-output --compact-output .)
echo "${jsonString}" > sbom/sbom.json
