# Phase 02 — Tasks

Ordered top-to-bottom.

## Provisioning

- [x] Download Debian 12 cloud image to Proxmox (2026-05-19)
- [ ] Create VM 922 on pmvm1 (4 CPU, 8 GB, 60 GB, vmbr0+DHCP,
      user `ejosterberg`)
- [ ] Discover IP, add `~/.ssh/config` alias `fpbx17-sandbox`
- [ ] `apt update && apt full-upgrade -y && reboot`
- [ ] Install `qemu-guest-agent`

## FreePBX 17 install

- [ ] Run Sangoma's official installer:
      `curl -O https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh && sudo bash sng_freepbx_debian_install.sh`
- [ ] Capture full log to `phase-02-fpbx17-validate/install.log`
- [ ] Set admin password, run initial setup wizard
- [ ] Configure two pjsip test extensions
- [ ] Register softphone, verify calls

## Install dep modules

- [ ] Module Admin → install `contactmanager`, `cidlookup`, `pm2`
      (FreePBX 17 versions)

## Install panel module

- [ ] Upload same tarball from phase-01:
      `scp /tmp/callpanel.tar.gz fpbx17-sandbox:/tmp/`
- [ ] Module Admin → Upload Modules → Upload Local
- [ ] **Expect this to fail** — capture exact error in findings.md

## Validation (expect mostly failures)

For each acceptance criterion from phase-01 (AC1 through AC8), attempt
to verify. Each failure → entry in findings.md per the template in
plan.md.

## Document + wrap

- [ ] findings.md categorized: install / runtime / UI / surprisingly-OK
- [ ] Snapshot VM 922: `qm snapshot 922 phase-02-baseline-failure-captured`
- [ ] Update specs/current-state.md (phase-02 complete)
- [ ] Update specs/handoff.md (next session = phase-03 forward-port)
- [ ] Spec phase-03 (forward-port) based on findings — open
      `specs/phase-03-fpbx17-forward-port/spec.md`
