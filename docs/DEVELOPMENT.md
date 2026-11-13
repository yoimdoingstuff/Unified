# Development Setup

## Current state

This repository is documentation-first. A Theos project, Makefile, package metadata, and source tree have not yet been added.

## Toolchain direction

Planned tools:
- macOS or a supported Linux environment for Theos development.
- Theos build system.
- Logos for runtime hooks where appropriate.
- Objective-C for UIKit integration.
- An SDK compatible with the selected legacy deployment target.

The exact host setup and dependencies depend on the jailbreak and iOS version. Do not assume a modern SDK can target every legacy device.

## Setup checklist

1. Choose the first device, iOS version, and jailbreak.
2. Check its supported injection mechanism and package format.
3. Install Theos using its official documentation.
4. Install an SDK and compiler toolchain compatible with the target architecture.
5. Confirm a minimal sample tweak builds before adding Unified hooks.
6. Record exact tool versions and commands here.

## Proposed future layout

    Unified/
    ├── AGENTS.md
    ├── Makefile
    ├── control
    ├── Tweak.x
    ├── Sources/
    │   ├── UNConfiguration.*
    │   ├── UNGeometry.*
    │   ├── UNCompatibilityPolicy.*
    │   └── UNDiagnostics.*
    ├── Resources/
    ├── docs/
    └── tests/

## Build and install

No build or install command is published yet because the Theos project and target package format do not exist. Add exact commands once implemented and verify them on a clean environment.

Do not install experimental builds on a primary device without a backup and known recovery method.
