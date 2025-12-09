# Release Candidate Workflow Guide

**Purpose**: Detailed workflow for creating, testing, and promoting release candidates  
**Status**: Script-ready (scripts created in T019, T021)  
**Last Updated**: 2025-12-09

---

## Overview

The Release Candidate (RC) workflow allows testing a planned release before final promotion to `main`. This guide walks through each step with decision points and safety procedures.

**Key Phases**:
1. **Pre-RC Planning** - Version decision, changelog preparation
2. **RC Creation** - Branch creation with validation
3. **RC Testing** - Automated and manual validation
4. **RC Resolution** - Promote or abandon
5. **Post-Release** - Cleanup and announcement

**Estimated Timeline**: 2-7 days per RC (depending on issues found)

---

## Phase 1: Pre-RC Planning

### 1.1 Determine Release Version

**Decision**: What version should this RC represent?

**Using Semantic Versioning** (SemVer 2.0.0):

| Scenario | Change | Example |
|----------|--------|---------|
| Bug fixes only | Patch version | `1.0.0` → `1.0.1` |
| New features | Minor version | `1.0.0` → `1.1.0` |
| Breaking changes | Major version | `1.0.0` → `2.0.0` |
| Pre-release | Add -rcN | `1.0.0-rc.1`, `1.0.0-rc.2` |

**Example Decision Tree**:
```
Q: Did we add new color spaces or API endpoints?
└─ Yes → Minor version bump (1.0.0 → 1.1.0)

Q: Did we break existing API?
└─ Yes → Major version bump (1.0.0 → 2.0.0)

Q: Only bug fixes and optimizations?
└─ Yes → Patch version bump (1.0.0 → 1.0.1)
```

**Store version decision**:
```bash
# Set environment variable for this RC session
export RELEASE_VERSION="1.1.0"
export RC_NUMBER="1"

# Verify
echo "Planning RC: $RELEASE_VERSION-rc.$RC_NUMBER"
```

### 1.2 Prepare CHANGELOG

**Purpose**: Document changes since last release

**Location**: [CHANGELOG.md](../../CHANGELOG.md)

**Format**: Keep a Changelog (https://keepachangelog.com/)

**Template to add**:

```markdown
## [1.1.0] - 2025-12-15

### Added
- New color space: HSLuv for perceptually uniform colors
- API: `ColorJourney.hsluvFromRGB()` conversion function
- Docs: HSLuv integration guide

### Changed
- Performance: 15% faster RGB to Lab conversion
- Internal: Refactored color space modules for clarity

### Fixed
- Bug: HSV conversion edge case for grayscale colors
- Bug: CIELab boundary checking for invalid inputs

### Security
- Dependencies: Updated to latest versions

### Deprecated
- (none)

### Removed
- (none)

---

## [1.0.0] - 2025-12-01
... (previous releases)
```

**Commit CHANGELOG**:
```bash
git checkout develop
git add CHANGELOG.md
git commit -m "chore: prepare CHANGELOG for 1.1.0 release"
git push origin develop
```

### 1.3 Update Package Metadata

**Update version in Package.swift** (if needed):

```swift
// Package.swift
let package = Package(
    name: "ColorJourney",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "ColorJourney", targets: ["ColorJourney"]),
    ],
    // ... rest of config
)
```

**Note**: SemVer is tracked via Git tags, not in Package.swift, so version updates are optional.

### 1.4 Gather Release Notes

**Collect from**:
- [ ] Closed issues since last release
- [ ] Merged PRs and their descriptions
- [ ] Known issues for this RC
- [ ] Performance metrics or benchmarks
- [ ] Dependencies updated

**Example**:
```
Release Notes for 1.1.0
========================

New Features:
- HSLuv color space support (issue #42)
- 15% performance improvement in Lab conversion

Bug Fixes:
- Fixed grayscale handling in HSV (PR #48)
- Fixed Lab boundary validation (PR #52)

Known Issues for RC Testing:
- HSLuv interpolation edge case at hue discontinuity
  (will be addressed in 1.1.1 if needed)

Testing Focus:
- HSLuv conversions across full gamut
- Performance benchmarks vs 1.0.0
- Lab color boundary edge cases
```

---

## Phase 2: RC Creation

### 2.1 Create Release-Candidate Branch

**Prerequisites**:
- [ ] develop branch is up-to-date
- [ ] CHANGELOG is updated
- [ ] All features for this version are merged to develop
- [ ] No pending work on develop
- [ ] (If publishing to CocoaPods) CocoaPods CLI installed: `gem install cocoapods`
- [ ] (If publishing to CocoaPods) Trunk token available: `pod trunk me` succeeds

**Create RC branch**:

```bash
cd /path/to/your/ColorJourney/repo

# Ensure develop is current
git checkout develop
git pull origin develop

# Create RC branch
./scripts/create-rc-branch.sh 1.1.0 1

# Expected output:
# ✓ Version format valid: 1.1.0
# ✓ RC number valid: 1
# ✓ Latest changes from develop
#
# ✓ Created branch: release-candidate/1.1.0-rc.1
# 
# Next steps:
# 1. Monitor CI builds on the RC branch
# 2. Run release gates checklist
# 3. When ready to release, run:
#    ./scripts/tag-release.sh 1.1.0

# Verify branch exists
git branch | grep release-candidate/1.1.0-rc.1
git log --oneline -3  # Verify commits are from develop
```

**GitHub Notification**: 
- GitHub will automatically trigger CI workflows for the RC branch
- RC branch appears in pull requests interface
- Branch protection rules apply (all checks must pass)

### 2.2 Monitor RC Branch CI

**Workflow File**: [.github/workflows/core-ci.yml](.github/workflows/core-ci.yml)

**Triggered checks**:
```
☐ build-macos      - Swift and iOS builds on macOS
☐ lint             - SwiftLint code quality checks
☐ test-c-core      - C library unit tests on Linux
☐ reproducibility  - Verify artifact reproducibility
```

**Status Check Page**:
1. Go to https://github.com/peternicholls/ColorJourney
2. Click "Branches" tab
3. Find `release-candidate/1.1.0-rc.1`
4. Click branch name to see CI status

**Expect**: All checks should pass (inherited from develop)

**If checks fail**:
- [ ] Review error message
- [ ] Fix issue on develop branch
- [ ] Delete RC branch: `./scripts/delete-rc-branch.sh 1.1.0`
- [ ] Recreate after fix merged: `./scripts/create-rc-branch.sh 1.1.0 2` (increment RC number)

---

## Phase 3: RC Testing

### 3.1 Run Release Gates Checklist

**Document**: [DevDocs/RELEASE_GATES.md](RELEASE_GATES.md)

**Checklist**:

#### Gate 1: Pre-Release (Plan Phase)
```
[ ] Version decision documented
[ ] CHANGELOG updated with changes
[ ] Breaking changes assessed
[ ] Deprecations documented
[ ] Dependencies reviewed
```

#### Gate 2: RC Testing (Build Phase)
```
[ ] CI all green on RC branch
[ ] Manual smoke tests passed
[ ] Integration tests passed
[ ] Package contents verified (FR-007, FR-008)
[ ] No regression issues found
```

#### Gate 3: Promotion (Quality Gate)
```
[ ] Artifact auditing passed
[ ] Security scan completed
[ ] License compliance verified
[ ] Documentation updated
[ ] Artifact hashes recorded
```

#### Gate 4: Publishing (Release)
```
[ ] GitHub release created
[ ] Tags pushed to all registries
[ ] Announcements sent
[ ] Metrics recorded
```

#### Gate 5: Post-Release (Monitoring)
```
[ ] No critical user-reported issues
[ ] Performance baseline met
[ ] Download metrics normal
```

### 3.2 Manual Testing

**Test Environments**:

```bash
# Test on macOS
swift build -c release
swift test

# Test on Linux (in Docker)
docker-compose build
docker-compose run --rm test

# Test Swift integration
cd Examples
swift test -c release

# Test C integration
cd Examples
gcc -I ../Sources/CColorJourney/include \
    -c CExample.c -o CExample.o
gcc CExample.o -L ../Sources/CColorJourney/build \
    -lcolorjourney -o CExample
./CExample
```

**Test Scenarios**:

1. **Color Space Conversions**:
   ```swift
   import ColorJourney
   
   let rgb = RGB(red: 255, green: 128, blue: 64)
   let hsl = rgb.toHSL()
   let lab = rgb.toLab()
   let hsluv = rgb.toHSLuv()
   print("All conversions working: \(rgb), \(hsl), \(lab), \(hsluv)")
   ```

2. **Interpolation**:
   ```swift
   let color1 = RGB(red: 255, green: 0, blue: 0)
   let color2 = RGB(red: 0, green: 0, blue: 255)
   let interpolated = color1.interpolate(to: color2, steps: 10)
   print("Interpolation produces \(interpolated.count) steps")
   ```

3. **Edge Cases**:
   - Grayscale colors (R=G=B)
   - Pure colors (single channel max)
   - Zero/black (0,0,0)
   - Max white (255,255,255)

4. **Performance**:
   ```bash
   time swift build -c release  # Should be fast
   time swift test               # Acceptable timeframe
   ```

### 3.3 Artifact Validation

**Swift Package**:
```bash
./scripts/package-swift.sh 1.1.0

# Verify contents
tar -tzf ColorJourney-1.1.0.tar.gz | head -20

# Should include:
# - Sources/ColorJourney/
# - Package.swift
# - README.md
# - LICENSE
# - CHANGELOG.md
# - Docs/

# Should exclude:
# - DevDocs/
# - Tests/CColorJourneyTests/
# - Dockerfile
# - Makefile
```

**C Library**:
```bash
./scripts/package-c.sh 1.1.0 macos

# Verify contents
tar -tzf libcolorjourney-1.1.0-macos-universal.tar.gz

# Should include:
# - include/ColorJourney.h
# - lib/libcolorjourney.a
# - examples/
# - README.md
# - LICENSE
```

**Artifact Audit**:
```bash
./scripts/audit-artifacts.sh ColorJourney-1.1.0.tar.gz swift
./scripts/audit-artifacts.sh libcolorjourney-1.1.0-macos-universal.tar.gz c

# Should show all checks ✓
```

### 3.4 Known Issues & Decision Points

**If issues found during testing**:

| Severity | Decision | Action |
|----------|----------|--------|
| Critical (breaks API) | Cannot proceed | Delete RC, fix, start new RC |
| Major (significant bug) | Proceed to next RC | Delete this RC, increment to rc.2 |
| Minor (edge case) | Document & release | Add to release notes, proceed |
| Documentation | Fix & republish | Update docs, increment RC |

**Example Decision**:
```
Issue: HSLuv interpolation produces wrong hue in certain ranges
Severity: Major (affects color quality)
Decision: Create RC.2 to include fix

# Delete problematic RC
./scripts/delete-rc-branch.sh 1.1.0

# Fix issue on develop
git checkout develop
git pull origin develop
# ... fix code and test ...
git push origin develop

# Recreate RC with fix
./scripts/create-rc-branch.sh 1.1.0 2

# Repeat testing...
```

---

## Phase 4: RC Resolution

### 4.1 Approve RC for Release

**Criteria for promotion**:
- [ ] All CI checks passing
- [ ] Release gates checklist complete
- [ ] Manual testing passed
- [ ] Artifact contents correct
- [ ] No critical or major issues

**Sign-off**:
```bash
# Document approval
git checkout release-candidate/1.1.0-rc.1
git log --oneline -1

# Record decision
echo "Release Candidate 1.1.0-rc.1 APPROVED for promotion"
echo "Date: $(date)"
echo "Tester: $(git config user.name)"
```

### 4.2 Promote RC to Release

**Tag and merge to main**:

```bash
./scripts/tag-release.sh 1.1.0

# Expected output:
# ✓ Version format valid: 1.1.0
# ✓ Switched to main branch
# ✓ Merged release-candidate/1.1.0-rc.1 into main
# ✓ Created annotated tag: v1.1.0
# ✓ Tag pushed to origin
#
# Next steps:
# 1. Wait for GitHub Actions to:
#    - Build artifacts (package-swift.sh, package-c.sh)
#    - Create GitHub Release
#    - Update badges
# 2. Verify release on https://github.com/peternicholls/ColorJourney/releases
# 3. Announce release to users
```

**What this script does**:
1. Validates version format (SemVer)
2. Checks RC branch exists
3. Switches to main branch
4. Merges RC branch into main (with merge commit)
5. Creates annotated Git tag `v1.1.0`
6. Pushes tag to GitHub
7. Triggers CI workflow to generate artifacts

### 4.3 Verify GitHub Release

**Wait for release creation** (2-5 minutes after tag push):

```bash
# Check tag exists locally
git describe --tags

# Check GitHub release created
curl -s https://api.github.com/repos/peternicholls/ColorJourney/releases/latest \
  | jq '.tag_name, .name, .assets | length'

# Expected: 
# "v1.1.0"
# "Release 1.1.0"
# 4 (Swift + C artifacts + checksums)
```

**Verify on web**:
1. Go to https://github.com/peternicholls/ColorJourney/releases
2. Click latest release (v1.1.0)
3. Verify:
   - [ ] Release title: "Release 1.1.0"
   - [ ] Release notes from CHANGELOG
   - [ ] 4 asset files:
     - ColorJourney-1.1.0.tar.gz (Swift)
     - libcolorjourney-1.1.0-*.tar.gz (C, multiple platforms)
   - [ ] Checksums included in release notes

### 4.4 Cleanup RC Branch

**Delete RC branch** (only after successful release):

```bash
./scripts/delete-rc-branch.sh 1.1.0

# Expected output:
# ✓ Version format valid: 1.1.0
# ✓ Deleted local branch: release-candidate/1.1.0-rc.1
# ✓ Deleted remote branch: release-candidate/1.1.0-rc.1
#
# Branch history preserved in reflog.
```

**Verify deletion**:
```bash
git branch -a | grep -i release-candidate  # Should be empty or show other RCs

git log --oneline | head -1  # Should be on main with merge commit
```

---

## Phase 5: Post-Release

### 5.1 Verify Package Registries

**Swift Package Index**:
1. Go to https://swiftpackageindex.com/search?query=ColorJourney
2. Verify version 1.1.0 appears
3. Verify documentation generated
4. Check compatibility matrix (iOS, macOS, etc.)

**CocoaPods** (if published):
```bash
pod search ColorJourney
# Should show: ColorJourney (1.1.0)
```

**Homebrew** (if published):
```bash
brew info colorjourney
# Should show: colorjourney 1.1.0
```

### 5.2 Announce Release

**Create announcement** (email, Twitter, etc.):

```
Subject: ColorJourney 1.1.0 Released 🎉

We're excited to announce ColorJourney 1.1.0!

New Features:
- HSLuv color space support for perceptually uniform colors
- 15% performance improvement in RGB to Lab conversion

Bug Fixes:
- Fixed HSV conversion edge case for grayscale colors
- Fixed CIELab boundary checking

Download:
- Swift: https://github.com/peternicholls/ColorJourney
- C: [download link]

Changelog: https://github.com/peternicholls/ColorJourney/blob/main/CHANGELOG.md

Thanks to everyone who contributed!
```

### 5.3 Monitor Release Health

**First week metrics**:
- [ ] Download count (GitHub Releases)
- [ ] No critical issues reported
- [ ] User feedback positive
- [ ] Documentation questions answered
- [ ] Dependencies all resolved

**If issues found**:
- Create hotfix branch from main
- Release as 1.1.1 patch
- Follow same RC workflow

---

## Decision Trees

### Should We Create an RC?

```
Q: Are we releasing new features or major fixes?
└─ Yes → CREATE RC for testing

Q: Is it only a patch/hotfix?
└─ Yes → Optional (tag directly if confident)

Q: Does release affect public API?
└─ Yes → MUST CREATE RC for impact testing
```

### Should We Promote This RC?

```
Q: Are all CI checks passing?
├─ No → FIX and recreate RC
└─ Yes → Continue

Q: Are there critical issues?
├─ Yes → ABANDON RC, delete, fix, recreate
└─ No → Continue

Q: Are we confident in artifact quality?
├─ No → Document issues, recreate RC
└─ Yes → PROMOTE to release
```

### When to Increment RC Number

```
Scenario                          → Action
Found critical bug                → Delete RC.1, create RC.2
Need more testing time            → Keep RC.1, test longer
Minor docs issue                  → Fix in RC.1, test again
Dependency security update        → RC.2 (recreate after update)
Performance optimization found    → RC.2 (recreate after change)
```

---

## Troubleshooting

### RC Branch Creation Fails

**Error**: "Branch already exists"

**Solution**:
```bash
# Check if RC branch exists
git branch -a | grep release-candidate/1.1.0

# If it exists and failed, delete it
./scripts/delete-rc-branch.sh 1.1.0

# Try creation again
./scripts/create-rc-branch.sh 1.1.0 1
```

### CI Checks Failing on RC

**Error**: "build-macos check failed"

**Solution**:
1. Click on failing check to see error details
2. Fix issue on develop branch
3. Delete RC and recreate:
   ```bash
   ./scripts/delete-rc-branch.sh 1.1.0
   git checkout develop && git pull origin develop
   ./scripts/create-rc-branch.sh 1.1.0 2
   ```

### Tag Push Fails

**Error**: "Tag already exists"

**Solution**:
```bash
# Check if tag already created
git tag | grep v1.1.0

# If exists, verify it matches current RC
git checkout v1.1.0
git log --oneline -1

# If correct, tag-release.sh should have promoted RC
# If different, create new RC with different version
```

### GitHub Release Not Creating

**Problem**: Artifacts not generated after tag push

**Check**:
1. Go to Actions tab
2. Find "release-artifacts" workflow
3. Check if job is running/failed
4. If failed, check error message
5. Fix and re-run workflow

---

## Testing Checklist

Before declaring RC ready for promotion:

**Automated Tests**:
- [ ] All GitHub Actions checks passing
- [ ] Swift tests passing
- [ ] C tests passing
- [ ] SwiftLint passing

**Manual Tests**:
- [ ] Color conversion accuracy verified
- [ ] Performance acceptable
- [ ] Documentation accurate
- [ ] Examples work correctly

**Release Gates**:
- [ ] Pre-Release gate complete
- [ ] RC Testing gate complete
- [ ] Promotion gate complete
- [ ] Artifacts valid (FR-007, FR-008)

**Artifact Validation**:
- [ ] Swift artifact includes correct files
- [ ] C artifacts build correctly
- [ ] Checksums match
- [ ] Archive integrity confirmed

