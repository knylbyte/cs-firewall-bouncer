FROM alpine:latest AS builder

ARG CS_VERSION=v0.0.33

ARG TARGETPLATFORM

RUN apk add --no-cache curl ca-certificates tar

WORKDIR /tmp/bouncer
RUN case "$TARGETPLATFORM" in \
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

ENV CROWDSEC_PORT="8080" \
    CROWDSEC_LAPI_URL="" \
    PROMETHEUS_ENABLED="false" \
    PROMETHEUS_PORT="60601"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache nftables iptables ipset gettext ca-certificates tzdata openssl
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
