# Phase 01 — Plan

## Approach

Provision Debian 11 cloud VM → install FreePBX 16 via community Debian
script → install module from local fork tarball → exercise every
feature listed in upstream README → write findings.

No code changes to the module in this phase. If a fix is *trivial*
(typo, single-line) and necessary to even start the panel, edit
locally on the sandbox **and** flag the edit in findings.md so it gets
properly applied in phase-03.

## Architecture

```
┌──────────────────────────────────────────────┐
│  pmvm1 (Proxmox)                             │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ VM 921 — fpbx16-sandbox                │  │
│  │                                        │  │
│  │ Debian 11 (bullseye)                   │  │
│  │ ├─ Asterisk 18.x (pjsip)               │  │
│  │ ├─ FreePBX 16.0.45                     │  │
│  │ │   ├─ contactmanager >= 16.0.17       │  │
│  │ │   ├─ cidlookup >= 16.0.5             │  │
│  │ │   ├─ pm2 >= 13.0.3.8                 │  │
│  │ │   └─ callpanel (from local fork)     │  │
│  │ ├─ Node 14.x (from NodeSource)         │  │
│  │ ├─ MariaDB 10.5 (Debian 11 default)    │  │
│  │ └─ Apache 2.4 + PHP 7.4 or 8.1         │  │
│  └────────────────────────────────────────┘  │
│                                              │
└──────────────────────────────────────────────┘
            │
            │ vmbr0 (LAN bridge)
            ▼
   10.32.161.0/24 — Eric's LAN
```

## Install path decision tree

**Primary path:** [FreePBX 16 on Debian 11 community installer]
- Use the POSSA or community script: `freepbx_install_dist`
- Pros: matches Eric's "Debian please" preference
- Cons: not Sangoma-official; quality varies; may hit dep conflicts
  on newer Debian package versions

**Fallback path A:** Build from source per FreePBX wiki
(https://wiki.freepbx.org/display/FOP/Installing+FreePBX+16+on+Debian+11)
- Pros: fully controlled, no third-party script
- Cons: ~60-90 min install, lots of moving pieces

**Fallback path B:** FreePBX Distro 12.7 (SNG7) ISO
- Pros: Sangoma-official, what most production users actually run,
  closest to friend's likely environment
- Cons: not Debian (RHEL7-derived), Eric explicitly preferred Debian
- If we go here, document in changes.md why we deviated

**Decision:** start with primary path. If it fails within 30 min,
switch to fallback A. Note the choice in setup-log.md.

## Module install path

1. Build tarball from this fork:
   ```
   cd ~/Documents/GITprojects/FreePBXDashboardUpdate
   tar czf /tmp/callpanel.tar.gz --exclude=node_modules --exclude=.git \
       --transform 's,^\.,callpanel,' .
   ```
2. Upload via FreePBX UI:
   `Admin → Module Admin → Upload Modules → Upload Local`
3. Install + Apply Config from Module Admin
4. The PHP `install()` method in `Callpanel.class.php` triggers
   `npm install` in `calls-contacts-panel/` — this is where Node
   version mismatches surface.

## Schema changes

None. The panel uses FreePBX's existing schema (asterisk database +
contactmanager tables). The panel's own config is in JSON files
under the module directory, not the DB.

## Security surface

The panel exposes:

- HTTP server on port 4848 (default, configurable) — JSON API + WS
- Auth via bcrypt password (set in config) — single shared password
- Reads from FreePBX MariaDB via mysql2
- Connects to Asterisk AMI on localhost:5038

For this validation phase, leave the default auth setup as-is. Note
in findings.md if defaults are weak.

## What we're measuring

| Capability | How we test it | Pass criteria |
|---|---|---|
| Install completes | Run via Module Admin | No errors in install log; service starts |
| Active calls visible | Make test call between two pjsip extensions | Call shown in panel within 2s |
| Call log appears | Hang up after test call | Entry in panel within 5s |
| Contact CRUD | Create/edit/delete via panel UI | Changes show in FreePBX ContactManager |
| CallerID lookup | Incoming call from known number | Name resolves in panel |
| Phonebook XML | Click generate Yealink + Fanvil | Valid XML downloads, parseable |
| Make Call | Click extension → enter number | Asterisk originates call correctly |
| Admin view | `Admin → Calls + Contacts Panel` | Loads, save config persists |

## Performance considerations

Sandbox is throwaway — no perf testing needed in this phase. Just
note in findings.md if anything is comically slow (>5s for UI
operations) as that suggests a real issue.
