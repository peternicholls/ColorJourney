# Documentation Streamlining Plan

## Purpose
Create a clear documentation split so the root README remains a concise user entry point, Docs/ carries user-focused depth (with visuals and conceptual explanations), and DevDocs/ holds contributor-level technical detail. Keep content DRY across README, Docs, DevDocs, and code comments.

## Audiences and Depth
- **Users (product consumers):** Want to operate the engine, understand perceptual color space at a conceptual level (with visuals), and configure journeys without deep math.
- **Contributors (engine builders):** Need algorithms, math, performance rationale, implementation details, and build/test/release process.

## Scope by Artifact
### README (root)
- Keep: C-first/OKLab value, capabilities summary, quick start, install/platform pointers, concise user configuration summary (lightness, chroma, contrast, temperature, loop mode, variation) with optional “see DevDocs for deep rationale” links.
- Trim/move: deep architecture, performance internals, testing internals, long use-case gallery, algorithm details, build/publish process.
- Link to: Docs/ guides + generated APIs; DevDocs/ for contributor details.

### Docs/ (user-facing, included in releases)
- Content: high-level, visual explanations of perceptual color space (3D axes), how moving in each dimension affects colors; diagrams/visuals; how configurations alter the journey; integration guides (Swift, C), Quick Start, FAQ, Troubleshooting, use-case patterns.
- References: generated APIs (DocC: Docs/generated/swift-docc; Doxygen: Docs/generated/doxygen), guides (Docs/guides/* HTML), index.html as the landing page.
- Tone: conceptual and applied, minimal math; can link to DevDocs for deep dives.

### DevDocs/ (contributor-facing, excluded from releases)
- Content: mathematical foundations, algorithm choices, perceptual modeling vs performance tradeoffs, implementation rationale, build/test/release workflows, standards, parity/testing plans, migration guides, and process docs.
- Entry points: DevDocs/00_START_HERE.md, DevDocs/README.md, with navigation updates when adding new docs.
- Tone: technical and detailed, cites code paths and benchmarks.

## Migration Mapping (current README -> targets)
- **Stay in README (user entry):** Overview/value, capabilities, quick start, install/platform pointers, concise user configuration summary, links to Docs/ and DevDocs/.
- **Move to Docs/:** Use-case gallery, integration details (SwiftUI, C, SPM, CocoaPods, Make basics), FAQ/troubleshooting patterns, user-facing “Why perceptual/OKLab” with visuals and 3D space intuition.
- **Move to DevDocs/:** Architecture/Why C deep dive, performance internals/benchmarks, testing internals, algorithm details (fast cbrt, journey design math, contrast algorithms), build/publish/release processes, contributor standards.

## Content Patterns and Depth Split
- Docs: explain perceptual color space with diagrams (3D axes), show how configs shift journeys, provide visual examples and practical guidance; minimal formulas.
- DevDocs: formal math (OKLab equations, ΔE, cube root choices), algorithm rationale and constraints, performance budgets, thread safety decisions, code references.

## Action Plan
1. **Outline agreement:** Validate this plan with stakeholders; confirm destination for advanced configuration details (user-friendly in Docs; deep rationale in DevDocs).
2. **README trim:** Keep entry-level content; replace deep sections with links to Docs/ and DevDocs/.
3. **Docs updates:** Ensure guides cover quick start, integration, FAQ, troubleshooting, use cases, and perceptual space visuals; link to generated DocC/Doxygen.
4. **DevDocs updates:** Consolidate technical deep dives (math, algorithms, performance, testing, build/release). Update navigation (00_START_HERE.md, README.md) when adding docs.
5. **Link audit:** Ensure README → Docs/ and DevDocs/ paths work; Docs index points to guides and generated APIs; DevDocs map includes any new documents.

## Checklists
- **When adding user-facing content:** Prefer Docs/; link from README; avoid duplicating in DevDocs.
- **When adding contributor content:** Place in DevDocs/; add to navigation; avoid duplicating in Docs/.
- **When adding public APIs:** Update DocC/Doxygen comments, run `make docs`, ensure Docs/generated refreshed; keep README pointers valid.
- **When adding examples:** Add to Examples/, ensure runnable, hook into verification (`make verify-examples`), and link from Docs as needed.

## DRY and Governance
- Follow AGENTS.md: no duplication across Docs/ (user), DevDocs/ (contrib), and code comments; maintain navigation maps (DevDocs/README.md, DevDocs/00_START_HERE.md, Docs/README.md); keep Playground/Examples in sync with public APIs.
- Docs/ included in releases; DevDocs/ excluded. Update maps when paths change.

## Risks / Decisions to Confirm
- Final destination for advanced configuration rationale: keep user-summary in README/Docs; place detailed parameter rationale in DevDocs.
- Visual assets: ensure diagrams/graphics for perceptual space are added to Docs/ guides and referenced from README.

## Success Criteria
- README is concise, user-focused, and links to deeper user and contributor docs.
- Docs/ contains the user-depth material (conceptual, visual, integration, FAQ) plus generated APIs.
- DevDocs/ contains the technical deep dives, processes, and rationale.
- Navigation is consistent; no duplicated content across tiers.
