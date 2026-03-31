# Manual BrandMeister STFU Mode for ASL3 / DVSwitch


Manual BrandMeister STFU mode setup and helper workflow for DVSwitch / ASL3.

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

## Quick Install

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

This guide shows how to install and use **STFU** in **manual mode** on an ASL3 / DVSwitch system.

This is for people who:

- already have **ASL3**, **Analog_Bridge**, **MMDVM_Bridge**, and **DVSwitch** working
- want to test or use **BrandMeister through STFU**
- do **not** want to replace their normal AllTune2 / MMDVM_Bridge setup
- want a simple helper script so they do not have to type command after command every time

This guide keeps STFU **manual only**.

It does **not** auto-start STFU.
It does **not** change AllTune2.
It does **not** replace TGIF, YSF, EchoLink, or AllStar.

## What manual STFU mode does

When you start manual STFU mode, it:

1. Stops `mmdvm_bridge`
2. Connects your main node to your local DVSwitch node
3. Switches DVSwitch to `STFU` mode
4. Starts the real `STFU` program in the background
5. Tunes BrandMeister to the talkgroup you choose

When you stop manual STFU mode, it:

1. Stops STFU
2. Disconnects your local DVSwitch node
3. Starts `mmdvm_bridge` again

That gives you a clean way to test or use BM through STFU, then go back to normal mode.

---

## Important warnings

- Do **not** run STFU and `mmdvm_bridge` for BrandMeister at the same time.
- STFU is a **manual mode** in this guide, not a replacement for your normal system.
- Your local DVSwitch node still needs to be connected when using STFU.
- STFU expects to find a file named `DVSwitch.ini` in its working folder.
- Your real BrandMeister password will be stored in the `[STFU]` section of `DVSwitch.ini`.

---

## Tested idea behind this setup

This setup is useful when:

- normal BM through MMDVM_Bridge is awkward or inconsistent
- BM behaves differently than TGIF
- you want a clean terminal-controlled BM mode without disturbing your normal setup

---

## Requirements

You should already have these working:

- ASL3
- Analog_Bridge
- MMDVM_Bridge
- DVSwitch
- A local DVSwitch node on your system

Example node numbers used in this guide:

- Main node: `67040`
- Local DVSwitch node: `1957`

Change those numbers to match your own system where needed.

---

# Part 1 - Install STFU

## 1. Install git

```bash
sudo apt update
sudo apt install -y git
```

## 2. Download STFU

```bash
cd /opt
sudo git clone https://github.com/DVSwitch/STFU.git
```

## 3. Check architecture

```bash
uname -m
```

If it prints:

```text
aarch64
```

then install the arm64 binary like this:

```bash
cd /opt/STFU
sudo cp bin/STFU.arm64 /usr/local/bin/STFU
sudo chmod +x /usr/local/bin/STFU
```

## 4. Confirm the binary is installed

```bash
ls -l /usr/local/bin/STFU
```

You should see the file there.

---

# Part 2 - Configure DVSwitch.ini for STFU

Edit your live file:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Find the `[STFU]` section and make sure it is set correctly.

Example:

```ini
[STFU]
BMAddress = 3104.repeater.net
BMPort = 54006
BMPassword = YOUR_REAL_BRANDMEISTER_PASSWORD
Address = 127.0.0.1
txPort = 36100
rxPort = 36103
UserID = YOUR_DMR_ID
TalkerAlias = YOURCALLSIGN YOURCITY
StartTG = YOUR_TALKGROUP
LogLevel = 1
```

### Set these values correctly

- `BMPassword` = your real BrandMeister password
- `UserID` = your DMR ID
- `TalkerAlias` = whatever you want to send
- `StartTG` = the talkgroup STFU should start on

For example, if you want STFU to start on TG `3220008`:

```ini
StartTG = 3220008
```

Save and exit.

---

# Part 3 - Create the required DVSwitch.ini link for STFU

STFU wants a file literally named `DVSwitch.ini` in `/opt/STFU`.

Create the link like this:

```bash
cd /opt/STFU
sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini DVSwitch.ini
ls -l DVSwitch.ini
```

You should see it pointing to:

```text
/opt/MMDVM_Bridge/DVSwitch.ini
```

---

# Part 4 - Install the helper script

This repository includes a helper script named `bm-stfu.sh`.

Put it here:

```text
/usr/local/bin/bm-stfu.sh
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/bm-stfu.sh
```

Open it and edit the two node numbers if needed:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
```

These are the two lines to adjust:

```bash
MAIN_NODE="67040"
DVSWITCH_NODE="1957"
```

If your system uses different node numbers, change them.

---

# Part 5 - Manual STFU mode usage

## Start BM through STFU

```bash
bm-stfu.sh start 3220008
```

This will:

- stop `mmdvm_bridge`
- connect main node `67040` to local DVSwitch node `1957`
- switch DVSwitch to STFU mode
- start STFU in the background
- tune BM to TG `3220008`

## Change BM talkgroups while STFU is already running

```bash
bm-stfu.sh tune 91
```

More examples:

```bash
bm-stfu.sh tune 3100
bm-stfu.sh tune 93
bm-stfu.sh tune 3220008
```

## Check status

```bash
bm-stfu.sh status
```

This tells you whether STFU is running and whether `mmdvm_bridge` is active.

## Stop STFU mode and return to normal operation

```bash
bm-stfu.sh stop
```

This will:

- stop STFU
- disconnect the local DVSwitch node
- start `mmdvm_bridge` again

---

# Part 6 - Do you need more than one terminal?

No.

The helper script starts STFU in the background, so your terminal returns to a prompt.

That means you can use the **same terminal** to run:

```bash
bm-stfu.sh start 3220008
bm-stfu.sh tune 91
bm-stfu.sh status
bm-stfu.sh stop
```

You only need a second terminal if you want to watch logs or run other commands at the same time.

---

# Part 7 - Full quick start and stop examples

## Start manual BM STFU mode

```bash
bm-stfu.sh start 3220008
```

## Change BM talkgroup later

```bash
bm-stfu.sh tune 91
```

## Return to normal mode

```bash
bm-stfu.sh stop
```

---

# Part 8 - Example manual fallback commands

If you ever want to do it by hand without the helper script, this is the order:

## Start by hand

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun 67040 *31957"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
cd /opt/STFU
sudo STFU
```

Then in another terminal if needed:

```bash
/opt/MMDVM_Bridge/dvswitch.sh tune 3220008
```

## Stop by hand

In the STFU terminal, stop it with `Ctrl+C`, then run:

```bash
sudo systemctl start mmdvm_bridge
```

---

# Part 9 - What was wrong before

These are the common things that stop STFU from working:

1. Only having `/opt/Analog_Bridge/stfu.sh`
   - that helper is **not** the real STFU engine

2. Not installing the real STFU binary
   - example correct install path:
     ```text
     /usr/local/bin/STFU
     ```

3. STFU not finding `DVSwitch.ini`
   - fixed by creating this link:
     ```bash
     cd /opt/STFU
     sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini DVSwitch.ini
     ```

4. Wrong node numbers in the helper script

5. Wrong `[STFU]` values in `DVSwitch.ini`
   - especially password, DMR ID, and StartTG

6. Trying to run STFU and `mmdvm_bridge` for BM at the same time

---

# Part 10 - Security reminder

If you ever exposed your real BrandMeister password in terminal output, logs, screenshots, or chat, change it in BrandMeister SelfCare afterward.

---

# Part 11 - Recommended repository contents

A useful GitHub repository for this should include:

- this README
- `bm-stfu.sh`
- a short cheat sheet section
- a note that this is **manual mode** and not integrated into AllTune2

---

# Part 12 - Final note

This is a personal-use helper workflow for people who want to use BrandMeister through STFU without replacing their normal DVSwitch / MMDVM_Bridge setup.

Use it when you want STFU.
Stop it when you want to go back to normal mode.
