# Phase 03 — Forward-port to FreePBX 17

**Goal:** Apply code changes so the module installs and runs on FreePBX
17 (Asterisk 22 / Debian 12 / PHP 8.2 / Node 18+) without regressing
the FreePBX 16 install path.

## Acceptance criteria

1. Same source tree produces a tarball that installs cleanly on **both**
   FreePBX 16 (phase-01 sandbox) and FreePBX 17 (phase-02 sandbox).
2. `fwconsole ma list` shows `callpanel` as Enabled on both.
3. PM2 process starts and `http://<host>:4848/callpanel/` returns 200.
4. No PHP 8.x deprecation warnings in the FreePBX Notification panel
   after install + Apply Config.
5. Admin view (FreePBX → Admin → Calls + Contacts Panel) renders
   without errors on both versions.
6. Test call (Asterisk CLI `originate`) appears in the active-calls
   widget within 2s.
7. Phonebook XMLs generate successfully (Yealink + Fanvil).

## Out of scope (deferred to later phases)

- React 17 → 18 upgrade
- create-react-app → Vite migration
- axios 0.x → 1.x upgrade
- Per-user auth via FreePBX userman
- Backend HTTP bind to 127.0.0.1 (currently 0.0.0.0)
- CORS tightening

Above are nice-to-have modernizations. Phase 03 is strictly:
"make it work on FreePBX 17."

## Changes applied (working set as of 2026-05-19)

| File | Change | Reason |
|---|---|---|
| `module.xml` | `<version>17.0.0</version>`, dual-version `<supported>`, bumped publisher | Fork v17.0.0; works on both 16+17 |
| `Callpanel.class.php` | `$nodever = '18.0.0'`, `$npmver = '8.0.0'` | FreePBX 17 ships Node 20; FreePBX 16's `pm2` module wants Node 18+ |
| `Callpanel.class.php` | `install()` now runs `npm run build` for backend + `npm ci --include=dev && npm run build` for frontend after `installNodeDependencies` | Upstream never built — `build/src/main.js` (pm2 entrypoint) didn't exist after install |
| `Callpanel.class.php` | Null-safe `?? ''` / `?? null` on `$_POST`, `$_SESSION`, `$_GET`, `$_SERVER` access | PHP 8 `Undefined array key` → `E_DEPRECATED` blocks page render under Whoops |
| `Callpanel.class.php` | `randcheck` comparison `!=` → `!==` | Strict-equal for CSRF token check (minor security improvement) |
| `views/main.php` | `?? ''` on `$localconf` / `$defaultconf` lookups | Same PHP 8 reason |
| `calls-contacts-panel/package.json` | `engines.node: '>=18.0.0'` | FreePBX 17 ships Node 20 |
| `calls-contacts-panel/package.json` | `license: 'AGPL-3.0-only'` (was `'MIT'`) | License consistency (see [CHANGES.md](../../CHANGES.md)) |
| `calls-contacts-panel/frontend/package.json` | Added `license: 'AGPL-3.0-only'` | License consistency |

## Known unknowns (resolve during phase-02 testing)

- Does `yana` AMI lib work on Node 20?
- Does `asterisk-ami-client`-style libs need replacement for Asterisk 22?
- Does the `Pm2->installNodeDependencies` callback signature still work?
- Does FreePBX 17's `load_view()` still exist or did it move?
- Does the `<framework>` hook syntax still trigger correctly on FreePBX 17?

Each "unknown" gets a finding entry in
`specs/phase-02-fpbx17-validate/findings.md` after testing.

## Risk assessment

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Backend `npm run build` fails due to dep peer-version conflicts | Medium | High | Pin Node 18 LTS during phase-02 testing; fall back to bumping individual deps |
| Frontend CRA build fails on Node 20 | Medium | High | CRA 5 has known issues with Node 20 — may need to override OpenSSL flag (`NODE_OPTIONS=--openssl-legacy-provider`) or upgrade to react-scripts 5.0.1 |
| `yana` AMI lib needs replacement | Low | High | Last published 2023; fork or replace with `asterisk-ami-client` if it breaks |
| FreePBX 17 admin view fails | Low | Medium | Most likely PHP 8 issues — phase-02 catches these |
| Module signature verification fails on upload | Low | Medium | `fwconsole ma uploadtrusted` (vs `upload`) skips signature; document for users |
