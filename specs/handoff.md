# Handoff — for the next Claude session

**Last updated:** 2026-05-19 (ship complete)

## Status

**Released:** [v17.0.1](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/tag/v17.0.1)
on 2026-05-19.

Validated end-to-end on:
- VM 921: Debian 12 + FreePBX 16.0.45 + Asterisk 18.26.4 + PHP 7.4
- VM 922: Debian 12 + FreePBX 17.0.28 + Asterisk 22.8.2 + PHP 8.2

Both: PM2 process online, all HTTP endpoints return 200, AMI
connected, all 4 monitors started (Active Calls, Call Logs,
Phonebook, Caller ID).

## What to start on

**The obvious next step is** deploying to Eric's friend's PBX. The
friend runs FreePBX 16.0.45 / Asterisk 18.9 / pjsip — same major
versions as the validated VM 921 sandbox. Procedure:

1. SSH to friend's PBX (or have Eric do it)
2. `cd /tmp && wget https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/download/v17.0.1/callpanel-17.0.1.tgz`
3. Extract: `sudo tar -xzf callpanel-17.0.1.tgz -C /var/www/html/admin/modules/`
4. Chown: `sudo chown -R asterisk:asterisk /var/www/html/admin/modules/callpanel`
5. Install: `sudo fwconsole ma install callpanel -f`
6. Apply Config (or `sudo fwconsole reload`)
7. Verify pm2: `sudo fwconsole pm2 --list | grep callpanel`
8. Browse to `http://<friend-pbx>:4848/callpanel/`

If friend wants Apache reverse-proxy on port 80, see the snippet in
the project README.md.

If something fails on friend's PBX that didn't fail on the sandbox,
diff his stack vs ours:
- Host OS (likely SNG7 / Rocky Linux on FreePBX Distro vs our Debian 12)
- Exact FreePBX 16 patch level (verify with `fwconsole --version`)
- Manager.conf format (look for the section name pattern)
- freepbx.conf quoting (single vs double — our regex handles both)

If Eric instead wants to skip the friend-deployment and pursue
modernization first — ask him first before starting any phase-05+
work.

## Open follow-ups (deferred, by phase)

### Phase 05 (modernization — when Eric chooses to invest)
- Frontend: migrate create-react-app → Vite (CRA deprecated 2025)
- Frontend: React 17 → 18
- Frontend: Tailwind 3 → 4 (when stable)
- Backend: axios 0.24 → 1.x (security CVEs in 0.x range)
- Backend: lint config in CI (removed from install pipeline)
- Backend: Jest 27 → 29

### Cross-cutting (any phase)
- Apache reverse-proxy automation in `Callpanel.class.php::install()`
- Per-user auth via FreePBX userman (security audit F-03)
- Restrict CORS origin to FreePBX host (security audit F-04)
- Bind backend HTTP to 127.0.0.1 (security audit F-05)
- SonarQube project (`freepbx-callpanel`) per sonarqube-playbook.md
- GitHub Actions: add CI workflow that runs `tsc --noEmit` and
  `npm run lint` on PRs (separate from release workflow)
- Investigate replacing `yana` AMI lib with something more actively
  maintained (last yana release was 2023)

## Deployment cheat-sheet

| Resource | Value |
|---|---|
| Proxmox host (cluster) | `pmvm1` / `pmvm2` (`pmcluster`) |
| FreePBX 16 sandbox VM | VMID **921**, name `fpbx16-sandbox`, IP **10.32.161.80** |
| FreePBX 17 sandbox VM | VMID **922**, name `fpbx17-sandbox`, IP **10.32.161.47** |
| Linux user (both) | `ejosterberg` |
| SSH aliases | `fpbx16-sandbox`, `fpbx17-sandbox` |
| GitHub fork | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel |
| Released tarball | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/download/v17.0.1/callpanel-17.0.1.tgz |
| Latest release URL | https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel/releases/latest |
| FreePBX 16 install log | `/var/log/freepbx16-install.log` (VM 921) |
| FreePBX 17 install log | `/var/log/pbx/freepbx17-install-*.log` (VM 922) |
| Panel install location | `/var/www/html/admin/modules/callpanel/` |
| Panel PM2 logs | `/var/lib/asterisk/.pm2/logs/callpanel-{out,error}.log` (FreePBX 16) or `/home/asterisk/.pm2/logs/...` (FreePBX 17) |

## Decisions logged

(Same as prior version — see git history)

## Anti-patterns to avoid

- **Don't tar to the working directory in CI** — tar sees its own
  output file change and aborts with "file changed as we read it".
  Always write to `/tmp/` or an out-of-tree path. (Bit us once
  shipping v17.0.0; fixed in v17.0.1.)
- **Don't force-push tags** — when a tag's CI fails, just bump the
  patch version and re-tag. Cleaner history.
- **Don't run `prebuild: npm run lint` at install time** — linting
  is a CI concern. Install-time should be the minimum needed to make
  the module run. (Bit us on first install attempt.)
- **Don't assume `localhost` resolves to IPv4 on Node 18+** — it
  resolves to ::1 first. Coerce to `127.0.0.1` when connecting to
  services that bind IPv4-only (MariaDB on Debian 12 defaults).
