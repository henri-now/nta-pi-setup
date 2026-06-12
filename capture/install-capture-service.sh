#!/bin/bash
#####################################
# Installs the tcpdump capture service.
#   - captures on the given NIC (e.g. enx3c18a0d52e65)
#   - all traffic, size-rotated at 50 MB/file, never overwritten
#   - runs continuously, enabled at boot; idles when the cable is unplugged
#
# Storage management is handled by a separate script.
#
# USAGE: sudo ./install-capture-service.sh NIC
#   NIC   the NIC interface name (e.g. enx3c18a0d52e65 or eth1)
#####################################
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root (use sudo)" >&2
    exit 1
fi

NIC="${1:-}"
if [ -z "$NIC" ]; then
    echo "ERROR: no NIC specified" >&2
    echo "USAGE: sudo $0 NIC   (e.g. sudo $0 enx3c18a0d52e65)" >&2
    exit 1
fi

if ! command -v tcpdump >/dev/null 2>&1; then
    echo "tcpdump not found, installing..."
    apt-get update -qq && apt-get install -y tcpdump
fi

if ! ip link show "$NIC" >/dev/null 2>&1; then
    echo "WARNING: interface '$NIC' not currently present" >&2
fi

mkdir -p /var/captures

cat > /etc/systemd/system/capture.service <<EOF
[Unit]
Description=tcpdump packet capture on ${NIC}
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
ExecStartPre=/usr/bin/mkdir -p /var/captures
ExecStart=/usr/bin/tcpdump -i ${NIC} -n -C 50 -w /var/captures/cap.pcap -Z root
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now capture.service

echo
echo "Installed capture.service:"
echo "  interface : ${NIC}"
echo "  files     : /var/captures, 50 MB each, never overwritten"
echo "  runs continuously, enabled at boot (idles when cable unplugged)"
echo
echo "Status: systemctl status capture.service"
echo "Logs:   journalctl -u capture.service -f"
echo "Files:  ls -lh /var/captures"