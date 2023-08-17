#!/usr/bin/env bash
set -euo pipefail

artifact=sbom.json
echo "${SBOM}" > "$artifact"

hash=$(sha256sum "$artifact" | awk '{print $1}')
subject_name=$(basename "$(readlink -m "$artifact")")
printf -v sbom_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}}' \
    "$subject_name" "$hash"

syft_path=$(command -v syft)
syft_hash=$(sha256sum "${syft_path}" | awk '{print $1}')
syft_version=$(syft version --output=json)
printf -v syft_subject \
    '{"name": "%s", "digest": {"sha256": "%s"}, "version": %s}' \
    "$syft_path" "$syft_hash" "$syft_version"

cat <<EOF >DATA
{
    "version": 1,
    "attestations":
    [
        {
            "name": "${artifact}",
            "subjects":
            [
                ${sbom_subject}
            ]
        },
        {
            "name": "syft",
            "subjects":
            [
                ${syft_subject}
            ]
        }
    ]
}
EOF

jq <DATA

# Expected file with pre-defined output
cat DATA > "$SLSA_OUTPUTS_ARTIFACTS_FILE"