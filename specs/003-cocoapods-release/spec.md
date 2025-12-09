```markdown
# Feature Specification: CocoaPods Release

**Feature Branch**: `003-cocoapods-release`  
**Created**: 2025-12-09  
**Status**: Draft  
**Input**: User description: "a cocoapods release"

---

## Clarifications

### Session 2025-12-09

- Q: Should CocoaPods replace Swift Package Manager or complement it? → A: Complement - SPM remains the primary distribution method; CocoaPods provides broader iOS/macOS ecosystem compatibility
- Q: Should the podspec support both Swift and C sources? → A: Yes, the podspec should include both Swift wrapper and C core for seamless integration
- Q: What minimum iOS/macOS versions should be supported? → A: iOS 13.0+, macOS 10.15+ (aligns with Swift 5.9 availability and modern SwiftUI)
- Q: Should the CocoaPods release version track the Swift package version? → A: Yes, maintain version parity with Swift releases for consistency
- Q: Should we publish to CocoaPods Trunk or use a private spec repo? → A: Publish to CocoaPods Trunk (public repository) for maximum discoverability

## User Scenarios & Testing *(mandatory)*

### User Story 1 - iOS/macOS Developers Can Install via CocoaPods (Priority: P1)

As an iOS/macOS developer using CocoaPods, I want to add ColorJourney to my Podfile and have it integrate seamlessly into my Xcode project, so that I can use the color palette generation features without manual setup.

**Why this priority**: Primary requirement - enables CocoaPods users to access ColorJourney without switching to SPM.

**Independent Test**: Create a new iOS project, add ColorJourney via CocoaPods, import the framework, and generate a color palette successfully.

**Acceptance Scenarios**:

1. **Given** a developer with an existing iOS project using CocoaPods, **When** they add `pod 'ColorJourney'` to their Podfile and run `pod install`, **Then** the ColorJourney framework is integrated without errors
2. **Given** the pod is installed, **When** they import ColorJourney in Swift code, **Then** all public APIs are accessible and autocomplete works correctly
3. **Given** a multi-platform project (iOS + macOS), **When** they install the pod, **Then** it works correctly on both platforms without additional configuration
4. **Given** a developer checking dependencies, **When** they run `pod outdated`, **Then** they can see if a newer version of ColorJourney is available

---

### User Story 2 - Maintain Version Parity with SPM (Priority: P1)

As a package maintainer, I need CocoaPods releases to have the same version numbers as Swift Package Manager releases, so that users can depend on consistent versioning regardless of their dependency management tool.

**Why this priority**: Prevents confusion and ensures consistent experience across package managers.

**Independent Test**: Release process produces matching version tags that work for both SPM and CocoaPods.

**Acceptance Scenarios**:

1. **Given** a new Swift package version is released (e.g., 1.2.0), **When** the CocoaPods release is created, **Then** it uses the same version number (1.2.0)
2. **Given** version tags exist for both SPM and CocoaPods, **When** users check available versions, **Then** they see identical version numbers across both package managers
3. **Given** a breaking change requires a major version bump, **When** released, **Then** both SPM and CocoaPods receive the same major version increment
4. **Given** the CHANGELOG is updated, **When** viewing release notes, **Then** the same version appears for both distribution methods

---

### User Story 3 - Podspec Validates Successfully (Priority: P1)

As a package maintainer, I need the ColorJourney.podspec to pass CocoaPods validation, so that it can be published to CocoaPods Trunk and installed by users without issues.

**Why this priority**: Technical requirement for publishing to CocoaPods Trunk.

**Independent Test**: `pod spec lint ColorJourney.podspec` passes with no warnings or errors.

**Acceptance Scenarios**:

1. **Given** the podspec is created, **When** running `pod spec lint ColorJourney.podspec`, **Then** validation passes without errors
2. **Given** the podspec references source files, **When** validating, **Then** all Swift and C source files are correctly included
3. **Given** the podspec declares platform support, **When** validating, **Then** iOS 13.0+ and macOS 10.15+ are correctly specified
4. **Given** the podspec is ready for publishing, **When** running `pod trunk push ColorJourney.podspec`, **Then** it successfully publishes to CocoaPods Trunk

---

### User Story 4 - CocoaPods Release Automation (Priority: P1)

As a release manager, I need the CocoaPods release process to be automated as part of the existing release workflow, so that publishing to CocoaPods Trunk happens consistently and doesn't require manual steps.

**Why this priority**: Ensures release consistency and reduces human error.

**Independent Test**: Release script can publish to CocoaPods Trunk automatically from the CI/CD pipeline.

**Acceptance Scenarios**:

1. **Given** a new release is tagged (e.g., 1.2.0), **When** the release workflow runs, **Then** the podspec is automatically validated and pushed to CocoaPods Trunk
2. **Given** the automated release fails CocoaPods validation, **When** reviewing CI logs, **Then** clear error messages indicate what needs to be fixed
3. **Given** a manual release is needed, **When** following the release playbook, **Then** documented commands exist for publishing to CocoaPods Trunk
4. **Given** the release is published, **When** checking CocoaPods.org, **Then** the new version appears within 10 minutes

---

### User Story 5 - Documentation Shows Both Installation Methods (Priority: P2)

As a potential user, I want the README to clearly show both Swift Package Manager and CocoaPods installation instructions, so that I can choose the dependency manager that works best for my project.

**Why this priority**: Improves discoverability and user experience for CocoaPods users.

**Independent Test**: README includes clear, copy-pasteable instructions for both SPM and CocoaPods installation.

**Acceptance Scenarios**:

1. **Given** a user reading the README, **When** they look for installation instructions, **Then** they see both SPM and CocoaPods options clearly separated
2. **Given** CocoaPods installation instructions, **When** they copy the Podfile syntax, **Then** it's correct and immediately usable
3. **Given** a user searching for "ColorJourney CocoaPods" on Google, **When** they find the README, **Then** installation instructions are visible without scrolling excessively
4. **Given** version-specific installation, **When** users want a specific version, **Then** they see how to specify versions in both SPM and CocoaPods

---

### Edge Cases

- What happens if CocoaPods validation fails but SPM release succeeds?
- How do we handle platform-specific features that work in SPM but not CocoaPods?
- What if a user has both SPM and CocoaPods trying to include ColorJourney (conflict resolution)?
- How do we deprecate the CocoaPods version if we decide to discontinue support?
- What if CocoaPods Trunk is temporarily unavailable during a release?

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a valid `ColorJourney.podspec` file that includes both Swift wrapper and C core sources
- **FR-002**: Podspec MUST declare minimum deployment targets: iOS 13.0, macOS 10.15
- **FR-003**: Podspec MUST specify Swift version 5.9 compatibility
- **FR-004**: Podspec MUST include all public headers from the C core in `public_header_files`
- **FR-005**: Podspec MUST reference the correct Git repository and tag-based versioning
- **FR-006**: System MUST support automated `pod spec lint` validation as part of CI/CD
- **FR-007**: System MUST support automated `pod trunk push` as part of release workflow
- **FR-008**: CocoaPods version numbers MUST match Swift Package Manager version numbers exactly
- **FR-009**: README MUST include CocoaPods installation instructions alongside existing SPM instructions
- **FR-010**: Podspec MUST include LICENSE file reference (MIT license)
- **FR-011**: Podspec MUST include summary, description, and homepage metadata
- **FR-012**: System MUST ensure CocoaPods releases use the same source tag as SPM releases (no separate tagging)
- **FR-013**: Release playbook MUST document manual CocoaPods publishing steps as fallback
- **FR-014**: System MUST prevent CocoaPods publishing if SPM release fails (coordinated release gates)

### Non-Functional Requirements

- **NFR-001**: CocoaPods validation MUST complete within 5 minutes
- **NFR-002**: CocoaPods publication to Trunk MUST complete within 10 minutes of successful validation
- **NFR-003**: Pod installation time MUST be comparable to equivalent SPM installation (within 20% difference)
- **NFR-004**: CocoaPods release artifacts MUST be deterministic and reproducible across build environments

### Key Entities

- **ColorJourney.podspec**: CocoaPods specification file defining package metadata, source files, dependencies, and platform support
- **CocoaPods Trunk**: Public CocoaPods package repository where ColorJourney will be published
- **Pod Version**: Semantic version number matching SPM releases (e.g., 1.2.0)
- **Platform Deployment Target**: Minimum iOS/macOS versions required to use the pod
- **Source Files**: Swift wrapper (`Sources/ColorJourney/`) and C core (`Sources/CColorJourney/`) included in the pod

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `pod spec lint ColorJourney.podspec` passes with zero errors and zero warnings
- **SC-002**: `pod trunk push ColorJourney.podspec` successfully publishes to CocoaPods Trunk
- **SC-003**: Test iOS project can install ColorJourney via CocoaPods and successfully import and use the framework
- **SC-004**: CocoaPods installation time is within 20% of SPM installation time for equivalent project setup
- **SC-005**: README includes both SPM and CocoaPods installation instructions visible in the first screen of documentation
- **SC-006**: CocoaPods release version matches SPM release version with 100% consistency
- **SC-007**: Automated CI/CD pipeline can publish CocoaPods releases without manual intervention
- **SC-008**: CocoaPods.org listing shows correct version, description, and documentation links within 10 minutes of publication
- **SC-009**: Zero user-reported issues with CocoaPods installation in the first month after release
- **SC-010**: Release playbook includes validated manual fallback procedure for CocoaPods publishing

---

## Assumptions

- **CocoaPods Environment**: Maintainers have CocoaPods Trunk credentials configured for automated publishing
- **Version Coordination**: CocoaPods releases will always follow SPM releases (never precede them)
- **Platform Support**: iOS 13.0+ and macOS 10.15+ are acceptable minimum deployment targets for the user base
- **Git Tags**: Existing release tagging system (e.g., `v1.2.0`) will be used for both SPM and CocoaPods
- **Source Distribution**: CocoaPods will distribute source code only (no prebuilt binaries), matching SPM approach
- **C Core Inclusion**: The C core must be included in the pod for the Swift wrapper to function correctly
- **Build System**: CocoaPods will use Xcode's default build system; no custom CMake integration needed for pod consumers

---

## Out of Scope

- Creating separate versioning schemes for CocoaPods vs SPM
- Supporting CocoaPods for non-Apple platforms (Linux, Windows)
- Creating binary frameworks or XCFrameworks for CocoaPods distribution (source-only distribution)
- Migrating existing SPM users to CocoaPods
- Supporting CocoaPods versions older than 1.10.0
- Creating a private CocoaPods spec repository
- Implementing CocoaPods-specific features not available in SPM
- Backwards compatibility with iOS versions older than 13.0

---

## Implementation Notes

### Xcode-Native Package Creation Approach

Following the proven HexColor pattern, ColorJourney is maintained as an **Xcode-native Swift package** with a clean `Package.swift` structure:

**Key Principles**:
- **Package.swift at repository root** must match the repository name
- **Minimal Package.swift structure** (~60-80 lines) for clarity
- **Public API visibility** is explicit (C headers + Swift wrappers marked public)
- **Git tags use semantic versioning without 'v' prefix** (e.g., `1.0.0` not `v1.0.0`)
- **CocoaPods as distribution layer** consuming the same tagged sources

### Podspec Structure

The podspec references the same git repository and tags as SPM, ensuring single-source-of-truth distribution:

```ruby
Pod::Spec.new do |spec|
  spec.name         = 'ColorJourney'
  spec.version      = '1.0.0'  # Matches SPM version (no 'v' prefix)
  spec.summary      = 'Perceptually uniform color palette generation'
  spec.description  = 'ColorJourney generates aesthetically pleasing color palettes using OKLab color space for perceptual uniformity.'
  spec.homepage     = 'https://github.com/peternicholls/ColorJourney'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { 'Peter Nicholls' => 'email@example.com' }
  spec.source       = { :git => 'https://github.com/peternicholls/ColorJourney.git', :tag => "#{spec.version}" }
  
  spec.ios.deployment_target = '13.0'
  spec.osx.deployment_target = '10.15'
  spec.swift_version = '5.9'
  
  spec.source_files = 'Sources/**/*.{swift,c,h}'
  spec.public_header_files = 'Sources/CColorJourney/include/*.h'
  spec.preserve_paths = 'Sources/CColorJourney/**/*'
end
```

### Package.swift Minimal Structure

The Package.swift remains clean and focused, keeping CocoaPods as a distribution layer:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ColorJourney",  // ⚠️ Must match repository name
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "ColorJourney", targets: ["ColorJourney"])
    ],
    targets: [
        .target(
            name: "ColorJourney",
            dependencies: ["CColorJourney"]
        ),
        .target(
            name: "CColorJourney",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "ColorJourneyTests",
            dependencies: ["ColorJourney"]
        )
    ]
)
```

### Single Source of Truth: Git Tags

Both SPM and CocoaPods consume the same git tag (`1.0.0`), ensuring perfect version parity:

```bash
# Feature 002 (SPM) creates tag
git tag 1.0.0  # No 'v' prefix (SPM requirement)
git push origin 1.0.0

# Feature 003 (CocoaPods) consumes same tag
pod spec lint ColorJourney.podspec
pod trunk push ColorJourney.podspec
```

### Release Workflow Integration

The existing release workflow will be extended:

```
1. Create RC branch (existing)
2. Run tests (existing)
3. Validate podspec (`pod spec lint`)          ← NEW GATE
4. Approve and tag release (existing, no 'v')
5. Publish to SPM (existing)
6. Publish to CocoaPods Trunk (`pod trunk push`)  ← NEW STEP
7. Update badges and documentation (existing)
```

If CocoaPods publication fails, the entire release is rolled back (gates enforce coordination).

### Developer Workflow: Xcode Native

Developers can also create packages using Xcode's native interface (File > New > Package > Library), which:
- Automatically creates Package.swift with correct naming
- Initializes folder structure (Sources/, Tests/)
- Ensures Package.swift and folder name match

ColorJourney follows this standard structure for maximum compatibility.

---

## Related Documentation

- [CocoaPods Guides](https://guides.cocoapods.org/)
- [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
- [CocoaPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)
- ColorJourney Release Playbook (002-professional-release-workflow)

---

**Last Updated**: 2025-12-09
```
