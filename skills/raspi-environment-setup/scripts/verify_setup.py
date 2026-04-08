#!/usr/bin/env python3
"""
Hardware and dependency verification script for insectDetector.
Run from the project root with the venv activated:
    source .venv/bin/activate
    python scripts/verify_setup.py
Exits with code 0 if all checks pass, 1 if any fail.
"""
import sys

failures = 0


def ok(msg: str) -> None:
    print(f"[OK] {msg}")


def fail(msg: str) -> None:
    global failures
    failures += 1
    print(f"[FAIL] {msg}", file=sys.stderr)


# --- Dependency version checks ---

try:
    import cv2
    ok(f"cv2 {cv2.__version__}")
except Exception as e:
    fail(f"cv2 import failed: {e}")

try:
    from picamera2 import Picamera2
    import picamera2
    ok(f"picamera2 {picamera2.__version__}")
except Exception as e:
    fail(f"picamera2 import failed: {e}")

try:
    import paho.mqtt.client as mqtt
    import paho.mqtt
    ok(f"paho-mqtt {paho.mqtt.__version__}")
except Exception as e:
    fail(f"paho-mqtt import failed: {e}")

# --- Camera capture check ---

try:
    cam = Picamera2()
    config = cam.create_video_configuration(
        main={"size": (640, 480), "format": "BGR888"},
        controls={"FrameRate": 10.0},
    )
    cam.configure(config)
    cam.start()
    try:
        for i in range(5):
            frame = cam.capture_array()
            if frame is None:
                fail(f"frame {i}: received None")
            else:
                ok(f"frame {i}: shape={frame.shape} dtype={frame.dtype}")
    finally:
        cam.stop()
        cam.close()
except Exception as e:
    fail(f"camera capture failed: {e}")

# --- Result ---

if failures == 0:
    print("\nAll checks passed.")
    sys.exit(0)
else:
    print(f"\n{failures} check(s) failed.", file=sys.stderr)
    sys.exit(1)
