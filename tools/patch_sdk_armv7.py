#!/usr/bin/env python3
"""Add armv7-only Objective-C runtime exports missing from a trimmed SDK.

The theos/sdks iPhoneOS10.3.sdk libobjc.A.tbd has a single export section
shared by all architectures and omits the functions only 32-bit ARM uses
to send messages that return structs (CGRect, CGSize, ...):

    _objc_msgSend_stret, _objc_msgSendSuper_stret, _objc_msgSendSuper2_stret

The real libobjc exports these for armv7/armv7s on every iOS from 5 to 10;
only the stub file is incomplete. Linking armv7 code that calls a
struct-returning method (e.g. -[UIView frame]) then fails with
"Undefined symbols: _objc_msgSend_stret".

This script inserts an armv7/armv7s export section for them. It edits only
the .tbd text stub inside the SDK (no Apple binaries), is idempotent, and
does nothing if the symbols are already present.

Usage: patch_sdk_armv7.py <path/to/iPhoneOSX.Y.sdk>
"""

import os
import sys

SYMBOLS = ["_objc_msgSend_stret", "_objc_msgSendSuper_stret", "_objc_msgSendSuper2_stret"]
SECTION = (
    "  - archs:                [ armv7, armv7s ]\n"
    "    symbols:              [ " + ", ".join(SYMBOLS) + " ]\n"
)


def main(sdk):
    path = os.path.join(sdk, "usr", "lib", "libobjc.A.tbd")
    if not os.path.isfile(path):
        sys.exit("not found: %s" % path)

    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    if "_objc_msgSend_stret" in text:
        print("unchanged: %s already exports _objc_msgSend_stret" % path)
        return

    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.rstrip() == "exports:":
            lines.insert(i + 1, SECTION)
            break
    else:
        sys.exit("no top-level 'exports:' line in %s; format not recognised" % path)

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print("patched: %s (+ %s for armv7, armv7s)" % (path, ", ".join(SYMBOLS)))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: patch_sdk_armv7.py <path/to/iPhoneOSX.Y.sdk>")
    main(sys.argv[1])
