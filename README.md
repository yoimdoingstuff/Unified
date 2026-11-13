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
- Support legacy jailbreak injection environments where practical.

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

The minimum iOS version, jailbreak targets, and injection platforms have not yet been selected. See [Compatibility](docs/COMPATIBILITY.md).

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
- [Agent instructions](AGENTS.md)
- [Contributing](CONTRIBUTING.md)

## Current status

**Planning / research.** Implementation has not started.

The first milestone is a small proof of concept on one chosen legacy iOS version and jailbreak environment. It should demonstrate one scaling direction, correct touch mapping, and a safe way to disable the tweak before expanding scope.

## Disclaimer

Unified is an experimental third-party jailbreak project. Jailbreaking and runtime modification can cause instability, data loss, or boot problems. Test on a restorable device, keep backups, and do not install builds you do not trust. No affiliation with or endorsement by Apple is implied.
