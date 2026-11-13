# Testing Strategy

## Principles

A successful build does not prove runtime scaling works. Test visual geometry, interaction, lifecycle, and stability.

## Geometry unit tests

Test Fit, Fill, and Stretch independently from UIKit:
- Portrait and landscape source/destination rectangles.
- Equal and extreme aspect ratios.
- Non-zero rectangle origins.
- Invalid or zero-sized input.
- Expected scale and translation.
- Forward/inverse transform round trips.

## Runtime matrix

| Area | Checks |
| --- | --- |
| Launch | Cold launch, warm launch, relaunch |
| Display | Fit, Fill, Stretch; clipping and alignment |
| Input | Corner taps, centre tap, swipes, gestures |
| Scrolling | Vertical, horizontal, nested scroll views |
| Layout | Rotation, safe areas, bars, modal views |
| Text | Keyboard, text entry, selection, alerts |
| Lifecycle | Background, foreground, termination |
| Stability | Repeated launch, memory, crash logs |
| Isolation | Unselected apps and system UI unchanged |
| Recovery | Disable tweak, remove package, reboot |

## Test record template

    Date:
    Device model / architecture:
    iOS version and build:
    Jailbreak and version:
    Injection platform and version:
    Theos / SDK version:
    App and bundle identifier:
    App version:
    Scaling direction / mode:
    Build result:
    Launch result:
    Visual result:
    Touch / gesture result:
    Rotation result:
    Keyboard / modal result:
    Known issues:
    Logs / reproduction notes:

## Release gate

Do not mark a target supported until the package builds, loads only in intended processes, basic visual behaviour and touch mapping work, rotation and common presentations are checked, disable/uninstall paths are verified, and limitations are documented.
