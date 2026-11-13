#import "UNPreferences.h"

NSString *const UNPreferencesDefaultPath =
    @"/var/mobile/Library/Preferences/com.yoimdoingstuff.unified.plist";
NSString *const UNPreferencesKeyEnabled = @"Enabled";
NSString *const UNPreferencesKeyDefaultMode = @"DefaultMode";
NSString *const UNPreferencesKeyApps = @"Apps";
NSString *const UNPreferencesKeyMode = @"Mode";

/* YES only for a real NSNumber that is true; strings like "YES" do not count. */
static BOOL UNIsTrue(id value)
{
    return [value isKindOfClass:[NSNumber class]] && [(NSNumber *)value boolValue];
}

static BOOL UNIsValidMode(id value)
{
    UNScaleMode mode;
    return [value isKindOfClass:[NSString class]]
        && UNScaleModeFromString([(NSString *)value UTF8String], &mode);
}

static BOOL UNIsBundleIdentifier(id value)
{
    return [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0;
}

@implementation UNPreferences

+ (instancetype)preferencesWithContentsOfFile:(NSString *)path
{
    return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
    self = [super init];
    if (self != nil) {
        NSDictionary *loaded = nil;
        _path = [path copy];
        if (path != nil) {
            loaded = [NSDictionary dictionaryWithContentsOfFile:path];
        }
        if ([loaded isKindOfClass:[NSDictionary class]]) {
            _root = [loaded mutableCopy];
        } else {
            _root = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (void)dealloc
{
    [_path release];
    [_root release];
    [super dealloc];
}

- (NSString *)path
{
    return _path;
}

#pragma mark - Global

- (BOOL)isGloballyEnabled
{
    return UNIsTrue([_root objectForKey:UNPreferencesKeyEnabled]);
}

- (void)setGloballyEnabled:(BOOL)enabled
{
    [_root setObject:[NSNumber numberWithBool:enabled] forKey:UNPreferencesKeyEnabled];
}

- (NSString *)defaultMode
{
    id value = [_root objectForKey:UNPreferencesKeyDefaultMode];
    return UNIsValidMode(value) ? (NSString *)value : nil;
}

- (BOOL)setDefaultMode:(NSString *)mode
{
    if (mode == nil) {
        [_root removeObjectForKey:UNPreferencesKeyDefaultMode];
        return YES;
    }
    if (!UNIsValidMode(mode)) {
        return NO;
    }
    [_root setObject:[[mode copy] autorelease] forKey:UNPreferencesKeyDefaultMode];
    return YES;
}

#pragma mark - Per app

- (NSDictionary *)appsDictionary
{
    id apps = [_root objectForKey:UNPreferencesKeyApps];
    return [apps isKindOfClass:[NSDictionary class]] ? (NSDictionary *)apps : nil;
}

- (NSDictionary *)settingsForApp:(NSString *)bundleIdentifier
{
    id settings;
    if (!UNIsBundleIdentifier(bundleIdentifier)) {
        return nil;
    }
    settings = [[self appsDictionary] objectForKey:bundleIdentifier];
    return [settings isKindOfClass:[NSDictionary class]] ? (NSDictionary *)settings : nil;
}

/* Replaces one app's settings; an empty dictionary removes the app entirely. */
- (void)storeSettings:(NSDictionary *)settings forApp:(NSString *)bundleIdentifier
{
    NSMutableDictionary *apps = [[[self appsDictionary] mutableCopy] autorelease];
    if (apps == nil) {
        apps = [NSMutableDictionary dictionary];
    }
    if ([settings count] == 0) {
        [apps removeObjectForKey:bundleIdentifier];
    } else {
        [apps setObject:settings forKey:bundleIdentifier];
    }
    if ([apps count] == 0) {
        [_root removeObjectForKey:UNPreferencesKeyApps];
    } else {
        [_root setObject:apps forKey:UNPreferencesKeyApps];
    }
}

- (NSMutableDictionary *)mutableSettingsForApp:(NSString *)bundleIdentifier
{
    NSMutableDictionary *settings = [[[self settingsForApp:bundleIdentifier] mutableCopy] autorelease];
    return settings != nil ? settings : [NSMutableDictionary dictionary];
}

- (BOOL)isEnabledForApp:(NSString *)bundleIdentifier
{
    return UNIsTrue([[self settingsForApp:bundleIdentifier] objectForKey:UNPreferencesKeyEnabled]);
}

- (void)setEnabled:(BOOL)enabled forApp:(NSString *)bundleIdentifier
{
    NSMutableDictionary *settings;
    if (!UNIsBundleIdentifier(bundleIdentifier)) {
        return;
    }
    settings = [self mutableSettingsForApp:bundleIdentifier];
    if (enabled) {
        [settings setObject:[NSNumber numberWithBool:YES] forKey:UNPreferencesKeyEnabled];
    } else {
        /* Absent means off; keeps the file small and the meaning unambiguous. */
        [settings removeObjectForKey:UNPreferencesKeyEnabled];
    }
    [self storeSettings:settings forApp:bundleIdentifier];
}

- (NSString *)modeForApp:(NSString *)bundleIdentifier
{
    id value = [[self settingsForApp:bundleIdentifier] objectForKey:UNPreferencesKeyMode];
    return UNIsValidMode(value) ? (NSString *)value : nil;
}

- (BOOL)setMode:(NSString *)mode forApp:(NSString *)bundleIdentifier
{
    NSMutableDictionary *settings;
    if (!UNIsBundleIdentifier(bundleIdentifier)) {
        return NO;
    }
    if (mode != nil && !UNIsValidMode(mode)) {
        return NO;
    }
    settings = [self mutableSettingsForApp:bundleIdentifier];
    if (mode == nil) {
        [settings removeObjectForKey:UNPreferencesKeyMode];
    } else {
        [settings setObject:[[mode copy] autorelease] forKey:UNPreferencesKeyMode];
    }
    [self storeSettings:settings forApp:bundleIdentifier];
    return YES;
}

- (NSArray *)configuredAppIdentifiers
{
    NSMutableArray *result = [NSMutableArray array];
    NSDictionary *apps = [self appsDictionary];
    for (id key in apps) {
        if (UNIsBundleIdentifier(key) && [self settingsForApp:key] != nil) {
            [result addObject:key];
        }
    }
    [result sortUsingSelector:@selector(compare:)];
    return result;
}

- (NSArray *)enabledAppIdentifiers
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *identifier in [self configuredAppIdentifiers]) {
        if ([self isEnabledForApp:identifier]) {
            [result addObject:identifier];
        }
    }
    return result;
}

#pragma mark - Decision

- (UNPolicyDecision)decisionForApp:(NSString *)bundleIdentifier
{
    UNPolicyInput input;
    NSString *appMode = [self modeForApp:bundleIdentifier];
    NSString *defaultMode = [self defaultMode];

    input.globalEnabled = [self isGloballyEnabled];
    input.appEnabled = [self isEnabledForApp:bundleIdentifier];
    /* UTF8String buffers live until the enclosing autorelease pool drains,
     * which is after UNPolicyDecide returns. */
    input.appMode = appMode != nil ? [appMode UTF8String] : NULL;
    input.defaultMode = defaultMode != nil ? [defaultMode UTF8String] : NULL;
    return UNPolicyDecide(input);
}

#pragma mark - Storage

- (void)removeAllSettings
{
    [_root removeAllObjects];
}

- (NSDictionary *)dictionaryRepresentation
{
    return [[_root copy] autorelease];
}

- (BOOL)save
{
    if (_path == nil) {
        return NO;
    }
    return [_root writeToFile:_path atomically:YES];
}

@end
