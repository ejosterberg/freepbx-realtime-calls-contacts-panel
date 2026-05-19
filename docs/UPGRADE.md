# Upgrading

How to move from one version of the Calls + Contacts Panel to the
next.

## Upgrade strategy

The simplest reliable upgrade is **uninstall + reinstall**:

1. Back up your `config.local.json`
2. Uninstall the current module
3. Install the new version
4. Restore `config.local.json`
5. Restart the panel

The module has no database tables of its own (it reads from
FreePBX's existing `contactmanager_*` and CDR tables), so there's
no schema migration to worry about. Your contacts and call history
are stored in FreePBX, not in the panel — they survive any
panel upgrade or reinstall untouched.

## Step-by-step

### 1. Check what version you have now

```bash
grep -A1 '<version>' /var/www/html/admin/modules/callpanel/module.xml | head -2
```

### 2. Check what's available

```bash
gh release list -R ejosterberg/freepbx-realtime-calls-contacts-panel \
  --limit 5
```

Or browse the
[Releases page](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases).

Check [CHANGELOG.md](../CHANGELOG.md) for what changed between
versions.

### 3. Back up your config

```bash
sudo cp /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json \
   /tmp/callpanel-config.bak.json
```

(If you've never customized any settings, this file may not exist —
that's fine, skip this step.)

### 4. Uninstall the current version

```bash
sudo fwconsole ma uninstall callpanel
sudo fwconsole ma delete callpanel
```

This stops the PM2 process and removes the module directory.

### 5. Install the new version

```bash
cd /tmp
sudo wget https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest/download/callpanel-NEW-VERSION.tgz
sudo tar -xzf callpanel-NEW-VERSION.tgz -C /var/www/html/admin/modules/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
sudo fwconsole ma install callpanel -f
```

(Replace `NEW-VERSION` with the actual version number from step 2.)

### 6. Restore your config

```bash
sudo cp /tmp/callpanel-config.bak.json \
   /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
sudo chown asterisk:asterisk \
   /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
sudo fwconsole pm2 --restart callpanel
```

### 7. Apply config + verify

```bash
sudo fwconsole reload
sudo fwconsole pm2 --list | grep callpanel
# Expected: status `online`, restart count `0`
```

Browse to the panel and confirm everything still works.

## Downgrading

The same procedure works in reverse — uninstall the current version,
install an older release. There are no schema changes to worry about
across versions, so downgrades are safe.

```bash
# Example: roll back from v17.0.1 to v17.0.0
sudo fwconsole ma uninstall callpanel
sudo fwconsole ma delete callpanel
cd /tmp
sudo wget https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/download/v17.0.0/callpanel-17.0.0.tgz
sudo tar -xzf callpanel-17.0.0.tgz -C /var/www/html/admin/modules/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
sudo fwconsole ma install callpanel -f
```

Note that v17.0.0 specifically has a CI tarball that never built —
v17.0.1 is the earliest installable release of this fork.

## Major version upgrades

Currently there's only the v17.0.x line. If a future v18.0.0 or
v17.1.0 introduces a breaking change, the release notes will call
it out and link to specific upgrade steps for that version. As of
this writing, no breaking changes are planned.

## What does NOT need to change on upgrade

- **Your FreePBX `pjsip`, extension, and trunk config** — the
  panel doesn't touch dialplan or signaling
- **The `contactmanager_*` tables** — these belong to FreePBX,
  not the panel
- **The Asterisk `manager.conf` user the panel uses** — the panel
  re-detects this on every startup
- **Your FreePBX User Manager users** — auth is delegated to
  FreePBX's `userman` module

## What MIGHT need to change on upgrade

- **Apache reverse-proxy snippet** — if a future version changes
  ports or paths (none planned), the snippet needs to match. The
  current path/port (`/callpanel/` on `127.0.0.1:4848`) is stable.
- **Node.js minimum version** — if a future release requires
  Node 22+ instead of 18+, you'd need to upgrade Node before
  installing.
- **Module dependency versions** — check the [release notes](../CHANGELOG.md)
  to see if the new version bumped `contactmanager`, `cidlookup`,
  or `pm2` minimum requirements.

## Why not in-place upgrade?

The pattern of uninstall + reinstall (vs `fwconsole ma upgrade`)
is more reliable because:

- Removes stale `node_modules` and `build/` artifacts cleanly
- Forces a full rebuild against the new Node version (in case
  FreePBX upgraded Node in the interim)
- Eliminates the chance of leftover database hooks from older
  versions
- Mirrors what a fresh install does — no special "upgrade" code
  paths to maintain

The downside is ~5–10 minutes of panel downtime during the
rebuild. For a home/small-business PBX this is acceptable;
schedule the upgrade for off-hours.

## Automating upgrades

If you upgrade frequently, the manual steps above can be wrapped
in a script. Example `~/upgrade-callpanel.sh`:

```bash
#!/bin/bash
set -e

VERSION="${1:-latest}"
URL="https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases"

if [ "$VERSION" = "latest" ]; then
  URL="$URL/latest/download"
else
  URL="$URL/download/v$VERSION"
fi

# Try to discover tarball filename for the chosen version
echo "Fetching version manifest..."
TARBALL=$(curl -sLI "$URL/" | grep -oE 'callpanel-[0-9.]+\.tgz' | head -1)
[ -z "$TARBALL" ] && { echo "Couldn't determine tarball name"; exit 1; }

echo "Will install: $TARBALL"

# Back up config
CONFIG=/var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
[ -f "$CONFIG" ] && sudo cp "$CONFIG" /tmp/callpanel-config.bak.json

# Download
cd /tmp
sudo wget -q "$URL/$TARBALL" -O "$TARBALL"

# Uninstall + reinstall
sudo fwconsole ma uninstall callpanel || true
sudo fwconsole ma delete callpanel || true
sudo rm -rf /var/www/html/admin/modules/callpanel
sudo tar -xzf "$TARBALL" -C /var/www/html/admin/modules/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
sudo fwconsole ma install callpanel -f

# Restore config
[ -f /tmp/callpanel-config.bak.json ] && {
  sudo cp /tmp/callpanel-config.bak.json "$CONFIG"
  sudo chown asterisk:asterisk "$CONFIG"
  sudo fwconsole pm2 --restart callpanel
}

sudo fwconsole reload

echo "Upgrade complete. Panel status:"
sudo fwconsole pm2 --list | grep callpanel
```

Usage:

```bash
./upgrade-callpanel.sh           # latest
./upgrade-callpanel.sh 17.0.1    # specific version
```
