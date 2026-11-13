# Compatibility

## Current status

No iOS version, device, jailbreak, injection platform, or app has been runtime-verified. Compatibility must be established by testing.

## Target matrix

| iOS version | Device / architecture | Jailbreak | Injection platform | Build | Runtime |
| --- | --- | --- | --- | --- | --- |
| Not selected | Not selected | Not selected | Not selected | Not tested | Not tested |

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
