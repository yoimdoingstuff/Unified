/*
 * Settings > Unified > Choose Apps > <app> > Diagnostics.
 *
 * Shows the report the tweak wrote inside the app's container
 * (Sources/UNDiagnostics.h), with a button to copy it as text, so results
 * can be checked and shared without SSH.
 */

#import "UNPrefsCommon.h"
#import "UNDiagnostics.h"

@interface UNDiagnosticsController : PSListController
@end

@implementation UNDiagnosticsController

- (NSString *)un_reportPath
{
    NSString *container = [[self specifier] propertyForKey:UNSpecifierDataContainer];
    if (![container isKindOfClass:[NSString class]] || [container length] == 0) {
        return nil;
    }
    return [container stringByAppendingPathComponent:UNDiagnosticsRelativePath];
}

- (NSDictionary *)un_report
{
    NSString *path = [self un_reportPath];
    NSDictionary *report = path != nil ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
    return [report isKindOfClass:[NSDictionary class]] ? report : nil;
}

static NSString *UNJoinedLines(id lines)
{
    NSMutableArray *strings = [NSMutableArray array];
    if ([lines isKindOfClass:[NSArray class]]) {
        for (id line in (NSArray *)lines) {
            if ([line isKindOfClass:[NSString class]]) {
                [strings addObject:line];
            }
        }
    }
    return [strings count] > 0 ? [strings componentsJoinedByString:@"\n"] : @"(none)";
}

static NSString *UNStringValue(NSDictionary *report, NSString *key)
{
    id value = [report objectForKey:key];
    return [value isKindOfClass:[NSString class]] ? value : @"?";
}

- (NSString *)un_reportText
{
    NSDictionary *report = [self un_report];
    if (report == nil) {
        return nil;
    }
    return [NSString stringWithFormat:
        @"Unified %@ on iOS %@, mode %@, updated %@\n\nApp:\n%@\n\nWindows:\n%@\n\nTouches:\n%@",
        UNStringValue(report, UNDiagnosticsKeyUnifiedVersion),
        UNStringValue(report, UNDiagnosticsKeySystem),
        UNStringValue(report, UNDiagnosticsKeyMode),
        UNStringValue(report, UNDiagnosticsKeyUpdated),
        UNJoinedLines([report objectForKey:UNDiagnosticsKeyApp]),
        UNJoinedLines([report objectForKey:UNDiagnosticsKeyWindows]),
        UNJoinedLines([report objectForKey:UNDiagnosticsKeyTouches])];
}

- (NSMutableArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        NSDictionary *report = [self un_report];
        PSSpecifier *button;

        [self setTitle:@"Diagnostics"];

        if (report == nil) {
            [specifiers addObject:UNGroupSpecifier(@"No report yet",
                [self un_reportPath] == nil
                    ? @"This app's data folder could not be found, so its report cannot be read."
                    : @"Switch Unified on for this app, then close the app from the app switcher and "
                      @"open it again. If there is still no report, the tweak did not load in the app, "
                      @"or the app could not read Unified's settings.")];
            _specifiers = [specifiers retain];
            return _specifiers;
        }

        [specifiers addObject:UNGroupSpecifier(@"Summary",
            [NSString stringWithFormat:@"Unified %@ on iOS %@\nMode: %@\nUpdated: %@",
                UNStringValue(report, UNDiagnosticsKeyUnifiedVersion),
                UNStringValue(report, UNDiagnosticsKeySystem),
                UNStringValue(report, UNDiagnosticsKeyMode),
                UNStringValue(report, UNDiagnosticsKeyUpdated)])];
        [specifiers addObject:UNGroupSpecifier(@"App", UNJoinedLines([report objectForKey:UNDiagnosticsKeyApp]))];
        [specifiers addObject:UNGroupSpecifier(@"Windows", UNJoinedLines([report objectForKey:UNDiagnosticsKeyWindows]))];
        [specifiers addObject:UNGroupSpecifier(@"Touches", UNJoinedLines([report objectForKey:UNDiagnosticsKeyTouches]))];

        [specifiers addObject:UNGroupSpecifier(nil,
            @"Copies this report as text, so you can paste it into Notes or an email.")];
        button = [PSSpecifier preferenceSpecifierNamed:@"Copy Report"
                                                target:self
                                                   set:NULL
                                                   get:NULL
                                                detail:Nil
                                                  cell:PSButtonCell
                                                  edit:Nil];
        /* The public `action` ivar is how button specifiers get their
         * selector on every iOS version in range. */
        button->action = @selector(un_copyReport:);
        [specifiers addObject:button];

        _specifiers = [specifiers retain];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadSpecifiers];
}

- (void)un_copyReport:(PSSpecifier *)specifier
{
    NSString *text = [self un_reportText];
    UIAlertView *alert;
    (void)specifier;

    if (text != nil) {
        [[UIPasteboard generalPasteboard] setString:text];
    }
    alert = [[UIAlertView alloc] initWithTitle:@"Unified"
                                       message:(text != nil ? @"Report copied." : @"There is no report to copy.")
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
