# Run BrandMeister STFU on ASL3 / DVSwitch (Manual Mode + Optional Web GUI)

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

---

## What this repo includes

This repo now includes two parts:

1. **Base manual STFU mode**
   - helper script: `bm-stfu.sh`
   - main installer: `install_bm_stfu_manual_mode.sh`

2. **Optional STFU web GUI add-on**
   - browser-based control panel for:
     - Start
     - Change TG
     - Stop
     - Status
     - Saved Favorites
   - requires the base manual STFU install to already be working first

---

## Quick Start (Most Important)

After install, this is all you need:

```bash
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh stop
sudo bm-stfu.sh status
```

That’s it.

---

## Install Choices

### Option 1 — Base manual mode only

Install the helper script and use STFU from the command line.

### Option 2 — Base manual mode + optional web GUI

Install the base manual mode first, then add the optional web interface.

> The web GUI is an add-on for `bm-stfu.sh`.  
> It does not work by itself.

---

## Install

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

---

## One-Time Setup (Required)

Edit your settings:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Set the values that match your system, including:

- `BMPassword`
- `UserID`
- `TalkerAlias`
- `StartTG`

### Important note about `StartTG`

If STFU briefly lands on TG91 before switching to the talkgroup you requested, check this setting:

```ini
StartTG=0
```

Using `StartTG=0` avoids an unwanted brief startup hit on TG91 on systems like mine.

Then edit:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
```

Set:

```bash
MAIN_NODE="YOUR_NODE"
DVSWITCH_NODE="YOUR_DVSWITCH_NODE"
```

---

## Base Manual Mode Commands

Start STFU on a talkgroup:

```bash
sudo bm-stfu.sh start 3220008
```

Change talkgroups while STFU is already running:

```bash
sudo bm-stfu.sh tune 91
```

Stop STFU and return to normal:

```bash
sudo bm-stfu.sh stop
```

Show current status:

```bash
sudo bm-stfu.sh status
```

---

## Optional STFU Web GUI Add-On

The STFU web GUI is an optional browser-based front end for `bm-stfu.sh`.

It is meant for users who want:
- simple Start / Change TG / Stop / Status buttons
- saved favorites
- a lightweight web control panel

### Important

You must install and configure the base manual mode first.

The web GUI depends on:
- `/usr/local/bin/bm-stfu.sh`
- the STFU base install
- a sudoers rule allowing the web server user to run `bm-stfu.sh`

It is not a standalone install by itself.

---

## STFU Web GUI Features

The web GUI currently supports:

- Start a talkgroup
- Change talkgroup after STFU is already running
- Stop STFU
- Refresh status
- Save Favorites
- Load Favorites
- Delete Favorites
- Private target support with trailing `#`

Example private target:

```text
3220008#
```

### Favorites

Saved favorites use:

```text
/var/www/html/stfu/favorites.txt
```

Favorites include:
- TG / Private TG
- Station Name / Label
- Description

---

## Web GUI Files

Current local web GUI files are:

```text
/var/www/html/stfu/index.php
/var/www/html/stfu/favorites.txt
```

A typical sudoers example file is:

```text
/etc/sudoers.d/stfu-web
```

Example contents:

```text
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/bm-stfu.sh
```

Validate it with:

```bash
sudo visudo -cf /etc/sudoers.d/stfu-web
```

---

## Web GUI Notes

The web GUI is designed to be simple and light.

Current behavior includes:
- Start should be used first
- Change TG is meant for changing talkgroups after STFU is already active
- the Add Favorite section is meant for adding new favorites
- loading a saved favorite should fill the control target without forcing you to re-save it

---

## Troubleshooting

### If the web GUI does not work

Check:
- base manual STFU mode is installed first
- `bm-stfu.sh` runs correctly from the command line
- sudoers rule exists and is valid
- `favorites.txt` exists and is writable by `www-data`

Recommended permissions:

```bash
sudo chown root:www-data /var/www/html/stfu/index.php
sudo chmod 644 /var/www/html/stfu/index.php
sudo chown www-data:www-data /var/www/html/stfu/favorites.txt
sudo chmod 664 /var/www/html/stfu/favorites.txt
```

### If the page throws an HTTP 500 error

Check Apache errors:

```bash
sudo tail -n 50 /var/log/apache2/error.log
```

Check PHP syntax:

```bash
sudo php -l /var/www/html/stfu/index.php
```

### If STFU briefly hits TG91 before changing to the requested talkgroup

Set this in `DVSwitch.ini`:

```ini
StartTG=0
```

---

## Summary

This repo now supports:

- **Base manual STFU mode**
- **Optional STFU web GUI add-on**

The command-line workflow remains the base install.  
The web GUI is an optional convenience layer on top of it.
