# Changelog

All notable changes to this fork are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

For the delta vs upstream
([adroste/freepbx-realtime-calls-contacts-panel](https://github.com/adroste/freepbx-realtime-calls-contacts-panel)),
see [CHANGES.md](CHANGES.md).

## [Unreleased]

### Added

- **5 new UI languages** (machine-assisted first-pass translations,
  pending native review): Spanish (`es`), French (`fr`), Italian (`it`),
  Brazilian Portuguese (`pt-BR`), Dutch (`nl`). Brings total supported
  languages from 2 (English, German) to 7. See
  [`frontend/public/locales/README.md`](calls-contacts-panel/frontend/public/locales/README.md)
  for translation status table + contribution guide.
- Updates the README's compat/feature table accordingly.

## [17.0.2] — 2026-05-19

### Security

- **Cleared all critical CVEs.** Runtime deps bumped to clear:
  - **mysql2 RCE** ([GHSA-fpw7-j2hg-69v5](https://github.com/advisories/GHSA-fpw7-j2hg-69v5),
    CVSS 9.8) — was `mysql2@2.3.3`, now `mysql2@^3.11.0`
  - **socket.io-parser injection** ([GHSA-qm95-pgcg-qqfq](https://github.com/advisories/GHSA-qm95-pgcg-qqfq),
    CVSS 9.8) on both backend and frontend — was `socket.io@4.4.0` and
    `socket.io-client@4.4.1`, now both `^4.8.0`
- Net change in `npm audit` totals: backend `55 → 21` vulnerabilities
  (5 critical → **0**); frontend `86 → 30` (7 critical → **0**).
  Remaining high/moderate are dev/build transitives in jest 27 +
  react-scripts 5 — not in runtime artifact. See [security audit v2](specs/security/audit-2026-05-19-v2.md).
- Removed unused `axios@0.24.0` dependency from both backend and
  frontend (was a leftover, not imported anywhere).

### Added

- **Detailed documentation suite** under `docs/`:
  [INSTALL.md](docs/INSTALL.md), [CONFIGURATION.md](docs/CONFIGURATION.md),
  [USAGE.md](docs/USAGE.md), [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md),
  [UPGRADE.md](docs/UPGRADE.md),
  [PROVISIONING-YEALINK.md](docs/PROVISIONING-YEALINK.md),
  [PROVISIONING-FANVIL.md](docs/PROVISIONING-FANVIL.md),
  [FAQ.md](docs/FAQ.md)
- **SonarQube project tracking** at
  [10.32.161.205:9000/dashboard?id=freepbx-callpanel](http://10.32.161.205:9000/dashboard?id=freepbx-callpanel).
  Initial scan: 0 vulnerabilities (A rating), 6 security hotspots
  (manual review), 4 bugs (2 fixed in this release), 103 code smells
  (all minor).
- **Improvements roadmap** at
  [specs/phase-05-modernization/IMPROVEMENTS.md](specs/phase-05-modernization/IMPROVEMENTS.md)
  — 18 cataloged improvements with effort estimates.

### Changed

- TypeScript bumped from `~4.5.3` to `~4.9.5` (newer @types/* require
  newer TS to parse).
- Backend `express` bumped from `^4.17.2` to `^4.21.0` (security
  patches in 4.18+).
- Backend `bcrypt` bumped from `^5.0.1` to `^5.1.1` (minor security).
- Frontend `react-scripts` pinned to `^5.0.1` (was `^5.0.0`).

### Fixed

- **2 SonarQube-flagged bugs** in `Callpanel.class.php`:
  - Line 337: referenced undefined `$command` variable in error path
    (inherited from upstream)
  - Line 383: referenced undefined `$process` variable in error path
    (inherited from upstream)
- **2 SonarQube-flagged code smells:** added `public` visibility
  modifier on `readConfig()` and `saveConfig()` in
  `Callpanel.class.php`.
- **Frontend TypeScript error** in `ContactEditor.tsx:273`: missing
  optional chain (`errors.phoneNumbers?.[0].number` → `?.[0]?.number`).
  Surfaced by the TS 4.9 upgrade; was a latent null-deref under TS 4.5
  too but the older compiler didn't catch it.
- **Security audit note F-03** was incorrect (claimed single shared
  password). Auth actually delegates to FreePBX User Manager
  (`userman_users`) with bcrypt verification + module permission
  check. Original audit doc updated; v2 audit doc supersedes.

### Ship discipline note

This release exists because v17.0.1 was declared "shipped" without
running available quality tooling (`npm audit`, SonarQube). When run
after the fact, the audit found 12 critical CVEs in the released
artifact. The discipline change is documented in
[specs/constitution.md §5a](specs/constitution.md#5a--ship-verification-added-2026-05-19)
— every future release must verify CI + audit results + scan before
the "shipped" claim.

## [17.0.1] — 2026-05-19

## [17.0.1] — 2026-05-19

### Fixed

- **CI release workflow** — `tar` was writing the output tarball
  into the same directory it was archiving, causing "file changed
  as we read it" errors. Tarball now writes to `/tmp/`.

No functional changes to the module itself vs v17.0.0.

## [17.0.0] — 2026-05-19

First release of the [Eric Osterberg](https://github.com/ejosterberg)
fork.

### Added

- **FreePBX 17 / Asterisk 22 / PHP 8.2 compatibility** alongside
  the original FreePBX 16 support. Same source tarball installs
  on both.
- **Install method actually builds the code now.** Upstream relied
  on `Pm2->installNodeDependencies` (= `npm install`) but never
  ran `npm run build` — `pm2.config.js` pointed at
  `build/src/main.js` that never existed post-install. Fixed:
  install method now runs `npm ci --include=dev` + `npm run build`
  for both backend and frontend.
- **AGPL-3.0 license consistency** — `calls-contacts-panel/package.json`
  declared `MIT` (leftover from scaffolding); now declares
  `AGPL-3.0-only` matching the rest of the project.
- **AMI user auto-detection** — finds the first non-`general`
  section with a `secret` field in `/etc/asterisk/manager.conf`.
  FreePBX 16+ generates random hashed usernames; upstream
  hardcoded `admin` (which doesn't exist post-install).
- **GitHub Actions release workflow** — auto-builds the install
  tarball on `v*` tag push and creates a GitHub release with the
  tarball attached.
- **Documentation:** [CHANGES.md](CHANGES.md) documenting fork
  modifications per AGPL §5(a). README rewritten with fork notice,
  dual-version compat table, install steps, Apache reverse-proxy
  snippet.
- **Spec-driven workflow** — full `specs/` directory with
  constitution, current state, handoff, phase docs, and security
  audit.

### Changed

- `module.xml` version bumped from `16.0.0` to `17.0.0`.
  `<supported>` now declares both `16.0` and `17.0`.
- Backend `engines.node` bumped from `>= 16.13` to `>=18.0.0`
  (FreePBX 17's `pm2` module ships Node 20).
- `tsconfig.json` adds `skipLibCheck: true` (yana@1.2.4's typings
  are incompatible with TS 4.5 strict mode).
- `Callpanel.class.php` `$nodever` bumped from `14.15.0` to `18.0.0`
  (Node 14 EOL since 2023).

### Fixed

- **PHP 8.x null-safety** — all `$_POST` / `$_SESSION` / `$_GET` /
  `$_SERVER` access in `Callpanel.class.php` and `views/main.php`
  now uses `?? ''` / `?? null` defaults. PHP 8 promotes "Undefined
  array key" to `E_DEPRECATED`, which Whoops intercepts on
  FreePBX 17.
- **PHP 8.2 dynamic property deprecation** — declared `$freepbx`
  and `$db` properties at class scope in `Callpanel.class.php`.
- **CSRF token comparison hardened** — `!=` → `!==` strict
  comparison.
- **`Pm2->getStatus()` guarded against false return** — FreePBX 17's
  PM2 module returns `false` when a process isn't registered (vs
  FreePBX 16's empty array). All `$status['pm2_env']` access now
  wrapped in `is_array($status)` checks.
- **Database connection forces IPv4** — Node 18+ resolves
  "localhost" to IPv6 `::1` first, but MariaDB on Debian 12 only
  listens on `127.0.0.1`. Panel now coerces `AMPDBHOST ===
  'localhost'` to `'127.0.0.1'` automatically.
- **`/etc/freepbx.conf` parser handles double-quoted values** —
  FreePBX 17 writes `$amp_conf["KEY"] = "value";` (double quotes);
  FreePBX 16 writes single quotes. Regex now matches either.
- **Removed `prebuild: npm run lint` hook** — lint is a CI concern,
  not install-time. The hook tried to run eslint with the
  `react-app` config, which is in `react-scripts` (a frontend
  devDep) and isn't installed yet when backend builds.

### Removed

- Commented-out hooks in `module.xml` (Chown, Certman framework
  hooks that were disabled in upstream).

### Security

- See [`specs/security/audit-2026-05-19.md`](specs/security/audit-2026-05-19.md)
  for the full security review. Known limitations:
  - CORS allows any origin with credentials (intended for behind-
    reverse-proxy use)
  - HTTP server binds to `0.0.0.0:4848` (firewall externally or
    use reverse-proxy)
  - Default admin password not enforced at install time
    (deferred to phase-04 of project specs)

## Pre-fork history

For changes prior to this fork (upstream v16.0.0 by Alexander
Droste, released 2022-01-15), see the
[upstream repo](https://github.com/adroste/freepbx-realtime-calls-contacts-panel).

[Unreleased]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/compare/v17.0.2...HEAD
[17.0.2]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.2
[17.0.1]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.1
[17.0.0]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.0
