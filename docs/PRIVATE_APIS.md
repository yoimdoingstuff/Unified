# Private APIs and Dependencies

AGENTS.md rule 7: every private API is listed here with why it is needed and what can go wrong. All are used from the **Settings pane only** (Preferences.app). The tweak that loads into apps uses none so far.

| API / file | Used in | Why | iOS range expected | Risk and fallback |
| --- | --- | --- | --- | --- |
| **Preferences.framework** (`PSListController`, `PSSpecifier`, `PSListItemsController`) | `prefs/*.m` | The only way to add a page to the Settings app. Standard for jailbreak tweaks via PreferenceLoader. | 5–10 (long-standing API) | Only old, widely used methods: `preferenceSpecifierNamed:target:set:get:detail:cell:edit:`, `setProperty:forKey:`, `propertyForKey:`, `setValues:titles:`, `reloadSpecifiers`, `specifier`, and the `_specifiers` ivar. If one breaks, the pane fails to open; the tweak is unaffected. |
| **LSApplicationWorkspace / LSApplicationProxy** (MobileCoreServices) | `Sources/UNAppCatalog.m` | List installed App Store apps, names, and device family for the app picker. | 7–10 | Reached through `NSClassFromString` and `respondsToSelector:` only; nothing is linked. Missing selectors fall back to reading the app's `Info.plist`, then to source 2 below. |
| **`/var/mobile/Library/Caches/com.apple.mobile.installation.plist`** | `Sources/UNAppCatalog.m` | App list on iOS 5–7, where LSApplicationWorkspace may be missing or incomplete. | 5–7 (removed in 8) | Read-only. If unreadable, the app list is empty and the pane says so. Apps that already have settings are still listed, so they can be switched off. |

## Package dependencies

| Package | Why |
| --- | --- |
| `mobilesubstrate` (Cydia Substrate, or a compatible replacement) | Loads the tweak into apps. Confirmed present on the first test device, because Cydia installed a package that depends on it. |
| `preferenceloader` | Shows `Settings > Unified`. Without it the tweak still works, but there is no pane. |

## Not used (yet)

No hooks into SpringBoard, backboardd, or app internals. Display adaptation (ROADMAP Phase 2) will need some; each one will be added to this table when it is introduced.
