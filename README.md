# BrandMeister STFU for ASL3 / DVSwitch

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

Manual Mode + Optional Web UI Add-On

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

## Install Order

### Step 1 - Install the base manual STFU mode first

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

### Step 2 - Install the optional Web UI add-on after the base install is working

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

That's it.

---

---

## Log file

The manual BM/STFU helper writes to one visible log file:

    /var/log/bm-stfu-manual-mode.log

The helper also sets STFU's log directory so the STFU binary does not fall back to:

    /var/log/STFU.log

Older installs may have used:

    /var/log/bm-stfu.log
    /var/log/STFU.log

Those older files are no longer used by this helper after updating. They can be removed manually after confirming STFU is stopped.

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

### MAIN_NODE and DVSWITCH_NODE

The base installer will prompt you for these values during install:

```text
MAIN_NODE
DVSWITCH_NODE
```

For a normal new install, you should not need to edit `/usr/local/bin/bm-stfu.sh` by hand.

If you ever need to review or change them later, you can check:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
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

## Install

### Installer Script Method

Use this if you want the easiest supported path.

#### Base manual STFU mode

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git
cd bm-stfu-manual-mode
chmod +x install_bm_stfu_manual_mode.sh
sudo ./install_bm_stfu_manual_mode.sh
```

#### Optional Web UI add-on

Run this only after the base manual mode is already working:

```bash
cd bm-stfu-manual-mode
chmod +x install_stfu_web.sh
sudo ./install_stfu_web.sh
```

The Web UI installer now:

- installs the Web UI files
- installs the `stfu-web` sudoers rule
- validates the sudoers file
- backs up an existing sudoers file before replacing it
- tests `bm-stfu.sh status` as `www-data`

---

### Manual Line-by-Line Install

Use this if you do **not** want to run the installer scripts.

#### Base manual STFU mode

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git
cd bm-stfu-manual-mode
sudo apt update
sudo apt install -y git
```

Check that DVSwitch / MMDVM_Bridge is already installed:

```bash
ls -l /opt/MMDVM_Bridge/DVSwitch.ini
```

Clone the STFU upstream repo:

```bash
sudo git clone https://github.com/DVSwitch/STFU.git /opt/STFU
```

Install the correct STFU binary.

For most 64-bit Debian / ASL3 systems:

```bash
sudo install -m 0755 /opt/STFU/bin/STFU.amd64 /usr/local/bin/STFU
```

For ARM64 systems:

```bash
sudo install -m 0755 /opt/STFU/bin/STFU.arm64 /usr/local/bin/STFU
```

For ARMHF systems:

```bash
sudo install -m 0755 /opt/STFU/bin/STFU.armhf /usr/local/bin/STFU
```

Install the helper script:

```bash
sudo install -m 0755 bm-stfu.sh /usr/local/bin/bm-stfu.sh
```

Link `DVSwitch.ini` into `/opt/STFU`:

```bash
sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini /opt/STFU/DVSwitch.ini
```

Edit your BrandMeister settings:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Make sure `[STFU]` has your real values for:

- `BMPassword`
- `UserID`
- `TalkerAlias`
- `StartTG`

Recommended:

```ini
StartTG=0
```

If you used the manual install instead of the base installer, you must also set your node values in:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
```

Set:

```bash
MAIN_NODE="YOUR_NODE"
DVSWITCH_NODE="YOUR_DVSWITCH_NODE"
```

Test it:

```bash
sudo bm-stfu.sh status
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh stop
```

#### Manual install of the optional Web UI

Use this only after the base manual STFU mode is already working.

Create the live web directory:

```bash
sudo mkdir -p /var/www/html/stfu
```

Copy the web UI files:

```bash
sudo cp web-ui/index.php /var/www/html/stfu/index.php
sudo cp web-ui/favorites.txt /var/www/html/stfu/favorites.txt
sudo cp web-ui/README.md /var/www/html/stfu/README.txt
sudo cp web-ui/sudoers-example.txt /var/www/html/stfu/sudoers-example.txt
```

Set file ownership and permissions:

```bash
sudo chown root:www-data /var/www/html/stfu/index.php
sudo chmod 644 /var/www/html/stfu/index.php

sudo chown www-data:www-data /var/www/html/stfu/favorites.txt
sudo chmod 664 /var/www/html/stfu/favorites.txt

sudo chown root:root /var/www/html/stfu/README.txt
sudo chmod 644 /var/www/html/stfu/README.txt

sudo chown root:root /var/www/html/stfu/sudoers-example.txt
sudo chmod 644 /var/www/html/stfu/sudoers-example.txt
```

Install the sudoers rule:

```bash
echo 'www-data ALL=(ALL) NOPASSWD: /usr/local/bin/bm-stfu.sh' | sudo tee /etc/sudoers.d/stfu-web >/dev/null
sudo chown root:root /etc/sudoers.d/stfu-web
sudo chmod 440 /etc/sudoers.d/stfu-web
sudo visudo -cf /etc/sudoers.d/stfu-web
```

Check PHP syntax:

```bash
sudo php -l /var/www/html/stfu/index.php
```

Test backend access as the web user:

```bash
sudo -u www-data sudo /usr/local/bin/bm-stfu.sh status
```

Open the Web UI:

```text
http://YOUR_NODE_IP/stfu/
```

---

## Uninstall

### Remove the optional Web UI only

If you want to remove only the Web UI add-on:

Back up favorites first if you want to keep them:

```bash
sudo cp /var/www/html/stfu/favorites.txt /root/favorites.txt.backup
```

Remove the live Web UI files:

```bash
sudo rm -rf /var/www/html/stfu
```

Remove the sudoers rule:

```bash
sudo rm -f /etc/sudoers.d/stfu-web
```

That removes:

- the web page
- saved favorites
- the web sudoers rule

It does **not** remove the base STFU manual mode.

---

### Remove the base manual STFU mode

If you want to remove the STFU base install too:

Stop STFU if it is running:

```bash
sudo bm-stfu.sh stop || true
```

Remove the installed helper script and binary:

```bash
sudo rm -f /usr/local/bin/bm-stfu.sh
sudo rm -f /usr/local/bin/STFU
```

Remove the STFU working directory:

```bash
sudo rm -rf /opt/STFU
```

Optional: remove the local repo clone too:

```bash
rm -rf ~/bm-stfu-manual-mode
```

Or, if you cloned it somewhere else, remove that directory instead.

---

## Sudoers Requirement for the Web UI

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

The Web UI installer now installs and validates the sudoers rule automatically.

It also backs up an existing sudoers file before replacing it.

---

## Recommended Permissions for the Live Web UI

```bash
sudo chown root:www-data /var/www/html/stfu/index.php
sudo chmod 644 /var/www/html/stfu/index.php
sudo chown www-data:www-data /var/www/html/stfu/favorites.txt
sudo chmod 664 /var/www/html/stfu/favorites.txt
```

---

## Web UI Notes

- Start should be used first.
- Change TG is meant for changing talkgroups after STFU is already active.
- Add Favorite is for adding a new favorite.
- Load fills the control target for quick use.
- Favorites are shown in a visible list and use `favorites.txt`.

---
## Warning

**Warning:** If you leave STFU active and then switch to AllTune2 or other DVSwitch tools, normal MMDVM_Bridge operation may not work until STFU is stopped and normal bridge mode is restored. Always press **Stop** before leaving the STFU Web UI or before using AllTune2.

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

### If you installed during the earlier broken installer window

The easiest recovery path is:

```bash
cd ~/bm-stfu-manual-mode
git pull origin main
```

Then:

- verify the correct `MAIN_NODE` and `DVSWITCH_NODE` are in `/usr/local/bin/bm-stfu.sh`
- rerun the Web UI installer:

```bash
chmod +x install_stfu_web.sh
sudo ./install_stfu_web.sh
```

---

## Summary

This repo now supports:

- **Base manual STFU mode**
- **Optional STFU Web UI add-on**

Install the base project first.  
Then install the optional Web UI if you want browser-based control.

You can now install it either way:

### Installer scripts
```bash
chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
chmod +x install_stfu_web.sh && sudo ./install_stfu_web.sh
```

### Manual line-by-line
Use the Install and Uninstall sections above for the full manual path.
