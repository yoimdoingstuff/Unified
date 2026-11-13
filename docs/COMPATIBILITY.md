# Compatibility

## Current status

No iOS version, device, jailbreak, injection platform, or app has been runtime-verified. Compatibility must be established by testing.

## Target range

**Goal: iOS 5.0 through iOS 10.x.** This is the intended support range, not a claim. Each version stays *Untested* until it has a test record.

The first proof of concept targets **one** version, device, and jailbreak from inside this range. Broaden only after it passes.

## First proof-of-concept target

| Item | Value | Confirmed on device? |
| --- | --- | --- |
| Device | iPad mini (1st generation), Wi-Fi + Cellular, 64 GB: A5, **armv7**, 1024×768 points at 1x (non-Retina), 512 MB RAM | Owner-reported. The cellular radio and storage size are not expected to matter |
| iOS | 8.4.1 | Owner-reported |
| Jailbreak | EverPwnage, untether from LukeZGD's repo | Owner-reported. Exact versions are not needed unless a jailbreak-specific problem appears |
| Injection platform | Cydia Substrate | Confirmed present: Cydia installed Unified 0.0.1~poc1, which depends on `mobilesubstrate`. That the tweak actually loads into apps is not yet observed |
| Scaling direction | iPhone app → iPad display (the only direction this device can test) | — |

Why this target is convenient:
- iOS 8.4.1 already has orientation-dependent `UIScreen.bounds`, `nativeBounds` and trait collections, but no iPad Split View (iOS 9). There is one full-screen window per app.
- The 1x screen makes the blur from iOS's own iPhone-app 2× mode obvious, which is a good baseline for the planned upscaling feature.
- 512 MB RAM is tight. Memory use from any higher render scale must be measured on this device.

What this target cannot show: iPad-only apps on iPhone, arm64 behaviour, Retina rendering, iOS 5–7 or 9–10 behaviour.

## Jailbreak independence

Design goal: Unified contains **no jailbreak-specific code**. It depends only on a Substrate-compatible hooking API (what Logos generates), standard file locations, and public or documented-private UIKit/Core Animation behaviour. This is what lets it work with any jailbreak that provides that API.

That is a design goal, not a compatibility claim. Only jailbreaks with a test record are listed as tested.

## Devices and architectures in range

| Architecture | Devices (examples) | iOS versions they can run within 5–10 |
| --- | --- | --- |
| armv7 | iPhone 3GS, 4, 4S; iPad 1, 2, 3, mini 1; iPod touch 3rd–5th gen | 5–9 (iPad 1, iPod 3rd gen: 5 only; iPhone 3GS, iPod 4th gen: up to 6; iPhone 4: up to 7; others: up to 9) |
| armv7s | iPhone 5, 5c; iPad 4 | 6–10 |
| arm64 | iPhone 5s and later; iPad Air, mini 2 and later; iPad Pro; iPod touch 6th gen | 7–10 (by device) |

Implications:
- iOS 5 and 6 are 32-bit only. arm64 binaries need a minimum deployment target of iOS 7.
- **Unified ships as one universal package** with armv7 (iOS 5.0+) and arm64 (iOS 7.0+) slices. armv7s is not built separately, because armv7 code runs on armv7s devices.
- Highest iOS per device should be confirmed against Apple's release history before a device is added to the matrix.

## Version differences that affect Unified

Research notes from public UIKit API history. Re-verify each one on the target OS before relying on it.

| Change | First iOS | Why it matters |
| --- | --- | --- |
| Auto Layout (`NSLayoutConstraint`) | 6 | iOS 5 apps use springs/struts or manual `layoutSubviews`; relayout after a size change is less predictable. |
| 4-inch iPhone screen (320×568) | 6 | Apps without a 4" launch image are letterboxed by the system. |
| Status bar overlays content; `topLayoutGuide` | 7 | Content inset assumptions change between iOS 6 and 7. |
| arm64 | 7 | See above. |
| `UIScreen.bounds` becomes orientation-dependent; `nativeBounds` added | 8 | Before iOS 8 bounds are always portrait. Geometry inputs must be normalised per version. |
| `UITraitCollection`, size classes | 8 | Idiom/size-class layout branching only exists from iOS 8. |
| iPhone 6/6 Plus sizes (375×667, 414×736), Display Zoom | 8 | Apps without matching launch assets are scaled by the system. |
| iPad Slide Over / Split View | 9 | An iPad app's window may not be full-screen. |
| Safe-area insets | 11 | **Outside range.** Do not use. |

System behaviour that overlaps Unified's job:
- **iPhone apps on iPad** already run in a system compatibility mode: a small iPhone-sized window with a 1×/2× zoom. Unified must either work with or replace that system scaling. Where it is implemented (SpringBoard, backboardd, or UIKit in-process) is an open research question and may affect the "no system process" rule in AGENTS.md.
- **iPad-only apps on iPhone** are normally refused at install time (device family check). Getting one installed or launched may need changes outside the app process. Investigate before promising this direction.

## Injection platforms in range

Tweaks in this era generally load through Cydia Substrate (MobileSubstrate), or a Substrate-compatible replacement on some iOS 10 jailbreaks. The exact injection library per jailbreak must be confirmed and recorded. Logos output that uses the Substrate API is the expected starting point.

## Target matrix

| iOS version | Device / architecture | Jailbreak | Injection platform | Build | Runtime |
| --- | --- | --- | --- | --- | --- |
| 5.x | armv7 | Not selected | Not selected | Not tested | Not tested |
| 6.x | armv7 / armv7s | Not selected | Not selected | Not tested | Not tested |
| 7.x | armv7 / armv7s / arm64 | Not selected | Not selected | Not tested | Not tested |
| **8.4.1 (first PoC)** | iPad mini 1st gen, armv7 | EverPwnage | Cydia Substrate (present: Cydia installed a package depending on it) | Build-tested (CI) | Install-tested: 0.0.1~poc1 installs via Cydia. Loading into apps not observed. |
| 8.x (other) | armv7 / armv7s / arm64 | Not selected | Not selected | Not tested | Not tested |
| 9.x | armv7 / armv7s / arm64 | Not selected | Not selected | Not tested | Not tested |
| 10.x | armv7s / arm64 | Not selected | Not selected | Not tested | Not tested |

## App compatibility categories

**Good early candidates:** simple UIKit apps with one main window and flexible Auto Layout constraints.

**Higher-risk apps:** fixed-dimension interfaces; apps branching on idiom or size classes; apps with multiple windows; custom OpenGL ES, Metal, or video surfaces; games with custom touch coordinate systems; complex keyboard, modal, popover, or external display behaviour; apps relying on private APIs.

These are risk categories, not confirmed compatibility results.

## Legacy iOS considerations

Legacy releases differ in UIKit APIs, app lifecycle, architecture support, and jailbreak injection environments. Do not copy a modern tweak's deployment target or dependency assumptions without checking the actual target.

Record exact iOS version/build, device model/architecture, jailbreak/version, injection library/version, Theos/SDK version, app/bundle ID/version, scaling direction/mode, and results for touch, rotation, keyboard, safe areas, and relaunch.

## Compatibility labels
- **Untested:** no runtime test.
- **Build-tested:** compiles, runtime unverified.
- **Basic-tested:** launches and basic display behaviour works.
- **Interaction-tested:** touch, gestures, and scrolling verified.
- **Regression-tested:** orientation, keyboard, modal UI, and relaunch checked.
- **Unsupported:** known not to work or intentionally excluded.

Never describe an entire iOS release as supported based on one successful app.
