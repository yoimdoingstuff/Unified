# Architecture

This is the intended separation of responsibilities, not an existing implementation.

## Proposed components

    Unified
    ├── Injection entry point
    │   ├── Process / bundle identification
    │   └── Target-process eligibility
    ├── Configuration
    │   ├── Global defaults
    │   ├── Per-app overrides
    │   └── Safe disable state
    ├── Compatibility policy
    │   ├── App/device direction
    │   ├── Optional idiom policy
    │   └── App-specific exceptions
    ├── Geometry engine
    │   ├── Source and destination content bounds
    │   ├── Fit / Fill / Stretch calculations
    │   └── Transform and inverse transform
    ├── UIKit / rendering integration
    │   └── Render quality (upscaling: render scale, filters)   [planned]
    ├── Asset replacement (HD texture packs)                  [planned]
    │   ├── Pack discovery and manifest validation
    │   └── Image load interception
    └── Diagnostics

## Responsibilities

**Injection entry point:** load only in supported app processes, identify the app, read configuration, and avoid SpringBoard by default.

**Configuration:** provide global enable state, default mode, and per-bundle overrides. Missing or invalid preferences must leave the app unmodified.

**Compatibility policy:** decide eligibility and adaptation policy. Device identity spoofing is separate and opt-in.

**Geometry engine:** calculate transforms between source and destination content rectangles. Keep it independent of UIKit where practical and unit test it.

**Rendering integration:** apply geometry at a verified point in the target OS lifecycle. The exact hook is an open research question. A Core Animation transform may help with a prototype but is not sufficient alone.

**Input mapping:** apply the inverse display transform to touch and gesture coordinates. Account for coordinate origins and orientation.

**Render quality (planned):** choose the internal render scale and scaling filters for adapted content. Uses the geometry engine's scale; must never change layout or input mapping.

**Asset replacement (planned):** find a user-supplied pack for the current bundle ID and app version, validate it, and substitute higher-resolution images at the original point size. Off unless a pack exists *and* the app has it enabled. Separate from geometry, so it can be disabled on its own.

**Diagnostics:** opt-in, local, minimal logging without sensitive data.

## Principles
- Per-process and per-app scope.
- Reversible behaviour and safe defaults.
- Small, testable geometry functions.
- Explicit compatibility targets.
- No network requirement or analytics.
- No assumption that every app uses the same UIKit layout strategy.
