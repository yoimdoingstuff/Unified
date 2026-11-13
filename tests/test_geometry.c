/*
 * Host unit tests for Sources/UNGeometry.c.
 *
 * Plain C99, no framework: build and run with `make -C tests`.
 * Exit status is 0 only if every check passed.
 */

#include "UNGeometry.h"

#include <math.h>
#include <stdio.h>

static int gChecks = 0;
static int gFailures = 0;

static bool nearlyEqual(double a, double b)
{
    double scale = fmax(1.0, fmax(fabs(a), fabs(b)));
    return fabs(a - b) <= 1e-9 * scale;
}

#define CHECK(cond)                                                              \
    do {                                                                         \
        gChecks++;                                                               \
        if (!(cond)) {                                                           \
            gFailures++;                                                         \
            fprintf(stderr, "%s:%d: CHECK failed: %s\n", __FILE__, __LINE__,     \
                    #cond);                                                      \
        }                                                                        \
    } while (0)

#define CHECK_NEAR(actual, expected)                                             \
    do {                                                                         \
        double _a = (actual);                                                    \
        double _e = (expected);                                                  \
        gChecks++;                                                               \
        if (!nearlyEqual(_a, _e)) {                                              \
            gFailures++;                                                         \
            fprintf(stderr, "%s:%d: %s == %.17g, expected %.17g\n", __FILE__,     \
                    __LINE__, #actual, _a, _e);                                  \
        }                                                                        \
    } while (0)

static void checkTransform(UNTransform t, double sx, double sy, double tx, double ty,
                           const char *label)
{
    int before = gFailures;
    CHECK_NEAR(t.scaleX, sx);
    CHECK_NEAR(t.scaleY, sy);
    CHECK_NEAR(t.translateX, tx);
    CHECK_NEAR(t.translateY, ty);
    if (gFailures != before) {
        fprintf(stderr, "  in case: %s\n", label);
    }
}

static void checkIsIdentity(UNTransform t)
{
    CHECK(t.scaleX == 1.0 && t.scaleY == 1.0);
    CHECK(t.translateX == 0.0 && t.translateY == 0.0);
}

/* outer contains inner, allowing tiny floating-point slack. */
static bool rectContains(UNRect outer, UNRect inner)
{
    const double eps = 1e-9 * fmax(1.0, fmax(outer.width, outer.height));
    return inner.x >= outer.x - eps && inner.y >= outer.y - eps
        && inner.x + inner.width <= outer.x + outer.width + eps
        && inner.y + inner.height <= outer.y + outer.height + eps;
}

/* ------------------------------------------------------------------------ */

static void testIPhoneOnIPadPortrait(void)
{
    UNRect src = UNRectMake(0, 0, 320, 480);
    UNRect dst = UNRectMake(0, 0, 768, 1024);
    UNTransform t;

    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));
    checkTransform(t, 1024.0 / 480.0, 1024.0 / 480.0, 128.0 / 3.0, 0.0, "iPhone->iPad fit");

    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    checkTransform(t, 2.4, 2.4, 0.0, -64.0, "iPhone->iPad fill");

    CHECK(UNTransformMake(src, dst, UNScaleModeStretch, &t));
    checkTransform(t, 2.4, 1024.0 / 480.0, 0.0, 0.0, "iPhone->iPad stretch");
}

static void testIPadOnIPhonePortrait(void)
{
    UNRect src = UNRectMake(0, 0, 768, 1024);
    UNRect dst = UNRectMake(0, 0, 320, 480);
    UNTransform t;

    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));
    checkTransform(t, 5.0 / 12.0, 5.0 / 12.0, 0.0, 80.0 / 3.0, "iPad->iPhone fit");

    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    checkTransform(t, 15.0 / 32.0, 15.0 / 32.0, -20.0, 0.0, "iPad->iPhone fill");

    CHECK(UNTransformMake(src, dst, UNScaleModeStretch, &t));
    checkTransform(t, 320.0 / 768.0, 480.0 / 1024.0, 0.0, 0.0, "iPad->iPhone stretch");
}

static void testLandscape(void)
{
    UNRect src = UNRectMake(0, 0, 480, 320);
    UNRect dst = UNRectMake(0, 0, 1024, 768);
    UNTransform t;

    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));
    checkTransform(t, 1024.0 / 480.0, 1024.0 / 480.0, 0.0, 128.0 / 3.0, "landscape fit");

    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    checkTransform(t, 2.4, 2.4, -64.0, 0.0, "landscape fill");
}

static void testEqualAspectRatioAllModesAgree(void)
{
    UNRect src = UNRectMake(0, 0, 320, 480);
    UNRect dst = UNRectMake(0, 0, 640, 960);
    UNScaleMode modes[] = { UNScaleModeFit, UNScaleModeFill, UNScaleModeStretch };
    size_t i;

    for (i = 0; i < sizeof(modes) / sizeof(modes[0]); i++) {
        UNTransform t;
        CHECK(UNTransformMake(src, dst, modes[i], &t));
        checkTransform(t, 2.0, 2.0, 0.0, 0.0, "equal aspect");
    }
}

static void testNonZeroOrigins(void)
{
    UNRect src = UNRectMake(10, 20, 100, 200);
    UNRect dst = UNRectMake(50, 60, 300, 300);
    UNTransform t;
    UNPoint p;

    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));
    checkTransform(t, 1.5, 1.5, 110.0, 30.0, "origins fit");

    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    checkTransform(t, 3.0, 3.0, 20.0, -150.0, "origins fill");

    CHECK(UNTransformMake(src, dst, UNScaleModeStretch, &t));
    checkTransform(t, 3.0, 1.5, 20.0, 30.0, "origins stretch");

    /* Stretch maps source corners exactly onto destination corners. */
    p = UNTransformApplyToPoint(t, UNPointMake(src.x, src.y));
    CHECK_NEAR(p.x, dst.x);
    CHECK_NEAR(p.y, dst.y);
    p = UNTransformApplyToPoint(t, UNPointMake(src.x + src.width, src.y + src.height));
    CHECK_NEAR(p.x, dst.x + dst.width);
    CHECK_NEAR(p.y, dst.y + dst.height);
}

static void testExtremeAspectRatios(void)
{
    UNRect tall = UNRectMake(0, 0, 1, 1000);
    UNRect wide = UNRectMake(0, 0, 1000, 1);
    UNTransform t;

    CHECK(UNTransformMake(tall, wide, UNScaleModeFit, &t));
    checkTransform(t, 0.001, 0.001, 499.9995, 0.0, "extreme fit");
    CHECK(UNTransformIsValid(t));

    CHECK(UNTransformMake(tall, wide, UNScaleModeFill, &t));
    checkTransform(t, 1000.0, 1000.0, 0.0, -499999.5, "extreme fill");

    CHECK(UNTransformMake(tall, wide, UNScaleModeStretch, &t));
    checkTransform(t, 1000.0, 0.001, 0.0, 0.0, "extreme stretch");
}

static void testInvalidInputsFailSafe(void)
{
    UNRect good = UNRectMake(0, 0, 320, 480);
    UNRect bad[] = {
        UNRectMake(0, 0, 0, 480),           /* zero width */
        UNRectMake(0, 0, 320, 0),           /* zero height */
        UNRectMake(0, 0, -320, 480),        /* negative width */
        UNRectMake(0, 0, 320, -480),        /* negative height */
        UNRectMake(NAN, 0, 320, 480),       /* NaN origin */
        UNRectMake(0, 0, INFINITY, 480),    /* infinite size */
        UNRectMake(0, 0, 320, NAN),         /* NaN size */
        UNRectMake(1e308, 0, 1e308, 1),     /* x + width overflows */
    };
    size_t i;
    UNTransform t;

    for (i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
        CHECK(!UNRectIsValid(bad[i]));

        t.scaleX = 99.0; /* make sure the output is overwritten */
        CHECK(!UNTransformMake(bad[i], good, UNScaleModeFit, &t));
        checkIsIdentity(t);

        t.scaleX = 99.0;
        CHECK(!UNTransformMake(good, bad[i], UNScaleModeFill, &t));
        checkIsIdentity(t);
    }

    /* Unknown mode. */
    t.scaleX = 99.0;
    CHECK(!UNTransformMake(good, good, (UNScaleMode)42, &t));
    checkIsIdentity(t);

    /* NULL output pointer must not crash. */
    CHECK(!UNTransformMake(good, good, UNScaleModeFit, NULL));
    CHECK(!UNTransformInvert(UNTransformIdentity, NULL));

    /* Scale overflow to infinity. */
    CHECK(!UNTransformMake(UNRectMake(0, 0, 1e-300, 1e-300), UNRectMake(0, 0, 1e300, 1e300),
                           UNScaleModeFit, &t));
    checkIsIdentity(t);

    /* Scale underflow to zero. */
    CHECK(!UNTransformMake(UNRectMake(0, 0, 1e300, 1e300), UNRectMake(0, 0, 1e-300, 1e-300),
                           UNScaleModeFit, &t));
    checkIsIdentity(t);
}

static void testInvert(void)
{
    UNTransform t;
    UNTransform inv;
    UNTransform bad = { 0.0, 1.0, 0.0, 0.0 };
    UNTransform negative = { -1.0, 1.0, 0.0, 0.0 };

    CHECK(UNTransformInvert(UNTransformIdentity, &inv));
    checkIsIdentity(inv);

    CHECK(UNTransformMake(UNRectMake(0, 0, 320, 480), UNRectMake(0, 0, 768, 1024),
                          UNScaleModeFill, &t));
    CHECK(UNTransformInvert(t, &inv));
    checkTransform(inv, 1.0 / 2.4, 1.0 / 2.4, 0.0, 64.0 / 2.4, "invert fill");

    inv.scaleX = 99.0;
    CHECK(!UNTransformInvert(bad, &inv));
    checkIsIdentity(inv);
    CHECK(!UNTransformInvert(negative, &inv));
}

/* Forward then inverse must return the original point for every mode. */
static void testRoundTrips(void)
{
    UNRect pairs[][2] = {
        { { 0, 0, 320, 480 }, { 0, 0, 768, 1024 } },
        { { 0, 0, 768, 1024 }, { 0, 0, 320, 480 } },
        { { 0, 0, 480, 320 }, { 0, 0, 1024, 768 } },
        { { 0, 0, 320, 568 }, { 0, 0, 1024, 768 } },
        { { 10, 20, 100, 200 }, { 50, 60, 300, 300 } },
        { { -40, 7.5, 375, 667 }, { 0, 20, 768, 1004 } },
    };
    UNScaleMode modes[] = { UNScaleModeFit, UNScaleModeFill, UNScaleModeStretch };
    size_t i, m, k;

    for (i = 0; i < sizeof(pairs) / sizeof(pairs[0]); i++) {
        UNRect src = pairs[i][0];
        UNRect dst = pairs[i][1];
        UNPoint points[7];

        points[0] = UNPointMake(src.x, src.y);
        points[1] = UNPointMake(src.x + src.width, src.y);
        points[2] = UNPointMake(src.x, src.y + src.height);
        points[3] = UNPointMake(src.x + src.width, src.y + src.height);
        points[4] = UNPointMake(src.x + src.width / 2, src.y + src.height / 2);
        points[5] = UNPointMake(src.x + src.width * 0.13, src.y + src.height * 0.87);
        points[6] = UNPointMake(src.x - 25, src.y + src.height + 33); /* outside */

        for (m = 0; m < sizeof(modes) / sizeof(modes[0]); m++) {
            UNTransform t;
            UNTransform inv;
            UNRect mapped;
            UNPoint centre;

            CHECK(UNTransformMake(src, dst, modes[m], &t));
            CHECK(UNTransformInvert(t, &inv));

            for (k = 0; k < sizeof(points) / sizeof(points[0]); k++) {
                UNPoint there = UNTransformApplyToPoint(t, points[k]);
                UNPoint back = UNTransformApplyToPoint(inv, there);
                CHECK_NEAR(back.x, points[k].x);
                CHECK_NEAR(back.y, points[k].y);
            }

            /* Centre always maps to centre. */
            centre = UNTransformApplyToPoint(t, points[4]);
            CHECK_NEAR(centre.x, dst.x + dst.width / 2);
            CHECK_NEAR(centre.y, dst.y + dst.height / 2);

            mapped = UNTransformApplyToRect(t, src);
            switch (modes[m]) {
            case UNScaleModeFit:
                /* Whole source visible, fills at least one axis exactly. */
                CHECK(rectContains(dst, mapped));
                CHECK(nearlyEqual(mapped.width, dst.width)
                      || nearlyEqual(mapped.height, dst.height));
                break;
            case UNScaleModeFill:
                /* Destination fully covered, matches at least one axis exactly. */
                CHECK(rectContains(mapped, dst));
                CHECK(nearlyEqual(mapped.width, dst.width)
                      || nearlyEqual(mapped.height, dst.height));
                break;
            case UNScaleModeStretch:
                CHECK_NEAR(mapped.x, dst.x);
                CHECK_NEAR(mapped.y, dst.y);
                CHECK_NEAR(mapped.width, dst.width);
                CHECK_NEAR(mapped.height, dst.height);
                break;
            }
        }
    }
}

static void testInputMapping(void)
{
    UNRect src = UNRectMake(0, 0, 320, 480);
    UNRect dst = UNRectMake(0, 0, 768, 1024);
    UNTransform t;
    UNPoint p;

    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));

    /* Centre tap. */
    CHECK(UNTransformMapDestinationPointToSource(t, src, UNPointMake(384, 512), &p));
    CHECK_NEAR(p.x, 160);
    CHECK_NEAR(p.y, 240);

    /* Tap in the left letterbox bar lands outside app content. */
    CHECK(!UNTransformMapDestinationPointToSource(t, src, UNPointMake(10, 500), &p));
    CHECK(p.x < 0.0);

    /* Tap on the content's top-left corner maps to source origin. Only the
     * mapped value is asserted: whether an exact-edge tap counts as inside
     * can flip on a one-ulp rounding difference. */
    (void)UNTransformMapDestinationPointToSource(t, src, UNPointMake(128.0 / 3.0, 0), &p);
    CHECK_NEAR(p.x, 0);
    CHECK_NEAR(p.y, 0);

    /* Taps near every screen corner of the content area. */
    {
        double left = 128.0 / 3.0 + 1.0;
        double right = 768.0 - 128.0 / 3.0 - 1.0;
        UNPoint corners[4];
        size_t i;
        corners[0] = UNPointMake(left, 1);
        corners[1] = UNPointMake(right, 1);
        corners[2] = UNPointMake(left, 1023);
        corners[3] = UNPointMake(right, 1023);
        for (i = 0; i < 4; i++) {
            CHECK(UNTransformMapDestinationPointToSource(t, src, corners[i], &p));
        }
    }

    /* Fill: on-screen points map inside the source (cropped region excluded). */
    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    (void)UNTransformMapDestinationPointToSource(t, src, UNPointMake(0, 0), &p);
    CHECK_NEAR(p.x, 0);
    CHECK_NEAR(p.y, 64.0 / 2.4);
    (void)UNTransformMapDestinationPointToSource(t, src, UNPointMake(768, 1024), &p);
    CHECK_NEAR(p.x, 320);
    CHECK_NEAR(p.y, (1024.0 + 64.0) / 2.4);
    CHECK(UNTransformMapDestinationPointToSource(t, src, UNPointMake(0.5, 0.5), &p));
    CHECK(UNTransformMapDestinationPointToSource(t, src, UNPointMake(767.5, 1023.5), &p));

    /* Invalid transform: fails and leaves the input point untouched. */
    {
        UNTransform bad = { 0.0, 1.0, 0.0, 0.0 };
        CHECK(!UNTransformMapDestinationPointToSource(bad, src, UNPointMake(5, 6), &p));
        CHECK(p.x == 5.0 && p.y == 6.0);
    }

    CHECK(!UNTransformMapDestinationPointToSource(t, src, UNPointMake(1, 1), NULL));
}

static void testIntersection(void)
{
    UNRect out;

    CHECK(UNRectIntersection(UNRectMake(0, 0, 10, 10), UNRectMake(5, 5, 10, 10), &out));
    CHECK_NEAR(out.x, 5);
    CHECK_NEAR(out.y, 5);
    CHECK_NEAR(out.width, 5);
    CHECK_NEAR(out.height, 5);

    CHECK(UNRectIntersection(UNRectMake(0, 0, 10, 10), UNRectMake(2, 3, 4, 5), &out));
    CHECK_NEAR(out.x, 2);
    CHECK_NEAR(out.width, 4);

    /* Touching edges only -> no positive-area overlap. */
    CHECK(!UNRectIntersection(UNRectMake(0, 0, 10, 10), UNRectMake(10, 0, 10, 10), &out));
    CHECK(out.width == 0.0 && out.height == 0.0);

    CHECK(!UNRectIntersection(UNRectMake(0, 0, 10, 10), UNRectMake(20, 20, 1, 1), &out));
    CHECK(!UNRectIntersection(UNRectMake(0, 0, 0, 10), UNRectMake(0, 0, 10, 10), &out));
}

static void testVisibleSourceRect(void)
{
    UNRect src = UNRectMake(0, 0, 320, 480);
    UNRect dst = UNRectMake(0, 0, 768, 1024);
    UNTransform t;
    UNRect visible;

    /* Fill crops top and bottom equally. */
    CHECK(UNTransformMake(src, dst, UNScaleModeFill, &t));
    CHECK(UNTransformVisibleSourceRect(t, src, dst, &visible));
    CHECK_NEAR(visible.x, 0);
    CHECK_NEAR(visible.y, 80.0 / 3.0);
    CHECK_NEAR(visible.width, 320);
    CHECK_NEAR(visible.height, 1280.0 / 3.0);

    /* Fit and Stretch show everything. */
    CHECK(UNTransformMake(src, dst, UNScaleModeFit, &t));
    CHECK(UNTransformVisibleSourceRect(t, src, dst, &visible));
    CHECK_NEAR(visible.width, 320);
    CHECK_NEAR(visible.height, 480);

    CHECK(UNTransformMake(src, dst, UNScaleModeStretch, &t));
    CHECK(UNTransformVisibleSourceRect(t, src, dst, &visible));
    CHECK_NEAR(visible.width, 320);
    CHECK_NEAR(visible.height, 480);

    /* Invalid destination. */
    CHECK(!UNTransformVisibleSourceRect(t, src, UNRectMake(0, 0, 0, 0), &visible));
}

int main(void)
{
    testIPhoneOnIPadPortrait();
    testIPadOnIPhonePortrait();
    testLandscape();
    testEqualAspectRatioAllModesAgree();
    testNonZeroOrigins();
    testExtremeAspectRatios();
    testInvalidInputsFailSafe();
    testInvert();
    testRoundTrips();
    testInputMapping();
    testIntersection();
    testVisibleSourceRect();

    if (gFailures != 0) {
        fprintf(stderr, "test_geometry: %d of %d checks FAILED\n", gFailures, gChecks);
        return 1;
    }
    printf("test_geometry: all %d checks passed\n", gChecks);
    return 0;
}
