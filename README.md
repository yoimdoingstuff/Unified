# Unified

**One app. Any screen.**

Unified is a planned jailbreak tweak for legacy iOS. Its goal is to make iPhone-only applications usable on iPad-sized displays and iPad-only applications usable on iPhone-sized displays.

The project is currently in planning and research. No working tweak or compatibility guarantees are claimed yet.

## Goals
- Scale iPhone-designed interfaces to use an iPad display.
- Fit iPad-designed interfaces onto an iPhone display.
- Provide per-app configuration.
- Offer Fit, Fill, and Stretch display modes.
- Preserve touch interaction, scrolling, rotation, and system UI behaviour.
- Support legacy jailbreak injection environments where practical, with no jailbreak-specific code.
- **Upscaling (planned):** render scaled apps at a higher internal resolution and offer filter choices, so enlarged interfaces look sharp rather than pixel-stretched.
- **HD texture packs (planned):** optional, user-supplied, per-app replacement images at higher resolution, for bitmap content that upscaling cannot sharpen.

## Display modes

| Mode | Behaviour |
| --- | --- |
| **Fit** | Preserve aspect ratio and show the entire interface. Unused space may remain. |
| **Fill** | Preserve aspect ratio while filling the display. Some content may be cropped. |
| **Stretch** | Independently scale horizontal and vertical dimensions. Distortion is possible. |

These are intended behaviours, not a promise that every app can be transformed by one rendering operation.

## Important technical distinction

Unified must address two separate concerns:

1. **Rendering and geometry:** fitting an application's existing interface into a different display shape.
2. **Application compatibility:** handling apps that assume a particular device idiom, screen dimensions, size classes, orientation, or UIKit feature set.

Changing reported screen dimensions or spoofing device identity alone is not sufficient. The implementation must test layout behaviour and input-coordinate mapping, and may need app-specific compatibility rules.

## Planned technology
- Objective-C for UIKit and runtime integration.
- Logos / Theos for tweak development and packaging.
- A jailbreak injection backend selected for the target iOS and jailbreak.
- UIKit and Core Animation investigation for layout, rendering, and coordinate handling.

**Target range: iOS 5 through iOS 10, as one universal package.** A single `.deb` contains one dylib with an armv7 slice (iOS 5.0+) and an arm64 slice (iOS 7.0+). There are no per-version builds. This is the goal, not a tested claim. No version in that range has been tested yet. **First proof-of-concept target:** iPad mini (1st generation, armv7) on iOS 8.4.1 with the EverPwnage jailbreak, scaling iPhone apps up to the iPad display. Nothing has been built or run on it yet. See [Compatibility](docs/COMPATIBILITY.md).

## Repository guide
- [Project overview](docs/PROJECT_OVERVIEW.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Technical design](docs/TECHNICAL_DESIGN.md)
- [Roadmap](ROADMAP.md)
- [Task list](TODO.md)
- [Development setup](docs/DEVELOPMENT.md)
- [Testing strategy](docs/TESTING.md)
- [Compatibility research](docs/COMPATIBILITY.md)
- [Security and privacy](docs/SECURITY.md)
- [Private APIs and dependencies](docs/PRIVATE_APIS.md)
- [Agent instructions](AGENTS.md)
- [Contributing](CONTRIBUTING.md)

## Current status

**Planning / research, early implementation.** No tweak exists yet; nothing runs on a device.

| Component | Status |
| --- | --- |
| Geometry engine (`Sources/UNGeometry.*`): Fit / Fill / Stretch transforms, inverse mapping for input, visible-region calculation | **Implemented; host unit tests pass in CI** (gcc/clang, Linux/macOS, with sanitizers). Plain C99, no UIKit. Not yet integrated with UIKit or tested on iOS. |
| Process/config policy (`Sources/UNPolicy.*`): eligibility, global + per-app opt-in, mode selection | **Implemented; host unit tests pass in CI.** Not run on a device. |
| Theos skeleton (`Tweak.x`, `Makefile`, `control`, `Unified.plist`) | **Builds in CI as one universal package** (armv7 iOS 5.0+, arm64 iOS 7.0+, both checked automatically). **Installs via Cydia** on iPad mini 1st gen, iOS 8.4.1 (owner report). Loading into apps not yet observed. Reads settings and logs one line in explicitly enabled apps. No hooks; changes nothing. |
| Settings pane (`prefs/`, `Settings > Unified`) | **Implemented, builds in CI. On the first device (0.0.2) the Settings row did not appear; cause under investigation** (see [Testing](docs/TESTING.md#troubleshooting-no-unified-row-in-settings)). Global switch, default mode, an app list grouped by iPhone/iPad/universal, and a per-app switch and mode. Needs PreferenceLoader. Uses private APIs listed in [docs/PRIVATE_APIS.md](docs/PRIVATE_APIS.md). |
| Settings model (`Sources/UNPreferences.*`) | **Implemented; host tests pass on macOS in CI** (with and without sanitizers). Shared by the tweak and the pane. |
| Classic-mode scaling (`Tweak.x`): iPhone apps on iPad drawn with Fit/Fill/Stretch instead of 1×/2×, touches mapped through the inverse | **Experimental, built, not yet run on a device.** iOS 8+ only, portrait only. Writes a diagnostics report viewable in Settings. See [Technical design §2a](docs/TECHNICAL_DESIGN.md). |
| iPad apps on iPhone | **Not started.** iOS refuses to install them; needs separate research. |
| Upscaling, HD texture packs | **Planned** (ROADMAP Phases 3a and 3b). Not started. |

Known geometry limitations: axis-aligned scale + translation only (no rotation; orientation must be resolved before rectangles are passed in), content is always centred, no pixel rounding, and touches exactly on a content edge may be classified either side due to floating-point rounding.

The first milestone is a small proof of concept on one chosen legacy iOS version and jailbreak environment. It should demonstrate one scaling direction, correct touch mapping, and a safe way to disable the tweak before expanding scope.

## Disclaimer

Unified is an experimental third-party jailbreak project. Jailbreaking and runtime modification can cause instability, data loss, or boot problems. Test on a restorable device, keep backups, and do not install builds you do not trust. No affiliation with or endorsement by Apple is implied.
