# Development Setup

## Current state

What exists (none of it built yet):
- `Sources/UNGeometry.{h,c}`: plain C99 geometry engine.
- `Sources/UNPolicy.{h,c}`: plain C99 process eligibility and per-app enable/mode decision.
- `Tweak.x`, `Makefile`, `control`, `Unified.plist`: Phase 1 Theos skeleton. It logs one line in apps that are explicitly enabled and changes nothing.
- `tests/`: host unit tests for both C modules.
- `Resources/example-preferences.plist`: a preferences file for testing by hand.

## Host unit tests

Requirements: any C99 compiler (`gcc` or `clang`) and `make`, on Linux or macOS. Windows users can use WSL or MSYS2.

    make -C tests
    make -C tests clean
    make -C tests EXTRA_CFLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all"

The `ci` GitHub Actions workflow (`.github/workflows/ci.yml`) has two jobs:
- `host-tests` runs the commands above with gcc and clang on Ubuntu and clang on macOS, with and without sanitizers. These cover the plain-C modules only and say nothing about runtime behaviour on iOS.
- `tweak-build` installs Theos, the L1ghtmann Linux iOS toolchain and the iPhoneOS 9.3 SDK on Ubuntu 22.04, then runs `make package`. The `.deb` is uploaded as the `unified-deb` artifact. A passing build is not a runtime test.

`tests/Makefile` is deliberately separate from the Theos root `Makefile` so host tests never need the iOS SDK.

## Toolchain direction

Planned tools:
- macOS or a supported Linux environment for Theos development.
- Theos build system.
- Logos for runtime hooks where appropriate.
- Objective-C for UIKit integration.
- An SDK compatible with the selected legacy deployment target.

The exact host setup and dependencies depend on the jailbreak and iOS version. Do not assume a modern SDK can target every legacy device.

## Constraints from the iOS 5–10 target

See [Compatibility](COMPATIBILITY.md) for the device and API table.

- **Architectures:** armv7 for iOS 5–6 and older devices, arm64 for iOS 7+. The arm64 slice cannot have a deployment target below iOS 7.
- **Toolchain:** recent Xcode releases no longer build 32-bit iOS code. The tweak needs a toolchain/SDK combination that still emits armv7 with an iOS 5.0 deployment target. Which one is not yet decided; record the exact versions here once a sample tweak builds.
- **Objective-C rules for shared code:**
  - Use only APIs available on iOS 5. Reach newer APIs through `respondsToSelector:` / `NSClassFromString` with an iOS 5 fallback, and comment which iOS version introduced each one.
  - Avoid object subscripting (`array[i]`, `dict[key]`). It relies on methods added in iOS 6 and needs a compatibility shim on iOS 5. Collection literals (`@[...]`, `@{...}`) are expected to be fine; confirm when the first build runs.
  - Do not use `UITraitCollection`, size classes, `nativeBounds`, or `topLayoutGuide` without a version check.
  - `CGFloat` is `float` on 32-bit and `double` on arm64. `UNGeometry` uses `double` internally; convert at the UIKit boundary.
- **Geometry engine:** `Sources/UNGeometry.c` uses only C99 and libm (`fmin`, `fmax`, `isfinite`). It should build for every architecture in range, but no iOS build has been run yet.

## Setup checklist

1. ~~Choose the first device, iOS version, and jailbreak.~~ iPad mini 1st gen, iOS 8.4.1, EverPwnage.
2. Install Theos using its official documentation (macOS or Linux; on Windows use WSL).
3. Install an iOS SDK that still contains armv7 stubs into `$THEOS/sdks`.
4. Run `make package` and fix whatever the first build reports.
5. Record the exact host OS, Theos commit, toolchain, and SDK versions here.

## Layout

    Unified/
    ├── Makefile               Theos build (tweak)
    ├── control                Package metadata
    ├── Unified.plist          Substrate filter: loads into UIKit processes
    ├── Tweak.x                Entry point (%ctor), reads preferences
    ├── Sources/
    │   ├── UNGeometry.*       Fit / Fill / Stretch, inverse mapping
    │   └── UNPolicy.*         Eligibility and enable/mode decision
    ├── Resources/             Example preferences
    ├── docs/
    └── tests/                 Host unit tests (separate Makefile)

## Build and install (unverified)

These commands follow standard Theos usage. They have **not** been run against this project yet.

    make package                                  # builds packages/*.deb
    make package TARGET=iphone:clang:9.3:8.0      # pin an SDK if "latest" lacks armv7
    make package install THEOS_DEVICE_IP=<ipad-ip>  # needs OpenSSH on the iPad

Or copy the `.deb` to the iPad and install it with Filza or `dpkg -i`.

## Turning it on for one app

There is no Settings pane yet. Copy `Resources/example-preferences.plist` to `/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist` on the iPad and replace `com.example.someapp` with the target app's bundle ID. Format:

| Key | Type | Meaning |
| --- | --- | --- |
| `Enabled` | Boolean | Global switch. Anything other than `true` means off. |
| `DefaultMode` | String | `fit`, `fill` or `stretch`. Invalid or missing means `fit`. |
| `Apps` → *bundle ID* → `Enabled` | Boolean | Per-app switch. Required; there is no "all apps" option. |
| `Apps` → *bundle ID* → `Mode` | String | Overrides `DefaultMode` for that app. |

## Turning it off / recovery

In order of preference:
1. Set `Enabled` to `false`, or delete the preferences file, then relaunch the app.
2. Uninstall the package (Cydia, or `dpkg -r com.yoimdoingstuff.unified`).
3. Substrate safe mode, if the device misbehaves at boot.

Unified never acts in SpringBoard or the Settings app (enforced in `UNPolicy.c`). It does load into every UIKit process, because of the `com.apple.UIKit` filter, but returns immediately where it isn't enabled.

Do not install experimental builds on a primary device without a backup and known recovery method.
