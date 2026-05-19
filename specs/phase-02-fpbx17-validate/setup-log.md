# Phase 02 — Setup log (operational record)

## Environment

| | |
|---|---|
| Proxmox host | `pmvm1` |
| VMID | **922** |
| VM name | `fpbx17-sandbox` |
| OS | Debian 12 (bookworm) |
| Specs | 4 CPU, 8 GB RAM, 60 GB disk on vmpool |
| Network | vmbr0 + DHCP |
| Linux user | `ejosterberg` |
| SSH alias | `fpbx17-sandbox` (post-IP) |
| IP | _TBD_ |
| MAC | _TBD_ |

## Commands run

### 1. Download Debian 12 cloud image (2026-05-19)

```bash
ssh proxmox-workshop 'wget -q https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 -O /var/lib/vz/template/iso/debian-12-genericcloud-amd64.qcow2'
```

### 2. Create VM 922 via cloud-init

(Pending.) Template — same as VM 921 but VMID=922, NAME=fpbx17-sandbox,
ISO=debian-12-genericcloud-amd64.qcow2.

### 3. Run Sangoma FreePBX 17 Debian installer

(Pending.)

```bash
ssh fpbx17-sandbox <<'INSTALL'
cd /tmp
curl -O https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh
sudo bash sng_freepbx_debian_install.sh 2>&1 | tee fpbx17-install.log
INSTALL
```

## Decisions

(Empty.)

## Snapshots

Suggested:
- `phase-02-base-debian` — post-Debian-update, pre-FreePBX
- `phase-02-freepbx-clean` — post-FreePBX-install, extensions configured
- `phase-02-baseline-failure-captured` — after module install attempted + findings.md complete
