---
name: raspi-environment-setup
description: "Use when setting up the Raspberry Pi environment for insectDetector, installing dependencies, enabling the camera, verifying hardware, or troubleshooting installation issues on Pi OS Bookworm with Camera Module 2 NoIR."
user-invocable: true
---

# Raspberry Pi Environment Setup

## Pre-requisites Checklist

- [ ] Raspberry Pi OS **Bookworm** (64-bit recommended for Pi 4/5)
- [ ] Camera Module 2 NoIR physically connected to the CSI ribbon cable port
- [ ] Legacy camera interface **DISABLED**: `sudo raspi-config` → Interface Options → Legacy Camera → **No** (use libcamera, not legacy)
- [ ] Internet connection available for package installation
- [ ] Python 3.11+ (included in Bookworm — verify with `python3 --version`)

## 1. System Package Installation

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-picamera2 python3-opencv python3-pip python3-venv libatlas-base-dev
```

| Package | Why |
|---|---|
| `python3-picamera2` | Official picamera2 from apt — avoids libcamera conflicts that pip installs cause |
| `python3-opencv` | System OpenCV — avoids ARM compilation issues and GUI lib conflicts |
| `libatlas-base-dev` | Required by numpy on ARM (ATLAS BLAS backend) |

## 2. Python Virtual Environment Setup

```bash
cd ~/insectDetector
python3 -m venv .venv --system-site-packages
source .venv/bin/activate
pip install paho-mqtt pyyaml
```

**`--system-site-packages` is mandatory.** picamera2 and OpenCV are installed via apt into the system Python. A standard isolated venv cannot see them. Only `paho-mqtt` and `pyyaml` are installed via pip — do NOT pip-install `opencv-python`, `opencv-python-headless`, or `picamera2` on top.

## 3. Hardware Verification

Run the bundled verification script to confirm all dependencies and hardware are working:

```bash
source .venv/bin/activate
python scripts/verify_setup.py
```

Expected output:
```
[OK] cv2 4.x.x
[OK] picamera2 0.x.x
[OK] paho-mqtt 2.x.x
[OK] frame 0: shape=(480, 640, 3) dtype=uint8
[OK] frame 1: shape=(480, 640, 3) dtype=uint8
...
All checks passed.
```

See [verify_setup.py](./scripts/verify_setup.py) for the full script.

## 4. Autostart on Boot (Production)

Create a systemd service so insectDetector starts automatically after boot:

```bash
sudo nano /etc/systemd/system/insect-detector.service
```

Paste this content (adjust `User` and `WorkingDirectory` to match your actual username):

```ini
[Unit]
Description=InsectDetector
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/insectDetector
ExecStart=/home/pi/insectDetector/.venv/bin/python main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable insect-detector
sudo systemctl start insect-detector
sudo systemctl status insect-detector
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: picamera2` inside venv | venv created without `--system-site-packages` | Delete `.venv` and recreate with the flag |
| `ImportError: libGL.so.1 not found` | Missing OpenGL lib (pip opencv-python pulled in) | `sudo apt install libgl1` |
| `RuntimeError: Camera is not available` | Camera not detected by libcamera | Check ribbon cable seating; run `libcamera-hello --list-cameras` |
| `Permission denied /dev/video0` | User not in video group | `sudo usermod -aG video $USER` then log out/in |
| `libcamera: ERROR` messages in output | libcamera informational logging | Normal — not fatal; suppress with `LIBCAMERA_LOG_LEVELS=*:ERROR python main.py` |
