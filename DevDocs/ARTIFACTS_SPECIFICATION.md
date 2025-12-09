# Release Artifacts Specification

**Purpose**: Define artifact contents, formats, and validation requirements  
**Implements**: FR-007 (Swift Artifacts) and FR-008 (C Artifacts)  
**Last Updated**: 2025-12-09

---

## Overview

ColorJourney releases **separate artifacts** for Swift and C consumers, each tailored to their specific needs and delivery mechanisms.

| Artifact Type | Format | Use Case | Language |
|---------------|--------|----------|----------|
| **Swift** | Source tarball | SPM direct inclusion | Swift 5.9+ |
| **C (macOS)** | Compiled library + headers | Native Xcode/CMake | C99 |
| **C (Linux)** | Compiled library + headers | GCC/Clang environments | C99 |
| **C (Windows)** | Compiled library + headers | Visual C++ / MinGW | C99 |

---

## Artifact 1: Swift Package (FR-007)

### 1.1 File Format

**Name**: `ColorJourney-VERSION.tar.gz`  
**Example**: `ColorJourney-1.0.0.tar.gz`

**Compression**: gzip (`.tar.gz`)  
**Encoding**: UTF-8 for all text files  
**Archive integrity**: SHA256 checksum included in release notes

### 1.2 Required Contents

**MUST Include**:

```
ColorJourney-1.0.0/
├── Sources/
│   └── ColorJourney/                   [REQUIRED]
│       ├── ColorJourney.swift
│       ├── Configuration/
│       │   └── *.swift
│       ├── Extensions/
│       │   └── *.swift
│       ├── Journey/
│       │   └── *.swift
│       └── Types/
│           └── *.swift
├── Package.swift                       [REQUIRED]
├── README.md                           [REQUIRED]
├── LICENSE                             [REQUIRED - exact copy of repo LICENSE]
├── CHANGELOG.md                        [REQUIRED - for this version]
└── Docs/                               [REQUIRED]
    ├── api/
    │   ├── *.html
    │   └── *.md
    └── guides/
        └── *.html
```

### 1.3 Forbidden Contents

**MUST Exclude**:

```
❌ Sources/CColorJourney/               (C source code)
❌ Tests/CColorJourneyTests/            (C tests)
❌ Dockerfile                           (Container config)
❌ docker-compose.yml                   (Container config)
❌ Makefile, Makefile.serve             (Build scripts)
❌ CMakeLists.txt, CMakeConfig.cmake.in (C build config)
❌ .github/                             (CI/CD workflows)
❌ DevDocs/                             (Internal documentation)
❌ Examples/CExample.c                  (C examples)
❌ .gitignore, .dockerignore            (Git config)
❌ scripts/                             (Build scripts)
❌ Tests/ColorJourneyTests/             (Swift tests - optional to exclude)
```

### 1.4 Swift Package Validation

**Test unpacking and building**:

```bash
# Extract
tar -xzf ColorJourney-1.0.0.tar.gz
cd ColorJourney-1.0.0

# Verify structure
ls -la
# Should show: Sources/, Package.swift, README.md, LICENSE, CHANGELOG.md, Docs/

# Test as SPM dependency
mkdir test-project
cd test-project
swift package init --type executable

# Add to Package.swift
echo 'ColorJourney' > Package.swift.tmp
# Add dependency: .package(path: "../ColorJourney-1.0.0")

# Try to build
swift build
# Should succeed without errors
```

### 1.5 Size Requirements

**Recommended**:
- Uncompressed: < 5 MB
- Compressed (.tar.gz): < 1 MB
- Rationale: Source-only distribution (no compiled binaries)

---

## Artifact 2: C Library Package

### 2.1 File Format

**Name**: `libcolorjourney-VERSION-PLATFORM-ARCH.tar.gz`  
**Example**: `libcolorjourney-1.0.0-macos-universal.tar.gz`

**Platform Matrix**:

| Platform | ARCH | Example Filename |
|----------|------|------------------|
| macOS | universal | `libcolorjourney-1.0.0-macos-universal.tar.gz` |
| macOS | x86_64 | `libcolorjourney-1.0.0-macos-x86_64.tar.gz` |
| macOS | arm64 | `libcolorjourney-1.0.0-macos-arm64.tar.gz` |
| Linux | x86_64 | `libcolorjourney-1.0.0-linux-x86_64.tar.gz` |
| Linux | aarch64 | `libcolorjourney-1.0.0-linux-aarch64.tar.gz` |
| Windows | x86_64 | `libcolorjourney-1.0.0-windows-x86_64.tar.gz` |
| Windows | i686 | `libcolorjourney-1.0.0-windows-i686.tar.gz` |

**Compression**: gzip (`.tar.gz`)

### 2.2 Required Contents

**MUST Include**:

```
libcolorjourney-1.0.0-macos-universal/
├── lib/
│   └── libcolorjourney.a                [REQUIRED - static library]
├── include/
│   ├── ColorJourney.h                   [REQUIRED - C API header]
│   └── colorjourney_version.h           [REQUIRED - version macro]
├── examples/
│   ├── CExample.c                       [REQUIRED]
│   └── Makefile                         [REQUIRED]
├── README.md                            [REQUIRED]
├── LICENSE                              [REQUIRED]
├── CHANGELOG.md                         [REQUIRED - for this version]
└── CMakeLists.txt (optional)            [OPTIONAL - for CMake consumers]
```

### 2.3 Forbidden Contents

**MUST Exclude**:

```
❌ Sources/ColorJourney/                (Swift source)
❌ Package.swift                        (Swift SPM manifest)
❌ Tests/                               (Test code)
❌ .github/                             (CI/CD workflows)
❌ DevDocs/                             (Internal docs)
❌ Dockerfile, Makefile, scripts/       (Build tools)
❌ *.so, *.dylib, *.dll                 (Shared libraries)
  (Distribution is static .a only)
❌ *.debug, *.dSYM                      (Debug symbols)
  (Can be removed to reduce size)
```

### 2.4 C Library Validation

**Test extraction and compilation**:

```bash
# Extract
tar -xzf libcolorjourney-1.0.0-macos-universal.tar.gz
cd libcolorjourney-1.0.0-macos-universal

# Verify structure
ls -la
# Should show: lib/, include/, examples/, README.md, LICENSE, CHANGELOG.md

# Verify static library
file lib/libcolorjourney.a
# Should show: Mach-O universal binary with 2 architectures

# Compile example
cd examples
make

# Run example
./CExample
# Should output color conversions without errors
```

### 2.5 Compiler Support

**Compilation requirements by platform**:

| Platform | Compiler | Standard | Flags |
|----------|----------|----------|-------|
| macOS | Apple Clang | C99 | `-std=c99 -Wall` |
| Linux | GCC 7+ | C99 | `-std=c99 -Wall` |
| Windows | MSVC 2019+ | C99 | `/std:c11` |
| Windows | MinGW | C99 | `-std=c99 -Wall` |

**Example GCC compilation**:
```bash
gcc -I include/ -c examples/CExample.c -o CExample.o -std=c99
gcc CExample.o -L lib/ -lcolorjourney -o CExample
./CExample
```

### 2.6 Size Requirements

**Recommended**:

| Component | Size |
|-----------|------|
| Static library (.a) | 50-200 KB |
| Headers (.h) | 10-50 KB |
| Compressed archive | < 100 KB |
| Total uncompressed | < 500 KB |

**Rationale**: Compiled binary distribution, minimal overhead

---

## Artifact 3: Checksums & Integrity

### 3.1 SHA256 Checksums

**Generate**:
```bash
sha256sum ColorJourney-1.0.0.tar.gz > ColorJourney-1.0.0.tar.gz.sha256
sha256sum libcolorjourney-1.0.0-*.tar.gz > libcolorjourney-1.0.0.sha256

# Or on macOS
shasum -a 256 ColorJourney-1.0.0.tar.gz > ColorJourney-1.0.0.tar.gz.sha256
```

**Format**:
```
abc123def456... ColorJourney-1.0.0.tar.gz
def789ghi123... libcolorjourney-1.0.0-macos-universal.tar.gz
ghi456jkl789... libcolorjourney-1.0.0-linux-x86_64.tar.gz
```

**Included in**: GitHub Release description and as separate `.sha256` files

### 3.2 Verify Downloaded Artifacts

```bash
# After downloading
sha256sum -c ColorJourney-1.0.0.tar.gz.sha256
# Output: ColorJourney-1.0.0.tar.gz: OK

# Or manual verification
sha256sum ColorJourney-1.0.0.tar.gz
# Compare with published hash in GitHub Release
```

### 3.3 Reproducibility

**Goal**: Same source code → same artifact hash

**Test procedure**:
```bash
# Build 1
./scripts/package-swift.sh 1.0.0
HASH1=$(sha256sum ColorJourney-1.0.0.tar.gz | awk '{print $1}')

# Clean
rm ColorJourney-1.0.0.tar.gz

# Build 2
./scripts/package-swift.sh 1.0.0
HASH2=$(sha256sum ColorJourney-1.0.0.tar.gz | awk '{print $1}')

# Verify
if [ "$HASH1" = "$HASH2" ]; then
    echo "✓ Reproducible build"
else
    echo "✗ Build not reproducible"
fi
```

---

## Artifact 4: GitHub Release Format

### 4.1 Release Assets

**GitHub Release** automatically includes:

```
Release: v1.0.0 - ColorJourney 1.0.0
Published: 2025-12-15

Release Notes:
[Automatically populated from CHANGELOG.md]

Assets:
  ✓ ColorJourney-1.0.0.tar.gz               (Swift, ~500 KB)
  ✓ libcolorjourney-1.0.0-macos-universal.tar.gz    (~80 KB)
  ✓ libcolorjourney-1.0.0-linux-x86_64.tar.gz      (~80 KB)
  ✓ libcolorjourney-1.0.0-windows-x86_64.tar.gz    (~90 KB)

Checksums (in release notes):
  Swift:
    abc123def... ColorJourney-1.0.0.tar.gz
  C Libraries:
    def456ghi... libcolorjourney-1.0.0-macos-universal.tar.gz
    ghi789jkl... libcolorjourney-1.0.0-linux-x86_64.tar.gz
    jkl012mno... libcolorjourney-1.0.0-windows-x86_64.tar.gz
```

### 4.2 Release Notes Template

```markdown
# ColorJourney 1.0.0

## New Features
- HSLuv color space support
- 15% faster RGB→Lab conversion

## Bug Fixes
- Fixed HSV grayscale handling
- Fixed Lab boundary validation

## Installation

### Swift
Download `ColorJourney-1.0.0.tar.gz` and add to your project:
```swift
.package(path: "path/to/ColorJourney-1.0.0"),
```

### C
Download the appropriate platform-specific library:
- macOS: `libcolorjourney-1.0.0-macos-universal.tar.gz`
- Linux: `libcolorjourney-1.0.0-linux-x86_64.tar.gz`
- Windows: `libcolorjourney-1.0.0-windows-x86_64.tar.gz`

## Checksums
Verify artifact integrity:
```
abc123... ColorJourney-1.0.0.tar.gz
```

## Changelog
[Full changelog in CHANGELOG.md]
```

---

## Artifact 5: Validation Checklist

### Automated Validation (audit-artifacts.sh)

**Script**: [scripts/audit-artifacts.sh](../../scripts/audit-artifacts.sh)

**Usage**:
```bash
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift
./scripts/audit-artifacts.sh libcolorjourney-1.0.0-macos-universal.tar.gz c
```

**Checks**:

**Swift**:
```
✓ Archive integrity (valid tar.gz)
✓ Required files present (Sources/, Package.swift, README, LICENSE, CHANGELOG, Docs/)
✓ Forbidden files absent (DevDocs/, CColorJourney/, .github/)
✓ No compiled binaries
✓ Version consistency (matches filename)
```

**C**:
```
✓ Archive integrity
✓ Required files (lib/, include/, examples/, README, LICENSE, CHANGELOG)
✓ Forbidden files absent (Swift sources, shared libraries)
✓ Static library present (.a file)
✓ Headers present (.h files)
✓ Platform in filename valid (macos, linux, windows)
✓ Architecture in filename valid (universal, x86_64, arm64, aarch64, i686)
```

### Manual Validation Checklist

Before publishing:

**Swift Artifact**:
- [ ] File size < 1 MB (compressed)
- [ ] Extracts without errors
- [ ] Contains all required directories
- [ ] No C source code included
- [ ] No test code included
- [ ] CHANGELOG present and correct
- [ ] README present and accurate
- [ ] SHA256 checksum generated
- [ ] Can be used as SPM dependency

**C Artifact**:
- [ ] File size < 100 KB (compressed)
- [ ] Extracts without errors
- [ ] Contains lib/, include/, examples/
- [ ] Static library (.a) is valid
- [ ] Headers (.h) compile without errors
- [ ] Example code compiles and runs
- [ ] No Swift source code included
- [ ] SHA256 checksum generated
- [ ] Works with CMake or Make

**GitHub Release**:
- [ ] Release notes from CHANGELOG
- [ ] All 4 artifact files attached (Swift + 3 C platforms)
- [ ] SHA256 checksums in release notes
- [ ] Installation instructions clear
- [ ] Links to documentation present
- [ ] Download counts visible
- [ ] Release marked as "latest"

---

## Distribution Channels

### 1. Swift Package Index

**URL**: https://swiftpackageindex.com/search?query=ColorJourney

**Automatic**: After GitHub Release, index picks up new versions  
**Timeline**: 15-30 minutes after release  
**Verification**: Appears in SPI with compatibility matrix

### 2. CocoaPods (If Configured)

**Installation**: Add to Podfile
```ruby
pod 'ColorJourney', '~> 1.0.0'
```

**Requires**: podspec file (not yet implemented)

### 3. GitHub Releases Page

**URL**: https://github.com/peternicholls/ColorJourney/releases

**Automatic**: Created by CI/CD workflow  
**Download**: Direct from GitHub

### 4. Package Registries

**Future support**:
- [ ] C Package Manager (cpm)
- [ ] Conan (C/C++ package manager)
- [ ] Vcpkg (Microsoft C++ package manager)

---

## Troubleshooting

### Archive Corrupted

**Error**: `tar: Error is not recoverable: exiting now`

**Cause**: Archive creation failed or corrupted during download

**Solution**:
```bash
# Regenerate artifact
rm ColorJourney-1.0.0.tar.gz
./scripts/package-swift.sh 1.0.0

# Verify checksum
sha256sum ColorJourney-1.0.0.tar.gz
```

### Missing Files in Artifact

**Error**: Extract shows incomplete directory structure

**Solution**:
```bash
# Check what's in the archive
tar -tzf ColorJourney-1.0.0.tar.gz | head -20

# Run audit script
./scripts/audit-artifacts.sh ColorJourney-1.0.0.tar.gz swift
# Will show exactly what's missing

# Regenerate
rm ColorJourney-1.0.0.tar.gz
./scripts/package-swift.sh 1.0.0
```

### Checksum Mismatch

**Error**: Downloaded artifact hash doesn't match published hash

**Cause**: Download corrupted, network interrupted, or file modified

**Solution**:
```bash
# Re-download the artifact
# Verify checksum again
sha256sum -c <(echo "abc123def... ColorJourney-1.0.0.tar.gz")
```

### C Library Won't Link

**Error**: `undefined reference to 'colorjourney_rgb_to_lab'`

**Cause**: Compiled against wrong architecture or missing library

**Solution**:
```bash
# Verify library architecture
file lib/libcolorjourney.a
# macOS: should show Mach-O universal binary
# Linux: should show ELF 64-bit LSB

# Check symbol exists
nm lib/libcolorjourney.a | grep colorjourney_rgb_to_lab
# Should show the symbol

# Link with correct flags
gcc -I include/ example.c -L lib/ -lcolorjourney -o example
```

---

## Quick Reference

**Swift Artifact**:
- Format: `ColorJourney-VERSION.tar.gz`
- Size: < 1 MB (compressed)
- Contents: Sources/, Package.swift, README, LICENSE, CHANGELOG, Docs/
- Excluded: C code, tests, CI/CD, internal docs

**C Artifact**:
- Format: `libcolorjourney-VERSION-PLATFORM-ARCH.tar.gz`
- Size: < 100 KB (compressed)
- Contents: lib/, include/, examples/, README, LICENSE, CHANGELOG
- Excluded: Swift code, shared libraries, debug symbols

**Validation**:
- Use `audit-artifacts.sh` for automated checks
- Verify SHA256 checksums
- Test extraction and basic usage
- Check GitHub Release page for all assets

