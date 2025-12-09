# Epic Specification: Professional Release Workflow

**Epic Branch**: `002-professional-release-workflow`  
**Created**: 2025-12-09  
**Status**: Draft  
**Input**: User description: "Implement professional release workflow with semantic versioning, separate Swift and C package releases, multi-platform support (currently Swift/C, future WASM/website/iOS/JS/Python)"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Establish Git Branching Strategy (Priority: P1)

As a maintainer, I need a clear branching strategy that supports continuous development and production releases, so that the codebase remains stable while new features are being developed.

**Why this priority**: Foundation for all release management. Without a clear branching strategy, all subsequent release processes will be chaotic and error-prone.

**Independent Test**: Git workflow is established and documented; `develop` branch exists with protection rules; main/release branches follow the specified pattern.

**Acceptance Scenarios**:

1. **Given** the repository currently uses `main` as development branch, **When** the rename and branching strategy is implemented, **Then** `develop` becomes the primary development branch and `main` is reserved for releases only
2. **Given** a feature is ready for development, **When** a developer creates a branch, **Then** it follows the naming pattern and branches from `develop`
3. **Given** the release workflow is active, **When** looking at the branch list, **Then** `develop`, `main`, and release candidate branches are clearly distinguished
4. **Given** CI/CD pipelines are configured, **When** code is pushed to different branches, **Then** appropriate checks run (e.g., full tests on develop, release checks on RC branches)

---

### User Story 2 - Implement Release Candidate Workflow (Priority: P1)

As a release manager, I need to create release candidate branches that trigger comprehensive testing before promotion to final release, so that releases are validated before being published.

**Why this priority**: Critical for quality assurance. Release candidates ensure all tests pass and builds succeed before promoting to stable release.

**Independent Test**: RC workflow can be executed end-to-end; RC branches can be created, tested, and promoted or iterated.

**Acceptance Scenarios**:

1. **Given** `develop` branch is ready for release, **When** creating a release candidate (e.g., `release-candidate/1.0.0-rc.1`), **Then** it branches from `develop` with the RC version tag
2. **Given** an RC branch exists, **When** CI/CD runs, **Then** all tests (unit, integration, build verification) execute automatically
3. **Given** RC tests pass, **When** the release is approved, **Then** code is merged/tagged to `main` as version `1.0.0`
4. **Given** RC tests fail, **When** fixes are applied to the RC branch, **Then** the version increments to `rc.2`, `rc.3`, etc. and tests re-run
5. **Given** an RC is abandoned, **When** the branch is deleted, **Then** the RC is marked as superseded or archived for historical reference

---

### User Story 3 - Semantic Versioning Release Tagging (Priority: P1)

As a package consumer, I need releases to follow Semantic Versioning 2.0.0 so that I can understand the impact of upgrading (major/minor/patch).

**Why this priority**: Enables users to make informed dependency decisions and ensures consistent versioning across releases.

**Independent Test**: Release tags follow SemVer format; Git tags correctly mark release versions; CHANGELOG reflects version numbering.

**Acceptance Scenarios**:

1. **Given** a release is promoted from RC, **When** tagging for release on `main`, **Then** the tag follows semantic versioning format (e.g., `v1.0.0`, `v1.1.0`, `v2.0.0`)
2. **Given** users query available versions, **When** listing releases, **Then** they see all tagged versions in SemVer order
3. **Given** a user depends on ColorJourney, **When** they check dependencies, **Then** the version is clearly communicated as major.minor.patch
4. **Given** a breaking change is introduced, **When** released, **Then** the major version is incremented (e.g., `1.x.x` → `2.0.0`)

---

### User Story 4 - Multi-Platform Release (Swift vs C) (Priority: P1)

As a package maintainer, I need to release Swift and C libraries separately with independent versioning, so that language-specific consumers get the right packages for their needs.

**Why this priority**: ColorJourney serves multiple language ecosystems. Separate releases allow each to version independently based on their API stability.

**Independent Test**: Both Swift SPM package and C library can be released independently; release artifacts are correctly packaged for each platform.

**Acceptance Scenarios**:

1. **Given** a release is tagged, **When** processing the release, **Then** two distinct packages are generated: ColorJourney (Swift) and libcolorjourney (C)
2. **Given** a Swift-only API change, **When** released, **Then** only the Swift package version increments (C version remains stable)
3. **Given** a C core optimization, **When** released, **Then** only the C library version increments if the API is unchanged
4. **Given** both Swift and C components change, **When** released, **Then** both packages receive new versions and are coordinated with a unified release announcement
5. **Given** a user wants the C library, **When** they download, **Then** they get a clean C library distribution (headers, built library, no Swift/DevDocs clutter)

---

### User Story 5 - Future-Proof Multi-Language Architecture (Priority: P2)

As an architect, I need the release infrastructure to support future language bindings (WASM, TypeScript/JavaScript, Python, iOS/Mac app, etc.), so that adding new platforms doesn't require rebuilding the entire CI/CD system.

**Why this priority**: Enables scaling the project to multiple platforms without technical debt. Foundation for future growth.

**Independent Test**: Architecture documented; build system supports modular language-specific releases; CI/CD can be extended for new platforms.

**Acceptance Scenarios**:

1. **Given** the architecture is designed, **When** reviewing the release structure, **Then** it's clear how to add WASM, JS, or Python bindings
2. **Given** a future WASM binding is needed, **When** implementing it, **Then** minimal changes to CI/CD are required (no re-architecting of build system)
3. **Given** multiple language bindings exist, **When** releasing, **Then** each binding can be versioned and released independently while coordinating on the C core version
4. **Given** a C core version is released, **When** documented, **Then** all language bindings know which C core version they depend on
5. **Given** the repository grows with multiple platforms, **When** reviewed, **Then** the build and release system remains maintainable and understandable

---

### User Story 6 - Clean Release Artifacts (Priority: P2)

As a user downloading a release, I need release packages to contain only what's necessary for my use case, so that I'm not downloading irrelevant documentation or development artifacts.

**Why this priority**: Improves user experience; reduces download sizes; makes releases professional and focused.

**Independent Test**: Release artifacts are audited; unnecessary files (DevDocs, Makefile, examples, Docker files) are excluded from language-specific releases.

**Acceptance Scenarios**:

1. **Given** a release is generated, **When** downloading the Swift SPM package, **Then** it contains only source code, Package.swift, and minimal documentation (README, LICENSE, CHANGELOG)
2. **Given** a C library release, **When** downloaded, **Then** it includes headers, built libraries, C examples (optional), and minimal docs—no Swift code, no DevDocs
3. **Given** release artifacts, **When** extracted, **Then** directory structure is clean and immediately usable without navigating through development docs
4. **Given** documentation is needed, **When** users want it, **Then** they can access it on GitHub pages or from the development repository, not in release artifacts

---

### User Story 7 - Essential Badges and Release Information (Priority: P2)

As a potential user, I need clear, minimal badges on the README that show release status, build health, and version, so that I can quickly assess project maturity without documentation clutter.

**Why this priority**: First impression matters; essential information is visible; avoids visual clutter from non-essential badges.

**Independent Test**: README includes only critical badges; deprecated or clutter badges are removed; badges are accurate and auto-update.

**Acceptance Scenarios**:

1. **Given** the README is displayed, **When** scanning the top, **Then** I see only essential badges: latest version, build status, platform support
2. **Given** a new release is published, **When** the badge updates, **Then** it reflects the new version without manual intervention
3. **Given** CI/CD runs, **When** tests pass/fail, **Then** the build status badge accurately reflects the current state
4. **Given** multiple platforms are supported, **When** viewing the README, **Then** platform support is shown clearly (iOS 13+, macOS 10.15+, etc.) without excessive badge clutter

---

### Edge Cases

- What happens if an RC build fails at the last minute before release?
- How do we handle a critical bug discovered after an RC is released to the wild?
- What if both Swift and C APIs have breaking changes at the same time?
- How do we maintain backward compatibility guidance for major version bumps?
- What if a release artifact generation fails midway?
- How do we handle releases for legacy C-only users if the repo gains new language bindings?

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support renaming `main` branch to `develop` as the primary development branch without losing commit history
- **FR-002**: System MUST establish `main` as the stable release branch, updated only when code is released
- **FR-003**: System MUST support creation of release candidate branches with the naming pattern `release-candidate/X.Y.Z-rc.N` where X.Y.Z follows Semantic Versioning 2.0.0
- **FR-004**: System MUST automatically trigger CI/CD pipelines on RC branch creation to run all unit tests, integration tests, and build verification
- **FR-005**: System MUST support promotion of RC branches to final release versions (creating Git tags like `vX.Y.Z`)
- **FR-006**: System MUST prevent merging back to `develop` from `main` to maintain branching separation (RC → main only, never main → develop)
- **FR-007**: Swift package release MUST generate artifacts containing only Swift source code, Package.swift, minimal README, LICENSE, and CHANGELOG—excluding DevDocs, Dockerfile, Makefile, C sources, and examples
- **FR-008**: C library release MUST generate artifacts with headers (`.h`), built static libraries (`.a`), C compilation examples, minimal README, LICENSE, and CHANGELOG—excluding Swift code, Package.swift, and DevDocs
- **FR-009**: System MUST support independent versioning of Swift and C packages while maintaining a coordinated C core version reference
- **FR-010**: System MUST implement modern CMake build system for C library compilation, supporting cross-platform builds (macOS, Linux, Windows)
- **FR-011**: System MUST configure README to display only essential badges: version badge, build status badge, platform support, without clutter from non-critical information
- **FR-012**: System MUST update badge information automatically when releases are published (version badge reflects latest tag)
- **FR-013**: System MUST document the release architecture clearly, including how future language bindings (WASM, TypeScript, Python, iOS/macOS app) can be integrated without redesigning the release system
- **FR-014**: System MUST maintain a CHANGELOG following Keep a Changelog format, with separate sections for each release version and clear SemVer compatibility notes
- **FR-015**: System MUST support re-releasing RC versions if fixes are required (e.g., rc.1 → rc.2) without manual intervention
- **FR-016**: System MUST prevent accidental releases from non-release branches through branch protection rules and CI/CD gates
- **FR-017**: System MUST provide a documented release playbook for maintainers detailing step-by-step processes for creating RC, approving release, and handling failures

### Key Entities

- **Release Candidate (RC)**: A branch (`release-candidate/X.Y.Z-rc.N`) created from `develop` that undergoes comprehensive testing before promotion to release
- **Release Tag**: A Git tag (`vX.Y.Z`) marking a stable, versioned release on the `main` branch
- **Semantic Version**: Version number format `MAJOR.MINOR.PATCH` (e.g., `1.0.0`) following SemVer 2.0.0 spec
- **Build Artifact**: Language-specific package distribution (Swift SPM or C library) generated from a release
- **Release Branch**: The `main` branch serving as the stable, released codebase
- **Development Branch**: The `develop` branch (renamed from `main`) serving as the primary development line

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Repository successfully transitions from `main` as development to `develop` with zero loss of commit history or branches
- **SC-002**: All existing CI/CD pipelines adapt to the new branching strategy with no regressions in test coverage or build times
- **SC-003**: Release candidate workflow can be executed end-to-end in under 30 minutes (from RC creation to approval or fix iteration)
- **SC-004**: All RC builds and tests complete successfully and consistently pass, with 100% reproducibility across runs
- **SC-005**: Released packages (Swift SPM and C library) have verified clean artifact contents (no unwanted files, correct directory structure)
- **SC-006**: Version badges on README update automatically within 5 minutes of a new release being published
- **SC-007**: Documentation for the release architecture is clear enough that a new maintainer can onboard in under 2 hours
- **SC-008**: Future language binding integration (WASM, TypeScript, Python, etc.) requires fewer than 3 new CI/CD jobs to be created
- **SC-009**: Release playbook is followed by 100% of releases with zero deviations or manual workarounds
- **SC-010**: Swift and C packages can be released independently without coordinating version numbers (unless breaking changes in C core)
- **SC-011**: README contains exactly 3-4 essential badges; non-critical badges are removed (achieved through audit and cleanup)
- **SC-012**: All release tags follow SemVer 2.0.0 format with 100% consistency

---

## Assumptions

- **Git/GitHub**: Repository has admin access to configure branch protection rules, workflows, and release automation
- **Build System**: C library will use CMake as the modern build standard; Swift uses existing SPM (no changes needed there)
- **Testing**: Existing test suite is comprehensive and runs quickly enough for RC gates (likely <5 minutes)
- **Future Platforms**: WASM, TypeScript/JavaScript, Python, and iOS/macOS app bindings will be added as separate subdirectories/modules, not integrated into existing C or Swift code paths
- **Release Frequency**: Releases will be made at least monthly (not high-frequency continuous deployment)
- **Documentation**: Existing DevDocs will remain in the repository but excluded from release artifacts
- **Versioning**: Starting version is `1.0.0` (as per existing CHANGELOG); all future releases follow SemVer strictly

---

## Out of Scope

- Changing or refactoring the C core implementation itself (already complete and tested)
- Adding new features to ColorJourney (this epic is infrastructure-only)
- Implementing actual language bindings for WASM, TypeScript, Python, or iOS/macOS app (architecture designed to support them, but not implemented yet)
- Detailed CI/CD workflow files (GitHub Actions YAML specifics—will be separate implementation tasks)
- Internal performance optimizations or algorithmic improvements
- Changes to API signatures or public interfaces (system must remain API-compatible)

---

## Implementation Notes

### Branching Strategy Summary

```
main (stable releases only)
  ↑ (merge RC when approved)
  |
release-candidate/X.Y.Z-rc.N (testing gates)
  ↑ (create from develop)
  |
develop (primary development line, renamed from main)
  ↑ (merge feature branches here)
  |
feature/* (feature branches)
```

### Build System Modern Tools

- **C Library**: CMake 3.16+ for cross-platform builds
  - Supports macOS, Linux, Windows out of the box
  - Easy to extend for embedded/custom platforms
  - Can output static/dynamic libraries and prebuilt binaries

- **Swift Package**: Existing SPM system (no changes required)

- **Future Extensibility**: Each new language binding gets its own build system (Cargo for Rust, Webpack for JS, etc.) but depends on the C core output

### Release Artifact Strategy

```
Release v1.0.0
  ├── swift-colorjourney-1.0.0.tar.gz (Swift SPM package)
  │   ├── Sources/
  │   ├── Package.swift
  │   ├── README.md
  │   ├── LICENSE
  │   └── CHANGELOG.md
  │
  └── libcolorjourney-1.0.0.tar.gz (C library)
      ├── include/ (headers)
      ├── lib/ (built libraries: .a, maybe .so)
      ├── examples/ (C usage examples)
      ├── README.md
      ├── LICENSE
      └── CHANGELOG.md
```

---

## Related Documentation

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Flow / Git Branching Strategies](https://guides.github.com/introduction/flow/)
- [CMake Documentation](https://cmake.org/documentation/)
- [Swift Package Manager](https://swift.org/package-manager/)
