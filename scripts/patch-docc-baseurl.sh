#!/bin/bash
# Patch Swift-DocC baseUrl to work from subdirectory

DOCC_DIR="$1"

if [ -z "$DOCC_DIR" ]; then
    DOCC_DIR="Docs/generated/swift-docc"
fi

if [ ! -f "$DOCC_DIR/index.html" ]; then
    echo "❌ Swift-DocC index.html not found at $DOCC_DIR/index.html"
    exit 1
fi

echo "🔧 Patching Swift-DocC baseUrl for serving from subdirectory..."

# Replace baseUrl in index.html
sed -i.bak 'var baseUrl = "/"' "var baseUrl = \"/generated/swift-docc/\"" "$DOCC_DIR/index.html"

if [ $? -eq 0 ]; then
    echo "✅ Patched baseUrl in $DOCC_DIR/index.html"
    echo "   Changed: var baseUrl = \"/\""
    echo "   To:      var baseUrl = \"/generated/swift-docc/\""
else
    echo "⚠️  Could not patch baseUrl. You may need to serve from Docs/generated/swift-docc/ directly"
fi
