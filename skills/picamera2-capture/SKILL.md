---
name: picamera2-capture
description: "Use when writing or reviewing camera capture code using picamera2 on Raspberry Pi OS (Bookworm). Covers Picamera2 API, 10 FPS configuration, BGR frame delivery compatible with OpenCV, and NoIR camera considerations."
user-invocable: true
---

# picamera2 Capture Patterns

## picamera2 vs Legacy picamera

| | picamera2 | picamera (v1) |
|---|---|---|
| Pi OS Bookworm support | ✓ Official | ✗ Deprecated, does not work |
| libcamera stack | ✓ | ✗ |
| Camera Module 2 | ✓ | ✗ on Bookworm |

**Install (preferred):**
```bash
sudo apt install python3-picamera2
```

Or via pip (use only inside a venv with `--system-site-packages`):
```bash
pip install picamera2
```

**Do NOT use `cv2.VideoCapture(0)`** on Pi OS Bookworm — unreliable with the libcamera stack.

## Basic Capture Pattern for OpenCV

```python
from picamera2 import Picamera2

cam = Picamera2()
config = cam.create_video_configuration(
    main={"size": (640, 480), "format": "BGR888"},
    controls={"FrameRate": 10.0}
)
cam.configure(config)
cam.start()

try:
    while True:
        frame = cam.capture_array()  # np.ndarray, BGR, uint8, shape (480, 640, 3)
        # pass frame to detector
finally:
    cam.stop()
    cam.close()
```

- `"format": "BGR888"` delivers frames in OpenCV-native BGR order — **no `cvtColor` conversion needed**
- `capture_array()` blocks until the next frame is ready, respecting the configured `FrameRate`

## FrameRate Control

```python
# At configuration time (preferred):
controls={"FrameRate": 10.0}

# After start (dynamic adjustment):
cam.set_controls({"FrameRate": 10.0})
```

10 FPS is the target for insectDetector — the balance point between capturing fast insects and keeping Pi 4 CPU load safe.

## Startup and Teardown

Always release the camera on exit. Two patterns:

**try/finally (explicit):**
```python
cam = Picamera2()
cam.configure(config)
cam.start()
try:
    # main loop
finally:
    cam.stop()
    cam.close()
```

**Context manager (implicit):**
```python
with Picamera2() as cam:
    cam.configure(config)
    cam.start()
    # main loop
```

**AEC/AGC settling:** the first ~10 frames after `cam.start()` may be underexposed while the auto-exposure and auto-gain algorithms stabilize. These frames should be absorbed by the MOG2 warm-up skip — no separate handling needed.

## NoIR Camera Considerations

The Camera Module 2 NoIR has no IR cut filter — it sees near-infrared light in addition to visible spectrum.

| Condition | Effect on frames | Impact on detection |
|---|---|---|
| Daylight | Slight pink/purple cast from IR leakage | None — MOG2 operates on intensity changes |
| Night + 850nm IR LEDs | Near-greyscale appearance | None — MOG2 works normally |

No software configuration is required to "enable" NoIR — it is a hardware property of the lens assembly.

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `RuntimeError: Camera is not available` | Camera interface disabled | `sudo raspi-config` → Interface Options → Camera → Enable |
| `libcamera: ERROR` messages in logs | libcamera informational output | Normal — not fatal, can be suppressed with `LIBCAMERA_LOG_LEVELS=*:ERROR` |
| Frame wrong shape or wrong dtype | Wrong format string | Use `"BGR888"` → gives `(H, W, 3)` uint8 |
| `ModuleNotFoundError: picamera2` in venv | venv missing system packages | Recreate venv with `--system-site-packages` |
