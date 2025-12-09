# Toolchain Pinning & Reproducibility

**Purpose**: Ensure deterministic, reproducible builds across CI/CD and releases  
**Last Updated**: 2025-12-09

---

## Toolchain Versions (Pinned)

### Swift
- **Version**: Swift 5.9 (or 5.10 with compatibility)
- **Rationale**: Matches swift-tools-version in Package.swift
- **GitHub Actions**: `macos-latest` currently provides Swift 5.9/5.10
- **Documentation**: See swift-tools-version in [Package.swift](../../Package.swift)

### CMake
- **Minimum Version**: 3.16
- **Recommended Version**: 3.20+
- **Rationale**: 3.16 is widely available on CI/CD systems
- **Rationale**: Project configuration is compatible with 3.16

### C Compiler
- **Standard**: C99 (ISO/IEC 9899:1999)
- **Compiler Targets**:
  - **macOS**: Apple Clang (Xcode command line tools)
  - **Linux**: GCC 7+ or Clang 6+
  - **Windows**: MSVC 2019+ or MinGW

### Build Tools
- **macOS**: 
  - Xcode Command Line Tools (latest)
  - `make` utility
- **Linux**:
  - GCC/Clang development packages
  - Make/CMake
- **Windows**:
  - MSVC Build Tools or MinGW
  - CMake 3.16+

---

## CI/CD Toolchain Configuration

### GitHub Actions Workflow (.github/workflows/core-ci.yml)

**macOS Jobs**:
```yaml
runs-on: macos-latest
# Provides: Swift 5.9+, Xcode command line tools, CMake
```

**Linux Jobs**:
```yaml
runs-on: ubuntu-latest
# Provides: GCC, CMake, Make
```

**Swift Version Check**:
```bash
swift --version
# Output: swift-driver version X.X.X targeting LLVM X.X.X
```

### Pinned Dependencies

| Tool | Version | Purpose | Lock Mechanism |
|------|---------|---------|-----------------|
| Swift | 5.9 | Language & package manager | swift-tools-version |
| Package.resolved | Fixed | Dependency lock | Committed to repo |
| CMake | 3.16+ | C build system | CMakeLists.txt |
| Xcode | Latest | macOS SDK | macos-latest |

---

## Reproducibility Requirements

### Definition
A build is reproducible if, given the same source code commit, running the build twice produces byte-for-byte identical outputs.

### Why It Matters
- **Release Integrity**: Users can verify artifacts match source code
- **Supply Chain Security**: Detect tampering or modifications
- **Version Traceability**: Ensures released artifacts match tagged code

### Deterministic Build Checks

#### Swift Build
```bash
# Build 1
swift build -c release --show-bin-path
shasum -a 256 $(swift build -c release --show-bin-path)/ColorJourney

# Build 2 (same commit)
swift build -c release --show-bin-path
shasum -a 256 $(swift build -c release --show-bin-path)/ColorJourney

# Hashes MUST match
```

#### C Library Build
```bash
# Build 1
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
shasum -a 256 build/libcolorjourney.a

# Build 2
rm -rf build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
shasum -a 256 build/libcolorjourney.a

# Hashes MUST match
```

#### Artifact Packaging
```bash
# Package 1
./scripts/package-swift.sh 1.0.0
shasum -a 256 ColorJourney-1.0.0.tar.gz

# Package 2
rm ColorJourney-1.0.0.tar.gz
./scripts/package-swift.sh 1.0.0
shasum -a 256 ColorJourney-1.0.0.tar.gz

# Hashes MUST match
```

### Non-Deterministic Risks

| Risk | Cause | Mitigation |
|------|-------|-----------|
| **Timestamps** | Build system embeds current time | Use `SOURCE_DATE_EPOCH` for reproducibility |
| **Compiler flags** | Different optimization levels | Pin compiler flags in CMakeLists.txt |
| **Library order** | Link order differences | Explicit target dependencies |
| **Toolchain versions** | Different compiler versions | Pin swift-tools-version, CMake version |

---

## Release Artifact Reproducibility

### Swift Artifact (package-swift.sh)

**Reproducibility Checks**:
- [x] Source files included (not compiled binaries)
- [x] No timestamps embedded (tar without mtime modification)
- [x] File order deterministic (sorted in archive)
- [x] No platform-specific paths
- [x] Same archive compression (gzip consistent)

**Test Procedure**:
```bash
VERSION="1.0.0"

# Build 1
./scripts/package-swift.sh $VERSION
HASH1=$(shasum -a 256 ColorJourney-${VERSION}.tar.gz | awk '{print $1}')

# Clean
rm ColorJourney-${VERSION}.tar.gz

# Build 2
./scripts/package-swift.sh $VERSION
HASH2=$(shasum -a 256 ColorJourney-${VERSION}.tar.gz | awk '{print $1}')

# Verify
if [ "$HASH1" = "$HASH2" ]; then
    echo "✓ Swift artifact is reproducible"
else
    echo "✗ Hashes don't match: $HASH1 vs $HASH2"
    exit 1
fi
```

### C Artifact (package-c.sh)

**Reproducibility Checks**:
- [x] Static library built with pinned compiler
- [x] Headers included as-is (no processing)
- [x] No timestamps or metadata in archive
- [x] Consistent tar creation

**Test Procedure**:
```bash
VERSION="1.0.0"
PLATFORM="linux"

# Build 1 (clean cmake)
rm -rf Sources/CColorJourney/build
cmake -B Sources/CColorJourney/build -DCMAKE_BUILD_TYPE=Release
cmake --build Sources/CColorJourney/build
./scripts/package-c.sh $VERSION $PLATFORM
HASH1=$(shasum -a 256 libcolorjourney-${VERSION}-${PLATFORM}-x86_64.tar.gz | awk '{print $1}')

# Clean
rm -rf Sources/CColorJourney/build libcolorjourney-${VERSION}-${PLATFORM}-x86_64.tar.gz

# Build 2
cmake -B Sources/CColorJourney/build -DCMAKE_BUILD_TYPE=Release
cmake --build Sources/CColorJourney/build
./scripts/package-c.sh $VERSION $PLATFORM
HASH2=$(shasum -a 256 libcolorjourney-${VERSION}-${PLATFORM}-x86_64.tar.gz | awk '{print $1}')

# Verify
if [ "$HASH1" = "$HASH2" ]; then
    echo "✓ C artifact is reproducible"
else
    echo "✗ Hashes don't match"
    exit 1
fi
```

---

## GitHub Actions CI Configuration

### current-ci.yml Settings

```yaml
jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4.1.7
      
      - name: Swift Version
        run: swift --version
        
      - name: Build
        run: swift build -v
        
      - name: Run tests
        run: swift test -v
```

### Reproducibility Validation in CI

**Add job to core-ci.yml**:
```yaml
  reproducibility-check:
    name: Verify Build Reproducibility
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4.1.7
      
      - name: Run reproducibility verification
        run: |
          # Build once
          cmake -B build1 -DCMAKE_BUILD_TYPE=Release
          cmake --build build1
          HASH1=$(shasum -a 256 build1/libcolorjourney.a | awk '{print $1}')
          
          # Clean and rebuild
          rm -rf build1
          cmake -B build1 -DCMAKE_BUILD_TYPE=Release
          cmake --build build1
          HASH2=$(shasum -a 256 build1/libcolorjourney.a | awk '{print $1}')
          
          # Compare
          if [ "$HASH1" = "$HASH2" ]; then
            echo "✓ Build is reproducible"
            exit 0
          else
            echo "✗ Build not reproducible: $HASH1 != $HASH2"
            exit 1
          fi
```

---

## Validation Checklist

Before releasing:

- [ ] Swift build successful on macOS
- [ ] C build successful on Linux (CMake)
- [ ] All tests pass (Swift + C)
- [ ] Artifact hashes match between builds
- [ ] No platform-specific paths in artifacts
- [ ] No embedded timestamps
- [ ] Source code version matches Git tag
- [ ] CHANGELOG updated with version

---

## Troubleshooting

### Build Hash Mismatch

**Symptom**: Artifact hashes differ between builds on same commit

**Investigation**:
1. Check file timestamps: `tar -tzf artifact.tar.gz | head`
2. Check for embedded version strings: `strings build/libcolorjourney.a | grep -i version`
3. Verify compiler version: `gcc --version`, `swift --version`
4. Check build flags: `cmake --build build -- VERBOSE=1`

**Solutions**:
- Use `SOURCE_DATE_EPOCH` environment variable in build
- Remove build directory between builds: `rm -rf build`
- Use same compiler version (check CI toolchain)
- Check for non-deterministic flag ordering

### CMake Configuration Issues

**Problem**: CMake finds different compiler versions

**Solution**:
```bash
# Explicitly specify compiler
cmake -B build \
  -DCMAKE_C_COMPILER=/usr/bin/gcc-11 \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++-11 \
  -DCMAKE_BUILD_TYPE=Release
```

---

## References

- [Reproducible Builds](https://reproducible-builds.org/)
- [Debian Reproducible Builds](https://wiki.debian.org/ReproducibleBuilds)
- [SOURCE_DATE_EPOCH Specification](https://reproducible-builds.org/specs/source-date-epoch/)

