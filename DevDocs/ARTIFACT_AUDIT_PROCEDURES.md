# Artifact Audit Procedures

**Purpose**: Step-by-step guide for validating release artifacts before publication  
**Implements**: FR-007 (Swift) and FR-008 (C) compliance verification  
**Last Updated**: 2025-12-09

---

## Overview

Artifact auditing ensures that release packages meet quality standards, contain required content, and exclude sensitive or unnecessary files.

**Two Approaches**:
1. **Automated** (audit-artifacts.sh script) - Fast, repeatable validation
2. **Manual** - Detailed inspection for complex scenarios

---

## Automated Audit (Recommended)

### Using audit-artifacts.sh Script

**Location**: [scripts/audit-artifacts.sh](../../scripts/audit-artifacts.sh)

**Syntax**:
```bash
./scripts/audit-artifacts.sh <archive-file> <type>

Where:
  <archive-file> = Path to .tar.gz file to audit
  <type>         = 'swift' or 'c' (determines validation rules)
```

### Swift Artifact Audit

**Command**:
```bash
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift

# Expected Output:
# ================================================
# Auditing Swift Artifact: ColorJourney-1.0.0.tar.gz
# ================================================
#
# Checking archive integrity...
# ✓ Archive is valid tar.gz
#
# Checking required files...
# ✓ Sources/ColorJourney/ exists
# ✓ Package.swift exists
# ✓ README.md exists
# ✓ LICENSE exists
# ✓ CHANGELOG.md exists
# ✓ Docs/ directory exists
#
# Checking for forbidden files...
# ✓ No C source code found
# ✓ No test code found
# ✓ No DevDocs/ found
# ✓ No .github/ found
#
# Audit Result: ✓ PASS
```

### C Artifact Audit

**Command**:
```bash
./scripts/audit-artifacts.sh libcolorjourney-1.0.0-macos-universal.tar.gz c

# Expected Output:
# ================================================
# Auditing C Artifact: libcolorjourney-1.0.0-macos-universal.tar.gz
# ================================================
#
# Checking archive integrity...
# ✓ Archive is valid tar.gz
#
# Checking platform and architecture...
# ✓ Platform: macos
# ✓ Architecture: universal
#
# Checking required files...
# ✓ lib/ directory exists
# ✓ include/ directory exists
# ✓ examples/ directory exists
# ✓ README.md exists
# ✓ LICENSE exists
# ✓ CHANGELOG.md exists
#
# Checking library...
# ✓ libcolorjourney.a exists
# ✓ libcolorjourney.a is valid static library
#
# Checking headers...
# ✓ ColorJourney.h exists
# ✓ colorjourney_version.h exists
#
# Checking for forbidden files...
# ✓ No Swift source code found
# ✓ No shared libraries (.so/.dylib/.dll) found
# ✓ No test code found
#
# Audit Result: ✓ PASS
```

### Audit Failure Scenarios

**If audit fails**, check specific error message:

**Example 1: Missing required file**
```bash
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift

# ✗ CHANGELOG.md missing (REQUIRED)
# Audit Result: ✗ FAIL

Solution:
1. Verify CHANGELOG.md exists in source
2. Regenerate artifact: ./scripts/package-swift.sh 1.0.0
3. Re-run audit
```

**Example 2: Forbidden file included**
```bash
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift

# ✗ DevDocs/ found (FORBIDDEN)
# Audit Result: ✗ FAIL

Solution:
1. Check package script exclude list
2. Regenerate artifact: ./scripts/package-swift.sh 1.0.0
3. Verify DevDocs/ is NOT in archive: tar -tzf ColorJourney-1.0.0.tar.gz | grep DevDocs
```

### Batch Auditing (All Artifacts)

**For releasing multiple artifacts at once**:

```bash
#!/bin/bash
# audit-all.sh

echo "Auditing all release artifacts..."

# Swift
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift || exit 1

# C - all platforms
for PLATFORM in macos linux windows; do
  for ARCH in x86_64 aarch64 arm64; do
    FILE="libcolorjourney-1.0.0-${PLATFORM}-${ARCH}.tar.gz"
    if [ -f "$FILE" ]; then
      ./scripts/audit-artifacts.sh "$FILE" c || exit 1
    fi
  done
done

echo "✓ All artifacts passed audit"
```

**Run**:
```bash
chmod +x audit-all.sh
./audit-all.sh
```

---

## Manual Audit Process

**Use when**:
- Automated script unavailable
- Detailed inspection needed
- Custom validation rules required

### Step 1: Extract and Inspect

**Swift artifact**:
```bash
# Create audit workspace
mkdir audit-workspace && cd audit-workspace

# Extract
tar -xzf ../ColorJourney-1.0.0.tar.gz

# List top-level contents
ls -la ColorJourney-1.0.0/

# Expected:
# Sources/
# Package.swift
# README.md
# LICENSE
# CHANGELOG.md
# Docs/
```

**C artifact**:
```bash
# Extract
tar -xzf ../libcolorjourney-1.0.0-macos-universal.tar.gz

# List top-level
ls -la libcolorjourney-1.0.0-macos-universal/

# Expected:
# lib/
# include/
# examples/
# README.md
# LICENSE
# CHANGELOG.md
```

### Step 2: Verify Required Files

**Swift - Check each required directory**:

```bash
# Check Sources
find Sources/ColorJourney -name "*.swift" | head -5
# Should show Swift files

# Check Package.swift
test -f Package.swift && echo "✓ Package.swift exists" || echo "✗ Missing"

# Check documentation
test -f README.md && echo "✓ README.md exists" || echo "✗ Missing"
test -f LICENSE && echo "✓ LICENSE exists" || echo "✗ Missing"
test -f CHANGELOG.md && echo "✓ CHANGELOG.md exists" || echo "✗ Missing"

# Check Docs directory
test -d Docs && ls Docs/ | head -3 && echo "✓ Docs present" || echo "✗ Missing"
```

**C - Verify binaries and headers**:

```bash
# Check library
test -f lib/libcolorjourney.a && echo "✓ libcolorjourney.a exists" || echo "✗ Missing"

# Verify library is actually a static library
file lib/libcolorjourney.a
# Should show: Mach-O universal binary (for macOS)
#           or ELF 64-bit LSB (for Linux)

# Check headers
test -f include/ColorJourney.h && echo "✓ ColorJourney.h exists" || echo "✗ Missing"
test -f include/colorjourney_version.h && echo "✓ Version header exists" || echo "✗ Missing"

# Check examples
test -d examples && ls examples/ | head && echo "✓ Examples present" || echo "✗ Missing"
```

### Step 3: Verify Forbidden Files Absent

**Swift - Ensure C code excluded**:

```bash
# Check for C source
tar -tzf ColorJourney-1.0.0.tar.gz | grep -E '\.(c|h)$' && \
  echo "✗ C source files FOUND (forbidden)" || \
  echo "✓ No C source files"

# Check for C tests
tar -tzf ColorJourney-1.0.0.tar.gz | grep CColorJourneyTests && \
  echo "✗ C tests FOUND (forbidden)" || \
  echo "✓ No C tests"

# Check for internal docs
tar -tzf ColorJourney-1.0.0.tar.gz | grep DevDocs && \
  echo "✗ DevDocs FOUND (forbidden)" || \
  echo "✓ No DevDocs"

# Check for CI/CD
tar -tzf ColorJourney-1.0.0.tar.gz | grep '.github/' && \
  echo "✗ .github/ FOUND (forbidden)" || \
  echo "✓ No .github/"
```

**C - Ensure Swift code excluded**:

```bash
# Check for Swift source
tar -tzf libcolorjourney-1.0.0-macos-universal.tar.gz | grep -E '\.swift$' && \
  echo "✗ Swift source FOUND (forbidden)" || \
  echo "✓ No Swift source"

# Check for Swift SPM manifest
tar -tzf libcolorjourney-1.0.0-macos-universal.tar.gz | grep 'Package.swift' && \
  echo "✗ Package.swift FOUND (forbidden)" || \
  echo "✓ No Package.swift"

# Check for shared libraries (should be static only)
tar -tzf libcolorjourney-1.0.0-macos-universal.tar.gz | grep -E '\.(so|dylib|dll)$' && \
  echo "✗ Shared libraries FOUND (use .a only)" || \
  echo "✓ No shared libraries"
```

### Step 4: Verify File Integrity

**Check for corruption**:

```bash
# Test extraction without errors
tar -tzf ColorJourney-1.0.0.tar.gz > /dev/null 2>&1 && \
  echo "✓ Archive integrity OK" || \
  echo "✗ Archive corrupted"

# Verify all files readable
tar -tzf ColorJourney-1.0.0.tar.gz | wc -l
# Should show reasonable number of files (100+)
```

**Verify permissions**:

```bash
# Extract and check file permissions
tar -xzf ColorJourney-1.0.0.tar.gz

# Check source files readable
find Sources/ColorJourney -type f -exec test -r {} \; && \
  echo "✓ All source files readable" || \
  echo "✗ Permission issues"

# Check shell scripts executable (if any)
find . -name "*.sh" -exec test -x {} \; 2>/dev/null && \
  echo "✓ Scripts executable" || \
  echo "⚠ Some scripts not executable (OK if no scripts)"
```

### Step 5: Content Validation

**Swift - Verify Package.swift syntax**:

```bash
cd ColorJourney-1.0.0

# Check Package.swift is valid
swift package describe > /dev/null 2>&1 && \
  echo "✓ Package.swift is valid" || \
  echo "✗ Package.swift has syntax errors"

# Check dependencies resolve
swift package show-dependencies > /dev/null 2>&1 && \
  echo "✓ Dependencies resolve" || \
  echo "✗ Dependency resolution failed"
```

**C - Verify headers compile**:

```bash
cd libcolorjourney-1.0.0-macos-universal

# Test header includes
gcc -I include/ -c examples/CExample.c -o /tmp/test.o -std=c99 && \
  echo "✓ Headers compile successfully" || \
  echo "✗ Header compilation failed"

# Check for syntax errors
grep -q "^#ifndef COLORJOURNEY_H" include/ColorJourney.h && \
  echo "✓ Header guards present" || \
  echo "✗ Missing header guards"
```

### Step 6: Version Consistency

**Verify version matches**:

```bash
# Check filename version
FILENAME_VERSION="1.0.0"  # Extract from filename

# Check Package.swift version (Swift)
grep -q "name.*ColorJourney" Package.swift && \
  echo "✓ Package name correct" || \
  echo "✗ Package name mismatch"

# Check C header version
grep -q "define COLORJOURNEY_VERSION" include/colorjourney_version.h && \
  echo "✓ Version header present" || \
  echo "✗ Missing version macro"

# Check CHANGELOG has entry for version
grep -q "## \[1.0.0\]" CHANGELOG.md && \
  echo "✓ CHANGELOG entry present" || \
  echo "✗ CHANGELOG missing version"
```

---

## Audit Checklist

### Pre-Audit

- [ ] All artifacts generated successfully
- [ ] Artifact files exist in current directory
- [ ] No archive errors or warnings during generation
- [ ] Workspace clean (no mixed old/new artifacts)

### Automated Audit

- [ ] Run `audit-artifacts.sh` for each artifact
- [ ] All scripts return exit code 0 (success)
- [ ] No FAIL messages in output
- [ ] Checksums generated for each artifact

### Manual Verification

- [ ] Archives extract without errors
- [ ] All required files present (verified via listing)
- [ ] No forbidden files present (verified via grep)
- [ ] File permissions correct (readable sources, executable scripts)
- [ ] Content valid (syntax checks pass)
- [ ] Version consistency verified (filename, headers, CHANGELOG)

### Pre-Release

- [ ] All artifacts pass automated audit ✓
- [ ] Manual spot-checks completed (at least 2 artifacts)
- [ ] Checksum verification tested
- [ ] Example code tested (extraction + compilation)
- [ ] Release notes include artifact descriptions
- [ ] GitHub Release template prepared
- [ ] Distribution channels verified (SPM, etc.)

---

## Automated Audit Troubleshooting

### Script Not Found

**Error**: `./scripts/audit-artifacts.sh: No such file`

**Solution**:
```bash
# Verify script exists
ls -la scripts/audit-artifacts.sh

# Make executable if needed
chmod +x scripts/audit-artifacts.sh

# Run from correct directory
cd /path/to/ColorJourney
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift
```

### Invalid Archive Type

**Error**: `Type must be 'swift' or 'c'`

**Solution**:
```bash
# Correct syntax
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift  # ✓
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz c      # ✓

# Incorrect
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz Swift  # ✗ (wrong case)
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz lib    # ✗ (wrong type)
```

### Archive Not Found

**Error**: `Archive file not found`

**Solution**:
```bash
# Verify artifact exists
ls -la *.tar.gz

# Use correct path
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift  # Current dir

# Or full path
./scripts/audit-artifacts.sh /path/to/ColorJourney-1.0.0.tar.gz swift
```

---

## Integration into CI/CD

### Add Audit to GitHub Actions

**In release-artifacts.yml**:

```yaml
- name: Audit Swift Artifact
  run: |
    ./scripts/audit-artifacts.sh ColorJourney-${VERSION}.tar.gz swift
    
- name: Audit C Artifacts
  run: |
    for PLATFORM in macos linux windows; do
      for ARCH in x86_64 aarch64 arm64; do
        FILE="libcolorjourney-${VERSION}-${PLATFORM}-${ARCH}.tar.gz"
        if [ -f "$FILE" ]; then
          ./scripts/audit-artifacts.sh "$FILE" c
        fi
      done
    done
    
- name: Generate Checksums
  run: |
    sha256sum *.tar.gz > CHECKSUMS.txt
```

### Audit Gate Before Publishing

```yaml
publish-release:
  needs: [audit-swift, audit-c, generate-checksums]
  runs-on: ubuntu-latest
  steps:
    - name: Create GitHub Release
      # Only runs if all audits pass
```

---

## Quick Reference

**Validate single artifact**:
```bash
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift
```

**Validate all artifacts**:
```bash
for f in *.tar.gz; do
  type=$(echo "$f" | grep -q "^ColorJourney" && echo swift || echo c)
  ./scripts/audit-artifacts.sh "$f" "$type"
done
```

**Manual checklist**:
1. Extract artifact
2. Verify required files present
3. Verify forbidden files absent
4. Test compilation (C) or dependency resolution (Swift)
5. Check version consistency

