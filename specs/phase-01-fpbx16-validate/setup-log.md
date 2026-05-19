# Phase 01 — Setup log (operational record)

Append-as-you-go log of every command, config, and decision during
the sandbox provisioning + install. Future-you (or another Claude
session) will reproduce this exact procedure when shipping to the
friend's PBX.

## Environment

| | |
|---|---|
| Proxmox host | `pmvm1` (cluster `pmcluster`) |
| VMID | **921** |
| VM name | `fpbx16-sandbox` |
| OS | Debian 11 (bullseye) |
| Specs | 4 CPU, 8 GB RAM, 60 GB disk on vmpool |
| Network | vmbr0 + DHCP |
| Linux user | `ejosterberg` |
| SSH alias | `fpbx16-sandbox` (added post-IP-discovery) |
| IP | _TBD post-cloud-init_ |
| MAC | _TBD post-create_ |

## Commands run

### 1. Download Debian 11 cloud image (2026-05-19)

Initiated on Proxmox host (background download):

```bash
ssh proxmox-workshop 'wget -q https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2 -O /var/lib/vz/template/iso/debian-11-genericcloud-amd64.qcow2'
```

_Status as of writing: download in progress._

### 2. Create VM 921 via cloud-init

(Pending — to be filled in once executed.)

Template command (per proxmox-playbook.md):

```bash
ssh proxmox-workshop bash <<'PROVISION'
set -e
VMID=921
NAME=fpbx16-sandbox
MEM=8192
CORES=4
DISK=60
ISO=/var/lib/vz/template/iso/debian-11-genericcloud-amd64.qcow2

qm create $VMID \
  --name $NAME --memory $MEM --cores $CORES --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-single \
  --serial0 socket --vga serial0 \
  --agent enabled=1 --ostype l26

qm importdisk $VMID $ISO vmpool
qm set $VMID --scsi0 vmpool:vm-$VMID-disk-0,discard=on,ssd=1
qm set $VMID --ide2 vmpool:cloudinit
qm set $VMID --boot order=scsi0
qm resize $VMID scsi0 ${DISK}G

qm set $VMID --ciuser ejosterberg
qm set $VMID --sshkeys /root/.ssh/authorized_keys
qm set $VMID --ipconfig0 ip=dhcp

qm start $VMID
PROVISION
```

### 3. Discover IP

(Pending.) Per playbook, options:
- arp-scan against vmbr0 for the VM's MAC
- tcpdump for outbound traffic
- Cloud-init injects qemu-guest-agent? (No — debian cloud image
  doesn't include it; we'll install it post-boot)

### 4. SSH alias

(Pending.) Once IP is known, add to `~/.ssh/config` on Eric's box:

```
Host fpbx16-sandbox
  HostName <discovered-ip>
  User ejosterberg
  IdentityFile ~/.ssh/proxmox_workshop
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
```

### 5. FreePBX 16 install

(Pending.) See plan.md for the decision tree (community installer →
fallback A: wiki manual install → fallback B: SNG7 ISO).

## Decisions

(Empty — fill in as choices are made.)

## Snapshots

(Empty — snapshot at each milestone.)

Suggested milestones:
- `phase-01-base-debian` — after Debian + updates, before FreePBX
- `phase-01-freepbx-clean` — after FreePBX 16 + extensions configured
- `phase-01-baseline-complete` — after panel module installed + validated
