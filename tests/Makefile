# Host-side unit tests. Independent of Theos and the iOS SDK.
#
#   make -C tests            build and run all tests for this host
#   make -C tests clean
#   make -C tests EXTRA_CFLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all"
#
# The Objective-C tests (test_preferences) need Foundation, so they only
# build on macOS.

CC ?= cc
CFLAGS = -std=c99 -Wall -Wextra -Wpedantic -Wshadow -Werror -O1 -g
# Manual retain/release, matching the tweak (iOS 5 compatible).
OBJCFLAGS = -fno-objc-arc -Wall -Wextra -Wshadow -Werror -O1 -g
SOURCES_DIR = ../Sources
BUILD_DIR = build

GEOMETRY_BIN = $(BUILD_DIR)/test_geometry
POLICY_BIN = $(BUILD_DIR)/test_policy
PREFERENCES_BIN = $(BUILD_DIR)/test_preferences

TEST_BINS = $(GEOMETRY_BIN) $(POLICY_BIN)
ifeq ($(shell uname -s),Darwin)
TEST_BINS += $(PREFERENCES_BIN)
endif

.PHONY: test clean

test: $(TEST_BINS)
	@for t in $(TEST_BINS); do echo "== $$t"; ./$$t || exit 1; done

$(GEOMETRY_BIN): test_geometry.c $(SOURCES_DIR)/UNGeometry.c $(SOURCES_DIR)/UNGeometry.h
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -I$(SOURCES_DIR) test_geometry.c $(SOURCES_DIR)/UNGeometry.c -o $@ -lm

$(POLICY_BIN): test_policy.c $(SOURCES_DIR)/UNPolicy.c $(SOURCES_DIR)/UNPolicy.h $(SOURCES_DIR)/UNGeometry.h
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -I$(SOURCES_DIR) test_policy.c $(SOURCES_DIR)/UNPolicy.c -o $@

$(PREFERENCES_BIN): test_preferences.m $(SOURCES_DIR)/UNPreferences.m $(SOURCES_DIR)/UNPreferences.h \
		$(SOURCES_DIR)/UNAppCatalog.m $(SOURCES_DIR)/UNAppCatalog.h $(SOURCES_DIR)/UNPolicy.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(OBJCFLAGS) $(EXTRA_CFLAGS) -I$(SOURCES_DIR) test_preferences.m \
		$(SOURCES_DIR)/UNPreferences.m $(SOURCES_DIR)/UNAppCatalog.m $(SOURCES_DIR)/UNPolicy.c \
		-framework Foundation -o $@

clean:
	rm -rf $(BUILD_DIR)
