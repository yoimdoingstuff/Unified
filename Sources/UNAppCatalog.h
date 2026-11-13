/*
 * UNAppCatalog - lists installed App Store apps for the Settings pane.
 *
 * Status: implemented; the family parser has host tests
 * (tests/test_preferences.m). The app listing itself uses private,
 * version-specific sources and has not run on a device yet.
 *
 * Sources, tried in order (see docs/PRIVATE_APIS.md):
 *   1. LSApplicationWorkspace / LSApplicationProxy (MobileCoreServices,
 *      private; iOS 7+). Reached through the runtime, never linked.
 *   2. /var/mobile/Library/Caches/com.apple.mobile.installation.plist
 *      (undocumented MobileInstallation cache; iOS 5-7).
 * If both fail the list is empty and the pane says so; settings for apps
 * already configured stay reachable.
 *
 * Foundation only, so the parser can be tested on a Mac.
 */

#import <Foundation/Foundation.h>

typedef enum {
    UNAppFamilyUnknown = 0,
    UNAppFamilyiPhone = 1,    /* iPhone/iPod only */
    UNAppFamilyiPad = 2,      /* iPad only */
    UNAppFamilyUniversal = 3  /* both */
} UNAppFamily;

/*
 * Interprets an Info.plist UIDeviceFamily value: a number, a numeric string,
 * or an array of either. 1 = iPhone/iPod, 2 = iPad; other values are ignored.
 * nil means the key is absent, which iOS treats as iPhone-only.
 */
UNAppFamily UNAppFamilyFromDeviceFamilyValue(id value);

/* "iPhone", "iPad", "iPhone and iPad", "unknown". */
NSString *UNAppFamilyDescription(UNAppFamily family);

@interface UNAppInfo : NSObject {
@private
    NSString *_bundleIdentifier;
    NSString *_displayName;
    UNAppFamily _family;
    NSString *_dataContainerPath;
}
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                             displayName:(NSString *)displayName
                                  family:(UNAppFamily)family;
- (NSString *)bundleIdentifier;
- (NSString *)displayName;
- (UNAppFamily)family;
/* The app's home directory (where its diagnostics report is), or nil. */
- (NSString *)dataContainerPath;
- (void)setDataContainerPath:(NSString *)path;
@end

@interface UNAppCatalog : NSObject
/* User-installed apps as UNAppInfo, sorted by display name. Never nil. */
+ (NSArray *)installedUserApplications;
@end
