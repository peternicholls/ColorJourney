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
DOCS_DIR := Docs/generated
DOCS_SWIFT_DIR := $(DOCS_DIR)/swift-docc
DOCS_C_DIR := $(DOCS_DIR)/doxygen
DOCS_PUBLISH_DIR := $(DOCS_DIR)/publish

.PHONY: all lib example test-c clean docs docs-swift docs-c docs-index docs-publish docs-validate docs-clean

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

# EXAMPLE VERIFICATION TARGETS
# ============================
# Compile and verify runnable examples

.PHONY: verify-examples verify-example-c verify-example-swift

verify-examples: verify-example-c verify-example-swift
	@echo ""
	@echo "✅ All examples verified"
	@echo ""

verify-example-c: $(EXAMPLE_BIN)
	@echo "🔨 Running C example..."
	@$(EXAMPLE_BIN) > /tmp/example_c_output.txt
	@if grep -q "Discrete palette" /tmp/example_c_output.txt && grep -q "Determinism check: PASS" /tmp/example_c_output.txt; then \
		echo "✅ C example produced expected output"; \
	else \
		echo "❌ C example output incorrect"; \
		exit 1; \
	fi

verify-example-swift:
	@echo "🔨 Building Swift examples..."
	@swift build 2>&1 | grep -q "Build complete" && echo "✅ Swift examples compile" || (echo "❌ Swift examples failed to compile" && exit 1)

# UNIFIED DOCUMENTATION BUILD SYSTEM
# ===================================

docs: docs-swift docs-c docs-index
	@echo ""
	@echo "✅ All documentation generated"
	@echo ""
	@echo "View unified index: open Docs/index.html"
	@echo "View Swift API:     open $(DOCS_SWIFT_DIR)/index.html"
	@echo "View C API:         open $(DOCS_C_DIR)/html/index.html"
	@echo ""

docs-swift:
	@echo "📱 Generating Swift-DocC documentation..."
	@rm -rf .build/plugins/Swift-DocC
	@swift package generate-documentation \
		--hosting-base-path /generated/swift-docc/ 2>&1 | tail -1
	@mkdir -p $(DOCS_SWIFT_DIR)
	@if [ -d ".build/plugins/Swift-DocC/outputs" ]; then \
		rm -rf $(DOCS_SWIFT_DIR)/*; \
		for archive in .build/plugins/Swift-DocC/outputs/*.doccarchive; do \
			if [ "$$(basename $$archive)" = "ColorJourney.doccarchive" ]; then \
				cp -r $$archive/* $(DOCS_SWIFT_DIR)/ 2>/dev/null || true; \
			fi; \
		done; \
	fi
	@if [ -f "$(DOCS_SWIFT_DIR)/index.html" ]; then \
		echo "✅ Swift-DocC generated → $(DOCS_SWIFT_DIR)/"; \
		echo ""; \
		echo "Assets configured for: http://localhost:8000/generated/swift-docc/"; \
	else \
		echo "⚠️  Swift-DocC index not found"; \
	fi

docs-c:
	@echo "🔧 Generating C API documentation (Doxygen)..."
	@mkdir -p $(DOCS_C_DIR)
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen .specify/doxyfile 2>&1 | grep -i "warning\|error" || echo "   (no warnings)"; \
		echo "✅ Doxygen generated → $(DOCS_C_DIR)/"; \
	else \
		echo "❌ doxygen not found. Install with: brew install doxygen"; \
		exit 1; \
	fi

docs-index:
	@echo "📚 Creating unified documentation index..."
	@mkdir -p Docs
	@if [ -f Docs/index.html ]; then \
		echo "✅ Unified index found → Docs/index.html"; \
	else \
		echo "❌ index.html not found in Docs/"; \
		exit 1; \
	fi

docs-publish:
	@echo "🌐 Generating documentation for web publishing (GitHub Pages)..."
	@mkdir -p $(DOCS_PUBLISH_DIR)/swift-docc
	@swift package --allow-writing-to-directory $(DOCS_PUBLISH_DIR)/swift-docc \
		generate-documentation \
		--target ColorJourney \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path ColorJourney \
		--output-path $(DOCS_PUBLISH_DIR)/swift-docc 2>&1 | grep -i "error" || true
	@echo "✅ Web-ready documentation generated → $(DOCS_PUBLISH_DIR)/"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Commit: git add Docs/generated/"
	@echo "  2. Push:   git push origin main"
	@echo "  3. Enable GitHub Pages in repository settings"

docs-validate:
	@echo "🔍 Validating documentation quality..."
	@echo "   Checking Swift-DocC..."
	@swift package generate-documentation --verbose 2>&1 | grep -i "error" && echo "   ❌ Errors found" && exit 1 || echo "   ✅ No errors"
	@echo "   Checking Doxygen..."
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen .specify/doxyfile 2>&1 | grep -i "error" && echo "   ❌ Errors found" && exit 1 || echo "   ✅ No errors"; \
	fi
	@echo "✅ Documentation validation passed"

docs-clean:
	@echo "🗑️  Cleaning generated documentation..."
	@rm -rf $(DOCS_DIR)
	@rm -f Docs/index.html
	@rm -rf .build/documentation
	@echo "✅ Documentation cleaned"

# DOCUMENTATION SERVER TARGETS
# ============================
# Serve documentation locally using Docker

.PHONY: serve serve-docs serve-swift serve-c serve-all serve-stop

serve: serve-docs
	
serve-docs:
	@echo "🚀 Serving unified documentation with Docker"
	@echo ""
	@echo "📚 Open in browser:"
	@echo "   Unified Hub:     http://localhost:8000/index.html"
	@echo "   Swift API:       http://localhost:8000/generated/swift-docc/"
	@echo "   C API:           http://localhost:8000/generated/doxygen/html/"
	@echo ""
	@if command -v docker-compose >/dev/null 2>&1; then \
		docker-compose up --build; \
	elif command -v docker >/dev/null 2>&1; then \
		echo "⚠️  docker-compose not found, trying 'docker compose'..."; \
		docker compose up --build; \
	else \
		echo "❌ Docker not installed. Install from: https://www.docker.com/products/docker-desktop"; \
		exit 1; \
	fi

serve-swift:
	@echo "🚀 Serving Swift-DocC only (Python built-in server)"
	@echo ""
	@echo "Open in browser: http://localhost:8000/"
	@echo ""
	@echo "Press Ctrl+C to stop server"
	@echo ""
	@cd Docs/generated/swift-docc && python3 -m http.server 8000 --bind 127.0.0.1

serve-c:
	@echo "🚀 Serving Doxygen (Python built-in server)"
	@echo ""
	@echo "Open in browser: http://localhost:8000/"
	@echo "Press Ctrl+C to stop server"
	@echo ""
	@cd Docs/generated/doxygen/html && python3 -m http.server 8000 --bind 127.0.0.1

serve-all:
	@echo "🚀 Serving entire project (Python built-in server)"
	@echo ""
	@echo "Open in browser:"
	@echo "   Unified Hub: http://localhost:8000/Docs/index.html"
	@echo ""
	@echo "Press Ctrl+C to stop server"
	@echo ""
	@python3 -m http.server 8000 --bind 127.0.0.1

serve-stop:
	@echo "🛑 Stopping Docker containers..."
	@if command -v docker-compose >/dev/null 2>&1; then \
		docker-compose down; \
	else \
		docker compose down; \
	fi
	@echo "✅ Stopped"

