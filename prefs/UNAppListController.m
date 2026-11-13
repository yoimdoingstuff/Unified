/*
 * Settings > Unified > Choose Apps.
 *
 * Lists installed App Store apps, grouped by which device they were made
 * for. On an iPad, iPhone-only apps come first (that is what Unified is
 * for); on an iPhone, iPad-only apps come first. Apps that already have
 * settings but are not in the list (uninstalled, or the list could not be
 * read) are shown too, so they can always be switched off.
 */

#import "UNPrefsCommon.h"
#import "UNAppCatalog.h"

@interface UNAppSettingsController : PSListController
@end

@interface UNAppListController : PSListController
@end

@implementation UNAppListController

- (PSSpecifier *)un_specifierForIdentifier:(NSString *)identifier
                                      name:(NSString *)name
                                    family:(UNAppFamily)family
{
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                            target:self
                                                               set:NULL
                                                               get:@selector(un_statusForSpecifier:)
                                                            detail:[UNAppSettingsController class]
                                                              cell:PSLinkCell
                                                              edit:Nil];
    [specifier setProperty:identifier forKey:UNSpecifierBundleIdentifier];
    [specifier setProperty:name forKey:UNSpecifierDisplayName];
    [specifier setProperty:[NSNumber numberWithInt:(int)family] forKey:UNSpecifierFamily];
    return specifier;
}

- (NSMutableArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        NSMutableArray *primary = [NSMutableArray array];
        NSMutableArray *other = [NSMutableArray array];
        NSMutableArray *unlisted = [NSMutableArray array];
        NSMutableSet *listedIdentifiers = [NSMutableSet set];
        NSArray *apps = [UNAppCatalog installedUserApplications];
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        UNAppFamily primaryFamily = isPad ? UNAppFamilyiPhone : UNAppFamilyiPad;

        [self setTitle:@"Apps"];

        for (UNAppInfo *app in apps) {
            PSSpecifier *specifier = [self un_specifierForIdentifier:[app bundleIdentifier]
                                                                name:[app displayName]
                                                              family:[app family]];
            [listedIdentifiers addObject:[app bundleIdentifier]];
            if ([app family] == primaryFamily) {
                [primary addObject:specifier];
            } else {
                [other addObject:specifier];
            }
        }

        for (NSString *identifier in [UNLoadPreferences() configuredAppIdentifiers]) {
            if (![listedIdentifiers containsObject:identifier]) {
                [unlisted addObject:[self un_specifierForIdentifier:identifier
                                                                name:identifier
                                                              family:UNAppFamilyUnknown]];
            }
        }

        if (isPad) {
            [specifiers addObject:UNGroupSpecifier(@"iPhone apps",
                [primary count] > 0
                    ? @"Made for iPhone only. These are the apps Unified is meant to adapt on iPad."
                    : @"No iPhone-only apps found.")];
        } else {
            [specifiers addObject:UNGroupSpecifier(@"iPad apps",
                [primary count] > 0
                    ? @"Made for iPad only."
                    : @"No iPad-only apps found. iOS normally refuses to install iPad-only apps on iPhone.")];
        }
        [specifiers addObjectsFromArray:primary];

        if ([other count] > 0) {
            [specifiers addObject:UNGroupSpecifier(@"Other apps",
                @"These already support this device, so adapting them is usually unnecessary.")];
            [specifiers addObjectsFromArray:other];
        }

        if ([unlisted count] > 0) {
            [specifiers addObject:UNGroupSpecifier(@"Other configured apps",
                @"Apps with saved settings that are not in the list above.")];
            [specifiers addObjectsFromArray:unlisted];
        }

        if ([apps count] == 0) {
            [specifiers addObject:UNGroupSpecifier(nil,
                @"Couldn't read the list of installed apps on this iOS version.")];
        }

        _specifiers = [specifiers retain];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /* Refresh On/Off after returning from an app's page. */
    [self reloadSpecifiers];
}

- (id)un_statusForSpecifier:(PSSpecifier *)specifier
{
    UNPreferences *preferences = UNLoadPreferences();
    NSString *identifier = [specifier propertyForKey:UNSpecifierBundleIdentifier];
    NSString *mode;

    if (![preferences isEnabledForApp:identifier]) {
        return @"Off";
    }
    mode = [preferences modeForApp:identifier];
    return mode != nil ? [NSString stringWithFormat:@"On, %@", UNModeTitle(mode)] : @"On";
}

@end
