# Branching Strategy

**Purpose**: Define the Git branching model for ColorJourney  
**Last Updated**: 2025-12-09

---

## Overview

ColorJourney uses a **modified Git Flow** branching strategy that supports:
- Continuous development on `develop`
- Stable releases on `main`
- Release candidates on `release-candidate/*` branches
- Feature branches for larger work (optional, PRs use feature branches)

```
develop (primary dev)
  ↓
release-candidate/X.Y.Z-rc.N (testing & stabilization)
  ↓
main (stable releases only)
  ↓
vX.Y.Z (tagged releases)
```

---

## Branches

### Main (Stable Releases)

**Purpose**: Production-ready releases only

**Characteristics**:
- Protected branch (no direct pushes)
- Receives merges only from release-candidate/* branches
- Each commit should have a corresponding Git tag
- No merges back to develop

**Created from**: release-candidate/* branches
**Deleted**: Never (history preserved)
**Naming**: `main`

**Protection Rules**:
- Require code reviews (1 approval minimum)
- Require status checks to pass (all CI/CD)
- Dismiss stale PR approvals
- Block direct pushes (PR merge only)
- Require branches to be up to date before merging

### Develop (Primary Development)

**Purpose**: Main integration branch for features and fixes

**Characteristics**:
- Primary branch for feature development
- Should be green in CI/CD at all times
- Feature branches created from here
- Release candidates branched from here

**Created from**: Initial repository setup
**Deleted**: Never (history preserved)
**Naming**: `develop`

**Protection Rules**:
- Require code reviews (1 approval minimum)
- Require status checks to pass (all CI/CD)
- Dismiss stale PR approvals
- Block direct pushes (PR merge only)
- Require branches to be up to date before merging

### Release Candidate (Testing & Stabilization)

**Purpose**: Prepare for release with comprehensive testing

**Characteristics**:
- Created from `develop` when release is planned
- Triggers full CI/CD test suite on creation
- Can receive hotfixes during RC testing
- Deleted after promotion to main (via merge) or abandonment
- Allows multiple RCs (rc.1, rc.2, etc.) for iteration

**Created from**: `develop` via `./scripts/create-rc-branch.sh`
**Deleted**: After promotion or abandonment via `./scripts/delete-rc-branch.sh`
**Naming**: `release-candidate/X.Y.Z-rc.N`

**Example names**:
- `release-candidate/1.0.0-rc.1` (first attempt)
- `release-candidate/1.0.0-rc.2` (second iteration, bugs fixed)
- `release-candidate/1.1.0-rc.1` (minor version bump)
- `release-candidate/2.0.0-rc.1` (major version with breaking changes)

**Protection Rules**:
- Require status checks to pass (all CI/CD gates)
- Prevent deletion (ensure deliberate cleanup)

### Feature Branches (Optional)

**Purpose**: Develop features before merging to develop

**Characteristics**:
- Created from `develop` for significant features
- Short-lived (typically < 2 weeks)
- Deleted after PR merge to develop

**Created from**: `develop`
**Deleted**: After PR merge
**Naming**: `feature/short-description` or `bugfix/issue-number`

**Examples**:
- `feature/oklab-optimization`
- `bugfix/234-ios-crash`

---

## Workflow: Feature Development

### 1. Create Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### 2. Develop & Commit

```bash
# Make changes
git add .
git commit -m "feat: implement feature"
git push -u origin feature/my-feature
```

### 3. Create Pull Request

- Open PR against `develop`
- Add description and acceptance criteria
- Request reviewers

### 4. Address Review

- Make requested changes
- Commit and push
- Re-request review once resolved

### 5. Merge

- Merge PR to `develop` (squash or merge commit)
- Delete feature branch after merge

---

## Workflow: Release Preparation

### 1. Plan Release

On `develop`:
- Update CHANGELOG.md with new version
- Update VersionMapping.md (if needed)
- Verify README and documentation

### 2. Create Release Candidate

```bash
./scripts/create-rc-branch.sh 1.0.0 1
```

This:
- Creates `release-candidate/1.0.0-rc.1` from `develop`
- Pushes to remote
- Triggers CI/CD pipeline

### 3. Test RC

- Monitor CI/CD results
- Perform manual testing if needed
- Report issues

### 4a. Promote to Release (if passing)

```bash
./scripts/tag-release.sh 1.0.0
```

This:
- Merges RC to `main` with merge commit
- Creates Git tag `v1.0.0`
- Pushes tag (triggers artifact generation)

### 4b. Fix & Retry (if failing)

```bash
git checkout release-candidate/1.0.0-rc.1
# Make fixes
git push origin release-candidate/1.0.0-rc.1
# CI re-runs automatically
```

If multiple fixes needed:

```bash
./scripts/create-rc-branch.sh 1.0.0 2
# This creates release-candidate/1.0.0-rc.2
```

### 5. Cleanup

```bash
./scripts/delete-rc-branch.sh 1.0.0 1
```

---

## Branch Protection Rules Summary

| Branch | Require Reviews | Require Checks | Dismiss Stale | Block Direct Push | From Branch |
|--------|-----------------|---|---|---|---|
| `main` | Yes (1+) | Yes | Yes | Yes | RC only |
| `develop` | Yes (1+) | Yes | Yes | Yes | Features |
| `release-candidate/*` | No | Yes | No | Yes | develop |

---

## Naming Conventions

### Release Candidate Branches

Format: `release-candidate/MAJOR.MINOR.PATCH-rc.N`

- MAJOR.MINOR.PATCH: Semantic version
- rc: Literal string (release candidate)
- N: Increment number (1, 2, 3, ...)

Examples:
- ✓ `release-candidate/1.0.0-rc.1`
- ✓ `release-candidate/2.3.4-rc.5`
- ✗ `release-candidate/1.0.0` (missing -rc.N)
- ✗ `rc/1.0.0` (wrong prefix)

### Feature Branches

Format: `feature/short-description` or `bugfix/issue-number`

Examples:
- ✓ `feature/perceptual-bias-tuning`
- ✓ `bugfix/334-memory-leak`
- ✗ `my-feature` (vague)
- ✗ `feature-1.0.0` (version in branch)

---

## Protection Rule Implementation

### GitHub Settings

1. Go to: Settings → Branches → Branch protection rules
2. Create rule for `main`:
   - Pattern: `main`
   - Require PR reviews before merging: ✓
   - Require status checks to pass: ✓
   - Require branches to be up to date: ✓
   - Restrict who can push: ✓ (admins only)

3. Create rule for `develop`:
   - Pattern: `develop`
   - Require PR reviews before merging: ✓
   - Require status checks to pass: ✓
   - Require branches to be up to date: ✓
   - Restrict who can push: ✓ (admins only)

4. Create rule for `release-candidate/*`:
   - Pattern: `release-candidate/*`
   - Require status checks to pass: ✓
   - Restrict who can force-push: ✓ (admins only)

---

## Merging Strategy

### Merge Commits (Prefer)

- Use merge commits for feature PRs to `develop`
- Preserves branch history
- Clear commit graph: `git log --graph`

### Squash Commits (Optional)

- Use squash for small fixes or cleanup commits
- Keeps develop history cleaner
- Less granular history

### Fast-Forward Merges (Not for main)

- Never use for `main` (need merge commits for clarity)
- Can use for feature branches (optional)

---

## FAQ

**Q: Can I merge a feature directly to main?**  
A: No. All code must go through develop first, then RC, then main.

**Q: What if I accidentally push to main?**  
A: Branch protection rules prevent this. If you have admin override, revert immediately: `git reset --hard HEAD~1`

**Q: How long does an RC stay open?**  
A: Typically 1-7 days depending on test results. Aim for < 24 hours.

**Q: Can I delete develop or main?**  
A: No, branch protection rules prevent deletion. These are permanent branches.

**Q: What if I need to cherry-pick a commit to main?**  
A: Create an RC from develop, include the fix, then promote. Don't commit directly to main.

