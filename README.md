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
- want a simpler repeatable workflow instead of typing command after command every time

This guide keeps STFU **manual only**.

It does **not** auto-start STFU.  
It does **not** change AllTune2.  
It does **not** replace TGIF, YSF, EchoLink, or AllStar.

## What manual STFU mode does

When you start manual STFU mode, it:

1. Stops `mmdvm_bridge`
2. Connects your main node to your local DVSwitch node
3. Switches DVSwitch to `STFU` mode
4. Starts the real `STFU` program
5. Tunes BrandMeister to the talkgroup you choose

When you stop manual STFU mode, it:

1. Stops STFU
2. Disconnects your local DVSwitch node if desired
3. Starts `mmdvm_bridge` again

That gives you a clean way to test or use BM through STFU, then go back to normal mode.

---

## Important warnings

- Do **not** run STFU and `mmdvm_bridge` for BrandMeister at the same time.
- STFU is a **manual mode** in this guide, not a replacement for your normal system.
- Your local DVSwitch node still needs to be connected when using STFU.
- STFU expects to find a file named `DVSwitch.ini` in `/opt/STFU`.
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
- a local DVSwitch node on your system

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

# Part 4 - Manual STFU mode usage

## Start BM through STFU

Use this exact order:

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun YOUR_MAIN_NODE *3YOUR_DVSWITCH_NODE"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
sudo STFU
```

Replace:

- `YOUR_MAIN_NODE` with your main node number
- `YOUR_DVSWITCH_NODE` with your local DVSwitch node number

Example using this guide's node numbers:

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun 67040 *31957"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
sudo STFU
```

If STFU starts correctly, you should see it connect to the BrandMeister server.

## Tune BM to a talkgroup

Open another terminal if needed and tune to the talkgroup you want:

```bash
/opt/MMDVM_Bridge/dvswitch.sh tune 3220008
```

Replace `3220008` with any BM talkgroup you want.

## Stop STFU mode and return to normal operation

In the STFU terminal, stop it with `Ctrl+C`.

Then run:

```bash
sudo systemctl start mmdvm_bridge
```

If you also want to disconnect your local DVSwitch node, do that with your normal command for your system.

---

# Part 5 - Do you need more than one terminal?

Usually yes, for the cleanest workflow.

- Terminal 1: run `sudo STFU` and leave it running
- Terminal 2: run `dvswitch.sh tune ...` commands as needed

You can stop STFU later with `Ctrl+C` in Terminal 1.

---

# Part 6 - Full quick start and stop examples

## Start manual BM STFU mode

```bash
sudo systemctl stop mmdvm_bridge
sudo asterisk -rx "rpt fun 67040 *31957"
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
sudo STFU
```

Then, in another terminal:

```bash
/opt/MMDVM_Bridge/dvswitch.sh tune 3220008
```

## Return to normal mode

In the STFU terminal:

```text
Ctrl+C
```

Then run:

```bash
sudo systemctl start mmdvm_bridge
```

---

# Part 7 - Common problems

## STFU says `DVSwitch.ini` not found

Fix:

```bash
cd /opt/STFU
sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini DVSwitch.ini
```

## `sudo ./STFU` says command not found

The installed binary is normally here:

```text
/usr/local/bin/STFU
```

Run it like this:

```bash
sudo STFU
```

## STFU runs but no audio

- Make sure your local DVSwitch node is connected
- Make sure you switched to STFU mode:

```bash
/opt/MMDVM_Bridge/dvswitch.sh mode STFU
```

## MMDVM_Bridge conflicts with STFU

You must stop it before running STFU:

```bash
sudo systemctl stop mmdvm_bridge
```

## Still no audio on BM

Try:

- checking your `[STFU]` settings in `DVSwitch.ini`
- checking your node numbers in the connect command
- tuning the talkgroup again
- restarting STFU cleanly

---

# Part 8 - BrandMeister behavior (important)

BrandMeister can behave differently than TGIF.

On some systems, BM through normal MMDVM_Bridge flow may not pass audio immediately after a reboot until the node is keyed once.

This is why STFU manual mode can be useful - it gives you a cleaner direct BM path without replacing your normal system.

---

# Part 9 - Security reminder

If you ever exposed your real BrandMeister password in terminal output, logs, screenshots, or chat, change it in BrandMeister SelfCare afterward.

---

# Part 10 - Final note

This is a personal-use helper workflow for people who want to use BrandMeister through STFU without replacing their normal DVSwitch / MMDVM_Bridge setup.

Use it when you want STFU.  
Stop it when you want to go back to normal mode.
