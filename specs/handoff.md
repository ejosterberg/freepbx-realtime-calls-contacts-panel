# Handoff — for the next Claude session

**Last updated:** 2026-05-19 (initial setup + forward-port + ship session)

## What to start on

**If installs are still running when this session ends:** check both
waiters and resume from where they left off. Both background bash
waiters poll `until` loops:

```
ssh fpbx16-sandbox 'sudo tail -20 /var/log/freepbx16-install.log'
ssh fpbx17-sandbox 'sudo tail -20 /tmp/fpbx17-install.log'
```

If either install died mid-way, rebuild the VM (`qm destroy <VMID>
--purge 1`) and re-run the install. The scripts are idempotent for the
parts that re-run, but a partial install is messier than a fresh one.

**If installs completed but module install / test was not done yet:**
the obvious next move is — on each sandbox — install the dep modules,
upload the panel tarball, install it, and exercise the test scenarios
in `phase-01-fpbx16-validate/tasks.md` (AC1–AC9).

**If module install + test completed:** the obvious next move is to
ship. Run the steps in `phase-04-ship-to-github/tasks.md` (commit with
DCO, tag, push, gh release create).

If Eric instead wants to skip ahead — ask him first.

## Open follow-ups (by phase)

### Phase 01 (FreePBX 16 baseline validate)
- [ ] Install script `specs/phase-01-fpbx16-validate/install-fpbx16.sh`
      uploaded + executing on VM 921
- [ ] After FreePBX install: `fwconsole ma downloadinstall contactmanager
      cidlookup pm2` (deps not auto-installed by base FreePBX install)
- [ ] Configure two pjsip extensions (e.g., 1001, 1002)
- [ ] Build callpanel tarball + upload + install
- [ ] Run `phase-01-fpbx16-validate/test-module-install.sh`
- [ ] Write findings to `phase-01-fpbx16-validate/findings.md`

### Phase 02 (FreePBX 17 baseline validate)
- [ ] Sangoma installer `sng_freepbx_debian_install.sh` executing on VM 922
- [ ] Verify post-install: `fwconsole --version` and `asterisk -rx 'core
      show version'` should show FreePBX 17 + Asterisk 22
- [ ] Module deps: should already be installed via `fwconsole ma
      installlocal` in installer; verify with `fwconsole ma list | grep
      -E "contactmanager|cidlookup|pm2"`
- [ ] Build same callpanel tarball + upload + install
- [ ] Expect this to surface issues — capture findings

### Phase 03 (FreePBX 17 forward-port)
**Already applied in this session (uncommitted):**
- `module.xml` — v17.0.0, dual-version supported, fork publisher
- `Callpanel.class.php` — Node 18 min, install() does build, PHP 8 null-safety
- `views/main.php` — PHP 8 null-safety
- `calls-contacts-panel/package.json` — Node 18 engines, AGPL license
- `calls-contacts-panel/frontend/package.json` — AGPL license added
- `CHANGES.md` — fork modifications log per AGPL §5(a)
- `README.md` — fork notice, dual-version compat table, install steps
- `.github/workflows/release.yml` — auto-build tarball on tag push
- `specs/` — full spec-kit scaffold

**Still to apply (pending phase-02 findings):**
- Whatever the FreePBX 17 install surfaces

### Phase 04 (ship)
- [ ] Commit changes in logical chunks with `-s` (DCO sign-off)
- [ ] Tag `v17.0.0`
- [ ] `git push origin main --follow-tags`
- [ ] GHA release workflow auto-fires and creates the GH release
- [ ] Update friend on availability

### Cross-cutting
- [ ] SonarQube project (`freepbx-callpanel`) per sonarqube-playbook.md
      — defer to phase-05 once code stabilizes
- [ ] Apache reverse-proxy automation (add to install method) — defer
- [ ] Per-user auth via FreePBX userman (security audit F-03) — defer
- [ ] CORS tightening + bind-to-127.0.0.1 (audit F-04/F-05) — defer

## Deployment cheat-sheet

| Resource | Value |
|---|---|
| Proxmox host (cluster) | `pmvm1` / `pmvm2` (`pmcluster`) |
| SSH alias for Proxmox | `proxmox-workshop` |
| FreePBX 16 sandbox VM | VMID **921**, name `fpbx16-sandbox`, IP **10.32.161.80** |
| FreePBX 17 sandbox VM | VMID **922**, name `fpbx17-sandbox`, IP **10.32.161.47** |
| Linux user (both VMs) | `ejosterberg` |
| SSH alias to sandboxes | `fpbx16-sandbox`, `fpbx17-sandbox` |
| Sandbox SSH key | `~/.ssh/proxmox_workshop` |
| Storage pool (VMs) | `vmpool` (ZFS, cluster-shared) |
| FreePBX 16 install log | `/var/log/freepbx16-install.log` (VM 921) |
| FreePBX 17 install log | `/tmp/fpbx17-install.log` (VM 922) |
| FreePBX 16 install script | `specs/phase-01-fpbx16-validate/install-fpbx16.sh` (in repo) |
| FreePBX 17 install script | `https://github.com/FreePBX/sng_freepbx_debian_install` |
| FreePBX web UI (16) | `http://10.32.161.80/admin` (post-install) |
| FreePBX web UI (17) | `http://10.32.161.47/admin` (post-install) |
| Panel direct URL | `http://<host>:4848/callpanel/` (port 4848) |
| GitHub fork | `https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel` |
| gh CLI auth | logged in as ejosterberg, repo+workflow scopes |

## Decisions logged

- **Two sandboxes, not one** (2026-05-19) — friend on FreePBX 16, long-term
  goal FreePBX 17. Need both.
- **Debian 12 for both sandboxes** (2026-05-19) — original plan was Debian
  11 for FreePBX 16, Debian 13 for FreePBX 17. Reverted Debian 13 →
  Debian 12 for FreePBX 17 because Sangoma's installer explicitly
  blocks Debian 13. Reverted Debian 11 → Debian 12 for FreePBX 16
  per Eric's directive (use latest Debian we can).
- **FreePBX 16 on Debian 12 via custom install** (2026-05-19) — no
  official Sangoma support for FreePBX 16 on Debian 12; using PHP 7.4
  from Sury + Asterisk 18 source build. Recipe in
  `specs/phase-01-fpbx16-validate/install-fpbx16.sh`.
- **Test calls via Asterisk CLI `originate`** (2026-05-19) — instead of
  SIPp. Simpler; tests exactly what the panel reads (AMI events).
- **Dual-FreePBX-version supported in single tarball** (2026-05-19) —
  module.xml declares both 16.0 and 17.0; dep version constraints use
  lower-bound (`ge 16.0.17`) which satisfies both 16 and 17 module
  catalogs.

## Anti-patterns to avoid

- **Don't snapshot before committing — always commit before risky
  changes.** Snapshots are infrastructure-level (Proxmox); they don't
  help with code reverts.
- **Don't use SonarQube scan as a quality gate before phase-03 is
  complete.** Lots of false-positive PHP 8 warnings until the
  null-safety patches stabilize across the codebase. Save the scan for
  after a release.
- **Don't claim "tested on FreePBX 17" until phase-02 findings are
  populated.** As of this writing, the FreePBX 17 sandbox install is
  still in progress.
