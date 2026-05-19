# CHANGES — modifications from upstream

This file documents all modifications made to the original
`adroste/freepbx-realtime-calls-contacts-panel` codebase in this fork,
in compliance with **AGPL-3.0 §5(a)** ("you must give all recipients
... prominent notices stating that you modified it, and giving a
relevant date").

## Upstream baseline

| | |
|---|---|
| Upstream repo | https://github.com/adroste/freepbx-realtime-calls-contacts-panel |
| Upstream commit (baseline) | last commit of `main` branch as of 2022-01-15 |
| Upstream version tag | v16.0.0 |
| Upstream license | AGPL-3.0 (per root `LICENSE` and `calls-contacts-panel/LICENSE`) |
| Upstream status | Archived (read-only on GitHub) |

## Fork

| | |
|---|---|
| Fork repo | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel |
| Fork license | AGPL-3.0-only (inherited; cannot be relaxed per AGPL §10) |
| Forked by | Eric Osterberg <ejosterberg@gmail.com> |
| Fork start date | 2026-05-19 |

## Modifications

### 2026-05-19 — license consistency cleanup (Eric Osterberg)

- `calls-contacts-panel/package.json` — changed `"license": "MIT"` to
  `"license": "AGPL-3.0-only"`. The upstream package.json declared
  MIT, which contradicts the project's `LICENSE` files and
  `module.xml` (both AGPLv3). The MIT declaration was a leftover from
  npm scaffolding and was never the intended license. Project-wide
  license is and has always been AGPL-3.0; this commit aligns the
  metadata.
- `calls-contacts-panel/frontend/package.json` — added
  `"license": "AGPL-3.0-only"` field (was missing entirely upstream).
- Added this `CHANGES.md` file at repo root.
- Added `specs/` directory with project constitution and phase docs
  for spec-driven workflow. Specs are project planning artifacts
  and not part of the shipped module; they do not affect the
  module's runtime behavior.

No code (PHP, JavaScript, TypeScript) was modified in this commit set.

## Planned modifications (not yet applied)

- Forward-port to FreePBX 17 + Asterisk 22 (phase-03+)
- Upgrade Node.js minimum from 14 to 20 LTS
- Migrate React frontend build system from create-react-app (deprecated)
  to Vite
- Upgrade React 17 → 18+
- Replace axios 0.24 (security-EOL) with current axios 1.x

When these land, append entries above with date, author, and rationale.
