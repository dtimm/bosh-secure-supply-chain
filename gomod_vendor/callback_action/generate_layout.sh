#!/usr/bin/env bash
set -euo pipefail

echo "${GO_MOD_FILE:?GO_MOD_FILE must be set}"
go_sum_file="$(dirname "${GO_MOD_FILE}")/go.sum"

go_bin="$(which go)"
go_hash=$(sha256sum "${go_bin}" | awk '{print $1}')
go_version="$(go version)"

mod_hash=$(sha256sum "${GO_MOD_FILE}" | awk '{print $1}')
printf -v gomod_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}, "actions": ["go mod tidy", "go mod vendor"], "tools": [{"name": "%s", "digest": {"sha256": "%s"}, "version": "%s"}]}' \
    "${GO_MOD_FILE}" "${mod_hash}" "${go_bin}" "${go_hash}" "${go_version}"

sum_hash=$(sha256sum "${go_sum_file}" | awk '{print $1}')
printf -v gosum_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}, "actions": ["go mod tidy", "go mod vendor"], "tools": [{"name": "%s", "digest": {"sha256": "%s"}, "version": "%s"}]}' \
    "${go_sum_file}" "${sum_hash}" "${go_bin}" "${go_hash}" "${go_version}"

cat <<EOF >DATA
{
    "version": 1,
    "attestations":
    [
        {
            "name": "go.mod",
            "subjects":
            [
                ${gomod_subject}
            ]
        },
        {
            "name": "go.sum",
            "subjects":
            [
                ${gosum_subject}
            ]
        }
    ]
}
EOF

jq <DATA

# Expected file with pre-defined output
cat DATA > "$SLSA_OUTPUTS_ARTIFACTS_FILE"