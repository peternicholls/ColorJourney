# Data Model

## Entities

### Branch
- Fields: name (`develop`, `main`, `release-candidate/X.Y.Z-rc.N`, `feature/*`), protection rules (required checks, allowed merges), source branch.
- Relationships: `release-candidate/*` branches are created from `develop`; `main` receives merges only from RC branches.
- Validation: RC branch names must match `release-candidate/{MAJOR.MINOR.PATCH}-rc.{N}`; `main` must be fast-forward-only from RC promotions.

### ReleaseCandidate
- Fields: targetVersion (SemVer), rcNumber, sourceBranch (`develop`), status (`open`, `approved`, `abandoned`), requiredChecks (Swift build/test, C build/test, lint), artifacts (Swift source bundle, C static bundle), changelogDraft.
- Relationships: promotes to a Release on `main`; supersedes previous RCs of same targetVersion when rcNumber increments.
- Validation: requiredChecks must be green before promotion; branch deleted after promotion/abandonment; rcNumber increments monotonically per targetVersion.

### Release
- Fields: version (SemVer), tag (`vX.Y.Z`), promotedFrom (ReleaseCandidate), artifacts (Swift package archive, C archive), changelogEntry, badgeUpdates.
- Relationships: maps to VersionMapping entries; tags live on `main`.
- Validation: tag must exist on `main`; changelog section added; badges refreshed from latest tag.

### Artifact
- Fields: type (`swift`, `c`), contents (allowed files), excluded (DevDocs, Dockerfile, Makefile, non-target sources), docs (`Docs/`), packaging format (e.g., `tar.gz`), buildPlatform matrix for C (`macOS`, `Linux`, `Windows`).
- Relationships: produced by ReleaseCandidate/Release pipelines; attached to GitHub release assets.
- Validation: Swift artifacts must be source-only; C artifacts must include headers + static `.a` only.

### VersionMapping
- Fields: swiftVersion (SemVer), requiredCCoreVersion (SemVer), notes (breaking/compat guidance).
- Relationships: referenced by Swift release notes and changelog; updated per Swift release.
- Validation: mapping required for every Swift release; cannot be empty.

### PipelineJob
- Fields: name (`swift-build`, `swift-test`, `c-build`, `c-test`, `lint`, `artifact-package`, `badge-update`), triggers (branches), requiredFor (RC, release), outputs (artifacts, status badges).
- Relationships: attached to branch protections; gates RC promotion.
- Validation: RC merges blocked unless required jobs succeed; release tags blocked unless artifact-package succeeds.

## State Transitions
- `develop` → `release-candidate/X.Y.Z-rc.N`: Create RC branch when release ready.
- RC status: `open` → `approved` (all checks pass) → merge to `main` with tag `vX.Y.Z` → RC branch deleted.
- RC failure loop: `open` → `fix` on same branch → rcNumber incremented if new RC cut.
- Release publication: tag on `main` → build artifacts → upload release assets → update badges + changelog + VersionMapping.
