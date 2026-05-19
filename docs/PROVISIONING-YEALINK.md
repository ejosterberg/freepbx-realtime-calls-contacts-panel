# Provisioning Yealink phones for the panel's phonebook

This guide walks you through pointing a Yealink IP phone at the
panel's Yealink-format phonebook XML so the contacts you manage in
FreePBX appear on the phone's screen.

## Prerequisites

- Calls + Contacts Panel installed and running (see [INSTALL.md](INSTALL.md))
- A Yealink phone reachable on the same network as your FreePBX host
- Phone firmware ≥ V81 (most T-series phones from 2018+ are fine)
- You can log in to the phone's web UI as an admin

## The phonebook URL

```
http://<your-freepbx-host>:4848/callpanel/yealink-phonebook.xml
```

If you've configured the Apache reverse-proxy snippet from
[INSTALL.md](INSTALL.md#optional-apache-reverse-proxy), use:

```
http://<your-freepbx-host>/callpanel/yealink-phonebook.xml
```

Test it first by hitting the URL in a browser. You should see an
XML document starting with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<YealinkIPPhoneBook>
  <Title>Phonebook</Title>
  <Menu Name="...">
    ...
  </Menu>
</YealinkIPPhoneBook>
```

If the URL returns a 200 with that XML, the phone will accept it.
If you get a 404 or empty response, see
[TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Phone-side setup (web UI)

The exact path varies slightly across Yealink models, but on
T46/T48/T52/T54 the workflow is:

1. Log in to the phone's web UI as **admin** (default password
   is `admin` on factory-reset phones — change it!)
2. Navigate to **Directory → Remote Phone Book**
3. In the first empty row:
   - **Remote URL:** paste the panel's yealink-phonebook.xml URL
   - **Display Name:** something like "Office Contacts" (this is
     what the phone shows on screen)
4. Save / Apply
5. The phone fetches the XML immediately and lists contacts under
   **Menu → Directory → Remote Phonebook → Office Contacts**

## Auto-refresh

Yealink phones cache remote phonebooks. To control refresh
frequency:

1. **Directory → Remote Phone Book**
2. Set **Update Time Interval (Seconds)** to the desired value
   - Default: `21600` (6 hours) — fine if your contacts don't
     change often
   - For frequently-updated panels: `300` (5 minutes) — phone
     refreshes more aggressively

## Incoming-call match

If you also want the phone's display to show contact names on
incoming calls (matched against the remote phonebook), enable:

1. **Directory → Remote Phone Book**
2. Tick **Incoming Call** for your phonebook entry
3. Save

When a call arrives, the phone queries the remote phonebook and
shows the matching contact name + image (if you uploaded one in
the panel's Contact Editor).

## Provisioning via the phone's config file

If you're using Yealink's auto-provisioning (RPS / DHCP option 66 /
HTTPS config server), you can bake the remote phonebook into the
phone's `<MAC>.cfg`:

```ini
# Remote Phone Book
remote_phonebook.data.1.url = http://your-freepbx-host:4848/callpanel/yealink-phonebook.xml
remote_phonebook.data.1.name = Office Contacts

# Auto-refresh every hour
phonebook_remote.update_time_interval = 3600

# Match incoming calls against remote phonebook
features.call_log_show_num.incoming = 0
features.remote_phonebook.enable = 1
```

(Yealink config keys vary by firmware version — check Yealink's
"Auto-Provisioning Guide" PDF for your exact phone model.)

## Multiple panels / multiple phonebooks

You can register up to 5 remote phonebooks per phone. Useful if
you want to combine:

- Office contacts (from this panel)
- Personal LDAP directory
- Static XML phonebook on a separate server

Just fill in rows 2, 3, 4, 5 in the **Remote Phone Book** page.

## Troubleshooting Yealink-specific issues

### Phone says "Download failed"

- Verify the URL is reachable from the phone's network (try
  `curl` from another machine on the same VLAN)
- Verify the URL is HTTP, not HTTPS (Yealink older firmware
  doesn't always validate self-signed certs gracefully)
- Check the phone's syslog (System → Trace) for the exact HTTP
  error

### Phonebook shows but contacts are blank / partially broken

- The phone may be enforcing a contact limit (default is 1000
  per phonebook on T-series; check **Phone → Capabilities** in
  the web UI)
- Names with characters outside UTF-8 ASCII range may render as
  `?` on older firmware — upgrade to V83 or newer if you see
  this with European / non-Latin characters

### Incoming call doesn't show contact name

- Confirm **Incoming Call** checkbox is enabled on the phonebook entry
- Verify the number format Asterisk presents matches what's stored
  in the contact — see
  [CONFIGURATION.md → Caller ID Prefixes](CONFIGURATION.md#caller-id-prefixes)
  for the prefix-stripping trick
- Note that Yealink's match is exact-string (no fuzzy matching),
  so make sure both ends agree on `+`, country code, area code

### Phone forgets the phonebook after reboot

- Save the config (not just "Apply") in **Settings → Configuration
  → Save All Configuration**
- Or push the config via auto-provisioning so it's part of the
  template, not the runtime config

## Reference URLs

- [Yealink Auto-Provisioning Guides](https://support.yealink.com/en/portal/docList?archiveType=document&productCode=12d68bcdde304ad0)
  (per-model PDFs)
- [Yealink phone web UI default credentials](https://support.yealink.com/en/portal/knowledge?id=000004078)

## Tested with

The Yealink phonebook endpoint was upstream-tested with T-series
phones before the 2022 archive. This fork has **not** independently
re-tested against physical Yealink hardware — the XML format is
unchanged from upstream, so any phone that worked with upstream
should work with this fork.

If you confirm a model works (or doesn't), please file an issue
or PR so we can build a compatibility list.
