# Run BrandMeister STFU on ASL3 / DVSwitch (Manual Mode)

Author: Terry Claiborne  
Contact: kc3kmv@yahoo.com

---

## 🚀 Quick Start (Most Important)

After install, this is all you need:

```bash
sudo bm-stfu.sh start 3220008
sudo bm-stfu.sh tune 91
sudo bm-stfu.sh stop
```

That’s it.

---

## 📦 Install

```bash
git clone https://github.com/TerryClaiborne/bm-stfu-manual-mode.git && cd bm-stfu-manual-mode && chmod +x install_bm_stfu_manual_mode.sh && sudo ./install_bm_stfu_manual_mode.sh
```

---

## ⚙️ One-Time Setup (Required)

Edit your settings:

```bash
sudo nano /opt/MMDVM_Bridge/DVSwitch.ini
```

Set:
- BMPassword
- UserID
- TalkerAlias
- StartTG

Then edit node numbers:

```bash
sudo nano /usr/local/bin/bm-stfu.sh
```

Set:
```bash
MAIN_NODE="YOUR_NODE"
DVSWITCH_NODE="YOUR_DVSWITCH_NODE"
```

---

## 🔄 Commands

Start STFU:

```bash
sudo bm-stfu.sh start 3220008
```

Change talkgroup:

```bash
sudo bm-stfu.sh tune 3100
sudo bm-stfu.sh tune 93
sudo bm-stfu.sh tune 3220008
```

Check status:

```bash
sudo bm-stfu.sh status
```

Stop and return to normal:

```bash
sudo bm-stfu.sh stop
```

---

## ⚠️ Important Notes

- Do NOT run STFU and mmdvm_bridge at the same time
- This does NOT replace your normal setup
- This is manual mode only

---

## 🛠 Troubleshooting

If STFU cannot find DVSwitch.ini:

```bash
cd /opt/STFU
sudo ln -sf /opt/MMDVM_Bridge/DVSwitch.ini DVSwitch.ini
```

If no audio:
- Check node connection
- Try keying once
