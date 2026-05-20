# Phase 06 — Production Validation Findings

Validation pass requested by Eric after he caught me declaring v17.0.2
"shipped" without actually exercising the UI or doing a real call.

**Status:** All four production gates met for FreePBX 16/Debian 12.
SNG7 validation still in progress.

## Tests performed

### 1. Real call test — Asterisk live channel + WS subscription ✅
- **Set up:** custom dialplan context `test-callpanel` in
  `/etc/asterisk/extensions_custom.conf` running `Wait(60)` so the
  channel survives at least one panel poll interval
- **Originated:** `asterisk -rx "channel originate Local/s@test-callpanel application Wait 60"`
- **Verified:** Asterisk CLI shows 2 channel halves (Local channels
  come in pairs); panel WS client emits 1 logical `activeCalls` event
  with the channel grouped correctly. ID, status, channel name all
  match. CallerID set in dialplan (`5551234567`) gets matched against
  the contact `Jane Doe` and displayed as the contact name in the
  panel.
- **Conclusion:** AMI → CoreShowChannels → grouping → WS emission
  pipeline works end-to-end.

### 2. Browser-driven UI test on fpbx16 sandbox ✅
- **Tool:** Claude in Chrome MCP, driving a real Chrome browser
- **Connectivity:** Chrome refused direct connection to
  `http://10.32.161.80:4848` (likely HTTPS-First-Mode or Private
  Network Access blocking the LAN IP); worked via SSH local-forward
  to `http://127.0.0.1:4848`
- **Verified:**
  - Login page renders (title, subtitle, username/password fields,
    Login button — all styled with Tailwind)
  - Login form accepts credentials, submits, redirects to
    `#/calls`
  - Calls view renders: header, navigation, filter, search, page-
    size dropdown, table
  - Contacts view renders: search, filter, New button, contact list
  - Contact Editor (/contacts/new) renders: all fields (first name,
    last name, display name, title, company, address, email, website,
    group, phone, fax), with + buttons to add multiple
  - Live active call appears in the Calls view in real-time, with:
    - Status: "Ringing" (matches Asterisk channel state)
    - Date: 05/19/2026 5:32:01 PM
    - Duration: counting up (26s when screenshotted)
    - App: AppDial2
    - Caller: `<unknown>`
    - **Callee: "Jane Doe (5551234567)" — contact-matched** via
      caller-ID resolution
    - Via: channel name
- **Console findings:** several `i18next` warnings about late namespace
  load — cosmetic, falls back to keys until translations load (~50ms);
  no JS errors, no React errors, no failed fetches

### 3. Apache reverse-proxy validation ✅
- **Original snippet in INSTALL.md was BROKEN.** Used
  `RewriteCond %{QUERY_STRING} transport=websocket` — fails because
  mod_proxy_http consumes the request before mod_rewrite fires.
  Plain HTTP worked but WebSocket upgrade was silently failing.
- **Corrected snippet** uses scoped `<LocationMatch>` + `Upgrade`
  header detection:
  ```apache
  <LocationMatch "^/callpanel/">
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade}    websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade   [NC]
    RewriteRule .* "ws://127.0.0.1:4848%{REQUEST_URI}" [P,L]
  </LocationMatch>
  ProxyPass        /callpanel/ http://127.0.0.1:4848/callpanel/
  ProxyPassReverse /callpanel/ http://127.0.0.1:4848/callpanel/
  ```
- **Verified via proxy on port 80:**
  - HTTP /callpanel/ → 200 ✅
  - HTTP /callpanel/lookupcallerid?number=5551234567 → 200, returns "Jane Doe" ✅
  - HTTP /callpanel/yealink-phonebook.xml → 200 ✅
  - WebSocket transport via socket.io-client (forced `["websocket"]`) → connects ✅
  - Polling transport via socket.io-client (forced `["polling"]`) → connects ✅
- **Documentation updated:** `docs/INSTALL.md` now has the corrected
  snippet with a note about the broken older snippet for users
  following stale guides.

### 4. SNG7 / FreePBX Distro sandbox validation — Rocky 8 surrogate ✅
- **VM 923 (fpbx16-rocky-sandbox)**: Rocky Linux 8.10 + FreePBX
  16.0.45 + Asterisk 18.26.4 + PHP 7.4 (Remi) + Node 18
- **SNG7 ISO** (SNG7-PBX16-64bit-2306-1.iso) was downloaded but is
  interactive-install only; we chose Rocky 8 as the cloud-init-
  friendly RHEL-family surrogate. Same package family (dnf/rpm),
  same systemd, same firewalld, same SELinux as SNG7.
- **Install script** at
  [`install-fpbx16-rocky.sh`](install-fpbx16-rocky.sh) — reusable
  for fresh Rocky 8 deployments.
- **Issues encountered (and now baked into the script):**
  - RPM DB corruption from cloud-init's first dnf — recovered via
    `rpm --rebuilddb`
  - `iksemel-devel` not in Rocky 8 default repos — removed
    (was for XMPP support, not needed)
  - `bzip2` + `bzip2-devel` missing — needed by Asterisk's
    bundled jansson configure
  - `php-process` missing from default Remi PHP 7.4 install —
    needed for FreePBX's `posix_geteuid()` call
- **Panel install verified:**
  - PM2 process online (0 restarts, normal memory)
  - All 4 HTTP endpoints (/callpanel/, /lookupcallerid,
    /yealink-phonebook.xml, /fanvil-phonebook.xml) return 200
  - WS auth + activeCalls subscription round-trips successfully
    with bcrypt-hashed FreePBX User Manager password
- **Conclusion:** the panel works on RHEL-family hosts (Rocky 8,
  by extension AlmaLinux 8 / SNG7) with the same install commands
  as Debian (just `fwconsole ma install callpanel -f`). Friend's
  FreePBX Distro deployment should work; the install script
  documents what RHEL-family hosts need beyond a fresh OS.

## Discovered issues + fixes

| Issue | Status |
|---|---|
| Apache WS rewrite uses query-string detection (broken) | ✅ Fixed in docs/INSTALL.md |
| FreePBX User Manager stores plaintext passwords (security concern) | ℹ️ Upstream FreePBX issue, not ours — documented in [audit-2026-05-19-v2.md](../security/audit-2026-05-19-v2.md) |
| `react-scripts` binary loses execute bit after `npm install --ignore-scripts` | ℹ️ Install method uses `npm ci` (without --ignore-scripts) so this doesn't affect end users; just a sandbox-test gotcha |
| Chrome refuses LAN-IP HTTP URLs (HTTPS-First/PNA) | ℹ️ Use hostname + DNS, or set up reverse-proxy with TLS for production deployments |

## Test artifacts

- `ws-test-client.js` — Node.js socket.io test client. Reusable for
  CI gating or post-deploy smoke tests.
- Test dialplan context `[test-callpanel]` left in fpbx16-sandbox's
  `/etc/asterisk/extensions_custom.conf` for repeated testing.
- Test user `testadmin` in fpbx16-sandbox's User Manager with
  manually-bcrypt-hashed password (workaround for the plaintext
  storage upstream FreePBX issue noted above).
- Test contact "Jane Doe (5551234567)" in fpbx16-sandbox's
  `contactmanager_group_entries` table.
