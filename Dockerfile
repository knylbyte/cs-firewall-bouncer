FROM alpine:latest AS builder

# This version is automatically updated by the workflow
ARG CS_VERSION=v0.0.33

ARG TARGETPLATFORM

RUN apk add --no-cache curl ca-certificates tar jq

WORKDIR /tmp/bouncer
RUN if [ "$CS_VERSION" = "latest" ]; then \
        CS_VERSION=$(curl -s https://api.github.com/repos/crowdsecurity/cs-firewall-bouncer/releases/latest | jq -r '.tag_name'); \
    fi \
    && case "$TARGETPLATFORM" in \
        "linux/amd64") CS_ARCH=amd64 ;; \
        "linux/arm64") CS_ARCH=arm64 ;; \
        "linux/arm/v7") CS_ARCH=armv7 ;; \
        *) echo "Unsupported architecture $TARGETPLATFORM" && exit 1 ;; \
    esac \
    && curl -L -o bouncer.tgz "https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/${CS_VERSION}/crowdsec-firewall-bouncer-linux-${CS_ARCH}.tgz" \
    && tar -xzf bouncer.tgz \
    && mv crowdsec-firewall-bouncer*/crowdsec-firewall-bouncer /crowdsec-firewall-bouncer \
    && mv crowdsec-firewall-bouncer*/config/crowdsec-firewall-bouncer.yaml /crowdsec-firewall-bouncer.yaml

FROM alpine:latest
ARG CS_VERSION

ENV CROWDSEC_PORT="8080" \
    CROWDSEC_LAPI_URL="" \
    PROMETHEUS_ENABLED="false" \
    PROMETHEUS_PORT="60601" \
    BOUNCER_VERSION="$CS_VERSION"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache nftables nftables iptables ipset gettext ca-certificates tzdata openssl curl jq
ENV TZ=UTC

COPY --from=builder /crowdsec-firewall-bouncer /usr/local/bin/crowdsec-firewall-bouncer
COPY --from=builder /crowdsec-firewall-bouncer.yaml /defaults/crowdsec-firewall-bouncer.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN mkdir -p /etc/crowdsec/tls /var/log/crowdsec \
    && openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
        -subj "/CN=crowdsec" \
        -keyout /etc/crowdsec/tls/key.pem \
        -out /etc/crowdsec/tls/cert.pem \
    && cp /etc/crowdsec/tls/cert.pem /etc/crowdsec/tls/ca.crt \
    && sed -i 's#^log_dir: .*#log_dir: /var/log/crowdsec#' /defaults/crowdsec-firewall-bouncer.yaml

VOLUME ["/etc/crowdsec"]

ENTRYPOINT ["/entrypoint.sh"]
CMD []
