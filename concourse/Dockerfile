FROM gcr.io/projectsigstore/cosign:v2.1.1 as cosign
FROM anchore/syft:v0.87.0 as syft

FROM harbor-repo.vmware.com/dockerhub-proxy-cache/paketobuildpacks/builder-jammy-buildpackless-tiny:0.0.85

COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign
COPY --from=syft /syft /usr/local/bin/syft

WORKDIR /workspace
USER root
