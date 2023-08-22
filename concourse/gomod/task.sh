#!/usr/bin/env bash
set -eux

echo "${PACKAGE_NAME:?PACKAGE_NAME must be set}"
sbom_format="${SBOM_FORMAT:-cyclonedx-json}"

spec_file="bosh-release/packages/$PACKAGE_NAME/spec"

# Check if spec file exists
if [[ ! -f "$spec_file" ]]; then
  echo "spec file not found for $PACKAGE_NAME. Skipping..."
  return
fi

echo "Finding go.mod files for $PACKAGE_NAME..."

gomods=()
while IFS= read -r line
do
  # Check if spec file contains go.mod
  if [[ "$line" =~ "go.mod" ]]; then
    # Extract relative path from line
    rel_path=$(echo $line | cut -d':' -f2 | tr -d ' ' | tr -d '"')
    rel_path=${rel_path#"-"}

    # Absolute path to the go.mod file
    abs_path="bosh-release/src/$rel_path"

    # If go.mod exists, add it to the list
    for f in $(ls $abs_path); do
      echo "go.mod found in $f"
      gomods+=("$f")
    done
  fi
done < "$spec_file"

uniq_gomods=($(for g in "${gomods[@]}"; do echo "${g}"; done | sort -u))
for gomod in "${uniq_gomods[@]}"; do
  echo "Generating SBoM for ${gomod}"
  package_sbom="$(syft packages "file:${gomod}" --output "${sbom_format}")"

  jsonString=$(echo "${package_sbom}" | jq --join-output --compact-output .)

  output_file=${gomod//\//-}
  echo "${jsonString}" > "sboms/${output_file#bosh-release-src-}.sbom.json"
done
