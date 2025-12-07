# Simple C build for ColorJourney
CC ?= cc
AR ?= ar
CFLAGS ?= -std=c99 -Wall -Wextra -O3 -ffast-math -I Sources/CColorJourney/include
BUILD_DIR := .build/gcc
SRC := Sources/CColorJourney/ColorJourney.c
OBJ := $(BUILD_DIR)/ColorJourney.o
STATIC_LIB := $(BUILD_DIR)/libcolorjourney.a
EXAMPLE_SRC := Examples/CExample.c
EXAMPLE_BIN := $(BUILD_DIR)/example
TEST_SRC := Tests/CColorJourneyTests/test_c_core.c
TEST_BIN := $(BUILD_DIR)/test_c_core

.PHONY: all lib example test-c clean

all: lib example

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ): $(SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(SRC) -o $(OBJ)

$(STATIC_LIB): $(OBJ)
	$(AR) rcs $(STATIC_LIB) $(OBJ)

lib: $(STATIC_LIB)

$(EXAMPLE_BIN): $(EXAMPLE_SRC) $(STATIC_LIB)
	$(CC) $(CFLAGS) $(EXAMPLE_SRC) $(STATIC_LIB) -lm -o $(EXAMPLE_BIN)

example: $(EXAMPLE_BIN)

$(TEST_BIN): $(TEST_SRC) $(STATIC_LIB)
	$(CC) $(CFLAGS) $(TEST_SRC) $(STATIC_LIB) -lm -o $(TEST_BIN)

test-c: $(TEST_BIN)
	$(TEST_BIN)

clean:
	rm -rf $(BUILD_DIR)
