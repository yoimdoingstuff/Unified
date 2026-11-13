/*
 * Settings > Unified: global switch, default mode, link to the app list.
 * Principal class of UnifiedPrefs.bundle.
 */

#import "UNPrefsCommon.h"

@interface UNAppListController : PSListController
@end

@interface UNRootListController : PSListController
@end

@implementation UNRootListController

- (NSMutableArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *specifier;

        [self setTitle:@"Unified"];

        [specifiers addObject:UNGroupSpecifier(nil,
            @"Master switch. When off, Unified changes nothing in any app, whatever the settings below say.")];

        specifier = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                   target:self
                                                      set:@selector(un_setValue:specifier:)
                                                      get:@selector(un_valueForSpecifier:)
                                                   detail:Nil
                                                     cell:PSSwitchCell
                                                     edit:Nil];
        [specifier setProperty:UNPreferencesKeyEnabled forKey:UNSpecifierKey];
        [specifiers addObject:specifier];

        [specifiers addObject:UNGroupSpecifier(@"Display mode", UNModesFooter)];

        specifier = [PSSpecifier preferenceSpecifierNamed:@"Default mode"
                                                   target:self
                                                      set:@selector(un_setValue:specifier:)
                                                      get:@selector(un_valueForSpecifier:)
                                                   detail:NSClassFromString(@"PSListItemsController")
                                                     cell:PSLinkListCell
                                                     edit:Nil];
        [specifier setProperty:UNPreferencesKeyDefaultMode forKey:UNSpecifierKey];
        [specifier setValues:[NSArray arrayWithObjects:@"fit", @"fill", @"stretch", nil]
                      titles:[NSArray arrayWithObjects:@"Fit", @"Fill", @"Stretch", nil]];
        [specifiers addObject:specifier];

        [specifiers addObject:UNGroupSpecifier(@"Apps",
            @"Unified only acts in apps you switch on here. Changes take effect the next time "
            @"the app opens: close it from the app switcher first.")];

        specifier = [PSSpecifier preferenceSpecifierNamed:@"Choose Apps"
                                                   target:self
                                                      set:NULL
                                                      get:@selector(un_appsSummary:)
                                                   detail:[UNAppListController class]
                                                     cell:PSLinkCell
                                                     edit:Nil];
        [specifiers addObject:specifier];

        [specifiers addObject:UNGroupSpecifier(@"Status",
            @"Experimental. iPhone apps running on an iPad are drawn with the chosen mode "
            @"instead of the usual 1x/2x. This needs iOS 8 or later and only works in portrait "
            @"for now; anything else is left as iOS normally shows it. iPad apps on iPhone are "
            @"not supported yet. Each app's page has a diagnostics report showing what happened.")];

        _specifiers = [specifiers retain];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /* Refresh the "Choose Apps" summary after returning from the app list. */
    [self reloadSpecifiers];
}

- (id)un_valueForSpecifier:(PSSpecifier *)specifier
{
    UNPreferences *preferences = UNLoadPreferences();
    NSString *key = [specifier propertyForKey:UNSpecifierKey];

    if ([key isEqualToString:UNPreferencesKeyEnabled]) {
        return [NSNumber numberWithBool:[preferences isGloballyEnabled]];
    }
    if ([key isEqualToString:UNPreferencesKeyDefaultMode]) {
        NSString *mode = [preferences defaultMode];
        return mode != nil ? mode : @"fit";
    }
    return nil;
}

- (void)un_setValue:(id)value specifier:(PSSpecifier *)specifier
{
    UNPreferences *preferences = UNLoadPreferences();
    NSString *key = [specifier propertyForKey:UNSpecifierKey];

    if ([key isEqualToString:UNPreferencesKeyEnabled]) {
        [preferences setGloballyEnabled:([value respondsToSelector:@selector(boolValue)] && [value boolValue])];
    } else if ([key isEqualToString:UNPreferencesKeyDefaultMode]) {
        if (![value isKindOfClass:[NSString class]] || ![preferences setDefaultMode:value]) {
            return;
        }
    } else {
        return;
    }
    UNSavePreferences(preferences);
}

- (id)un_appsSummary:(PSSpecifier *)specifier
{
    NSUInteger count = [[UNLoadPreferences() enabledAppIdentifiers] count];
    (void)specifier;
    if (count == 0) {
        return @"None";
    }
    return [NSString stringWithFormat:@"%lu on", (unsigned long)count];
}

@end
