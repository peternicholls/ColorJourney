#!/bin/bash

# Script: tag-release.sh
# Purpose: Promote RC to release by tagging on main
# Usage: ./scripts/tag-release.sh <VERSION> [RC_BRANCH]
# Example: ./scripts/tag-release.sh 1.0.0

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ -z "${1:-}" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: $0 <VERSION> [RC_BRANCH]"
    echo "Example: $0 1.0.0 release-candidate/1.0.0-rc.2"
    exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
RC_BRANCH_OVERRIDE="${2:-}"

# Validate SemVer format (X.Y.Z)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid SemVer format: $VERSION${NC}"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
    exit 1
fi

echo -e "${YELLOW}Promoting release to main...${NC}"
echo "Version: $VERSION"
echo "Tag: $TAG"
if [ -n "$RC_BRANCH_OVERRIDE" ]; then
    echo "RC branch override: $RC_BRANCH_OVERRIDE"
fi
echo ""

# Ensure clean working tree
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}Error: Working tree is dirty. Commit or stash changes first.${NC}"
    exit 1
fi

# Determine RC branch (prefer override, otherwise highest rc.N on origin)
resolve_rc_branch() {
    if [ -n "$RC_BRANCH_OVERRIDE" ]; then
        echo "$RC_BRANCH_OVERRIDE"
        return 0
    fi

    echo "Resolving latest RC branch for $VERSION..."
    RC_CANDIDATES=$(git ls-remote --heads origin "release-candidate/${VERSION}-rc.*" | awk '{print $2}' | sed 's@refs/heads/@@' | sort -t'.' -k4,4n)
    if [ -z "$RC_CANDIDATES" ]; then
        echo -e "${RED}Error: No RC branches found for version $VERSION on origin${NC}"
        exit 1
    fi
    echo "$RC_CANDIDATES" | tail -n1
}

RC_BRANCH=$(resolve_rc_branch)
echo "Using RC branch: $RC_BRANCH"

# Check if tag already exists
if git rev-parse --verify "$TAG" > /dev/null 2>&1; then
    echo -e "${RED}Error: Tag already exists: $TAG${NC}"
    exit 1
fi

# Fetch latest refs
git fetch origin --tags

# Switch to main
echo "Switching to main branch..."
git checkout main

# Pull latest
echo "Pulling latest from origin/main..."
git pull --ff-only origin main

# Ensure RC branch is available locally
if ! git show-ref --verify --quiet "refs/remotes/origin/${RC_BRANCH}"; then
    echo -e "${RED}Error: RC branch not found on origin: ${RC_BRANCH}${NC}"
    exit 1
fi

echo "Merging RC branch: ${RC_BRANCH}"
git merge --no-ff -m "Merge branch '${RC_BRANCH}' for release ${VERSION}" "origin/${RC_BRANCH}"

# Create annotated tag
echo "Creating tag: $TAG"
git tag -a "$TAG" -m "Release version $VERSION"

# Push main branch first (keeps tag and origin/main aligned for release workflow)
echo "Pushing main branch..."
git push origin main || true

# Push tag after main is updated
echo "Pushing tag to remote..."
git push origin "$TAG"

echo -e "${GREEN}✓ Release tagged successfully: $TAG${NC}"
echo ""
echo "Next steps:"
echo "1. Verify release on GitHub releases page"
echo "2. Wait for artifact generation workflow to complete"
echo "3. Verify badges update within 5 minutes"
echo "4. Clean up RC branch: ./scripts/delete-rc-branch.sh $VERSION"
