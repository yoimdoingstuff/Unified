# TODO

Keep this list synchronized with [ROADMAP.md](ROADMAP.md).

## Immediate priorities
- [x] Decide supported iOS range: 5–10. *(See docs/COMPATIBILITY.md.)*
- [x] Decide first proof-of-concept iOS version: 8.4.1.
- [x] Decide initial device and CPU architecture: iPad mini 1st gen, armv7.
- [x] Decide first jailbreak: EverPwnage. *(Unified itself must stay jailbreak-agnostic.)*
- [x] On the device: confirm Cydia Substrate is installed. *(Implied: Cydia installed Unified, which depends on `mobilesubstrate`.)*
- [x] Find and record a toolchain/SDK that builds armv7. *(docs/DEVELOPMENT.md: verified build toolchain.)*
- [x] Set up and verify Theos. *(In CI on Linux; no local build environment.)*
- [x] Build the minimal Logos tweak that logs in enabled apps without modifying behaviour. *(CI)*
- [x] Install the package on the iPad mini. *(0.0.1~poc1 via Cydia; owner report.)*
- [ ] Fix: Settings row missing on iPad mini with 0.0.2 (check PreferenceLoader first; docs/TESTING.md troubleshooting).
- [ ] Run the Settings-pane device test in docs/TESTING.md (no SSH needed).
- [ ] Run the scaling device test (0.0.3) and read the diagnostics report.
- [ ] Scaling: landscape support (UIKit's transform is rotated there; currently skipped).
- [ ] Scaling: iOS 5–7 touch path (no scene-reference conversions).
- [ ] Scaling: hide or move the 1×/2× button when Unified scales the app.
- [ ] Observe the tweak actually loading in an app. *(Needs either the device log or the first visible feature.)*
- [x] Add geometry tests for Fit, Fill, and Stretch. *(`tests/test_geometry.c`)*
- [x] Confirm host tests pass in the `ci` workflow's `host-tests` job. *(Passed 2026-11-13 on commit 43d9b9a: gcc and clang on ubuntu-latest, clang on macos-latest, each with and without ASan/UBSan.)*
- [x] Get the `tweak-build` CI job passing. *(Passed on 87a2f5f with the iPhoneOS 10.3 SDK, armv7 only. The 9.3 SDK fails: its libSystem.tbd re-exports liblaunch, but liblaunch.tbd is missing.)*
- [x] Confirm the universal build in CI: one dylib with armv7 and arm64 slices. *(e713149)*
- [x] Confirm CI's "Check universal package" step passes (armv7 min 5.0, arm64 min 7.0). *(8304012)*
- [ ] Select a simple app for the first rendering experiment.

## Technical investigation
- [ ] Determine target OS screen and window bounds behaviour (portrait-fixed before iOS 8, orientation-dependent from iOS 8).
- [ ] Find where iPhone-on-iPad compatibility scaling is applied on each version (in-app UIKit vs SpringBoard/backboardd).
- [ ] Investigate the install/launch block for iPad-only apps on iPhone.
- [ ] Investigate UIKit trait collections and size classes.
- [ ] Investigate safe areas and status/navigation bars.
- [ ] Identify a viable rendering integration point.
- [ ] Determine inverse touch/gesture coordinate mapping. *(Math exists: `UNTransformMapDestinationPointToSource`. Where to apply it in UIKit's event path, and what to do with touches outside content, are still open.)*
- [ ] Decide pixel-alignment policy for transforms (rounding to device pixels) once the rendering hook is known.
- [ ] Test orientation changes and relaunch.
- [ ] Evaluate whether specific apps require idiom spoofing.
- [x] Record private API dependencies and alternatives. *(docs/PRIVATE_APIS.md; keep it updated as hooks are added.)*

## Upscaling (ROADMAP Phase 3a)
- [ ] Capture baseline screenshots of iOS's own iPhone-app 2× mode on the iPad mini.
- [ ] Prototype a higher `contentsScale` on one app's layer tree and compare text sharpness.
- [ ] Prototype `CALayer` filter choices (nearest / linear / trilinear).
- [ ] Measure memory and frame rate on the 512 MB device.

## HD texture packs (ROADMAP Phase 3b)
- [ ] Draft the pack folder layout and manifest format.
- [ ] Prototype `UIImage` load replacement for one app, keeping the original point size.
- [ ] Define validation rules (aspect ratio, size limits, formats) and fallbacks.
- [ ] Research asset-catalog images and OpenGL ES texture uploads.

## Configuration
- [x] Define bundle identifier matching. *(Exact match; see `UNPolicy.c`.)*
- [x] Define global defaults and per-app overrides. *(docs/DEVELOPMENT.md)*
- [x] Define safe disable mechanism. *(Off unless both switches are on; Settings/SpringBoard excluded; uninstall.)*
- [ ] Verify preference storage on iOS 8.4.1: can a sandboxed app read `/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist`?
- [x] Settings UI: `Settings > Unified` with global switch, default mode, app list, per-app switch and mode. *(Built; not yet seen on a device.)*
- [ ] Settings UI: "reset all settings" control.
- [ ] Settings UI: confirm the app list works on iOS 5–7 (installation-cache fallback) and 9–10.

## Quality
- [ ] Add reproducible build instructions.
- [ ] Add device / OS / jailbreak test matrix.
- [ ] Add crash and regression test notes.
- [ ] Verify package install, upgrade, disable, and uninstall.
- [ ] Keep known limitations visible in README.
