# Host-side unit tests. Independent of Theos and the iOS SDK.
#
#   make -C tests            build and run all tests
#   make -C tests clean
#   make -C tests EXTRA_CFLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all"

CC ?= cc
CFLAGS = -std=c99 -Wall -Wextra -Wpedantic -Wshadow -Werror -O1 -g
SOURCES_DIR = ../Sources
BUILD_DIR = build

GEOMETRY_BIN = $(BUILD_DIR)/test_geometry
POLICY_BIN = $(BUILD_DIR)/test_policy

.PHONY: test clean

test: $(GEOMETRY_BIN) $(POLICY_BIN)
	./$(GEOMETRY_BIN)
	./$(POLICY_BIN)

$(GEOMETRY_BIN): test_geometry.c $(SOURCES_DIR)/UNGeometry.c $(SOURCES_DIR)/UNGeometry.h
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -I$(SOURCES_DIR) test_geometry.c $(SOURCES_DIR)/UNGeometry.c -o $@ -lm

$(POLICY_BIN): test_policy.c $(SOURCES_DIR)/UNPolicy.c $(SOURCES_DIR)/UNPolicy.h $(SOURCES_DIR)/UNGeometry.h
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -I$(SOURCES_DIR) test_policy.c $(SOURCES_DIR)/UNPolicy.c -o $@

clean:
	rm -rf $(BUILD_DIR)
