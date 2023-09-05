# BOSH Create Release Link

This link provides two in-toto attestations for a BOSH release per go.mod file used by packages in the BOSH release:
1. Software bill of materials (SBoM) generated using `syft` and using the CycloneDX format.
1. Provenance for that SBoM, attesting that the packages in the SBoM are properly vendored into the repository and indicating the gosum checksums for each vendored dependencies.

## Build Types

