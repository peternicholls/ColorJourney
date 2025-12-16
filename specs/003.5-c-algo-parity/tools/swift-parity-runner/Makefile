# Swift Parity Runner Makefile
# Build and test Swift wrapper parity validation

.PHONY: build clean test run help

# Paths
SWIFT := swift
BUILD_DIR := .build
PACKAGE_PATH := .
BINARY_NAME := swift-parity-runner
BINARY_PATH := $(BUILD_DIR)/debug/$(BINARY_NAME)

# Default corpus and reference
CORPUS ?= ../../corpus/default.json
REFERENCE ?= ../../artifacts/full-run-default/report.json
ARTIFACTS ?= ../../artifacts/swift-parity
RUN_ID ?= swift-parity-$(shell date +%Y%m%d-%H%M%S)

help:
	@echo "Swift Parity Runner - Makefile targets:"
	@echo ""
	@echo "  build        - Build debug binary"
	@echo "  clean        - Remove build artifacts"
	@echo "  test         - Run Swift unit tests"
	@echo "  run          - Execute parity runner with default corpus"
	@echo "  run-edge     - Execute parity runner with edge cases corpus"
	@echo "  run-custom   - Execute with custom CORPUS, REFERENCE, ARTIFACTS"
	@echo ""
	@echo "Environment variables:"
	@echo "  CORPUS       - Path to corpus JSON (default: ../../corpus/default.json)"
	@echo "  REFERENCE    - Path to C reference report (default: ../../artifacts/full-run-default/report.json)"
	@echo "  ARTIFACTS    - Output directory (default: ../../artifacts/swift-parity)"
	@echo "  RUN_ID       - Custom run identifier (default: auto-generated)"
	@echo ""
	@echo "Examples:"
	@echo "  make run"
	@echo "  make run-edge"
	@echo "  make run-custom CORPUS=../../corpus/edge-cases.json REFERENCE=../../artifacts/full-run-edge/report.json"

build:
	@echo "Building Swift parity runner..."
	$(SWIFT) build -c debug --package-path $(PACKAGE_PATH)
	@echo "Build complete: $(BINARY_PATH)"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete"

test:
	@echo "Running Swift unit tests..."
	$(SWIFT) test --package-path $(PACKAGE_PATH)

run: build
	@echo "Running Swift parity with default corpus..."
	@if [ ! -f "$(CORPUS)" ]; then \
		echo "Error: Corpus not found at $(CORPUS)"; \
		exit 1; \
	fi
	@if [ ! -f "$(REFERENCE)" ]; then \
		echo "Error: Reference report not found at $(REFERENCE)"; \
		exit 1; \
	fi
	$(BINARY_PATH) \
		--corpus $(CORPUS) \
		--c-reference $(REFERENCE) \
		--artifacts $(ARTIFACTS) \
		--run-id $(RUN_ID)

run-edge: build
	@echo "Running Swift parity with edge cases corpus..."
	$(BINARY_PATH) \
		--corpus ../../corpus/edge-cases.json \
		--c-reference ../../artifacts/full-run-edge/report.json \
		--artifacts ../../artifacts/swift-parity-edge \
		--run-id swift-parity-edge-$(shell date +%Y%m%d-%H%M%S)

run-custom: build
	@echo "Running Swift parity with custom parameters..."
	@if [ ! -f "$(CORPUS)" ]; then \
		echo "Error: Corpus not found at $(CORPUS)"; \
		exit 1; \
	fi
	@if [ ! -f "$(REFERENCE)" ]; then \
		echo "Error: Reference report not found at $(REFERENCE)"; \
		exit 1; \
	fi
	$(BINARY_PATH) \
		--corpus $(CORPUS) \
		--c-reference $(REFERENCE) \
		--artifacts $(ARTIFACTS) \
		--run-id $(RUN_ID)

# Quick validation target (for CI/testing)
validate: build
	@echo "Validating Swift parity runner..."
	$(BINARY_PATH) --help
	@echo "Validation complete - binary is executable"
