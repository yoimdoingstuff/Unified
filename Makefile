# Unified - Theos build. NOT yet verified: no build has been run.
#
# First target: iPad mini 1st gen (armv7), iOS 8.4.1.
# The deployment target will be lowered towards 5.0 once a toolchain that
# builds armv7 for iOS 5 is confirmed (see docs/DEVELOPMENT.md).
#
# The SDK must still contain armv7 stubs; iPhoneOS 9.3 from theos/sdks is
# what CI uses. Override on the command line to try another.
#
# Host unit tests do not use this file: run `make -C tests`.

TARGET ?= iphone:clang:9.3:8.0
ARCHS ?= armv7

# Cydia-era dpkg on iOS 8 may not understand xz/zstd-compressed packages.
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Unified

Unified_FILES = Tweak.x Sources/UNGeometry.c Sources/UNPolicy.c
Unified_CFLAGS = -ISources -Wall -Wextra
Unified_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
