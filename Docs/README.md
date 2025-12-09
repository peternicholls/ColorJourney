# ColorJourney Documentation

**Welcome to the ColorJourney documentation hub!**

This folder contains all generated and user-facing documentation for the ColorJourney color generation library.

---

## 📚 Documentation Types

### API Reference

- **[Swift API (DocC)](generated/swift-docc/)** — Complete Swift package API documentation
  - Auto-generated from source code
  - IDE integration (Xcode Quick Help)
  - Cross-referenced symbols
  - Runnable code examples

- **[C API (Doxygen)](generated/doxygen/html/)** — C core library documentation
  - Function signatures and parameters
  - Call graphs and dependencies
  - Data structure definitions
  - Algorithm explanations

### User Guides

- **[Quick Reference](../DevDocs/guides/DOCS_QUICKREF.md)** — One-page cheat sheet
  - Common commands
  - Copy-paste templates
  - Fast syntax lookup

- **[Swift API Guide](../DevDocs/guides/SWIFT_DOCC_GUIDE.md)** — How to use the Swift library
  - Type-safe configuration
  - Preset styles
  - SwiftUI integration
  - Best practices

### Developer Documentation

See **[DevDocs/](../DevDocs/)** for documentation standards, guides, and development resources:

- **[Documentation Standards](../DevDocs/standards/DOCUMENTATION.md)** — How to write documentation
- **[Architecture Guide](../DevDocs/standards/ARCHITECTURE.md)** — System design and data flow
- **[Swift-DocC Plugin Guide](../DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md)** — Publishing documentation
- **[Unified Docs Build](../DevDocs/guides/UNIFIED_DOCS_BUILD.md)** — Documentation generation system

---

## 🚀 Quick Start

### View API Documentation

```bash
# Swift API
open generated/swift-docc/

# C API
open generated/doxygen/html/
```

### Generate Fresh Documentation

```bash
# In repository root
make docs

# View unified index
open Docs/index.html
```

### Find Something Specific

1. **For Swift code**: Search [Swift API documentation](generated/swift-docc/)
2. **For C code**: Browse [C API documentation](generated/doxygen/html/)
3. **For quick lookup**: Check [Quick Reference](../DevDocs/guides/DOCS_QUICKREF.md)
4. **For standards**: See [Documentation Standards](../DevDocs/standards/DOCUMENTATION.md)

---

## 📖 Documentation Structure

```
Docs/
├── generated/                 # Auto-generated documentation
│   ├── swift-docc/           # Swift-DocC output (HTML)
│   ├── doxygen/              # Doxygen output (HTML, LaTeX)
│   └── publish/              # Web-ready for GitHub Pages
├── guides/                    # User guides (if any)
├── index.html                # Unified documentation index
└── README.md                 # This file
```

```
DevDocs/
├── standards/                # Documentation standards
│   ├── DOCUMENTATION.md      # Standards and conventions
│   └── ARCHITECTURE.md       # System architecture
├── guides/                   # Developer guides
│   ├── DOCS_QUICKREF.md
│   ├── SWIFT_DOCC_GUIDE.md
│   ├── SWIFT_DOCC_PLUGIN_GUIDE.md
│   └── UNIFIED_DOCS_BUILD.md
├── *.md                      # Implementation docs, status, decisions
└── stress-test/              # Performance analysis
```

---

## 🔄 Documentation Workflow

### For Users

1. Read [Quick Reference](../DevDocs/guides/DOCS_QUICKREF.md) for quick lookup
2. Check [Swift API documentation](generated/swift-docc/) for API details
3. Browse [C API documentation](generated/doxygen/html/) for C core

### For Contributors

1. Follow [Documentation Standards](../DevDocs/standards/DOCUMENTATION.md)
2. Use templates from [Swift-DocC Guide](../DevDocs/guides/SWIFT_DOCC_GUIDE.md)
3. Test with `make docs-validate`
4. Build with `make docs`

### For Documentation Publishers

1. Follow [Unified Docs Build Guide](../DevDocs/guides/UNIFIED_DOCS_BUILD.md)
2. Use `make docs-publish` for GitHub Pages
3. Deploy generated files from `Docs/generated/publish/`

---

## 🛠️ Build System

### Makefile Targets

```bash
make docs              # Generate all documentation
make docs-swift        # Generate Swift-DocC only
make docs-c            # Generate Doxygen only
make docs-index        # Generate unified index
make docs-clean        # Clean all generated docs
make docs-publish      # Generate for web publishing
make docs-validate     # Validate documentation quality
```

See [Unified Docs Build](../DevDocs/guides/UNIFIED_DOCS_BUILD.md) for complete information.

---

## 📊 What's Documented

### Swift API (100% coverage)

- ✅ `ColorJourneyRGB` — Color representation
- ✅ `ColorJourneyConfig` — Journey configuration
- ✅ `ColorJourney` — Main library class
- ✅ 6 configuration enums with all cases
- ✅ SwiftUI extensions
- ✅ 30+ code examples

### C API (100% coverage)

- ✅ 12 public functions
- ✅ 3 color structs
- ✅ 7 configuration enums
- ✅ 56+ Doxygen tags
- ✅ Algorithm explanations
- ✅ Memory and determinism guarantees

---

## ❓ FAQ

**Q: How do I generate documentation?**
A: Run `make docs` from the repository root.

**Q: Where's the API documentation?**
A: See [Swift API](generated/swift-docc/) and [C API](generated/doxygen/html/) folders.

**Q: How do I write good documentation?**
A: Follow [Documentation Standards](../DevDocs/standards/DOCUMENTATION.md) and use templates from [Swift-DocC Guide](../DevDocs/guides/SWIFT_DOCC_GUIDE.md).

**Q: How do I publish docs online?**
A: See [Unified Docs Build Guide](../DevDocs/guides/UNIFIED_DOCS_BUILD.md) or [Swift-DocC Plugin Guide](../DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md).

**Q: Which format should I use?**
A: Swift uses `///` comments (DocC), C uses Doxygen format (`@param`, `@return`).

**Q: Can I view docs locally?**
A: Yes! After `make docs`, open `Docs/index.html` in your browser.

---

## 📚 References

- **[Swift-DocC Blog](https://www.swift.org/blog/swift-docc/)**
- **[Swift-DocC Plugin](https://swiftlang.github.io/swift-docc-plugin/)**
- **[Doxygen Manual](https://www.doxygen.nl/)**
- **[ColorJourney Repository](../)**

---

## 🎯 Next Steps

1. **View API Docs**: Open [Swift API](generated/swift-docc/) or [C API](generated/doxygen/html/)
2. **Quick Lookup**: Check [Quick Reference](../DevDocs/guides/DOCS_QUICKREF.md)
3. **Learn More**: Read [Architecture Guide](../DevDocs/standards/ARCHITECTURE.md)
4. **Contribute**: Follow [Documentation Standards](../DevDocs/standards/DOCUMENTATION.md)

**Generated**: 2025-12-08 | **Format**: Swift-DocC + Doxygen | **Status**: Production Ready ✅

