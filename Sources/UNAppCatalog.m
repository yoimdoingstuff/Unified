#import "UNAppCatalog.h"

static NSString *const UNInstallationCachePath =
    @"/var/mobile/Library/Caches/com.apple.mobile.installation.plist";

static void UNAccumulateFamily(id entry, BOOL *hasPhone, BOOL *hasPad)
{
    NSInteger value;
    if ([entry isKindOfClass:[NSNumber class]]) {
        value = [(NSNumber *)entry integerValue];
    } else if ([entry isKindOfClass:[NSString class]]) {
        value = [(NSString *)entry integerValue];
    } else {
        return;
    }
    if (value == 1) {
        *hasPhone = YES;
    } else if (value == 2) {
        *hasPad = YES;
    }
}

UNAppFamily UNAppFamilyFromDeviceFamilyValue(id value)
{
    BOOL hasPhone = NO;
    BOOL hasPad = NO;

    if (value == nil) {
        return UNAppFamilyiPhone;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        for (id entry in (NSArray *)value) {
            UNAccumulateFamily(entry, &hasPhone, &hasPad);
        }
    } else {
        UNAccumulateFamily(value, &hasPhone, &hasPad);
    }

    if (hasPhone && hasPad) {
        return UNAppFamilyUniversal;
    }
    if (hasPhone) {
        return UNAppFamilyiPhone;
    }
    if (hasPad) {
        return UNAppFamilyiPad;
    }
    return UNAppFamilyUnknown;
}

NSString *UNAppFamilyDescription(UNAppFamily family)
{
    switch (family) {
    case UNAppFamilyiPhone:
        return @"iPhone";
    case UNAppFamilyiPad:
        return @"iPad";
    case UNAppFamilyUniversal:
        return @"iPhone and iPad";
    case UNAppFamilyUnknown:
        break;
    }
    return @"unknown";
}

@implementation UNAppInfo

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                             displayName:(NSString *)displayName
                                  family:(UNAppFamily)family
{
    self = [super init];
    if (self != nil) {
        _bundleIdentifier = [bundleIdentifier copy];
        _displayName = [(displayName != nil ? displayName : bundleIdentifier) copy];
        _family = family;
    }
    return self;
}

- (void)dealloc
{
    [_bundleIdentifier release];
    [_displayName release];
    [super dealloc];
}

- (NSString *)bundleIdentifier
{
    return _bundleIdentifier;
}

- (NSString *)displayName
{
    return _displayName;
}

- (UNAppFamily)family
{
    return _family;
}

- (NSComparisonResult)un_compareByName:(UNAppInfo *)other
{
    return [_displayName localizedCaseInsensitiveCompare:[other displayName]];
}

@end

/* Sends a no-argument message that returns an object, if the receiver
 * responds to it. Used for private classes that are not linked. */
static id UNObjectFromSelector(id receiver, SEL selector)
{
    if (receiver == nil || ![receiver respondsToSelector:selector]) {
        return nil;
    }
    return [receiver performSelector:selector];
}

static NSString *UNStringFromSelector(id receiver, SEL selector)
{
    id value = UNObjectFromSelector(receiver, selector);
    return ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) ? value : nil;
}

@implementation UNAppCatalog

/* iOS 7+: LSApplicationWorkspace (private). Returns NO if unavailable. */
+ (BOOL)un_appendFromWorkspace:(NSMutableArray *)result
{
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = UNObjectFromSelector(workspaceClass, @selector(defaultWorkspace));
    id applications = UNObjectFromSelector(workspace, @selector(allInstalledApplications));

    if (applications == nil) {
        applications = UNObjectFromSelector(workspace, @selector(allApplications));
    }
    if (![applications isKindOfClass:[NSArray class]]) {
        return NO;
    }

    for (id proxy in (NSArray *)applications) {
        NSString *type = UNStringFromSelector(proxy, @selector(applicationType));
        NSString *identifier = UNStringFromSelector(proxy, @selector(applicationIdentifier));
        NSString *name;
        UNAppFamily family = UNAppFamilyUnknown;
        id deviceFamily;
        UNAppInfo *info;

        if (identifier == nil || ![type isEqualToString:@"User"]) {
            continue;
        }

        name = UNStringFromSelector(proxy, @selector(localizedName));
        if (name == nil) {
            name = UNStringFromSelector(proxy, @selector(itemName));
        }

        deviceFamily = UNObjectFromSelector(proxy, @selector(deviceFamily));
        if ([deviceFamily isKindOfClass:[NSArray class]] && [(NSArray *)deviceFamily count] > 0) {
            family = UNAppFamilyFromDeviceFamilyValue(deviceFamily);
        } else {
            id bundleURL = UNObjectFromSelector(proxy, @selector(bundleURL));
            if ([bundleURL isKindOfClass:[NSURL class]]) {
                NSString *plistPath = [[(NSURL *)bundleURL path] stringByAppendingPathComponent:@"Info.plist"];
                NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
                if ([infoPlist isKindOfClass:[NSDictionary class]]) {
                    family = UNAppFamilyFromDeviceFamilyValue([infoPlist objectForKey:@"UIDeviceFamily"]);
                    if (name == nil) {
                        name = [infoPlist objectForKey:@"CFBundleDisplayName"];
                    }
                }
            }
        }

        info = [[UNAppInfo alloc] initWithBundleIdentifier:identifier displayName:name family:family];
        [result addObject:info];
        [info release];
    }
    return YES;
}

/* iOS 5-7: MobileInstallation's cache file. Returns NO if unreadable. */
+ (BOOL)un_appendFromInstallationCache:(NSMutableArray *)result
{
    NSDictionary *cache = [NSDictionary dictionaryWithContentsOfFile:UNInstallationCachePath];
    id user = [cache isKindOfClass:[NSDictionary class]] ? [cache objectForKey:@"User"] : nil;

    if (![user isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    for (id identifier in (NSDictionary *)user) {
        id entry = [(NSDictionary *)user objectForKey:identifier];
        NSString *name;
        UNAppInfo *info;

        if (![identifier isKindOfClass:[NSString class]] || ![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        name = [(NSDictionary *)entry objectForKey:@"CFBundleDisplayName"];
        if (![name isKindOfClass:[NSString class]] || [name length] == 0) {
            name = [(NSDictionary *)entry objectForKey:@"CFBundleName"];
        }
        if (![name isKindOfClass:[NSString class]] || [name length] == 0) {
            name = nil;
        }

        info = [[UNAppInfo alloc]
            initWithBundleIdentifier:identifier
                         displayName:name
                              family:UNAppFamilyFromDeviceFamilyValue(
                                         [(NSDictionary *)entry objectForKey:@"UIDeviceFamily"])];
        [result addObject:info];
        [info release];
    }
    return YES;
}

+ (NSArray *)installedUserApplications
{
    NSMutableArray *result = [NSMutableArray array];

    if (![self un_appendFromWorkspace:result] || [result count] == 0) {
        [result removeAllObjects];
        [self un_appendFromInstallationCache:result];
    }
    [result sortUsingSelector:@selector(un_compareByName:)];
    return result;
}

@end
