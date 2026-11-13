/*
 * UNPreferences - the one place that reads and writes Unified's settings.
 *
 * Used by both the tweak (read-only, in each app) and the Settings pane
 * (read/write, in Preferences.app), so the two can never disagree about
 * the file format.
 *
 * Status: implemented; host tests in tests/test_preferences.m (macOS).
 *
 * File: /var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist
 *   Enabled      Boolean   global switch (absent or not a Boolean = off)
 *   DefaultMode  String    "fit" | "fill" | "stretch" (invalid = ignored)
 *   Apps         Dict      bundle ID -> { Enabled: Boolean, Mode: String }
 *
 * The file is read and written directly, not through CFPreferences, so the
 * tweak and the pane see the same bytes on every iOS version (cfprefsd
 * caching differs across iOS 5-10).
 *
 * Objective-C rules: manual retain/release (no ARC), no object
 * subscripting, nothing newer than iOS 5 Foundation.
 */

#import <Foundation/Foundation.h>

#include "UNPolicy.h"

extern NSString *const UNPreferencesDefaultPath;
extern NSString *const UNPreferencesKeyEnabled;
extern NSString *const UNPreferencesKeyDefaultMode;
extern NSString *const UNPreferencesKeyApps;
extern NSString *const UNPreferencesKeyMode;

@interface UNPreferences : NSObject {
@private
    NSString *_path;
    NSMutableDictionary *_root;
}

/* Missing, unreadable, or malformed files load as empty settings (all off). */
+ (instancetype)preferencesWithContentsOfFile:(NSString *)path;
- (instancetype)initWithContentsOfFile:(NSString *)path;

- (NSString *)path;

- (BOOL)isGloballyEnabled;
- (void)setGloballyEnabled:(BOOL)enabled;

/* A valid mode string, or nil when unset or invalid. */
- (NSString *)defaultMode;
/* nil clears it. Returns NO, leaving settings unchanged, for an invalid mode. */
- (BOOL)setDefaultMode:(NSString *)mode;

- (BOOL)isEnabledForApp:(NSString *)bundleIdentifier;
- (void)setEnabled:(BOOL)enabled forApp:(NSString *)bundleIdentifier;

/* The app's own mode (valid string), or nil when unset or invalid. */
- (NSString *)modeForApp:(NSString *)bundleIdentifier;
/* nil clears it (the app then follows DefaultMode). NO for an invalid mode. */
- (BOOL)setMode:(NSString *)mode forApp:(NSString *)bundleIdentifier;

/* Bundle IDs with any stored settings, sorted. */
- (NSArray *)configuredAppIdentifiers;
/* Bundle IDs whose per-app switch is on, sorted. */
- (NSArray *)enabledAppIdentifiers;

/* What UNPolicyDecide says for this app with the current settings. */
- (UNPolicyDecision)decisionForApp:(NSString *)bundleIdentifier;

- (void)removeAllSettings;
- (NSDictionary *)dictionaryRepresentation;

/* Writes atomically to -path. Unknown keys from the file are preserved. */
- (BOOL)save;

@end
