# Badge Requirements & Update Process

## Overview

README badges serve as quick status indicators for users and contributors. This document specifies which badges are essential, their update process, and automation requirements.

## Essential Badges

Color Journey README includes **3 essential badges** (no more, no less):

### 1. Build Status Badge

**Purpose**: Indicates whether the latest build on `main` is passing  
**Location**: README.md, top section, near title  
**Format**: GitHub Actions workflow status  
**Update Frequency**: Automatic, real-time (on push to main)  
**Example**:
```
[![Build Status](https://github.com/yourusername/ColorJourney/actions/workflows/core-ci.yml/badge.svg?branch=main)](https://github.com/yourusername/ColorJourney/actions/workflows/core-ci.yml)
```

**Implementation**:
- GitHub Actions provides this automatically for any workflow
- Accessible via: `https://github.com/OWNER/REPO/actions/workflows/WORKFLOW.yml/badge.svg`
- Can filter by branch: `?branch=main`
- Links to Actions workflow detail page

**Rationale**: Users need to know if code is stable before using it. Real-time, automated, no manual updates needed.

### 2. Version Badge

**Purpose**: Shows latest released version (e.g., v1.0.0)  
**Location**: README.md, top section, next to Build Status  
**Format**: Dynamic version from Git tags  
**Update Frequency**: Automatic, within 5 minutes of release  
**Example**:
```
[![Version](https://img.shields.io/github/v/release/yourusername/ColorJourney)](https://github.com/yourusername/ColorJourney/releases)
```

**Implementation**:
- Use shields.io dynamic badge API
- Source: Latest GitHub release tag
- Cached by shields.io; updates within 5 minutes post-release
- Links to GitHub releases page

**Automated Update Process**:
1. Tag created on `main` via `scripts/tag-release.sh` (e.g., `git tag v1.0.0`)
2. GitHub automatically creates GitHub Release from tag
3. Shields.io cache refreshes (SLA: <5 minutes)
4. README badge reflects new version automatically

**Rationale**: Users want to know what version to install. Automated refresh eliminates manual update step.

### 3. Platform Support Badge

**Purpose**: Indicates supported platforms and minimum versions  
**Location**: README.md, Features or Building section  
**Format**: Custom badge with platform list  
**Update Frequency**: Manual (only on major platform support changes)  
**Example**:
```
[![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20Linux%20%7C%20Windows-informational)](README.md#platform-support)
```

**Implementation**:
- Static badge (doesn't change frequently)
- Lists: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, visionOS 1+, Catalyst 13+, C99 (Linux/Windows)
- Updates only when platform support changes (rare)

**Rationale**: Developers need to know platform compatibility before integration.

---

## Prohibited Badges (Remove if Present)

The following badges **must not** appear in README (violates "clean artifacts" requirement):

- Coverage percentage badges (`.cov`, code coverage %)
- Multiple linting badges (eslint, prettier, swiftlint)
- "Stars" or social media badges
- "Downloads" badges (unreliable, clutter)
- Third-party status badges (Snyk, SonarCloud, etc.)
- Custom "awesome" or "framework of the month" badges

**Rationale**: These add clutter without adding user value. CI ensures code quality; users don't need to see every metric.

---

## Badge Markdown Template

```markdown
## Status & Platforms

[![Build Status](https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml/badge.svg?branch=main)](https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml)
[![Version](https://img.shields.io/github/v/release/peternicholls/ColorJourney)](https://github.com/peternicholls/ColorJourney/releases)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20Linux%20%7C%20Windows-informational)](README.md#platform-support)
```

---

## Automated Badge Update Process

### Build Status Badge (Real-Time)

**How it works**:
1. Workflow runs on push to `main` (core-ci.yml)
2. GitHub Actions generates badge dynamically
3. Badge URL: `https://github.com/OWNER/REPO/actions/workflows/WORKFLOW.yml/badge.svg`
4. Badge reflects current workflow status in real-time
5. No manual action needed

**CI Job**:
```yaml
# .github/workflows/core-ci.yml
name: CI

on:
  push:
    branches: [main, develop, release-candidate/*]
  pull_request:
    branches: [main, develop]

jobs:
  swift-build-and-test:
    # ...
  c-build-and-test:
    # ...
  # ... more jobs
```

**Verification**: Badge passes ✅ when all CI jobs pass; shows "failing" 🔴 if any job fails.

### Version Badge (Automated, <5 min SLA)

**How it works**:
1. Release tag created: `git tag v1.0.0 && git push origin v1.0.0`
2. GitHub automatically creates GitHub Release for the tag
3. Shields.io detects new release (periodic checks)
4. Badge updates to show `v1.0.0`
5. SLA: update within 5 minutes of tag push

**Release Workflow** (.github/workflows/release-artifacts.yml):
```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  publish-release:
    runs-on: ubuntu-latest
    steps:
      # ... build artifacts ...
      - name: Create GitHub Release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref_name }}
          body: |
            See CHANGELOG.md for details
          # ... attach artifacts ...
```

**Verification**: 
1. Tag is created
2. GitHub Release appears in releases page
3. Wait up to 5 minutes
4. Refresh badges.io cache: `https://img.shields.io/github/v/release/peternicholls/ColorJourney?cache_bust=$TIMESTAMP`

### Platform Support Badge (Manual)

**How it works**:
1. No automation needed; static badge
2. Update README.md only when platform support changes
3. Changes documented in CHANGELOG.md

**Update Process**:
```markdown
<!-- Infrequently updated, example: -->
<!-- When adding visionOS support, update badge: -->
[![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20visionOS%201%2B%20%7C%20Linux%20%7C%20Windows-informational)](README.md#platform-support)
```

---

## Badge Refresh SLA & Monitoring

### Acceptable Delays

| Badge | Update Trigger | SLA | Monitoring |
|-------|---|---|---|
| Build Status | Workflow completion | <1 minute | Automatic (GitHub Actions) |
| Version | Tag + GitHub Release | <5 minutes | Check shields.io cache |
| Platform | Manual edit | Manual | Code review |

### SLA Verification

**For Build Status**:
```bash
# Check if badge updates after CI completes
curl -I https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml/badge.svg
# Should return 200 within 1 minute of workflow completion
```

**For Version**:
```bash
# Check shields.io cache
curl https://img.shields.io/github/v/release/peternicholls/ColorJourney
# Should reflect latest tag; if not, refresh cache:
curl https://img.shields.io/github/v/release/peternicholls/ColorJourney?cache_bust=$(date +%s)
```

---

## Implementation Checklist

### For Repository Setup

- [x] `core-ci.yml` workflow exists and passes
- [x] Badges in README.md point to correct URLs
- [x] Version badge uses shields.io API
- [x] No prohibited badges in README

### For Release Process

When cutting a release (T025/T026):

1. [ ] Run `scripts/tag-release.sh` to create tag
2. [ ] Verify GitHub Release is created automatically
3. [ ] Wait 5 minutes
4. [ ] Verify version badge updated
5. [ ] Verify build status badge is green
6. [ ] Confirm no prohibited badges in README

### Monitoring During Release

```bash
#!/bin/bash
# Monitor badge refresh (run after creating release tag)

echo "Release tag created. Monitoring badge updates..."

for i in {1..5}; do
  echo "Check $i (1 minute elapsed)..."
  sleep 60
  
  # Check version badge
  version=$(curl -s https://img.shields.io/github/v/release/peternicholls/ColorJourney | grep -o 'v[0-9.]*' | head -1)
  echo "  Version badge: $version"
  
  # Check build status
  status=$(curl -I https://github.com/peternicholls/ColorJourney/actions/workflows/core-ci.yml/badge.svg | grep -o 'passing\|failing')
  echo "  Build status: $status"
done
```

---

## Troubleshooting

### Version Badge Shows Old Version

**Problem**: Badge shows v1.0.0, but latest release is v1.1.0  
**Solution**: 
1. Verify GitHub Release exists: https://github.com/peternicholls/ColorJourney/releases
2. If Release exists, wait 5 more minutes (shields.io cache)
3. Force cache refresh:
   ```
   https://img.shields.io/github/v/release/peternicholls/ColorJourney?cache_bust=true
   ```
4. If Release doesn't exist, GitHub didn't auto-create it from tag; manually create via GitHub UI

### Build Status Badge Shows Red (Failing)

**Problem**: Badge shows 🔴, but CI should be passing  
**Solution**:
1. Check GitHub Actions: https://github.com/peternicholls/ColorJourney/actions
2. Find the failed job (e.g., `swift-build-and-test`, `c-build-and-test`)
3. Fix the failing job
4. Re-run workflow or push new commit to trigger
5. Badge updates automatically when workflow passes

### Platform Badge Is Incorrect

**Problem**: Badge shows wrong platforms  
**Solution**: Update README.md badge URL manually; no automation for this static badge.

---

## Best Practices

1. **Keep Badges Minimal**: Only the 3 essential badges. Every badge adds clutter.
2. **Use Real-Time Automation**: Build status and version should auto-update; never manually edit these.
3. **Update Changelog First**: Always update CHANGELOG.md before creating a release tag.
4. **Test Release Locally**: Use `scripts/test-release-automation.sh` to verify release process before going live.
5. **Document in Release Notes**: In GitHub Release description, explain badge meaning for new users.

---

## Example Release Notes (with Badge Context)

```markdown
# v1.1.0 - December 15, 2025

## What's New
- Added 3 new style presets
- Improved performance on Apple Silicon
- Expanded platform support to visionOS 1+

## Installation
See README.md for platform-specific installation instructions.

## Status Indicators
- **Build Status Badge**: Indicates if current `main` branch is stable
- **Version Badge**: Auto-updates to v1.1.0 within 5 minutes
- **Platform Badge**: Lists all supported platforms and minimum versions

## Changelog
See [CHANGELOG.md](CHANGELOG.md) for detailed changes.
```

---

## References

- [shields.io](https://shields.io) — Badge generation service
- [Keep a Changelog](https://keepachangelog.com/) — Changelog format
- [Semantic Versioning](https://semver.org/) — Version numbering scheme

---

**Last Updated**: 2025-12-09  
**Maintained By**: Color Journey Release Team  
**Related**: [RELEASE_PLAYBOOK.md](RELEASE_PLAYBOOK.md), [RELEASE_TAGGING.md](RELEASE_TAGGING.md)
