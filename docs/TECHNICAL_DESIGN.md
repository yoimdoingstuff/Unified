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

A future preference model may contain global enabled state, default mode, per-app enabled state, per-app mode override, and optional per-app compatibility flags.

Use stable bundle identifiers. Missing, malformed, or unreadable configuration should default to disabled.

## 7. Open questions
- Which legacy iOS versions will be supported first?
- Which jailbreak injection libraries are in scope?
- What is the earliest reliable integration point for app content geometry?
- How should multiple app windows be handled?
- Which architectures must packages support?
