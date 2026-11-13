/*
 * Settings > Unified > Choose Apps > <app>: per-app switch and mode.
 * The app is identified by properties on the link specifier that opened
 * this page (set in UNAppListController).
 */

#import "UNPrefsCommon.h"
#import "UNAppCatalog.h"

@interface UNAppSettingsController : PSListController
@end

@implementation UNAppSettingsController

- (NSString *)un_bundleIdentifier
{
    id identifier = [[self specifier] propertyForKey:UNSpecifierBundleIdentifier];
    return [identifier isKindOfClass:[NSString class]] ? identifier : nil;
}

- (NSMutableArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        NSString *identifier = [self un_bundleIdentifier];
        NSString *name = [[self specifier] propertyForKey:UNSpecifierDisplayName];
        UNAppFamily family = (UNAppFamily)[[[self specifier] propertyForKey:UNSpecifierFamily] intValue];
        NSString *defaultMode = [UNLoadPreferences() defaultMode];
        PSSpecifier *specifier;

        [self setTitle:(name != nil ? name : @"App")];

        if (identifier == nil) {
            [specifiers addObject:UNGroupSpecifier(nil, @"This app could not be identified.")];
            _specifiers = [specifiers retain];
            return _specifiers;
        }

        [specifiers addObject:UNGroupSpecifier(nil,
            [NSString stringWithFormat:@"Made for: %@\nBundle ID: %@",
                                       UNAppFamilyDescription(family), identifier])];

        specifier = [PSSpecifier preferenceSpecifierNamed:@"Use Unified"
                                                   target:self
                                                      set:@selector(un_setValue:specifier:)
                                                      get:@selector(un_valueForSpecifier:)
                                                   detail:Nil
                                                     cell:PSSwitchCell
                                                     edit:Nil];
        [specifier setProperty:UNPreferencesKeyEnabled forKey:UNSpecifierKey];
        [specifiers addObject:specifier];

        [specifiers addObject:UNGroupSpecifier(@"Display mode", UNModesFooter)];

        specifier = [PSSpecifier preferenceSpecifierNamed:@"Mode"
                                                   target:self
                                                      set:@selector(un_setValue:specifier:)
                                                      get:@selector(un_valueForSpecifier:)
                                                   detail:NSClassFromString(@"PSListItemsController")
                                                     cell:PSLinkListCell
                                                     edit:Nil];
        [specifier setProperty:UNPreferencesKeyMode forKey:UNSpecifierKey];
        [specifier setValues:[NSArray arrayWithObjects:UNModeDefaultValue, @"fit", @"fill", @"stretch", nil]
                      titles:[NSArray arrayWithObjects:
                                 [NSString stringWithFormat:@"Default (%@)", UNModeTitle(defaultMode)],
                                 @"Fit", @"Fill", @"Stretch", nil]];
        [specifiers addObject:specifier];

        _specifiers = [specifiers retain];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadSpecifiers];
}

- (id)un_valueForSpecifier:(PSSpecifier *)specifier
{
    UNPreferences *preferences = UNLoadPreferences();
    NSString *identifier = [self un_bundleIdentifier];
    NSString *key = [specifier propertyForKey:UNSpecifierKey];

    if ([key isEqualToString:UNPreferencesKeyEnabled]) {
        return [NSNumber numberWithBool:[preferences isEnabledForApp:identifier]];
    }
    if ([key isEqualToString:UNPreferencesKeyMode]) {
        NSString *mode = [preferences modeForApp:identifier];
        return mode != nil ? mode : UNModeDefaultValue;
    }
    return nil;
}

- (void)un_setValue:(id)value specifier:(PSSpecifier *)specifier
{
    UNPreferences *preferences = UNLoadPreferences();
    NSString *identifier = [self un_bundleIdentifier];
    NSString *key = [specifier propertyForKey:UNSpecifierKey];

    if (identifier == nil) {
        return;
    }
    if ([key isEqualToString:UNPreferencesKeyEnabled]) {
        [preferences setEnabled:([value respondsToSelector:@selector(boolValue)] && [value boolValue])
                         forApp:identifier];
    } else if ([key isEqualToString:UNPreferencesKeyMode]) {
        NSString *mode = [value isKindOfClass:[NSString class]] ? value : nil;
        if ([mode isEqualToString:UNModeDefaultValue]) {
            mode = nil;
        }
        if (![preferences setMode:mode forApp:identifier]) {
            return;
        }
    } else {
        return;
    }
    UNSavePreferences(preferences);
}

@end
