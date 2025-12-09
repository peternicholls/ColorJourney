# Quickstart: Professional Release Workflow

## Prerequisites
- Branch protections enabled on `develop`, `main`, and `release-candidate/*` requiring CI checks (Swift build/test, C build/test, lint).
- GitHub Actions secrets/permissions to create tags and releases.
- Tooling: Swift 5.9+, CMake 3.16+, make, git.

## Steps
1) Prepare `develop`
- Ensure `develop` is up to date and green in CI.
- Update CHANGELOG draft and VersionMapping notes for the upcoming version.

2) Cut a release candidate
- From `develop`: `git checkout -b release-candidate/1.0.0-rc.1`
- Push branch; CI should trigger full Swift + C + lint checks.

3) Iterate RC if needed
- Fix issues directly on the RC branch.
- If a new RC is required, create `release-candidate/1.0.0-rc.2` from `develop` (or fast-forward RC branch) and rerun CI.

4) Promote to release
- When RC checks are green, merge RC into `main` (no back-merges from `main` to `develop`).
- Tag on `main`: `git tag v1.0.0 && git push origin v1.0.0`.
- Delete the RC branch after promotion or abandonment.

5) Build and publish artifacts
- Swift (source-only): archive Sources/, Package.swift, README, LICENSE, CHANGELOG, Docs.
- C library: build static `.a` per platform via CMake, include headers + optional C examples + Docs.
- Attach artifacts to the GitHub release for `v1.0.0`.

6) Refresh badges and mapping
- Update README badges to reflect latest tag and CI status.
- Record Swift→C core dependency mapping for the release.

## Validation checklist
- RC naming matches `release-candidate/X.Y.Z-rc.N`.
- CI checks required by branch protections are green.
- SemVer tag exists on `main` and changelog entry is updated.
- Release artifacts contain only allowed files per language.
- RC branches are deleted post-promotion/abandonment.
