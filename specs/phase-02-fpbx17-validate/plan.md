# Phase 02 — Plan

## Approach

Same as phase-01 but using:
- Debian 12 (bookworm) instead of 11
- Sangoma's official Debian installer (FreePBX 17 has one;
  FreePBX 16 didn't)
- Latest Asterisk 22 LTS
- Same unmodified module tarball

The key difference: this install path is well-documented, so it
should go faster than phase-01. The interesting work is the failure
characterization.

## Installer

Sangoma's official FreePBX 17 Debian installer:
- Repo: https://github.com/FreePBX/sng_freepbx_debian_install
- Single script: `sng_freepbx_debian_install.sh`
- Runs unattended after a few opening prompts
- Installs Asterisk 22, FreePBX 17, MariaDB, Apache, PHP, all deps

```bash
ssh fpbx17-sandbox 'curl -O https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh && sudo bash sng_freepbx_debian_install.sh' | tee /tmp/fpbx17-install.log
```

Expect ~30-45 min. Captures full log for the setup-log.md.

## VM 922 spec

| | |
|---|---|
| VMID | 922 |
| Name | `fpbx17-sandbox` |
| CPU | 4 |
| RAM | 8 GB |
| Disk | 60 GB on vmpool |
| Network | vmbr0 + DHCP |
| OS image | debian-12-genericcloud-amd64.qcow2 |

## Failure-capture protocol

For each issue:

1. **Reproduce minimally** — get to the failure with the smallest
   sequence of commands. Capture them.
2. **Capture context** — full log block from `pm2 logs callpanel`,
   `/var/log/asterisk/full`, browser console / network tab, FreePBX
   admin Notification panel.
3. **Compare with phase-01** — does the same step pass on FreePBX
   16? (Cross-reference required for the punch list to be useful.)
4. **Write up** — append to findings.md in the standard form.

## findings.md structure (template)

```
# Phase 02 findings

## Install-time failures
### F-01: <one-line title>
- **Reproduction:** ...
- **Expected (phase-01 behavior):** ...
- **Actual (phase-02 behavior):** ...
- **Hypothesis:** ...
- **Fix estimate:** trivial / small / large / unknown
- **Logs:**
  ```
  <relevant log block>
  ```

## Runtime failures
(same structure)

## UI / API failures
(same structure)

## Things that surprisingly worked
(also worth noting — saves time in phase-03)
```
