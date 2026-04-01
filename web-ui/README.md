# STFU Web UI Add-On for bm-stfu-manual-mode

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

---

## What this is

This is the optional web GUI add-on for the main **bm-stfu-manual-mode** project.

It provides a lightweight browser-based control panel for:

- Start
- Change TG
- Stop
- Refresh Status
- Save Favorite
- Load Favorite
- Delete Favorite

It is meant to run locally on an ASL3 / DVSwitch system using Apache and PHP.

---

## Important

This web UI is **not standalone**.

You must already have the base **bm-stfu-manual-mode** install working first.

The web UI depends on:

- `/usr/local/bin/bm-stfu.sh`
- the base STFU install
- Apache / PHP
- a working sudoers rule for `www-data`

If the base script does not work from the command line first, the web UI will not work either.

---

## Current Live Location

On my working system, the live web UI files are in:

```text
/var/www/html/stfu
```

The main files currently used there are:

```text
/var/www/html/stfu/index.php
/var/www/html/stfu/favorites.txt
/var/www/html/stfu/README.txt
/var/www/html/stfu/sudoers-example.txt
```

---

## What the Web UI Does

The STFU web panel supports:

- Start a talkgroup
- Change talkgroup after STFU is already active
- Stop STFU
- Refresh backend status
- Save Favorites
- Load Favorites into the control target field
- Delete Favorites
- Private target support with trailing `#`

Example private target:

```text
3220008#
```

---

## Favorites

Saved favorites are stored in:

```text
/var/www/html/stfu/favorites.txt
```

Each favorite includes:

- TG / Private TG
- Station Name / Label
- Description

The Add Favorite section is meant for adding a **new** favorite.  
Saved Favorites are shown below in a visible list with **Load** and **Delete** buttons.

---

## Sudoers Requirement

The web UI needs permission for the Apache web user to run the helper script.

The working example file is:

```text
/var/www/html/stfu/sudoers-example.txt
```

A typical installed sudoers file is:

```text
/etc/sudoers.d/stfu-web
```

Typical contents:

```text
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/bm-stfu.sh
```

Validate it with:

```bash
sudo visudo -cf /etc/sudoers.d/stfu-web
```

---

## Recommended Permissions

```bash
sudo chown root:www-data /var/www/html/stfu/index.php
sudo chmod 644 /var/www/html/stfu/index.php
sudo chown www-data:www-data /var/www/html/stfu/favorites.txt
sudo chmod 664 /var/www/html/stfu/favorites.txt
```

---

## Basic Use

### Start a talkgroup
Type a target in the control field, then press:

```text
Start
```

### Change TG
Start a talkgroup first, then enter a different target and press:

```text
Change TG
```

### Stop
Press:

```text
Stop
```

### Refresh Status
Press:

```text
Refresh Status
```

---

## Notes About Operation

- **Start** should be used first.
- **Change TG** is meant for changing talkgroups after STFU is already running.
- The Add Favorite fields should be blank when the page first loads.
- Loading a saved favorite should fill the control target field without forcing the Add Favorite section to stay populated.
- Favorites are meant to be quick to load and use from the page.

---

## StartTG Note

If STFU briefly lands on TG91 before switching to the requested target, check:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Recommended setting:

```ini
StartTG=0
```

That avoided the brief unwanted TG91 startup hit on my system.

---

## Troubleshooting

### If the page throws an HTTP 500 error

Check Apache errors:

```bash
sudo tail -n 50 /var/log/apache2/error.log
```

Check PHP syntax:

```bash
sudo php -l /var/www/html/stfu/index.php
```

### If Favorites do not save

Check:

- `/var/www/html/stfu/favorites.txt` exists
- `favorites.txt` is writable by `www-data`

### If buttons work incorrectly

Confirm the base script works first:

```bash
sudo bm-stfu.sh status
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh stop
```

If the command-line workflow is not right, fix that first before troubleshooting the web UI.

---

## Packaging Direction

For GitHub packaging, this web UI should be treated as an **optional add-on** to the main project, not a replacement for it.

Recommended direction:

- main repo README explains the base project and optional GUI
- this README explains the web UI specifically
- later, the repo can include an installer for the web UI after the base install is confirmed working

---

## Summary

This web UI is a lightweight front end for the base STFU manual mode project.

It depends on the base install first, and it is meant to make common STFU actions easier from a browser without replacing the command-line workflow.
