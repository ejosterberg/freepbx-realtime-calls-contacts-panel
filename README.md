# FreePBX Realtime Calls & Contacts Panel

A realtime web panel for FreePBX to view active calls, browse call logs,
and manage contacts.

Suited for use at home and small businesses.

> **Fork notice — read this if you're coming from upstream.** This is a
> maintained fork of [adroste/freepbx-realtime-calls-contacts-panel][upstream]
> (upstream was archived 2022-01-15). This fork adds **FreePBX 17
> compatibility** alongside the original FreePBX 16 support, fixes the
> install-time build step that upstream omitted, and patches PHP 8.x
> warnings. See [CHANGES.md](CHANGES.md) for the full delta.

[upstream]: https://github.com/adroste/freepbx-realtime-calls-contacts-panel

## Compatibility

| FreePBX | Asterisk | PHP | Node | Status |
|---|---|---|---|---|
| **17.0** | 22.x | 8.2 | 18+ | ✅ Supported (this fork) |
| **16.0** | 18.x / 20.x | 7.4 | 18+ | ✅ Supported (original target) |

Tested on Debian 12 (bookworm) for both FreePBX versions. SNG7 (the
official FreePBX Distro for v16) is untested but should work.

## Features

- **Realtime Call Monitoring** — active calls + call logs
- **Better CallerID Lookup** — integrates with FreePBX CallerID Lookup;
  custom REST endpoint; matches numbers with/without area codes
- **Contact Management** — wraps FreePBX ContactManager; create/edit/delete
  with a modern UI; save unknown numbers from call logs as new contacts
- **Click-to-call** — originate calls from any extension to any number
- **i18n** — English, German; new languages straightforward to add
- **Phonebook generation** — produces Yealink and Fanvil compatible XMLs
- **PM2-managed backend service** — managed via FreePBX's `pm2` module

## Screenshots

![](./screenshots/calls.png)
![](./screenshots/contacts.png)
![](./screenshots/makecall.png)
![](./screenshots/contactviewer.png)
![](./screenshots/contacteditor.png)

## Install

### Prerequisites

These FreePBX modules must be installed first (Module Admin):

- `contactmanager` ≥ 16.0.17
- `cidlookup` ≥ 16.0.5
- `pm2` ≥ 13.0.3.8

Plus Node.js ≥ 18 on the host (FreePBX 17's `pm2` module bundles a
compatible Node; for FreePBX 16, install Node 18+ from NodeSource).

### Steps

1. Download the latest release tarball:
   `https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest`
2. FreePBX → Admin → Module Admin → Upload Modules → Upload Local
3. Select the tarball and click **Install**
4. **Apply Config** (be patient — the first install runs `npm ci` and
   builds both backend and frontend; this can take 5–10 minutes on a
   modest VM)
5. FreePBX → Admin → **Calls + Contacts Panel** to verify status

![](./screenshots/fpbxadminview.png)

### Access the panel

The backend serves the React frontend on port **4848** by default:

```
http://<your-freepbx-host>:4848/callpanel/
```

To put it behind FreePBX's Apache (so it shares port 80/443), add a
reverse-proxy snippet to `/etc/apache2/conf-enabled/freepbx.conf`:

```apache
ProxyPass        /callpanel/ http://127.0.0.1:4848/callpanel/
ProxyPassReverse /callpanel/ http://127.0.0.1:4848/callpanel/
RewriteCond %{REQUEST_URI} ^/callpanel [NC]
RewriteCond %{QUERY_STRING} transport=websocket [NC]
RewriteRule ^/(.*) ws://127.0.0.1:4848/$1 [P,L]
```

Then `a2enmod proxy proxy_http proxy_wstunnel rewrite && systemctl reload apache2`.

## Advanced usage

**Phonebook URLs** (for IP phone provisioning):

- Fanvil: `http://<host>:4848/callpanel/fanvil-phonebook.xml`
- Yealink: `http://<host>:4848/callpanel/yealink-phonebook.xml`

**Caller ID prefixes** — go to FreePBX → Admin → Calls + Contacts Panel →
Caller ID Prefixes and add area codes like `+491234,01234`. Numbers
saved with or without the area code will both match incoming caller IDs.

**Caller ID Lookup source** — create a CallerID Lookup Source like this:

![](./screenshots/calleridlookupsource.png)

---

# License

**AGPL-3.0-only** — inherited from upstream. See [LICENSE](LICENSE)
and [CHANGES.md](CHANGES.md). Derivatives must remain AGPLv3; if you
run this as a network service for users beyond yourself, §13 requires
offering source to those users.

---

# Development

## Project structure

```
.                                  --- FreePBX module wrapper (root dir + files)
├── Callpanel.class.php            --- BMO class (PHP glue to FreePBX)
├── LICENSE                        --- AGPLv3
├── CHANGES.md                     --- modifications from upstream (per AGPL §5(a))
├── README.md                      --- this file
├── module.xml                     --- FreePBX module manifest
├── install.php / uninstall.php    --- module lifecycle stubs
├── page.callpanel.php             --- entry point for the admin view
├── specs/                         --- spec-driven workflow (planning artifacts)
├── views/main.php                 --- admin config page UI
├── screenshots/                   --- README images
└── calls-contacts-panel           --- the actual app (NodeJS + React)
    ├── LICENSE                    --- AGPLv3
    ├── package.json               --- backend (TypeScript + Express + socket.io)
    ├── pm2.config.js              --- PM2 process descriptor
    ├── config.default.json
    ├── src                        --- backend source
    └── frontend                   --- React frontend (Tailwind + i18next)
        ├── package.json
        └── src
```

## Adding a language

1. `cd calls-contacts-panel/frontend/public/locales`
2. Create a new folder with the BCP-47 tag (e.g. `fr`, `es`, `it`)
3. Copy `en/translation.json` into it and translate
4. Rebuild the frontend (`npm run build`) — open a PR

## Dev environment

### Backend

Forward MySQL (3306) and Asterisk AMI (5038) from your FreePBX instance
to your dev machine:

```bash
ssh -L 3306:127.0.0.1:3306 \
    -L 5038:127.0.0.1:5038 \
    root@your-freepbx
```

Then:

```bash
cd calls-contacts-panel
mkdir -p dev-resources
scp root@your-freepbx:/etc/freepbx.conf dev-resources/
scp root@your-freepbx:/etc/asterisk/manager.conf dev-resources/
npm install
npm run dev:service           # ts-node directly
# or
npm run build:watch &         # tsc -w
npm run dev:service:build     # nodemon on build/
```

### Frontend

```bash
cd calls-contacts-panel/frontend
npm install
npm run start                 # react-scripts dev server on :3000
```

## Specs (spec-kit workflow)

This project follows a spec-driven workflow — see [specs/README.md](specs/README.md).
Read `specs/constitution.md` first, then `specs/current-state.md` and
`specs/handoff.md` before making changes.

# Credits

- Original module: **Alexander Droste** (adroste) — 2021–2022
- Fork maintainer: **Eric Osterberg** (ejosterberg) — 2026–

See [CHANGES.md](CHANGES.md) for the full modification history.
