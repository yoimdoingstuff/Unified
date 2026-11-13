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
    └── Diagnostics

## Responsibilities

**Injection entry point:** load only in supported app processes, identify the app, read configuration, and avoid SpringBoard by default.

**Configuration:** provide global enable state, default mode, and per-bundle overrides. Missing or invalid preferences must leave the app unmodified.

**Compatibility policy:** decide eligibility and adaptation policy. Device identity spoofing is separate and opt-in.

**Geometry engine:** calculate transforms between source and destination content rectangles. Keep it independent of UIKit where practical and unit test it.

**Rendering integration:** apply geometry at a verified point in the target OS lifecycle. The exact hook is an open research question. A Core Animation transform may help with a prototype but is not sufficient alone.

**Input mapping:** apply the inverse display transform to touch and gesture coordinates. Account for coordinate origins and orientation.

**Diagnostics:** opt-in, local, minimal logging without sensitive data.

## Principles
- Per-process and per-app scope.
- Reversible behaviour and safe defaults.
- Small, testable geometry functions.
- Explicit compatibility targets.
- No network requirement or analytics.
- No assumption that every app uses the same UIKit layout strategy.
