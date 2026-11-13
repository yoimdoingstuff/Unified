/*
 * UNPolicy - decides whether Unified may act in the current process, and how.
 *
 * Status: implemented, host unit tests written (tests/test_policy.c).
 * Not yet run on a device.
 *
 * Plain C99 with no Foundation dependency, so it is host-testable. The
 * Objective-C side (Tweak.x) reads the preferences file, type-checks every
 * value, and passes plain C values in here.
 *
 * Safety rules encoded here:
 *  - Anything missing, malformed, or unknown means "do nothing".
 *  - An app is adapted only if Unified is enabled globally AND that app is
 *    explicitly enabled. There is no "all apps" switch.
 *  - SpringBoard and the Settings app are never eligible, so the device
 *    stays usable and Unified can always be switched off from Settings.
 *  - App extensions and non-app processes are never eligible.
 */

#ifndef UNIFIED_UNPOLICY_H
#define UNIFIED_UNPOLICY_H

#include <stdbool.h>

#include "UNGeometry.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * True when the process looks like a normal app that Unified may consider.
 * Both arguments may be NULL (treated as ineligible).
 *
 * executablePath must contain ".app/" and must not contain ".appex/".
 */
bool UNProcessIsEligible(const char *bundleIdentifier, const char *executablePath);

/* "fit", "fill", "stretch" (exact, lowercase). Returns false for anything else. */
bool UNScaleModeFromString(const char *string, UNScaleMode *outMode);

/* Lowercase name for logging; "invalid" for unknown values. Never NULL. */
const char *UNScaleModeName(UNScaleMode mode);

typedef struct {
    /* Already type-checked by the caller: true only for a real boolean true. */
    bool globalEnabled;
    bool appEnabled;
    /* May be NULL. Invalid strings are ignored. */
    const char *appMode;
    const char *defaultMode;
} UNPolicyInput;

typedef struct {
    bool adapt;
    UNScaleMode mode;
} UNPolicyDecision;

/*
 * adapt = globalEnabled && appEnabled.
 * mode  = appMode if valid, else defaultMode if valid, else Fit.
 * When adapt is false, mode is still filled in (Fit by default) but must be ignored.
 */
UNPolicyDecision UNPolicyDecide(UNPolicyInput input);

#ifdef __cplusplus
}
#endif

#endif /* UNIFIED_UNPOLICY_H */
