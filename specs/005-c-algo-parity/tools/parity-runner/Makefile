CC ?= cc
CFLAGS ?= -std=c99 -Wall -Wextra -pedantic -Iinclude -Ivendor/cjson
LDFLAGS ?= -lm

SRC_LIB = src/json_validation.c src/compare.c
SRC_BIN = src/main.c
VENDOR_SRC = vendor/cjson/cJSON.c

PARITY_RUNNER = parity-runner
UNIT_TEST = tests/unit_tests
INTEGRATION_TEST = tests/integration_tests

all: $(PARITY_RUNNER)

$(PARITY_RUNNER): $(SRC_LIB) $(SRC_BIN) $(VENDOR_SRC)
	$(CC) $(CFLAGS) $(SRC_LIB) $(SRC_BIN) $(VENDOR_SRC) -o $@ $(LDFLAGS)

$(UNIT_TEST): tests/test_json_validation.c $(SRC_LIB) $(VENDOR_SRC) include/types.h
	$(CC) $(CFLAGS) tests/test_json_validation.c $(SRC_LIB) $(VENDOR_SRC) -o $@ $(LDFLAGS)

$(INTEGRATION_TEST): tests/test_integration.c $(PARITY_RUNNER)
	$(CC) $(CFLAGS) tests/test_integration.c -o $@ $(LDFLAGS)

test: $(PARITY_RUNNER) $(UNIT_TEST) $(INTEGRATION_TEST)
	./$(UNIT_TEST)
	./$(INTEGRATION_TEST)

clean:
	rm -f $(PARITY_RUNNER) $(UNIT_TEST) $(INTEGRATION_TEST)
	find . -name "*.o" -delete

.PHONY: all test clean
