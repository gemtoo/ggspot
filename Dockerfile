FROM alpine:edge
RUN apk upgrade --no-cache && apk add --no-cache yggdrasil radvd gettext-envsubst jq bash tar xz || true
ARG S6_OVERLAY_VERSION=3.2.1.0
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
RUN ln -sf /bin/bash /bin/sh && mkdir -p /run/radvd
COPY --chown=root:root --chmod=755 cont-init.d /etc/cont-init.d
COPY --chown=root:root --chmod=755 services.d /etc/services.d
COPY --chown=root:root --chmod=755 templates /etc/templates

ENTRYPOINT ["/init"]
