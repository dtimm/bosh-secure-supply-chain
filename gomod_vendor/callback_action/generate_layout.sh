#!/usr/bin/env bash
set -euo pipefail

echo "${GO_MOD_FILE:?GO_MOD_FILE must be set}"

hash=$(sha256sum "${GO_MOD_FILE}" | awk '{print $1}')
subject_name=$(basename "$(readlink -m "${GO_MOD_FILE}")")
printf -v gomod_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}}' \
    "$subject_name" "$hash"

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
        }
    ]
}
EOF

jq <DATA

# Expected file with pre-defined output
cat DATA > "$SLSA_OUTPUTS_ARTIFACTS_FILE"