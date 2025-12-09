# Swift-DocC Plugin Guide for ColorJourney

**Last Updated**: 2025-12-08  
**Reference**: [Swift-DocC Plugin Documentation](https://swiftlang.github.io/swift-docc-plugin/)  
**Scope**: Publishing Swift package documentation online with multi-platform support

This guide explains how to use the **Swift-DocC Plugin** to generate and publish documentation for the ColorJourney Swift package across multiple platforms (iOS, macOS, watchOS, tvOS, visionOS, Linux).

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Local Development](#local-development)
4. [Generating for Web Hosting](#generating-for-web-hosting)
5. [Multi-Platform Package Documentation](#multi-platform-package-documentation)
6. [GitHub Pages Publishing](#github-pages-publishing)
7. [Static Server Hosting](#static-server-hosting)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Quick Start

### Generate Documentation Locally

```bash
# Generate for local viewing (with IDE indexing)
swift package generate-documentation

# View in Xcode
open .build/documentation
```

### Generate for Web Publishing

```bash
# Generate for static web hosting (e.g., GitHub Pages)
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney \
  --output-path ./docs
```

### Deploy to GitHub Pages

```bash
# Commit and push the ./docs directory
git add docs/
git commit -m "docs: generate Swift-DocC documentation"
git push origin main

# In GitHub: Settings → Pages → Source: Deploy from branch (main, /docs folder)
```

---

## Installation

### Add Swift-DocC Plugin to Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ColorJourney",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "ColorJourney", targets: ["ColorJourney"])
    ],
    dependencies: [
        // Add Swift-DocC plugin as dependency
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CColorJourney",
            path: "Sources/CColorJourney",
            sources: ["ColorJourney.c"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "ColorJourney",
            dependencies: ["CColorJourney"],
            path: "Sources/ColorJourney"
        ),
        .testTarget(
            name: "ColorJourneyTests",
            dependencies: ["ColorJourney"]
        )
    ]
)
```

### Verify Installation

```bash
swift package generate-documentation --help
```

If successful, you'll see the Swift-DocC plugin options.

---

## Local Development

### Generate Local Documentation

```bash
# Generate documentation for the Swift package target
swift package generate-documentation

# Output: .build/documentation/
```

**What's included:**
- IDE indexing for Xcode symbol navigation
- Searchable symbol index
- Cross-reference resolution
- All public APIs with documentation

### View in Xcode

```bash
# Open documentation viewer
open .build/documentation

# Or in Xcode directly
# Product → Build Documentation (Cmd+Shift+D)
```

### View in Web Browser

```bash
# Local HTTP server (if available)
python3 -m http.server 8000 --directory .build/documentation

# Open http://localhost:8000
```

### Generate for Specific Target

```bash
# Document only the ColorJourney target
swift package generate-documentation --target ColorJourney

# Document all targets
swift package generate-documentation
```

---

## Generating for Web Hosting

### Overview

The Swift-DocC plugin provides three modes for web publishing:

| Mode | Use Case | Command Complexity | Server Setup |
|------|----------|-------------------|--------------|
| **Archived** | IDE indexing + web | Low | Standard routing |
| **Static Hosting** | GitHub Pages, simple servers | Medium | None (static only) |
| **Transform + Base Path** | Subdirectory hosting | Medium | None (static only) |

### Mode 1: Archive Format (Default)

Generates documentation archive with IDE indexing. Requires proper server routing.

```bash
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --output-path ./docs
```

**Requires server configuration:**
```
/docs/               → /docs/index.html
/docs/documentation → /docs/documentation/colorjourney/...
```

**Best for:** Self-hosted servers with routing control.

### Mode 2: Transform for Static Hosting

Optimized for GitHub Pages, AWS S3, Vercel, Netlify, etc.

```bash
# Generate for root domain (e.g., docs.example.com)
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --output-path ./docs
```

**Advantages:**
- No server routing rules needed
- Works on any static host
- Smaller file size (no IDE index)
- Fast CDN-friendly

**Output structure:**
```
docs/
├── index.html
├── css/
├── js/
├── data/
└── documentation/
```

### Mode 3: Subdirectory Hosting

Host docs at subdirectory (e.g., `example.com/ColorJourney/`):

```bash
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney \
  --output-path ./docs
```

**Key flag:** `--hosting-base-path ColorJourney`

This tells Swift-DocC to generate all relative paths assuming docs are at `/ColorJourney/`.

**Use cases:**
- GitHub Pages from organization site: `org.github.io/ColorJourney/`
- Project subpath: `example.com/projects/ColorJourney/`
- Monorepo documentation: `docs.example.com/packages/ColorJourney/`

---

## Multi-Platform Package Documentation

### Platform Availability in Docs

ColorJourney supports multiple platforms. Each platform is listed in `Package.swift`:

```swift
platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .macCatalyst(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
]
```

When generating documentation, **Swift-DocC automatically marks which platforms each symbol is available on**.

In the generated docs, every function/type shows:
- ✅ **iOS 13+**
- ✅ **macOS 10.15+**
- ✅ **watchOS 6+**
- ✅ **tvOS 13+**
- ✅ **visionOS 1+**
- ✅ **macCatalyst 13+**

### Documenting Platform-Specific Behaviors

If a symbol has platform-specific behavior, document it:

```swift
/// Creates a color journey suitable for all Apple platforms.
///
/// ## Platform Notes
///
/// - **iOS/iPadOS**: Full SwiftUI integration available
/// - **macOS**: Use `.nsColor` property for AppKit colors
/// - **watchOS**: Optimized for small watch screen displays
/// - **tvOS**: Works with TVML color integration
/// - **visionOS**: Compatible with visionOS SwiftUI enhancements
/// - **Linux**: C core available via system installation
///
/// - SeeAlso: ``ColorJourneyRGB.nsColor``, ``ColorJourneyRGB.uiColor``
public final class ColorJourney
```

### C Core Availability

The C core (`CColorJourney`) is available on all platforms through the Swift wrapper. If documenting C interop:

```swift
/// ## C Interoperability
///
/// The underlying C core is available for direct C FFI usage:
///
/// ```c
/// #include "ColorJourney.h"
/// CJ_Config config = cj_config_init();
/// // Direct C usage
/// ```
///
/// For Swift, use the ``ColorJourney`` class instead (fully bridged).
public func c_interop_example()
```

---

## GitHub Pages Publishing

### Setup (One-Time)

1. **Create `.github/workflows/publish-docs.yml`:**

```yaml
name: Publish Documentation

on:
  push:
    branches:
      - main
    paths:
      - "Sources/**"
      - "Package.swift"
      - ".github/workflows/publish-docs.yml"
  release:
    types: [published]
  workflow_dispatch:

jobs:
  publish-docs:
    runs-on: macos-latest
    
    permissions:
      pages: write
      id-token: write
    
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup Swift
        uses: swift-actions/setup-swift@v1
        with:
          swift-version: "5.9"
      
      - name: Build documentation
        run: |
          swift package --allow-writing-to-directory ./docs \
            generate-documentation \
            --target ColorJourney \
            --disable-indexing \
            --transform-for-static-hosting \
            --hosting-base-path ColorJourney \
            --output-path ./docs
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

2. **Enable GitHub Pages:**
   - Repository Settings → Pages → Source: GitHub Actions

3. **Commit and push:**

```bash
git add .github/workflows/publish-docs.yml
git commit -m "ci: add documentation publishing workflow"
git push origin main
```

### Automatic Publishing

Documentation automatically publishes on:
- ✅ Push to main branch (docs/ folder changes)
- ✅ Release published
- ✅ Manual trigger (workflow_dispatch)

**Result:** `https://peternicholls.github.io/ColorJourney/`

### Custom Domain

If hosting on custom domain:

1. GitHub Settings → Pages → Custom domain: `colors.example.com`
2. Add DNS CNAME record: `colors.example.com → peternicholls.github.io`
3. Update workflow `--hosting-base-path` (remove if at root):

```bash
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --output-path ./docs
```

---

## Static Server Hosting

### AWS S3 + CloudFront

```bash
# Generate documentation
swift package --allow-writing-to-directory ./docs \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney \
  --output-path ./docs

# Upload to S3
aws s3 sync ./docs s3://my-bucket/ColorJourney/
```

**CloudFront configuration:**
- Origin: S3 bucket
- Default root object: `index.html`
- Error pages → 404 → `/index.html` (for SPA routing)

### Vercel / Netlify

```bash
# Automatic deployment via git
# Just push docs/ folder to repository
git add docs/
git commit -m "docs: update documentation"
git push
```

**Netlify config (`netlify.toml`):**

```toml
[build]
  command = "swift package --allow-writing-to-directory ./docs generate-documentation --target ColorJourney --disable-indexing --transform-for-static-hosting --hosting-base-path ColorJourney --output-path ./docs"
  publish = "docs"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Self-Hosted Server

```bash
# Generate with base path
swift package --allow-writing-to-directory ./public \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path /ColorJourney \
  --output-path ./public

# Copy to web server
sudo cp -r ./public/* /var/www/html/ColorJourney/
```

**No routing configuration needed** (static hosting handles it).

---

## Troubleshooting

### Symbol References Not Linking

**Problem:** `` ``SymbolName`` `` appears as plain text instead of link

**Solution:**
1. Verify exact symbol name spelling
2. For functions, include parentheses: `` ``funcName()`` ``
3. For functions with parameters: `` ``funcName(param:otherParam:)`` ``
4. Rebuild: `swift package generate-documentation --clean`

### Broken Links in Generated Docs

**Problem:** Links to external URLs return 404

**Solution:**
1. Verify URLs in markdown are valid
2. For external links, use: `[Text](https://example.com)`
3. For symbol links, use: `` ``SymbolName`` ``
4. Check for typos in paths

### Documentation Generation Errors

**Problem:** `error: Unable to generate documentation`

**Solution:**
```bash
# Enable verbose output
swift package generate-documentation --verbose 2>&1 | grep -i error

# Common issues:
# - Syntax errors in /// comments
# - Unmatched backticks
# - Invalid markdown in examples
# - Broken symbol references
```

### Hosting Base Path Issues

**Problem:** Docs work locally but not on GitHub Pages

**Solution:**
1. Verify `--hosting-base-path` matches actual URL path
2. For `org.github.io/ColorJourney/`, use: `--hosting-base-path ColorJourney`
3. For root domain, omit `--hosting-base-path`
4. Test locally:
   ```bash
   python3 -m http.server --directory ./docs 8000
   ```

### Static Hosting Not Loading Properly

**Problem:** Index loads but other pages show 404

**Solution:**
1. Use `--transform-for-static-hosting` flag
2. Verify `.htaccess` for Apache:
   ```
   <IfModule mod_rewrite.c>
     RewriteEngine On
     RewriteBase /ColorJourney/
     RewriteRule ^index\.html$ - [L]
     RewriteCond %{REQUEST_FILENAME} !-f
     RewriteCond %{REQUEST_FILENAME} !-d
     RewriteRule . /ColorJourney/index.html [L]
   </IfModule>
   ```
3. Or use `nginx` config:
   ```
   location /ColorJourney/ {
     try_files $uri /ColorJourney/index.html;
   }
   ```

---

## Best Practices

### 1. Documentation Catalog

Create `Sources/ColorJourney/ColorJourney.docc/ColorJourney.md` for organization:

```markdown
# ``ColorJourney``

Perceptually uniform color palette generation for Swift.

## Overview

Generate beautiful, programmatic color palettes using OKLab perceptual color math.

## Topics

### Getting Started

- <doc:Getting-Started>

### Essentials

- ``ColorJourney``
- ``ColorJourneyConfig``
- ``ColorJourneyRGB``

### Configuration

- ``LightnessBias``
- ``ChromaBias``
- ``ContrastLevel``
- ``TemperatureBias``
- ``LoopMode``
- ``JourneyStyle``
```

### 2. Article Pages

Create `.docc/Getting-Started.md` for conceptual articles:

```markdown
# Getting Started with Color Journey

Learn how to create and use color journeys.

## Create a Journey

Start with a single anchor color:

```swift
let baseColor = ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8)
let journey = ColorJourney(
    config: .singleAnchor(baseColor, style: .balanced)
)
```

## Generate Colors

Sample colors from the journey:

```swift
let color = journey.sample(at: 0.5)
let palette = journey.discrete(count: 8)
```
```

### 3. Versioned Documentation

Generate separate docs for each version:

```bash
# Generate for v1.0.0
git checkout v1.0.0
swift package --allow-writing-to-directory ./docs/v1.0.0 \
  generate-documentation \
  --target ColorJourney \
  --disable-indexing \
  --transform-for-static-hosting \
  --hosting-base-path ColorJourney/v1.0.0 \
  --output-path ./docs/v1.0.0

git checkout main
```

### 4. CI/CD Integration

Always regenerate docs on:
- ✅ Main branch changes
- ✅ Release tags
- ✅ Pull requests (preview)

### 5. Link to Docs from README

```markdown
## Documentation

- **[API Documentation](https://peternicholls.github.io/ColorJourney/)** — Full API reference
- **[Getting Started](https://peternicholls.github.io/ColorJourney/documentation/colorjourney/getting-started)** — Quick tutorial
```

### 6. Keep Docs in Sync

When updating API:
1. Update code comments first
2. Update DOCUMENTATION.md glossary
3. Regenerate docs
4. Commit updated docs alongside code changes

### 7. Monitor Doc Quality

```bash
# Check for undocumented public symbols
swift package generate-documentation --verbose 2>&1 | grep -i "no declaration found"

# Verify no warnings
swift package generate-documentation 2>&1 | grep -i warning
```

---

## Summary Table

| Task | Command |
|------|---------|
| **Generate locally** | `swift package generate-documentation` |
| **Generate for GitHub Pages** | `swift package --allow-writing-to-directory ./docs generate-documentation --target ColorJourney --disable-indexing --transform-for-static-hosting --hosting-base-path ColorJourney --output-path ./docs` |
| **Generate for root domain** | (same, omit `--hosting-base-path`) |
| **View in browser** | `open .build/documentation` or `python3 -m http.server --directory ./docs 8000` |
| **Deploy to GitHub Pages** | `git add docs/ && git commit && git push` (with workflow) |
| **Clean build** | `rm -rf .build && swift package generate-documentation` |

---

## References

- **[Swift-DocC Plugin Official Docs](https://swiftlang.github.io/swift-docc-plugin/)**
- **[Generating Documentation for Hosting Online](https://swiftlang.github.io/swift-docc-plugin/documentation/swiftdoccplugin/generating-documentation-for-hosting-online/)**
- **[Publishing to GitHub Pages](https://swiftlang.github.io/swift-docc-plugin/documentation/swiftdoccplugin/publishing-to-github-pages)**
- **[Swift-DocC Blog Post](https://www.swift.org/blog/swift-docc/)**
- **[ColorJourney DOCUMENTATION.md](./DOCUMENTATION.md)** — Full standards
- **[ColorJourney SWIFT_DOCC_GUIDE.md](./SWIFT_DOCC_GUIDE.md)** — DocC format guide

