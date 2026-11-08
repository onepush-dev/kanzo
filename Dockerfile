# Kanzo on Railway: the official Kanzo v0.4.1 static (musl) release binary
# (emanuele-em/kanzo, AGPL-3.0) in ONE Alpine container with:
#   - Caddy on Railway's $PORT plus a tiny cookie login gate (Kanzo has no
#     logins by design: "anyone who can reach the port can read and change the
#     board"). MCP clients use "Authorization: Bearer <KANZO_PASSWORD>".
#   - Kanzo itself pinned to 127.0.0.1 (listen is reset on every boot), data
#     in KANZO_HOME=/data on a Railway volume.
FROM caddy:2.10.2-alpine AS edge

FROM alpine:3.22
ARG KANZO_VERSION=0.4.1
ARG KANZO_SHA256=660622f9b366d5a459b5b850b177370f76e18d9819993d0f0fabce00ae076c41
RUN apk add --no-cache ca-certificates curl tini nodejs xz \
 && curl -fsSL -o /tmp/kanzo.tar.xz "https://github.com/emanuele-em/kanzo/releases/download/v${KANZO_VERSION}/kanzo-x86_64-unknown-linux-musl.tar.xz" \
 && echo "${KANZO_SHA256}  /tmp/kanzo.tar.xz" | sha256sum -c - \
 && tar xJf /tmp/kanzo.tar.xz -C /tmp \
 && install -m 755 /tmp/kanzo-x86_64-unknown-linux-musl/kanzo /usr/local/bin/kanzo \
 && mkdir -p /usr/share/licenses/kanzo && cp /tmp/kanzo-x86_64-unknown-linux-musl/LICENSE /usr/share/licenses/kanzo/ \
 && rm -rf /tmp/kanzo* \
 && kanzo --version
COPY --from=edge /usr/bin/caddy /usr/local/bin/caddy
COPY railway/Caddyfile /etc/kanzo-railway/Caddyfile
COPY railway/gate.mjs /etc/kanzo-railway/gate.mjs
COPY railway/start.sh /usr/local/bin/kanzo-railway-start
RUN chmod 755 /usr/local/bin/kanzo-railway-start \
 && node --check /etc/kanzo-railway/gate.mjs \
 && caddy validate --config /etc/kanzo-railway/Caddyfile --adapter caddyfile
# Plain defaults live in the image so the template only carries the generated
# password. Override any of them with a Railway variable.
ENV PORT=8080 \
    KANZO_PORT=4242 \
    KANZO_HOME=/data \
    GATE_PORT=8789 \
    KANZO_USERNAME=admin
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -sf "http://127.0.0.1:${PORT:-8080}/healthz" || exit 1
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/kanzo-railway-start"]
