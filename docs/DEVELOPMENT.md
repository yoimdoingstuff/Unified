# Development Setup

## Current state

What exists (the package installs on the test iPad; nothing has been observed running yet):
- `Sources/UNGeometry.{h,c}`: plain C99 geometry engine. Host tests pass in CI.
- `Sources/UNPolicy.{h,c}`: plain C99 process eligibility and per-app enable/mode decision. Host tests pass in CI.
- `Sources/UNPreferences.{h,m}`: reads and writes the settings file. Shared by the tweak and the Settings pane. Host-tested on macOS.
- `Sources/UNAppCatalog.{h,m}`: installed-app list for the pane (private APIs, see [PRIVATE_APIS.md](PRIVATE_APIS.md)).
- `Tweak.x`, `Makefile`, `control`, `Unified.plist`: Phase 1 Theos skeleton. It logs one line in apps that are explicitly enabled and changes nothing. Builds in CI.
- `prefs/`: the `Settings > Unified` pane (Theos bundle subproject, loaded by PreferenceLoader). The PreferenceLoader entry plist is in `layout/Library/PreferenceLoader/Preferences/`.
- `tests/`: host unit tests (C on Linux and macOS; Objective-C on macOS only).
- `Resources/example-preferences.plist`: a preferences file for testing by hand, without the pane.

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

Build history:
- `87a2f5f`: first successful build, armv7 only, deployment target 8.0.
- `e713149`: first universal build. One gzip-compressed `.deb` (10 KB) containing `Library/MobileSubstrate/DynamicLibraries/Unified.{dylib,plist}`, with the dylib holding armv7 + arm64 slices. Both slices were stamped with a minimum of iOS 5.0.
- `f4fbde9`: build failed. Adding `-miphoneos-version-min=7.0` for arm64 conflicts with Theos's own `-target arm64-apple-ios5.0` (clang error `-Woverriding-t-option`).
- `c77d707`: the Makefile switched to Theos's per-architecture variables (`TARGET_OS_DEPLOYMENT_VERSION` = 5.0, `TARGET_OS_DEPLOYMENT_VERSION_arm64` = 7.0) and left the version out of `TARGET`, which would otherwise take precedence. The CI check still reported arm64 at 5.0, but that was a misreading by `llvm-objdump --arch-name`.
- `8304012`: **universal package verified in CI.** clang received `-target armv7-apple-ios5.0` and `-target arm64-apple-ios7.0`. `tools/macho_minos.py` reads the final dylib's slices directly as armv7 5.0 and arm64 7.0. CI's "Check universal package" step now uses that script and fails unless those values match.
- The linker warns `building for iOS 5.0.0 is deprecated`. That is expected and harmless.

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
    │   ├── UNPolicy.*         Eligibility and enable/mode decision
    │   ├── UNPreferences.*    Settings file read/write (tweak + pane)
    │   └── UNAppCatalog.*     Installed-app list for the pane
    ├── prefs/                 Settings > Unified (PreferenceLoader bundle)
    ├── layout/                Files copied into the package as-is
    ├── Resources/             Example preferences
    ├── tools/                 Build helpers (macho_minos.py: per-slice min iOS)
    ├── docs/
    └── tests/                 Host unit tests (separate Makefile)

## Build and install

    make package                                    # builds packages/*.deb (verified in CI)
    make package install THEOS_DEVICE_IP=<ipad-ip>  # needs OpenSSH on the iPad (unverified)

Or download the `unified-deb` artifact from a CI run (you need to be signed in to GitHub), copy the `.deb` to the iPad, and install it with Filza or `dpkg -i`. Installation has not been tried yet.

## Turning it on for one app

Use `Settings > Unified` (needs PreferenceLoader). Without the pane, copy `Resources/example-preferences.plist` to `/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist` and replace `com.example.someapp` with the target app's bundle ID. Both write the same format, handled by `Sources/UNPreferences.m`:

| Key | Type | Meaning |
| --- | --- | --- |
| `Enabled` | Boolean | Global switch. Anything other than `true` means off. |
| `DefaultMode` | String | `fit`, `fill` or `stretch`. Invalid or missing means `fit`. |
| `Apps` → *bundle ID* → `Enabled` | Boolean | Per-app switch. Required; there is no "all apps" option. |
| `Apps` → *bundle ID* → `Mode` | String | Overrides `DefaultMode` for that app. |

## Turning it off / recovery

In order of preference:
1. Switch off `Settings > Unified > Enabled` (or the app's own switch), then close and reopen the app. Without the pane: set `Enabled` to `false` in the file, or delete it.
2. Uninstall the package (Cydia, or `dpkg -r com.yoimdoingstuff.unified`).
3. Substrate safe mode, if the device misbehaves at boot.

Unified never acts in SpringBoard or the Settings app (enforced in `UNPolicy.c`). It does load into every UIKit process, because of the `com.apple.UIKit` filter, but returns immediately where it isn't enabled.

Do not install experimental builds on a primary device without a backup and known recovery method.
