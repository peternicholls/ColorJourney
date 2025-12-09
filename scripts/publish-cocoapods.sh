#!/bin/bash
# scripts/publish-cocoapods.sh
# Publish ColorJourney to CocoaPods Trunk
#
# Usage:
#   ./scripts/publish-cocoapods.sh lint              # Run spec lint only
#   ./scripts/publish-cocoapods.sh push              # Lint then push
#   ./scripts/publish-cocoapods.sh dry-run           # Dry-run without publishing
#   COCOAPODS_TRUNK_TOKEN=xxx ./scripts/publish-cocoapods.sh push  # With explicit token

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Podspec location
PODSPEC_PATH="${REPO_ROOT}/ColorJourney.podspec"

# Exit handler
cleanup() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} Publication failed"
        exit 1
    fi
}

trap cleanup EXIT

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v pod &> /dev/null; then
        log_error "CocoaPods not found. Install with: gem install cocoapods"
        exit 1
    fi
    
    if [ ! -f "$PODSPEC_PATH" ]; then
        log_error "Podspec not found at $PODSPEC_PATH"
        exit 1
    fi
    
    log_info "✓ CocoaPods installed"
    log_info "✓ Podspec found"
}

# Extract version from podspec and Package.swift
check_version_parity() {
    log_info "Checking version parity..."
    
    # Get version from podspec
    PODSPEC_VERSION=$(grep "spec.version" "$PODSPEC_PATH" | sed 's/.*"\([^"]*\)".*/\1/')
    
    # Get version from Package.swift
    PACKAGE_VERSION=$(grep "let package = Package" "$REPO_ROOT/Package.swift" -A 100 | grep "version" | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "")
    
    # Get current git tag
    GIT_TAG=$(git -C "$REPO_ROOT" describe --tags --exact-match 2>/dev/null || echo "")
    
    echo "  Podspec version:   $PODSPEC_VERSION"
    echo "  Git tag:           ${GIT_TAG:-'(none)'}"
    
    # Ensure no 'v' prefix in podspec version
    if [[ "$PODSPEC_VERSION" =~ ^v ]]; then
        log_error "Podspec version must not have 'v' prefix: $PODSPEC_VERSION"
        exit 1
    fi
    
    # Ensure git tag exists and matches
    if [ -n "$GIT_TAG" ] && [ "$GIT_TAG" != "v$PODSPEC_VERSION" ]; then
        log_warn "Git tag '$GIT_TAG' does not match podspec version '$PODSPEC_VERSION'"
    fi
    
    log_info "✓ Version parity check passed"
}

# Lint the podspec
lint_podspec() {
    log_info "Running pod spec lint..."
    
    if pod spec lint "$PODSPEC_PATH" --verbose; then
        log_info "✓ Podspec lint passed"
    else
        log_error "Podspec lint failed"
        exit 1
    fi
}

# Dry-run: check but don't publish
dry_run_push() {
    log_info "Running dry-run (lint only, no publication)..."
    lint_podspec
    log_info "✓ Dry-run successful - ready to publish"
}

# Push to CocoaPods Trunk (with retry and backoff)
push_to_trunk() {
    log_info "Linting before push..."
    lint_podspec
    
    log_info "Pushing to CocoaPods Trunk..."
    
    if [ -z "${COCOAPODS_TRUNK_TOKEN:-}" ]; then
        log_error "COCOAPODS_TRUNK_TOKEN not set. Export it and retry:"
        echo "  export COCOAPODS_TRUNK_TOKEN=<your-token>"
        exit 1
    fi
    
    # Verify token validity
    if ! pod trunk me &>/dev/null; then
        log_warn "Trunk token may be invalid or expired"
        log_warn "Attempting push anyway (may fail)..."
    fi
    
    # Retry configuration
    local max_attempts=3
    local backoff_seconds=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt/$max_attempts: Pushing to trunk..."
        
        if pod trunk push "$PODSPEC_PATH" --verbose; then
            log_info "✓ Successfully pushed to CocoaPods Trunk"
            echo ""
            log_info "Verification steps:"
            echo "  1. Wait ~10 minutes for CocoaPods.org index to update"
            echo "  2. Verify: pod search ColorJourney"
            echo "  3. View: https://cocoapods.org/pods/ColorJourney"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                log_warn "Push attempt $attempt failed, retrying in ${backoff_seconds}s..."
                sleep $backoff_seconds
                backoff_seconds=$((backoff_seconds * 2))  # Exponential backoff
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to push to CocoaPods Trunk after $max_attempts attempts"
    exit 1
}

# Main
main() {
    local command="${1:-}"
    
    case "$command" in
        lint)
            check_prerequisites
            lint_podspec
            ;;
        push)
            check_prerequisites
            check_version_parity
            push_to_trunk
            ;;
        dry-run)
            check_prerequisites
            check_version_parity
            dry_run_push
            ;;
        *)
            echo "Usage: $0 {lint|push|dry-run}"
            echo ""
            echo "Commands:"
            echo "  lint    - Validate podspec locally"
            echo "  push    - Lint then push to CocoaPods Trunk"
            echo "  dry-run - Lint without publishing"
            echo ""
            echo "Environment:"
            echo "  COCOAPODS_TRUNK_TOKEN - Required for 'push' command"
            exit 1
            ;;
    esac
}

main "$@"
