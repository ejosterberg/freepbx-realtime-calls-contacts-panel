# FAQ

## Compatibility

### Does this work on FreePBX 16?

Yes — fully supported. The fork was originally built for FreePBX 16
and validated on FreePBX 16.0.45 + Asterisk 18.x + PHP 7.4 +
Debian 12.

### Does this work on FreePBX 17?

Yes — added in v17.0.0 of this fork. Validated on FreePBX 17.0.28 +
Asterisk 22.8.2 + PHP 8.2 + Debian 12.

### Does the same tarball install on both versions?

Yes. The `module.xml` declares both `<version>16.0</version>` and
`<version>17.0</version>` as supported. No conditional code paths —
same source, same build, both targets.

### What about FreePBX 15 or earlier?

Not supported. FreePBX 15 is EOL and out of scope.

### What about FreePBX 18 (when released)?

Currently unknown. As FreePBX 18 lands, this fork will be tested
and (if needed) patched to support it.

### What Linux distros does this work on?

The PHP module wrapper is host-OS agnostic. Validated on:

- **Debian 12 (bookworm)** — explicit test platform for both
  FreePBX versions
- **FreePBX Distro 12.7 (SNG7 / RHEL 7-derived)** — untested by
  this fork, but the module's code doesn't use anything
  distro-specific; should work
- **Rocky Linux 8 / FreePBX Distro 12.8** — untested, same caveat

If you confirm a distro works (or doesn't), please open an issue.

### Does this work on FreePBX Distro vs hand-installed FreePBX?

Both should work. The validation sandbox was a hand-installed
FreePBX on plain Debian 12. FreePBX Distro provides a slightly
different filesystem layout but the panel respects FreePBX's
own `fwconsole`-resolved paths, so it adapts automatically.

### What about chan_sip (not pjsip)?

The panel reads AMI's `CoreShowChannels` action, which returns
all channels regardless of channel driver. It should work with
chan_sip too — but chan_sip is deprecated since Asterisk 17 and
not recommended for new deployments.

## Features

### Can I make calls from the browser (softphone mode)?

No. The panel's "Make Call" feature triggers a server-side
originate that rings your existing extension — the audio still
flows through your desk phone or registered softphone. The panel
itself doesn't do RTP, WebRTC, or browser audio.

If you want a full WebRTC softphone in the browser, look at
FreePBX UCP or third-party tools like sipML5.

### Can I see who's parked / on hold?

Active calls in any channel state are shown, including held calls
(channel state "Hold"). Park slots specifically aren't broken out
as a separate view — they appear as regular channels.

### Can I record calls from the panel?

No. Call recording is controlled by FreePBX's dialplan and
extension settings. The panel shows whether a call is being
recorded (via the channel's recording flag) but doesn't expose
start/stop controls.

### Can I transfer calls from the panel?

No. Transfers are done from the phone, not the panel.

### Can multiple users see each other's contacts?

Yes — all logged-in users see the same shared contact list (the
FreePBX Contact Manager database). There's no per-user filtering.

### Can users only see their own call history?

No — same as contacts, the call log is shared across all panel
users. If you need per-user filtering, you'd need to modify the
panel's call-logs query.

### Can I integrate with my CRM?

There's no native CRM integration. The panel exposes a REST
endpoint for caller ID lookup (`/callpanel/lookupcallerid?number=...`)
which third-party tools could poll, but there's no outbound
webhook or push notification.

### Can I customize the UI?

It's a React app built with Tailwind. To customize, fork the
repo and rebuild — the source is in `calls-contacts-panel/frontend/src/`.
There's no plugin system or theme support.

## Performance

### How many concurrent calls can the panel handle?

The panel polls AMI every 1 second by default. Each poll returns
all active channels and serializes them as a list update over
WebSocket. For a typical home/small-business PBX (< 50 concurrent
calls, < 20 panel users), this is well within Node 18's capacity.

Memory footprint: ~80 MB per panel backend process. PM2 will
restart it if memory grows unbounded.

### Will polling Asterisk every 1 second hurt my PBX?

Not measurably. `CoreShowChannels` is a simple AMI action that
serializes existing channel state — it doesn't trigger any
dialplan work. Asterisk handles it in microseconds.

### What about the 3-minute phonebook refresh?

This re-queries the `contactmanager_*` tables. With < 10,000
contacts the query is fast (< 100 ms). The panel keeps the result
in memory and serves matches locally, so individual caller-ID
lookups don't hit the DB.

### Can I run this on a Raspberry Pi?

Probably — the panel's CPU usage is low. RAM is the constraint
(Node + frontend build needs ~512 MB free). A Pi 4 with 2 GB+
should be fine.

## Security

### Are passwords stored in the panel?

No. Authentication delegates to FreePBX's User Manager. The
panel reads `userman_users` via the FreePBX DB connection and
calls bcrypt.compare against the user-provided password. The
panel itself stores no credentials.

### Are panel users separate from FreePBX users?

No — same accounts. If a user can log in to FreePBX UCP with
their credentials, they can log in to the panel (subject to the
permission check — see
[CONFIGURATION.md → Access control](CONFIGURATION.md#access-control)).

### Is the WebSocket connection encrypted?

By default, no — the panel listens on plain HTTP port 4848. For
production, run behind Apache reverse-proxy on HTTPS (see
[INSTALL.md → Apache reverse proxy](INSTALL.md#optional-apache-reverse-proxy)).

### Is there fail2ban integration?

Not directly. Failed authentication attempts are logged to the
PM2 stdout log. You could write a fail2ban filter to detect
"authentication failed" lines in
`/var/lib/asterisk/.pm2/logs/callpanel-out.log` if you wanted to
add this.

### Has this been security-reviewed?

A basic security audit is at [`specs/security/audit-2026-05-19.md`](../specs/security/audit-2026-05-19.md).
It identified the auth model + a few known limitations. A full
formal review (SonarQube, dependency CVE scan, penetration test)
has not been performed.

## Licensing

### What license is this under?

AGPL-3.0-only. Inherited from upstream
([adroste/freepbx-realtime-calls-contacts-panel](https://github.com/adroste/freepbx-realtime-calls-contacts-panel)),
non-negotiable.

### Can I use this commercially?

Yes — AGPL allows commercial use. But if you offer it as a
network service to customers, AGPL §13 requires offering source
to those users (typically via a "Download source" link in the
UI).

### Can I fork this?

Yes. Per AGPL, your fork must remain AGPL-3.0 and you must state
your modifications (a CHANGES.md or equivalent). See this fork's
[CHANGES.md](../CHANGES.md) for an example.

### Can I include this in a proprietary FreePBX distribution?

Probably not, due to AGPL. You'd be combining proprietary and
AGPL code in a way that requires the combined work to be AGPL.
Consult a lawyer.

## Upgrades & maintenance

### How often is this fork updated?

No release cadence. Updates land as needed — bug fixes, new
FreePBX/Asterisk versions, security patches. Watch the GitHub
releases page or use a GitHub Atom feed.

### Will upstream ever come back to life?

Unlikely. The upstream repo was archived in 2022. This fork is
the active maintenance line.

### Can I contribute back?

Yes — pull requests welcome at
[github.com/ejosterberg/freepbx-realtime-calls-contacts-panel](https://github.com/ejosterberg/freepbx-realtime-calls-contacts-panel).
Please read the [specs/constitution.md](../specs/constitution.md)
first to understand the project's invariants.

## Comparison

### How does this compare to FreePBX UCP?

| | This panel | FreePBX UCP |
|---|---|---|
| Real-time active calls | ✅ | ✅ (with limitations) |
| Call log search | ✅ | ✅ |
| Contact CRUD | ✅ (better UI) | ✅ |
| Click-to-call | ✅ | ✅ |
| Voicemail / Fax | ❌ | ✅ |
| Conference rooms | ❌ | ✅ |
| Chat / presence | ❌ | ✅ |
| Phonebook XML for IP phones | ✅ | ❌ |
| Caller ID REST endpoint | ✅ | ❌ |
| Multi-language UI | ✅ (en/de) | ✅ |
| Cost | Free (AGPL) | Free (open source UCP) or paid (Sangoma Connect) |
| FreePBX dependencies | contactmanager, cidlookup, pm2, userman | All FreePBX modules |
| Code maturity | Forked / community-maintained | Sangoma-maintained |

Use both side-by-side if you want — they don't conflict. The
panel is focused on **realtime call visibility + contact
management** with a better-than-UCP UI for those specific
tasks. For everything else, UCP is more featureful.

### How does this compare to commercial Sangoma Connect / FreePBX RestApps?

Sangoma Connect is a complete UC platform — softphone, video,
chat, presence, mobile apps. This panel is a focused web tool for
admin-style call visibility and contact management. They serve
different purposes.

If you need a full UC platform, Sangoma Connect or similar
commercial offerings are the answer.

If you just want a beautiful realtime panel + phonebook
generator + caller-ID enrichment, this panel does that and nothing
else.
