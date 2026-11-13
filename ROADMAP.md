# Roadmap

Unified is in **planning / research**. These milestones are goals, not claims of completed work.

## Phase 0 - Definition and research
- [x] Choose the overall supported range: iOS 5–10 (armv7, armv7s, arm64).
- [x] Choose the first proof-of-concept target: iPad mini (1st gen, cellular, armv7), iOS 8.4.1, EverPwnage jailbreak. *(See docs/COMPATIBILITY.md.)*
- [ ] Confirm Cydia Substrate is the injection platform (checked implicitly when the first test tweak loads).
- [ ] Choose a toolchain/SDK that builds armv7 (iOS 5.0 deployment target) and arm64.
- [ ] Research where iOS applies iPhone-on-iPad compatibility scaling, and the install-time block on iPad-only apps on iPhone.
- [ ] Choose the first jailbreak and injection environment.
- [ ] Confirm Theos toolchain support.
- [ ] Research UIKit geometry, trait collections, screen modes, and Core Animation on the target OS.
- [ ] Build a compatibility matrix of representative iPhone-only and iPad-only apps.

**Exit:** reproducible development environment and written proof-of-concept plan.

## Phase 1 - Safe tweak skeleton
- [ ] Create Theos project and package metadata. *(Written; not yet built.)*
- [ ] Add process filtering and bundle identification. *(Written: `UNPolicy.c` + `Tweak.x`; untested on device.)*
- [ ] Add configuration parsing with safe defaults. *(Written; untested on device.)*
- [ ] Add global disable and per-app opt-in. *(Written; untested on device.)*
- [ ] Verify install, disable, removal, and recovery.

**Exit:** tweak loads without changing app geometry and does not affect unrelated processes.

## Phase 2 - Geometry proof of concept
- [x] Implement unit-tested Fit, Fill, and Stretch calculations. *(`Sources/UNGeometry.*`, `tests/test_geometry.c`. Host tests pass in CI; not yet exercised on iOS.)*
- [ ] Identify app content bounds and coordinate spaces.
- [ ] Prototype rendering adaptation in one direction.
- [ ] Map touch coordinates back into the app's source coordinate space.
- [ ] Test taps, swipes, scrolling, keyboard, and rotation.

**Exit:** one simple app adapts in one direction with correct interaction.

## Phase 3 - Bidirectional support
- [ ] Support iPhone-designed apps on iPad displays.
- [ ] Support iPad-designed apps on iPhone displays.
- [ ] Handle safe areas, bars, and orientation.
- [ ] Investigate size classes and idiom-dependent layouts.
- [ ] Add per-app compatibility overrides.

**Exit:** both directions work for a documented set of apps.

## Phase 3a - Upscaling (render quality)

Goal: scaled-up apps look sharp instead of pixel-stretched. This matters most on 1x screens like the first target, where iPhone apps are enlarged about 2.13×.

- [ ] Measure the baseline: how iOS's own 2× mode and a plain Unified transform look on the target device.
- [ ] Render scale: draw app content at a higher internal resolution (e.g. raise `contentsScale` / `contentScaleFactor`) so text, vector shapes and Core Graphics drawing are rasterised at the final on-screen size. This does not add detail to bitmaps.
- [ ] Scaling filter choice per app: nearest (pixel-art), linear, trilinear (`CALayer` magnification/minification filters).
- [ ] Measure memory and frame-rate cost on the 512 MB target device; cap or disable render scale when unsafe.
- [ ] Per-app setting with a safe default (off), plus a fallback if layer creation fails.
- [ ] Document what cannot be upscaled: OpenGL ES / video surfaces, pre-rendered bitmaps (see HD texture packs).

**Exit:** a documented set of UIKit apps renders text and vector UI crisply at the chosen scale, with measured memory cost and no input regressions.

## Phase 3b - HD texture pack support

Goal: let users supply higher-resolution replacement images for a specific app, to complement upscaling for bitmap content.

- [ ] Define a pack format: per-bundle-ID folder (e.g. under `/Library/Unified/Packs/<bundle id>/`) with a manifest naming the app version(s) it targets and the images it replaces.
- [ ] Replace images loaded through UIKit (`+[UIImage imageNamed:]`, `imageWithContentsOfFile:`, and related initialisers): load the replacement at the original point size with a higher `scale`, so layout does not change.
- [ ] Validate replacements: same aspect ratio as the original, size limits, readable formats only; fall back to the original on any mismatch.
- [ ] Investigate asset catalogs (`Assets.car`, iOS 7+): can replacement work by asset name at the API level?
- [ ] Investigate games that upload textures directly through OpenGL ES. This is much harder and likely app-specific; only a research item until proven.
- [ ] Per-app enable switch, global off switch, and a way to tell when a pack is active.
- [ ] Measure memory cost on the target device.
- [ ] Packs are user-supplied. Do not ship or commit app assets (they are proprietary). Document how pack authors should handle rights.

**Exit:** one documented UIKit app shows replaced images at the correct size with no layout change, and disabling the pack restores the originals.

## Phase 4 - Configuration and usability
- [ ] Add a target-appropriate Settings interface.
- [ ] Add global default mode and per-app mode selection.
- [ ] Add per-app enable/disable and reset controls.
- [ ] Explain compatibility warnings.

## Phase 5 - Compatibility and release
- [ ] Expand device and iOS compatibility matrix.
- [ ] Test navigation, media, keyboard, and modal flows.
- [ ] Test install, upgrade, disable, and uninstall.
- [ ] Review crashes, memory use, and launch overhead.
- [ ] Prepare release notes and package metadata.
- [ ] Publish only with clearly stated tested environments.

## Future ideas
- App-specific layout profiles.
- Optional device-idiom overrides.
- Preference export/import.
