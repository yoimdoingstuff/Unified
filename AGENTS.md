# Agent Instructions

These instructions apply to all automated coding agents and contributors.

## Project objective

Build Unified, a jailbreak tweak for legacy iOS that aims to adapt iPhone-only applications to iPad displays and iPad-only applications to iPhone displays.

This is not simply a screen magnifier. Account for app layout, device idiom assumptions, orientation, touch coordinates, system UI, and jailbreak compatibility.

## Non-negotiable rules

1. Inspect existing source, build configuration, documentation, and history before making architectural decisions.
2. Never invent compatibility. State exactly which iOS versions, devices, jailbreaks, and injection platforms have been tested.
3. Do not claim a feature works without a reproducible test. Distinguish implemented, experimental, planned, and verified functionality.
4. Prefer reversible changes. Add a reliable per-app disable switch and safe global disable/recovery path early.
5. Do not globally spoof device identity by default. Scope overrides to selected processes and make them configurable.
6. Preserve input correctness. Every rendering transform needs tested mapping for taps, gestures, scrolling, and keyboard interaction where applicable.
7. Avoid private APIs unless unavoidable. Document each private API, why it is needed, and its compatibility risk.
8. Keep the tweak lightweight. Avoid polling, network access, analytics, and unnecessary dependencies.
9. Do not commit proprietary SDKs, signing credentials, jailbreak bypasses, or device/user data.
10. Update README, ROADMAP, and TODO when implementation status changes.

## Architecture guidance

Separate configuration, process selection, compatibility policy, geometry calculation, rendering integration, and input-coordinate mapping.

Keep the first proof of concept narrow and explicitly opt-in. Prefer a shared, unit-testable geometry model over scattered scale constants.

Do not assume changing screen bounds, device idiom, or trait collections will make an app relayout correctly. A layer transform alone is not a complete solution.

Avoid modifying SpringBoard or system processes unless a documented requirement exists.

## Workflow

1. Read the architecture and development documents.
2. Confirm target iOS, device architecture, jailbreak, and injection library.
3. Make the smallest testable change.
4. Build with the documented Theos toolchain.
5. Test on a disposable or restorable device.
6. Record device, OS, jailbreak, app, mode, and results.
7. Update documentation and task status.

## Definition of done

A feature needs documented behaviour and limitations, safe defaults, a disable path, build validation, runtime tests, input/orientation checks, and updated documentation.

## Agent report

Report files changed, build/test commands, exact tested environment, results, failures, and remaining risks. Never claim a test passed if it was not run.
