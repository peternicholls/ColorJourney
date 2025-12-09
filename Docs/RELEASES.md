# ColorJourney Releases

**Find the right release package for your platform and language.**

---

## 🎯 Quick Download

### Swift Package Manager (Recommended for Swift/iOS/macOS)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/peternicholls/ColorJourney.git", from: "1.0.0")
]
```

Or use Xcode: **File** → **Add Package Dependencies** → Enter repository URL

### C Library (For C/C++/Cross-Platform)

Download the latest release from [GitHub Releases](https://github.com/peternicholls/ColorJourney/releases):

1. Choose your platform: **macOS**, **Linux**, or **Windows**
2. Download `ColorJourney-C-{version}-{platform}.tar.gz`
3. Extract and link against `libColorJourney.a`

---

## 📦 Release Types

### Swift Releases (Source-Only)

**Package Name**: `ColorJourney-Swift-{version}.tar.gz`

**Contents**:
- Swift source code (`Sources/ColorJourney/`)
- C core dependency (`Sources/CColorJourney/`)
- Package manifest (`Package.swift`)
- User documentation (`Docs/`, `README.md`)
- License and changelog (`LICENSE`, `CHANGELOG.md`)

**Platforms**: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, visionOS 1+, Linux (Swift 5.9+)

**Installation**: Via Swift Package Manager (see above)

**Documentation**: Included in package (`Docs/generated/swift-docc/`)

### C Library Releases (Static Binary)

**Package Name**: `ColorJourney-C-{version}-{platform}.tar.gz`

**Contents**:
- Static library (`.a` file)
- Public headers (`include/ColorJourney.h`)
- C examples (optional)
- User documentation (`Docs/`)
- License and changelog

**Platforms**: 
- **macOS**: x86_64, arm64 (universal binary)
- **Linux**: x86_64, arm64
- **Windows**: x64 (MinGW-w64 or MSVC)

**Installation**: Link against `libColorJourney.a` + include headers

**Documentation**: Included in package (`Docs/generated/doxygen/`)

---

## 🔢 Version Numbering

ColorJourney follows [Semantic Versioning 2.0.0](https://semver.org/):

**Format**: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)

- **MAJOR**: Breaking API changes
- **MINOR**: New features (backward-compatible)
- **PATCH**: Bug fixes (backward-compatible)

### Version Mapping (Swift ↔ C)

Swift releases depend on a minimum C core version. Check the release notes for compatibility:

| Swift Version | Required C Core Version | Notes |
|--------------|-------------------------|-------|
| 1.0.0        | 1.0.0+                 | Initial release |
| 1.1.0        | 1.0.0+                 | Swift API additions |
| 2.0.0        | 2.0.0+                 | Breaking changes |

**Swift releases depend on a specific C core version. Check the release notes for exact compatibility information.**

---

## 🚀 Release Channels

### Stable Releases (Recommended)

**Branch**: `main`  
**Tags**: `v1.0.0`, `v1.1.0`, etc.  
**Status**: Production-ready, tested, documented

Download from [GitHub Releases](https://github.com/peternicholls/ColorJourney/releases)

### Release Candidates (Preview)

**Branch**: `release-candidate/X.Y.Z-rc.N`  
**Tags**: `v1.0.0-rc.1`, `v1.0.0-rc.2`, etc.  
**Status**: Pre-release testing, may have issues

**Use for**: Early testing, integration validation, feedback

**Warning**: RC releases may change before final release

### Development Builds (Bleeding Edge)

**Branch**: `develop`  
**Tags**: None (use branch commits)  
**Status**: Unstable, may break

**Use for**: Development, experimentation, contribution

**Warning**: Not recommended for production use

---

## 📋 Release Contents

### What's Included

✅ **Swift Releases**:
- Swift source code
- C core dependency (source)
- Swift Package Manager manifest
- User-facing documentation (`Docs/`)
- README, LICENSE, CHANGELOG

✅ **C Releases**:
- Static library (`.a`)
- Public headers
- User-facing documentation (`Docs/`)
- C examples (optional)
- README, LICENSE, CHANGELOG

### What's NOT Included

❌ **Developer-only files** (excluded from all releases):
- Development documentation (`DevDocs/`)
- Build system files (`Makefile`, `CMakeLists.txt`)
- Docker configuration (`Dockerfile`, `docker-compose.yml`)
- CI/CD workflows (`.github/`)
- Cross-language examples (Swift examples in C releases, C examples in Swift releases)
- Test suites

**Rationale**: Release artifacts are minimal and language-specific. Developers should clone the repository for full source access.

---

## 🔐 Release Verification

### Verify Checksums (Recommended)

Each release includes SHA256 checksums:

```bash
# Download release and checksum file
curl -LO https://github.com/peternicholls/ColorJourney/releases/download/v1.0.0/ColorJourney-Swift-1.0.0.tar.gz
curl -LO https://github.com/peternicholls/ColorJourney/releases/download/v1.0.0/checksums.txt

# Verify
sha256sum -c checksums.txt
```

### Verify Git Tag (For Source)

```bash
# Clone and verify tag signature (if GPG-signed)
git clone https://github.com/peternicholls/ColorJourney.git
cd ColorJourney
git tag -v v1.0.0
```

---

## 📖 Release Notes

Each release includes detailed release notes covering:

- **New Features**: What's been added
- **Bug Fixes**: What's been corrected
- **Breaking Changes**: What's incompatible with previous versions
- **Deprecations**: What's scheduled for removal
- **Performance**: Improvements and optimizations
- **Documentation**: Updates and additions

See [CHANGELOG.md](../CHANGELOG.md) or [GitHub Releases](https://github.com/peternicholls/ColorJourney/releases)

---

## 🛠️ Building from Source

### Swift Package

```bash
git clone https://github.com/peternicholls/ColorJourney.git
cd ColorJourney
git checkout v1.0.0
swift build -c release
```

### C Library

```bash
git clone https://github.com/peternicholls/ColorJourney.git
cd ColorJourney
git checkout v1.0.0
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

See [README.md](../README.md) for complete build instructions.

---

## ❓ FAQ

**Q: Which release should I use?**  
A: Use the latest stable release from `main` branch (tagged `vX.Y.Z`)

**Q: What's the difference between Swift and C releases?**  
A: Swift is source-only (SPM), C is pre-built static library. Choose based on your language.

**Q: Are releases reproducible?**  
A: Yes! Same source + toolchain = identical binaries. See [DevDocs/TOOLCHAIN_REPRODUCIBILITY.md](../DevDocs/TOOLCHAIN_REPRODUCIBILITY.md)

**Q: How often are releases published?**  
A: On-demand, following the release workflow. No fixed schedule.

**Q: Can I use a release candidate in production?**  
A: Not recommended. RCs are for testing only. Wait for stable release.

**Q: Where's the source code?**  
A: Clone the repository: `git clone https://github.com/peternicholls/ColorJourney.git`

**Q: How do I report a release issue?**  
A: Open an issue on [GitHub Issues](https://github.com/peternicholls/ColorJourney/issues)

---

## 🔗 References

- **[GitHub Releases](https://github.com/peternicholls/ColorJourney/releases)** — Download releases
- **[CHANGELOG.md](../CHANGELOG.md)** — Version history
- **[VERSION_MAPPING.md](../DevDocs/VERSION_MAPPING.md)** — Swift ↔ C version compatibility
- **[RELEASE_PLAYBOOK.md](../DevDocs/RELEASE_PLAYBOOK.md)** — Release process (for maintainers)
- **[Semantic Versioning](https://semver.org/)** — Versioning standard

---

## 🎯 Next Steps

1. **Download**: Get the latest release from [GitHub Releases](https://github.com/peternicholls/ColorJourney/releases)
2. **Install**: Follow platform-specific instructions above
3. **Integrate**: See [README.md](../README.md) for usage examples
4. **Explore**: Check [API Documentation](generated/) for complete reference

---

**Last Updated**: 2025-12-09 | **Status**: Production Ready ✅
