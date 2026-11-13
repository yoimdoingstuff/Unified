/*
 * Unified - injection entry point and classic-mode scaling.
 *
 * Status: EXPERIMENTAL. Builds in CI; not yet observed on a device.
 *
 * What it does, only in apps switched on in Settings > Unified:
 *  1. Writes a diagnostics report into the app's container (shown in the
 *     Settings pane), so behaviour can be checked without SSH.
 *  2. If the app is an iPhone app running in classic (compatibility) mode
 *     on an iPad, replaces UIKit's 1x/2x classic presentation transform
 *     with the selected Fit / Fill / Stretch transform, and maps
 *     screen <-> window conversions (touches) through the exact inverse.
 *
 * How (research in docs/TECHNICAL_DESIGN.md, APIs in docs/PRIVATE_APIS.md):
 * on iOS 5.1-8.1 UIKit presents classic apps in-process: each UIWindow has
 * a private _transformLayer, configured by
 * -_updateTransformLayerForClassicPresentation. iOS 8 adds
 * -_convert*SceneReferenceSpace: methods for window <-> screen conversion.
 * Scaling is applied only when all of these exist and the layer tree looks
 * as expected; otherwise UIKit's own behaviour is left untouched and the
 * reason is recorded in the diagnostics.
 *
 * Objective-C here must stay iOS 5 compatible (docs/DEVELOPMENT.md):
 * manual retain/release, no object subscripting, runtime checks for
 * anything newer than iOS 5.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "UNDiagnostics.h"
#import "UNPreferences.h"
#include "UNGeometry.h"
#include "UNPolicy.h"

/* Layout-compatible with QuartzCore's private CADoublePoint. */
typedef struct {
    double x;
    double y;
} UNDoublePoint;

@interface UIApplication (UNPrivate)
- (BOOL)_isClassic;
@end

@interface UIWindow (UNPrivate)
- (CGRect)_sceneReferenceBounds;
- (CGPoint)_convertPointToSceneReferenceSpace:(CGPoint)point;
- (CGPoint)_convertPointFromSceneReferenceSpace:(CGPoint)point;
- (BOOL)_isClassicControllerWindow;
@end

#pragma mark - State

static UNScaleMode gMode = UNScaleModeFit;
static NSString *gBundleIdentifier = nil;
static NSMutableDictionary *gWindowLines = nil; /* window address -> status line */
static NSMutableArray *gAppLines = nil;
static unsigned long gTouchConversions = 0;
static unsigned long gOtherConversions = 0;
static NSDictionary *gLastWritten = nil;
static const void *const kUNActiveTransformKey = &kUNActiveTransformKey;

#pragma mark - Diagnostics

static NSString *UNRectString(CGRect rect)
{
    return [NSString stringWithFormat:@"%.1f,%.1f %.1fx%.1f",
                     (double)rect.origin.x, (double)rect.origin.y,
                     (double)rect.size.width, (double)rect.size.height];
}

static NSString *UNWindowKey(UIWindow *window)
{
    return [NSString stringWithFormat:@"%@ %p", NSStringFromClass([window class]), (void *)window];
}

static void UNWriteDiagnostics(void)
{
    NSMutableDictionary *report;
    NSArray *windowLines;
    NSString *path;
    NSDateFormatter *formatter;

    if (gAppLines == nil) {
        return;
    }

    windowLines = [[gWindowLines allValues] sortedArrayUsingSelector:@selector(compare:)];
    report = [NSMutableDictionary dictionary];
    [report setObject:[[UIDevice currentDevice] systemVersion] forKey:UNDiagnosticsKeySystem];
    [report setObject:@"0.0.3" forKey:UNDiagnosticsKeyUnifiedVersion];
    [report setObject:[NSString stringWithUTF8String:UNScaleModeName(gMode)] forKey:UNDiagnosticsKeyMode];
    [report setObject:gAppLines forKey:UNDiagnosticsKeyApp];
    [report setObject:(windowLines != nil ? windowLines : [NSArray array]) forKey:UNDiagnosticsKeyWindows];
    [report setObject:[NSArray arrayWithObjects:
                           [NSString stringWithFormat:@"Screen-to-window conversions handled by Unified: %lu", gTouchConversions],
                           [NSString stringWithFormat:@"Window-to-screen conversions handled by Unified: %lu", gOtherConversions],
                           nil]
               forKey:UNDiagnosticsKeyTouches];

    /* Skip identical rewrites (the conversion counters are left out of the
     * comparison so touches do not cause a write each time). */
    {
        NSMutableDictionary *comparable = [[report mutableCopy] autorelease];
        [comparable removeObjectForKey:UNDiagnosticsKeyTouches];
        if (gLastWritten != nil && [gLastWritten isEqualToDictionary:comparable]) {
            return;
        }
        [gLastWritten release];
        gLastWritten = [comparable copy];
    }

    formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [report setObject:[formatter stringFromDate:[NSDate date]] forKey:UNDiagnosticsKeyUpdated];

    path = [NSHomeDirectory() stringByAppendingPathComponent:UNDiagnosticsRelativePath];
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    [report writeToFile:path atomically:YES];
}

static void UNRecordWindow(UIWindow *window, NSString *line)
{
    if (gWindowLines == nil) {
        return;
    }
    [gWindowLines setObject:[NSString stringWithFormat:@"%@: %@", NSStringFromClass([window class]), line]
                     forKey:UNWindowKey(window)];
    UNWriteDiagnostics();
}

#pragma mark - Active transform per window

static void UNSetActiveTransform(UIWindow *window, const UNTransform *transform)
{
    NSValue *value = nil;
    if (transform != NULL) {
        value = [NSValue valueWithBytes:transform objCType:@encode(UNTransform)];
    }
    objc_setAssociatedObject(window, kUNActiveTransformKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL UNGetActiveTransform(UIWindow *window, UNTransform *outTransform)
{
    NSValue *value = objc_getAssociatedObject(window, kUNActiveTransformKey);
    if (value == nil) {
        return NO;
    }
    [value getValue:outTransform];
    return YES;
}

#pragma mark - Scaling

static CALayer *UNTransformLayer(UIWindow *window)
{
    Ivar ivar = class_getInstanceVariable([UIWindow class], "_transformLayer");
    id layer = ivar != NULL ? object_getIvar(window, ivar) : nil;
    return [layer isKindOfClass:[CALayer class]] ? (CALayer *)layer : nil;
}

static BOOL UNIsAffineScaleTranslate(CATransform3D t)
{
    return t.m12 == 0 && t.m13 == 0 && t.m14 == 0
        && t.m21 == 0 && t.m23 == 0 && t.m24 == 0
        && t.m31 == 0 && t.m32 == 0 && t.m33 == 1 && t.m34 == 0
        && t.m43 == 0 && t.m44 == 1;
}

/* YES if a layer's own coordinates equal its superlayer's (no move/scale). */
static BOOL UNLayerIsNeutral(CALayer *layer)
{
    CGRect bounds = [layer bounds];
    CGPoint anchor = [layer anchorPoint];
    CGPoint position = [layer position];
    return CATransform3DIsIdentity([layer transform])
        && fabs((double)(position.x - (bounds.origin.x + anchor.x * bounds.size.width))) < 0.01
        && fabs((double)(position.y - (bounds.origin.y + anchor.y * bounds.size.height))) < 0.01;
}

/*
 * Called after UIKit has configured the window's transform layer for
 * classic presentation. Replaces that transform with Unified's, or leaves
 * it alone and records why.
 */
static void UNApplyClassicScaling(UIWindow *window)
{
    UIApplication *application = [UIApplication sharedApplication];
    CALayer *transformLayer;
    CALayer *windowLayer = [window layer];
    CATransform3D existing;
    CGRect sourceRect;
    CGRect sceneRect;
    CGPoint contentOrigin;
    CGPoint unitStep;
    CGRect layerBounds;
    CGPoint anchorPoint;
    UNTransform target;
    UNTransform layerTransform;
    CATransform3D applied;
    CGPoint systemTopLeft;
    CGPoint systemBottomRight;

    UNSetActiveTransform(window, NULL);

    if ([window respondsToSelector:@selector(_isClassicControllerWindow)] && [window _isClassicControllerWindow]) {
        UNRecordWindow(window, @"classic chrome window, left alone");
        return;
    }
    if (![application respondsToSelector:@selector(_isClassic)] || ![application _isClassic]) {
        UNRecordWindow(window, @"app is not in classic mode, left alone");
        return;
    }
    if (![window respondsToSelector:@selector(_sceneReferenceBounds)]
        || ![window respondsToSelector:@selector(_convertPointToSceneReferenceSpace:)]
        || ![window respondsToSelector:@selector(_convertPointFromSceneReferenceSpace:)]) {
        UNRecordWindow(window, @"scene-reference conversions missing on this iOS version; not scaled");
        return;
    }

    transformLayer = UNTransformLayer(window);
    if (transformLayer == nil) {
        UNRecordWindow(window, @"no _transformLayer; not scaled");
        return;
    }
    if ([windowLayer superlayer] != transformLayer) {
        UNRecordWindow(window, @"window layer is not inside _transformLayer; not scaled");
        return;
    }
    if ([transformLayer superlayer] != nil && !UNLayerIsNeutral([transformLayer superlayer])) {
        UNRecordWindow(window, @"_transformLayer's parent moves or scales it; not scaled");
        return;
    }

    existing = [transformLayer transform];
    if (!UNIsAffineScaleTranslate(existing)) {
        /* Rotated (landscape) or otherwise unexpected: keep UIKit's. */
        UNRecordWindow(window, @"UIKit transform is rotated or non-affine; not scaled");
        return;
    }

    /* What UIKit currently does, for the report. */
    sourceRect = [window bounds];
    systemTopLeft = [window _convertPointToSceneReferenceSpace:sourceRect.origin];
    systemBottomRight = [window _convertPointToSceneReferenceSpace:
        CGPointMake(CGRectGetMaxX(sourceRect), CGRectGetMaxY(sourceRect))];
    sceneRect = [window _sceneReferenceBounds];

    if (!UNTransformMake(UNRectMake(sourceRect.origin.x, sourceRect.origin.y,
                                    sourceRect.size.width, sourceRect.size.height),
                         UNRectMake(sceneRect.origin.x, sceneRect.origin.y,
                                    sceneRect.size.width, sceneRect.size.height),
                         gMode, &target)) {
        UNRecordWindow(window, [NSString stringWithFormat:@"invalid geometry (window %@, scene %@); not scaled",
                                   UNRectString(sourceRect), UNRectString(sceneRect)]);
        return;
    }

    /* Window point p sits at contentOrigin + p inside the transform layer;
     * check that mapping is a plain translation. */
    contentOrigin = [transformLayer convertPoint:CGPointZero fromLayer:windowLayer];
    unitStep = [transformLayer convertPoint:CGPointMake(1, 1) fromLayer:windowLayer];
    if (fabs((double)(unitStep.x - contentOrigin.x) - 1.0) > 0.001
        || fabs((double)(unitStep.y - contentOrigin.y) - 1.0) > 0.001) {
        UNRecordWindow(window, @"window layer is scaled inside _transformLayer; not scaled");
        return;
    }

    layerBounds = [transformLayer bounds];
    anchorPoint = [transformLayer anchorPoint];
    if (!UNSolveRootLayerTransform(
            target,
            UNPointMake([transformLayer position].x, [transformLayer position].y),
            UNPointMake(layerBounds.origin.x + anchorPoint.x * layerBounds.size.width,
                        layerBounds.origin.y + anchorPoint.y * layerBounds.size.height),
            UNPointMake(contentOrigin.x, contentOrigin.y),
            &layerTransform)) {
        UNRecordWindow(window, @"could not solve layer transform; not scaled");
        return;
    }

    applied = CATransform3DIdentity;
    applied.m11 = (CGFloat)layerTransform.scaleX;
    applied.m22 = (CGFloat)layerTransform.scaleY;
    applied.m41 = (CGFloat)layerTransform.translateX;
    applied.m42 = (CGFloat)layerTransform.translateY;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [transformLayer setTransform:applied];
    [CATransaction commit];

    UNSetActiveTransform(window, &target);
    UNRecordWindow(window, [NSString stringWithFormat:
        @"SCALED %s. window %@ -> scene %@, scale %.3f x %.3f, offset %.1f,%.1f "
        @"(UIKit had: %.1f,%.1f to %.1f,%.1f, layer scale %.3f)",
        UNScaleModeName(gMode), UNRectString(sourceRect), UNRectString(sceneRect),
        target.scaleX, target.scaleY, target.translateX, target.translateY,
        (double)systemTopLeft.x, (double)systemTopLeft.y,
        (double)systemBottomRight.x, (double)systemBottomRight.y, (double)existing.m11]);
}

#pragma mark - Conversions (touch mapping)

static CGPoint UNMapFromScene(UNTransform t, CGPoint point)
{
    UNPoint mapped;
    UNTransformMapDestinationPointToSource(t, UNRectMake(0, 0, 1, 1), UNPointMake(point.x, point.y), &mapped);
    return CGPointMake((CGFloat)mapped.x, (CGFloat)mapped.y);
}

static CGPoint UNMapToScene(UNTransform t, CGPoint point)
{
    UNPoint mapped = UNTransformApplyToPoint(t, UNPointMake(point.x, point.y));
    return CGPointMake((CGFloat)mapped.x, (CGFloat)mapped.y);
}

%group UNClassicScaling

%hook UIWindow

- (void)_updateTransformLayerForClassicPresentation
{
    %orig;
    UNApplyClassicScaling(self);
}

- (void)_updateTransformLayerSizeForClassicPresentation
{
    %orig;
    UNApplyClassicScaling(self);
}

- (CGPoint)_convertPointFromSceneReferenceSpace:(CGPoint)point
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        gTouchConversions++;
        return UNMapFromScene(t, point);
    }
    return %orig;
}

- (CGPoint)_convertPointToSceneReferenceSpace:(CGPoint)point
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        gOtherConversions++;
        return UNMapToScene(t, point);
    }
    return %orig;
}

- (UNDoublePoint)_convertDoublePointFromSceneReferenceSpace:(UNDoublePoint)point
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        UNDoublePoint result;
        UNPoint mapped;
        gTouchConversions++;
        UNTransformMapDestinationPointToSource(t, UNRectMake(0, 0, 1, 1), UNPointMake(point.x, point.y), &mapped);
        result.x = mapped.x;
        result.y = mapped.y;
        return result;
    }
    return %orig;
}

- (UNDoublePoint)_convertDoublePointToSceneReferenceSpace:(UNDoublePoint)point
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        UNDoublePoint result;
        UNPoint mapped = UNTransformApplyToPoint(t, UNPointMake(point.x, point.y));
        gOtherConversions++;
        result.x = mapped.x;
        result.y = mapped.y;
        return result;
    }
    return %orig;
}

- (CGRect)_convertRectFromSceneReferenceSpace:(CGRect)rect
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        UNTransform inverse;
        if (UNTransformInvert(t, &inverse)) {
            UNRect mapped = UNTransformApplyToRect(inverse, UNRectMake(rect.origin.x, rect.origin.y,
                                                                       rect.size.width, rect.size.height));
            gOtherConversions++;
            return CGRectMake((CGFloat)mapped.x, (CGFloat)mapped.y,
                              (CGFloat)mapped.width, (CGFloat)mapped.height);
        }
    }
    return %orig;
}

- (CGRect)_convertRectToSceneReferenceSpace:(CGRect)rect
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        UNRect mapped = UNTransformApplyToRect(t, UNRectMake(rect.origin.x, rect.origin.y,
                                                             rect.size.width, rect.size.height));
        gOtherConversions++;
        return CGRectMake((CGFloat)mapped.x, (CGFloat)mapped.y,
                          (CGFloat)mapped.width, (CGFloat)mapped.height);
    }
    return %orig;
}

/* Offsets are vectors: scale only, no translation. */
- (CGPoint)_convertOffsetFromSceneReferenceSpace:(CGPoint)offset
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        gOtherConversions++;
        return CGPointMake((CGFloat)(offset.x / t.scaleX), (CGFloat)(offset.y / t.scaleY));
    }
    return %orig;
}

- (CGPoint)_convertOffsetToSceneReferenceSpace:(CGPoint)offset
{
    UNTransform t;
    if (UNGetActiveTransform(self, &t)) {
        gOtherConversions++;
        return CGPointMake((CGFloat)(offset.x * t.scaleX), (CGFloat)(offset.y * t.scaleY));
    }
    return %orig;
}

%end

%end

#pragma mark - Launch

static void UNRecordLaunch(void)
{
    UIApplication *application = [UIApplication sharedApplication];
    UIScreen *screen = [UIScreen mainScreen];
    NSString *classic = @"unknown (no -_isClassic)";

    if ([application respondsToSelector:@selector(_isClassic)]) {
        classic = [application _isClassic] ? @"yes" : @"no";
    }

    [gAppLines addObject:@"Unified loaded in this app."];
    [gAppLines addObject:[NSString stringWithFormat:@"Bundle ID: %@", gBundleIdentifier]];
    [gAppLines addObject:[NSString stringWithFormat:@"Device: %@, %@",
                             [[UIDevice currentDevice] model],
                             [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
                                 ? @"iPad idiom" : @"iPhone idiom"]];
    [gAppLines addObject:[NSString stringWithFormat:@"Classic (compatibility) mode: %@", classic]];
    [gAppLines addObject:[NSString stringWithFormat:@"Screen as the app sees it: %@ @%.0fx",
                             UNRectString([screen bounds]), (double)[screen scale]]];
    UNWriteDiagnostics();
}

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
         * "disabled": the safe outcome (and no diagnostics appear). */
        preferences = [UNPreferences preferencesWithContentsOfFile:UNPreferencesDefaultPath];
        decision = [preferences decisionForApp:bundleIdentifier];
        if (!decision.adapt) {
            return;
        }

        gMode = decision.mode;
        gBundleIdentifier = [bundleIdentifier copy];
        gWindowLines = [[NSMutableDictionary alloc] init];
        gAppLines = [[NSMutableArray alloc] init];

        NSLog(@"[Unified] enabled for %@ (mode: %s)", bundleIdentifier, UNScaleModeName(decision.mode));

        /* Hooks are installed only in apps the user switched on. */
        %init(UNClassicScaling);

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *notification) {
                        (void)notification;
                        UNRecordLaunch();
                    }];
    }
}
