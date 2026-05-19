#!/bin/bash
# Test the callpanel module install on a freshly-built FreePBX sandbox.
# Assumes /tmp/callpanel.tgz exists (uploaded by host) and module deps
# (contactmanager, cidlookup, pm2) are already installed.

set -e
exec > >(tee -a /var/log/callpanel-install-test.log) 2>&1
echo "=== Callpanel module install test $(date) ==="

cd /tmp

# Sanity: tarball must exist
test -f /tmp/callpanel.tgz || { echo "FAIL: /tmp/callpanel.tgz not found"; exit 1; }

# Verify deps
echo "--- Verifying FreePBX module deps ---"
for mod in contactmanager cidlookup pm2; do
  STATE=$(fwconsole ma list 2>/dev/null | awk -v m="$mod" '$2==m {print $4}')
  echo "  $mod: $STATE"
  if [ "$STATE" != "Enabled" ]; then
    echo "FAIL: $mod must be Enabled before installing callpanel"
    exit 1
  fi
done

# Install via fwconsole (equivalent to Upload Modules UI)
echo "--- Installing callpanel module ---"
fwconsole ma uploadtrusted /tmp/callpanel.tgz
fwconsole ma install callpanel
fwconsole reload

# Verify install succeeded
STATE=$(fwconsole ma list 2>/dev/null | awk '$2=="callpanel" {print $4}')
echo "callpanel state after install: $STATE"
if [ "$STATE" != "Enabled" ]; then
  echo "FAIL: callpanel not Enabled after install"
  fwconsole ma list | grep callpanel || true
  exit 1
fi

# Verify PM2 process running
echo "--- Verifying PM2 process ---"
sleep 5
fwconsole pm2 --list || true
PM2_STATUS=$(fwconsole pm2 --list 2>/dev/null | awk '$2=="callpanel" {print $10}')
echo "callpanel PM2 status: $PM2_STATUS"

# Verify HTTP endpoint
echo "--- Verifying HTTP endpoint ---"
sleep 3
curl -sf -o /dev/null -w "/callpanel/ HTTP: %{http_code}\n" http://localhost:4848/callpanel/
curl -sf -o /dev/null -w "/callpanel/lookupcallerid HTTP: %{http_code}\n" 'http://localhost:4848/callpanel/lookupcallerid?number=1234567890'
curl -sf -o /dev/null -w "/callpanel/fanvil-phonebook.xml HTTP: %{http_code}\n" http://localhost:4848/callpanel/fanvil-phonebook.xml
curl -sf -o /dev/null -w "/callpanel/yealink-phonebook.xml HTTP: %{http_code}\n" http://localhost:4848/callpanel/yealink-phonebook.xml

# Verify backend log doesn't have catastrophic errors
echo "--- Backend log (last 30 lines) ---"
fwconsole pm2 --log=callpanel --lines=30 2>&1 | tail -30

echo "=== Install test complete $(date) ==="
