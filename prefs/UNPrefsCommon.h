/*
 * Shared helpers for the Unified Settings pane (Preferences.app process).
 *
 * Preferences.framework is private; it is the standard, long-lived way to
 * add a Settings pane through PreferenceLoader. Only long-standing
 * PSSpecifier/PSListController API is used (see docs/PRIVATE_APIS.md).
 * Specifiers are built in code rather than from plists so behaviour is the
 * same on iOS 5-10. `specifiers` returns NSMutableArray to match the
 * `_specifiers` ivar and property type in PSListController.h.
 *
 * Every read and write goes through UNPreferences on the settings file
 * directly. The pane re-reads the file before each change, so it never
 * overwrites values it did not set.
 */

#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#import "UNPreferences.h"

/* Present in Preferences.framework since well before iOS 5, but not
 * declared in Theos's PSSpecifier.h (theos/headers 25ef5c9). Sets the
 * values and titles a PSLinkListCell offers in PSListItemsController. */
@interface PSSpecifier (UNDeclarations)
- (void)setValues:(NSArray *)values titles:(NSArray *)titles;
@end

/* Specifier property keys used inside the pane. */
#define UNSpecifierKey @"UNKey"
#define UNSpecifierBundleIdentifier @"UNBundleIdentifier"
#define UNSpecifierDisplayName @"UNDisplayName"
#define UNSpecifierFamily @"UNFamily"

/* Value shown for "follow the default mode" in the per-app mode list. */
#define UNModeDefaultValue @"default"

static inline UNPreferences *UNLoadPreferences(void)
{
    return [UNPreferences preferencesWithContentsOfFile:UNPreferencesDefaultPath];
}

static inline NSString *UNModeTitle(NSString *mode)
{
    if ([mode isEqualToString:@"fill"]) {
        return @"Fill";
    }
    if ([mode isEqualToString:@"stretch"]) {
        return @"Stretch";
    }
    return @"Fit";
}

static inline PSSpecifier *UNGroupSpecifier(NSString *title, NSString *footer)
{
    PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:title
                                                        target:nil
                                                           set:NULL
                                                           get:NULL
                                                        detail:Nil
                                                          cell:PSGroupCell
                                                          edit:Nil];
    if (footer != nil) {
        [group setProperty:footer forKey:@"footerText"];
    }
    return group;
}

/* Saves, and tells the user if the file could not be written. */
static inline void UNSavePreferences(UNPreferences *preferences)
{
    if (![preferences save]) {
        /* UIAlertView: available on every iOS in range (deprecated only from 9). */
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:@"Unified"
                      message:@"Couldn't save settings. Your change was not applied."
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

static NSString *const UNModesFooter =
    @"Fit: shows the whole app, keeping its shape. Empty bars may remain.\n"
    @"Fill: fills the screen, keeping its shape. Edges may be cut off.\n"
    @"Stretch: fills the screen exactly. The app may look squashed.";
