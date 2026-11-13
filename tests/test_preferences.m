/*
 * Host tests for Sources/UNPreferences.m and the parser in UNAppCatalog.m.
 * Objective-C with Foundation, manual retain/release: macOS only.
 * Build and run with `make -C tests` on a Mac.
 */

#import <Foundation/Foundation.h>

#include <unistd.h>

#import "UNAppCatalog.h"
#import "UNPreferences.h"

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

static NSString *TempPath(NSString *name)
{
    NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:
        [NSString stringWithFormat:@"unified-tests-%d", (int)getpid()]];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    return [dir stringByAppendingPathComponent:name];
}

static void WriteString(NSString *path, NSString *contents)
{
    [contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

static void testMissingAndMalformedFilesAreOff(void)
{
    NSString *missing = TempPath(@"missing.plist");
    NSString *garbage = TempPath(@"garbage.plist");
    UNPreferences *prefs;

    [[NSFileManager defaultManager] removeItemAtPath:missing error:NULL];
    prefs = [UNPreferences preferencesWithContentsOfFile:missing];
    CHECK(![prefs isGloballyEnabled]);
    CHECK(![prefs isEnabledForApp:@"com.example.app"]);
    CHECK(![prefs decisionForApp:@"com.example.app"].adapt);
    CHECK([prefs defaultMode] == nil);

    WriteString(garbage, @"this is not a plist {{{");
    prefs = [UNPreferences preferencesWithContentsOfFile:garbage];
    CHECK(![prefs isGloballyEnabled]);
    CHECK(![prefs decisionForApp:@"com.example.app"].adapt);

    prefs = [UNPreferences preferencesWithContentsOfFile:nil];
    CHECK(![prefs isGloballyEnabled]);
    CHECK(![prefs save]); /* no path */
}

static void testWrongTypesAreOff(void)
{
    NSString *path = TempPath(@"types.plist");
    NSDictionary *apps;
    NSDictionary *root;
    UNPreferences *prefs;

    /* Strings instead of booleans, an array instead of a dictionary. */
    apps = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSDictionary dictionaryWithObjectsAndKeys:@"YES", @"Enabled", [NSNumber numberWithInt:3], @"Mode", nil],
        @"com.example.strings",
        [NSArray arrayWithObject:@"x"], @"com.example.array",
        nil];
    root = [NSDictionary dictionaryWithObjectsAndKeys:
        @"YES", @"Enabled", @"zoom", @"DefaultMode", apps, @"Apps", nil];
    CHECK([root writeToFile:path atomically:YES]);

    prefs = [UNPreferences preferencesWithContentsOfFile:path];
    CHECK(![prefs isGloballyEnabled]);
    CHECK([prefs defaultMode] == nil);
    CHECK(![prefs isEnabledForApp:@"com.example.strings"]);
    CHECK([prefs modeForApp:@"com.example.strings"] == nil);
    CHECK(![prefs isEnabledForApp:@"com.example.array"]);
    CHECK([[prefs configuredAppIdentifiers] isEqualToArray:[NSArray arrayWithObject:@"com.example.strings"]]);

    /* Apps itself of the wrong type. */
    root = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], @"Enabled", @"oops", @"Apps", nil];
    CHECK([root writeToFile:path atomically:YES]);
    prefs = [UNPreferences preferencesWithContentsOfFile:path];
    CHECK([prefs isGloballyEnabled]);
    CHECK([[prefs configuredAppIdentifiers] count] == 0);
    [prefs setEnabled:YES forApp:@"com.example.app"]; /* replaces the bad Apps value */
    CHECK([prefs isEnabledForApp:@"com.example.app"]);
}

static void testRoundTrip(void)
{
    NSString *path = TempPath(@"roundtrip.plist");
    UNPreferences *prefs;
    UNPolicyDecision decision;
    NSDictionary *onDisk;

    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    prefs = [UNPreferences preferencesWithContentsOfFile:path];
    [prefs setGloballyEnabled:YES];
    CHECK([prefs setDefaultMode:@"fill"]);
    [prefs setEnabled:YES forApp:@"com.example.one"];
    CHECK([prefs setMode:@"stretch" forApp:@"com.example.one"]);
    [prefs setEnabled:YES forApp:@"com.example.two"];
    CHECK([prefs save]);

    /* Exactly the format Tweak.x and docs/DEVELOPMENT.md describe. */
    onDisk = [NSDictionary dictionaryWithContentsOfFile:path];
    CHECK([[onDisk objectForKey:@"Enabled"] isEqual:[NSNumber numberWithBool:YES]]);
    CHECK([[onDisk objectForKey:@"DefaultMode"] isEqual:@"fill"]);
    CHECK([[[[onDisk objectForKey:@"Apps"] objectForKey:@"com.example.one"] objectForKey:@"Mode"] isEqual:@"stretch"]);

    prefs = [UNPreferences preferencesWithContentsOfFile:path];
    CHECK([prefs isGloballyEnabled]);
    CHECK([[prefs defaultMode] isEqualToString:@"fill"]);
    CHECK([[prefs enabledAppIdentifiers] isEqualToArray:
        [NSArray arrayWithObjects:@"com.example.one", @"com.example.two", nil]]);

    decision = [prefs decisionForApp:@"com.example.one"];
    CHECK(decision.adapt && decision.mode == UNScaleModeStretch);
    decision = [prefs decisionForApp:@"com.example.two"];
    CHECK(decision.adapt && decision.mode == UNScaleModeFill);
    decision = [prefs decisionForApp:@"com.example.three"];
    CHECK(!decision.adapt);

    /* Global switch off overrides everything. */
    [prefs setGloballyEnabled:NO];
    CHECK(![prefs decisionForApp:@"com.example.one"].adapt);
}

static void testSettersValidateAndClean(void)
{
    UNPreferences *prefs = [UNPreferences preferencesWithContentsOfFile:nil];

    CHECK(![prefs setDefaultMode:@"zoom"]);
    CHECK([prefs defaultMode] == nil);
    CHECK([prefs setDefaultMode:@"fit"]);
    CHECK([prefs setDefaultMode:nil]);
    CHECK([prefs defaultMode] == nil);

    CHECK(![prefs setMode:@"Fit" forApp:@"com.example.app"]);
    CHECK(![prefs setMode:@"fit" forApp:@""]);
    CHECK(![prefs setMode:@"fit" forApp:nil]);
    [prefs setEnabled:YES forApp:nil]; /* ignored, must not crash */
    CHECK([[prefs configuredAppIdentifiers] count] == 0);

    /* Turning an app off with no mode removes it completely. */
    [prefs setEnabled:YES forApp:@"com.example.app"];
    [prefs setEnabled:NO forApp:@"com.example.app"];
    CHECK([[prefs configuredAppIdentifiers] count] == 0);
    CHECK([[prefs dictionaryRepresentation] objectForKey:@"Apps"] == nil);

    /* A mode survives the app being switched off. */
    CHECK([prefs setMode:@"fill" forApp:@"com.example.app"]);
    CHECK(![prefs isEnabledForApp:@"com.example.app"]);
    CHECK([[prefs modeForApp:@"com.example.app"] isEqualToString:@"fill"]);
    CHECK([prefs setMode:nil forApp:@"com.example.app"]);
    CHECK([[prefs configuredAppIdentifiers] count] == 0);
}

static void testUnknownKeysPreserved(void)
{
    NSString *path = TempPath(@"unknown.plist");
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:
        @"keep me", @"FutureSetting", [NSNumber numberWithBool:YES], @"Enabled", nil];
    UNPreferences *prefs;

    CHECK([root writeToFile:path atomically:YES]);
    prefs = [UNPreferences preferencesWithContentsOfFile:path];
    [prefs setEnabled:YES forApp:@"com.example.app"];
    CHECK([prefs save]);
    CHECK([[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"FutureSetting"] isEqual:@"keep me"]);

    [prefs removeAllSettings];
    CHECK([prefs save]);
    CHECK([[NSDictionary dictionaryWithContentsOfFile:path] count] == 0);
}

static void testDeviceFamilyParsing(void)
{
    NSNumber *one = [NSNumber numberWithInt:1];
    NSNumber *two = [NSNumber numberWithInt:2];

    CHECK(UNAppFamilyFromDeviceFamilyValue(nil) == UNAppFamilyiPhone);
    CHECK(UNAppFamilyFromDeviceFamilyValue(one) == UNAppFamilyiPhone);
    CHECK(UNAppFamilyFromDeviceFamilyValue(two) == UNAppFamilyiPad);
    CHECK(UNAppFamilyFromDeviceFamilyValue(@"2") == UNAppFamilyiPad);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray arrayWithObject:one]) == UNAppFamilyiPhone);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray arrayWithObjects:one, two, nil]) == UNAppFamilyUniversal);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray arrayWithObjects:@"1", @"2", nil]) == UNAppFamilyUniversal);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray arrayWithObject:two]) == UNAppFamilyiPad);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray array]) == UNAppFamilyUnknown);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSArray arrayWithObject:[NSNumber numberWithInt:3]]) == UNAppFamilyUnknown);
    CHECK(UNAppFamilyFromDeviceFamilyValue([NSDictionary dictionary]) == UNAppFamilyUnknown);

    CHECK([UNAppFamilyDescription(UNAppFamilyiPhone) isEqualToString:@"iPhone"]);
    CHECK([UNAppFamilyDescription(UNAppFamilyUniversal) isEqualToString:@"iPhone and iPad"]);
    CHECK([UNAppFamilyDescription((UNAppFamily)42) isEqualToString:@"unknown"]);
}

static void testAppInfo(void)
{
    UNAppInfo *info = [[UNAppInfo alloc] initWithBundleIdentifier:@"com.example.app"
                                                      displayName:nil
                                                           family:UNAppFamilyiPhone];
    CHECK([[info displayName] isEqualToString:@"com.example.app"]); /* falls back to the bundle ID */
    CHECK([info family] == UNAppFamilyiPhone);
    [info release];
}

int main(void)
{
    @autoreleasepool {
        testMissingAndMalformedFilesAreOff();
        testWrongTypesAreOff();
        testRoundTrip();
        testSettersValidateAndClean();
        testUnknownKeysPreserved();
        testDeviceFamilyParsing();
        testAppInfo();
    }

    if (gFailures != 0) {
        fprintf(stderr, "test_preferences: %d of %d checks FAILED\n", gFailures, gChecks);
        return 1;
    }
    printf("test_preferences: all %d checks passed\n", gChecks);
    return 0;
}
