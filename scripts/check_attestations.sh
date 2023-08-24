#!/usr/bin/env bash

unzip -p $HOME/Downloads/*-slsa-attestations.zip | tar -C out/ -xzv || true
rm $HOME/Downloads/*-slsa-attestations.zip || true

echo "Attestation metadata:"
jq -r .dsseEnvelope.payload <out/*/go.mod.build.slsa | base64 -d | jq .subject
jq -r .dsseEnvelope.payload <out/*/go.sum.build.slsa | base64 -d | jq .subject