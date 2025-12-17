#!/bin/bash
# Integration test script for Swift parity runner
# Tests that the runner executes correctly against fixture corpus

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="${TOOLS_DIR}/.build/debug/swift-parity-runner"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
OUTPUT_DIR="$SCRIPT_DIR/output"

echo "=== Swift Parity Runner Integration Tests ==="
echo ""

# Clean previous output
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Test 1: Verify binary exists and is executable
echo "[TEST 1] Verify binary is executable..."
if [ ! -x "$RUNNER" ]; then
    echo "❌ FAIL: Binary not found or not executable at $RUNNER"
    echo "   Run 'make build' first"
    exit 1
fi
echo "✅ PASS: Binary is executable"
echo ""

# Test 2: Help flag works
echo "[TEST 2] Test --help flag..."
if ! "$RUNNER" --help > /dev/null 2>&1; then
    echo "❌ FAIL: --help flag did not work"
    exit 1
fi
echo "✅ PASS: --help flag works"
echo ""

# Test 3: Missing required arguments fail gracefully
echo "[TEST 3] Test missing required arguments..."
if "$RUNNER" 2>/dev/null; then
    echo "❌ FAIL: Runner should fail without arguments"
    exit 1
fi
echo "✅ PASS: Missing arguments handled correctly"
echo ""

# Test 4: Run against fixture corpus (minimal 1-case corpus)
echo "[TEST 4] Run against fixture corpus..."
FIXTURE_CORPUS="$FIXTURES_DIR/fixture-corpus.json"
FIXTURE_REFERENCE="$FIXTURES_DIR/fixture-reference.json"

if [ ! -f "$FIXTURE_CORPUS" ]; then
    echo "⚠️  SKIP: Fixture corpus not found at $FIXTURE_CORPUS"
    echo "   Create fixtures to enable this test"
else
    if ! "$RUNNER" \
        --corpus "$FIXTURE_CORPUS" \
        --c-reference "$FIXTURE_REFERENCE" \
        --artifacts "$OUTPUT_DIR/fixture-run" \
        --run-id "integration-test-fixture"; then
        echo "❌ FAIL: Runner execution failed"
        exit 1
    fi
    
    # Verify output report exists
    REPORT="$OUTPUT_DIR/fixture-run/integration-test-fixture/report.json"
    if [ ! -f "$REPORT" ]; then
        echo "❌ FAIL: Report not generated at $REPORT"
        exit 1
    fi
    
    # Verify JSON is valid
    if ! python3 -m json.tool "$REPORT" > /dev/null 2>&1; then
        echo "❌ FAIL: Report is not valid JSON"
        exit 1
    fi
    
    echo "✅ PASS: Fixture corpus run succeeded"
fi
echo ""

# Test 5: Verify CLI options work
echo "[TEST 5] Test CLI options (case filter, pass gate)..."
CORPUS="$TOOLS_DIR/../../corpus/default.json"
REFERENCE="$TOOLS_DIR/../../artifacts/full-run-default/report.json"

if [ ! -f "$CORPUS" ] || [ ! -f "$REFERENCE" ]; then
    echo "⚠️  SKIP: Default corpus/reference not available"
else
    if ! "$RUNNER" \
        --corpus "$CORPUS" \
        --c-reference "$REFERENCE" \
        --artifacts "$OUTPUT_DIR/options-test" \
        --run-id "integration-test-options" \
        --cases "baseline-wheel" \
        --pass-gate 0.90; then
        echo "❌ FAIL: CLI options test failed"
        exit 1
    fi
    
    REPORT="$OUTPUT_DIR/options-test/integration-test-options/report.json"
    # Verify only 1 case was run (filtered by --cases)
    CASE_COUNT=$(python3 -c "import json; print(json.load(open('$REPORT'))['summary']['totalCases'])")
    if [ "$CASE_COUNT" != "1" ]; then
        echo "❌ FAIL: Case filter did not work (expected 1 case, got $CASE_COUNT)"
        exit 1
    fi
    
    echo "✅ PASS: CLI options work correctly"
fi
echo ""

echo "=== All Integration Tests Passed ✅ ==="
echo ""
echo "Test artifacts available in: $OUTPUT_DIR"
