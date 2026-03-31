# Run BrandMeister STFU on ASL3 / DVSwitch (Manual Mode)

Manual STFU setup and helper workflow for DVSwitch / ASL3.

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

---

## Quick Use (What most people want)

Once installed, this is all you need:

### Start STFU on your talkgroup

```bash
sudo bm-stfu.sh start 3220008
```

### Change talkgroups

```bash
sudo bm-stfu.sh tune 3100
sudo bm-stfu.sh tune 93
sudo bm-stfu.sh tune 3220008
```

### Stop STFU and return to normal

```bash
sudo bm-stfu.sh stop
```

That’s it.

---

## What this actually does (simple version)

- Stops MMDVM_Bridge
- Connects your node to your local DVSwitch node
- Switches DVSwitch to STFU mode
- Starts STFU
- Tunes BrandMeister to the talkgroup you choose

When you stop it, everything goes back to normal.

---

## Install

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

---

## Who this is for

This is for you if:

- you already have ASL3 / DVSwitch working
- you want to use BrandMeister through STFU
- you don’t want to mess up your normal setup (AllTune2, TGIF, YSF, EchoLink, or AllStar)
- you just want simple commands that work without typing a bunch of stuff every time

This runs STFU in **manual mode only**.

You start it when you need it, and stop it when you're done.

---

## Why this exists

BrandMeister can be picky.

Sometimes after a reboot, audio won’t pass until the node is keyed first.

Most people never notice because they already keyed their node.

This gives you a clean way to:
- bring BM up properly
- switch talkgroups easily
- and go back to normal without messing anything up

## What manual STFU mode does

When you start manual STFU mode, it:

1. Stops `mmdvm_bridge`
2. Connects your main node to your local DVSwitch node
3. Switches DVSwitch to `STFU` mode
4. Starts the real `STFU` program in the background or foreground, depending on your workflow
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

The helper script `bm-stfu.sh` must be created or copied onto the system before use.

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
DVSWITCH_NODE=""
```

If your system uses different node numbers, change them.

---

# Part 5 - Manual STFU mode usage

## Start BM through STFU

```bash
sudo bm-stfu.sh start 3220008
```

This will:

- stop `mmdvm_bridge`
- connect main node (YOUR_NODE) to local DVSwitch node (YOUR_DVSWITCH_NODE)
- switch DVSwitch to STFU mode
- start STFU in the background
- tune BM to TG `3220008`

## Change BM talkgroups while STFU is already running

```bash
sudo bm-stfu.sh tune 91
```

More examples:

```bash
sudo bm-stfu.sh tune 3100
sudo bm-stfu.sh tune 93
sudo bm-stfu.sh tune 3220008
```

## Check status

```bash
sudo bm-stfu.sh status
```

This tells you whether STFU is running and whether `mmdvm_bridge` is active.

## Stop STFU mode and return to normal operation

```bash
sudo bm-stfu.sh stop
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
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh status
sudo bm-stfu.sh stop
```

You only need a second terminal if you want to watch logs or run other commands at the same time.

---

# Part 7 - Full quick start and stop examples

## Start manual BM STFU mode

```bash
sudo bm-stfu.sh start 3220008
```

## Change BM talkgroup later

```bash
sudo bm-stfu.sh tune 91
```

## Return to normal mode

```bash
sudo bm-stfu.sh stop
```

---

# Part 8 - Example manual fallback commands

If you ever want to do it by hand without the helper script, this is the order:

## Start by hand

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun YOUR_MAIN_NODE *3YOUR_DVSWITCH_NODE"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
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

# Part 11 - Repository contents

This repository currently includes:

- this README
- `install_bm_stfu_manual_mode.sh`

If you want to distribute `bm-stfu.sh` with the project, add it to the repository as a separate file.

---

# Part 12 - Final note

This is a personal-use helper workflow for people who want to use BrandMeister through STFU without replacing their normal DVSwitch / MMDVM_Bridge setup.

Use it when you want STFU.  
Stop it when you want to go back to normal mode.

---

## Example Usage

Start STFU manually:

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun YOUR_MAIN_NODE *3YOUR_DVSWITCH_NODE"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
sudo STFU
```

To return to normal DVSwitch operation:

```bash
sudo pkill STFU
sudo systemctl start mmdvm_bridge
```

---

## BrandMeister Behavior (IMPORTANT)

BrandMeister (BM) may not pass audio immediately after a reboot.

In many cases, the node must be keyed once before audio flows.

This is **not a bug in AllTune2 or DVSwitch**, but how BM behaves when initializing a connection.

This is why STFU manual mode exists - it ensures a clean and active connection to BM.

---

## Common Problems

### STFU says DVSwitch.ini not found

Fix:

```bash
cd /opt/STFU
sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini DVSwitch.ini
```

---

### STFU runs but no audio

- Make sure your local DVSwitch node is connected
- Make sure you switched to STFU mode:

```bash
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
```

---

### Still no audio on BM

This is normal behavior for some BM setups.

Try keying the node once or restarting STFU.

---

### MMDVM_Bridge conflicts with STFU

You must stop it before running STFU:

```bash
sudo systemctl stop mmdvm_bridge
```

---

## Notes

- This setup does NOT modify your normal DVSwitch operation
- STFU is optional and only used when needed
- You can safely return to normal mode anytime
