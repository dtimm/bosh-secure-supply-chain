### BOSH Secure Supply Chain

This repository contains tools and pipelines for building BOSH releases with attested provenance information. The goal is to ensure that BOSH releases can be included in software that requires secure supply chain information.

Each Concourse task in the repository is designed as a "link" in the supply chain. Each link connects to the upstream chain by validating the provenance information of the preceeding links and then producing new provenance information for the next link. Each link produces one or more [in-toto v0.1.0 attestations](https://in-toto.io/Statement/v0.1), which are rendered into an output `attestations` directory.

## Usage
Reference the [concourse-pipeline](./concourse/pipeline.yml) for an example of how to use these tasks in a pipeline.

## Links
### go.mod vendor SBoM
This link provides at least two in-toto attestations for a BOSH release:
1. Software bill of materials (SBoM) for each go.mod file used by packages in the BOSH release. This SBoM is generated using `syft` and used the CycloneDX format.
1. Provenance for each SBoM, attesting that the packages in the SBoM are properly vendored into the repository.
