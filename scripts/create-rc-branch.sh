#!/bin/bash

# Script: create-rc-branch.sh
# Purpose: Create a release candidate branch from develop with proper naming
# Usage: ./scripts/create-rc-branch.sh <VERSION> [RC_NUMBER]
# Example: ./scripts/create-rc-branch.sh 1.0.0 1

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: $0 <VERSION> [RC_NUMBER]"
    echo "Example: $0 1.0.0 1"
    exit 1
fi

VERSION="$1"
RC_NUMBER="${2:-1}"

# Validate SemVer format (X.Y.Z)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid SemVer format: $VERSION${NC}"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
    exit 1
fi

# Validate RC number
if ! [[ "$RC_NUMBER" =~ ^[0-9]+$ ]] || [ "$RC_NUMBER" -lt 1 ]; then
    echo -e "${RED}Error: Invalid RC number: $RC_NUMBER${NC}"
    echo "RC number must be a positive integer (e.g., 1, 2, 3)"
    exit 1
fi

RC_BRANCH="release-candidate/${VERSION}-rc.${RC_NUMBER}"

echo -e "${YELLOW}Creating release candidate branch...${NC}"
echo "Version: $VERSION"
echo "RC Number: $RC_NUMBER"
echo "Branch: $RC_BRANCH"
echo ""

# Check if on develop branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "develop" ]; then
    echo -e "${YELLOW}Current branch: $CURRENT_BRANCH${NC}"
    echo "Switching to develop branch..."
    git checkout develop
fi

# Ensure develop is up to date
echo "Pulling latest from develop..."
git pull origin develop

# Check if RC branch already exists
if git rev-parse --verify "$RC_BRANCH" > /dev/null 2>&1; then
    echo -e "${RED}Error: RC branch already exists: $RC_BRANCH${NC}"
    exit 1
fi

# Create RC branch
echo "Creating branch: $RC_BRANCH"
git checkout -b "$RC_BRANCH"

# Push to remote
echo "Pushing branch to remote..."
git push -u origin "$RC_BRANCH"

echo -e "${GREEN}✓ RC branch created successfully: $RC_BRANCH${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor CI/CD pipeline on GitHub Actions"
echo "2. Review test results"
echo "3. If tests pass, promote to main with: ./scripts/tag-release.sh $VERSION"
echo "4. If tests fail, fix on this branch and run: ./scripts/increment-rc.sh $VERSION $((RC_NUMBER + 1))"
