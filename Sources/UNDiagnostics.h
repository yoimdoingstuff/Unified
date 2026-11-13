/*
 * Shared names for the per-app diagnostics report.
 *
 * The tweak writes the report inside the app's own container (the only
 * place a sandboxed app may write). The Settings pane, which runs in
 * Preferences.app, reads it from there and shows it under
 * Settings > Unified > <app> > Diagnostics.
 *
 * The report is a property list of plain strings and numbers. It contains
 * geometry and state only: no app content, no identifiers beyond the
 * bundle ID, nothing sent anywhere (docs/SECURITY.md).
 */

#ifndef UNIFIED_UNDIAGNOSTICS_H
#define UNIFIED_UNDIAGNOSTICS_H

/* Relative to the app's home directory (its data container). */
#define UNDiagnosticsRelativePath @"Library/Caches/com.yoimdoingstuff.unified.diagnostics.plist"

/* Top-level keys. */
#define UNDiagnosticsKeyUpdated @"Updated"        /* NSString, local time */
#define UNDiagnosticsKeySystem @"iOS"             /* NSString */
#define UNDiagnosticsKeyUnifiedVersion @"Unified" /* NSString */
#define UNDiagnosticsKeyMode @"Mode"              /* NSString */
#define UNDiagnosticsKeyApp @"App"                /* NSArray of NSString lines */
#define UNDiagnosticsKeyWindows @"Windows"        /* NSArray of NSString lines */
#define UNDiagnosticsKeyTouches @"Touches"        /* NSArray of NSString lines */

#endif /* UNIFIED_UNDIAGNOSTICS_H */
