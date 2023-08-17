#!/usr/bin/env bash
set -eux

for FILE in sboms/*; do
  cosign sign-blob --yes --tlog-upload=false --key signing-key/cosign.key --bundle attestations/cosign.bundle ${FILE}
done
