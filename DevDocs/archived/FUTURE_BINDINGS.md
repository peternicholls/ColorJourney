# Future Multi-Language Bindings Architecture

## Overview

Color Journey is designed from the ground up to support multiple language bindings while maintaining a single source of truth: the C99 core. This document outlines the architecture and process for adding future language bindings (Python, JavaScript/WASM, Rust, etc.) without duplicating logic or breaking existing releases.

## Design Principles

### 1. Single Source of Truth
- **C99 Core** is the canonical implementation
- All bindings call into or compile from the same C core
- Algorithm changes made once, benefit all languages
- No separate implementations for different languages

### 2. Language-Agnostic Release Infrastructure
- Release process supports multiple language artifacts in parallel
- CI/CD matrix extends (not replaces) for new bindings
- Each binding has its own version, independent release cadence
- Shared C core version underpins all bindings

### 3. Modular Build System
- CMake project is extensible for new targets
- Swift Package Manager is self-contained
- New bindings can be added without modifying existing CI
- Clear separation of concerns: C core, language FFI, language API

### 4. Clear Dependency Mapping
- Each binding documents its minimum required C core version
- Version mapping extends (see [VERSION_MAPPING.md](VERSION_MAPPING.md))
- Bindings can advance independently; C core is shared responsibility

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│         Color Journey C Core (v1.0.0+)          │
│  [ColorJourney.c/h - OKLab, journeys, config] │
│  Platform: C99, Portable, Deterministic        │
└────────────────────┬────────────────────────────┘
                     │
       ┌─────────────┼─────────────┬──────────────┬──────────────┐
       │             │             │              │              │
       ▼             ▼             ▼              ▼              ▼
   ┌───────────┐ ┌───────────┐ ┌──────────────┐ ┌──────────┐ ┌──────────┐
   │  Swift    │ │ Python    │ │ JavaScript   │ │  Rust    │ │   C++    │
   │  Wrapper  │ │  ctypes   │ │  WASM Bind   │ │   FFI    │ │  Extern  │
   │  (SPM)    │ │ (PyPI)    │ │   (npm)      │ │ (crates) │ │ (header) │
   └───────────┘ └───────────┘ └──────────────┘ └──────────┘ └──────────┘
      v1.0.0+      v1.0.0+       v1.0.0+        v1.0.0+      v1.0.0+
    (Swift 5.9)  (Python 3.8+) (Node 16+)    (Rust 1.56+)  (C++11+)
```

## Current State: Swift + C

### Swift (`Sources/ColorJourney/`)
- **Type**: Language wrapper + idiomatic API
- **Depends on**: C core via bridging header
- **Distribution**: Swift Package Manager (source-only)
- **Release**: Independent semantic versioning (v1.0.0+)
- **CI**: Core-ci.yml (Swift build + test)

### C (`Sources/CColorJourney/`)
- **Type**: Canonical implementation
- **Depends on**: Standard library only (C99, libm)
- **Distribution**: CMake-built static `.a` archives per platform
- **Release**: Independent semantic versioning (v1.0.0+)
- **CI**: Core-ci.yml (C build + test + reproducibility)

---

## Adding New Bindings: Reference Process

### Phase 1: Planning
1. Create new feature branch `feature/binding-LANGUAGE`
2. Create spec in `specs/NNN-LANGUAGE-binding/spec.md`
   - Define user API, feature completeness, platform support
   - Document FFI layer or build strategy
   - Set success criteria and testing strategy
3. Document in this file (FUTURE_BINDINGS.md) in "Binding Candidates" section

### Phase 2: Build & FFI
1. Create language-specific FFI or wrapper layer:
   - **Python**: `bindings/python/colorjourney/` with ctypes or C extension
   - **JavaScript**: `bindings/javascript/` with WASM build and TypeScript bindings
   - **Rust**: `bindings/rust/colorjourney/` with rust-bindgen or manual FFI
2. Extend CMakeLists.txt or build system to produce required artifacts
3. Add language-specific CI job in `.github/workflows/`

### Phase 3: Testing & Documentation
1. Add language binding tests to CI (separate job, gated before release)
2. Document API in language-native format (docstrings, RustDoc, JSDoc, etc.)
3. Create language-specific examples in `Examples/LANGUAGE-Example.*`
4. Update [VERSION_MAPPING.md](VERSION_MAPPING.md) with new binding version

### Phase 4: Release Integration
1. Update release workflow to include new binding artifact packaging
2. Extend CI matrix in `.github/workflows/release-artifacts.yml`
3. Document release artifact contents (what's included in LANGUAGE archive)
4. Test end-to-end release for Swift + C + new binding simultaneously

### Phase 5: Publishing
1. Publish to language-specific package manager:
   - Python → PyPI
   - JavaScript → npm
   - Rust → crates.io
   - etc.
2. Tag release as `v1.0.0-LANGUAGE:v1.0.0` (optional) or use unified `v1.0.0` tag
3. Update unified release notes with compatibility matrix

---

## Binding Candidates & Timeline

### Planned Near-Term (2025-2026)

#### Python Binding (High Priority)
- **Use Case**: Data science/visualization (matplotlib, plotly, Jupyter)
- **FFI Strategy**: ctypes or Python C extension
- **Distribution**: PyPI as `colorjourney` package
- **Estimated Timeline**: Q1-Q2 2026
- **Tests**: pytest with property-based testing
- **Example**: Matplotlib gradient generation, Seaborn integration

#### JavaScript/WASM Binding (High Priority)
- **Use Case**: Web/Node.js, front-end color tools
- **FFI Strategy**: Emscripten WASM or rust-wasm
- **Distribution**: npm as `@colorjourney/js` scoped package
- **Estimated Timeline**: Q1-Q2 2026
- **Tests**: Jest + browser compatibility testing
- **Example**: React color picker, D3 visualization integration

#### Rust Binding (Medium Priority)
- **Use Case**: Rust-native performance, game engines, systems programming
- **FFI Strategy**: rust-bindgen or hand-written FFI + safe wrapper
- **Distribution**: crates.io as `colorjourney` crate
- **Estimated Timeline**: Q2-Q3 2026
- **Tests**: cargo test, criterion for benchmarks
- **Example**: Bevy game engine integration, Egui UI library integration

### Potential Future (2026+)

#### C++ Binding (Low Priority)
- **Use Case**: Game engines (Unreal, CryEngine), legacy C++ code
- **FFI Strategy**: Header-only C++ wrapper + extern "C"
- **Distribution**: vcpkg, Conan package managers
- **Estimated Timeline**: Post-stabilization phase

#### Go Binding (Exploratory)
- **Use Case**: Backend services, CLI tools
- **FFI Strategy**: cgo FFI or pure Go reimplementation (not recommended)
- **Distribution**: Go module
- **Estimated Timeline**: If community interest arises

---

## Release Workflow with Multiple Bindings

### Unified Release (All Platforms Simultaneously)

```bash
# 1. Cut RC from develop with all changes
git checkout -b release-candidate/1.1.0-rc.1

# 2. CI triggers:
#    - Swift build/test
#    - C build/test  
#    - Python build/test
#    - WASM build/test
#    - Rust build/test
#    - Lint (all languages)

# 3. If all green, promote to main
git merge main --no-ff
git tag v1.1.0

# 4. CI release workflow triggers:
#    - Build Swift SPM artifact
#    - Build C static `.a` archives (macOS/Linux/Windows)
#    - Build Python wheel (.whl for all platforms)
#    - Build WASM bundles (.js + .wasm)
#    - Build Rust crate documentation

# 5. Publishing:
git push origin main --tags
# → Swift: automatic (GitHub release)
# → C: automatic (GitHub release)
# → Python: twine upload to PyPI
# → WASM: npm publish
# → Rust: cargo publish

# 6. Announce: Unified release notes cover all platforms
#    "v1.1.0 released for Swift, C, Python, JavaScript, and Rust"
```

### Staggered Release (Different Binding, Same C Core)

If a new feature is only for Swift, C core stays the same:

```bash
# 1. Swift feature branch, develop branch unchanged for C
git checkout -b feature/swift-new-preset

# 2. CI: Swift tests only
# 3. Merge to develop
# 4. No new release (not in RC criteria)

# But later, when both Swift and C have changes:
# 1. RC includes all platform updates
# 2. All CI jobs run
# 3. Single `v1.2.0` tag covers Swift v1.2.0 + C v1.0.0 (unchanged)
#    AND new binding v1.2.0
```

---

## Version Numbering Strategy

### Option 1: Unified Versioning (Recommended)
All bindings and C core share major.minor.patch, but release independently:

```
v1.0.0 (C)        → Release C core
v1.0.0 (Swift)    → Release Swift (requires C v1.0.0+)
v1.0.0 (Python)   → Release Python (requires C v1.0.0+)
v1.1.0 (C)        → C patch/minor
v1.1.0 (Python)   → Python only
v2.0.0 (Swift)    → Major API change
```

**Pros**: Single tag, unified release notes, clear alignment  
**Cons**: Coordinate across teams; may force unnecessary bumps

### Option 2: Independent Versioning (Current Approach)
Each binding has its own version, C core is the reference:

```
C v1.0.0
Swift v1.0.0  (requires C v1.0.0+)
Python v1.0.0 (requires C v1.0.0+)
→ Later:
C v1.1.0
Swift v1.0.0  (unchanged, still works with C v1.1.0+)
Python v2.0.0 (major API change)
```

**Pros**: Flexibility, independent release cadence, no forced bumps  
**Cons**: Requires version mapping documentation (done in VERSION_MAPPING.md)

**Decision**: Use Option 2 (Independent Versioning) to maximize flexibility.

---

## CI/CD Architecture for Multiple Bindings

### Current: Core-CI.yml

```yaml
jobs:
  swift-build-and-test:
  swift-lint:
  c-build-and-test:
  lint-all:  # Common linting
```

### Future: Extended Matrix

```yaml
jobs:
  # C & Swift (existing)
  swift-build-and-test:
  c-build-and-test:
  
  # New bindings (add as they come online)
  python-build-and-test:
    - Strategy: matrix over Python 3.8, 3.9, 3.10, 3.11, 3.12
    - Run: pytest + type checking (mypy/pyright)
  
  wasm-build-and-test:
    - Strategy: build WASM, run Jest tests in Node.js and browser
    - Run: npm test + Node tests
  
  rust-build-and-test:
    - Strategy: cargo test + clippy lint
    - Run: cargo test + cargo clippy
  
  lint-all:  # Covers all languages
```

### Release Workflow: Extended

```yaml
# .github/workflows/release-artifacts.yml

on:
  push:
    tags:
      - 'v*'

jobs:
  # C artifacts
  build-c-artifacts:
    - macOS static `.a`
    - Linux static `.a`
    - Windows static `.a`
  
  # Swift artifacts
  build-swift-artifacts:
    - SPM source archive
    - Documentation
  
  # Python artifacts (NEW)
  build-python-artifacts:
    - Python wheels for macOS/Linux/Windows
    - Source distribution (.tar.gz)
  
  # WASM artifacts (NEW)
  build-wasm-artifacts:
    - Compiled .wasm + .js bindings
    - ESM and CommonJS variants
  
  # Rust artifacts (NEW)
  build-rust-artifacts:
    - Crate documentation
    - Binary examples (optional)
  
  publish-all:
    - Upload C artifacts to GitHub release
    - Upload Swift artifacts (SPM)
    - Push Python to PyPI
    - Push WASM to npm
    - Publish Rust to crates.io
    - Update version badges
```

---

## Extensibility Guidelines

### For Each New Binding

**1. Organizational Structure**
```
bindings/
├── python/
│   ├── colorjourney/
│   ├── tests/
│   ├── setup.py
│   └── README.md
├── javascript/
│   ├── src/
│   ├── tests/
│   ├── package.json
│   └── README.md
└── rust/
    ├── src/
    ├── tests/
    ├── Cargo.toml
    └── README.md
```

**2. API Design Pattern**
Keep the conceptual API consistent:
```
// All bindings follow this conceptual shape:

// Create configuration
config = ColorJourneyConfig(
  anchors: [...],
  style: "balanced"
)

// Create journey from config
journey = ColorJourney(config)

// Sample colors
color = journey.sample(0.5)
palette = journey.discrete(10)
```

**3. Testing Requirements**
Every binding must have:
- Unit tests covering all public APIs
- Determinism tests (seeded variation produces repeatable results)
- Integration tests with the C core
- Cross-platform compatibility tests (where applicable)

**4. Documentation Requirements**
Every binding must document:
- Installation & setup instructions
- API reference (language-native format)
- Examples matching [Examples/](../../Examples/) (C, Swift)
- Performance characteristics
- Platform support matrix
- Version dependency on C core

---

## Maintenance & Evolution

### Breaking Changes in C Core
When the C core has a breaking change (v2.0.0):

1. C core is released as v2.0.0
2. All bindings remain at current version until they're updated:
   - Python v1.0.0 still works with C v1.0.0 (old CI job pins version)
   - Swift v1.0.0 still works with C v1.0.0
3. When binding is updated to support C v2.0.0:
   - Binding releases as v2.0.0 (major bump for new C dependency)
   - Update [VERSION_MAPPING.md](VERSION_MAPPING.md)
4. Old binding versions (pinned to C v1.0.0) remain available in package managers

### Addition of New Features
No changes to architecture; just release new binding version with new features.

---

## Success Criteria for New Bindings

Before adding a binding to the release process:

- [ ] Binding code is in `bindings/LANGUAGE/`
- [ ] CI job (core-ci.yml) exists and passes
- [ ] All tests pass on target platforms
- [ ] API is documented (docstrings/comments)
- [ ] Examples exist in `Examples/`
- [ ] Version dependency on C core documented in [VERSION_MAPPING.md](VERSION_MAPPING.md)
- [ ] Release process tested end-to-end
- [ ] Package manager setup verified (PyPI, npm, crates.io, etc.)

---

## Questions & References

**Q: Can a binding be written in the host language instead of wrapping C?**  
A: Not recommended. The C core is optimized and deterministic; reimplementing risks bugs, inconsistencies, and maintenance burden. However, for performance-critical languages (Rust), a safe idiomatic wrapper is acceptable.

**Q: What if a binding needs platform-specific code?**  
A: C core is portable (C99); bindings can have platform-specific build steps (WASM needs Emscripten, Python wheels need platform-specific compilation). CI should test all platforms.

**Q: How do we handle API evolution across bindings?**  
A: API changes in C core should be backward-compatible where possible. When breaking, all bindings are updated together or pinned to compatible C versions.

---

**Last Updated**: 2025-12-09  
**Maintained By**: Color Journey Architecture Team  
**Related**: [VERSION_MAPPING.md](VERSION_MAPPING.md), [RELEASE_PLAYBOOK.md](RELEASE_PLAYBOOK.md), specs/002-professional-release-workflow/
