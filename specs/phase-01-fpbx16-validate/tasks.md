# Phase 01 — Tasks

Ordered top-to-bottom. Each item is one atomic ~15-60 min work block.

## Sandbox provisioning (VM 921)

- [x] Download Debian 11 cloud image to Proxmox (2026-05-19)
- [ ] Create VM 921 on pmvm1 via cloud-init recipe (4 CPU, 8 GB RAM,
      60 GB disk on vmpool, vmbr0 + DHCP, user `ejosterberg`,
      SSH key from `/root/.ssh/authorized_keys`)
- [ ] Wait for first boot + cloud-init to complete (~2 min)
- [ ] Discover assigned IP (arp-scan or tcpdump per playbook)
- [ ] Add SSH alias `fpbx16-sandbox` to `~/.ssh/config`
- [ ] Verify SSH login as `ejosterberg` works
- [ ] Update setup-log.md with VMID, MAC, IP, SSH alias

## Base system prep (on VM 921)

- [ ] `apt update && apt full-upgrade -y` and reboot
- [ ] Install qemu-guest-agent (`apt install -y qemu-guest-agent`)
- [ ] Install base deps the FreePBX installer assumes: `curl wget git
      sudo gnupg2 lsb-release`
- [ ] Verify time sync (`timedatectl status`) — FreePBX hates clock skew

## FreePBX 16 install (primary path: community Debian installer)

- [ ] Clone the community installer: `git clone <repo>` — choose one
      of:
      - https://github.com/POSSA/freepbx_install_dist
      - https://github.com/SuperFastClick/installer (search for a
        recent, maintained one before settling)
- [ ] Run the installer script — capture full output to install.log
- [ ] If it fails: switch to fallback path A (manual install per
      FreePBX wiki). Document the failure in setup-log.md.
- [ ] Confirm FreePBX web UI loads at `http://<vm921-ip>/admin`
- [ ] Set admin password; run through initial setup wizard
- [ ] Pin FreePBX version to 16.0.45 specifically (the friend's
      version): `fwconsole ma upgrade framework --tag=16.0.45` or
      similar. Verify with `fwconsole ma listonline`.
- [ ] Confirm Asterisk 18.x is running (`asterisk -rx 'core show
      version'`); if 18.9 specifically is available, install it.
- [ ] Switch from chan_sip to pjsip if not already default
- [ ] Configure two test pjsip extensions (e.g., 1001 and 1002)
- [ ] Register a softphone (e.g., Zoiper on laptop) to one extension
      and verify calls work between the two extensions

## Install module dependencies

- [ ] Module Admin → install `contactmanager` (16.0.17+), `cidlookup`
      (16.0.5+), `pm2` (13.0.3.8+)
- [ ] Verify via `fwconsole ma list | grep -E "contactmanager|
      cidlookup|pm2"`

## Install Node.js for the panel backend

- [ ] Install Node.js — version per `Callpanel.class.php:9`
      (currently `14.15.0` minimum). NodeSource 14.x repo:
      `curl -fsSL https://deb.nodesource.com/setup_14.x | bash -`
      then `apt install -y nodejs`
- [ ] If NodeSource 14.x is gone (likely — it's EOL), use the
      tarball from https://unofficial-builds.nodejs.org/download/
      release/latest-v14.x/ or step up to Node 16.x and edit
      `Callpanel.class.php`'s `$nodever` locally (note in findings)
- [ ] Verify `node --version` and `npm --version`

## Install the panel module

- [ ] Build tarball from local fork:
      ```
      cd ~/Documents/GITprojects/FreePBXDashboardUpdate
      tar czf /tmp/callpanel.tar.gz --exclude=node_modules \
          --exclude=.git --transform 's,^\./,callpanel/,' .
      ```
- [ ] Upload to sandbox: `scp /tmp/callpanel.tar.gz fpbx16-sandbox:/tmp/`
- [ ] Install via FreePBX Module Admin → Upload Modules → Upload
      Local. Watch the install output for errors.
- [ ] Apply Config
- [ ] Verify `pm2 list` (run as asterisk user) shows `callpanel`
      running
- [ ] Verify panel reachable at `http://<vm921-ip>:4848` or via the
      configured proxy

## Functional validation (against acceptance criteria)

- [ ] AC1: VM up + reachable ✓ (assumed if got this far)
- [ ] AC2: deps installed at minimum versions ✓
- [ ] AC3: module installs without errors ✓
- [ ] AC4: panel UI loads
- [ ] AC5a: active calls visible (make call between extensions)
- [ ] AC5b: call log appears after hangup
- [ ] AC5c: CallerID lookup works (configure a test entry first)
- [ ] AC6: contact CRUD round-trips to FreePBX ContactManager
- [ ] AC7: phonebook XML generation (yealink + fanvil)
- [ ] AC8: admin view loads and saves config
- [ ] Capture findings as each AC is tested

## Document + wrap

- [ ] Create `findings.md` with categorized results: works as-is,
      works with caveats, broken
- [ ] Update `specs/current-state.md` (phase-01 status)
- [ ] Update `specs/handoff.md` (next session points to phase-02)
- [ ] Snapshot VM 921: `qm snapshot 921 phase-01-baseline-complete`
- [ ] If everything passes: open phase-04 (ship to friend) as the
      next-priority phase
- [ ] If significant issues: spec phase-03 (forward-port) based on
      findings
