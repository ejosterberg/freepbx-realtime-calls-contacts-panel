# Improvements roadmap

This document catalogs improvements identified during the v17.0.2
audit pass that haven't been applied yet. Each item lists severity,
effort estimate, and dependencies, so future sessions can pick them
off in priority order.

## High-priority (security / correctness)

### I-01 — Bind backend HTTP to 127.0.0.1 by default
**Severity:** High (defense in depth against external scrape)
**Effort:** Small (one-line change + README update)
**Breaking?** Yes — users not using reverse-proxy lose direct access
**Dependencies:** None — just edit `web-server.ts:24` to listen on
`127.0.0.1` instead of default `0.0.0.0`.
**Why:** The phonebook XML endpoints leak all contacts to anyone who
can reach port 4848. Binding to localhost forces the Apache reverse
proxy path, which lets users layer auth/TLS/IP filtering.
**Recommended bundling:** ship in a v18.0.0 major (breaking change).

### I-02 — Add CSP + secure cookie headers
**Severity:** Medium
**Effort:** Small (express middleware)
**Breaking?** No
**Dependencies:** Add `helmet` or hand-rolled middleware.
**Why:** No CSP currently. Frontend is React (XSS-resistant at the
React level), but CSP provides defense in depth and protects
phonebook XML responses from being embedded in malicious frames.

### I-03 — Document upstream `yana` AMI lib replacement plan
**Severity:** Low (works currently)
**Effort:** Medium (depends on alternatives)
**Breaking?** No (internal)
**Dependencies:** None
**Why:** `yana@1.2.4` last published 2023. If it goes unmaintained,
we need an exit. Candidates: `asterisk-manager`, `asterisk-ami-client`,
`node-asterisk-ami`. Spec a replacement before yana actually breaks.

## Medium-priority (modernization)

### I-04 — Migrate frontend from create-react-app to Vite
**Severity:** Medium (CRA deprecated 2025; ~14 high CVEs in CRA transitive deps)
**Effort:** Large (1-2 day refactor)
**Breaking?** No (user-facing behavior identical)
**Dependencies:** I-05 (React 17→18 should land first or together)
**Why:**
- CRA deprecated by Meta in 2025; no security patches forthcoming
- Most of the ~14 frontend high CVEs come from CRA transitives
  (webpack 5.0–5.104, ejs, loader-utils, etc.)
- Vite builds 10x faster, hot-reload is sub-second
- Native ESM, no babel-transform overhead

**Plan sketch:**
1. `npm install -D vite @vitejs/plugin-react vitest`
2. Move `index.html` to project root, update script tag to ESM
3. Replace `react-scripts start` → `vite`, `react-scripts build` → `vite build`, `react-scripts test` → `vitest`
4. Update `tailwind.config.js` content paths if needed
5. Move env var prefix from `REACT_APP_` to `VITE_` (currently we don't use any, so just verify)
6. Remove `react-scripts` + the `@types/jest` (vitest brings types)
7. Re-test build + functional

### I-05 — Bump React 17 → 18
**Severity:** Medium (React 17 still supported but old; concurrent features in 18)
**Effort:** Medium (1 day with careful testing)
**Breaking?** Possibly (some lifecycle methods, `ReactDOM.render` → `createRoot`)
**Dependencies:** Test with current frontend before/after.
**Why:**
- React 17 lacks the concurrent features in 18 (useTransition,
  Suspense for data, etc.) — not critical here but useful for
  perceived responsiveness on slow connections
- All `@types/react`+`@types/react-dom` are now in 18.x line; type
  drift is starting to bite

**Plan sketch:**
1. `npm install react@^18 react-dom@^18 @types/react@^18 @types/react-dom@^18`
2. Update `src/index.tsx` to use `createRoot` API
3. Test every component; React 18 batches state updates more
   aggressively, which can change behavior in subtle cases
4. Verify with `@testing-library/react@^14`

### I-06 — Clear remaining backend high-severity CVEs
**Severity:** Medium (build-time only)
**Effort:** Medium (jest 27 → 29 + ts-jest 27 → 29 cascade)
**Breaking?** No (tests only)
**Dependencies:** None
**Why:** 6 high-severity CVEs remain after v17.0.2 dep bumps. All
are dev/build transitive (`@babel/traverse`, `cross-spawn`, `nanoid`,
`webpack`, etc.) — not in runtime artifact. But the lint output
becomes noisy and the supply-chain attack surface during install
is non-zero.

**Plan sketch:**
1. `npm install -D jest@^29 ts-jest@^29 @types/jest@^29`
2. Update `jest.config.js` — Jest 29 changed some defaults
3. Update test files if any use removed APIs
4. Verify all tests still pass

### I-07 — axios upgrade or removal verification across full codebase
**Severity:** Low (already removed from package.json in v17.0.2)
**Effort:** Tiny (audit grep)
**Breaking?** No
**Why:** Confirm no transitive dep still pulls a vulnerable axios.

## Low-priority (quality / DX)

### I-08 — Add CI workflow for lint + tests
**Severity:** Low
**Effort:** Small (one workflow file)
**Why:** Currently only the release workflow exists. PRs to main
should be gated on at least `npm run lint` and `npm test` passing.

**Plan sketch:** `.github/workflows/ci.yml` triggers on `pull_request`,
matrix over Node 18 + 20, runs both backend and frontend lint + test.

### I-09 — Add `npm audit` to the CI pipeline as a gate
**Severity:** Low
**Effort:** Tiny
**Dependencies:** I-08 (CI workflow must exist first)
**Why:** Caught us once already — would prevent shipping with
critical CVEs in the lockfile.

**Suggested gate level:** fail on critical, warn on high.

### I-10 — Add SonarQube scan to CI
**Severity:** Low
**Effort:** Small
**Dependencies:** I-08, the SonarQube server has to be reachable from
GitHub Actions (it isn't currently — internal IP only)
**Why:** Continuous code-quality tracking. If we accept the SonarQube
limitation that it runs on-LAN, an alternative is GitHub's built-in
CodeQL or a SaaS like Snyk for the CI path.

### I-11 — Replace `rand()` in views/main.php with `random_int()`
**Severity:** Low (only used for CSRF token randomness)
**Effort:** Tiny
**Why:** SonarQube flagged it. `random_int()` is cryptographically
secure; `rand()` is not. For a CSRF token where prediction = bypass,
the upgrade is the right call.

### I-12 — Replace `Math.random()` in ws-api.test.ts:10
**Severity:** Low (test code; not security-critical)
**Effort:** Tiny
**Why:** SonarQube flagged it. Tests should be deterministic anyway;
seed a PRNG or use a fixture.

### I-13 — Document the regex on database.ts:28 as bounded
**Severity:** Low
**Effort:** Tiny
**Why:** SonarQube flagged the regex `/['"]([\S\s]*?)['"]\s*;/`
as potentially ReDoS-vulnerable. The input is `/etc/freepbx.conf`
(< 1 KB, admin-controlled), so the risk is theoretical. Either
add a comment explaining the bounded input, or rewrite the regex
to be greedy-resistant.

### I-14 — Per-user contact / call-log filtering
**Severity:** Low (documented as known limitation)
**Effort:** Medium
**Why:** Multi-tenant deployments need per-user visibility limits.
Currently all panel users see all data.

### I-15 — Apache reverse-proxy automation in install method
**Severity:** Low
**Effort:** Medium
**Why:** Right now users have to manually drop a config file. The
install method could detect Apache and offer to write the snippet
automatically (with a confirmation prompt during `fwconsole ma install`).

### I-16 — Increase i18n coverage ✅ partially done (Unreleased)
**Severity:** Very Low
**Effort:** Per-language — turned out to be ~5 min per language for
machine-assisted translation (62 short keys total)
**Current:** English, German, Spanish, French, Italian,
Brazilian Portuguese, Dutch
**Wanted:** Polish, Russian, Chinese (Simplified), Japanese,
Arabic, European Portuguese, Catalan
**Status:** Machine-assisted translations for es/fr/it/pt-BR/nl
shipped pending native-speaker review. Track quality issues at
[github issues](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/issues)
with the `i18n` label.

**Lesson learned:** original estimate was "Very Low priority / per-language effort". The actual mechanical work was tiny (62 short keys). The HARD part is native-quality review, which can be crowdsourced post-ship via PRs. Don't conflate the two efforts when rating priority.

### I-17 — Per-feature ACLs in FreePBX User Manager
**Severity:** Low
**Effort:** Medium
**Why:** Currently it's all-or-nothing per user. Could add custom
permissions like `panel.contacts.write`, `panel.calls.makecall`.

### I-18 — In-place upgrade support (alternative to uninstall+reinstall)
**Severity:** Very Low
**Effort:** Small
**Why:** Currently UPGRADE.md mandates uninstall+reinstall. Adding
an `upgrade()` BMO method that preserves config.local.json and skips
the DB cleanup would shave 1-2 minutes off upgrades.

## Won't do (intentionally)

### W-01 — Browser-based softphone (WebRTC)
Out of scope per [constitution §9](../constitution.md#9--things-explicitly-out-of-scope).
The panel originates calls server-side; audio still routes through
existing phones. A real softphone is a separate project.

### W-02 — Mobile app
Out of scope per constitution §9.

### W-03 — Multi-tenant SaaS hosting
Out of scope per constitution §9.

### W-04 — Replace FreePBX Contact Manager
The panel WRAPS Contact Manager, doesn't replace it. Per constitution §9.

## Tracking conventions

- This file is the canonical TODO list. Update it as items land
  or new improvements get identified.
- Priority sort order is High → Medium → Low within each band.
- "Effort" estimates assume one developer; multiply for unfamiliar
  contributors.
- When picking up an item, open a phase directory
  (`specs/phase-NN-<slug>/`) with spec.md + plan.md + tasks.md per
  the spec-kit workflow.
