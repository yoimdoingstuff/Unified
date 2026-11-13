# Unified - Theos build.
#
# One universal package for iOS 5-10: a single dylib with
#   armv7  (deployment target 5.0; also runs on armv7s devices)
#   arm64  (deployment target 7.0, the first 64-bit release; set below,
#           because the toolchain otherwise stamps this slice with 5.0)
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

TARGET ?= iphone:clang:10.3:5.0
ARCHS ?= armv7 arm64

# Cydia-era dpkg on iOS 8 may not understand xz/zstd-compressed packages.
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Unified

Unified_FILES = Tweak.x Sources/UNGeometry.c Sources/UNPolicy.c
Unified_CFLAGS = -ISources -Wall -Wextra -Wunguarded-availability
Unified_FRAMEWORKS = Foundation

# Theos compiles and links each architecture in its own pass with
# THEOS_CURRENT_ARCH set; the later -miphoneos-version-min wins.
ifeq ($(THEOS_CURRENT_ARCH),arm64)
Unified_CFLAGS += -miphoneos-version-min=7.0
Unified_LDFLAGS += -miphoneos-version-min=7.0
endif

include $(THEOS_MAKE_PATH)/tweak.mk
