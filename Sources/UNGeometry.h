/*
 * UNGeometry - display-mode geometry for Unified.
 *
 * Status: implemented, host unit tests written (tests/test_geometry.c).
 * Not yet integrated with UIKit or exercised on a device.
 *
 * This module is deliberately plain C99 with no UIKit, Foundation, or
 * CoreGraphics dependency so it can be unit-tested on a build host and
 * compiled unchanged into the tweak. Values are doubles; callers convert
 * to/from CGFloat (float on 32-bit ARM, double on 64-bit).
 *
 * Model
 * -----
 * A UNTransform is an axis-aligned scale followed by a translation:
 *
 *     x' = x * scaleX + translateX
 *     y' = y * scaleY + translateY
 *
 * This maps one-to-one onto CGAffineTransformMake(scaleX, 0, 0, scaleY,
 * translateX, translateY). Rotation and flips are intentionally out of
 * scope: orientation has to be handled by whoever supplies the source and
 * destination rectangles, and both scales are always strictly positive.
 *
 * Source and destination rectangles share one coordinate convention
 * (UIKit's: origin top-left, y grows downward), but this module does not
 * depend on which corner is the origin as long as both rects agree.
 *
 * Alignment: in every mode the centre of the source rectangle maps to the
 * centre of the destination rectangle.
 */

#ifndef UNIFIED_UNGEOMETRY_H
#define UNIFIED_UNGEOMETRY_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    double x;
    double y;
} UNPoint;

typedef struct {
    double x;
    double y;
    double width;
    double height;
} UNRect;

typedef enum {
    /* Uniform scale, whole source visible, unused destination space possible. */
    UNScaleModeFit = 0,
    /* Uniform scale, destination fully covered, source may be cropped. */
    UNScaleModeFill = 1,
    /* Independent X/Y scale, destination exactly covered, aspect may change. */
    UNScaleModeStretch = 2
} UNScaleMode;

typedef struct {
    double scaleX;
    double scaleY;
    double translateX;
    double translateY;
} UNTransform;

extern const UNTransform UNTransformIdentity;

static inline UNPoint UNPointMake(double x, double y)
{
    UNPoint p;
    p.x = x;
    p.y = y;
    return p;
}

static inline UNRect UNRectMake(double x, double y, double width, double height)
{
    UNRect r;
    r.x = x;
    r.y = y;
    r.width = width;
    r.height = height;
    return r;
}

/* True when every component is finite and width and height are > 0. */
bool UNRectIsValid(UNRect rect);

/* True when every component is finite and both scales are > 0. */
bool UNTransformIsValid(UNTransform transform);

/*
 * Compute the transform that maps `source` into `destination` for `mode`.
 *
 * Returns false (and writes UNTransformIdentity to *outTransform) when
 * either rect is invalid, the mode is unknown, or the result would not be
 * finite / would have a zero scale. Callers must treat false as "do not
 * adapt this app" rather than applying the identity as if it were valid.
 */
bool UNTransformMake(UNRect source, UNRect destination, UNScaleMode mode,
                     UNTransform *outTransform);

/* Inverse transform. Returns false for an invalid transform or non-finite result. */
bool UNTransformInvert(UNTransform transform, UNTransform *outInverse);

UNPoint UNTransformApplyToPoint(UNTransform transform, UNPoint point);

/* Valid only for a valid transform (positive scales keep width/height positive). */
UNRect UNTransformApplyToRect(UNTransform transform, UNRect rect);

/*
 * Overlap of two rects. Returns false (and writes a zero rect) when they do
 * not overlap with positive area. Rects that only touch along an edge do not
 * count as overlapping.
 */
bool UNRectIntersection(UNRect a, UNRect b, UNRect *outIntersection);

/*
 * Input mapping: convert a point in destination (screen) space back into
 * the app's source coordinate space using the inverse of `transform`.
 *
 * *outSourcePoint receives the mapped point whenever the transform is
 * invertible, even if it lands outside the source content (e.g. a tap in a
 * Fit-mode letterbox bar). The return value is true only when the mapped
 * point lies inside `sourceContent`, edges inclusive. Callers decide what
 * to do with touches that land outside; this module does not clamp.
 */
bool UNTransformMapDestinationPointToSource(UNTransform transform, UNRect sourceContent,
                                            UNPoint destinationPoint,
                                            UNPoint *outSourcePoint);

/*
 * The part of `source` that is visible inside `destination` after applying
 * `transform`, in source coordinates. For Fit and Stretch this is the whole
 * source; for Fill it is the uncropped region. Returns false if nothing is
 * visible or the transform is invalid.
 */
bool UNTransformVisibleSourceRect(UNTransform transform, UNRect source, UNRect destination,
                                  UNRect *outVisibleSource);

#ifdef __cplusplus
}
#endif

#endif /* UNIFIED_UNGEOMETRY_H */
