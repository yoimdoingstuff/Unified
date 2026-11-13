# UnifiedPrefs.bundle - the Settings > Unified pane (loaded by PreferenceLoader).
# Same universal build settings as the tweak; see the root Makefile.

TARGET ?= iphone:clang:10.3
TARGET_OS_DEPLOYMENT_VERSION = 5.0
TARGET_OS_DEPLOYMENT_VERSION_arm64 = 7.0
ARCHS ?= armv7 arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = UnifiedPrefs

UnifiedPrefs_FILES = UNRootListController.m UNAppListController.m UNAppSettingsController.m \
	../Sources/UNPreferences.m ../Sources/UNAppCatalog.m ../Sources/UNPolicy.c
UnifiedPrefs_INSTALL_PATH = /Library/PreferenceBundles
UnifiedPrefs_FRAMEWORKS = UIKit Foundation
UnifiedPrefs_PRIVATE_FRAMEWORKS = Preferences
UnifiedPrefs_CFLAGS = -I../Sources -Wall -Wextra -Wunguarded-availability

include $(THEOS_MAKE_PATH)/bundle.mk
