# Usage

End-user guide for the Calls + Contacts Panel UI. For installation
and admin configuration, see [INSTALL.md](INSTALL.md) and
[CONFIGURATION.md](CONFIGURATION.md).

## Logging in

Browse to `http://<your-freepbx-host>:4848/callpanel/` (or
whatever URL your admin gave you — if Apache reverse-proxy is
configured, it might be just `http://<host>/callpanel/`).

Enter your **FreePBX User Manager** credentials — the same
username and password you use for the FreePBX User Control Panel
(UCP).

If your login fails:

- Check you have the right permissions (your admin needs to enable
  PBX Admin OR give you CDR Reports + Contact Manager in your User
  Manager profile)
- Confirm your User Manager account has a **Default User
  (Extension)** set — outbound calls fail without one

## UI overview

After login, you'll see a header with three sections (depending on
window size, these may be collapsed into a hamburger menu):

| Section | Purpose |
|---|---|
| **Calls** | Live view of active calls + searchable call log history |
| **Contacts** | Browse, search, create, edit, delete contacts |
| **Make Call** | Initiate an outbound call from your extension |

Plus a logout button.

## Calls view

### Active Calls

The top panel shows every call currently in progress on the PBX.
Each row has:

| Column | What it shows |
|---|---|
| **From** | Caller — display name (if matched to a contact), phone number, optionally a contact link |
| **To** | Callee — same fields |
| **Status** | Channel state: Ringing / Up (in-progress) / etc. |
| **Duration** | Time since the call established (HH:MM:SS) |
| **App** | Asterisk dialplan application currently running (Dial, Bridge, etc.) |
| **Channel** | Asterisk channel identifier (e.g., `PJSIP/100-00000045`) |

The list updates every **1 second** (configurable — see
[CONFIGURATION.md → Check for Active Calls Interval](CONFIGURATION.md#check-for-active-calls-interval-ms)).
Calls disappear from the view when they hang up; you'll find them
in the Call Logs section below.

If a caller's number matches a saved contact, the contact's name
shows in green (with a clickable link to the contact card). If
the number is unknown, you'll see a **Save as new contact** /
**Add to existing contact** action — click to capture the number
without leaving the page.

### Call Logs

Below active calls is a searchable history. Each row has the
same fields as Active Calls (plus end timestamp and call
direction). The list shows up to **1000** entries by default.

Use the search box to filter by:

- Caller / callee name
- Phone number (full or partial)
- Date range (depending on UI version)

The call log monitor polls the Asterisk CDR database every
**3 seconds** (configurable). New entries appear without needing
to refresh.

### Save unknown numbers as contacts

When a call comes in (or out) from a number not in your address
book, click the "Save" or "+" action on that row:

- **Save as new contact** — opens the Contact Editor with the
  number pre-filled. Add a name, save.
- **Add to existing contact** — search dropdown of all your
  contacts. Pick one. The number is appended to that contact's
  numbers list with a type you choose (Work / Mobile / Home / etc.).

## Contacts view

### Browse

Contacts are pulled from FreePBX's **Contact Manager** module
(`contactmanager_*` tables). Anything added here syncs back to
FreePBX → Admin → Contact Manager, and vice versa.

Each contact card shows:

- Name (first + last + company)
- Multiple phone numbers, each typed (Work / Mobile / Home /
  Fax / etc.)
- Multiple email addresses (typed)
- Multiple websites (typed)
- Speed dial assignment (if any)
- Image / avatar (if uploaded)

### Search

The search box does fuzzy matching across name, company, all
numbers, and all emails. As you type, the contact list filters
in real time.

### Create / edit

Click the **+ New** button (or any existing contact, then Edit)
to open the Contact Editor:

1. Fill in name + company (any combination — all optional)
2. Click "Add Number" / "Add Email" / "Add Website" to add fields
3. For each number, choose a type from the dropdown
4. Optionally upload an image (gets stored in FreePBX's
   `contactmanager_entry_images`)
5. Click Save

Changes propagate to FreePBX Contact Manager immediately.

### Delete

Click the trash icon on a contact card, confirm. The contact and
all its numbers/emails/etc. are removed.

### Bulk import (CSV)

The panel includes a CSV import flow:

1. Contacts view → click the CSV upload icon
2. Select a CSV file (UTF-8 encoded)
3. Map columns to fields (Name, First Name, Last Name, Company,
   Number 1, Type 1, Email, etc.)
4. Preview the parsed rows
5. Click Import

Common spreadsheet exports (Google Contacts, Outlook .csv, iCloud
.csv) are supported with manual column mapping. There's no
de-duplication on import — if you import the same CSV twice, you
get duplicate contacts.

## Make Call

Click **Make Call** in the header to open the dialer:

1. **From extension** — defaults to your User Manager's "Default
   User Extension". If you have permission, you can change this to
   any other extension or ring group.
2. **To number** — enter the destination. Internal extension,
   external phone number, anything you'd dial from a desk phone.
3. Click **Call**.

What happens: the panel issues an Asterisk AMI `Originate`
action. Your "from" extension rings; when you answer (pick up the
handset), the call attempts to connect to the destination. This
is the standard "click-to-dial" pattern.

The originating context is `from-internal` with the same dialing
rules as if you'd typed the number on your desk phone, including:

- Outbound route selection by dial pattern
- Caller ID rewriting
- Time conditions
- All other FreePBX dialplan logic

If your "from" extension doesn't ring, common causes:

- Extension isn't registered (check `sudo fwconsole pjsip show
  endpoints`)
- Your User Manager account has no Default Extension set
- The originate-skipvm context (used to skip your voicemail
  greeting on pickup) isn't configured — this is FreePBX-standard,
  but custom dialplans may have disabled it

## Caller ID matching

When a call arrives, the panel tries to match the caller's number
against your contacts. Matching uses:

1. **Exact match** — fastest path
2. **Last-N-digits match** — if no exact, compare the last
   `callerIdResolveLength` digits (default 6) of the incoming
   number against the last N of every contact number
3. **Prefix stripping** — if you've set
   [Caller ID Prefixes](CONFIGURATION.md#caller-id-prefixes), the
   panel also tries stripping each prefix from both sides of the
   comparison

Why this matters: phone systems are inconsistent about including
area codes. A contact saved as `5550100` should match an
incoming call presented as `+1212-555-0100` — with last-7-digit
matching, it does.

The match result is what shows as the caller's display name in
both Active Calls and Call Logs.

## Phonebooks for IP phones

The panel exposes two read-only HTTP endpoints that serve your
contacts as XML in formats IP phones understand:

- **Yealink:** `http://<host>:4848/callpanel/yealink-phonebook.xml`
- **Fanvil:** `http://<host>:4848/callpanel/fanvil-phonebook.xml`

Point your phones at these URLs and they'll display your contacts
on the phone's screen + match incoming caller IDs against them.

See [PROVISIONING-YEALINK.md](PROVISIONING-YEALINK.md) and
[PROVISIONING-FANVIL.md](PROVISIONING-FANVIL.md) for the phone-side
setup steps.

## CallerID Lookup REST endpoint

For integration with FreePBX's CID Lookup module, the panel also
exposes:

```
http://<host>:4848/callpanel/lookupcallerid?number=<phone-number>
```

It returns plain text — either the matched contact's combined
name, or the original number if no match was found.

In FreePBX:

```
Admin → CallerID Lookup Sources → Add Source
```

Set:
- **Source Type:** HTTP
- **URL:** `http://localhost:4848/callpanel/lookupcallerid?number=`
- (everything else: default)

Then assign this source to your inbound routes. The screenshot
in the project README shows what the config should look like.

## Multi-language support

The UI supports multiple languages via `i18next`. Currently
shipped:

- 🇺🇸 / 🇬🇧 English
- 🇩🇪 German (Deutsch)

The frontend auto-detects from your browser's `Accept-Language`
header and falls back to English. To add a language, see
[the project README](../README.md#adding-a-language).

## What the panel does NOT do

To set expectations:

- **Not a softphone.** The Make Call feature rings your existing
  extension; it doesn't audio in/out of your browser.
- **Not a UCP replacement.** It overlaps with FreePBX UCP for
  contacts + call history, but doesn't do voicemail, fax, conference
  rooms, presence, chat, etc.
- **Not multi-tenant.** All users see all calls and all contacts;
  there's no per-user filtering.
- **Not a CRM.** Contacts are simple cards — no notes, no
  activity history beyond call logs, no integrations.

If you need any of the above, look at FreePBX's commercial UCP
or a dedicated CRM tool.
