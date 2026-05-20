# Handoff — for the next Claude session

**Last updated:** 2026-05-20 (after v17.0.3 ship + sandbox cleanup)

## Status

**Latest release:** [v17.0.3](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.3)
— production-quality, end-to-end validated on Debian 12 + Rocky 8.

**Sandboxes:** all 3 VMs (921, 922, 923) destroyed 2026-05-20. SSH
config aliases (`fpbx16-sandbox`, `fpbx17-sandbox`, `fpbx16-rocky-sandbox`)
removed from `~/.ssh/config`. To re-test, re-provision from the install
scripts in `specs/phase-01-fpbx16-validate/`, `phase-02-fpbx17-validate/`,
and `phase-06-production-validation/`.

**Cached on Proxmox** (still useful):
- `/var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2`
- `/var/lib/vz/template/iso/debian-13-genericcloud-amd64.qcow2`
- `/var/lib/vz/template/iso/Rocky-8-GenericCloud.latest.x86_64.qcow2`
- `/var/lib/vz/template/iso/SNG7-PBX16-64bit-2306-1.iso` (interactive,
  unused — kept in case future testing wants the real FreePBX Distro
  install rather than the Rocky surrogate)

## What to start on (if anything)

There is no urgent next task. v17.0.3 is shipped and stable. The
remaining work is all in [`phase-05-modernization/IMPROVEMENTS.md`](phase-05-modernization/IMPROVEMENTS.md)
and is opt-in:

| Priority | Item | Rough effort |
|---|---|---|
| Medium | I-04 CRA → Vite migration (clears 14 frontend high CVEs) | 1-2 days |
| Medium | I-05 React 17 → 18 | 1 day |
| Medium | I-06 jest 27 → 29 (clears 6 backend high CVEs) | half day |
| Low | I-01 Bind backend to 127.0.0.1 (defense in depth) | 1 hr |
| Low | I-08 CI workflow for lint + tests | 2 hr |

**If Eric's friend deploys v17.0.3 and reports issues**, the obvious
next step is reproducing on a fresh sandbox matching his exact stack
and patching from there. Procedure:

1. Confirm friend's exact stack: `fwconsole --version`,
   `asterisk -rx 'core show version'`, `cat /etc/os-release`
2. Provision matching sandbox per
   [`phase-06-production-validation/install-fpbx16-rocky.sh`](phase-06-production-validation/install-fpbx16-rocky.sh)
   (or Debian path if he runs Debian)
3. Install v17.0.3 tarball — verify same failure
4. Capture: panel error logs, browser console, AMI events
5. Fix, re-test, ship v17.0.4

**If Eric instead asks for new features** — read
[`specs/constitution.md §9`](constitution.md) first to confirm the
feature isn't explicitly out of scope. Common asks that are OUT of
scope: WebRTC softphone, mobile app, multi-tenant SaaS, replacing
Contact Manager.

## Open follow-ups

### From the v17.0.3 production-validation pass
- [ ] Native-speaker review of es/fr/it translations — open as
      crowdsourceable issues with `i18n` label
- [ ] Friend's PBX deployment (when he's ready)

### Cross-cutting
- [ ] SonarQube quarterly scan reminder (Q3 2026)
- [ ] `npm audit` before every release (now codified in
      constitution.md §5a)
- [ ] React 18 + Vite migration when Eric's ready to invest the time

### Deferred / discussed but not built
- Per-user auth filtering (currently all panel users see all contacts/
  calls) — documented as known limitation in FAQ + audit
- Bind backend to 127.0.0.1 only (breaking change, would be v18.0.0)

## Deployment cheat-sheet (post-cleanup)

| Resource | Value |
|---|---|
| Proxmox host | `pmvm1` (cluster `pmcluster`) |
| SSH alias for Proxmox | `proxmox-workshop` |
| Next free VMID for sandboxes | **924** (921-923 used + destroyed) |
| Linux user (any sandbox) | `ejosterberg` |
| Sandbox SSH key | `~/.ssh/proxmox_workshop` |
| Storage pool | `vmpool` (ZFS, cluster-shared) |
| GitHub fork | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel |
| Latest release tarball | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest/download/callpanel-17.0.3.tgz |
| SonarQube project | http://10.32.161.205:9000/dashboard?id=freepbx-callpanel |
| gh CLI auth | logged in as ejosterberg, scopes: repo + workflow + gist + read:org |

## Reproducing the sandbox setup (if needed)

### Debian 12 + FreePBX 16 (matches friend's likely env)
```bash
# Provision VM per proxmox-playbook.md, then:
scp specs/phase-01-fpbx16-validate/install-fpbx16.sh <vm>:/tmp/
ssh <vm> 'sudo bash /tmp/install-fpbx16.sh'
# ~30-45 min
```

### Debian 12 + FreePBX 17 (latest)
```bash
# Provision VM per proxmox-playbook.md, then:
ssh <vm> 'cd /tmp && curl -O https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh && sudo bash sng_freepbx_debian_install.sh'
# ~45-60 min (Sangoma installer)
```

### Rocky 8 + FreePBX 16 (RHEL-family / SNG7 surrogate)
```bash
scp specs/phase-06-production-validation/install-fpbx16-rocky.sh <vm>:/tmp/
ssh <vm> 'sudo bash /tmp/install-fpbx16-rocky.sh'
# ~30-45 min, all 4 known package gotchas baked into the script
```

### Panel install (any of the above)
```bash
ssh <vm> 'sudo wget -q https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest/download/callpanel-17.0.3.tgz -O /tmp/callpanel.tgz \
  && sudo tar -xzf /tmp/callpanel.tgz -C /var/www/html/admin/modules/ \
  && sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel \
  && sudo fwconsole ma install callpanel -f'
# ~5-10 min (npm ci + builds backend + frontend)
```

## Decisions logged (full history)

(See previous handoff.md versions in git for the running log. As of
2026-05-20 the key decisions still in effect are:)

- Project license: AGPL-3.0-only (cannot be changed)
- Target FreePBX versions: 16 + 17 (single tarball supports both)
- Build host: Debian 12 (Sangoma's official platform); Rocky 8
  validated as RHEL-family proxy for SNG7
- Auth: FreePBX User Manager (bcrypt-hashed passwords required;
  FreePBX-stores-plaintext is upstream-bug-noted in audit)
- Spec-driven workflow per `~/.claude/spec-kit-playbook.md`
- Ship verification per `specs/constitution.md §5a` (5 checks before
  declaring "shipped")

## Anti-patterns to avoid (lessons from this project)

1. **Don't claim "shipped" without running available quality tooling.**
   v17.0.1 was declared shipped without `npm audit` or SonarQube;
   v17.0.2 was the security-fix release that cleared 12 critical CVEs
   the audit caught.

2. **Don't claim "UI works" based on HTTP 200.** Curl proves the
   bundle serves, not that the UI renders. Use Chrome MCP or Playwright
   to actually drive a browser before saying it works.

3. **Don't trust the docs to be correct just because you wrote them.**
   The Apache reverse-proxy snippet in INSTALL.md (v17.0.0-17.0.2) was
   broken for WebSocket. Discovered + fixed in v17.0.3 by actually
   trying it end-to-end with a real WS client.

4. **Don't rate effort by mechanical work alone.** Translation files
   are easy to mechanically generate but quality review is the hard
   part — rate "Very Low" only if BOTH halves are easy.

5. **Don't try to fix things by destructive shortcuts.** When the
   FreePBX install hit a cron error, the right move was `apt install
   cron` then resume, not nuke + restart. Investigate root causes.

6. **For force-pushes / tag rewrites — bump version instead.** v17.0.0
   shipped with a broken CI; I deleted the failed run but didn't
   force-push the tag. v17.0.1 was the fix release. Cleaner history.
