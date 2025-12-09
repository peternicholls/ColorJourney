# Branch Strategy Implementation Guide

**Purpose**: Step-by-step guide for implementing Git Flow branches and protections  
**Status**: Ready for GitHub Admin Action (Task T005/T006)  
**Last Updated**: 2025-12-09

---

## Overview

The ColorJourney project uses a **Git Flow-inspired branching model** with two permanent branches:
- **`main`** - Release-only branch containing tagged, released versions
- **`develop`** - Primary development branch for features and fixes

Temporary branches:
- **`release-candidate/*`** - Release validation and testing
- **`feature/*`** (optional) - Feature development isolation

---

## Current Repository Status

### Step 1: Verify Current Branch Names

**Check existing branches**:
```bash
cd /path/to/your/ColorJourney/repo
git branch -a

# Expected output:
# * main
#   develop
#   (other feature branches)
```

**If `develop` exists**: Branch rename may have already been done.  
**If only `master` exists**: Follow **Step 2: Rename Default Branch** below.

---

## Step 2: Rename Default Branch (If Needed)

**Only required if the default branch is currently named `master`**

### 2a. Local Repository Changes

```bash
# 1. Pull latest code
git checkout master
git pull origin master

# 2. Create new develop branch locally
git branch -m master develop
git fetch origin

# 3. Push renamed branch to GitHub
git push -u origin develop

# 4. Switch to develop
git checkout develop
```

### 2b. GitHub Web UI Configuration

**Navigate to repository settings**:
1. Go to https://github.com/peternicholls/ColorJourney
2. Click **Settings** (gear icon)
3. Select **Branches** (left sidebar)
4. Under "Default branch", click the dropdown
5. Select **develop** (or **main** if using main as release branch)
6. Click **Update** to confirm

**Result**: GitHub will:
- Update default branch for new clones
- Redirect pull requests to the new default branch
- Automatically handle user redirects

### 2c. Delete Old Branch (If Remote Still Has `master`)

```bash
# Delete remote master if it still exists
git push origin --delete master

# Verify removal
git branch -a  # Should NOT show origin/master
```

---

## Step 3: Create `main` Release Branch (If Needed)

**If using `main` as the release branch**:

```bash
# From develop, create main
git checkout -b main develop

# Or if main already exists as release branch
git checkout main
git merge develop --no-ff -m "Initialize main from develop"

# Push to GitHub
git push -u origin main
```

---

## Step 4: Protect Branches in GitHub

### 4a. Enable Branch Protection for `main`

**Via GitHub Web UI**:

1. Go to https://github.com/peternicholls/ColorJourney/settings/branch_protection_rules
2. Click **Add rule**
3. Fill in Branch name pattern: `main`
4. Enable the following settings:

**Required Reviews**:
```
☑ Require a pull request before merging
☑ Require approvals
  - Number of approvals: 1 (or 2 for strict enforcement)
☑ Require review from code owners
  - (Add CODEOWNERS file if not exists)
☑ Restrict who can push to matching branches
  - (Optional: only admins)
```

**Build/Status Checks**:
```
☑ Require status checks to pass before merging
  - Select these checks:
    ✓ build (macOS)
    ✓ build-ios (iOS)
    ✓ lint (SwiftLint)
    ✓ test-c-core
```

**Advanced Settings**:
```
☑ Require branches to be up to date before merging
☑ Require conversation resolution before merging
☑ Require signed commits (optional)
☐ Require linear history (NOT recommended - conflicts with merge commit strategy)
```

**Save Protection Rule**.

### 4b. Enable Branch Protection for `develop`

**Via GitHub Web UI**:

1. Continue at https://github.com/peternicholls/ColorJourney/settings/branch_protection_rules
2. Click **Add rule**
3. Fill in Branch name pattern: `develop`
4. Enable these settings:

**Build/Status Checks** (less strict than main):
```
☑ Require status checks to pass before merging
  - Select these checks:
    ✓ build (macOS)
    ✓ test-c-core
```

**Optional Reviews**:
```
☐ Require a pull request before merging (optional)
  - If required, set to 1 approval
☑ Require conversation resolution before merging
```

**Save Protection Rule**.

### 4c. Enable Branch Protection for `release-candidate/*`

**Via GitHub Web UI**:

1. Click **Add rule**
2. Fill in Branch name pattern: `release-candidate/*`
3. Enable these settings:

**Build/Status Checks** (strict for release validation):
```
☑ Require status checks to pass before merging
  - Select ALL checks:
    ✓ build (macOS)
    ✓ build-ios
    ✓ lint (SwiftLint)
    ✓ test-c-core
    ✓ reproducibility-check (once implemented)
```

**Advanced**:
```
☑ Require branches to be up to date before merging
☑ Dismiss stale pull request approvals
☑ Require conversation resolution before merging
```

**Do NOT enable**:
```
☐ Require a pull request before merging
  (RC branches are typically force-updated by release scripts)
```

**Save Protection Rule**.

---

## Step 5: Create CODEOWNERS File (Optional)

**Purpose**: Automatically request reviews from code owners

**Location**: Create `.github/CODEOWNERS` file

```
# Global code owners
* @peternicholls

# Swift-specific
Sources/ColorJourney/ @peternicholls
Tests/ColorJourneyTests/ @peternicholls

# C-specific
Sources/CColorJourney/ @peternicholls
Tests/CColorJourneyTests/ @peternicholls

# Docs
DevDocs/ @peternicholls
Docs/ @peternicholls

# Release assets
.github/workflows/release-artifacts.yml @peternicholls
scripts/ @peternicholls
```

**Commit and push**:
```bash
git add .github/CODEOWNERS
git commit -m "Add CODEOWNERS for branch protection integration"
git push origin develop
```

---

## Step 6: Update Local Configuration

**Sync local clone with new branch structure**:

```bash
# Remove tracking for old branch
git branch -dr origin/master 2>/dev/null || true

# Fetch all updates
git fetch origin

# Switch to develop
git checkout develop
git pull origin develop

# Verify main exists
git fetch origin main:main 2>/dev/null || git branch --track main origin/main

# Verify branches
git branch -a
# Should show:
# * develop
#   main
#   remotes/origin/develop
#   remotes/origin/main
```

---

## Step 7: Validate Configuration

### 7a. Test Branch Protections

**Try to push directly to main** (should be rejected):

```bash
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "Test direct push"
git push origin main

# Expected: 
# ! [remote rejected] main -> main (protected branch hook declined)
# error: failed to push some refs to 'origin/main'
```

**Correct approach** (via pull request):

```bash
# Reset test commit
git reset --hard HEAD~1

# Create feature branch
git checkout -b test/branch-protection
echo "test" >> test.txt
git add test.txt
git commit -m "Test via PR"
git push origin test/branch-protection

# Go to GitHub, create PR to main
# After approval and CI passes, merge via web UI
```

### 7b. Verify Release Candidate Branch

```bash
# Create test RC branch
git checkout develop
git checkout -b release-candidate/1.0.0-rc.1

# Push test RC
git push -u origin release-candidate/1.0.0-rc.1

# Try force-push (should work, RC is not strict)
git commit --allow-empty -m "test"
git push -f origin release-candidate/1.0.0-rc.1

# Clean up
git push origin --delete release-candidate/1.0.0-rc.1
git branch -d release-candidate/1.0.0-rc.1
```

---

## Step 8: Update Documentation

**Update repository README** to reflect new branch structure:

In `README.md`, add section:

```markdown
## Development Workflow

We use Git Flow-inspired branching:

- **`develop`** - Main development branch
  - PR default target for features and fixes
  - Automatic CI/CD on each push
  
- **`main`** - Release-only branch
  - Protected: requires PR + approved reviews + passing CI
  - Releases must be created via `scripts/tag-release.sh`
  
- **`release-candidate/*`** - Release validation
  - Created from develop for testing
  - Automatic full CI suite (all checks required)
  - Promoted to main via tag-release script
  
- **`feature/*`** - Optional feature branches
  - For long-running features or team collaboration
  - Merge to develop via PR

### Getting Started

1. Clone repository: `git clone https://github.com/peternicholls/ColorJourney.git`
2. Switch to develop: `git checkout develop`
3. Create feature: `git checkout -b feature/my-feature`
4. Submit PR to develop
```

---

## Step 9: Verify Workflow Scripts

**Test that release scripts work with new branches**:

```bash
# Test RC creation (from develop)
git checkout develop
./scripts/create-rc-branch.sh 1.0.0 1

# Expected:
# ✓ Version format valid: 1.0.0
# ✓ RC number valid: 1
# ✓ Latest changes from develop
# 
# ✓ Created branch: release-candidate/1.0.0-rc.1
# 
# Next steps:
# 1. Monitor CI builds on the RC branch
# 2. Run release gates checklist
# 3. When ready to release, run:
#    ./scripts/tag-release.sh 1.0.0

# Verify RC branch was created
git branch | grep release-candidate

# Test tagging (merge to main)
./scripts/tag-release.sh 1.0.0

# Expected to fail because main doesn't have 1.0.0-rc.1 merged
# This is expected behavior - only works after RC merge
```

---

## Troubleshooting

### Issue: "Cannot delete branch" on GitHub

**Cause**: Branch is protected or is the default branch

**Solution**:
1. If it's default branch, change default to another branch in Settings
2. If it's protected, disable protection temporarily, delete, then re-enable

### Issue: PR targets wrong branch

**Cause**: Default branch is not set correctly

**Solution**:
1. Go to Settings > Branches
2. Change "Default branch" to `develop`
3. GitHub will prompt for future PRs

### Issue: Force-push rejected on RC branch

**Problem**: RC branch protection prevents force-push

**Solution**: RC branches should NOT have force-push protection. Verify:
```bash
# In branch protection rule for release-candidate/*
# Ensure "Restrict who can push" is NOT enabled
# Or enable it only for specific users
```

### Issue: CI checks not running

**Cause**: Workflow files (.github/workflows/*.yml) may not have correct triggers

**Solution**: Verify workflows include branch triggers:
```yaml
on:
  push:
    branches:
      - main
      - develop
      - 'release-candidate/*'
  pull_request:
    branches:
      - main
      - develop
```

---

## Rollback Procedure

If branch strategy needs to be reverted:

```bash
# 1. Disable all branch protections
#    (Settings > Branches > delete all rules)

# 2. Rename develop back to master
git checkout develop
git branch -m develop master
git push -f origin master
git push origin --delete develop

# 3. Change default branch back to master
#    (Settings > Branches > Default branch)

# 4. Delete main if not needed
git push origin --delete main
```

---

## Validation Checklist

- [ ] Default branch changed to `develop` (or `main`)
- [ ] `main` branch protection enabled with:
  - [ ] PR required
  - [ ] 1+ approval required
  - [ ] CI status checks required (all checks)
  - [ ] Branch must be up to date
- [ ] `develop` branch protection enabled with:
  - [ ] CI status checks required (build + test)
- [ ] `release-candidate/*` branch protection enabled with:
  - [ ] All CI checks required
  - [ ] Force-push allowed (for release scripts)
- [ ] CODEOWNERS file created (optional)
- [ ] Local clone updated to use new branches
- [ ] Scripts tested with new branch structure
- [ ] README documentation updated
- [ ] All team members notified of branch changes

