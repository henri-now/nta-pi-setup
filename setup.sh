#!/bin/bash
set -euo pipefail

# --- Derive the interface (default-route first, fallback to first wired NIC) ---
IF=$(ip -o -4 route show default | awk '{print $5; exit}')
[ -z "$IF" ] && IF=$(ls /sys/class/net | grep -E '^(eth|en|end)' | head -n1)

if [ -z "$IF" ] || [ ! -r "/sys/class/net/$IF/address" ]; then
    echo "ERROR: could not determine a network interface" >&2
    exit 1
fi

# --- Build hostname from last 8 hex chars (4 bytes) of that NIC's MAC ---
MAC=$(tr -d ':' < "/sys/class/net/$IF/address")
H="nta-cap-${MAC: -8}"

echo "Interface : $IF"
echo "MAC       : $MAC"
echo "Hostname  : $H"

# --- Set the hostname ---
sudo hostnamectl set-hostname "$H"

# --- Keep /etc/hosts consistent: rewrite 127.0.1.1 if present, else append ---
sudo cp /etc/hosts /etc/hosts.bak
if grep -qE '^127\.0\.1\.1' /etc/hosts; then
    sudo sed -i -E "s/^127\.0\.1\.1.*/127.0.1.1 $H/" /etc/hosts
else
    echo "127.0.1.1 $H" | sudo tee -a /etc/hosts >/dev/null
fi

# --- Verify ---
echo "--- hostname: ---";    hostname
echo "--- /etc/hosts: ---";  cat /etc/hosts
echo "--- resolution: ---";  time hostname -f
