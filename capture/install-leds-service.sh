#!/usr/bin/env bash

# Installs the capture-leds NeoPixel status service.
# Run with: sudo ./install-leds-service.sh
# Reads the capture NIC from /etc/default/capture (written by the capture
# installer). Assumes venv at /opt/capture-led-venv with the Neopixel libs.

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)" >&2; exit 1; }

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SRC_DIR/capture-leds.py" ] || { echo "capture-leds.py not found in $SRC_DIR" >&2; exit 1; }

VENV="/opt/capture-led-venv"
[ -x "$VENV/bin/python3" ] || { echo "venv not found at $VENV" >&2; exit 1; }
[ -f /etc/default/capture ] || { echo "/etc/default/capture missing - run install-capture-service.sh first" >&2; exit 1; }

install -m 755 "$SRC_DIR/capture-leds.py" /usr/local/bin/capture-leds.py

cat > /etc/systemd/system/capture-leds.service << UNIT
[Unit]
Description=NeoPixel status indicator for tcpdump capture
After=capture.service
Wants=capture.service

[Service]
EnvironmentFile=/etc/default/capture
Type=simple
ExecStart=$VENV/bin/python3 /usr/local/bin/capture-leds.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable capture-leds.service
systemctl restart capture-leds.service

echo
echo "Installed capture-leds.service (NIC from /etc/default/capture)"
echo "Logs: journalctl -u capture-leds.service -f"
