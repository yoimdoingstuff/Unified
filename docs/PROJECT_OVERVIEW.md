# Project Overview

## What Unified is

Unified is a planned jailbreak tweak intended to make apps designed for one iOS device class usable on another:
- iPhone-oriented apps displayed on iPads.
- iPad-oriented apps displayed on iPhones.

The initial goal is to adapt an existing interface, not rewrite the application.

## User-facing concept

Users should be able to enable Unified and configure individual apps. Initial modes:

- **Fit:** preserve aspect ratio and show all content; unused space may remain.
- **Fill:** preserve aspect ratio and fill the destination; some content may be cropped.
- **Stretch:** fill the destination without preserving aspect ratio.

## What Unified is not

- It is not an app recompilation or porting tool.
- It cannot guarantee a fully native iPad interface from an iPhone-only app.
- It cannot guarantee dense iPad controls will be comfortable on an iPhone.
- It cannot add missing hardware capabilities, assets, or app features.
- It should not alter unrelated system processes.

## Success criteria

1. Work on a clearly defined legacy iOS and jailbreak target.
2. Adapt app content without unexpectedly changing system UI.
3. Preserve touch and gesture behaviour.
4. Handle rotation and safe areas.
5. Allow global and per-app disable.
6. Identify apps needing special compatibility handling.
