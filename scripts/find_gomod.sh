#!/usr/bin/env bash
set -e

echo "${PACKAGE_NAME:?PACKAGE_NAME must be set}"

spec_file="packages/$PACKAGE_NAME/spec"

# Check if spec file exists
if [[ ! -f "$spec_file" ]]; then
  echo "spec file not found for $PACKAGE_NAME."
  echo "go-mods=[]" | tee --append "$GITHUB_OUTPUT"
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
    abs_path="src/$rel_path"

    # If go.mod exists, add it to the list
    for f in $(ls $abs_path); do
      echo "go.mod found in $f"
      gomods+=("$f")
    done
  fi
done < "$spec_file"

uniq_gomods=($(for g in "${gomods[@]}"; do echo "${g}"; done | sort -u))
jsonString="$(jq --compact-output --null-input '$ARGS.positional' --args -- "${uniq_gomods[@]}")"
echo "go-mods=${jsonString}" | tee --append "$GITHUB_OUTPUT"
