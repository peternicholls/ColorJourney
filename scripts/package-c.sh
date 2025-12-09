#!/bin/bash

# Script: package-c.sh
# Purpose: Package C release artifact with static library and headers
# Usage: ./scripts/package-c.sh <VERSION> [PLATFORM]
# Example: ./scripts/package-c.sh 1.0.0 macos

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: $0 <VERSION> [PLATFORM]"
    echo "Supported platforms: macos, linux, windows"
    echo "Example: $0 1.0.0 macos"
    exit 1
fi

VERSION="$1"
PLATFORM="${2:-linux}"

# Determine architecture
case "$PLATFORM" in
    macos)
        ARCH="universal"
        ;;
    linux)
        ARCH="x86_64"
        ;;
    windows)
        ARCH="x86_64"
        ;;
    *)
        echo -e "${RED}Error: Unsupported platform: $PLATFORM${NC}"
        echo "Supported: macos, linux, windows"
        exit 1
        ;;
esac

ARTIFACT_NAME="libcolorjourney-${VERSION}-${PLATFORM}-${ARCH}"
ARTIFACT_FILE="${ARTIFACT_NAME}.tar.gz"

echo -e "${YELLOW}Packaging C release...${NC}"
echo "Version: $VERSION"
echo "Platform: $PLATFORM"
echo "Artifact: $ARTIFACT_FILE"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Staging artifact contents..."
mkdir -p "$TEMP_DIR/$ARTIFACT_NAME/include"
mkdir -p "$TEMP_DIR/$ARTIFACT_NAME/lib"
mkdir -p "$TEMP_DIR/$ARTIFACT_NAME/docs"

# Copy headers
echo "  • Headers"
if [ -d "Sources/CColorJourney/include" ]; then
    cp -r "Sources/CColorJourney/include/"* "$TEMP_DIR/$ARTIFACT_NAME/include/"
else
    echo -e "${RED}Error: Headers directory not found${NC}"
    exit 1
fi

# Build C library (if not already built)
echo "  • Building C library for $PLATFORM..."
if [ ! -d "build" ]; then
    cmake -B build -DCMAKE_BUILD_TYPE=Release
fi
cmake --build build --config Release

# Copy static library
echo "  • Static library"
if [ -f "build/libcolorjourney.a" ]; then
    cp "build/libcolorjourney.a" "$TEMP_DIR/$ARTIFACT_NAME/lib/"
else
    echo -e "${YELLOW}Warning: Static library not found (build may have failed)${NC}"
fi

# Copy documentation
echo "  • Documentation"
cp "README.md" "$TEMP_DIR/$ARTIFACT_NAME/" 2>/dev/null || true
cp "LICENSE" "$TEMP_DIR/$ARTIFACT_NAME/" 2>/dev/null || true
cp "CHANGELOG.md" "$TEMP_DIR/$ARTIFACT_NAME/" 2>/dev/null || true

# Copy end-user docs (include Docs/, exclude DevDocs/)
if [ -d "Docs" ]; then
    echo "  • End-user documentation"
    cp -r "Docs/" "$TEMP_DIR/$ARTIFACT_NAME/docs/"
fi

# Verify exclusions (should not be in C artifact)
echo ""
echo "Verifying exclusions..."
FORBIDDEN_ITEMS=("DevDocs" "Sources/ColorJourney" "Dockerfile" "Makefile" ".github" "Package.swift")
for item in "${FORBIDDEN_ITEMS[@]}"; do
    if [ -e "$TEMP_DIR/$ARTIFACT_NAME/$item" ]; then
        echo -e "${RED}Error: Forbidden item in artifact: $item${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
done
echo "✓ No forbidden items detected"

# Create archive
echo ""
echo "Creating archive: $ARTIFACT_FILE"
cd "$TEMP_DIR"
tar -czf "$OLDPWD/$ARTIFACT_FILE" "$ARTIFACT_NAME/"
cd "$OLDPWD"

# Calculate checksum
echo "Calculating checksum..."
CHECKSUM=$(shasum -a 256 "$ARTIFACT_FILE" | awk '{print $1}')
echo "SHA256: $CHECKSUM"

# Create checksum file
echo "$CHECKSUM  $ARTIFACT_FILE" > "${ARTIFACT_FILE}.sha256"

echo ""
echo -e "${GREEN}✓ C artifact packaged successfully${NC}"
echo "  Artifact: $ARTIFACT_FILE"
echo "  Checksum: ${ARTIFACT_FILE}.sha256"
echo ""
echo "Next steps:"
echo "1. Upload artifact to GitHub release: $ARTIFACT_FILE"
echo "2. Attach checksum file: ${ARTIFACT_FILE}.sha256"
echo "3. Verify header files and library are present"
