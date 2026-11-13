# Roadmap

Unified is in **planning / research**. These milestones are goals, not claims of completed work.

## Phase 0 - Definition and research
- [ ] Choose the first target iOS version and device architecture.
- [ ] Choose the first jailbreak and injection environment.
- [ ] Confirm Theos toolchain support.
- [ ] Research UIKit geometry, trait collections, screen modes, and Core Animation on the target OS.
- [ ] Build a compatibility matrix of representative iPhone-only and iPad-only apps.

**Exit:** reproducible development environment and written proof-of-concept plan.

## Phase 1 - Safe tweak skeleton
- [ ] Create Theos project and package metadata.
- [ ] Add process filtering and bundle identification.
- [ ] Add configuration parsing with safe defaults.
- [ ] Add global disable and per-app opt-in.
- [ ] Verify install, disable, removal, and recovery.

**Exit:** tweak loads without changing app geometry and does not affect unrelated processes.

## Phase 2 - Geometry proof of concept
- [ ] Implement unit-tested Fit, Fill, and Stretch calculations.
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
- Resolution/render-scale controls where supported.
- Preference export/import.
