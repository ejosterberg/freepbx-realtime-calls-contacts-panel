# Phase 02 — Baseline validate on FreePBX 17 sandbox

**Goal:** Establish the baseline failure inventory for the unmodified
module on FreePBX 17 / Asterisk 22 / Debian 12. Output is the input
spec for phase-03 (forward-port).

This phase mirrors phase-01 in structure but the **expected outcome
is failure** — the module is FreePBX 16-targeted and we want to learn
*how* it fails on 17, not whether.

## User stories

**As Eric**, I want a known-good FreePBX 17 sandbox I can keep using
across multiple forward-port iterations, so I'm not re-provisioning
infrastructure between phase-03 work sessions.

**As Eric**, I want a comprehensive list of every way the module
breaks on FreePBX 17, so phase-03 has a complete punch-list rather
than a series of "fix one thing, discover the next" loops.

## Acceptance criteria

1. VM 922 (`fpbx17-sandbox`) is up on pmvm1 with FreePBX 17 +
   Asterisk 22 + pjsip installed via Sangoma's official Debian
   installer.
2. Same dependent modules installed at their FreePBX 17 versions
   (`contactmanager`, `cidlookup`, `pm2`).
3. The unmodified module tarball (same one used in phase-01) is
   uploaded via Module Admin.
4. `findings.md` exists in this phase directory and categorizes every
   issue encountered into:
   - **Install-time** (PHP errors, BMO load failures, missing
     namespace classes, dep version mismatches)
   - **Runtime** (Node version rejected, npm install fails, PM2
     module API differences, AMI event shape changes, DB schema
     drift)
   - **UI** (frontend loads but features broken, API shape changes,
     auth flow differences)
5. For each finding, document:
   - Reproduction steps
   - Expected behavior (what FreePBX 16 does / what the README claims)
   - Actual behavior
   - Hypothesis for root cause
   - Fix estimate (trivial / small / large / unknown)

## Out of scope

Same as phase-01 + everything not on the install-validate critical
path. **No fixing in this phase** — every fix temptation gets
deferred to phase-03 so the punch list is complete.

## Risks

- **FreePBX 17 module API may have moved**: `\BMO` interface should
  still exist but specific methods (`install`, `uninstall`,
  `getActionBar`, `showPage`, etc.) may have signature changes.
- **PM2 module in FreePBX 17** may be on a different version with
  different `Pm2->getStatus()`, `Pm2->installNodeDependencies()` API.
- **Node version requirement** (currently `14.15.0` minimum hardcoded)
  will fail outright on FreePBX 17's expected Node 20+ environment.
- **`load_view()` helper** from FreePBX framework may have moved
  namespaces.
- **Asterisk 22 AMI events** may have different field names than
  Asterisk 18 — the `ami.ts` parsing code is likely brittle.
- **ContactManager schema** may have added columns / changed types
  between FreePBX 16 and 17.
