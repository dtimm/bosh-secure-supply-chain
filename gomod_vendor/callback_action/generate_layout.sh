#!/usr/bin/env bash
set -euo pipefail

echo "${GO_MOD_FILE:?GO_MOD_FILE must be set}"
go_sum_file="$(dirname "${GO_MOD_FILE}")/go.sum"

mod_hash=$(sha256sum "${GO_MOD_FILE}" | awk '{print $1}')
printf -v gomod_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}}' \
    "${GO_MOD_FILE}" "$mod_hash"

sum_hash=$(sha256sum "${go_sum_file}" | awk '{print $1}')
printf -v gosum_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}}' \
    "${go_sum_file}" "$sum_hash"

cat <<EOF >DATA
{
    "version": 1,
    "attestations":
    [
        {
            "name": "${GO_MOD_FILE}",
            "subjects":
            [
                ${gomod_subject}
            ]
        },
        {
            "name": "${go_sum_file}",
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