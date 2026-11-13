# Private APIs and Dependencies

AGENTS.md rule 7: every private API is listed here with why it is needed and what can go wrong.

## In apps (tweak, `Tweak.x`)

Hooks are installed only in apps switched on in Settings. Each use is guarded by `respondsToSelector:` or a nil check; if anything is missing, Unified leaves UIKit's behaviour unchanged and writes the reason to the diagnostics report.

| API | Why | Seen in headers for | Risk and fallback |
| --- | --- | --- | --- |
| `-[UIApplication _isClassic]` | Only scale apps that iOS runs in iPhone compatibility mode. | 8.1 (UIApplication) | Missing means not scaled. |
| `UIWindow` ivar `_transformLayer` | The layer UIKit uses to present classic apps 1×/2×; Unified replaces its transform. | 5.1, 6.1, 7.1, 8.1 | Read with `class_getInstanceVariable`; nil means not scaled. |
| `-[UIWindow _updateTransformLayerForClassicPresentation]`, `-_updateTransformLayerSizeForClassicPresentation` | **Hooked.** After UIKit configures the layer, Unified applies its own transform. | 5.1–8.1 (size variant: 8.1) | Hooking a missing selector is a no-op. Rotated or non-affine transforms are left alone. |
| `-[UIWindow _sceneReferenceBounds]` | Destination rectangle (the screen in points). | 8.1 | Required; missing means not scaled. |
| `-[UIWindow _convert{Point,DoublePoint,Rect,Offset}{From,To}SceneReferenceSpace:]` | **Hooked.** Screen ↔ window conversions; Unified answers with its exact transform and inverse so touches line up. | 8.1 | Assumed to be the path touches take on iOS 8. **Unverified**: the diagnostics count how often they are used. |
| `-[UIWindow _isClassicControllerWindow]` | Skip the window that draws the 1×/2× button and black surround. | 5.1 | If missing, all windows are considered. |

Header research used the class-dump collection at [F7eak/iOS-Headers](https://github.com/F7eak/iOS-Headers) (iOS 5.0–8.1). Nothing has been confirmed on iOS 9 or 10.

## In the Settings pane

| API / file | Used in | Why | iOS range expected | Risk and fallback |
| --- | --- | --- | --- | --- |
| **Preferences.framework** (`PSListController`, `PSSpecifier`, `PSListItemsController`) | `prefs/*.m` | The only way to add a page to the Settings app. Standard for jailbreak tweaks via PreferenceLoader. | 5–10 (long-standing API) | Only old, widely used methods: `preferenceSpecifierNamed:target:set:get:detail:cell:edit:`, `setProperty:forKey:`, `propertyForKey:`, `setValues:titles:`, `reloadSpecifiers`, `specifier`, and the `_specifiers` ivar. If one breaks, the pane fails to open; the tweak is unaffected. |
| **LSApplicationWorkspace / LSApplicationProxy** (MobileCoreServices) | `Sources/UNAppCatalog.m` | List installed App Store apps, names, device family, and data container (`dataContainerURL`, for the diagnostics report). | 7–10 | Reached through `NSClassFromString` and `respondsToSelector:` only; nothing is linked. Missing selectors fall back to reading the app's `Info.plist`, then to source 2 below. |
| **`/var/mobile/Library/Caches/com.apple.mobile.installation.plist`** | `Sources/UNAppCatalog.m` | App list on iOS 5–7, where LSApplicationWorkspace may be missing or incomplete. | 5–7 (removed in 8) | Read-only. If unreadable, the app list is empty and the pane says so. Apps that already have settings are still listed, so they can be switched off. |

## Package dependencies

| Package | Why |
| --- | --- |
| `mobilesubstrate` (Cydia Substrate, or a compatible replacement) | Loads the tweak into apps. Confirmed present on the first test device, because Cydia installed a package that depends on it. |
| `preferenceloader` | Shows `Settings > Unified`. Without it the tweak still works, but there is no pane. |

## Not used

No hooks into SpringBoard or backboardd. On iOS 8 SpringBoard decides *whether* an app runs in classic mode (`SBApplication -_classicMode`), but the presentation itself is done in the app's own UIKit, so Unified does not need SpringBoard for scaling.
