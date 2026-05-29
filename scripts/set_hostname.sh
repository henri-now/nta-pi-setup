#!/bin/bash
set -euo pipefail

PREFIX="nta-cap"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: please run as root: sudo $0" >&2
    exit 1
fi

# Ensure machine-id exists.
if [ ! -s /etc/machine-id ]; then
    systemd-machine-id-setup
fi

MACHINE_ID=$(cat /etc/machine-id | tr -d '[:space:]')

if [ -z "$MACHINE_ID" ]; then
    echo "ERROR: could not determine machine-id" >&2
    exit 1
fi

HOSTNAME="${PREFIX}-${MACHINE_ID:0:8}"

echo "Machine ID : $MACHINE_ID"
echo "Hostname   : $HOSTNAME"

hostnamectl set-hostname "$HOSTNAME"

cp /etc/hosts /etc/hosts.bak

if grep -qE '^127\.0\.1\.1' /etc/hosts; then
    sed -i -E "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

echo "--- hostname ---"
hostname

echo "--- /etc/hosts ---"
grep -E '^(127\.0\.0\.1|127\.0\.1\.1)' /etc/hosts