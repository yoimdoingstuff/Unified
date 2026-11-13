# Contributing

Thanks for your interest in Unified.

Unified is an experimental jailbreak tweak for adapting iPhone-oriented and iPad-oriented apps to different display sizes. At this early stage, careful research and reproducible testing are more useful than large speculative implementations.

## Before contributing
- Read [AGENTS.md](AGENTS.md), [Architecture](docs/ARCHITECTURE.md), and [Development](docs/DEVELOPMENT.md).
- Check [Roadmap](ROADMAP.md) and [TODO](TODO.md).
- Confirm the target iOS and jailbreak environment for any compatibility claim.

## Changes
- Keep pull requests focused.
- Explain the problem and intended behaviour.
- Include device, iOS version, jailbreak, injection platform, and app used for runtime testing.
- Include build output or test steps where relevant.
- Document limitations and private API use.
- Update roadmap and task status when project status changes.

## Testing

A successful compile is not proof of runtime behaviour. Check touch accuracy, scrolling, rotation, safe areas, keyboard, modal UI, and relaunch. Do not test experimental builds on a device that cannot be restored.

## Code style
- Use clear Objective-C names and small components.
- Keep geometry calculations independent of UIKit where practical.
- Avoid unexplained constants and app-specific hacks in shared code.
- Comment on non-obvious hooks and coordinate conversions.

## Security

Do not commit personal device logs containing identifiers, account details, tokens, or private information. Never commit signing keys, certificates, passwords, or jailbreak credentials.

## Issue reports

Include reproduction steps, expected and actual behaviour, device/OS details, jailbreak/injection details, and relevant crash logs with sensitive information removed.
