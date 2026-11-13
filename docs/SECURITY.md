# Security and Privacy

Unified is intended to operate locally on a jailbroken device.

## Principles
- No network connection is required for the core feature.
- Do not collect analytics, usage telemetry, or app contents.
- Do not read app documents or credentials.
- Do not store device identifiers without a clearly justified need.
- Keep debug logs opt-in and avoid sensitive values.
- Store only configuration preferences.
- HD texture packs (planned) are untrusted input: read them only from Unified's own pack directory, enforce size and format limits before decoding, and never execute content from a pack. Do not distribute or commit proprietary app assets.
- Do not weaken iOS security controls beyond what the jailbreak environment already requires.

## Runtime safety
- Load only into explicitly supported application processes.
- Default to disabled when configuration is missing or invalid.
- Provide a reliable disable path.
- Avoid modifying SpringBoard or system processes by default.
- Avoid private APIs where public alternatives are sufficient.
- Document required private APIs and stability risks.

## User warning

Jailbreak tweaks execute code inside other processes and can crash apps or destabilize devices. Users should keep backups and understand how to disable or remove the package before installing experimental builds.

Do not publish exploit details or sensitive device logs in public issue reports. Remove identifiers, tokens, and account information before sharing logs.
