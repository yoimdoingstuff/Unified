/*
 * Unified - injection entry point.
 *
 * Status: Phase 1 skeleton. Builds in CI; installed on a device (iPad mini
 * 1st gen, iOS 8.4.1) but loading into apps has not been observed yet.
 *
 * Current behaviour: when loaded into an app, decide (via UNPolicy and
 * UNPreferences) whether Unified is enabled for it. If it is, log one line.
 * Nothing else; there are no hooks, so app behaviour is unchanged.
 *
 * Objective-C here must stay iOS 5 compatible (see docs/DEVELOPMENT.md):
 * manual retain/release, no object subscripting, no post-iOS 5 API without
 * a runtime check.
 */

#import <Foundation/Foundation.h>

#import "UNPreferences.h"
#include "UNPolicy.h"

%ctor {
    @autoreleasepool {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *bundleIdentifier = [mainBundle bundleIdentifier];
        NSString *executablePath = [mainBundle executablePath];
        UNPreferences *preferences;
        UNPolicyDecision decision;

        if (!UNProcessIsEligible([bundleIdentifier UTF8String], [executablePath UTF8String])) {
            return;
        }

        /* Whether a sandboxed App Store app on iOS 8 may read this file is
         * unverified. If it can't, settings load as empty, which means
         * "disabled": the safe outcome. */
        preferences = [UNPreferences preferencesWithContentsOfFile:UNPreferencesDefaultPath];
        decision = [preferences decisionForApp:bundleIdentifier];
        if (!decision.adapt) {
            return;
        }

        NSLog(@"[Unified] enabled for %@ (mode: %s). Phase 1 skeleton: no changes applied.",
              bundleIdentifier, UNScaleModeName(decision.mode));
    }
}
