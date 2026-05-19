# Troubleshooting

When things go wrong, this is the first place to look.

## Where the logs live

| Log | Path (FreePBX 16) | Path (FreePBX 17) |
|---|---|---|
| Panel stdout | `/var/lib/asterisk/.pm2/logs/callpanel-out.log` | `/home/asterisk/.pm2/logs/callpanel-out.log` |
| Panel stderr | `/var/lib/asterisk/.pm2/logs/callpanel-error.log` | `/home/asterisk/.pm2/logs/callpanel-error.log` |
| FreePBX | `/var/log/asterisk/freepbx.log` | same |
| Asterisk | `/var/log/asterisk/full` | same |
| Apache | `/var/log/apache2/error.log` (Debian) or `/var/log/httpd/error_log` (RHEL) | same |

You can also tail panel logs via FreePBX's wrapper:

```bash
sudo fwconsole pm2 --log=callpanel
sudo fwconsole pm2 --log=callpanel --lines=100
```

## Diagnostic commands

Quick health-check sweep:

```bash
# Is the panel running?
sudo fwconsole pm2 --list | grep callpanel

# Are HTTP endpoints responding?
for ep in / /lookupcallerid?number=1234 /fanvil-phonebook.xml /yealink-phonebook.xml; do
  curl -sf -o /dev/null -w "/callpanel${ep}: HTTP %{http_code}\n" "http://localhost:4848/callpanel${ep}"
done

# Is the WebSocket endpoint responding?
curl -s 'http://localhost:4848/callpanel/socket.io/?EIO=4&transport=polling' | head -1
# Expected: 0{"sid":"...","upgrades":["websocket"],...}

# Is FreePBX seeing the module?
sudo fwconsole ma list | grep callpanel

# Is the AMI accessible?
sudo asterisk -rx 'manager show connected'

# Recent panel errors?
sudo tail -50 /var/lib/asterisk/.pm2/logs/callpanel-error.log 2>/dev/null \
  || sudo tail -50 /home/asterisk/.pm2/logs/callpanel-error.log
```

## Common problems

### Install fails: "Cron line added didn't remain in crontab"

**You're on a fresh Debian 12 install that doesn't have `cron`.**
FreePBX's framework install needs it.

```bash
sudo apt-get install -y cron at
sudo systemctl enable --now cron
# Re-run the FreePBX install or fwconsole reload
```

(This only affects fresh Debian 12 installs that didn't include
cron — typical FreePBX Distro installs ship with it.)

### Install fails: "tsc: not found" or "Backend build failed"

**The TypeScript compiler isn't reachable** during the build step.
Usually means `npm install` ran without devDependencies.

Versions prior to v17.0.1 had this bug; the v17.0.x install method
now uses `npm ci --include=dev` explicitly. If you're seeing this
on the current version:

```bash
cd /var/www/html/admin/modules/callpanel/calls-contacts-panel
sudo -u asterisk npm ci --include=dev
sudo -u asterisk npm run build
cd frontend
sudo -u asterisk npm ci --include=dev
sudo -u asterisk npm run build
sudo fwconsole pm2 --restart callpanel
```

### Install fails: "ESLint couldn't find the config 'react-app'"

**Lint runs at install-time before frontend deps install.** Affected
versions prior to v17.0.1 had `prebuild: npm run lint` on the
backend, which triggered eslint that needed react-scripts (a
frontend devDep). Removed in v17.0.1.

Fix: upgrade to v17.0.1 or later. If you're stuck on an older
version, edit
`/var/www/html/admin/modules/callpanel/calls-contacts-panel/package.json`
and remove the `"prebuild": "npm run lint",` line, then re-run
the install.

### Panel won't start: "ECONNREFUSED ::1:3306"

**Node 18+ resolves `localhost` to IPv6 first**, but MariaDB only
listens on IPv4 by default. v17.0.1 patches the panel to coerce
`AMPDBHOST=localhost` → `127.0.0.1` automatically.

If you're seeing this:

- Confirm you're on v17.0.1 or later (`grep version
  /var/www/html/admin/modules/callpanel/module.xml`)
- If yes, check `/etc/freepbx.conf` — if `AMPDBHOST` is something
  other than `localhost`, the patch doesn't fire. Manually edit
  `database.ts` to force `127.0.0.1`, OR configure MariaDB to
  listen on `::1` too:

```bash
# Quick MariaDB IPv6 enable
sudo sed -i 's/^bind-address.*/bind-address = ::/' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
```

### Panel won't start: "Access denied for user ''@'localhost' (using password: NO)"

**The freepbx.conf parser isn't extracting AMPDBUSER**. Affected
versions prior to v17.0.1 had a regex that only matched
single-quoted values — FreePBX 17 writes double-quoted.

Fix: upgrade to v17.0.1 or later.

### Panel won't start: "Cannot read properties of undefined (reading 'secret')"

**The AMI user lookup is failing.** Affected versions prior to
v17.0.1 hardcoded the AMI user as `admin` — FreePBX 16+ uses a
random hashed name. v17.0.1 finds the AMI user dynamically.

Fix: upgrade to v17.0.1.

Workaround (if you can't upgrade): hardcode an admin user in
`/etc/asterisk/manager_custom.conf`:

```ini
[admin]
secret = your-strong-password-here
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,log,verbose,command,agent,user,config,command,dtmf,reporting,cdr,dialplan,originate,message
write = system,call,log,verbose,command,agent,user,config,command,dtmf,reporting,cdr,dialplan,originate,message
```

Then `sudo fwconsole reload`. (The auto-detection in v17.0.1+ is
preferred — this workaround creates a manager user that doesn't
get rotated automatically.)

### Panel won't start: "Creation of dynamic property ... is deprecated"

**PHP 8.2 strict mode rejects un-declared properties.** v17.0.1
declares all properties at class scope.

Fix: upgrade to v17.0.1.

### PM2 says callpanel is "errored" with restart count climbing

PM2 retries failing processes up to 10 times then gives up. Each
restart is recorded in the log.

Steps:

1. Check the error log:
   ```bash
   sudo tail -50 /var/lib/asterisk/.pm2/logs/callpanel-error.log
   ```
2. Look for the FIRST error (PM2 may have retried + logged multiple
   times — the first crash tells you the root cause)
3. Match against the common problems above
4. After fixing, reset the restart counter:
   ```bash
   sudo fwconsole pm2 --restart callpanel
   ```

### Frontend loads but stays on a blank/loading screen forever

**WebSocket handshake is failing.** The frontend connects to
`<host>:4848/callpanel/socket.io/...` for live data; if that
can't complete, the UI stalls.

Check:

```bash
curl -s 'http://localhost:4848/callpanel/socket.io/?EIO=4&transport=polling'
# Expected output starts with: 0{"sid":"...
```

If that works locally but the browser still hangs, the issue is
between browser and server:

- **Apache reverse-proxy WebSocket rule missing** — see
  [INSTALL.md → Apache reverse proxy](INSTALL.md#optional-apache-reverse-proxy).
  The `RewriteRule ... ws://...` line is what makes WebSocket
  upgrades work through the proxy.
- **Firewall blocks port 4848** — if browsing directly without
  proxy, the firewall must allow 4848 inbound from the client.
- **Browser uses a different scheme than the proxy expects** —
  HTTPS → ws:// is blocked by Mixed Content. If you've configured
  HTTPS for FreePBX, the proxy must use `wss://` not `ws://`.

### Login fails: "authentication failed"

Check, in this order:

1. **Username/password correct in FreePBX User Manager?**
   ```bash
   sudo mysql -e 'SELECT username FROM asterisk.userman_users' \
     -u root
   ```
2. **User has either pbx_admin=1 OR pbx_modules includes
   contactmanager + cdr?**
   ```bash
   sudo mysql -e "
     SELECT u.username, s.\`key\`, s.val
     FROM asterisk.userman_users u
     JOIN asterisk.userman_users_settings s ON s.uid=u.id
     WHERE s.\`key\` IN ('pbx_admin','pbx_modules')
     AND u.username='THE_USERNAME'" -u root
   ```
3. **bcrypt module loaded on the panel's Node?** If not, the
   `bcrypt.compare()` call throws. Reinstall the panel to
   re-run npm ci.

### Active calls don't appear

**AMI events aren't reaching the panel** OR **the poll isn't
finding channels**.

Steps:

1. Confirm AMI connected:
   ```bash
   sudo tail -10 /var/lib/asterisk/.pm2/logs/callpanel-out.log
   ```
   You should see `[AMI] asterisk manager interface connected as <user>`.

2. Trigger a long-running call so the 1-second poll catches it:
   ```bash
   sudo asterisk -rx 'channel originate Local/100@app-blackhole application Wait 30'
   ```
   The panel should display this call within 2 seconds.

3. Verify with Asterisk CLI:
   ```bash
   sudo asterisk -rx 'core show channels concise'
   ```
   If channels exist here but not in the panel, the panel's poll
   isn't connecting to AMI. Check `manager.conf` for the user the
   panel logged in as and verify the `read` field includes
   `system,call,verbose,reporting,cdr,dialplan,originate`.

### Contacts don't sync with FreePBX Contact Manager

**Stale view, not actually broken.** The panel polls
`contactmanager_*` tables every 3 minutes by default. Edits made
in FreePBX Admin → Contact Manager will show up after the next
poll.

Force an immediate refresh:

```bash
sudo fwconsole pm2 --restart callpanel
```

Or lower the
[Phonebook Check Interval](CONFIGURATION.md#check-for-externally-changed-phonebook-entries-interval-ms)
in the admin UI.

### Make Call originates but the destination phone doesn't ring

Two-step originate works in two phases:

1. Panel originates a call to your extension first
2. When you pick up your extension, the dialplan completes the
   call to the destination

If step 2 fails:

- **Outbound route doesn't match the destination pattern** — try
  the same number from your desk phone; if that fails too, fix the
  outbound route, not the panel
- **`from-internal` context doesn't have a matching extension**
  — unusual but possible if you've heavily customized your
  dialplan; check `extensions_*.conf` for whether the destination
  is reachable from the `from-internal` context

Test the originate directly via Asterisk CLI:

```bash
sudo asterisk -rx 'channel originate Local/YOUREXTENSION@from-internal extension DESTINATION@from-internal'
```

If that works but the panel button doesn't, look at
`callpanel-error.log` for the AMI Originate error message.

### "Permission denied" writing config.local.json

The config file must be owned by the asterisk user:

```bash
sudo chown asterisk:asterisk /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
sudo chmod 644 /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
```

Also make sure the parent directory is writeable:

```bash
sudo chown asterisk:asterisk /var/www/html/admin/modules/callpanel/calls-contacts-panel/
```

This usually only matters if you've manually edited config files
as root.

## Resetting to factory defaults

If the panel is in a bad state and you just want it back to a
known-good install:

```bash
sudo fwconsole ma uninstall callpanel
sudo fwconsole ma delete callpanel
sudo rm -rf /var/www/html/admin/modules/callpanel
sudo fwconsole reload
# then re-install per INSTALL.md
```

This wipes the `config.local.json` too — you'll lose any
customizations. To preserve settings:

```bash
sudo cp /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json /tmp/config.local.json.bak
# ... uninstall + reinstall ...
sudo cp /tmp/config.local.json.bak /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
sudo chown asterisk:asterisk /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
sudo fwconsole pm2 --restart callpanel
```

## Reporting bugs

Before opening an issue, please gather:

1. **Version info:**
   ```bash
   sudo fwconsole --version
   sudo asterisk -rx 'core show version' | head -1
   cat /etc/os-release | head -2
   php --version | head -1
   node --version
   grep -A1 '<version>' /var/www/html/admin/modules/callpanel/module.xml | head -2
   ```

2. **Module status:**
   ```bash
   sudo fwconsole ma list | grep -E "callpanel|contactmanager|cidlookup|pm2|userman"
   sudo fwconsole pm2 --list | grep callpanel
   ```

3. **Last 50 lines of error log:**
   ```bash
   sudo tail -50 /var/lib/asterisk/.pm2/logs/callpanel-error.log \
     || sudo tail -50 /home/asterisk/.pm2/logs/callpanel-error.log
   ```

File issues at
[github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/issues](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/issues).
