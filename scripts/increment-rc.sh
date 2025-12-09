#!/bin/bash
#
# increment-rc.sh - Increment RC version and create new RC branch
#
# Usage:
#   ./scripts/increment-rc.sh [CURRENT_RC_BRANCH]
#
# Example:
#   ./scripts/increment-rc.sh release-candidate/1.0.0-rc.1
#   Creates:     release-candidate/1.0.0-rc.2
#   Merges from: develop
#
# This script handles the case where an RC fails CI and needs to be iterated.
# It increments the rc.N suffix and creates a new branch from develop.
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to print status messages
status_message() {
    echo -e "${GREEN}[RC INCREMENT]${NC} $1"
}

error_message() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning_message() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << 'EOF'
Usage: ./scripts/increment-rc.sh [CURRENT_RC_BRANCH]

Increments an RC branch version (rc.N suffix) and creates a new branch from develop.

Arguments:
  CURRENT_RC_BRANCH   - Current RC branch name (e.g., release-candidate/1.0.0-rc.1)
                        If omitted, uses current branch if it matches the RC pattern.

Examples:
  ./scripts/increment-rc.sh release-candidate/1.0.0-rc.1
    → Creates release-candidate/1.0.0-rc.2 from develop

  ./scripts/increment-rc.sh  # If currently on release-candidate/1.0.0-rc.1
    → Creates release-candidate/1.0.0-rc.2 from develop

Exit codes:
  0   Success
  1   Usage error
  2   Git operation failed
  3   Invalid RC branch format
EOF
}

# Parse arguments
CURRENT_RC_BRANCH="${1:-}"

if [[ -z "$CURRENT_RC_BRANCH" ]]; then
    # Try to use current branch
    CURRENT_RC_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ -z "$CURRENT_RC_BRANCH" ]]; then
        error_message "Not on a Git branch. Provide RC branch name as argument."
        show_usage
        exit 1
    fi
    status_message "Using current branch: $CURRENT_RC_BRANCH"
fi

# Validate RC branch format: release-candidate/X.Y.Z-rc.N
if ! [[ "$CURRENT_RC_BRANCH" =~ ^release-candidate/[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]]; then
    error_message "Invalid RC branch name: $CURRENT_RC_BRANCH"
    error_message "Expected format: release-candidate/X.Y.Z-rc.N (e.g., release-candidate/1.0.0-rc.1)"
    exit 3
fi

# Extract version and current rc number
VERSION_BASE="${CURRENT_RC_BRANCH#release-candidate/}"
VERSION_BASE="${VERSION_BASE%-rc.*}"
CURRENT_RC_NUM=$(echo "$CURRENT_RC_BRANCH" | sed -E 's/.*-rc\.([0-9]+)$/\1/')

# Calculate next rc number
NEXT_RC_NUM=$((CURRENT_RC_NUM + 1))
NEW_RC_BRANCH="release-candidate/${VERSION_BASE}-rc.${NEXT_RC_NUM}"

status_message "Current RC: $CURRENT_RC_BRANCH (rc.$CURRENT_RC_NUM)"
status_message "New RC:     $NEW_RC_BRANCH (rc.$NEXT_RC_NUM)"

# Verify we're in a git repo
cd "$REPO_ROOT"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error_message "Not in a Git repository"
    exit 2
fi

# Verify current branch matches the provided RC branch (if we're already on it)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "HEAD" ]]; then
    # Only warn if we're on a different branch
    if [[ "$CURRENT_BRANCH" != "$CURRENT_RC_BRANCH" ]]; then
        warning_message "Currently on branch: $CURRENT_BRANCH"
        warning_message "You'll need to switch branches for cleanup."
    fi
fi

# Ensure develop branch exists and is up to date
status_message "Checking develop branch..."
if ! git show-ref --quiet refs/heads/develop; then
    error_message "develop branch does not exist locally"
    exit 2
fi

# Create new RC branch from develop
status_message "Creating new RC branch from develop..."
git fetch origin develop 2>/dev/null || true
git checkout -b "$NEW_RC_BRANCH" origin/develop 2>/dev/null || git checkout -b "$NEW_RC_BRANCH" develop

if [[ $? -ne 0 ]]; then
    error_message "Failed to create new RC branch: $NEW_RC_BRANCH"
    exit 2
fi

status_message "Successfully created: $NEW_RC_BRANCH"

# Push to remote
status_message "Pushing new RC branch to remote..."
git push --set-upstream origin "$NEW_RC_BRANCH" || {
    error_message "Failed to push $NEW_RC_BRANCH to remote"
    exit 2
}

status_message "Successfully pushed: origin/$NEW_RC_BRANCH"

# Show next steps
cat << EOF

${GREEN}RC Increment Complete!${NC}

New RC branch created: ${GREEN}$NEW_RC_BRANCH${NC}

Next steps:
1. Push commits to the new RC branch:
   git commit -am "Fix: <issue description>"
   git push

2. Monitor CI for the new RC:
   https://github.com/peternicholls/ColorJourney/actions

3. Once all checks pass, promote to main:
   ./scripts/tag-release.sh ${VERSION_BASE}

4. Clean up old RC branch (optional):
   git push origin --delete ${CURRENT_RC_BRANCH}
   git branch -d ${CURRENT_RC_BRANCH}

If you need to iterate further, run this script again:
   ./scripts/increment-rc.sh ${NEW_RC_BRANCH}

EOF

exit 0
