FROM alpine:latest AS builder

ARG CS_VERSION=v0.0.33
ARG TARGETARCH
ARG TARGETVARIANT

RUN apk add --no-cache curl ca-certificates tar

WORKDIR /tmp/bouncer
RUN ARCH="${TARGETARCH}${TARGETVARIANT}" \
    && curl -L -o bouncer.tgz https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_VERSION}/crowdsec-firewall-bouncer-linux-${ARCH}.tgz \
    && tar -xzf bouncer.tgz \
    && mv crowdsec-firewall-bouncer*/crowdsec-firewall-bouncer /crowdsec-firewall-bouncer \
    && mv crowdsec-firewall-bouncer*/config/crowdsec-firewall-bouncer.yaml /crowdsec-firewall-bouncer.yaml

FROM alpine:latest

ENV CROWDSEC_API_KEY="" \
    CROWDSEC_PORT="8080" \
    CROWDSEC_LAPI_URL=""

RUN apk add --no-cache iptables gettext ca-certificates

COPY --from=builder /crowdsec-firewall-bouncer /usr/local/bin/crowdsec-firewall-bouncer
COPY --from=builder /crowdsec-firewall-bouncer.yaml /defaults/crowdsec-firewall-bouncer.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/etc/crowdsec"]

ENTRYPOINT ["/entrypoint.sh"]
CMD []
