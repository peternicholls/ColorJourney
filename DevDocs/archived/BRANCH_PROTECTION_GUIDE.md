# GitHub Branch Protection Configuration Guide

## Overview

This guide provides step-by-step instructions for configuring GitHub branch protections for the Color Journey professional release workflow. These protections enforce the required CI/CD checks and prevent invalid merges that could compromise release integrity.

**Branch & Tag Strategy**: 
- `develop` = primary development branch (renamed from main per T005)
- `release-candidate/*` = temporary RC testing branches (allow iteration during testing)
- **Tags** `v*.*.*` = releases (protected, auto-triggers artifact generation and badge updates via GitHub Releases)

**Required Access**: GitHub repository owner or admin with branch protection permissions

**Estimated Time**: 15-20 minutes

---

## Prerequisites

Before starting, ensure:
- You have GitHub repository admin access
- T005 is complete: `main` branch has been renamed to `develop`
- The following CI/CD workflows are created and tested:
  - `.github/workflows/core-ci.yml` ✓
  - `.github/workflows/release-artifacts.yml` ✓ (triggers on `v*.*.*` tags)
  - `.github/workflows/badge-update.yml` ✓
- At least one successful workflow run on each branch type and tag
- Team has reviewed [BRANCHING_STRATEGY.md](../DevDocs/BRANCHING_STRATEGY.md)

---

## Configuration Steps

### Step 1: Navigate to Branch Protection Settings

1. Go to GitHub repository: https://github.com/peternicholls/ColorJourney
2. Click **Settings** (top right)
3. In left sidebar, click **Branches** under "Code and automation"
4. You should see "Branch protection rules" section

---

### Step 2: Create Protection for Release Tags (`v*.*.*`)

Click **Add rule** and configure:

#### Basic Settings
- **Branch name pattern**: `v*`
- **Note**: GitHub will interpret this as a **tag protection rule** for any tag starting with `v`

#### Require status checks to pass before merging
✅ **Enable** (checkbox)

**Status checks to require**:
- `build-macos` (from core-ci.yml)
- `build-ios` (from core-ci.yml)
- `lint` (from core-ci.yml)
- `build-c` or equivalent C build job (if exists in core-ci.yml)

**Require branches to be up to date before merging**:
✅ **Enable** - Ensures tag is created from a tested commit

#### Require pull request reviews before merging
✅ **Enable** (checkbox)
- **Number of approvals**: `2` (strict for releases)
- **Dismiss stale pull request approvals when new commits are pushed**: ✅ **Enable**

#### Require conversation resolution before merging
✅ **Enable** (checkbox)

#### Restrict who can push to matching branches
✓ **Recommend restricting to release team only** - Prevents accidental tag creation

#### Allow force pushes
✗ **Disable** - Never allow force push to release tags

#### Allow deletions
✗ **Disable** - Prevent accidental deletion of release tags

#### Include administrators
✅ **Enable** - Tag protections apply to admins too

**Save rule** by clicking **Create**

---

### Step 3: Create Protection for `develop` Branch

Click **Add rule** and configure:

#### Basic Settings
- **Branch name pattern**: `develop`

#### Require status checks to pass before merging
✅ **Enable** (checkbox)

**Status checks to require**:
- `build-macos` (from core-ci.yml)
- `build-ios` (from core-ci.yml)
- `lint` (from core-ci.yml)
- `build-c` or equivalent C build job (if exists in core-ci.yml)

**Require branches to be up to date before merging**:
✅ **Enable** - Ensures status checks are run on latest code

#### Require pull request reviews before merging
✅ **Enable** (checkbox)
- **Number of approvals**: `1` (can be `2` for stricter governance)
- **Dismiss stale pull request approvals when new commits are pushed**: ✅ **Enable**
- **Require code review from code owners**: ✗ (Optional, disable unless CODEOWNERS file exists)

#### Require conversation resolution before merging
✅ **Enable** (checkbox) - Ensures all comments/discussions are addressed

#### Require signed commits
✗ **Disable** (Optional, enable if your team uses GPG signing)

#### Require status checks from required status checks to pass before merging
✅ **Enable**

#### Restrict who can push to matching branches
✗ **Disable** - Developers can push feature branches; only PR merges to develop controlled

#### Include administrators
✅ **Enable** - Branch protections apply to admins too (prevents accidental direct pushes)

#### Restrict dismissal of pull request reviews
✗ **Disable** - Allow admins to override if needed

**Save rule** by clicking **Create**

---

### Step 4: Create Protection for `release-candidate/*` Branches

Click **Add rule** and configure:

#### Basic Settings
- **Branch name pattern**: `release-candidate/*`

#### Require status checks to pass before merging
✅ **Enable** (checkbox)

**Status checks to require**:
- `build-macos`
- `build-ios`
- `lint`
- C build job
- Artifact packaging checks (if available)

**Require branches to be up to date before merging**:
✅ **Enable** - RC branch should be up-to-date before promotion to release

#### Require pull request reviews before merging
✅ **Enable** (checkbox)
- **Number of approvals**: `1` (less strict for RC since it's temporary)
- **Dismiss stale pull request approvals when new commits are pushed**: ✅ **Enable**

#### Require conversation resolution before merging
✅ **Enable** (checkbox)

#### Restrict who can push to matching branches
✗ **Disable** - Release team can push fixes directly to RC branch during iteration

#### Allow force pushes
✗ **Disable** - Prevent force push history corruption

#### Allow deletions
✗ **Disable** - Prevent accidental deletion

**Save rule** by clicking **Create**

---

## Post-Configuration Verification

After creating all three branch protection rules, verify:

### Checklist

- [ ] **develop branch protection exists**
  - Status checks enabled
  - PR review required (1 approval)
  - Admin included in restrictions

- [ ] **release tag protection (`v*`) exists**
  - Status checks enabled
  - Tag protection rule (not branch)
  - Admin included in restrictions
  - Force push disabled
  - Deletions disabled

- [ ] **release-candidate/* protection exists**
  - Status checks enabled
  - PR review required (1 approval)
  - Direct pushes allowed for RC iteration
  - Force push disabled

### Test the Protections

1. **Test develop protection**:
   - Attempt direct push to develop (should be blocked)
   - Create PR to develop with failing CI (should block merge)
   - Create PR with passing CI and 1 approval (should allow merge)

2. **Test release tag protection**:
   - Attempt to create a tag `v1.0.0` locally without RC branch (should be rejected)
   - Create RC, get 2 approvals, then tag release (should succeed)
   - Verify tag triggers release-artifacts.yml workflow
   - Verify badge and Release notes auto-update

3. **Test release-candidate/* protection**:
   - Verify direct pushes to RC branch work (for emergency fixes)
   - Verify CI checks still required
   - Verify merge to release requires approvals

---

## Common Issues & Troubleshooting

### Issue: "Status check is not available"

**Problem**: Required status check not found in the dropdown  
**Solution**:
1. Run at least one successful workflow on the branch
2. The status check must have run and reported back to GitHub
3. Check workflow file `.github/workflows/core-ci.yml` is in the repo
4. Verify workflow has `name:` field matching the job name

### Issue: "Branch rule not appearing"

**Problem**: Created rule but it's not showing up  
**Solution**:
1. Refresh the page
2. Check you're in the correct repository
3. Verify you have admin permissions
4. Try creating the rule again

### Issue: "Can't merge PR due to branch protection"

**Problem**: PR has all approvals but still can't merge  
**Solution**:
1. Check if status checks are all passing (may need to re-run)
2. Verify branch is up-to-date with develop
3. Check if "Dismiss stale approvals" is enabled (approval may have been dismissed)
4. Wait for all status checks to complete (green checkmarks)

### Issue: "Force push still allowed"

**Problem**: User can force push despite protection  
**Solution**:
1. Verify "Allow force pushes" is set to "Dismiss"
2. Check if there are multiple rules for the same branch (conflicting rules)
3. Verify you saved the rule (should see success message)
4. Clear browser cache and retry

### Issue: "Need to bypass protection for emergency"

**Situation**: Critical bug needs immediate release  
**Process**:
1. Temporarily disable the tag protection rule (from Settings > Branches)
2. Create the emergency tag
3. Re-enable the rule immediately
4. Document the emergency in your release notes
5. Consider adding an emergency change process to your playbook

---

## Branch & Tag Protection Rules Summary

| Protection | Pattern | Status Checks | PR Reviews | Force Push | Direct Push | Force Delete |
|-----------|---------|---------------|-----------|-----------|-----------|-------------|
| develop branch | `develop` | ✓ | ✓ (1) | ✗ | ✗ | ✗ |
| release tags | `v*` | ✓ | ✓ (2) | ✗ | ✗ (restricted) | ✗ |
| RC branches | `release-candidate/*` | ✓ | ✓ (1) | ✗ | ✓ | ✗ |

---

## Related Documentation

- [BRANCHING_STRATEGY.md](../DevDocs/BRANCHING_STRATEGY.md) - Workflow explanation
- [RELEASE_PLAYBOOK.md](../DevDocs/RELEASE_PLAYBOOK.md) - Release process
- [RC_WORKFLOW.md](../DevDocs/RC_WORKFLOW.md) - RC details

---

## Quick Reference: Branch Protection Settings

### For copy-paste into GitHub UI

**release tag protection (`v*`)**:
```
Branch name pattern: v*
(GitHub will auto-detect as tag protection rule)
✓ Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Status checks: build-macos, build-ios, lint, [c-build-job]
✓ Require pull request reviews before merging
  - Number of approvals: 2
  - Dismiss stale pull request approvals: YES
✓ Require conversation resolution before merging
✓ Restrict who can push (release team only - or leave empty for admin-only)
✓ Include administrators
✗ Allow force pushes
✗ Allow deletions
```

**develop branch protection**:
```
Branch name pattern: develop
✓ Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Status checks: build-macos, build-ios, lint, [c-build-job]
✓ Require pull request reviews before merging
  - Number of approvals: 1
  - Dismiss stale pull request approvals: YES
✓ Require conversation resolution before merging
✓ Include administrators
```

**release-candidate/* branch protection**:
```
Branch name pattern: release-candidate/*
✓ Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Status checks: build-macos, build-ios, lint, [c-build-job], [artifact-checks]
✓ Require pull request reviews before merging
  - Number of approvals: 1
  - Dismiss stale pull request approvals: YES
✓ Require conversation resolution before merging
✗ Restrict who can push (empty - allow direct pushes for RC iteration)
✓ Include administrators
✗ Allow force pushes
✗ Allow deletions
```

---

## Verification Script

Once protections are in place, run this verification (as a developer):

```bash
#!/bin/bash
# Quick test that branch protections are working

echo "Testing branch protections..."
echo ""

# Test 1: Try to push to develop (should fail)
echo "1. Attempting direct push to develop (should fail)..."
git checkout develop
echo "test" >> .gitkeep
git add .gitkeep
git commit -m "test"
git push origin develop 2>&1 | grep -q "protected\|rejected" && echo "✓ develop protection working" || echo "✗ develop protection NOT working"
git reset --hard HEAD~1

# Test 2: Try to push to release (should fail)
echo ""
echo "2. Attempting to create release tag without approval..."
git tag -a v1.0.0-test -m "Test release tag"
git push origin v1.0.0-test 2>&1 | grep -q "protected\|rejected" && echo "✓ release tag protection working" || echo "✗ release tag protection NOT working"
git tag -d v1.0.0-test 2>/dev/null || true

echo ""
echo "✓ Branch protections verified!"
```

---

**Last Updated**: December 9, 2025  
**Status**: Ready for Implementation  
**Maintainer**: Release Team  

**Next Step**: After completing these configurations, run the verification checklist above and mark T006 as complete.
