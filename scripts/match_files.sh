#!/usr/bin/env bash

unzip -p $HOME/Downloads/*-slsa-attestations.zip | tar -C out/ -xzv || true
rm $HOME/Downloads/*-slsa-attestations.zip || true

unzip $HOME/Downloads/artifact.zip -d out/ || true
rm $HOME/Downloads/artifact.zip || true

echo "SBoM sha256:"
sha256sum out/sbom.json | awk '{print $1}'

echo "Attestation metadata:"
jq -r .dsseEnvelope.payload <out/*/sbom.json.build.slsa | base64 -d | jq .subject