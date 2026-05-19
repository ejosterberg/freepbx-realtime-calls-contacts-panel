#!/bin/bash
# Continuation of install-fpbx16.sh — fix cron + re-run FreePBX install steps.
# Run as root. Idempotent (uses -f --force on FreePBX install).

set -e
exec > >(tee -a /var/log/freepbx16-install.log) 2>&1
echo "=== FreePBX 16 install RESUME $(date) ==="

export DEBIAN_FRONTEND=noninteractive

# Make sure cron is installed + running (root cause of the first failure)
apt-get install -y -qq cron at
systemctl enable --now cron at

# Re-run from Stage 6 (FreePBX install)
echo "=== Stage 6 (resume): FreePBX 16 ==="
cd /usr/src/freepbx
./start_asterisk start || true
./install -n --dbuser root --dbpass '' --webroot=/var/www/html --force

fwconsole ma installall
fwconsole chown
fwconsole reload
fwconsole restart

systemctl restart apache2

echo "=== FreePBX 16 install complete $(date) ==="
echo "Web UI: http://$(hostname -I | awk '{print $1}')/admin"
fwconsole --version
asterisk -rx 'core show version' || true
