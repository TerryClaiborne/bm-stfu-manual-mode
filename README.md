# BrandMeister STFU for ASL3 / DVSwitch

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

Manual Mode + Optional Web UI Add-On

---

## What this project is

This project has two parts:

1. **Base manual STFU mode**
   - helper script: `bm-stfu.sh`
   - base installer: `install_bm_stfu_manual_mode.sh`

2. **Optional STFU Web UI**
   - web installer: `install_stfu_web.sh`
   - web UI source files live under `web-ui/`

The Web UI is an add-on for the base project.  
It does **not** work by itself.

---

## Install

### Base manual mode

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git
cd bm-stfu-manual-mode
chmod +x install_bm_stfu_manual_mode.sh
sudo ./install_bm_stfu_manual_mode.sh
```

### Optional Web UI

Run this only after the base manual mode is already working:

```bash
cd bm-stfu-manual-mode
chmod +x install_stfu_web.sh
sudo ./install_stfu_web.sh
```

### Install order

1. install the base manual mode first
2. confirm `bm-stfu.sh` works
3. install the optional Web UI

If `/usr/local/bin/bm-stfu.sh` is missing, the Web UI installer will stop and tell you to install the base project first.

---

## Update

If you already use **both** the base manual mode and the Web UI, the safest normal update path is to update **both**.

### Pull the latest repo changes

```bash
cd ~/bm-stfu-manual-mode
git pull origin main
```

If your repo clone lives somewhere else, use that path instead.

### Recommended full update for users who run both manual mode and Web UI

```bash
cd ~/bm-stfu-manual-mode
chmod +x install_bm_stfu_manual_mode.sh
sudo ./install_bm_stfu_manual_mode.sh
chmod +x install_stfu_web.sh
sudo ./install_stfu_web.sh
```

### If you only need one part

#### Update only the base manual mode

```bash
cd ~/bm-stfu-manual-mode
chmod +x install_bm_stfu_manual_mode.sh
sudo ./install_bm_stfu_manual_mode.sh
```

#### Update only the Web UI

```bash
cd ~/bm-stfu-manual-mode
chmod +x install_stfu_web.sh
sudo ./install_stfu_web.sh
```

### Important update note

If you use local saved favorites in the live Web UI, back them up before rerunning the Web UI installer:

```bash
sudo cp /var/www/html/stfu/favorites.txt /root/favorites.txt.backup
```

Then restore them afterward if needed.

### Verify after update

```bash
sudo bm-stfu.sh status
```

If you use the Web UI, open:

```text
http://YOUR_NODE_IP/stfu/
```

and verify that:

- Status loads correctly
- Start works
- Change TG works
- Stop works
- Favorites still work

---

## One-Time Setup

Edit your live DVSwitch file:

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

### MAIN_NODE and DVSWITCH_NODE

The base installer prompts for these values during install:

```text
MAIN_NODE
DVSWITCH_NODE
```

For a normal installer-based setup, you should not need to edit `/usr/local/bin/bm-stfu.sh` by hand.

If you ever need to review or change them later:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
```

---

## Commands

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

## Log Files

The helper writes to:

```text
/var/log/bm-stfu-manual-mode.log
```

The STFU log directory is set to:

```text
/var/log/bm-stfu-manual-mode/
```

Older installs may have used:

```text
/var/log/bm-stfu.log
/var/log/STFU.log
```

After confirming STFU is stopped and your current install is using the newer paths, those older files can be removed manually.

---

## Optional Web UI

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

```text
/var/www/html/stfu
```

### Live files

```text
/var/www/html/stfu/index.php
/var/www/html/stfu/favorites.txt
/var/www/html/stfu/README.txt
/var/www/html/stfu/sudoers-example.txt
```

### Repo source files

```text
web-ui/index.php
web-ui/favorites.txt
web-ui/README.md
web-ui/sudoers-example.txt
```

### Favorites

Saved favorites are stored locally in:

```text
/var/www/html/stfu/favorites.txt
```

Each favorite includes:

- TG / Private TG
- Station Name / Label
- Description

---

## Warning

**Warning:** If you leave STFU active and then switch to AllTune2 or other DVSwitch tools, normal MMDVM_Bridge operation may not work until STFU is stopped and normal bridge mode is restored. Always press **Stop** before leaving the STFU Web UI or before using AllTune2.

---

## Uninstall

### Remove the optional Web UI only

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

### Remove the base manual STFU mode

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

### If you installed during the earlier broken installer window

The easiest recovery path is:

```bash
cd ~/bm-stfu-manual-mode
git pull origin main
```

Then:

- verify the correct `MAIN_NODE` and `DVSWITCH_NODE` are in `/usr/local/bin/bm-stfu.sh`
- rerun the needed installer or installers

---

## Summary

This project supports:

- **Base manual STFU mode**
- **Optional STFU Web UI add-on**

If you use both parts, the simplest update path is usually to update **both**.
