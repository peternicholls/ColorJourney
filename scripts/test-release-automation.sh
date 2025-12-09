#!/bin/bash

# Test suite: Release automation scripts
# Purpose: Validate that release scripts work correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="/tmp/colorjourney-release-tests"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}ColorJourney Release Script Tests${NC}"
echo "=================================="
echo ""

# Create test directory
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
trap "rm -rf $TEST_DIR" EXIT

# Test 1: create-rc-branch.sh validation
test_rc_branch_creation() {
    echo -e "${YELLOW}Test 1: RC Branch Creation${NC}"
    
    # Test with invalid version
    if "$SCRIPT_DIR/scripts/create-rc-branch.sh" "invalid" 2>/dev/null; then
        echo -e "${RED}✗ Should reject invalid SemVer${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Rejects invalid SemVer format${NC}"
    
    # Test with invalid RC number
    if "$SCRIPT_DIR/scripts/create-rc-branch.sh" "1.0.0" "0" 2>/dev/null; then
        echo -e "${RED}✗ Should reject RC number 0${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Rejects invalid RC number${NC}"
    
    # Test help message
    if ! "$SCRIPT_DIR/scripts/create-rc-branch.sh" 2>&1 | grep -q "Usage"; then
        echo -e "${RED}✗ Should show usage on missing args${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Shows usage for missing arguments${NC}"
    echo ""
}

# Test 2: tag-release.sh validation
test_tag_release() {
    echo -e "${YELLOW}Test 2: Release Tagging${NC}"
    
    # Test with invalid version
    if "$SCRIPT_DIR/scripts/tag-release.sh" "invalid" 2>/dev/null; then
        echo -e "${RED}✗ Should reject invalid SemVer${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Rejects invalid SemVer format${NC}"
    
    # Test help message
    if ! "$SCRIPT_DIR/scripts/tag-release.sh" 2>&1 | grep -q "Usage"; then
        echo -e "${RED}✗ Should show usage on missing args${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Shows usage for missing arguments${NC}"
    echo ""
}

# Test 3: delete-rc-branch.sh validation
test_delete_rc_branch() {
    echo -e "${YELLOW}Test 3: RC Branch Deletion${NC}"
    
    # Test with invalid version
    if "$SCRIPT_DIR/scripts/delete-rc-branch.sh" "invalid" 2>/dev/null; then
        echo -e "${RED}✗ Should reject invalid SemVer${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Rejects invalid SemVer format${NC}"
    echo ""
}

# Test 4: package-swift.sh validation
test_package_swift() {
    echo -e "${YELLOW}Test 4: Swift Packaging${NC}"
    
    # Test with missing version
    if "$SCRIPT_DIR/scripts/package-swift.sh" 2>&1 | grep -q "Error"; then
        echo -e "${GREEN}✓ Shows error for missing version${NC}"
    else
        echo -e "${RED}✗ Should error on missing version${NC}"
        return 1
    fi
    
    echo ""
}

# Test 5: package-c.sh validation
test_package_c() {
    echo -e "${YELLOW}Test 5: C Packaging${NC}"
    
    # Test with missing version
    if "$SCRIPT_DIR/scripts/package-c.sh" 2>&1 | grep -q "Error"; then
        echo -e "${GREEN}✓ Shows error for missing version${NC}"
    else
        echo -e "${RED}✗ Should error on missing version${NC}"
        return 1
    fi
    
    # Test with invalid platform
    if "$SCRIPT_DIR/scripts/package-c.sh" "1.0.0" "invalid" 2>&1 | grep -q "Unsupported"; then
        echo -e "${GREEN}✓ Rejects unsupported platform${NC}"
    else
        echo -e "${RED}✗ Should reject invalid platform${NC}"
        return 1
    fi
    
    echo ""
}

# Test 6: audit-artifacts.sh validation
test_audit_artifacts() {
    echo -e "${YELLOW}Test 6: Artifact Auditing${NC}"
    
    # Test with missing arguments
    if "$SCRIPT_DIR/scripts/audit-artifacts.sh" 2>&1 | grep -q "Error"; then
        echo -e "${GREEN}✓ Shows error for missing arguments${NC}"
    else
        echo -e "${RED}✗ Should error on missing arguments${NC}"
        return 1
    fi
    
    # Test with nonexistent file
    if "$SCRIPT_DIR/scripts/audit-artifacts.sh" "nonexistent.tar.gz" "swift" 2>&1 | grep -q "not found"; then
        echo -e "${GREEN}✓ Detects missing file${NC}"
    else
        echo -e "${RED}✗ Should detect missing file${NC}"
        return 1
    fi
    
    # Test with invalid artifact type
    if "$SCRIPT_DIR/scripts/audit-artifacts.sh" "dummy.tar.gz" "invalid" 2>&1 | grep -q "Error"; then
        echo -e "${GREEN}✓ Rejects invalid artifact type${NC}"
    else
        echo -e "${RED}✗ Should reject invalid type${NC}"
        return 1
    fi
    
    echo ""
}

# Test 7: Scripts are executable
test_scripts_executable() {
    echo -e "${YELLOW}Test 7: Script Permissions${NC}"
    
    for script in create-rc-branch.sh tag-release.sh delete-rc-branch.sh \
                   package-swift.sh package-c.sh audit-artifacts.sh; do
        if [ ! -x "$SCRIPT_DIR/scripts/$script" ]; then
            echo -e "${RED}✗ $script is not executable${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}✓ All scripts are executable${NC}"
    echo ""
}

# Test 8: Shebang validity
test_shebang() {
    echo -e "${YELLOW}Test 8: Script Shebangs${NC}"
    
    for script in create-rc-branch.sh tag-release.sh delete-rc-branch.sh \
                   package-swift.sh package-c.sh audit-artifacts.sh; do
        if ! head -1 "$SCRIPT_DIR/scripts/$script" | grep -q "#!/bin/bash"; then
            echo -e "${RED}✗ $script missing bash shebang${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}✓ All scripts have correct shebang${NC}"
    echo ""
}

# Run all tests
echo "Running validation tests..."
echo ""

FAILED=0

test_scripts_executable || FAILED=$((FAILED + 1))
test_shebang || FAILED=$((FAILED + 1))
test_rc_branch_creation || FAILED=$((FAILED + 1))
test_tag_release || FAILED=$((FAILED + 1))
test_delete_rc_branch || FAILED=$((FAILED + 1))
test_package_swift || FAILED=$((FAILED + 1))
test_package_c || FAILED=$((FAILED + 1))
test_audit_artifacts || FAILED=$((FAILED + 1))

echo "=================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ $FAILED test(s) failed${NC}"
    exit 1
fi
