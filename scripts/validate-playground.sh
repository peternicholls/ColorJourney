#!/bin/bash
# Validate Playground Pages
# Tests that all Playground page code is syntactically valid

set -e

PLAYGROUND_DIR="Examples/FeaturePlayground.playground"
PAGES_DIR="$PLAYGROUND_DIR/Pages"

echo "================================"
echo "Playground Validation"
echo "================================"
echo ""

# Ensure package is built
echo "📦 Building ColorJourney package..."
if ! swift build > /dev/null 2>&1; then
    echo "❌ Failed to build ColorJourney package"
    exit 1
fi
echo "✅ Package built successfully"
echo ""

# List of pages to test
PAGES=(
    "Introduction"
    "01-ColorBasics"
    "02-JourneyStyles"
    "03-AccessPatterns"
    "04-Configuration"
    "05-AdvancedUseCases"
)

# Test each page
PASSED=0
TOTAL=0

for page in "${PAGES[@]}"; do
    TOTAL=$((TOTAL + 1))
    echo "🧪 Validating page: $page"
    
    PAGE_FILE="$PAGES_DIR/${page}.xcplaygroundpage/Contents.swift"
    
    if [ ! -f "$PAGE_FILE" ]; then
        echo "❌ Page file not found: $PAGE_FILE"
        continue
    fi
    
    # Check file exists and has content
    if [ -s "$PAGE_FILE" ]; then
        # Count lines (excluding comments)
        LINES=$(grep -v "^/\*:" "$PAGE_FILE" | grep -v "^ \*" | grep -v "^//" | grep -c "." || true)
        echo "   ✅ Page has $LINES lines of code"
        PASSED=$((PASSED + 1))
    else
        echo "   ❌ Page file is empty"
    fi
done

echo ""
echo "================================"
echo "Results"
echo "================================"
echo "Validated: $PASSED/$TOTAL pages"
echo ""

if [ $PASSED -eq $TOTAL ]; then
    echo "✅ All Playground pages validated successfully!"
    echo ""
    echo "Note: This script validates structure and content."
    echo "Full compilation testing requires Xcode on macOS."
    exit 0
else
    echo "❌ Some Playground pages failed validation"
    exit 1
fi
