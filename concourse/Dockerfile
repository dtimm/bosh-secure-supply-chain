FROM gcr.io/projectsigstore/cosign:v2.1.1 as cosign
FROM anchore/syft:v0.87.0 as syft
FROM bosh/cli2:7.4.0 as bosh

FROM harbor-repo.vmware.com/dockerhub-proxy-cache/paketobuildpacks/builder-jammy-buildpackless-tiny:0.0.85

COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign
COPY --from=syft /syft /usr/local/bin/syft
COPY --from=bosh /usr/local/bin/bosh /usr/local/bin/bosh

USER root
RUN curl --fail -sSL https://go.dev/dl/go1.20.1.linux-amd64.tar.gz | tar -xz -C /usr/local
ENV GOROOT=/usr/local/go/
ENV PATH="$GOROOT/bin:/root/go/bin:$PATH"

WORKDIR /workspace
