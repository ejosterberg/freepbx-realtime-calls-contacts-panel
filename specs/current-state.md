# Current state — 2026-05-19

## Status table

| Phase | Description | Status |
|---|---|---|
| **phase-01** | Baseline validate on FreePBX 16 sandbox (friend-match) | ✅ Complete (2026-05-19) |
| **phase-02** | Baseline validate on FreePBX 17 sandbox (latest) | ✅ Complete (2026-05-19) |
| **phase-03** | Forward-port module to FreePBX 17 | ✅ Complete (2026-05-19) |
| **phase-04** | Ship to GitHub as v17.0.0 | 🟡 Committing now |

## What exists

**Repo:** Cloned from `ejosterberg/freepbx-realtime-calls-contacts-panel`
into this directory on 2026-05-19. The fork was created at some prior
point but never modified — it tracks upstream's archived state from
2022-01-15.

**Codebase as inherited:**
- PHP module wrapper: `Callpanel.class.php` (403 lines), `module.xml`,
  `views/main.php`, install/uninstall stubs
- NodeJS backend: `calls-contacts-panel/` — Node 16, TypeScript 4.5,
  Express 4, socket.io 4, mysql2 — ~80 KB source
- React frontend: `calls-contacts-panel/frontend/` — React 17,
  react-scripts 5 (CRA, deprecated), Tailwind 3.0 — ~64 KB source
- Total ~166 KB code

**Module declares compat:** FreePBX 16.0 only (per module.xml).
Depends on: contactmanager ge 16.0.17, cidlookup ge 16.0.5, pm2 ge 13.0.3.8.

## Tech-debt inventory (carried from upstream)

- Node 16 — EOL since 2023
- axios 0.24 — pre-1.0, has known CVEs in this range
- React 17 — supported but old
- react-scripts 5 (CRA) — deprecated by Meta in 2025
- Jest 27 — current is 29
- TypeScript 4.5 → 5.x available
- `calls-contacts-panel/package.json:51` declares MIT — inconsistent
  with project AGPLv3 license (fix in phase-01)
- `frontend/package.json` has no license field at all (fix in phase-01)

## Schema

No DB schema of its own. Reads from FreePBX's existing MariaDB tables
(asterisk DB, contactmanager tables). Writes via FreePBX module APIs.

## Sandbox infrastructure

| VMID | Name | Stack | Status |
|---|---|---|---|
| 921 | fpbx16-sandbox | Debian 12 / FreePBX 16.0.45 / Asterisk 18.26.4 | ✅ Healthy, panel installed + running |
| 922 | fpbx17-sandbox | Debian 12 / FreePBX 17.0.28 / Asterisk 22.8.2 | ✅ Healthy, panel installed + running |

Both on pmvm1. IPs TBD post-cloud-init.

## Friend's target environment

- FreePBX 16.0.45
- Asterisk 18.9
- pjsip
- Host OS unknown (likely FreePBX Distro 12.7 SNG7-based, or rocky-based 12.8)

The fpbx16-sandbox is the surrogate environment for friend validation.
Behavior should match because the module is PHP+JS that talks to
FreePBX's MariaDB and AMI socket — host OS doesn't matter much.

## Updated metrics

- Source files: ~166 KB total
- PHP files: 4
- TypeScript files: ~30 (backend + frontend combined)
- Test files: 6 (.test.ts)
- No CI configured yet
- No SonarQube project yet
