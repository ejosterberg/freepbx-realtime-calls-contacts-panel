# Phase 01 — Baseline validate on FreePBX 16 sandbox

**Goal:** Prove the unmodified (upstream-state) module can be installed
and operates correctly on a FreePBX 16.0.45 / Asterisk 18 / pjsip
environment that mirrors Eric's friend's production PBX.

## Why this phase exists

Eric's friend is on FreePBX 16.0.45 and wants the Calls + Contacts
Panel running on it. The upstream module declares 16.0 compat but the
last release was 2022 and has never been re-tested by anyone publicly.
Before Eric ships anything to a friend's production PBX, we need a
sandbox that mirrors that environment and a documented validation pass.

This phase is **validation-only**. No module code changes. If
something breaks, document it; do not fix it here — fixes go in
phase-03 (forward-port) or phase-04 (ship to friend) depending on
severity.

## User stories

**As Eric**, I want to install the panel on a fresh FreePBX 16 system
and have it work the way the original README describes, so that I can
either ship it to my friend with confidence or know exactly what to
fix before I do.

**As Eric**, I want every install step recorded as runnable commands,
so that when I deploy to my friend's actual PBX I can follow the same
script (adjusted for his host OS) without re-deriving the procedure.

**As Eric's friend**, I want my PBX to keep working — no broken
modules, no Asterisk restart loops, no dialplan corruption — even if
the panel itself doesn't work perfectly. Sandbox testing is the place
to catch any such regressions.

## Acceptance criteria

1. A Debian 11 VM (VMID 921, `fpbx16-sandbox`) is running on pmvm1
   with FreePBX 16.0.45 + Asterisk 18 + pjsip and is reachable at a
   documented IP.
2. The dependent FreePBX modules (`contactmanager`, `cidlookup`,
   `pm2`) are installed at minimum versions declared in
   `module.xml` (`>=16.0.17`, `>=16.0.5`, `>=13.0.3.8` respectively).
3. The Calls + Contacts Panel module (built from this fork's tarball,
   no code modifications) installs cleanly via FreePBX Module Admin
   → Upload Modules.
4. After install + Apply Config, the panel UI loads at `/callpanel/`
   and shows the dashboard.
5. With a test pjsip extension making/receiving calls:
   - Active calls appear in the panel within 2 seconds.
   - Call log entries appear after hangup.
   - CallerID lookup runs on incoming calls.
6. A new contact can be created, edited, and deleted via the panel UI
   and the change is reflected in FreePBX ContactManager.
7. Phonebook generation produces a valid Yealink XML and Fanvil XML.
8. The FreePBX admin view for the panel (`Admin → Calls + Contacts
   Panel`) renders and saves config changes.
9. `findings.md` exists in this phase directory and documents:
   - Every install step that needed manual intervention
   - Every feature that did NOT work as the README claims
   - Every error in `/var/log/asterisk/` or `pm2 logs callpanel`
   - Recommended fixes (without applying them)

## Explicitly out of scope

- Any code modification to the module (PHP, NodeJS, React)
- Forward-port to FreePBX 17 (phase-02 / phase-03)
- Production deployment to friend's PBX (phase-04)
- CI/CD setup
- Performance testing
- Multi-language testing (English only for now)
- Multi-tenancy

## Success vs. failure

**Success** = all 9 acceptance criteria met OR `findings.md`
documents specific reproducible failures with enough detail to
prioritize fixes in phase-03.

**Failure** = sandbox can't be provisioned, FreePBX 16 install
broken in ways unrelated to the panel, or the module's install
completes but corrupts the PBX dialplan / Asterisk config.

## Risks

- **FreePBX 16 on Debian 11 is community-supported only** — Sangoma's
  official 16 path is SNG7 (RHEL7-derived, EOL). Community installers
  vary in quality. If the install fails repeatedly, fall back to
  bringing up a SNG7 VM from FreePBX Distro 12.7 ISO.
- **Node 14.15.0 hardcoded** in `Callpanel.class.php` — Debian 11
  ships Node 16; might need to install Node 14 from NodeSource. Or
  edit the version check locally just for this validation (don't
  commit that edit).
- **PM2 module dependency `>=13.0.3.8`** — verify available in
  FreePBX 16 module repo. If missing, install manually.
