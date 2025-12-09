# ColourJourney Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-09

## Active Technologies
- Swift 5.9 (swift-tools-version), C99 core; Git tooling + SwiftPM, CMake 3.16+, Git/GitHub Actions (002-professional-release-workflow)
- Ruby 2.6+ (CocoaPods), Swift 5.9 (existing wrapper), C99 (existing core) + CocoaPods 1.10.0+, Swift Package Manager (existing), Gi (003-cocoapods-release)
- N/A (package metadata and distribution only) (003-cocoapods-release)

- C99 (core) + Swift 5.9 (wrapper) + None for C core; Foundation, SwiftUI for Swift wrapper (001-comprehensive-documentation)

## Project Structure

```text
src/
tests/
```

## Commands
- **Swift (SPM)**: `swift build` (debug build), `swift test` (Swift unit tests), `swift build -c release` (release build)
- **C core (Makefile)**: `make lib` (build static `.build/gcc/libcolorjourney.a`), `make test-c` (C core tests), `make verify-examples` (sanity-check C and Swift examples)
- **Docs**: `make docs` (Swift-DocC + Doxygen + unified index), `make docs-clean` (remove generated docs)

## Code Style

C99 (core) + Swift 5.9 (wrapper): Follow standard conventions

## Recent Changes
- 003-cocoapods-release: Added Ruby 2.6+ (CocoaPods), Swift 5.9 (existing wrapper), C99 (existing core) + CocoaPods 1.10.0+, Swift Package Manager (existing), Gi
- 002-professional-release-workflow: Added Swift 5.9 (swift-tools-version), C99 core; Git tooling + SwiftPM, CMake 3.16+, Git/GitHub Actions

- 001-comprehensive-documentation: Added C99 (core) + Swift 5.9 (wrapper) + None for C core; Foundation, SwiftUI for Swift wrapper

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
