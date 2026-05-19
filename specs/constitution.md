# Constitution — FreePBX Realtime Calls & Contacts Panel (Eric's fork)

This is the project-wide set of invariants. Read this first in every new
Claude session. Treat as immutable unless Eric explicitly amends it.

## §1 — License

**Project license: AGPL-3.0-only.** Inherited from upstream
(adroste/freepbx-realtime-calls-contacts-panel) and non-negotiable —
AGPLv3 is a strong-copyleft license that cannot be relaxed without
permission from every prior copyright holder.

Implications:

- Every published derivative must remain AGPL-3.0.
- If the panel is offered as a network service (multi-tenant, customer-
  facing), §13 requires offering source to those users.
- Modifications must be stated prominently (§5(a)) — that's what
  [CHANGES.md](../CHANGES.md) is for.
- Eric's usual Apache-2.0 default does NOT apply in this project.
- Code can flow IN from Apache-2.0/MIT/BSD sources. Code can NOT flow
  OUT into Eric's Apache-2.0 projects (one-way valve, AGPL is stricter).

**Attribution:** Original copyright (Alexander Droste, 2021) stays.
Eric's additions get a parallel copyright line — never replace upstream
attribution.

## §2 — Upstream is archived

The upstream repo at `adroste/freepbx-realtime-calls-contacts-panel`
was archived on GitHub (last push 2022-01-15). There is no path to
upstream patches. Eric's fork is the de facto fork-of-record. None of
the 10 existing forks have moved past the original commit either as of
2026-05-19.

Practical impact: no need to maintain upstream-compatible patches; the
fork can diverge freely. Still must preserve copyright + license per §1.

## §3 — Target stack

**Near-term (phase-01 ship target):** Friend's production environment
- FreePBX 16.0.45
- Asterisk 18.9
- pjsip (not chan_sip)
- FreePBX Distro or equivalent

**Long-term (phase-02+ ship target):** latest stable
- FreePBX 17 (current GA as of 2026-05)
- Asterisk 22 LTS (paired with FreePBX 17)
- Debian 12 (bookworm) — Sangoma's official Debian platform

The module must work on **both** version pairs by the end of phase-03.
A single codebase preferred; branching only if FreePBX 16/17 API
differences cannot be reconciled cleanly.

## §4 — Tech stack invariants

**Backend (NodeJS):**
- Node 20 LTS minimum (Node 16 in upstream is EOL)
- TypeScript 5.x
- Express 4.x (5 not yet GA)
- socket.io 4.x for WebSocket transport
- mysql2 for DB (matches FreePBX's MariaDB)
- Tests: Jest 29+
- Process supervision: PM2 (FreePBX's `pm2` module is the canonical path)

**Frontend (React):**
- React 18+ (19 acceptable when stable)
- Build tool: **Vite** (migrate off create-react-app — CRA deprecated
  since 2025; using CRA is a quality gate failure)
- Tailwind 3.x (4.x once it stabilizes)
- React Router 6.x
- TypeScript 5.x

**PHP glue:**
- PHP 8.1+ (matches FreePBX 16/17 baseline)
- FreePBX BMO interface (still the API in 17)
- Symfony Console components as needed (FreePBX provides)

## §5 — Quality gates (apply Eric's global standards)

- **Tests before "done":** new logic → tests; full suite must pass.
- **Security review:** SQLi (parameterized only), XSS (escape output),
  CSRF (token on all state-changing endpoints), no secrets in code/logs.
- **Self-verification:** never claim a UI change works without loading
  it in a browser. Type checks + tests verify correctness, not feature
  behavior.
- **`/quality-gate`** runs the full sweep — invoke before any release.

## §6 — Spec-driven workflow

Every non-trivial change gets a `specs/phase-NN-<slug>/` directory with
`spec.md + plan.md + tasks.md + setup-log.md`. The three-step rule
applies: ≥3 files, schema change, new API surface, multi-session, or
new dependency = spec it first.

Single-line bug fixes don't need a spec. Use judgment.

## §7 — DCO sign-off on commits

Every commit needs `Signed-off-by: Eric Osterberg <ejosterberg@gmail.com>`
(DCO 1.1). Per Eric's global standards. Implemented via `-s` flag on
`git commit` or `commit.gpgsign` config; never bypass.

No "Co-Authored-By: Claude" trailers — Eric's preference is human-only
attribution in commits.

## §8 — Sandbox infrastructure

Two reference environments on pmvm1 (Proxmox cluster `pmcluster`):

| VMID | Purpose | Stack |
|---|---|---|
| 921 | Friend-match validation | Debian 12 + FreePBX 16.0.45 + Asterisk 18 + pjsip |
| 922 | Latest validation | Debian 13 + FreePBX 17 + Asterisk 22 + pjsip |

**Note on Debian-version choice (2026-05-19, Eric directive):** these
are not Sangoma's officially-supported pairings (FreePBX 16 → Debian 11,
FreePBX 17 → Debian 12). Eric chose 12 + 13 deliberately so the
deployed environments stay current. Expect: PHP version mismatches with
upstream's tested envelope, Asterisk source compile likely required for
the FreePBX 16 sandbox, and Sangoma's FreePBX 17 installer may need
patches to accept Debian 13. Document in setup-log.md as encountered.

Both provisioned via the proxmox-playbook.md cloud-init recipe. Linux
user is `ejosterberg`. SSH aliases `fpbx16-sandbox` and `fpbx17-sandbox`
once IPs are known.

Both sandboxes are throwaway — snapshot before any destructive change,
free to rebuild from scratch via the install-log procedure.

## §9 — Things explicitly out of scope

- Multi-tenant SaaS hosting of the panel
- Mobile app
- WebRTC softphone in-browser (the panel makes calls via the PBX, it
  doesn't *be* a softphone)
- Replacing FreePBX's Contact Manager (panel uses it as a backend)
- Replacing FreePBX's CallerID Lookup module (panel integrates with it)
