# Unified Documentation Build System

**Last Updated**: 2025-12-08  
**Purpose**: Single command to generate all documentation (C, Swift, and other formats)

This guide explains how to build and manage all documentation for ColorJourney using a unified build system.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Build Targets](#build-targets)
3. [Directory Structure](#directory-structure)
4. [Documentation Types](#documentation-types)
5. [Build Process](#build-process)
6. [Viewing Generated Docs](#viewing-generated-docs)
7. [CI/CD Integration](#cicd-integration)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Generate All Documentation

```bash
# Generate all docs (C, Swift, web-ready)
make docs

# Clean and regenerate
make docs-clean
make docs

# Generate for publishing
make docs-publish
```

### View Generated Documentation

```bash
# View Swift-DocC docs locally
open Docs/generated/swift-docc/

# View Doxygen docs locally
open Docs/generated/doxygen/

# View combined HTML index
open Docs/index.html
```

---

## Build Targets

### Makefile Targets

```makefile
make docs              # Generate all documentation
make docs-swift        # Generate Swift-DocC only
make docs-c            # Generate Doxygen (C) only
make docs-index        # Generate combined index
make docs-clean        # Clean all generated docs
make docs-publish      # Generate for web publishing (GitHub Pages)
make docs-validate     # Validate documentation quality
```

### What Each Target Does

**`make docs`**
- Generates Swift-DocC documentation
- Generates Doxygen C documentation
- Creates unified index page
- Output: `Docs/generated/`

**`make docs-swift`**
- Generates Swift-DocC only
- Output: `Docs/generated/swift-docc/`

**`make docs-c`**
- Generates Doxygen only
- Output: `Docs/generated/doxygen/`

**`make docs-index`**
- Creates unified index page
- Links to all generated documentation
- Output: `Docs/index.html`

**`make docs-clean`**
- Removes all generated documentation
- Preserves source docs in `DevDocs/`

**`make docs-publish`**
- Generates for static web hosting
- Optimizes for GitHub Pages
- Output: `Docs/generated/publish/`

**`make docs-validate`**
- Checks for documentation errors
- Validates symbol references
- Reports warnings

---

## Directory Structure

### Root Level

```
ColorJourney/
├── Docs/                          # Generated and user-facing docs
│   ├── generated/                 # Generated output (Doxygen, DocC)
│   │   ├── swift-docc/            # Swift-DocC output
│   │   ├── doxygen/               # Doxygen (C) output
│   │   └── publish/               # Web-ready (GitHub Pages)
│   ├── api/                       # API reference pages
│   ├── guides/                    # User guides and tutorials
│   ├── index.html                 # Unified documentation index
│   └── README.md                  # Docs overview for users
│
├── DevDocs/                       # Developer documentation
│   ├── standards/                 # Documentation standards
│   │   ├── DOCUMENTATION.md       # Standards and conventions
│   │   └── ARCHITECTURE.md        # System architecture
│   ├── guides/                    # Developer guides
│   │   ├── SWIFT_DOCC_GUIDE.md
│   │   ├── SWIFT_DOCC_PLUGIN_GUIDE.md
│   │   ├── DOCS_QUICKREF.md
│   │   └── UNIFIED_DOCS_BUILD.md
│   ├── *_SUMMARY.md               # Decision summaries
│   ├── *_STATUS.md                # Implementation status
│   └── stress-test/               # Performance analysis
│
├── README.md                      # Project overview
├── CONTRIBUTING.md                # Contributing guide
├── Makefile                       # Build system
└── Package.swift                  # Swift package manifest
```

### Generated Documentation Location

All generated documentation goes into `Docs/generated/`:

```
Docs/generated/
├── swift-docc/
│   ├── index.html
│   ├── documentation/
│   │   └── colorjourney/
│   │       ├── colorjourney.html
│   │       ├── colorjourneyrGB.html
│   │       └── ...
│   ├── css/
│   ├── js/
│   └── data/
│
└── doxygen/
    ├── html/
    │   ├── index.html
    │   ├── classes.html
    │   ├── files.html
    │   └── ...
    └── latex/
```

---

## Documentation Types

### 1. Swift-DocC (/// comments in .swift files)

**Source**: `Sources/ColorJourney/ColorJourney.swift`
**Generated**: `Docs/generated/swift-docc/`
**Format**: Interactive HTML with cross-references
**Features**:
- IDE integration (Xcode Quick Help)
- Symbol search and navigation
- Multi-platform support indication
- Embedded code examples

**Generate**:
```bash
make docs-swift
```

### 2. Doxygen (C API documentation)

**Source**: `Sources/CColorJourney/include/ColorJourney.h`
**Config**: `.specify/doxyfile`
**Generated**: `Docs/generated/doxygen/`
**Format**: HTML + LaTeX + man pages
**Features**:
- Function/struct/enum documentation
- Call graphs and dependency diagrams
- Cross-reference index
- Search capability

**Generate**:
```bash
make docs-c
```

### 3. Developer Guides

**Source**: `DevDocs/guides/`
**Format**: Markdown files
**Content**:
- How to write documentation (`SWIFT_DOCC_GUIDE.md`)
- How to publish docs (`SWIFT_DOCC_PLUGIN_GUIDE.md`)
- Quick reference (`DOCS_QUICKREF.md`)
- Build system guide (this file)

**Not generated** - read directly from `DevDocs/`

### 4. Developer Standards

**Source**: `DevDocs/standards/`
**Format**: Markdown files
**Content**:
- Documentation standards (`DOCUMENTATION.md`)
- Architecture documentation (`ARCHITECTURE.md`)
- Terminology glossary
- Review checklists

**Not generated** - read directly from `DevDocs/`

### 5. Implementation Documents

**Source**: `DevDocs/*.md`
**Format**: Markdown files
**Content**:
- Implementation status
- Design decisions
- Stress test results
- Performance analysis

**Not generated** - read directly from `DevDocs/`

---

## Build Process

### How Documentation Gets Built

```
1. Developer writes code with /// comments (Swift) or @param tags (C)
   ↓
2. Run: make docs
   ↓
3. Swift-DocC processes .swift files → HTML output
   Doxygen processes .h/.c files → HTML output
   ↓
4. Generate unified index → Docs/index.html
   ↓
5. Output ready at: Docs/generated/
```

### Step-by-Step Build

```bash
# Step 1: Generate Swift-DocC
swift package generate-documentation \
  --target ColorJourney \
  --output-path Docs/generated/swift-docc

# Step 2: Generate Doxygen
doxygen .specify/doxyfile

# Step 3: Create unified index
cat > Docs/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ColorJourney Documentation</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>ColorJourney Documentation</h1>
    <ul>
        <li><a href="generated/swift-docc/">Swift API (DocC)</a></li>
        <li><a href="generated/doxygen/html/">C API (Doxygen)</a></li>
    </ul>
</body>
</html>
EOF
```

---

## Viewing Generated Docs

### Swift-DocC Documentation

```bash
# Generate and open
make docs-swift
open Docs/generated/swift-docc/index.html

# Or in Xcode
swift package generate-documentation
open .build/documentation/
```

**Features**:
- Interactive documentation
- Cross-referenced symbols
- Code examples
- Platform availability indicators

### Doxygen Documentation

```bash
# Generate and open
make docs-c
open Docs/generated/doxygen/html/index.html
```

**Features**:
- API reference
- Call graphs
- File structure
- Search index

### Combined Index

```bash
# Generate all
make docs

# Open unified index
open Docs/index.html
```

### Local Web Server

```bash
# Start local server for testing
cd Docs
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

---

## CI/CD Integration

### GitHub Actions Workflow

Automatically generate and publish documentation:

```yaml
# .github/workflows/docs.yml
name: Generate Documentation

on:
  push:
    branches: [main]
    paths:
      - "Sources/**"
      - ".specify/doxyfile"
      - "Makefile"
  pull_request:
    paths:
      - "Sources/**"

jobs:
  docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Swift
        uses: swift-actions/setup-swift@v1
        with:
          swift-version: "5.9"
      
      - name: Install Doxygen
        run: brew install doxygen
      
      - name: Generate documentation
        run: make docs
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: documentation
          path: Docs/generated/
      
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: actions/deploy-pages@v3
        with:
          artifact_name: documentation
```

### Local Pre-Commit Hook

Validate docs before commit:

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Validating documentation..."
make docs-validate

if [ $? -ne 0 ]; then
    echo "Documentation validation failed!"
    exit 1
fi
```

---

## Troubleshooting

### Doxygen Not Found

**Problem**: `doxygen: command not found`

**Solution**:
```bash
# Install Doxygen
brew install doxygen

# Verify installation
doxygen --version
```

### Swift-DocC Generation Fails

**Problem**: `error: Unable to generate documentation`

**Solution**:
```bash
# Clean and rebuild
rm -rf .build
swift package generate-documentation --verbose 2>&1 | grep -i error
```

### Symbol References Broken

**Problem**: Links in documentation don't work

**Solution**:
1. Check symbol name spelling (exact casing)
2. For functions, include parentheses: ``funcName()``
3. Rebuild: `make docs-swift`

### Doxygen Output Missing

**Problem**: `Docs/generated/doxygen/` is empty

**Solution**:
1. Check `.specify/doxyfile` exists
2. Verify header files are readable
3. Check warnings: `doxygen .specify/doxyfile 2>&1 | grep -i warning`

### Combined Index Not Generated

**Problem**: `Docs/index.html` doesn't exist

**Solution**:
```bash
# Regenerate index
make docs-index

# Or full rebuild
make docs-clean
make docs
```

---

## Makefile Reference

### Full Makefile Documentation Target

```makefile
.PHONY: docs docs-swift docs-c docs-index docs-clean docs-publish docs-validate

docs: docs-swift docs-c docs-index
	@echo "✅ All documentation generated"
	@echo "   View: open Docs/index.html"

docs-swift:
	@echo "Generating Swift-DocC..."
	@swift package generate-documentation \
		--target ColorJourney \
		--output-path Docs/generated/swift-docc
	@echo "✅ Swift-DocC generated → Docs/generated/swift-docc/"

docs-c:
	@echo "Generating Doxygen (C)..."
	@doxygen .specify/doxyfile
	@echo "✅ Doxygen generated → Docs/generated/doxygen/"

docs-index:
	@echo "Creating unified documentation index..."
	@mkdir -p Docs
	@cat > Docs/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ColorJourney Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; padding: 2rem; }
        h1 { color: #333; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .section { margin: 2rem 0; }
    </style>
</head>
<body>
    <h1>📚 ColorJourney Documentation</h1>
    <p>Complete documentation for the ColorJourney color generation library.</p>
    
    <div class="section">
        <h2>API Reference</h2>
        <ul>
            <li><a href="generated/swift-docc/">Swift API (DocC)</a></li>
            <li><a href="generated/doxygen/html/">C API (Doxygen)</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Developer Guides</h2>
        <ul>
            <li><a href="../DevDocs/guides/DOCS_QUICKREF.md">Quick Reference</a></li>
            <li><a href="../DevDocs/guides/SWIFT_DOCC_GUIDE.md">How to Write Documentation</a></li>
            <li><a href="../DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md">Publishing Documentation</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Standards</h2>
        <ul>
            <li><a href="../DevDocs/standards/DOCUMENTATION.md">Documentation Standards</a></li>
            <li><a href="../DevDocs/standards/ARCHITECTURE.md">System Architecture</a></li>
        </ul>
    </div>
</body>
</html>
EOF
	@echo "✅ Unified index created → Docs/index.html"

docs-clean:
	@echo "Cleaning generated documentation..."
	@rm -rf Docs/generated
	@rm -f Docs/index.html
	@echo "✅ Documentation cleaned"

docs-publish:
	@echo "Generating documentation for publishing..."
	@mkdir -p Docs/generated/publish
	@swift package --allow-writing-to-directory ./Docs/generated/publish \
		generate-documentation \
		--target ColorJourney \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path ColorJourney \
		--output-path ./Docs/generated/publish/swift-docc
	@echo "✅ Documentation ready for publishing"
	@echo "   Upload: Docs/generated/publish/"

docs-validate:
	@echo "Validating documentation..."
	@swift package generate-documentation --verbose 2>&1 | grep -i error && exit 1 || true
	@echo "✅ Documentation validation passed"
```

---

## Summary

| Task | Command |
|------|---------|
| **Generate all docs** | `make docs` |
| **Generate Swift-DocC only** | `make docs-swift` |
| **Generate Doxygen only** | `make docs-c` |
| **Generate unified index** | `make docs-index` |
| **Clean all docs** | `make docs-clean` |
| **Generate for publishing** | `make docs-publish` |
| **Validate quality** | `make docs-validate` |
| **View locally** | `open Docs/index.html` |

---

## Next Steps

1. **Configure Doxygen**: Update `.specify/doxyfile` if needed
2. **Run build**: `make docs`
3. **View output**: `open Docs/index.html`
4. **Set up CI/CD**: Add GitHub Actions workflow
5. **Publish**: Push `Docs/generated/` to GitHub Pages

