# Release Gates & Quality Policy

**Purpose**: Define formal release gates and quality criteria that must be satisfied before RC creation, promotion, and artifact publication.

**Last Updated**: 2025-12-09

---

## Release Gate 1: Pre-Release Checklist (Before RC Creation)

### Branch Status
- [ ] `develop` branch is up-to-date with main development line
- [ ] All required CI checks pass on `develop`
- [ ] No pending security vulnerabilities (CVSS ≥ 7.0)
- [ ] Code review quorum satisfied (minimum 1 approval for patch/minor, 2 for major)

### Documentation
- [ ] CHANGELOG.md draft updated with version entry
- [ ] README.md reviewed for accuracy (no broken links, current examples)
- [ ] API documentation is current
- [ ] Migration guides prepared (if major version bump)

### Version Coordination
- [ ] SemVer version number decided (major/minor/patch rationale documented)
- [ ] C core version requirement documented for Swift releases
- [ ] Breaking changes listed if applicable

**Action**: Create RC branch when all items checked.

---

## Release Gate 2: RC Testing & Validation (During RC Lifecycle)

### CI/CD Requirements
- [ ] Unit tests pass (Swift + C)
- [ ] Integration tests pass (Swift + C)
- [ ] Build succeeds on all target platforms (macOS, Linux, Windows for C; Apple platforms for Swift)
- [ ] Linting/code quality checks pass
- [ ] Security scan passes (CVSS < 7.0)
- [ ] Reproducibility check passes: artifact rebuild produces identical hashes

### Artifact Validation
- [ ] Swift artifact audit passes (no C sources, DevDocs, or Dockerfile included)
- [ ] C artifact audit passes (no Swift sources, Package.swift, or DevDocs included)
- [ ] Headers are complete and correct
- [ ] README/LICENSE/CHANGELOG included in both artifact types
- [ ] Docs/ directory correctly included; DevDocs/ excluded

### Timing
- [ ] RC workflow end-to-end completes in < 30 minutes
- [ ] No CI/CD timeouts or flakes

**Action**: Proceed to promotion when all items green. If any fail, fix on RC branch and increment rc.N.

---

## Release Gate 3: Promotion to Main (Before Tagging)

### Final Validation
- [ ] All RC Gate 2 checks are current (re-run if > 1 hour old)
- [ ] CHANGELOG.md finalized with release date
- [ ] Release notes prepared (if announcement needed)
- [ ] Version mapping updated (Swift→C core dependency)

### Merge & Tag
- [ ] RC branch merged/fast-forwarded to `main` without merge conflicts
- [ ] Git tag `vX.Y.Z` created on `main`
- [ ] RC branch deleted after promotion

**Action**: Push tag and trigger artifact packaging.

---

## Release Gate 4: Artifact Publishing (After Tagging)

### Artifact Generation
- [ ] Swift package archive created and checksum verified
- [ ] C library static binaries built for all platforms, checksums verified
- [ ] Artifacts uploaded to GitHub release assets
- [ ] Release notes published with asset links

### Badge & Metadata Updates
- [ ] Version badge updated (reflects latest tag)
- [ ] Build status badge reflects RC branch status
- [ ] Platform support badge accurate
- [ ] Version mapping documented in releases

### Post-Release Validation
- [ ] All badges update within 5 minutes
- [ ] Release assets are publicly downloadable
- [ ] Artifact hashes stable across re-downloads

**Action**: Mark release as complete when all items verified.

---

## Release Gate 5: Post-Release (Immediate Follow-up)

### Hygiene
- [ ] Develop branch synchronized if any release-only updates made
- [ ] RC branch deleted if not already removed
- [ ] Release announcement posted (if applicable)

### Monitoring
- [ ] No critical bugs reported within 24 hours
- [ ] Build badges reflect current state accurately

**Action**: Resume normal development.

---

## Edge Case Handling

### RC Build Failure
- **Scenario**: Test fails mid-RC lifecycle.
- **Action**: Fix on RC branch, force-push or rebase, increment rc.N, re-run CI.
- **Gate**: Cannot promote until all checks pass.

### Failed Artifact Generation
- **Scenario**: One platform (e.g., Windows C build) fails after RC passes.
- **Action**: Fix build issue on RC branch (may require rc.N increment), re-run full packaging.
- **Gate**: Cannot tag unless all artifacts succeed.

### Post-Release Bug Discovery
- **Scenario**: Critical bug found in released version X.Y.Z.
- **Action**: 
  1. If fixable without API change: create patch release X.Y.(Z+1) from main
  2. If API change needed: branch new RC from develop, increment version appropriately
  3. Document in CHANGELOG under "Hotfixes" section

### Abandoned RC
- **Scenario**: RC is deemed unsuitable for release (e.g., design flaw discovered).
- **Action**:
  1. Delete RC branch
  2. Document in issue/PR why RC was abandoned
  3. Return to develop for redesign/fixes
  4. Recut RC when ready (can reuse same version or bump as needed)

### Reproducibility Failure
- **Scenario**: Artifact rebuild produces different hash (non-deterministic build).
- **Action**:
  1. Do not promote release
  2. Investigate root cause (toolchain drift, timestamp issues, etc.)
  3. Document findings and fix
  4. Recut RC and re-run reproducibility check
  5. Only proceed when hashes match

---

## Checklist Quick Reference

| Gate | Key Checks | Block If |
|------|-----------|----------|
| **Pre-RC** | Develop green, docs updated, version decided | Any CI failure, incomplete changelog |
| **RC Testing** | All tests pass, artifacts audit clean, <30 min | Any test failure, artifact issues, reproducibility mismatch |
| **Promotion** | RC checks current, CHANGELOG final, merge clean | Merge conflicts, missing version mapping |
| **Publishing** | Artifacts built, badges update <5 min | Build/badge failures |
| **Post-Release** | Announce, monitor, cleanup | (Informational) |

---

## Responsibilities

- **Release Manager**: Owns gate progression, coordinates fixes, makes go/no-go decisions
- **CI/CD Automation**: Enforces checks, blocks invalid promotions, updates badges
- **Developers**: Fix issues on RC branch, provide input on version bumping
- **QA** (if applicable): Sign off on artifact audit and testing

---

## Tooling & Automation

- **Branch Protection**: GitHub branch rules enforce CI checks before merge
- **CI/CD Workflows**: `.github/workflows/core-ci.yml`, `artifact.yml`, `badge-update.yml` run required checks
- **Scripts**: `scripts/create-rc-branch.sh`, `scripts/tag-release.sh`, `scripts/package-swift.sh`, `scripts/package-c.sh`, `scripts/audit-artifacts.sh`
- **Monitoring**: GitHub Actions status badges, artifact integrity checks

