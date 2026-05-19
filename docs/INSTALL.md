# Installation

This guide walks you through installing the Calls + Contacts Panel
module on an existing FreePBX system. For configuration and usage
after install, see [CONFIGURATION.md](CONFIGURATION.md) and
[USAGE.md](USAGE.md).

## Prerequisites

| Component | Minimum version | Notes |
|---|---|---|
| FreePBX | 16.0 or 17.0 | Older or newer untested |
| Asterisk | 18.x (with FPBX 16) or 22.x (with FPBX 17) | pjsip channel driver |
| PHP | 7.4 (FPBX 16) or 8.2 (FPBX 17) | Set by your FreePBX install |
| Node.js | 18.x or newer | Provided by FreePBX's `pm2` module |
| MariaDB / MySQL | 10.5+ | Set by your FreePBX install |

**Required FreePBX modules** (install first if missing):

| Module | Minimum version | Why |
|---|---|---|
| `contactmanager` | 16.0.17 | Source of truth for contacts; the panel CRUDs through it |
| `cidlookup` | 16.0.5 | Caller ID number-to-name resolution |
| `pm2` | 13.0.3.8 | Runs the panel's NodeJS backend as a managed process |
| `userman` | (any) | Login authentication source for the panel |

Verify all four are installed:

```bash
sudo fwconsole ma list | grep -E "contactmanager|cidlookup|pm2|userman"
```

If any are missing:

```bash
sudo fwconsole ma downloadinstall contactmanager cidlookup pm2 userman
sudo fwconsole reload
```

## Installation — recommended path

### 1. Download the release tarball

On your FreePBX host:

```bash
cd /tmp
sudo wget https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest/download/callpanel-17.0.1.tgz
```

(Replace `17.0.1` with whatever is current. See the
[Releases page](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases)
for the latest version.)

### 2. Extract to FreePBX's modules directory

```bash
sudo tar -xzf /tmp/callpanel-17.0.1.tgz -C /var/www/html/admin/modules/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
```

### 3. Install via `fwconsole`

```bash
sudo fwconsole ma install callpanel -f
```

The `-f` flag bypasses signature verification (this is an unsigned
community fork). Expect the install to take **5–10 minutes** on a
typical VM — most of it is npm dependency install + frontend build.
The output will look something like:

```
Installing/Updating Required Libraries. This may take a while...
[npm-cache] [INFO] [npm] running [npm install]...
... (many lines of npm output) ...
Building backend (tsc)...
Installing + building frontend (react-scripts)...
... (more npm output) ...
Compiled successfully.
Finished updating libraries!
Started with PID 12345!
Module callpanel version 17.0.1 successfully installed
```

If you see `Started with PID <number>!` at the end — the panel is
running. If you see `Failed!` instead, jump to
[TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### 4. Apply config

```bash
sudo fwconsole reload
```

### 5. Verify the panel is running

```bash
sudo fwconsole pm2 --list | grep callpanel
```

Expected: status `online`, restart count `0`.

Test the HTTP endpoints:

```bash
curl -sf -o /dev/null -w "%{http_code}\n" http://localhost:4848/callpanel/
# Expected: 200
curl -sf -o /dev/null -w "%{http_code}\n" "http://localhost:4848/callpanel/lookupcallerid?number=1234567890"
# Expected: 200
curl -sf -o /dev/null -w "%{http_code}\n" http://localhost:4848/callpanel/fanvil-phonebook.xml
# Expected: 200
curl -sf -o /dev/null -w "%{http_code}\n" http://localhost:4848/callpanel/yealink-phonebook.xml
# Expected: 200
```

### 6. Access the panel

From a browser:

```
http://<your-freepbx-host>:4848/callpanel/
```

You'll see a login screen. Use a **FreePBX User Manager** username
and password (the same login that gets users into the FreePBX UCP).
See [CONFIGURATION.md → Access control](CONFIGURATION.md#access-control)
for the permission requirements.

### 7. Admin view

In the FreePBX admin UI:

```
Admin → Calls + Contacts Panel
```

You'll see service status (Running / Not Running), the panel URLs,
and configurable settings. See [CONFIGURATION.md](CONFIGURATION.md)
for what each setting does.

## Optional: Apache reverse proxy

By default the panel listens on port **4848**, separate from FreePBX's
Apache on 80/443. If you want everything on port 80/443 (sharing
FreePBX's web server), add a proxy snippet.

Create `/etc/apache2/conf-enabled/callpanel-proxy.conf` (Debian
naming) or `/etc/httpd/conf.d/callpanel-proxy.conf` (RHEL/SNG7
naming) with:

```apache
# Calls + Contacts Panel reverse proxy
RewriteEngine On

# WebSocket upgrade (must come BEFORE the plain HTTP rule)
RewriteCond %{REQUEST_URI}  ^/callpanel [NC]
RewriteCond %{QUERY_STRING} transport=websocket [NC]
RewriteRule ^/(.*) ws://127.0.0.1:4848/$1 [P,L]

# Plain HTTP proxy
ProxyPass        /callpanel/ http://127.0.0.1:4848/callpanel/
ProxyPassReverse /callpanel/ http://127.0.0.1:4848/callpanel/
```

Enable the modules and reload Apache:

```bash
# Debian
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite
sudo systemctl reload apache2

# RHEL/SNG7
# (proxy modules are typically already enabled)
sudo systemctl reload httpd
```

Now you can reach the panel at `http://<your-freepbx-host>/callpanel/`
(no port number).

## Installation — alternative paths

### Install from a local tarball (offline)

If your FreePBX host can't reach GitHub, download the tarball on
another machine, then `scp` it over:

```bash
# on your laptop
gh release download v17.0.1 -R ejosterberg/freepbx-realtime-calls-contacts-panel \
   --pattern '*.tgz' -O callpanel-17.0.1.tgz
scp callpanel-17.0.1.tgz root@your-freepbx:/tmp/

# on FreePBX
sudo tar -xzf /tmp/callpanel-17.0.1.tgz -C /var/www/html/admin/modules/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
sudo fwconsole ma install callpanel -f
sudo fwconsole reload
```

### Install from `main` (latest unreleased)

For testing the bleeding edge before a release:

```bash
cd /tmp
sudo git clone https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel.git
sudo mv freepbx-realtime-calls-contacts-panel /var/www/html/admin/modules/callpanel
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel
sudo fwconsole ma install callpanel -f
sudo fwconsole reload
```

**Don't do this on a production PBX** — `main` may contain in-progress
changes. Always use a tagged release in production.

### Install via FreePBX Module Admin UI (browser upload)

The FreePBX UI's "Upload Modules → Upload Local" path works in
theory but has historically been finicky with unsigned modules.
The CLI path above is more reliable and supplies clearer error
output when things go wrong.

If you want to try the UI:

1. Download the tarball locally
2. FreePBX → Admin → Module Admin → Upload Modules
3. Choose "Type: Local" and select the `.tgz`
4. Click Upload
5. Find "Calls + Contacts Panel" in the module list, check the
   Install radio button, click Process
6. Confirm + Apply Config

If the UI rejects the module as untrusted, use the CLI path
(`fwconsole ma install callpanel -f` — the `-f` is what bypasses
signature checks).

## Uninstall

```bash
sudo fwconsole ma uninstall callpanel
sudo fwconsole ma delete callpanel
sudo fwconsole reload
```

This stops the PM2 process, removes the database tables (the module
has none of its own, but anything FreePBX tracks gets cleaned up),
and removes the module directory.

The module's local config file (`calls-contacts-panel/config.local.json`)
is also removed, so any custom settings (Caller ID prefixes, port
number, etc.) are lost. If you want to preserve them across a
reinstall, back up that file first.

## What's next

- [CONFIGURATION.md](CONFIGURATION.md) — explanation of every admin
  panel setting + access control
- [USAGE.md](USAGE.md) — end-user guide for the panel UI
- [PROVISIONING-YEALINK.md](PROVISIONING-YEALINK.md) — point a Yealink
  IP phone at the phonebook XML
- [PROVISIONING-FANVIL.md](PROVISIONING-FANVIL.md) — same for Fanvil
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — what to do when the
  install or runtime fails
- [UPGRADE.md](UPGRADE.md) — moving from one panel version to the next
- [FAQ.md](FAQ.md) — common questions
