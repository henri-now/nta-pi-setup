#!/bin/bash

#####################################
# Installs the tcpdump capture service.
#   - captures on the given NIC (e.g. enx3c18a0d52e65)
#   - all traffic, size-rotated at 50 MB/file, no auto-overwrite
#   - tied to that NIC: capture starts when the NIC is present and
#     stops when it is unplugged (BindsTo the NIC's .device unit)
# USAGE: sudo ./install-capture-service.sh NIC
#   NIC   the USB NIC interface name (e.g. enx3c18a0d52e65 or eth1)
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
    echo "WARNING: interface '$NIC' not currently present; service will start when it appears" >&2
fi

mkdir -p /var/captures

# systemd .device unit for the NIC (name derived from the interface name)
NIC_DEVICE="sys-subsystem-net-devices-${NIC}.device"

cat > /etc/systemd/system/capture.service <<EOF
[Unit]
Description=tcpdump packet capture on ${NIC} (tied to ${NIC} presence)
# capture is bound to the NIC existing: starts when it appears,
# stops when it is unplugged
After=${NIC_DEVICE}
BindsTo=${NIC_DEVICE}

[Service]
Type=exec
ExecStartPre=/usr/bin/mkdir -p /var/captures
ExecStart=/usr/bin/tcpdump -i ${NIC} -n -C 50 -w /var/captures/cap.pcap -Z root
Restart=on-failure
RestartSec=5

[Install]
# started when the NIC appears
WantedBy=${NIC_DEVICE}
EOF

systemctl daemon-reload
systemctl enable capture.service

# start now if the NIC is already present
if systemctl --quiet is-active "${NIC_DEVICE}" 2>/dev/null; then
    systemctl start capture.service
fi

echo
echo "Installed capture.service:"
echo "  interface : ${NIC}"
echo "  files     : /var/captures, 50 MB each, no auto-overwrite"
echo "  trigger   : starts with NIC '${NIC}', stops when unplugged"
echo
echo "Status: systemctl status capture.service"
echo "Logs:   journalctl -u capture.service -f"