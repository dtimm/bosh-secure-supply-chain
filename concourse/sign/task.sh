#!/usr/bin/env bash
set -eux

echo "${SIGNING_KEY:?SIGNING_KEY must be set}"
echo -e ${SIGNING_KEY} > /tmp/cosign.key

for FILE in sboms/*; do
  cosign sign-blob --yes --tlog-upload=false --key /tmp/cosign.key --bundle attestations/${FILE#sboms/}.cosign.bundle ${FILE}
done
