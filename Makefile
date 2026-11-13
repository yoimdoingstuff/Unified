# Unified - Theos build.
#
# One universal package for iOS 5-10: a single dylib with
#   armv7  (deployment target 5.0; also runs on armv7s devices)
#   arm64  (deployment target 7.0, the first 64-bit release)
# Version differences are handled at runtime, never by separate builds.
#
# Build status: CI-built on Linux (see .github/workflows/ci.yml).
# Runtime: not yet tested on any device.
#
# SDK: iPhoneOS 10.3 from theos/sdks (has armv7 stubs). The theos/sdks 9.3
# SDK does NOT link armv7 here: its libSystem.tbd re-exports liblaunch,
# but liblaunch.tbd is missing from that SDK.
#
# The SDK is newer than the device, so -Wunguarded-availability flags any
# API newer than the deployment target that is used without a runtime check.
#
# Host unit tests do not use this file: run `make -C tests`.

# No deployment version in TARGET on purpose: Theos resolves it as
#   TARGET's 4th field > TARGET_OS_DEPLOYMENT_VERSION_<arch> > TARGET_OS_DEPLOYMENT_VERSION
# (theos makefiles/targets/_common/darwin_head.mk), so a version here would
# override the per-architecture value below.
TARGET ?= iphone:clang:10.3
TARGET_OS_DEPLOYMENT_VERSION = 5.0
TARGET_OS_DEPLOYMENT_VERSION_arm64 = 7.0
ARCHS ?= armv7 arm64

# Cydia-era dpkg on iOS 5-8 may not understand xz/zstd-compressed packages.
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Unified

Unified_FILES = Tweak.x Sources/UNGeometry.c Sources/UNPolicy.c Sources/UNPreferences.m
Unified_CFLAGS = -ISources -Wall -Wextra -Wunguarded-availability
Unified_FRAMEWORKS = Foundation UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

# Settings > Unified pane (needs PreferenceLoader on the device; its entry
# plist ships from layout/Library/PreferenceLoader/Preferences/).
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
