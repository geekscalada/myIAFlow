---
name: insectdetector-context
description: "Use when working on any module of the insectDetector project. Provides design decisions, module boundaries, internal contracts, project structure, and known risk mitigations. Load this skill whenever implementing, reviewing, or debugging insectDetector code."
user-invocable: true
disable-model-invocation: false
---

# insectDetector — Project Context

## Project Summary

Python monolith running headless on Raspberry Pi 4 (→ Pi 5 in production). Camera Module 2 NoIR mounted on the ceiling detects cockroaches by background subtraction, saves JPEG evidence per event, and publishes an MQTT alert to a local broker (consumed by Home Assistant).

## Module Boundaries and Responsibilities

| Module | Responsibility | Must NOT |
|---|---|---|
| `src/capture/` | picamera2 → BGR numpy frames at 10 FPS | No CV logic |
| `src/detector/` | MOG2 + morphology + contour filter → returns detections | No I/O of any kind |
| `src/storage/` | Writes `detections/YYYY-MM-DDTHH:MM:SS.jpg` | No CV, no MQTT |
| `src/publisher/` | paho-mqtt QoS 0 publish | No CV, no file I/O |
| `src/orchestrator/` | Main loop, 60s cooldown gate, wires all modules | No direct CV or I/O |
| `config.yaml` | Single source of truth for all parameters | Never duplicated in code |

## Internal Contracts (exact signatures)

```python
# capture
FrameSource                              # generator that yields np.ndarray (BGR uint8)

# detector
detect(frame: np.ndarray) -> list[Detection]
# Detection fields: bbox (x,y,w,h), area: float, aspect_ratio: float

# storage
save(frame: np.ndarray, timestamp: datetime) -> Path   # raises on failure

# publisher
publish(payload: dict) -> None           # never raises — QoS 0, loss accepted
```

## Key Design Decisions (non-negotiable)

- **MOG2 with `detectShadows=True`** — masks shadow pixels (127) separately from foreground (255), eliminating the main source of false positives (people walking under the camera)
- **Erosion → dilation pipeline** — erosion removes single-pixel noise; dilation re-joins blob fragments from fast-moving insects that MOG2 splits
- **Area filter 50–5000 px² + aspect ratio 1.5–3.0** — cockroaches are elongated; humans seen from the ceiling are near-circular (~1.0–1.2). This is the primary discriminator
- **Fire-and-forget MQTT (QoS 0)** — occasional loss is acceptable for personal use; not a life-safety system
- **One JPEG per event** — first positive frame only; maximum simplicity for MVP validation

## Risk Mitigations Already Decided

| Risk | Mitigation |
|---|---|
| Shadow false positives | `detectShadows=True` in MOG2 |
| Fast-insect blob fragmentation | MOG2 + dilation (not 3-frame diff) |
| Perspective size variation | Wide P2 area range (50–5000 px²) |
| Unlimited storage growth | **Not handled in MVP** — planned for next iteration |
| Network instability / MQTT loss | Accepted (QoS 0) — escalate to QoS 1 if needed |

## Project File Structure

```
insectDetector/
├── src/
│   ├── capture/          # picamera2 → frames
│   ├── detector/         # MOG2 + morphology + filters
│   ├── storage/          # JPEG with timestamp
│   ├── publisher/        # MQTT fire-and-forget
│   └── orchestrator/     # main loop + cooldown
├── config.yaml           # all parameters
├── main.py               # entry point (< 30 lines)
├── requirements.txt      # opencv-python-headless, picamera2, paho-mqtt, pyyaml
└── detections/           # output JPEGs (runtime, gitignored)
```

## Orchestration Flow

```
FrameSource → detect(frame)
                    ↓ list[Detection] non-empty AND cooldown expired
             storage.save(frame, now)   publisher.publish(payload)
```

Both `save` and `publish` are always called on a positive detection (sequentially). `save` raises on failure (log and continue). `publish` never raises.
