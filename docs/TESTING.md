# Testing Strategy

## Principles

A successful build does not prove runtime scaling works. Test visual geometry, interaction, lifecycle, and stability.

## Geometry unit tests

Implemented in `tests/test_geometry.c` against `Sources/UNGeometry.c`; run with `make -C tests` (see [Development](DEVELOPMENT.md)). Each item below has at least one test case.

Test Fit, Fill, and Stretch independently from UIKit:
- Portrait and landscape source/destination rectangles.
- Equal and extreme aspect ratios.
- Non-zero rectangle origins.
- Invalid or zero-sized input.
- Expected scale and translation.
- Forward/inverse transform round trips.

## First device test: Phase 1 skeleton

Goal: show the tweak loads only where enabled and changes nothing. Not run yet.

1. Install the package. Reboot or respring if prompted.
2. With **no** preferences file, open several apps and Settings. Expected: no `[Unified]` log lines, no behaviour change.
3. Install the example preferences with one test app's bundle ID. Launch that app. Expected: exactly one `[Unified] enabled for <bundle id> (mode: fit)` line in the device log, and no visible change.
4. Launch a different app. Expected: no log line.
5. Change `Mode` to `stretch` and an invalid value. Expected: `stretch`, then `fit`.
6. Set `Enabled` to `false`. Expected: no log line.
7. Uninstall the package. Expected: device and apps behave normally.

If step 3 shows nothing, check that Cydia Substrate is installed, then whether the app's sandbox can read the preferences path. That path is unverified on iOS 8.

## Runtime matrix

| Area | Checks |
| --- | --- |
| Launch | Cold launch, warm launch, relaunch |
| Display | Fit, Fill, Stretch; clipping and alignment |
| Input | Corner taps, centre tap, swipes, gestures |
| Scrolling | Vertical, horizontal, nested scroll views |
| Layout | Rotation, safe areas, bars, modal views |
| Text | Keyboard, text entry, selection, alerts |
| Lifecycle | Background, foreground, termination |
| Stability | Repeated launch, memory, crash logs |
| Isolation | Unselected apps and system UI unchanged |
| Recovery | Disable tweak, remove package, reboot |

## Test record template

    Date:
    Device model / architecture:
    iOS version and build:
    Jailbreak and version:
    Injection platform and version:
    Theos / SDK version:
    App and bundle identifier:
    App version:
    Scaling direction / mode:
    Build result:
    Launch result:
    Visual result:
    Touch / gesture result:
    Rotation result:
    Keyboard / modal result:
    Known issues:
    Logs / reproduction notes:

## Release gate

Do not mark a target supported until the package builds, loads only in intended processes, basic visual behaviour and touch mapping work, rotation and common presentations are checked, disable/uninstall paths are verified, and limitations are documented.
