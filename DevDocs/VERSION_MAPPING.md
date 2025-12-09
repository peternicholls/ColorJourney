# Version Mapping: Swift ↔ C Core Dependencies

## Overview

This document defines the mapping between Swift package releases and their required C core versions. Since Swift and C are released independently but have interdependent functionality, this mapping ensures compatibility and clear versioning expectations.

## Philosophy

- **Independent Versioning**: Swift and C versions follow SemVer independently
- **Explicit Dependency**: Every Swift release documents its minimum required C core version
- **Forward Compatibility**: Swift releases specify minimum C version, allowing newer C releases to work with older Swift
- **Breaking Changes**: C breaking changes trigger Swift major version bumps; C minor/patch don't force Swift changes

## Version Mapping Table

| Swift Version | Minimum C Core Version | Compatibility Notes | Release Date |
|---------------|------------------------|---------------------|--------------|
| 1.0.0         | 1.0.0                  | Initial release; full feature parity | 2025-12-XX   |
| 1.1.0         | 1.0.0+                 | New presets added; no C core changes required | (future)    |
| 2.0.0         | 2.0.0                  | Breaking change in API or OKLab behavior | (future)    |

## Rationale

### Why Independent Versioning?

1. **Different Release Cadences**: C core may receive performance optimizations; Swift may add idiomatic APIs independently
2. **Different Audiences**: C users don't follow Swift releases; Swift users may upgrade independently
3. **Platform Differences**: New Swift features (e.g., for SwiftUI) don't require C changes
4. **Flexibility**: Allows releasing Swift bug fixes without C changes, and vice versa

### Breaking Change Rules

#### Swift Breaking Changes (Major Version Bump)
- API signature changes (e.g., `discrete()` → `discretePalette()`)
- Configuration structure changes
- Default behavior changes
- New required parameters

#### C Breaking Changes (Major Version Bump)
- `ColorJourney_t` structure layout changes
- Function signature changes
- Behavior changes in core algorithms (e.g., different OKLab implementation)
- Memory layout or allocation guarantees

#### Non-Breaking Changes (Minor/Patch)
- C: Performance improvements, new functions, bug fixes
- Swift: New presets, new helper methods, new configuration options
- Either: Bug fixes, documentation improvements

## When to Update the Mapping

1. **New C Release**: If Swift already supports it, update the "+" notation
2. **New Swift Release with C Dependency Change**: Update minimum C version
3. **Breaking Change in Either**: Create new row; old Swift versions pin to compatible C versions
4. **Maintenance Release**: Update this table with actual release date

## Usage

### For Swift Users
Check this table to ensure your C core version is ≥ the minimum listed for your Swift version.

**Example**: If using Swift 1.0.0, you need C core ≥ 1.0.0. Upgrading to C 1.1.0, 1.2.0, etc., is safe.

### For C Users
Note that multiple Swift versions may depend on your C version. When making C releases, communicate in release notes which Swift versions are compatible.

### For Release Process
1. Before releasing Swift, verify all CI tests pass with the target C version
2. Update this table with new rows before cutting a Swift release tag
3. Include the mapping in Swift release notes: *"Requires C core ≥ vX.Y.Z"*

## Dependency Graph

```
Swift 1.0.0 ──requires──> C 1.0.0+
Swift 1.1.0 ──requires──> C 1.0.0+
Swift 2.0.0 ──requires──> C 2.0.0+
```

## Artifact Contents & Multi-Platform Releases

When releasing both Swift and C:

1. **Swift SPM Package**: Includes minimum C version in documentation and release notes
2. **C Static Libraries**: Released as separate per-platform archives (macOS, Linux, Windows)
3. **Unified Release Notes**: Document both Swift and C versions, plus compatibility matrix
4. **Changelog**: Separate [C] and [Swift] sections; cross-reference versions

### Example Release Notes (Unified)

```
# Release: December 9, 2025

## Swift Package v1.0.0
- New: 6 style presets
- Requires C core v1.0.0+
- See [C Core v1.0.0](#c-core) for C-level changes

## C Core v1.0.0
- Initial release
- OKLab color space with fast cube root
- Static library for macOS, Linux, Windows
- See [Swift Package v1.0.0](#swift-package) for Swift integration

## Compatibility
- Swift 1.0.0 ↔ C 1.0.0+
- Tested: Swift 5.9, C99 core on macOS 12+, Ubuntu 20.04 LTS, Windows 10+
```

## Future Extensibility

This mapping provides a foundation for future language bindings:

- **Python v1.0.0**: Requires C core ≥ 1.0.0
- **JavaScript/WASM v1.0.0**: Requires C core ≥ 1.0.0
- **Rust FFI v1.0.0**: Requires C core ≥ 1.0.0

Each binding maintains its own version and dependency mapping, all referencing the canonical C core.

## Questions & Maintenance

- **Q: Why not use same version for both?**  
  A: Decouples release cycles, avoids forcing unnecessary major bumps, allows parallel improvement

- **Q: What if C has a breaking change but Swift doesn't?**  
  A: C → v2.0.0 (new row), Swift continues on existing version row until it also requires v2.0.0

- **Q: Can we skip C versions in Swift?**  
  A: Yes; if C 1.2.0 only has minor fixes, Swift 1.1.0 can depend on C 1.0.0+ and skip 1.1.0, 1.2.0

---

**Last Updated**: 2025-12-09  
**Maintained By**: Color Journey Release Team  
**Related**: [RELEASE_PLAYBOOK.md](RELEASE_PLAYBOOK.md), [RELEASE_TAGGING.md](RELEASE_TAGGING.md), [ARTIFACTS_SPECIFICATION.md](ARTIFACTS_SPECIFICATION.md)
