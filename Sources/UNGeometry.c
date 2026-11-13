#include "UNGeometry.h"

#include <math.h>
#include <stddef.h>

const UNTransform UNTransformIdentity = { 1.0, 1.0, 0.0, 0.0 };

static const UNRect UNRectZero = { 0.0, 0.0, 0.0, 0.0 };

bool UNRectIsValid(UNRect rect)
{
    return isfinite(rect.x) && isfinite(rect.y)
        && isfinite(rect.width) && isfinite(rect.height)
        && rect.width > 0.0 && rect.height > 0.0
        && isfinite(rect.x + rect.width) && isfinite(rect.y + rect.height);
}

bool UNTransformIsValid(UNTransform transform)
{
    return isfinite(transform.scaleX) && isfinite(transform.scaleY)
        && isfinite(transform.translateX) && isfinite(transform.translateY)
        && transform.scaleX > 0.0 && transform.scaleY > 0.0;
}

bool UNTransformMake(UNRect source, UNRect destination, UNScaleMode mode,
                     UNTransform *outTransform)
{
    UNTransform result;
    double ratioX;
    double ratioY;
    double sourceCentreX;
    double sourceCentreY;
    double destinationCentreX;
    double destinationCentreY;

    if (outTransform == NULL) {
        return false;
    }
    *outTransform = UNTransformIdentity;

    if (!UNRectIsValid(source) || !UNRectIsValid(destination)) {
        return false;
    }

    ratioX = destination.width / source.width;
    ratioY = destination.height / source.height;

    switch (mode) {
    case UNScaleModeFit:
        result.scaleX = result.scaleY = fmin(ratioX, ratioY);
        break;
    case UNScaleModeFill:
        result.scaleX = result.scaleY = fmax(ratioX, ratioY);
        break;
    case UNScaleModeStretch:
        result.scaleX = ratioX;
        result.scaleY = ratioY;
        break;
    default:
        return false;
    }

    /* Centre the scaled source on the destination: centre(src) * s + t == centre(dst). */
    sourceCentreX = source.x + source.width / 2.0;
    sourceCentreY = source.y + source.height / 2.0;
    destinationCentreX = destination.x + destination.width / 2.0;
    destinationCentreY = destination.y + destination.height / 2.0;

    result.translateX = destinationCentreX - sourceCentreX * result.scaleX;
    result.translateY = destinationCentreY - sourceCentreY * result.scaleY;

    /* Catches overflow to inf and underflow of a ratio to zero. */
    if (!UNTransformIsValid(result)) {
        return false;
    }

    *outTransform = result;
    return true;
}

bool UNTransformInvert(UNTransform transform, UNTransform *outInverse)
{
    UNTransform inverse;

    if (outInverse == NULL) {
        return false;
    }
    *outInverse = UNTransformIdentity;

    if (!UNTransformIsValid(transform)) {
        return false;
    }

    /* x = (x' - t) / s  =>  scale 1/s, translate -t/s */
    inverse.scaleX = 1.0 / transform.scaleX;
    inverse.scaleY = 1.0 / transform.scaleY;
    inverse.translateX = -transform.translateX / transform.scaleX;
    inverse.translateY = -transform.translateY / transform.scaleY;

    if (!UNTransformIsValid(inverse)) {
        return false;
    }

    *outInverse = inverse;
    return true;
}

UNPoint UNTransformApplyToPoint(UNTransform transform, UNPoint point)
{
    return UNPointMake(point.x * transform.scaleX + transform.translateX,
                       point.y * transform.scaleY + transform.translateY);
}

UNRect UNTransformApplyToRect(UNTransform transform, UNRect rect)
{
    return UNRectMake(rect.x * transform.scaleX + transform.translateX,
                      rect.y * transform.scaleY + transform.translateY,
                      rect.width * transform.scaleX,
                      rect.height * transform.scaleY);
}

bool UNRectIntersection(UNRect a, UNRect b, UNRect *outIntersection)
{
    double minX;
    double minY;
    double maxX;
    double maxY;

    if (outIntersection == NULL) {
        return false;
    }
    *outIntersection = UNRectZero;

    if (!UNRectIsValid(a) || !UNRectIsValid(b)) {
        return false;
    }

    minX = fmax(a.x, b.x);
    minY = fmax(a.y, b.y);
    maxX = fmin(a.x + a.width, b.x + b.width);
    maxY = fmin(a.y + a.height, b.y + b.height);

    if (!(maxX > minX) || !(maxY > minY)) {
        return false;
    }

    *outIntersection = UNRectMake(minX, minY, maxX - minX, maxY - minY);
    return true;
}

bool UNTransformMapDestinationPointToSource(UNTransform transform, UNRect sourceContent,
                                            UNPoint destinationPoint,
                                            UNPoint *outSourcePoint)
{
    UNPoint mapped;

    if (outSourcePoint == NULL) {
        return false;
    }
    *outSourcePoint = destinationPoint;

    if (!UNTransformIsValid(transform)) {
        return false;
    }

    /* Divide directly rather than multiplying by a precomputed reciprocal:
     * one rounding step instead of two keeps edge taps closer to exact. */
    mapped = UNPointMake((destinationPoint.x - transform.translateX) / transform.scaleX,
                         (destinationPoint.y - transform.translateY) / transform.scaleY);
    *outSourcePoint = mapped;

    if (!UNRectIsValid(sourceContent) || !isfinite(mapped.x) || !isfinite(mapped.y)) {
        return false;
    }

    return mapped.x >= sourceContent.x && mapped.x <= sourceContent.x + sourceContent.width
        && mapped.y >= sourceContent.y && mapped.y <= sourceContent.y + sourceContent.height;
}

bool UNSolveRootLayerTransform(UNTransform target, UNPoint layerPosition, UNPoint layerAnchor,
                               UNPoint contentOrigin, UNTransform *outLayerTransform)
{
    UNTransform result;

    if (outLayerTransform == NULL) {
        return false;
    }
    *outLayerTransform = UNTransformIdentity;

    if (!UNTransformIsValid(target)
        || !isfinite(layerPosition.x) || !isfinite(layerPosition.y)
        || !isfinite(layerAnchor.x) || !isfinite(layerAnchor.y)
        || !isfinite(contentOrigin.x) || !isfinite(contentOrigin.y)) {
        return false;
    }

    result.scaleX = target.scaleX;
    result.scaleY = target.scaleY;
    result.translateX = target.translateX - layerPosition.x
                      - target.scaleX * (contentOrigin.x - layerAnchor.x);
    result.translateY = target.translateY - layerPosition.y
                      - target.scaleY * (contentOrigin.y - layerAnchor.y);

    if (!UNTransformIsValid(result)) {
        return false;
    }
    *outLayerTransform = result;
    return true;
}

bool UNTransformVisibleSourceRect(UNTransform transform, UNRect source, UNRect destination,
                                  UNRect *outVisibleSource)
{
    UNTransform inverse;
    UNRect destinationInSource;

    if (outVisibleSource == NULL) {
        return false;
    }
    *outVisibleSource = UNRectZero;

    if (!UNTransformInvert(transform, &inverse) || !UNRectIsValid(destination)) {
        return false;
    }

    destinationInSource = UNTransformApplyToRect(inverse, destination);
    return UNRectIntersection(source, destinationInSource, outVisibleSource);
}
