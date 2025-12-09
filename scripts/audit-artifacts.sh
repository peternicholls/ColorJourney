#!/bin/bash

# Script: audit-artifacts.sh
# Purpose: Validate release artifacts contain only allowed files per FR-007/FR-008
# Usage: ./scripts/audit-artifacts.sh <ARTIFACT_FILE> <TYPE>
# Example: ./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Arguments missing${NC}"
    echo "Usage: $0 <ARTIFACT_FILE> <TYPE>"
    echo "Supported types: swift, c"
    echo "Example: $0 ColorJourney-1.0.0.tar.gz swift"
    exit 1
fi

ARTIFACT_FILE="$1"
ARTIFACT_TYPE="$2"

if [ ! -f "$ARTIFACT_FILE" ]; then
    echo -e "${RED}Error: Artifact file not found: $ARTIFACT_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Auditing release artifact...${NC}"
echo "File: $ARTIFACT_FILE"
echo "Type: $ARTIFACT_TYPE"
echo ""

# Create temporary extraction directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Extracting artifact..."
tar -xzf "$ARTIFACT_FILE" -C "$TEMP_DIR"

# List extracted contents
echo "Artifact contents:"
find "$TEMP_DIR" -type f | sed 's/^/  /' | sort

echo ""
echo "Performing audit checks..."

if [ "$ARTIFACT_TYPE" = "swift" ]; then
    echo "Swift artifact requirements (FR-007):"
    
    # Required items
    echo "  Required items:"
    REQUIRED_ITEMS=("Sources/ColorJourney" "Package.swift" "README.md" "LICENSE" "CHANGELOG.md")
    for item in "${REQUIRED_ITEMS[@]}"; do
        if find "$TEMP_DIR" -path "*/$item" -o -path "*/$item/*" | grep -q .; then
            echo "    ✓ $item"
        else
            echo -e "    ${RED}✗ Missing: $item${NC}"
        fi
    done
    
    # Forbidden items
    echo "  Forbidden items:"
    FORBIDDEN_ITEMS=("Sources/CColorJourney" "DevDocs" "Dockerfile" "Makefile" "Package.swift~" ".github" "Tests/CColorJourneyTests")
    HAS_FORBIDDEN=0
    for item in "${FORBIDDEN_ITEMS[@]}"; do
        if find "$TEMP_DIR" -path "*/$item" -o -path "*/$item/*" 2>/dev/null | grep -q .; then
            echo -e "    ${RED}✗ Found forbidden: $item${NC}"
            HAS_FORBIDDEN=1
        fi
    done
    if [ "$HAS_FORBIDDEN" = "0" ]; then
        echo "    ✓ No forbidden items"
    fi

elif [ "$ARTIFACT_TYPE" = "c" ]; then
    echo "C artifact requirements (FR-008):"
    
    # Required items
    echo "  Required items:"
    REQUIRED_ITEMS=("include" "lib" "README.md" "LICENSE" "CHANGELOG.md")
    for item in "${REQUIRED_ITEMS[@]}"; do
        if find "$TEMP_DIR" -name "$item" | grep -q .; then
            echo "    ✓ $item"
        else
            echo -e "    ${RED}✗ Missing: $item${NC}"
        fi
    done
    
    # Check for .a files
    if find "$TEMP_DIR" -name "*.a" | grep -q .; then
        echo "    ✓ Static libraries (.a)"
    else
        echo -e "    ${RED}✗ No static libraries found (.a)${NC}"
    fi
    
    # Forbidden items
    echo "  Forbidden items:"
    FORBIDDEN_ITEMS=("Package.swift" "Sources/ColorJourney" "DevDocs" "Dockerfile" "Makefile" ".github")
    HAS_FORBIDDEN=0
    for item in "${FORBIDDEN_ITEMS[@]}"; do
        if find "$TEMP_DIR" -path "*/$item" -o -path "*/$item/*" 2>/dev/null | grep -q .; then
            echo -e "    ${RED}✗ Found forbidden: $item${NC}"
            HAS_FORBIDDEN=1
        fi
    done
    if [ "$HAS_FORBIDDEN" = "0" ]; then
        echo "    ✓ No forbidden items"
    fi

fi

echo ""
echo -e "${GREEN}✓ Artifact audit complete${NC}"

# Additional validation: Check artifact size
ARTIFACT_SIZE=$(du -h "$ARTIFACT_FILE" | cut -f1)
echo ""
echo "Artifact statistics:"
echo "  Size: $ARTIFACT_SIZE"

# Count files by type
echo "  File breakdown:"
if [ "$ARTIFACT_TYPE" = "swift" ]; then
    SWIFT_FILES=$(find "$TEMP_DIR" -name "*.swift" | wc -l | tr -d ' ')
    H_FILES=$(find "$TEMP_DIR" -name "*.h" | wc -l | tr -d ' ')
    C_FILES=$(find "$TEMP_DIR" -name "*.c" | wc -l | tr -d ' ')
    MD_FILES=$(find "$TEMP_DIR" -name "*.md" | wc -l | tr -d ' ')
    echo "    Swift files: $SWIFT_FILES"
    echo "    C headers: $H_FILES"
    echo "    C sources: $C_FILES"
    echo "    Documentation: $MD_FILES"
elif [ "$ARTIFACT_TYPE" = "c" ]; then
    A_FILES=$(find "$TEMP_DIR" -name "*.a" | wc -l | tr -d ' ')
    H_FILES=$(find "$TEMP_DIR" -name "*.h" | wc -l | tr -d ' ')
    MD_FILES=$(find "$TEMP_DIR" -name "*.md" | wc -l | tr -d ' ')
    echo "    Static libraries: $A_FILES"
    echo "    Headers: $H_FILES"
    echo "    Documentation: $MD_FILES"
fi

# Check for common issues
echo ""
echo "Quality checks:"

# Check for temporary files
TEMP_FILES=$(find "$TEMP_DIR" -type f \( -name "*.swp" -o -name "*.tmp" -o -name "*~" -o -name ".DS_Store" \) | wc -l | tr -d ' ')
if [ "$TEMP_FILES" -gt 0 ]; then
    echo -e "  ${RED}✗ Found $TEMP_FILES temporary/cache files${NC}"
    find "$TEMP_DIR" -type f \( -name "*.swp" -o -name "*.tmp" -o -name "*~" -o -name ".DS_Store" \) | sed 's/^/    /'
else
    echo "  ✓ No temporary files"
fi

# Check for hidden files (excluding .gitkeep)
HIDDEN_FILES=$(find "$TEMP_DIR" -type f -name ".*" ! -name ".gitkeep" | wc -l | tr -d ' ')
if [ "$HIDDEN_FILES" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Found $HIDDEN_FILES hidden files${NC}"
else
    echo "  ✓ No unexpected hidden files"
fi

# Check for executable permissions on scripts
if [ "$ARTIFACT_TYPE" = "swift" ]; then
    EXECUTABLES=$(find "$TEMP_DIR" -type f -perm +111 ! -path "*/Docs/*" | wc -l | tr -d ' ')
    if [ "$EXECUTABLES" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠ Found $EXECUTABLES executable files (verify if intentional)${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Artifact validation complete${NC}"
