# Release Tagging & Versioning Guide

**Purpose**: Understanding SemVer tagging, version naming, and promotion workflow  
**Status**: Script-ready (tag-release.sh in T024)  
**Last Updated**: 2025-12-09

---

## Semantic Versioning (SemVer 2.0.0)

**Overview**: Version format is `MAJOR.MINOR.PATCH` with optional pre-release identifiers

### Format

```
vX.Y.Z[-rcN]

Where:
  v         = Version prefix (Git tag convention)
  X         = MAJOR version (breaking changes)
  Y         = MINOR version (new features, backward compatible)
  Z         = PATCH version (bug fixes, backward compatible)
  -rcN      = Optional pre-release indicator (N = 1, 2, 3, ...)
  
Examples:
  v1.0.0          = Release version 1.0.0
  v1.1.0          = Release version 1.1.0 (minor bump)
  v1.0.1          = Release version 1.0.1 (patch bump)
  v2.0.0          = Release version 2.0.0 (major bump)
  v1.0.0-rc.1    = Release candidate 1 for 1.0.0
  v1.0.0-rc.2    = Release candidate 2 for 1.0.0
  v1.1.0-rc.3    = Release candidate 3 for 1.1.0
```

### Decision Matrix

When to bump which version:

| Change Type | MAJOR | MINOR | PATCH | Example |
|-------------|-------|-------|-------|---------|
| Bug fix | | | ✓ | `1.0.0` → `1.0.1` |
| New feature | | ✓ | | `1.0.0` → `1.1.0` |
| New color space | | ✓ | | `1.0.0` → `1.1.0` |
| Performance optimization | | | ✓ | `1.0.0` → `1.0.1` |
| Breaking API change | ✓ | | | `1.0.0` → `2.0.0` |
| Removed deprecated API | ✓ | | | `1.0.0` → `2.0.0` |
| New required parameter | ✓ | | | `1.0.0` → `2.0.0` |
| New optional parameter | | ✓ | | `1.0.0` → `1.1.0` |
| Dependency update | | | ✓ or ✗ | (case-by-case) |

### Pre-release vs Release

**Pre-release** (Release Candidate):
- Syntax: `v1.0.0-rc.N` where N = 1, 2, 3, ...
- Purpose: Testing and validation before final release
- Installation: `git clone && git checkout v1.0.0-rc.1` (explicit)
- Stability: **Not recommended for production use**

**Release** (Production):
- Syntax: `v1.0.0` (no -rc suffix)
- Purpose: Stable, tested version for general use
- Installation: Default when cloning
- Stability: **Ready for production**

---

## Version Numbering Rules

### Rule 1: Incremental Patches

```
1.0.0 → 1.0.1 → 1.0.2 → ...

When: Bug fixes only, no new features
Example: Fixed grayscale handling in HSV
```

### Rule 2: Reset PATCH on MINOR Bump

```
1.0.5 → 1.1.0  (PATCH resets)
1.1.0 → 1.1.1  (PATCH increments)
1.1.5 → 2.0.0  (Both reset)

When: New features added
```

### Rule 3: Reset Both on MAJOR Bump

```
1.5.3 → 2.0.0  (MINOR and PATCH reset)
2.0.0 → 2.0.1  (PATCH increments)
2.1.5 → 3.0.0  (Both reset)

When: Breaking changes introduced
```

### Rule 4: Pre-release Ordering

```
Sequence for a planned 1.0.0 release:

v1.0.0-rc.1 → v1.0.0-rc.2 → v1.0.0-rc.3 → v1.0.0

Pre-releases always precede the final release
Each -rc.N is tested before promotion
Final version has no -rc suffix
```

### Rule 5: No -rc for Patches

```
INCORRECT: v1.0.0-rc.1 → v1.0.1-rc.1
CORRECT:   v1.0.0 → v1.0.1

Patches are released directly without RC phase (usually)
Exception: Critical security fixes may warrant RC testing
```

---

## Git Tag Workflow

### Creating Tags (tag-release.sh)

**Automated via script**:

```bash
./scripts/tag-release.sh 1.0.0

# What the script does:
# 1. Validates version format (X.Y.Z)
# 2. Verifies release-candidate/1.0.0-rc.* exists
# 3. Checks out main branch
# 4. Merges RC into main: git merge release-candidate/1.0.0-rc.* --no-ff
# 5. Creates annotated tag: git tag -a v1.0.0 -m "Release 1.0.0"
# 6. Pushes tag: git push origin v1.0.0
# 7. Triggers release-artifacts.yml workflow
```

**Manual tag creation** (if needed):

```bash
git checkout main
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Verify tag created
git tag -l | grep v1.0.0
git show v1.0.0
```

**Annotated vs Lightweight Tags**:

```bash
# Annotated tag (recommended for releases)
git tag -a v1.0.0 -m "Release 1.0.0"
# Contains: author, date, message, GPG signature (optional)

# Lightweight tag (for references only)
git tag v1.0.0
# Simple pointer to commit, no metadata

# Always use annotated tags (-a) for releases
```

### Listing Existing Tags

```bash
# List all tags
git tag

# List tags matching pattern
git tag -l "v*"
git tag -l "v1.*"

# Show tag details
git show v1.0.0
git show --pretty=format:"%H %s" v1.0.0  # Commit + message

# List tags with dates
git log --tags --oneline --graph --decorate
```

### Deleting Tags (If Needed)

**If you created a tag incorrectly**:

```bash
# Delete local tag
git tag -d v1.0.0-wrong

# Delete remote tag
git push origin --delete v1.0.0-wrong

# Verify deletion
git tag -l | grep v1.0.0
```

---

## Release Promotion Process

### Pre-Promotion Checklist

Before running `tag-release.sh`:

```bash
# 1. Verify RC branch exists and is ready
git checkout release-candidate/1.0.0-rc.1
git log --oneline -5  # Recent commits

# 2. Verify main branch is clean
git checkout main
git status  # Should be clean

# 3. Verify latest develop is merged
git log --oneline -1 origin/develop
git log --oneline -1 origin/release-candidate/1.0.0-rc.1
# RC should be descendant of develop

# 4. Run final tests on RC
git checkout release-candidate/1.0.0-rc.1
swift test
```

### Promotion Steps

**Step 1: Run tag-release.sh**

```bash
./scripts/tag-release.sh 1.0.0

# Output:
# ✓ Version format valid: 1.0.0
# ✓ RC branch exists: release-candidate/1.0.0-rc.1
# ✓ Switched to main branch
# ✓ Merged RC into main (merge commit created)
# ✓ Created annotated tag: v1.0.0
# ✓ Tag pushed to origin
#
# Next steps:
# 1. GitHub Actions will automatically:
#    - Generate Swift artifact
#    - Generate C artifacts (per platform)
#    - Create GitHub Release with assets
#    - Update version badges
# 2. Verify release on GitHub in 2-5 minutes
```

**Step 2: Verify Tag Exists**

```bash
# Local
git tag -l | grep v1.0.0

# Remote
git ls-remote origin | grep v1.0.0
# Should show: abc123def v1.0.0

# GitHub
git describe --tags
# Should output: v1.0.0
```

**Step 3: Monitor Artifact Generation**

```bash
# Check GitHub Actions
# Go to Actions → release-artifacts workflow
# Status: Running → Success (2-5 minutes)

# Or via API
curl -s https://api.github.com/repos/peternicholls/ColorJourney/releases/latest | jq '.assets | length'
# Should show: 4 (Swift + C artifacts)
```

**Step 4: Verify GitHub Release**

```bash
# Via API
curl -s https://api.github.com/repos/peternicholls/ColorJourney/releases/tags/v1.0.0 | jq '.name, .published_at, .assets[].name'

# Via web
# https://github.com/peternicholls/ColorJourney/releases/tag/v1.0.0
```

### Post-Promotion Actions

**Step 5: Cleanup RC Branch**

```bash
# Delete RC branch
./scripts/delete-rc-branch.sh 1.0.0

# Verify deletion
git branch -a | grep -c release-candidate/1.0.0-rc
# Should output: 0
```

**Step 6: Merge main Back to Develop**

```bash
# Sync develop with release changes
git checkout develop
git pull origin develop
git merge main --no-ff -m "Merge main (v1.0.0) back to develop"
git push origin develop
```

**Step 7: Create Release Notes**

```bash
# GitHub Release auto-created by CI, but manually verify/enhance:
# https://github.com/peternicholls/ColorJourney/releases/tag/v1.0.0

# Add release notes in GitHub UI:
# - Summary of major changes
# - Upgrade instructions
# - Known issues (if any)
# - Thanks to contributors
```

---

## Version Constraints & Compatibility

### Swift Package Consumers

Users declare version requirements:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/peternicholls/ColorJourney.git", 
             from: "1.0.0"),  // 1.0.0 and newer, < 2.0.0
    
    .package(url: "https://github.com/peternicholls/ColorJourney.git", 
             "1.0.0"..<"1.1.0"),  // Exactly 1.0.x
]
```

### Implications

```
Release 1.0.0:
├─ from: "1.0.0" matches 1.0.0, 1.0.1, 1.1.0, 2.0.0
│  (SemVer compatible up to next major version)
└─ "1.0.0"..<"1.1.0" matches 1.0.0, 1.0.1
   (exact minor range)

Release 1.0.1 (patch):
├─ Backward compatible - all 1.0.0 users can upgrade safely
├─ New features? NO (no MINOR bump)
└─ Automatically picked up by from: "1.0.0"

Release 1.1.0 (minor):
├─ Backward compatible - all 1.0.0 users can upgrade safely
├─ New features? YES (new MINOR version)
├─ API breaking? NO (still 1.x.x)
└─ Automatically picked up by from: "1.0.0"

Release 2.0.0 (major):
├─ Breaking changes - 1.x.x users must update Package.swift
├─ API breaking? YES (new MAJOR version)
└─ NOT picked up by from: "1.0.0" (stops at < 2.0.0)
```

---

## Hotfix Releases

**Scenario**: Critical bug found in v1.0.0, need to release 1.0.1

### Hotfix Workflow

```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/1.0.1

# 2. Fix the bug
# ... edit files ...
git add .
git commit -m "fix: critical bug in color conversion"

# 3. Merge to main
git checkout main
git merge hotfix/1.0.1 --no-ff

# 4. Tag release
git tag -a v1.0.1 -m "Release 1.0.1 - Hotfix"
git push origin main v1.0.1

# 5. Merge back to develop
git checkout develop
git merge main
git push origin develop

# 6. Cleanup
git branch -d hotfix/1.0.1
```

---

## Version Naming Rules Summary

| Element | Rule | Example |
|---------|------|---------|
| Format | vMAJOR.MINOR.PATCH[-rcN] | v1.0.0, v1.0.0-rc.1 |
| MAJOR | Increment for breaking changes | 1.0.0 → 2.0.0 |
| MINOR | Increment for new features | 1.0.0 → 1.1.0 |
| PATCH | Increment for bug fixes | 1.0.0 → 1.0.1 |
| RC Number | Increment for retesting | rc.1 → rc.2 → rc.3 |
| Initial version | Start at v1.0.0 (not v0.1.0) | v1.0.0 |
| Releases only | No -rc in final release | v1.0.0 ✓, v1.0.0-rc.1 ✗ |
| Git tag | Always annotated | -a flag |

---

## Troubleshooting

### Tag Already Exists

**Error**: `fatal: tag 'v1.0.0' already exists`

**Solution**:
```bash
# Check which commit the tag points to
git show v1.0.0

# If it's wrong, delete and recreate
git tag -d v1.0.0
git push origin --delete v1.0.0
git tag -a v1.0.0 -m "Release 1.0.0 (fixed)"
git push origin v1.0.0
```

### Version Conflicts

**Problem**: Both v1.0.0 and v1.0.1 exist, which should users use?

**Solution**:
- v1.0.1 is newer (higher PATCH)
- Users on v1.0.0 should upgrade to v1.0.1
- No breaking changes in patch release

### Pre-release Ordering Issues

**Problem**: Users confused between v1.0.0-rc.1, v1.0.0-rc.2, v1.0.0

**Communication**:
```
v1.0.0-rc.1  = Release candidate 1 (TESTING ONLY)
v1.0.0-rc.2  = Release candidate 2 (TESTING ONLY)
v1.0.0       = STABLE RELEASE ← Use this in production
```

---

## Quick Reference

### Check Current Version

```bash
git describe --tags
# Output: v1.0.0 or v1.0.0-rc.1
```

### Create a Release

```bash
./scripts/tag-release.sh 1.0.0
# Automates the entire promotion process
```

### List All Versions

```bash
git tag -l | sort -V
# Shows all versions in order: v0.1.0, v1.0.0, v1.0.1, v1.1.0, v2.0.0
```

### Rollback to Previous Version

```bash
git checkout v1.0.0
# Detached HEAD state at v1.0.0
# Use for local testing/debugging only
```

