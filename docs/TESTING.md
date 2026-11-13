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

## Preferences unit tests

`tests/test_preferences.m` covers `UNPreferences` and the UIDeviceFamily parser in `UNAppCatalog`: missing, malformed and wrong-type files load as "off"; save/reload round trip in the documented format; validation of modes and bundle IDs; unknown keys preserved. It needs Foundation, so it runs only on macOS (the macOS `host-tests` CI job).

## Troubleshooting: no Unified row in Settings

Reported on 0.0.2 (iPad mini, iOS 8.4.1). Check in this order:
1. **PreferenceLoader installed?** Cydia → Installed → look for "PreferenceLoader". A `.deb` installed with Filza or `dpkg -i` does not install dependencies automatically, and without PreferenceLoader the Unified row never appears. Install it from Cydia (BigBoss repo).
2. **Settings fully restarted?** Close Settings from the app switcher (double-press Home, swipe it up) and open it again. A respring also works.
3. **Right version?** Cydia → Installed → Unified should show 0.0.2 or later. 0.0.1 had no Settings pane.
4. **Files present?** In Filza: `/Library/PreferenceLoader/Preferences/Unified.plist` and `/Library/PreferenceBundles/UnifiedPrefs.bundle/`.

Fallback without the pane: create `/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist` in Filza (it can edit plists), using `Resources/example-preferences.plist` as the template.

## Device test: scaling (0.0.3, experimental)

1. In Settings → Unified, turn on **Enabled**, open Choose Apps, pick an **iPhone-only** app, turn on **Use Unified**, leave Mode on Default (Fit).
2. Close the app fully from the app switcher, then open it. Hold the iPad in portrait.
3. Expected: the app is taller than iOS's normal 2× view and fills the screen top to bottom, with narrow black bars left and right.
4. Tap buttons near each corner and in the middle, scroll a list, and type in a text field. Expected: taps land where you touch.
5. Open Settings → Unified → the app → View Report. Expected: "Unified loaded in this app", "Classic (compatibility) mode: yes", a window line starting "SCALED fit", and non-zero conversion counts after tapping.
6. Try Fill and Stretch (close and reopen the app after each change).
7. Turn the app off in Settings, close and reopen it. Expected: back to normal 1×/2×.

Record what you see, especially any window line that says "not scaled", and whether taps are offset.

## Device test: Settings pane (no SSH needed)

Goal: show the pane works and saves settings. Not run yet.

1. Install the package from Cydia. It now depends on PreferenceLoader; Cydia will offer to install it.
2. Open Settings. Expected: a **Unified** row with a blue icon. Settings does not crash.
3. Open it. Expected: an Enabled switch, Default mode (Fit), Choose Apps (None), and a Status note.
4. Choose Apps. Expected: on an iPad, an "iPhone apps" section listing installed iPhone-only App Store apps by name, then "Other apps".
5. Open one app, switch **Use Unified** on, and set Mode to Fill. Go back. Expected: the app's row shows "On, Fill" and the root page shows "1 on".
6. Leave Settings completely (close it from the app switcher), reopen it. Expected: all values are still set.
7. Switch the master **Enabled** off and on. Expected: it stays as set after reopening.

Record the device, iOS version, and anything that differs from the expected results.

## First device test: Phase 1 skeleton (needs the device log)

Goal: show the tweak loads only where enabled and changes nothing. Not run yet. Settings can now be changed in the pane instead of copying the example file.

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
