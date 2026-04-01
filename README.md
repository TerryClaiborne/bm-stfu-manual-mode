# Run BrandMeister STFU on ASL3 / DVSwitch (Manual Mode + Optional Web GUI)

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

---

## What this repo includes

This repo contains two parts:

1. **Base manual STFU mode**
   - helper script: `bm-stfu.sh`
   - base installer: `install_bm_stfu_manual_mode.sh`

2. **Optional STFU Web UI add-on**
   - web installer: `install_stfu_web.sh`
   - web files are stored in the repo under `web-ui/`

The Web UI is an add-on for the base STFU project.  
It does **not** work by itself.

---

## Install order

### Step 1 — Install the base manual STFU mode first

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

### Step 2 — Install the optional Web UI add-on after the base install is working

From inside the same repo directory:

```bash
chmod +x install_stfu_web.sh && sudo ./install_stfu_web.sh
```

### Important

The Web UI installer checks for the base install first.

If `/usr/local/bin/bm-stfu.sh` is missing, the Web UI installer stops and tells you to install the base project first.

---

## Quick Start (Base Manual Mode)

After install, this is all you need:

```bash
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh stop
sudo bm-stfu.sh status
```

That’s it.

---

## One-Time Setup (Required)

Edit your live file:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Set the values that match your system, including:

- `BMPassword`
- `UserID`
- `TalkerAlias`
- `StartTG`

### Important note about `StartTG`

If STFU briefly lands on TG91 before switching to the talkgroup you requested, set:

```ini
StartTG=0
```

That avoided the brief unwanted startup hit on TG91 on my system.

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

## Optional STFU Web UI Add-On

The STFU Web UI is an optional browser-based front end for `bm-stfu.sh`.

It provides:

- Start
- Change TG
- Stop
- Refresh Status
- Save Favorite
- Load Favorite
- Delete Favorite
- private target support with trailing `#`

Example private target:

```text
3220008#
```

### Live Web UI location

On my working system, the live files are installed to:

```text
/var/www/html/stfu
```

### Files used by the Web UI

Installed live files:

```text
/var/www/html/stfu/index.php
/var/www/html/stfu/favorites.txt
/var/www/html/stfu/README.txt
/var/www/html/stfu/sudoers-example.txt
```

Repo source files:

```text
web-ui/index.php
web-ui/favorites.txt
web-ui/README.md
web-ui/sudoers-example.txt
```

### Favorites

Saved favorites are stored in:

```text
/var/www/html/stfu/favorites.txt
```

Each favorite includes:

- TG / Private TG
- Station Name / Label
- Description

---

## Sudoers requirement for the Web UI

The Web UI needs permission for the Apache web user to run the helper script.

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

### Important

The Web UI installer does **not** automatically install the sudoers file.  
It copies the example file and reminds you to review and install it yourself.

---

## Recommended permissions for the live Web UI

```bash
sudo chown root:www-data /var/www/html/stfu/index.php
sudo chmod 644 /var/www/html/stfu/index.php
sudo chown www-data:www-data /var/www/html/stfu/favorites.txt
sudo chmod 664 /var/www/html/stfu/favorites.txt
```

---

## Web UI notes

- Start should be used first.
- Change TG is meant for changing talkgroups after STFU is already active.
- Add Favorite is for adding a new favorite.
- Load fills the control target for quick use.
- Favorites are shown in a visible list and use `favorites.txt`.

---

## Troubleshooting

### If the Web UI does not work

Check:

- base manual STFU mode is installed first
- `bm-stfu.sh` works from the command line
- sudoers rule exists and is valid
- `favorites.txt` exists and is writable by `www-data`

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
- **Optional STFU Web UI add-on**

Install the base project first.  
Then install the optional Web UI if you want browser-based control.
