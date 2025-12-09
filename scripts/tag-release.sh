#!/bin/bash

# Script: tag-release.sh
# Purpose: Promote RC to release by tagging on main
# Usage: ./scripts/tag-release.sh <VERSION>
# Example: ./scripts/tag-release.sh 1.0.0

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
TAG="v${VERSION}"

# Validate SemVer format (X.Y.Z)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid SemVer format: $VERSION${NC}"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
    exit 1
fi

echo -e "${YELLOW}Promoting release to main...${NC}"
echo "Version: $VERSION"
echo "Tag: $TAG"
echo ""

# Check if tag already exists
if git rev-parse --verify "$TAG" > /dev/null 2>&1; then
    echo -e "${RED}Error: Tag already exists: $TAG${NC}"
    exit 1
fi

# Switch to main
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Switching to main branch..."
git checkout main

# Pull latest
echo "Pulling latest from main..."
git pull origin main

# Merge RC branch (if coming from RC)
RC_BRANCH="release-candidate/${VERSION}-rc.1"
if git rev-parse --verify "origin/$RC_BRANCH" > /dev/null 2>&1; then
    echo "Merging RC branch: $RC_BRANCH"
    git merge --no-ff "origin/$RC_BRANCH" -m "Release $VERSION"
elif [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Note: No RC branch detected. Ensure main is up-to-date.${NC}"
fi

# Create annotated tag
echo "Creating tag: $TAG"
git tag -a "$TAG" -m "Release version $VERSION"

# Push tag
echo "Pushing tag to remote..."
git push origin "$TAG"

# Try to push main (may not have commits if already up-to-date)
echo "Pushing main branch..."
git push origin main || true

echo -e "${GREEN}✓ Release tagged successfully: $TAG${NC}"
echo ""
echo "Next steps:"
echo "1. Verify release on GitHub releases page"
echo "2. Wait for artifact generation workflow to complete"
echo "3. Verify badges update within 5 minutes"
echo "4. Clean up RC branch: ./scripts/delete-rc-branch.sh $VERSION"
