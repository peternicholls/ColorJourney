# Start Here

This page gives you the fastest path through the developer docs while preserving the reasoning behind the project’s design choices.

## What ColorJourney Is
- Palette engine in C99 (`Sources/CColorJourney/ColorJourney.c`) for portability and determinism.
- Swift surface (`Sources/ColorJourney/`) for ergonomics and platform integration (SwiftUI helpers included).
- Tests live in `Tests/ColorJourneyTests/ColorJourneyTests.swift` (52 XCTest cases) and `Tests/CColorJourneyTests/test_c_core.c` (C harness).

## Pick a Path
- **Using the library right now:** `QUICK_REFERENCE.md` → `PALETTE_ENGINE_QUICKSTART.md` → `OUTPUT_PATTERNS.md` for real scenarios.
- **Understanding the architecture and rationale:** `standards/ARCHITECTURE.md` → `UNIVERSAL_PORTABILITY.md` → `API_ARCHITECTURE_DIAGRAM.md`.
- **Contributing code or docs:** `standards/DOCUMENTATION.md` → `guides/DOCS_QUICKREF.md` → `guides/SWIFT_DOCC_GUIDE.md` → `guides/UNIFIED_DOCS_BUILD.md`.
- **Releases and governance:** `BRANCHING_STRATEGY.md` → `BRANCH_PROTECTION_GUIDE.md` → `RELEASE_PLAYBOOK.md` + `RELEASE_GATES.md` + `RELEASE_TAGGING.md`.
- **Algorithm and parity investigations:** `ALGORITHM_COMPARISON_ANALYSIS.md` → `USAGE_AND_FULFILLMENT_ANALYSIS.md` → `stress-test/00_OVERVIEW.md`.

## Reference Map
- Full document map and maintenance notes live in `README.md` (this folder). Start there when adding or updating docs to avoid drift.
- Rationale-first documents: `PRD.md`, `UNIVERSAL_PORTABILITY.md`, `IMPLEMENTATION_STATUS.md`, `ANALYSIS_INDEX.md`.
- Build and publish commands: `guides/UNIFIED_DOCS_BUILD.md`, `guides/SWIFT_DOCC_PLUGIN_GUIDE.md`, `SWIFT_DOCC_404_SOLUTION.md`.

## Keep This Page Accurate
- When tests, file locations, or major commands change, update this page and `README.md` together.
- Link to the rationale (PRD and analysis docs) whenever behavior changes so future readers can trace decisions.

---

## Quick Commands

### View all documentation
```bash
cd DevDocs/
ls -lh *.md
```

### Open specific documents
```bash
# Vision & architecture
open UNIVERSAL_PORTABILITY.md
open EXECUTIVE_SUMMARY.md

# For developers
open QUICK_REFERENCE.md
open OUTPUT_PATTERNS.md

# Deep analysis
open USAGE_AND_FULFILLMENT_ANALYSIS.md

# Navigation
open ANALYSIS_INDEX.md
open DOCUMENTATION_SUMMARY.md
```

### Search within documentation
```bash
# Find all mentions of "C core"
grep -r "C core" DevDocs/

# Find all mentioned API methods
grep -r "sample\|discrete" DevDocs/

# Count documents
ls DevDocs/*.md | wc -l
```

---

## Keep Moving
- Use `README.md` for the full map and maintenance rules.
- Reach for `ANALYSIS_INDEX.md` when you need rationale or evidence behind a decision.
- Update this file whenever paths or tests change so newcomers land on accurate information.
