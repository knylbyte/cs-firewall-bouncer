#!/bin/sh
set -e

CONFIG_DIR=/etc/crowdsec
CONFIG_FILE="$CONFIG_DIR/crowdsec-firewall-bouncer.yaml"
DEFAULT_CONFIG=/defaults/crowdsec-firewall-bouncer.yaml

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    BACKEND=${BACKEND:-iptables}
    API_KEY=${CROWDSEC_API_KEY:-}
    BACKEND="$BACKEND" API_KEY="$API_KEY" envsubst < "$DEFAULT_CONFIG" > "$CONFIG_FILE"
fi

API_URL=${CROWDSEC_LAPI_URL:-http://127.0.0.1:${CROWDSEC_PORT:-8080}}
# Ensure trailing slash
case $API_URL in
    */) ;;
    *) API_URL="$API_URL/" ;;
esac

sed -i "s#^api_url:.*#api_url: ${API_URL}#" "$CONFIG_FILE"
if [ -n "$CROWDSEC_API_KEY" ]; then
    sed -i "s#^api_key:.*#api_key: ${CROWDSEC_API_KEY}#" "$CONFIG_FILE"
fi

# Configure Prometheus metrics if requested
PROMETHEUS_ENABLED=${PROMETHEUS_ENABLED:-false}
PROMETHEUS_PORT=${PROMETHEUS_PORT:-60601}
sed -i "0,/enabled:/s/enabled:.*/enabled: ${PROMETHEUS_ENABLED}/" "$CONFIG_FILE"
sed -i "0,/listen_port:/s/listen_port:.*/listen_port: ${PROMETHEUS_PORT}/" "$CONFIG_FILE"

exec crowdsec-firewall-bouncer -c "$CONFIG_FILE"
