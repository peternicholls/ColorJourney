#!/bin/bash

# Script: delete-rc-branch.sh
# Purpose: Delete a release candidate branch after promotion or abandonment
# Usage: ./scripts/delete-rc-branch.sh <VERSION> [RC_NUMBER]
# Example: ./scripts/delete-rc-branch.sh 1.0.0 1

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

RC_BRANCH="release-candidate/${VERSION}-rc.${RC_NUMBER}"

echo -e "${YELLOW}Deleting RC branch...${NC}"
echo "Branch: $RC_BRANCH"
echo ""

# Check if branch exists locally
if git rev-parse --verify "$RC_BRANCH" > /dev/null 2>&1; then
    echo "Deleting local branch: $RC_BRANCH"
    git branch -D "$RC_BRANCH"
fi

# Check if branch exists on remote
if git rev-parse --verify "origin/$RC_BRANCH" > /dev/null 2>&1; then
    echo "Deleting remote branch: $RC_BRANCH"
    git push origin --delete "$RC_BRANCH"
else
    echo -e "${YELLOW}Warning: Remote branch not found: origin/$RC_BRANCH${NC}"
fi

echo -e "${GREEN}✓ RC branch deleted: $RC_BRANCH${NC}"
echo ""
echo "Note: Branch deletion history is preserved in Git reflog"
echo "Release history is available via tags and CHANGELOG"
