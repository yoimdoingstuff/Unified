# Technical Design Notes

This document records implementation questions and constraints. It does not claim that unverified hooks are guaranteed solutions.

## 1. Geometry model

Let source content bounds be (xs, ys, ws, hs) and destination bounds be (xd, yd, wd, hd).

    scaleFit  = min(wd / ws, hd / hs)
    scaleFill = max(wd / ws, hd / hs)

For Stretch:

    scaleX = wd / ws
    scaleY = hd / hs

The transform also needs translation to align the scaled source rectangle with the destination rectangle. Fit shows all source content and may leave unused space. Fill covers the destination and may crop source content. Stretch fills the destination but changes aspect ratio.

Use actual content bounds, not blindly the physical screen dimensions. Safe areas, bars, and system-owned regions matter.

### Implementation (`Sources/UNGeometry.*`)

- Transform form: `x' = x·scaleX + translateX`, `y' = y·scaleY + translateY`, equal to `CGAffineTransformMake(scaleX, 0, 0, scaleY, translateX, translateY)`.
- Translation centres the source on the destination in every mode: `t = centre(dst) − centre(src)·s`.
- Doubles throughout; the UIKit layer converts to/from `CGFloat` (float on 32-bit ARM).
- Invalid input (non-finite values, zero/negative sizes, unknown mode, scale overflow/underflow) returns `false` with an identity output. Callers must treat `false` as "do not adapt", never as a valid identity transform.
- Input mapping (`UNTransformMapDestinationPointToSource`) returns the mapped point and whether it lies inside source content (edges inclusive). It never clamps; the touch policy for letterbox areas belongs to the integration layer.
- Not handled here: rotation/orientation, pixel rounding, non-centred alignment, multiple windows.

## 2. Coordinate spaces and input

Rendering and input must be treated as a pair. If source-to-destination mapping uses affine transform T, input in destination space must be converted using inverse transform T⁻¹ before the app handles it.

Test:
- Taps near all four corners.
- Swipes in both axes.
- Nested scroll views.
- Long press and gesture recognizers.
- Keyboard and text input.
- Modal presentation and dismissal.
- Rotation while active.

A visual transform without correct input mapping is not a working implementation.

## 2a. Classic-mode scaling (implemented, experimental, untested on device)

**Research (class-dump headers, iOS 5.0–8.1):** iPhone apps on iPad run in *classic* mode. SpringBoard decides whether an app is classic (`SBApplication -isClassic` on iOS 6/7, `-_classicMode` from `-_classicModeFromSupportedTypes` on iOS 8.1), but the 1×/2× presentation happens **inside the app's own UIKit**:
- Every `UIWindow` has a private `_transformLayer` (iOS 5.1–8.1).
- `-_updateTransformLayerForClassicPresentation` configures it for the zoom level; iOS 8.1 adds `-_updateTransformLayerSizeForClassicPresentation`.
- `UIClassicController` owns the 1×/2× button and black surround (its own window).
- iOS 8 converts between window and screen ("scene reference space") with `-_convertPointFromSceneReferenceSpace:` and related methods.

**Design (`Tweak.x`):**
1. Hook both update methods. After UIKit runs, if the app is classic and the layer tree is as expected (window layer directly inside `_transformLayer`, transform layer at scene coordinates, UIKit's transform unrotated), compute the target mapping with `UNTransformMake(window.bounds → _sceneReferenceBounds, mode)`.
2. Turn that mapping into a layer transform with `UNSolveRootLayerTransform`: Core Animation draws q at `position + T(q − anchor)`, so `T.translate = target.translate − position − scale·(contentOrigin − anchor)`. This is host-tested by simulating that formula.
3. Hook the scene-reference conversions so screen↔window conversions (expected to include touches) use exactly the same mapping and its inverse.
4. Anything unexpected leaves UIKit's transform in place and records why.

**Known limits of this first version:** iOS 8+ only (the conversion methods don't exist earlier); portrait only (rotated transforms are skipped); the 1×/2× button may overlap scaled content; Fill crops without any way to pan; touch mapping through these methods is an assumption to verify on the device.

## 3. UIKit behaviour

Investigate on the selected target:
- UIScreen bounds and native bounds.
- UIWindow and root view controller sizing.
- UIView layout and coordinate conversion.
- Trait collections, size classes, and idiom-dependent branching.
- Safe-area insets and status/navigation bars.
- Orientation and lifecycle differences between iOS releases.

Verify API availability on the chosen legacy OS before relying on it.

## 4. Core Animation

A layer transform may be useful for an early rendering experiment, but can cause issues with hit testing, clipping, masks, shadows, rasterization, keyboard and alert windows, system transitions, and text alignment. Do not assume one root-layer transform affects every relevant window or presentation.

## 5. Device idiom and app assumptions

Apps may branch on idiom, screen dimensions, size classes, or hardcoded constants. Spoofing one property can create inconsistent state if other APIs report the real device.

Treat identity overrides as a separate compatibility layer. Apply only to selected apps after documenting the checks they perform. Avoid global spoofing.

## 6. Configuration proposal

Implemented (Phase 1, unbuilt): a plist at `/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist` with global `Enabled`, `DefaultMode`, and `Apps.<bundle id>.{Enabled, Mode}`. The format is in [Development](DEVELOPMENT.md). Per-app compatibility flags come later.

- `Tweak.x` reads the file and type-checks each value. A wrong type is treated as missing.
- `UNPolicy.c` makes the decision in plain C: adapt only if global **and** per-app `Enabled` are true; mode precedence is app, then default, then Fit.
- SpringBoard, Settings, app extensions and non-`.app` processes are never eligible.
- The file is read directly rather than through `CFPreferences`, because cfprefsd behaviour differs across iOS 5–10. Whether a sandboxed app on iOS 8.4.1 may read this path is **unverified**. If it can't, Unified stays off, which is safe but would need a different storage location.

Use stable bundle identifiers. Missing, malformed, or unreadable configuration defaults to disabled.

## 6a. Upscaling (planned)

Scaling a 320×480-point iPhone interface onto a 1024×768 1x iPad means about 2.13× magnification of pixels that were drawn at 1x, which looks blurry. Upscaling raises the resolution content is *drawn* at, instead of stretching pixels afterwards.

- **Render scale:** set a higher `contentsScale` on layers (`contentScaleFactor` on views) so text, paths and Core Graphics drawing are rasterised at about the final on-screen size. Public API on iOS 4+; how it interacts with the rendering hook is still to be investigated.
- **Filters:** `CALayer` `magnificationFilter` / `minificationFilter` (nearest, linear, trilinear). Public API.
- **Limits:** this cannot add detail to bitmap images (see texture packs), and may not affect OpenGL ES layers, video or system-rendered windows. Memory grows roughly with the square of render scale, which matters on 512 MB devices.
- Expected private API use: none so far. Record any that becomes necessary.

## 6b. HD texture packs (planned)

- Packs are user-supplied files under a Unified-owned directory, keyed by bundle ID and app version. Unified never reads app data outside its own pack directory and the app's own image lookups.
- Replacement happens at the `UIImage` loading level. A replacement is returned at the original point size with a higher `scale`, so `UIImage.size` and layout stay unchanged.
- Validation before use: same aspect ratio as the original within a small tolerance, bounded pixel dimensions and file size, decodable format. Any failure falls back to the original image.
- Images decoded from packs are untrusted input. Keep decoding on system image APIs, enforce size limits, and never execute anything from a pack.
- Asset catalogs and direct OpenGL ES texture uploads are open research; neither is promised.

## 7. Target-range consequences (iOS 5–10)

- **Normalise screen geometry per version.** Before iOS 8 `UIScreen.bounds` is always portrait; from iOS 8 it follows interface orientation. The integration layer must convert both cases into the source/destination rects `UNGeometry` expects, so the geometry code stays version-agnostic.
- **Layout systems differ.** iOS 5 has no Auto Layout, and size classes arrive in iOS 8. Expect apps built for iOS 5–7 to relayout less predictably than iOS 8+ apps after a size change.
- **System compatibility scaling already exists** for iPhone apps on iPad and for apps without launch assets for newer iPhone sizes. Find out where it is applied before choosing Unified's rendering hook.
- **Installing iPad-only apps on iPhones** is blocked before the app process exists. That direction may need a separate, documented, opt-in mechanism.

## 8. Open questions
- First proof-of-concept target decided: iPad mini 1st gen, iOS 8.4.1, EverPwnage. Device details still to confirm.
- Which jailbreak injection libraries are in scope for each version?
- Where does iOS apply iPhone-on-iPad compatibility scaling on each version, and can Unified replace it in-process?
- What is needed to install or launch an iPad-only app on an iPhone, and is it acceptable under the project rules?
- What is the earliest reliable integration point for app content geometry?
- How should multiple app windows be handled?
- Which architectures must packages support?
