#!/usr/bin/env bash

# Installer for the diskclean service + timer
# Run with: sudo ./install.sh

set -euo pipefail

# Must be root to write to /usr/local/bin and /etc/systemd/system
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo ./install.sh)" >&2; exit 1; }

# Directory this installer lives in, so we can find diskclean.sh next to it
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

# Make sure the script we're about to install actually exists
[ -f "$SRC_DIR/diskclean.sh" ] || { echo "diskclean.sh not found in $SRC_DIR" >&2; exit 1; }

# Install the cleanup script and make it executable
install -m 755 "$SRC_DIR/diskclean.sh" /usr/local/bin/diskclean.sh

# Write the service unit (what to run)
cat > /etc/systemd/system/diskclean.service << 'EOF'
[Unit]
Description=Delete oldest files when folder size exceeds threshold

[Service]
Type=oneshot
ExecStart=/usr/local/bin/diskclean.sh
EOF

# Write the timer unit (when to run it)
cat > /etc/systemd/system/diskclean.timer << 'EOF'
[Unit]
Description=Run diskclean periodically

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOF

# Reload systemd so it picks up the new unit files
systemctl daemon-reload

# Enable + start the timer now (and on every boot)
systemctl enable --now diskclean.timer

# Show the result so you can confirm it's scheduled
echo
echo "Installed. Next run:"
systemctl list-timers diskclean.timer --no-pager
