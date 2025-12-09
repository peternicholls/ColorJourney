#!/bin/bash

# Script: package-swift.sh
# Purpose: Package Swift release artifact with include/exclude enforcement
# Usage: ./scripts/package-swift.sh <VERSION>
# Example: ./scripts/package-swift.sh 1.0.0

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: $0 <VERSION>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION="$1"
ARTIFACT_NAME="ColorJourney-${VERSION}"
ARTIFACT_FILE="${ARTIFACT_NAME}.tar.gz"

echo -e "${YELLOW}Packaging Swift release...${NC}"
echo "Version: $VERSION"
echo "Artifact: $ARTIFACT_FILE"
echo ""

# Verify required files exist
echo "Verifying required files..."
for required in "Sources/ColorJourney" "Package.swift" "README.md" "LICENSE" "CHANGELOG.md"; do
    if [ ! -e "$required" ]; then
        echo -e "${RED}Error: Required file not found: $required${NC}"
        exit 1
    fi
done

# Create temporary directory for artifact contents
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Staging artifact contents..."
mkdir -p "$TEMP_DIR/$ARTIFACT_NAME"

# Copy allowed files
echo "  • Swift sources (Sources/ColorJourney/)"
cp -r "Sources/ColorJourney/" "$TEMP_DIR/$ARTIFACT_NAME/Sources/ColorJourney/"

echo "  • Package files"
cp "Package.swift" "$TEMP_DIR/$ARTIFACT_NAME/"
[ -f "Package.resolved" ] && cp "Package.resolved" "$TEMP_DIR/$ARTIFACT_NAME/"

echo "  • Documentation"
cp "README.md" "$TEMP_DIR/$ARTIFACT_NAME/"
cp "LICENSE" "$TEMP_DIR/$ARTIFACT_NAME/"
cp "CHANGELOG.md" "$TEMP_DIR/$ARTIFACT_NAME/"

# Copy end-user docs (include Docs/, exclude DevDocs/)
if [ -d "Docs" ]; then
    echo "  • End-user documentation (Docs/)"
    cp -r "Docs/" "$TEMP_DIR/$ARTIFACT_NAME/Docs/"
fi

# Verify exclusions (should not be in artifact)
echo ""
echo "Verifying exclusions..."
FORBIDDEN_ITEMS=("DevDocs" "Sources/CColorJourney" "Dockerfile" "Makefile" ".github" "Tests/CColorJourneyTests" "Examples")
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
echo -e "${GREEN}✓ Swift artifact packaged successfully${NC}"
echo "  Artifact: $ARTIFACT_FILE"
echo "  Checksum: ${ARTIFACT_FILE}.sha256"
echo ""
echo "Next steps:"
echo "1. Upload artifact to GitHub release: $ARTIFACT_FILE"
echo "2. Attach checksum file: ${ARTIFACT_FILE}.sha256"
echo "3. Verify download and extraction work correctly"
