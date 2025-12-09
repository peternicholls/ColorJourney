# Release Playbook

**Purpose**: Step-by-step guide for ColorJourney release process  
**Last Updated**: 2025-12-09  
**Status**: In-Development (Phase 2)

---

## Prerequisites

Before starting any release process, ensure:

- [ ] You have push access to the repository
- [ ] GitHub branch protections are configured for `develop`, `main`, and `release-candidate/*`
- [ ] CI/CD workflows are active and passing on `develop`
- [ ] All required tooling is installed:
  - Swift 5.9+
  - CMake 3.16+
  - Git
  - Standard build tools (make, gcc/clang)

---

## Phase 1: Pre-Release Planning

### 1.1 Decision: Decide the Version Bump

**When**: Early in the release cycle, often at sprint/milestone completion

**Who**: Product owner + tech lead + maintainers

**Steps**:

1. Review the CHANGELOG.md `[Unreleased]` section
2. Categorize changes:
   - **Breaking changes** → Major version bump (X.0.0)
   - **New features (backward compatible)** → Minor version bump (X.Y.0)
   - **Bug fixes only** → Patch version bump (X.Y.Z)
3. Document rationale in a GitHub issue or PR
4. Review SemVer spec: https://semver.org/

**Decision Matrix**:
| Changes | Bump | Example |
|---------|------|---------|
| Breaking API | MAJOR | 1.0.0 → 2.0.0 |
| New features | MINOR | 1.0.0 → 1.1.0 |
| Bug fixes | PATCH | 1.0.0 → 1.0.1 |

### 1.2 Update Documentation

**When**: Before RC creation (same day)

**Who**: Release manager + documentation leads

**Steps**:

1. **Update CHANGELOG.md** (on `develop`):
   - Move content from `[Unreleased]` to `[VERSION] - YYYY-MM-DD`
   - Add section for Breaking Changes (if applicable)
   - Add Migration Guide link (if major version bump)
   - Keep Unreleased section empty but present

2. **Create/Update VersionMapping.md** (if Swift+C released together):
   - Document Swift version → required C core version mapping
   - Example: "Swift 1.2.0 requires ColorJourney C Core >= 1.1.0"

3. **Verify README.md**:
   - Check all examples are current
   - Verify quick start instructions work
   - Fix broken links

4. **Commit and push** to `develop`:
   ```bash
   git add CHANGELOG.md DevDocs/VERSION_MAPPING.md README.md
   git commit -m "docs: prepare for release 1.0.0"
   git push origin develop
   ```

---

## Phase 2: Release Candidate Creation

### 2.1 Create RC Branch

**When**: Ready to begin stabilization

**Who**: Release manager

**Command**:
```bash
./scripts/create-rc-branch.sh <VERSION> 1
# Example:
./scripts/create-rc-branch.sh 1.0.0 1
```

**What it does**:
- Creates branch: `release-candidate/1.0.0-rc.1`
- Pushes to remote
- Triggers CI/CD pipeline automatically

**Verify**:
- [ ] Branch created: `git branch -a | grep release-candidate`
- [ ] CI/CD pipeline running: Check GitHub Actions

### 2.2 Monitor CI/CD Pipeline

**Duration**: Typically 10-30 minutes

**Checks that must pass**:
- [ ] Swift build (macOS)
- [ ] Swift build (iOS)
- [ ] Swift tests
- [ ] C core build (Ubuntu)
- [ ] C core tests
- [ ] Linting (SwiftLint)

**If all checks pass**:
- Proceed to Phase 3 (Promotion)

**If any check fails**:
- Proceed to Phase 2.3 (Fix & Retry)

### 2.3 Fix Issues & Retry (if needed)

**When**: RC tests or builds fail

**Steps**:

1. Identify the failing check in CI/CD logs
2. Create a fix on the RC branch:
   ```bash
   git checkout release-candidate/1.0.0-rc.1
   # Make fixes
   git add .
   git commit -m "fix: address test failure in Swift build"
   git push origin release-candidate/1.0.0-rc.1
   ```
3. CI/CD pipeline re-runs automatically
4. If still failing, continue iterating
5. When ready for new RC number:
   ```bash
   ./scripts/create-rc-branch.sh 1.0.0 2
   ```

**Rationale**: RC.2, RC.3, etc. allow iteration without tagging a release prematurely

---

## Phase 3: Release Promotion

### 3.1 Approval & Promotion Decision

**When**: All RC checks have passed (green) for > 1 hour

**Who**: Release manager + QA lead (optional but recommended)

**Checklist**:
- [ ] All CI checks passing on RC branch
- [ ] Manual testing completed (if applicable)
- [ ] CHANGELOG.md is finalized
- [ ] No critical issues reported in RC cycle
- [ ] Release notes prepared (if announcing publicly)

### 3.2 Promote to Main & Tag

**Command**:
```bash
./scripts/tag-release.sh <VERSION>
# Example:
./scripts/tag-release.sh 1.0.0
```

**What it does**:
- Switches to `main` branch
- Merges RC branch (creates merge commit)
- Creates annotated Git tag: `1.0.0`
- Pushes tag to remote (triggers release-artifacts.yml)

**Verify**:
- [ ] Tag created locally: `git tag | grep 1.0.0`
- [ ] Tag pushed: `git ls-remote origin | grep 1.0.0`
- [ ] release-artifacts.yml workflow triggered: Check GitHub Actions

### 3.3 Cleanup RC Branch

**When**: After tag is created and workflows triggered

**Command**:
```bash
./scripts/delete-rc-branch.sh <VERSION> 1
# Example:
./scripts/delete-rc-branch.sh 1.0.0 1
```

**What it does**:
- Deletes local RC branch
- Deletes remote RC branch
- Preserves branch history in Git reflog

---

## Phase 4: Artifact Generation & Publishing

### 4.1 Wait for Artifact Workflows

**Duration**: Typically 5-15 minutes

**Workflows running**:
- `release-artifacts.yml`:
  - Packages Swift artifact
  - Packages C artifact (Linux)
  - Creates GitHub Release with artifacts attached

- `badge-update.yml`:
  - Updates version badge
  - Updates build status badge
  - Syncs version mapping

**Monitoring**:
- Check GitHub Actions for completion
- Verify no workflow failures

### 4.2 Verify Release Assets

**When**: release-artifacts.yml workflow completes

**Steps**:

1. Navigate to: `https://github.com/peternicholls/ColorJourney/releases`
2. Find the release for `1.0.0`
3. Verify assets attached:
   - [ ] `ColorJourney-1.0.0.tar.gz` (Swift source package)
   - [ ] `ColorJourney-1.0.0.tar.gz.sha256` (checksum)
   - [ ] `libcolorjourney-1.0.0-linux-x86_64.tar.gz` (C static lib)
   - [ ] `libcolorjourney-1.0.0-linux-x86_64.tar.gz.sha256` (checksum)

4. Test artifact integrity:
   ```bash
   # Verify checksums
   shasum -c ColorJourney-1.0.0.tar.gz.sha256
   shasum -c libcolorjourney-1.0.0-linux-x86_64.tar.gz.sha256
   
   # Extract and verify contents
   tar -tzf ColorJourney-1.0.0.tar.gz | head -20
   ```

### 4.3 Verify Badges Update

**Duration**: Should complete within 5 minutes

**Checks**:
- [ ] Version badge on README shows `1.0.0`
- [ ] Build status badge shows "passing"
- [ ] Platform badge shows supported platforms

---

## Phase 5: Post-Release

### 5.1 Announce Release (if applicable)

**When**: After artifacts are verified

**Actions**:
- Post release announcement to community channels (if applicable)
- Link to GitHub release page
- Highlight key features/fixes in CHANGELOG

### 5.2 Monitor for Issues

**Duration**: First 24 hours post-release

**Watch for**:
- User-reported issues in GitHub Issues
- Build failures for downstream users
- Performance regressions

### 5.3 Prepare for Next Cycle

**Steps**:
1. Switch back to `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. Update `CHANGELOG.md` with new `[Unreleased]` section:
   ```markdown
   ## [Unreleased]
   
   ### Added
   - (upcoming features)
   
   ### Fixed
   - (upcoming fixes)
   ```

3. Commit and push:
   ```bash
   git commit -am "docs: prepare for next development cycle"
   git push origin develop
   ```

---

## Emergency Procedures

### Hotfix for Released Version

**Scenario**: Critical bug discovered in `1.0.0` after release

**Steps**:

1. Create hotfix branch from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/1.0.1
   ```

2. Apply fix and test locally

3. Follow normal release process:
   ```bash
   ./scripts/create-rc-branch.sh 1.0.1 1
   # Verify CI passes
   ./scripts/tag-release.sh 1.0.1
   ```

4. Update `develop` with hotfix:
   ```bash
   git checkout develop
   git pull origin develop
   git merge main  # Pulls in v1.0.1 tag
   git push origin develop
   ```

### Abort Release (RC Abandoned)

**Scenario**: Critical issue found, RC must be abandoned

**Steps**:

1. Delete RC branch:
   ```bash
   ./scripts/delete-rc-branch.sh 1.0.0 1
   ```

2. Document in issue why RC was abandoned

3. Go back to `develop` and fix issues:
   ```bash
   git checkout develop
   # Apply fixes
   git push origin develop
   ```

4. When ready, create new RC with same or bumped version:
   ```bash
   ./scripts/create-rc-branch.sh 1.0.0 2  # Same version, new RC
   ```

---

## Reproducibility Verification

**Purpose**: Ensure builds are deterministic (same commit = same artifact)

**When**: When building artifacts for release

**Process**:

1. Build artifact the first time:
   ```bash
   ./scripts/package-swift.sh 1.0.0
   HASH_1=$(shasum -a 256 ColorJourney-1.0.0.tar.gz | awk '{print $1}')
   ```

2. Clean build artifacts:
   ```bash
   rm ColorJourney-1.0.0.tar.gz
   ```

3. Build again on same commit:
   ```bash
   ./scripts/package-swift.sh 1.0.0
   HASH_2=$(shasum -a 256 ColorJourney-1.0.0.tar.gz | awk '{print $1}')
   ```

4. Verify hashes match:
   ```bash
   [ "$HASH_1" = "$HASH_2" ] && echo "✓ Builds are reproducible" || echo "✗ MISMATCH"
   ```

**If hashes don't match**:
- Investigate source (timestamps, nondeterministic outputs, etc.)
- Fix root cause
- Re-run build verification
- Do NOT release until reproducibility is confirmed

---

## Phase 6: CocoaPods Publication (Optional - Feature 003)

**Purpose**: Publish ColorJourney to CocoaPods Trunk for iOS/macOS developers  
**Roles**: Release manager + maintainers with CocoaPods Trunk access  
**Prerequisites**: Feature 003 (CocoaPods Release) must be implemented

### 6.1 Prerequisites & Credentials

Before publishing to CocoaPods:

1. **Local CocoaPods Setup**:
   ```bash
   # Install CocoaPods (if not already installed)
   gem install cocoapods
   
   # Verify installation
   pod repo update
   ```

2. **Trunk Token**:
   - Register or log in to CocoaPods: https://trunk.cocoapods.org
   - Generate/retrieve your trunk token from account settings
   - Store locally (DO NOT commit):
     ```bash
     export COCOAPODS_TRUNK_TOKEN="your-token-here"
     ```
   - In CI: Add token as GitHub secret `COCOAPODS_TRUNK_TOKEN`

3. **Verify Token Validity**:
   ```bash
   pod trunk me
   ```
   Should show your email and registered devices.

### 6.2 Local Validation

**When**: Before pushing to trunk (recommended as part of release sign-off)

**Steps**:

1. Run the publish helper script in dry-run mode:
   ```bash
   ./scripts/publish-cocoapods.sh dry-run
   ```
   This will:
   - Run `pod spec lint` with verbose output
   - Verify version parity with Package.swift
   - Check for platform incompatibilities
   - **NOT push to trunk**

2. Fix any lint errors (typically missing headers or platform target issues)

3. Verify locally with a test Podfile (optional):
   ```bash
   cd Examples/CocoaPodsDemo
   pod install --repo-update
   # Try building the demo app in Xcode
   ```

### 6.3 Push to CocoaPods Trunk

**When**: After RC validation and verification of all artifacts

**Steps**:

1. Ensure your CocoaPods Trunk token is exported:
   ```bash
   export COCOAPODS_TRUNK_TOKEN="your-token"
   ```

2. Run the publish helper (with token):
   ```bash
   ./scripts/publish-cocoapods.sh push
   ```
   This will:
   - Lint the podspec
   - Verify version parity
   - Push to trunk using the token
   - Display success/failure status

3. Verify publication:
   ```bash
   # Wait ~10 minutes for index update, then:
   pod search ColorJourney
   
   # Or check directly:
   # https://cocoapods.org/pods/ColorJourney
   ```

### 6.4 CI/CD Integration (Automated)

If Feature 003 workflow updates are implemented, publication may be automated:

1. **Lint Step** (in release workflow):
   ```bash
   pod spec lint ColorJourney.podspec --verbose
   ```
   - Runs before trunk push
   - Fails release if lint fails
   - Must pass for pod to be published

2. **Push Step** (in release workflow):
   ```bash
   pod trunk push ColorJourney.podspec --verbose
   ```
   - Uses `COCOAPODS_TRUNK_TOKEN` secret
   - Fails release if push fails
   - Coordinated with GitHub release artifacts

### 6.5 Manual Fallback (if Automation Fails)

If CI/CD publication fails:

1. **Check Error Logs**:
   - Review GitHub Actions workflow logs
   - Look for lint errors or trunk token issues

2. **Lint Locally**:
   ```bash
   pod spec lint ColorJourney.podspec --verbose --allow-warnings=false
   ```

3. **Push Manually**:
   ```bash
   export COCOAPODS_TRUNK_TOKEN="your-token"
   pod trunk push ColorJourney.podspec --verbose
   
   # Or with dry-run to test:
   pod trunk push ColorJourney.podspec --dry-run --verbose
   ```

4. **Troubleshooting**:
   - Token expired? Regenerate from https://trunk.cocoapods.org
   - Header path issues? Verify `public_header_files` in ColorJourney.podspec
   - Platform targets? Ensure iOS 13.0+ and macOS 10.15+ match podspec

### 6.6 Verification

After successful push, verify the pod is available:

```bash
# Search in CocoaPods database
pod search ColorJourney

# Install in test Podfile
echo "pod 'ColorJourney', '~> 1.0'" > Podfile
pod install --repo-update
```

Expected result:
- Pod appears on CocoaPods.org within 10 minutes
- `pod search` finds the latest version
- `pod install` successfully downloads and integrates the pod

---

## Checklists

### Pre-Release Checklist

- [ ] Version decided and documented
- [ ] CHANGELOG.md updated with release version and date
- [ ] VersionMapping.md updated (if applicable)
- [ ] README.md verified for accuracy
- [ ] All commits on `develop` are intentional (no accidental WIPs)
- [ ] Documentation is current and links work

### Release Day Checklist

- [ ] RC branch created: `release-candidate/X.Y.Z-rc.1`
- [ ] CI/CD pipeline green on RC branch
- [ ] Issues fixed and RC.N incremented if needed
- [ ] Release approved by team
- [ ] Tag created: `vX.Y.Z` on main
- [ ] RC branch deleted
- [ ] release-artifacts.yml workflow completed
- [ ] Artifacts verified and checksums validated
- [ ] Badges updated and accurate
- [ ] CocoaPods podspec lint passes (if Feature 003 implemented)
- [ ] CocoaPods pod published to trunk (if Feature 003 implemented)
- [ ] Release announced (if applicable)

### Post-Release Checklist

- [ ] No critical issues reported in first 24 hours
- [ ] `develop` branch synced if any updates made
- [ ] Next cycle CHANGELOG.md started
- [ ] Team notified of new release
- [ ] Documentation updated (if needed)

---

## Troubleshooting

### Issue: CI/CD Fails on RC Branch

**Cause**: Test failure, build error, or lint issue

**Solution**:
1. Check GitHub Actions logs for detailed error
2. Fix on RC branch
3. Rerun CI by pushing: `git push origin release-candidate/X.Y.Z-rc.N`
4. If many issues, increment RC number and create new branch

### Issue: Tag Push Failed

**Cause**: Tag already exists or auth issue

**Solution**:
1. Verify tag: `git tag | grep vX.Y.Z`
2. If exists and wrong, delete: `git tag -d vX.Y.Z && git push origin --delete vX.Y.Z`
3. Retry: `git tag -a vX.Y.Z -m "Release"` && `git push origin vX.Y.Z`

### Issue: Artifacts Don't Generate

**Cause**: release-artifacts.yml workflow failed

**Solution**:
1. Check GitHub Actions for error logs
2. Common causes:
   - Missing toolchain (Swift, CMake)
   - Artifact path issues
   - Permissions for pushing to release
3. Fix root cause, then manually rerun workflow

---

## Reference

- **SemVer Spec**: https://semver.org/spec/v2.0.0.html
- **Keep a Changelog**: https://keepachangelog.com/en/1.0.0/
- **Git Flow**: https://nvie.com/posts/a-successful-git-branching-model/
- **GitHub Releases**: https://docs.github.com/en/repositories/releasing-projects-on-github

