# Development Setup

## Current state

What exists (nothing has run on a device yet):
- `Sources/UNGeometry.{h,c}`: plain C99 geometry engine. Host tests pass in CI.
- `Sources/UNPolicy.{h,c}`: plain C99 process eligibility and per-app enable/mode decision. Host tests pass in CI.
- `Tweak.x`, `Makefile`, `control`, `Unified.plist`: Phase 1 Theos skeleton. It logs one line in apps that are explicitly enabled and changes nothing. Builds in CI.
- `tests/`: host unit tests for both C modules.
- `Resources/example-preferences.plist`: a preferences file for testing by hand.

## Host unit tests

Requirements: any C99 compiler (`gcc` or `clang`) and `make`, on Linux or macOS. Windows users can use WSL or MSYS2.

    make -C tests
    make -C tests clean
    make -C tests EXTRA_CFLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all"

The `ci` GitHub Actions workflow (`.github/workflows/ci.yml`) has two jobs:
- `host-tests` runs the commands above with gcc and clang on Ubuntu and clang on macOS, with and without sanitizers. These cover the plain-C modules only and say nothing about runtime behaviour on iOS.
- `tweak-build` installs Theos, the L1ghtmann Linux iOS toolchain and the iPhoneOS 10.3 SDK on Ubuntu 22.04, then runs `make package`. It reports the package's architectures and minimum iOS versions as a public annotation, and uploads the `.deb` as the `unified-deb` artifact. A passing build is not a runtime test.

### Verified build toolchain

| Component | Version | Notes |
| --- | --- | --- |
| Host | GitHub Actions `ubuntu-22.04` | |
| Theos | `theos/theos` master, commit `8167f59` (2026-11-13) | CI clones master, so the commit can change; it is reported in each run's annotations. |
| Toolchain | L1ghtmann `iOSToolchain-x86_64`, clang 11.1.0 | Latest release at build time. |
| SDK | `theos/sdks` `iPhoneOS10.3.sdk` | Contains armv7 stubs. **`iPhoneOS9.3.sdk` does not link armv7:** its `libSystem.tbd` re-exports `liblaunch.dylib`, but `liblaunch.tbd` is missing from that SDK. |

First successful build: commit `87a2f5f`, armv7 only, deployment target 8.0. The universal armv7 + arm64 / iOS 5.0 configuration is being verified next.

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

- **One universal package.** There is a single `.deb` for every iOS version from 5 to 10, never one build per version. It contains one dylib with two slices:
  - `armv7`, deployment target iOS 5.0. This covers every 32-bit device; armv7s devices run armv7 code.
  - `arm64`, deployment target iOS 7.0 (the first 64-bit iOS).
  - Differences between iOS versions are handled at runtime (`respondsToSelector:`, `NSClassFromString`, version checks), not with build flags.
- **Toolchain:** recent Xcode releases no longer build 32-bit iOS code. The Theos Linux toolchain with the 10.3 SDK does (see above). `-Wunguarded-availability` is on, so any API newer than the deployment target used without a runtime check produces a warning.
- **Objective-C rules for shared code:**
  - Use only APIs available on iOS 5. Reach newer APIs through `respondsToSelector:` / `NSClassFromString` with an iOS 5 fallback, and comment which iOS version introduced each one.
  - Avoid object subscripting (`array[i]`, `dict[key]`). It relies on methods added in iOS 6 and needs a compatibility shim on iOS 5. Collection literals (`@[...]`, `@{...}`) are expected to be fine; confirm when the first build runs.
  - Do not use `UITraitCollection`, size classes, `nativeBounds`, or `topLayoutGuide` without a version check.
  - `CGFloat` is `float` on 32-bit and `double` on arm64. `UNGeometry` uses `double` internally; convert at the UIKit boundary.
- **Geometry engine:** `Sources/UNGeometry.c` uses only C99 and libm (`fmin`, `fmax`, `isfinite`), and compiles for armv7 in CI.

## Setup checklist (local builds)

CI already builds the package. To build locally instead:

1. Install Theos using its official documentation (macOS or Linux; on Windows use WSL).
2. On Linux, install the L1ghtmann iOS toolchain into `$THEOS/toolchain`, the same way `ci.yml` does.
3. Copy `iPhoneOS10.3.sdk` from `theos/sdks` into `$THEOS/sdks`.
4. Run `make package`.

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

## Build and install

    make package                                    # builds packages/*.deb (verified in CI)
    make package install THEOS_DEVICE_IP=<ipad-ip>  # needs OpenSSH on the iPad (unverified)

Or download the `unified-deb` artifact from a CI run (you need to be signed in to GitHub), copy the `.deb` to the iPad, and install it with Filza or `dpkg -i`. Installation has not been tried yet.

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
