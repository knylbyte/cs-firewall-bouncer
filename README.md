# CrowdSec Firewall Bouncer Docker Image

This repository provides a Dockerfile to build a minimal container for running the [CrowdSec firewall bouncer](https://github.com/crowdsecurity/cs-firewall-bouncer). The bouncer updates the host's iptables rules according to decisions from a CrowdSec Local API (LAPI).

## Build

```bash
docker build -t crowdsec-firewall-bouncer .
```

## Usage

The container expects at least the following environment variables:

- `CROWDSEC_API_KEY` – API key used by the bouncer
- `CROWDSEC_PORT` – port where the CrowdSec LAPI is reachable (default: `8080`)
- `CROWDSEC_LAPI_URL` can specify the full URL to the LAPI (default: `127.0.0.1`)
- `PROMETHEUS_ENABLED` – set to `true` to enable the Prometheus endpoint (default: `false`)
- `PROMETHEUS_PORT` – port for the Prometheus metrics endpoint (default: `60601`)

Configuration lives in `/etc/crowdsec`. If `crowdsec-firewall-bouncer.yaml` is missing, the entrypoint copies a default file on first start. To persist changes, mount the directory as a volume:

```bash
docker run -d \
  --name cs-firewall-bouncer \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e CROWDSEC_API_KEY=<API_KEY> \
  -e CROWDSEC_PORT=8080 \
  -e CROWDSEC_LAPI_URL=http://127.0.0.1:8080 \
  -e PROMETHEUS_ENABLED=false \
  -e PROMETHEUS_PORT=60601 \
  -v /path/to/config:/etc/crowdsec \
  --network=host \
  crowdsec-firewall-bouncer
```

The image exposes no ports and is based on a minimal Alpine system.

During build a self-signed certificate valid for ten years is generated in
`/etc/crowdsec/tls`. HTTPS remains disabled by default; uncomment the relevant
options in the configuration if you want to use it. Logs are written to
`/var/log/crowdsec`.

## Notes

- Modifying firewall rules requires elevated privileges (`--cap-add=NET_ADMIN --cap-add=NET_RAW` or `--privileged`).
- Ensure the CrowdSec LAPI is already running and reachable.
