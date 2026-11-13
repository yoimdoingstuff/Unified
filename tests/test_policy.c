/*
 * Host unit tests for Sources/UNPolicy.c.
 * Build and run with `make -C tests`. Exit status 0 only if every check passed.
 */

#include "UNPolicy.h"

#include <stdio.h>
#include <string.h>

static int gChecks = 0;
static int gFailures = 0;

#define CHECK(cond)                                                              \
    do {                                                                         \
        gChecks++;                                                               \
        if (!(cond)) {                                                           \
            gFailures++;                                                         \
            fprintf(stderr, "%s:%d: CHECK failed: %s\n", __FILE__, __LINE__,     \
                    #cond);                                                      \
        }                                                                        \
    } while (0)

static const char *const kAppPath8 =
    "/private/var/mobile/Containers/Bundle/Application/0000-UUID/Some.app/Some";
static const char *const kAppPathLegacy =
    "/private/var/mobile/Applications/0000-UUID/Some.app/Some";
static const char *const kSystemAppPath = "/Applications/MobileSafari.app/MobileSafari";

static void testProcessEligibility(void)
{
    /* Normal App Store apps (iOS 8+ and pre-iOS 8 container layouts) and system apps. */
    CHECK(UNProcessIsEligible("com.example.app", kAppPath8));
    CHECK(UNProcessIsEligible("com.example.app", kAppPathLegacy));
    CHECK(UNProcessIsEligible("com.apple.mobilesafari", kSystemAppPath));

    /* Never eligible. */
    CHECK(!UNProcessIsEligible("com.apple.springboard",
                               "/System/Library/CoreServices/SpringBoard.app/SpringBoard"));
    CHECK(!UNProcessIsEligible("com.apple.Preferences", "/Applications/Preferences.app/Preferences"));

    /* App extension inside an app bundle. */
    CHECK(!UNProcessIsEligible("com.example.app.widget",
                               "/var/mobile/Containers/Bundle/Application/X/Some.app/PlugIns/"
                               "Widget.appex/Widget"));

    /* Not an app bundle (daemon / tool). */
    CHECK(!UNProcessIsEligible("com.example.daemon", "/usr/libexec/exampled"));

    /* Missing values. */
    CHECK(!UNProcessIsEligible(NULL, kAppPath8));
    CHECK(!UNProcessIsEligible("", kAppPath8));
    CHECK(!UNProcessIsEligible("com.example.app", NULL));
    CHECK(!UNProcessIsEligible("com.example.app", ""));

    /* Exclusions are exact matches, not prefixes. */
    CHECK(UNProcessIsEligible("com.apple.springboard.example", kAppPath8));
}

static void testModeParsing(void)
{
    UNScaleMode mode = UNScaleModeStretch;

    CHECK(UNScaleModeFromString("fit", &mode) && mode == UNScaleModeFit);
    CHECK(UNScaleModeFromString("fill", &mode) && mode == UNScaleModeFill);
    CHECK(UNScaleModeFromString("stretch", &mode) && mode == UNScaleModeStretch);

    mode = UNScaleModeFill;
    CHECK(!UNScaleModeFromString("Fit", &mode));
    CHECK(!UNScaleModeFromString("", &mode));
    CHECK(!UNScaleModeFromString("fit ", &mode));
    CHECK(!UNScaleModeFromString("zoom", &mode));
    CHECK(!UNScaleModeFromString(NULL, &mode));
    CHECK(mode == UNScaleModeFill); /* untouched on failure */
    CHECK(!UNScaleModeFromString("fit", NULL));

    CHECK(strcmp(UNScaleModeName(UNScaleModeFit), "fit") == 0);
    CHECK(strcmp(UNScaleModeName(UNScaleModeFill), "fill") == 0);
    CHECK(strcmp(UNScaleModeName(UNScaleModeStretch), "stretch") == 0);
    CHECK(strcmp(UNScaleModeName((UNScaleMode)42), "invalid") == 0);
}

static UNPolicyInput makeInput(bool global, bool app, const char *appMode, const char *defaultMode)
{
    UNPolicyInput input;
    input.globalEnabled = global;
    input.appEnabled = app;
    input.appMode = appMode;
    input.defaultMode = defaultMode;
    return input;
}

static void testDecision(void)
{
    UNPolicyDecision d;

    /* Both switches are required. */
    CHECK(!UNPolicyDecide(makeInput(false, false, NULL, NULL)).adapt);
    CHECK(!UNPolicyDecide(makeInput(true, false, "fill", "fill")).adapt);
    CHECK(!UNPolicyDecide(makeInput(false, true, "fill", "fill")).adapt);
    CHECK(UNPolicyDecide(makeInput(true, true, NULL, NULL)).adapt);

    /* Mode precedence: app > default > Fit. */
    d = UNPolicyDecide(makeInput(true, true, "stretch", "fill"));
    CHECK(d.mode == UNScaleModeStretch);

    d = UNPolicyDecide(makeInput(true, true, NULL, "fill"));
    CHECK(d.mode == UNScaleModeFill);

    d = UNPolicyDecide(makeInput(true, true, "bogus", "fill"));
    CHECK(d.mode == UNScaleModeFill);

    d = UNPolicyDecide(makeInput(true, true, "bogus", "also bogus"));
    CHECK(d.mode == UNScaleModeFit);

    d = UNPolicyDecide(makeInput(true, true, NULL, NULL));
    CHECK(d.mode == UNScaleModeFit);
}

int main(void)
{
    testProcessEligibility();
    testModeParsing();
    testDecision();

    if (gFailures != 0) {
        fprintf(stderr, "test_policy: %d of %d checks FAILED\n", gFailures, gChecks);
        return 1;
    }
    printf("test_policy: all %d checks passed\n", gChecks);
    return 0;
}
