# Current state — updated 2026-05-20

## Status table

| Phase | Description | Status |
|---|---|---|
| **phase-01** | Baseline validate on FreePBX 16 sandbox (friend-match) | ✅ Complete (2026-05-19) |
| **phase-02** | Baseline validate on FreePBX 17 sandbox (latest) | ✅ Complete (2026-05-19) |
| **phase-03** | Forward-port module to FreePBX 17 | ✅ Complete (2026-05-19) |
| **phase-04** | Ship to GitHub as v17.0.0 | ✅ Complete (2026-05-19) — v17.0.0 thru v17.0.2 |
| **phase-06** | Production-quality validation (v17.0.3) | ✅ Complete (2026-05-19) |
| **phase-05** | Modernization (CRA → Vite, jest 27 → 29, React 17 → 18, etc.) | ⏸ Deferred — see [phase-05/IMPROVEMENTS.md](phase-05-modernization/IMPROVEMENTS.md) |

## Latest release

**v17.0.3** — 2026-05-19. Released artifact at
[`callpanel-17.0.3.tgz`](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/download/v17.0.3/callpanel-17.0.3.tgz)
(1.86 MB).

Validated end-to-end (Debian 12 + Rocky 8):

- PM2 process online + stable
- All 4 HTTP endpoints return 200
- WebSocket auth + real-time events work
- AMI active-call detection works (channel grouping correct, status,
  duration, channel name)
- Caller-ID contact matching works ("Jane Doe (5551234567)" displayed
  for matched call)
- Contact CRUD round-trips through FreePBX Contact Manager
- Apache reverse-proxy works for HTTP + WebSocket + polling fallback
- npm audit: 0 critical CVEs
- SonarQube: 0 vulnerabilities (A rating)

## What exists in this repo

- **PHP module wrapper** — `Callpanel.class.php`, `module.xml`,
  `views/main.php`, install/uninstall stubs (~500 lines of PHP)
- **NodeJS backend** — `calls-contacts-panel/` (TypeScript 4.9 +
  Express 4 + socket.io 4.8 + mysql2 3.x + yana AMI client)
- **React frontend** — `calls-contacts-panel/frontend/` (React 17 +
  react-scripts 5 + Tailwind 3 + i18next, 5 languages)
- **Docs** — `docs/` (INSTALL, CONFIGURATION, USAGE, TROUBLESHOOTING,
  UPGRADE, FAQ, PROVISIONING-YEALINK, PROVISIONING-FANVIL),
  `README.md`, `CHANGES.md`, `CHANGELOG.md`
- **Specs** — `specs/` (constitution + handoff + 6 phase dirs + security
  audit v1+v2 + improvements roadmap)
- **CI** — `.github/workflows/release.yml` (auto-builds tarball on tag
  push, creates GitHub release)
- **SonarQube** — project tracked at
  [`freepbx-callpanel`](http://10.32.161.205:9000/dashboard?id=freepbx-callpanel)

## Tech debt (deferred to phase-05)

- React 17 (current is 18+; CRA 5 transitively pulls 14 high-severity
  build-time CVEs — not runtime, but supply-chain risk during install)
- create-react-app (deprecated by Meta 2025; migrate to Vite)
- jest 27 (current is 29+; pulls @babel/traverse + minimist + form-data
  high-severity CVEs in dev deps)
- axios formerly in package.json (removed in v17.0.2; never used in code)

Full roadmap in [phase-05-modernization/IMPROVEMENTS.md](phase-05-modernization/IMPROVEMENTS.md).

## Sandbox infrastructure

**All three sandbox VMs destroyed 2026-05-20** after v17.0.3 ship-verification.

Re-provision via:
- [`phase-01-fpbx16-validate/install-fpbx16.sh`](phase-01-fpbx16-validate/install-fpbx16.sh) — Debian 12 + FreePBX 16
- [`phase-02-fpbx17-validate/setup-log.md`](phase-02-fpbx17-validate/setup-log.md) — Debian 12 + Sangoma FreePBX 17 official installer
- [`phase-06-production-validation/install-fpbx16-rocky.sh`](phase-06-production-validation/install-fpbx16-rocky.sh) — Rocky 8 + FreePBX 16

Per proxmox-playbook.md, next free VMID is 924 (was 921-923).
