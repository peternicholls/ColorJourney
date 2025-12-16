CC ?= cc
CFLAGS ?= -std=c99 -Wall -Wextra -pedantic -Iinclude -Ivendor/cjson -I../stats
LDFLAGS ?= -lm

SRC_LIB = src/json_validation.c src/compare.c src/exec.c src/report.c src/analysis.c src/stage_map.c ../stats/stats.c
SRC_BIN = src/main.c
VENDOR_SRC = vendor/cjson/cJSON.c

PARITY_RUNNER = parity-runner
UNIT_TEST = tests/unit_tests
INTEGRATION_TEST = tests/integration_tests
C_RUNNER = parity_c_runner
ALT_RUNNER = parity_wasm_as_c_runner

CANONICAL_SRC = ../../../../Tests/Parity/parity_c_runner.c ../../../../Sources/CColorJourney/ColorJourney.c src/json_validation.c vendor/cjson/cJSON.c
CANONICAL_INC = -Iinclude -Ivendor/cjson -I../../../../Sources/CColorJourney/include

ALT_SRC = ../../../../Tests/Parity/parity_wasm_as_c_runner.c ../../../../Sources/CColorJourney/ColorJourney.c src/json_validation.c vendor/cjson/cJSON.c
ALT_INC = -Iinclude -Ivendor/cjson -I../../../../Sources/CColorJourney/include

all: $(PARITY_RUNNER) $(C_RUNNER) $(ALT_RUNNER)

$(PARITY_RUNNER): $(SRC_LIB) $(SRC_BIN) $(VENDOR_SRC)
	$(CC) $(CFLAGS) $(SRC_LIB) $(SRC_BIN) $(VENDOR_SRC) -o $@ $(LDFLAGS)

$(C_RUNNER): $(CANONICAL_SRC)
	$(CC) $(CFLAGS) -DPARITY_BUILD_FLAGS='"$(CFLAGS)"' $(CANONICAL_INC) $(CANONICAL_SRC) -o $@ $(LDFLAGS)

$(ALT_RUNNER): $(ALT_SRC)
	$(CC) $(CFLAGS) -DPARITY_BUILD_FLAGS='"$(CFLAGS)"' $(ALT_INC) $(ALT_SRC) -o $@ $(LDFLAGS)

$(UNIT_TEST): tests/test_json_validation.c $(SRC_LIB) $(VENDOR_SRC) include/types.h
	$(CC) $(CFLAGS) tests/test_json_validation.c $(SRC_LIB) $(VENDOR_SRC) -o $@ $(LDFLAGS)

$(INTEGRATION_TEST): tests/test_integration.c $(PARITY_RUNNER)
	$(CC) $(CFLAGS) tests/test_integration.c -o $@ $(LDFLAGS)

test: $(PARITY_RUNNER) $(C_RUNNER) $(ALT_RUNNER) $(UNIT_TEST) $(INTEGRATION_TEST)
	./$(UNIT_TEST)
	./$(INTEGRATION_TEST)

clean:
	rm -f $(PARITY_RUNNER) $(UNIT_TEST) $(INTEGRATION_TEST) $(C_RUNNER) $(ALT_RUNNER)
	find . -name "*.o" -delete

.PHONY: all test clean
