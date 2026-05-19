# Configuration

After [installation](INSTALL.md), the panel is reachable at
`http://<host>:4848/callpanel/` and has sane defaults. This page
explains every setting + how access control works.

## Where settings live

| Setting source | Path | Edited via |
|---|---|---|
| **Defaults (read-only)** | `/var/www/html/admin/modules/callpanel/calls-contacts-panel/config.default.json` | (do not edit — overwritten on install) |
| **Local overrides** | `/var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json` | FreePBX admin UI (Admin → Calls + Contacts Panel), OR edit the JSON directly |
| **FreePBX DB connection** | `/etc/freepbx.conf` | Set by FreePBX, do not edit |
| **Asterisk Manager (AMI)** | `/etc/asterisk/manager.conf` | Set by FreePBX, do not edit |

After editing `config.local.json` directly, restart the panel:

```bash
sudo fwconsole pm2 --restart callpanel
```

(The admin UI does this for you when you click Submit with a
"Restart" option chosen.)

## Admin UI walkthrough

Open FreePBX → **Admin → Calls + Contacts Panel**. You'll see:

### Service Status

| Option | What it does |
|---|---|
| **Start** | Starts the PM2 process if it's not running. |
| **Stop** | Stops the PM2 process. The panel will be unreachable while stopped. |
| **Restart** | Stops then starts. Use after editing settings that need a reload. |
| **Don't change** | (default) Apply other config changes without restarting. |

The current status (Running/Not Running, in green/red) is shown to
the right.

### Caller ID Prefixes

Comma-separated list of area codes to try when matching incoming
caller IDs against your saved contacts.

**Why this exists:** if a contact is saved as `5550100` (no area
code) but a call comes in as `+1212-555-0100`, naive string matching
wouldn't link them. Adding `+1212,1212,212` as prefixes makes the
panel strip those when comparing — so it finds the match.

**Example:**
```
+491234,01234
```
(For a German user whose area code is +49 12 34 / 0 12 34.)

Leave blank to disable prefix-stripping.

### Caller ID Resolve Length

Default: **6**. Minimum: **2**.

Minimum digit count required to attempt a CID-to-contact match.
Numbers shorter than this length are passed through as-is (no
lookup attempted). Prevents very short internal extension numbers
(like `100`) from accidentally matching against contacts whose
numbers happen to end in those digits.

### HTTP Port

Default: **4848**. Valid range: 1024–65535.

The port the panel's backend listens on. Changing requires a
restart. If you reverse-proxy the panel behind Apache (see
[INSTALL.md → Apache reverse proxy](INSTALL.md#optional-apache-reverse-proxy)),
make sure the proxy snippet's `127.0.0.1:<port>` matches.

### Check for Active Calls Interval (ms)

Default: **1000**. Minimum: **200**.

How often the panel polls Asterisk's AMI for the current call list
(`CoreShowChannels` action). Lower = snappier UI but more CPU. The
default 1-second poll is fine for most home/small-business loads
(< 100 concurrent calls). Bump to 200 ms only if you really need
sub-second responsiveness; bump to 5000 ms if your PBX is busy and
you want to reduce overhead.

### Check for Call Logs Interval (ms)

Default: **3000**. Minimum: **500**.

How often the panel polls the Asterisk CDR database for new call
log entries. Lower = call history updates faster after hangup.
The 3-second default trades a little freshness for less DB load.

### Check for Externally-Changed Phonebook Entries Interval (ms)

Default: **180000** (3 minutes). Minimum: **2000**.

How often the panel re-reads FreePBX's `contactmanager_*` tables
to pick up changes made outside the panel (e.g. another admin
adding a contact via FreePBX → Admin → Contact Manager). If you
expect to edit contacts only through the panel itself, this can be
set very high (e.g. 30 minutes). Lower it if you're using the
panel concurrently with external contact-management tools.

### Submitting changes

Click **Submit** at the top of the page. Any setting changes
write to `config.local.json`. If you also selected a Service
Status change (Start/Stop/Restart), that runs immediately.

Some settings changes also auto-trigger a restart — specifically,
any change to **HTTP Port** or the **check interval** values forces
a restart so the backend picks them up.

## Access control

The panel **does not have its own user database**. It authenticates
against FreePBX's User Manager (`userman` module), the same source
that gates the User Control Panel (UCP).

When a user logs in:

1. The panel checks their username + password against
   `userman_users` (bcrypt-verified).
2. If credentials are valid, it checks their permissions in
   `userman_users_settings`:
   - **`pbx_admin = '1'`** → full access (recommended for admin users)
   - OR **`pbx_modules`** includes both `cdr` AND `contactmanager`
     → full access (recommended for non-admin staff who need to
     see/edit contacts and call history)
3. If both checks pass, the WebSocket connection is allowed.
4. The panel uses the user's `default_extension` (from
   `userman_users`) to attribute outbound "Make Call" requests.

### Giving a user access

In FreePBX:

1. **Admin → User Management** (or **Admin → User Manager** depending
   on FreePBX version)
2. Edit the user
3. Go to the **UCP** tab
4. Either:
   - Tick **PBX Admin** (gives full panel access), OR
   - Under **Allowed Modules**, tick **CDR Reports** and **Contact
     Manager**
5. Make sure the user has a **Default User (Extension)** set on the
   main tab — this is the extension used when they click "Make
   Call" in the panel.
6. Save.

The user can now log in to the panel with their User Manager
credentials.

### Revoking access

Untick PBX Admin AND remove either CDR Reports or Contact Manager
from their Allowed Modules. The next time they try to authenticate
(WebSocket reconnect), they'll be rejected. Sessions already open
remain valid until they refresh.

### Audit considerations

- Authentication is logged to the PM2 stdout log
  (`/var/lib/asterisk/.pm2/logs/callpanel-out.log` on FreePBX 16,
  `/home/asterisk/.pm2/logs/callpanel-out.log` on FreePBX 17). The
  username appears on connection.
- WebSocket auth uses credentials sent at handshake time — they
  travel as part of the Socket.IO auth payload (which is JSON,
  visible in plaintext over HTTP). **Run behind HTTPS in
  production** (terminate TLS at Apache and use the reverse-proxy
  snippet).
- There's no per-user feature gating beyond "can log in or not".
  Any logged-in user with panel access can see all calls and all
  contacts. If you need finer-grained access, file an issue.

## Network-level security

The panel binds to `0.0.0.0:4848` by default — reachable from any
IP that can route to your PBX. In a typical home/small-business
deployment this is fine because the PBX itself is behind a NAT or
firewall. In a hosted environment, you should:

- Block port 4848 inbound at your firewall, **and**
- Reverse-proxy via Apache on port 80/443 instead (see
  [INSTALL.md → Apache reverse proxy](INSTALL.md#optional-apache-reverse-proxy)).

The reverse-proxy approach forces all panel traffic through
FreePBX's existing Apache config, which means TLS, fail2ban, and
any other access controls you've layered onto port 443 apply to
the panel too.

A future version may add an option to bind the backend to
`127.0.0.1` only (forcing the reverse-proxy path); this is
tracked in
[the security audit](../specs/security/audit-2026-05-19.md).

## Editing config.local.json by hand

Sometimes it's faster to edit the JSON than click through the UI.
The file lives at:

```
/var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
```

Schema (all keys optional; missing keys fall back to defaults):

```json
{
  "callerIdPrefixes": ["+491234", "01234"],
  "callerIdResolveLength": 6,
  "httpPort": 4848,
  "activeCallsCheckIntervalMs": 1000,
  "callLogsCheckIntervalMs": 3000,
  "phonebookCheckIntervalMs": 180000
}
```

After editing, restart:

```bash
sudo fwconsole pm2 --restart callpanel
```

Ownership must remain `asterisk:asterisk` — if you edited as root:

```bash
sudo chown asterisk:asterisk /var/www/html/admin/modules/callpanel/calls-contacts-panel/config.local.json
```
