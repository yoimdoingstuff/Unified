/*
 * Unified - injection entry point.
 *
 * Status: Phase 1 skeleton. NOT yet built or run on a device.
 *
 * Current behaviour: when loaded into an app, decide (via UNPolicy) whether
 * Unified is enabled for it. If it is, log one line. Nothing else; there
 * are no hooks, so app behaviour is unchanged.
 *
 * Objective-C here must stay iOS 5 compatible (see docs/DEVELOPMENT.md):
 * no object subscripting, no ARC-only constructs, no post-iOS 5 API
 * without a runtime check.
 */

#import <Foundation/Foundation.h>

#include "UNPolicy.h"

/* Read directly rather than through CFPreferences: cfprefsd caching and
 * sandbox behaviour differ across iOS 5-10. Whether a sandboxed app on
 * iOS 8.4.1 can read this path is unverified; if it can't, the result is
 * "disabled", which is the safe outcome. */
static NSString *const kUNPreferencesPath =
    @"/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist";

/* Returns YES only for a real boolean/number YES. Strings and other types are ignored. */
static BOOL UNBoolValue(id value)
{
    return [value isKindOfClass:[NSNumber class]] && [(NSNumber *)value boolValue];
}

/* Returns a UTF-8 string only for an NSString value; otherwise NULL. The
 * pointer is valid for the enclosing autorelease pool. */
static const char *UNStringValue(id value)
{
    return [value isKindOfClass:[NSString class]] ? [(NSString *)value UTF8String] : NULL;
}

%ctor {
    @autoreleasepool {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *bundleIdentifier = [mainBundle bundleIdentifier];
        NSString *executablePath = [mainBundle executablePath];
        NSDictionary *preferences;
        NSDictionary *apps;
        NSDictionary *appSettings = nil;
        UNPolicyInput input;
        UNPolicyDecision decision;

        if (!UNProcessIsEligible([bundleIdentifier UTF8String], [executablePath UTF8String])) {
            return;
        }

        preferences = [NSDictionary dictionaryWithContentsOfFile:kUNPreferencesPath];
        if (![preferences isKindOfClass:[NSDictionary class]]) {
            return;
        }

        apps = [preferences objectForKey:@"Apps"];
        if ([apps isKindOfClass:[NSDictionary class]]) {
            id candidate = [apps objectForKey:bundleIdentifier];
            if ([candidate isKindOfClass:[NSDictionary class]]) {
                appSettings = candidate;
            }
        }

        input.globalEnabled = UNBoolValue([preferences objectForKey:@"Enabled"]);
        input.appEnabled = UNBoolValue([appSettings objectForKey:@"Enabled"]);
        input.appMode = UNStringValue([appSettings objectForKey:@"Mode"]);
        input.defaultMode = UNStringValue([preferences objectForKey:@"DefaultMode"]);

        decision = UNPolicyDecide(input);
        if (!decision.adapt) {
            return;
        }

        NSLog(@"[Unified] enabled for %@ (mode: %s). Phase 1 skeleton: no changes applied.",
              bundleIdentifier, UNScaleModeName(decision.mode));
    }
}
