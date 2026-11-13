#include "UNPolicy.h"

#include <stddef.h>
#include <string.h>

/*
 * Never adapted, even if a preferences file lists them:
 *  - SpringBoard: out of scope and the main crash risk (AGENTS.md).
 *  - Settings: keeps the Unified preference pane usable as a recovery path.
 */
static const char *const kExcludedBundleIdentifiers[] = {
    "com.apple.springboard",
    "com.apple.Preferences",
};

bool UNProcessIsEligible(const char *bundleIdentifier, const char *executablePath)
{
    size_t i;

    if (bundleIdentifier == NULL || bundleIdentifier[0] == '\0') {
        return false;
    }
    if (executablePath == NULL || executablePath[0] == '\0') {
        return false;
    }

    for (i = 0; i < sizeof(kExcludedBundleIdentifiers) / sizeof(kExcludedBundleIdentifiers[0]); i++) {
        if (strcmp(bundleIdentifier, kExcludedBundleIdentifiers[i]) == 0) {
            return false;
        }
    }

    /* App extensions live inside an app bundle, so check .appex first. */
    if (strstr(executablePath, ".appex/") != NULL) {
        return false;
    }
    if (strstr(executablePath, ".app/") == NULL) {
        return false;
    }

    return true;
}

bool UNScaleModeFromString(const char *string, UNScaleMode *outMode)
{
    if (string == NULL || outMode == NULL) {
        return false;
    }
    if (strcmp(string, "fit") == 0) {
        *outMode = UNScaleModeFit;
        return true;
    }
    if (strcmp(string, "fill") == 0) {
        *outMode = UNScaleModeFill;
        return true;
    }
    if (strcmp(string, "stretch") == 0) {
        *outMode = UNScaleModeStretch;
        return true;
    }
    return false;
}

const char *UNScaleModeName(UNScaleMode mode)
{
    switch (mode) {
    case UNScaleModeFit:
        return "fit";
    case UNScaleModeFill:
        return "fill";
    case UNScaleModeStretch:
        return "stretch";
    }
    return "invalid";
}

UNPolicyDecision UNPolicyDecide(UNPolicyInput input)
{
    UNPolicyDecision decision;
    UNScaleMode parsed;

    decision.adapt = input.globalEnabled && input.appEnabled;
    decision.mode = UNScaleModeFit;

    if (UNScaleModeFromString(input.appMode, &parsed)) {
        decision.mode = parsed;
    } else if (UNScaleModeFromString(input.defaultMode, &parsed)) {
        decision.mode = parsed;
    }

    return decision;
}
