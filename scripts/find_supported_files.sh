#!/usr/bin/env bash
set -e

gomods=()
gemfiles=()
for package in $(ls packages); do
  spec_file="packages/${package}/spec"

  # Check if spec file exists
  if [[ ! -f "${spec_file}" ]]; then
    echo "spec file not found for ${package}."
  else
    for glob in $(yq -r '.files[]' <${spec_file}); do
      for f in $(ls src/${glob}); do
        echo "Checking ${f}"
        case `basename ${f}` in
        go.mod)
          echo "go.mod found: ${f}"
          gomods+=("${f}")
          ;;
        Gemfile)
          echo "Gemfile found: ${f}"
          gemfiles+=("${f}")
          ;;
        *)
          ;;
        esac
      done
    done
  fi
done

uniq_files () {
  local files=("$@")
  local uniq_files=($(for g in "${files[@]}"; do echo "${g}"; done | sort -u))
  local jsonString="$(jq --compact-output --null-input '$ARGS.positional' --args -- "${uniq_files[@]}")"
  echo ${jsonString}
}

echo "gomods=$(uniq_files "${gomods[@]}")" | tee --append "$GITHUB_OUTPUT"
echo "gemfiles=$(uniq_files "${gemfiles[@]}")" | tee --append "$GITHUB_OUTPUT"
