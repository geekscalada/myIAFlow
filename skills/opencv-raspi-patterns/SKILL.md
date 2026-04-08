---
name: opencv-raspi-patterns
description: "Use when writing or reviewing OpenCV code for Raspberry Pi ARM. Covers MOG2 background subtraction, morphological filtering, contour extraction and filtering, and OpenCV performance considerations on ARM hardware."
user-invocable: true
---

# OpenCV Patterns for Raspberry Pi ARM

## MOG2 Background Subtraction

```python
mog2 = cv2.createBackgroundSubtractorMOG2(
    history=500,
    varThreshold=16,
    detectShadows=True
)
mask = mog2.apply(frame)
```

`apply()` returns a mask with three values:
- `0` = background
- `127` = shadow (grey)
- `255` = foreground (white)

**To discard shadows**, threshold to keep only `255` — do not use `> 0`:
```python
_, fg_mask = cv2.threshold(mask, 254, 255, cv2.THRESH_BINARY)
```

**Tuning parameters:**
- `history` — number of frames used to model the background. Lower = adapts faster (useful when lights switch on/off)
- `varThreshold` — pixel variance threshold. Higher = less sensitive, fewer false positives in noisy scenes

**Pi 4 limits:** MOG2 is CPU-bound. 640×480 at 10 FPS is within safe limits. 1280×720 at 10 FPS may saturate the CPU.

**Warm-up:** MOG2 needs ~`history` frames to stabilize. Skip detections during the first N frames to avoid noisy output on startup:
```python
WARMUP_FRAMES = 50
for i, frame in enumerate(source):
    mask = mog2.apply(frame)
    if i < WARMUP_FRAMES:
        continue
    # process mask
```

## Morphological Pipeline (Erosion → Dilation)

- **Erosion** removes isolated noise pixels (single-pixel salt-and-pepper artefacts)
- **Dilation** re-joins blob fragments split by fast-moving subjects (cockroaches moving quickly across frames)

```python
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))
mask = cv2.erode(mask, kernel, iterations=iterations)
mask = cv2.dilate(mask, kernel, iterations=iterations)
```

Use `MORPH_ELLIPSE` (not `MORPH_RECT`) for isotropic shapes — avoids horizontal/vertical bias. Typical starting values: `kernel_size=3`, `iterations=2`.

## Contour Extraction and Filtering

```python
contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

detections = []
for c in contours:
    area = cv2.contourArea(c)
    if not (area_min <= area <= area_max):
        continue

    x, y, w, h = cv2.boundingRect(c)
    # Always compute ratio as max/min to get a value >= 1
    aspect_ratio = max(w, h) / min(w, h) if min(w, h) > 0 else 0
    if not (aspect_ratio_min <= aspect_ratio <= aspect_ratio_max):
        continue

    detections.append(Detection(bbox=(x, y, w, h), area=area, aspect_ratio=aspect_ratio))
```

**Why aspect ratio works:**
- Cockroaches (elongated): 1.5–3.0
- Humans seen from ceiling (near-circular): 1.0–1.2
- This is the primary discriminator between insects and people

## ARM Performance Patterns

- **Resize before processing** — always work at target resolution, never process a higher-resolution frame:
  ```python
  frame = cv2.resize(frame, (640, 480))
  ```
- **Grayscale for MOG2** — if colour is not needed for downstream steps, convert first:
  ```python
  gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
  mask = mog2.apply(gray)
  ```
- **No `cv2.imshow`** — requires a display; crashes on headless Pi. Use file saves for debugging instead
- **Profile the detect call** — target < 50ms per frame at 10 FPS:
  ```python
  t0 = time.perf_counter()
  detections = detect(frame)
  elapsed_ms = (time.perf_counter() - t0) * 1000
  ```

## Common Pitfalls on Pi OS Bookworm

| Problem | Cause | Fix |
|---|---|---|
| `ImportError: libGL` | `opencv-python` pulls in GUI libs | Use `opencv-python-headless` instead |
| pip OpenCV conflicts with libcamera | Both provide camera bindings | Use system `python3-opencv` via apt, or `opencv-python-headless` via pip — not both |
| Noisy detections on startup | MOG2 background not yet modelled | Add warm-up skip (see above) |
| `cv2.imshow` crashes | No display available | Remove all `imshow` calls in production |
