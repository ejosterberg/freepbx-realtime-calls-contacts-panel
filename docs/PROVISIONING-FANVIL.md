# Provisioning Fanvil phones for the panel's phonebook

This guide walks you through pointing a Fanvil IP phone at the
panel's Fanvil-format phonebook XML.

## Prerequisites

- Calls + Contacts Panel installed and running (see [INSTALL.md](INSTALL.md))
- A Fanvil phone reachable on the same network as your FreePBX host
- Recent Fanvil firmware (most X-series and i-series phones from
  2019+ support remote phonebooks)
- You can log in to the phone's web UI as an admin

## The phonebook URL

```
http://<your-freepbx-host>:4848/callpanel/fanvil-phonebook.xml
```

Or, if you've configured Apache reverse-proxy:

```
http://<your-freepbx-host>/callpanel/fanvil-phonebook.xml
```

Test in a browser first. You should see an XML document starting with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <contact>
    ...
  </contact>
</root>
```

(The exact root tag depends on what Fanvil expects — the panel
emits the format Fanvil documents for remote phonebooks.)

## Phone-side setup (web UI)

Fanvil's web UI calls this feature "Cloud Phonebook". The
workflow on most X-series phones (X3/X5/X6/X7) is:

1. Log in to the phone's web UI as **admin** (default password
   is `admin` — change it!)
2. Navigate to **Phonebook → Cloud Phonebook**
3. Click **Add** (or edit an empty slot)
4. Fill in:
   - **Cloud Phonebook URL:** paste the panel's
     fanvil-phonebook.xml URL
   - **Calling Search:** set how the phone matches incoming calls
     (typically "Search by Phone Number")
   - **Name:** display name shown on the phone
   - **Username / Password:** leave blank (the panel's phonebook
     endpoint is unauthenticated; if you've put it behind HTTPS
     basic auth via the Apache reverse-proxy, fill these in)
5. Save / Apply

## Auto-refresh

Fanvil phones refresh cloud phonebooks on a configurable
interval:

1. **Phonebook → Cloud Phonebook → (select your entry)**
2. Set **Refresh Time** (seconds)
   - Default: typically `3600` (1 hour)
   - For dynamic environments: `300` (5 minutes)
   - For static contacts: `86400` (1 day)

## Incoming-call match

To make the phone show contact names on incoming calls:

1. **Phonebook → Cloud Phonebook → (select your entry)**
2. Tick **Incoming Calls** (or "Calling Search")
3. Save

Now when a call arrives, the phone queries the cloud phonebook
and displays the matching contact name.

## Provisioning via auto-provision

Fanvil's auto-provisioning system (DHCP option 66 / HTTPS
template URL) lets you bake cloud phonebooks into the phone's
config file:

```ini
# In your <MAC>.cfg or template.cfg:

# Cloud Phonebook 1
<Cloud Phonebook>
xml1_url = http://your-freepbx-host:4848/callpanel/fanvil-phonebook.xml
xml1_name = Office Contacts
xml1_refresh = 3600
xml1_search = 1
</Cloud Phonebook>
```

(Fanvil's INI keys vary by firmware — consult their
"Auto-Provisioning Manual" PDF for the model.)

## Multiple phonebooks

Fanvil phones typically support up to 8 cloud phonebooks. You
can register the panel's phonebook plus other sources (LDAP,
remote XML, etc.) and they'll all be browseable from the phone's
directory menu.

## Troubleshooting Fanvil-specific issues

### Phone says "Download failed" or "Update failed"

- Verify the URL is reachable from the phone's network (try
  `curl` from another machine on the same VLAN)
- If the URL uses Apache reverse-proxy on HTTPS with self-signed
  certs, the phone may reject — install your CA cert on the
  phone OR use HTTP for the phonebook even if FreePBX uses HTTPS
  elsewhere
- Check the phone's debug log (Maintenance → Diagnostic Tools →
  System Log) for the exact failure mode

### Phonebook downloads but no contacts appear

- Confirm the XML is valid (`xmllint` it if you have it)
- Check that contact entries have at least a name AND a number —
  Fanvil typically skips entries with neither
- Test against a different known-good cloud phonebook URL (Fanvil
  ships sample XMLs in their docs) to isolate phone-side vs
  panel-side

### Incoming call shows the number, not the contact name

- Confirm "Incoming Calls" / "Calling Search" is enabled
- Verify the number format Asterisk presents matches what's
  saved in the contact — see
  [CONFIGURATION.md → Caller ID Prefixes](CONFIGURATION.md#caller-id-prefixes)
- Check the phone's "Refresh Time" — if the phonebook hasn't
  refreshed since you added the contact, the match doesn't fire.
  Manually refresh: **Phonebook → Cloud Phonebook → (your entry)
  → Update**

### Phonebook forgets contacts after reboot

- The phone uses local cache that's reloaded on the refresh
  interval. After reboot, the phone re-downloads — make sure the
  panel is reachable at boot time (if FreePBX boots slower than
  the phone, the phone's first refresh attempt fails)
- Increase the refresh time so the cache survives longer

## Tested with

The Fanvil phonebook endpoint was upstream-tested before the 2022
archive. This fork has **not** independently re-tested against
physical Fanvil hardware. The XML format is unchanged from
upstream.

If you confirm a model works (or doesn't), please file an issue
or PR.

## Reference URLs

- [Fanvil downloads + manuals](https://www.fanvil.com/Support/download.html)
  (firmware, auto-provisioning guides, admin guides per model)
