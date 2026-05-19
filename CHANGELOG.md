# Changelog

All notable changes to this fork are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

For the delta vs upstream
([adroste/freepbx-realtime-calls-contacts-panel](https://github.com/adroste/freepbx-realtime-calls-contacts-panel)),
see [CHANGES.md](CHANGES.md).

## [Unreleased]

### Added

- Detailed documentation suite under `docs/`:
  [INSTALL.md](docs/INSTALL.md), [CONFIGURATION.md](docs/CONFIGURATION.md),
  [USAGE.md](docs/USAGE.md), [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md),
  [UPGRADE.md](docs/UPGRADE.md),
  [PROVISIONING-YEALINK.md](docs/PROVISIONING-YEALINK.md),
  [PROVISIONING-FANVIL.md](docs/PROVISIONING-FANVIL.md),
  [FAQ.md](docs/FAQ.md)

### Fixed

- Security audit note F-03 was incorrect (claimed single shared
  password). Auth actually delegates to FreePBX User Manager
  (`userman_users`) with bcrypt verification + module permission
  check (`pbx_admin` or `pbx_modules` containing `cdr` +
  `contactmanager`). Audit doc updated.

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

[Unreleased]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/compare/v17.0.1...HEAD
[17.0.1]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.1
[17.0.0]: https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.0
