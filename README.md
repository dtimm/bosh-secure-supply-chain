# BOSH Secure Supply Chain

This repository contains tools and pipelines for building BOSH releases with attested provenance information. The goal is to ensure that BOSH releases can be included in software that requires secure supply chain information.

Each Concourse task in the repository is designed as a "link" in the supply chain. Each link connects to the upstream chain by validating the provenance information of the preceeding links and then producing new provenance information for the next link. Each link produces one or more [in-toto v0.1.0 attestations](https://in-toto.io/Statement/v0.1), which are rendered into the output `attestations` directory.

## Usage
Reference the [concourse-pipeline](./concourse/pipeline.yml) for an example of how to use these tasks in a pipeline.

## Links
### [go.mod Vendor SBoM](./concourse/gomod_vendor_sbom/README.md)
### [BOSH Create Release](./concourse/bosh_create_release/README.md)
