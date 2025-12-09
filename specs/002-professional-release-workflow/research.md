# Research

## Swift toolchain version
- Decision: Standardize on Swift 5.9 (per swift-tools-version) for CI and release automation; document forward-compat testing on macOS latest.
- Rationale: Matches Package.swift baseline; avoids toolchain drift; GitHub Actions `macos-latest` currently ships 5.9/5.10-compatible; minimizes surprise for SPM consumers.
- Alternatives considered: Swift 5.10+ (risk of breaking older consumers until validated); Swift 5.8 (already below declared minimum).

## CI/CD provider and triggers
- Decision: Use GitHub Actions as the primary CI/CD surface, extending existing `core-ci.yml` to add RC/release jobs and branch protections on `develop`, `main`, and `release-candidate/*`.
- Rationale: Existing workflows already run on Actions; branch protection integrates cleanly with Actions-required status checks; keeps automation close to repository.
- Alternatives considered: CircleCI/Azure DevOps (adds infra overhead and split logs); local-only scripts (no enforcement, violates gating needs).

## C testing strategy
- Decision: Keep the Makefile-driven C test harness (`make test-c` running Tests/CColorJourneyTests/test_c_core.c) and surface it in Actions as a required check for RC/release branches; optional future migration to CTest if CMake is adopted for builds.
- Rationale: Harness already used in `core-ci.yml`; deterministic C99 build; minimal dependencies.
- Alternatives considered: Replace with CTest immediately (extra setup without short-term benefit); drop C tests (violates constitution testing gate).

## C build system for releases
- Decision: Introduce CMake (>=3.16) project files for C library packaging that emit static `.a` artifacts for macOS/Linux/Windows; use platform matrices in Actions to build and attach per-platform archives.
- Rationale: CMake is portable and aligns with FR-010; enables future bindings (WASM/JS/Python) to reuse the same targets; simplifies cross-platform static outputs.
- Alternatives considered: Keep Makefile-only (limited portability; harder to matrix-build); Autotools (heavier and inconsistent on Windows).

## Swift release packaging
- Decision: Ship Swift as source-only SPM package with artifacts limited to Sources/, Package.swift, README, LICENSE, CHANGELOG, and `/Docs`; exclude DevDocs, Docker/Makefiles, and C sources.
- Rationale: Matches clarifications; keeps SPM lightweight; avoids binary/xcframework maintenance; aligns with FR-007 and cleanliness goals.
- Alternatives considered: Ship xcframeworks (premature, adds signing/toolchain complexity); include DevDocs/examples (increases size, violates clean artifacts requirement).

## Branching and versioning workflow
- Decision: Rename current `main` to `develop` (preserve history), reserve `main` for releases, and create `release-candidate/X.Y.Z-rc.N` from `develop`; promote by merging to `main` with SemVer tag `vX.Y.Z`, then delete RC branch.
- Rationale: Matches spec acceptance scenarios; keeps release-only history on main; RCs provide stabilization gates; SemVer tags support badges and changelog automation.
- Alternatives considered: GitFlow hotfix/release branches with long-lived maintenance (extra complexity for current scope); trunk-based releases (conflicts with RC gate requirement).

## Badges and automation
- Decision: Use GitHub Actions badges for build status and SemVer tag-based version badge (e.g., shields.io pulling latest Git tag); include a platform support badge covering iOS 13+/macOS 10.15+; cap badges to three.
- Rationale: Meets FR-011/FR-012; leverages existing Actions outputs; minimizes visual clutter.
- Alternatives considered: Self-hosted badge generation (overhead); multiple coverage/lint badges (adds clutter beyond requirements).
