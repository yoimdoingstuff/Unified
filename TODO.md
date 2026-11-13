# TODO

Keep this list synchronized with [ROADMAP.md](ROADMAP.md).

## Immediate priorities
- [ ] Decide initial iOS version.
- [ ] Decide initial device and CPU architecture.
- [ ] Decide jailbreak and injection target.
- [ ] Set up and verify Theos.
- [ ] Create a minimal Logos tweak that logs its process without modifying behaviour.
- [ ] Add geometry tests for Fit, Fill, and Stretch.
- [ ] Select a simple app for the first rendering experiment.

## Technical investigation
- [ ] Determine target OS screen and window bounds behaviour.
- [ ] Investigate UIKit trait collections and size classes.
- [ ] Investigate safe areas and status/navigation bars.
- [ ] Identify a viable rendering integration point.
- [ ] Determine inverse touch/gesture coordinate mapping.
- [ ] Test orientation changes and relaunch.
- [ ] Evaluate whether specific apps require idiom spoofing.
- [ ] Record private API dependencies and alternatives.

## Configuration
- [ ] Define bundle identifier matching.
- [ ] Define global defaults and per-app overrides.
- [ ] Define safe disable mechanism.
- [ ] Decide preference storage for target iOS.
- [ ] Design Settings UI after core behaviour is proven.

## Quality
- [ ] Add reproducible build instructions.
- [ ] Add device / OS / jailbreak test matrix.
- [ ] Add crash and regression test notes.
- [ ] Verify package install, upgrade, disable, and uninstall.
- [ ] Keep known limitations visible in README.
