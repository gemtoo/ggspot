FROM alpine:edge
RUN apk upgrade --no-cache && apk add --no-cache yggdrasil radvd s6-overlay gettext-envsubst jq bash || true
RUN ln -sf /bin/bash /bin/sh && mkdir -p /run/radvd
COPY --chown=root:root --chmod=755 cont-init.d /etc/cont-init.d
COPY --chown=root:root --chmod=755 services.d /etc/services.d
COPY --chown=root:root --chmod=755 templates /etc/templates

ENTRYPOINT ["/init"]
