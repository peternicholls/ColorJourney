# Research: Comprehensive Code Documentation

**Date**: 2025-12-07  
**Feature**: 001-comprehensive-documentation  
**Status**: Completed Phase 0

This document resolves technical unknowns and establishes best practices for documentation standards across the ColorJourney codebase.

---

## 1. Doxygen Standards for C Core Documentation

**Decision**: Use Doxygen-compatible JavaDoc-style comments for C core API and algorithms.

**Rationale**:
- Doxygen is the industry standard for C/C++ documentation generation
- Comments use `/** ... */` blocks for functions and `///< ` for inline struct fields
- Supports cross-referencing, parameter documentation, return value documentation, and preconditions
- Compatible with modern documentation generators and IDE integration
- Widely adopted in open-source C libraries (e.g., libcurl, sqlite3)

**Format**:
```c
/**
 * @brief One-line summary of what the function does
 * 
 * Longer description explaining the purpose, algorithm, and any important caveats.
 * Can reference external documents or cite academic papers.
 * 
 * @param param1 Description of param1, valid range, and usage
 * @param param2 Description of param2
 * @return Description of return value and what it means
 * @pre Precondition (e.g., "journey must have been initialized")
 * @post Postcondition (e.g., "color is in sRGB space")
 * @note Important caveats or performance notes
 * @see Related functions or documents
 */
```

**Alternatives Considered**:
- Plain `/* */` comments: Too ambiguous, no standardization
- GTK-Doc style: Less common than Doxygen; similar complexity
- Inline comments only: No tool support, harder to extract for documentation sites

**Application**: All public functions in `ColorJourney.h`, all public structs, and all non-trivial algorithms in `ColorJourney.c`.

---

## 2. DocC Standards for Swift API Documentation

**Decision**: Use DocC-style comments (`///`) for Swift public APIs, enums, and functions.

**Rationale**:
- DocC is the official Apple documentation standard for Swift
- Comments appear in Xcode Quick Help, autocomplete, and generated documentation
- Supports markdown formatting, parameter descriptions, and code examples
- Integrates seamlessly with Swift Package Manager and Xcode build system
- Modern, discoverable in IDE, and verified by documentation compiler (`docc`)

**Format**:
```swift
/// One-line summary of what this type/function does.
///
/// A longer description explaining purpose, usage, and important behavior.
/// Can include examples and references to other APIs.
///
/// - Parameters:
///   - param1: Description of param1 and expected behavior
///   - param2: Description of param2
/// - Returns: Description of return value
/// - Throws: Error types and when they're thrown
/// - Example:
///   ```swift
///   let journey = ColorJourney(config: ...)
///   let color = journey.sample(at: 0.5)
///   ```
public func something(param1: Type, param2: Type) -> ReturnType {
```

**Alternatives Considered**:
- Plain `//` comments: Not recognized by Xcode Quick Help or documentation tools
- MARK comments: Useful for organization but not documentation
- External wiki: Documentation diverges from code; hard to keep in sync

**Application**: All public types, functions, enums, and properties in `Sources/ColorJourney/ColorJourney.swift`.

---

## 3. Architecture Documentation Location

**Decision**: Top-level architecture explanation lives in code comments (in both `ColorJourney.c` and `ColorJourney.swift` headers) and as a separate `ARCHITECTURE.md` reference.

**Rationale**:
- Comments in source files ensure documentation stays in sync with code changes
- Developers see architecture context when reading the code
- Single source of truth (the code itself)
- Can reference external documents (Constitution, PRD, papers) without duplication

**Content Includes**:
- Two-layer design rationale (C core + Swift wrapper)
- Key design constraints (determinism, perceptual integrity, portability)
- Data flow through the system (config → journey → sampling)
- Performance characteristics and guarantees
- References to the ColorJourney Constitution (principles and governance)

**Alternatives Considered**:
- Wiki or external documentation: Risk of drift; requires dual maintenance
- Separate doc files only: Developers may not find them when reading code
- No architecture docs: Maintainers struggle to understand rationale

**Application**: 
- `Sources/CColorJourney/ColorJourney.c` – Multi-paragraph header comment explaining design
- `Sources/ColorJourney/ColorJourney.swift` – Type and module documentation
- Root-level `ARCHITECTURE.md` – High-level overview with references

---

## 4. Test Documentation Standards

**Decision**: Test code MUST include comments explaining test intent, expected behavior, and why the test matters—not just assertions.

**Rationale**:
- Tests serve as executable specifications
- Comments should explain "what are we testing and why?" not "what does this line do?"
- Helps new developers understand the system through test examples
- Guides maintainers when modifying algorithms or APIs
- Test code is often read by non-authors; clarity is critical

**Format**:
```c
// Test Case: Continuous sampling produces colors in valid sRGB range
// Why this matters: Colors must be displayable; out-of-range values indicate algorithm bugs
void test_sample_produces_valid_rgb(void) {
    // Setup: Create a simple single-anchor journey
    CJ_Config config = {.anchors = {srgb(1.0f, 0.5f, 0.2f)}, .anchor_count = 1};
    CJ_Journey* j = cj_journey_create(&config);
    
    // Test: Sample across the full range [0, 1]
    for (float t = 0.0f; t <= 1.0f; t += 0.1f) {
        CJ_RGB color = cj_sample(j, t);
        assert(color.r >= 0.0f && color.r <= 1.0f);  // Red channel valid
        assert(color.g >= 0.0f && color.g <= 1.0f);  // Green channel valid
        assert(color.b >= 0.0f && color.b <= 1.0f);  // Blue channel valid
    }
    
    // Cleanup
    cj_journey_destroy(j);
}
```

**Alternatives Considered**:
- Minimal comments: Hard for new developers to understand test coverage
- Comments only for complex tests: Inconsistent; hard to know which tests are important
- Test names as documentation: Names can't explain all context and nuance

**Application**: All test files in `Tests/CColorJourneyTests/` and `Tests/ColorJourneyTests/`.

---

## 5. Example Code Verification & Annotation

**Decision**: All example code in `Examples/` must be:
1. **Syntax-checked** – Compiles without warnings
2. **Runnable** – Produces expected output without modification
3. **Annotated** – Comments explain key steps and decisions
4. **Self-contained** – No external setup or dependencies (beyond the library itself)

**Rationale**:
- Examples are often the first thing developers try
- Outdated or broken examples waste time and create frustration
- Annotations teach best practices and common patterns
- Verified examples give confidence in library correctness

**Content Coverage**:
- Single-anchor journey with basic configuration
- Multi-anchor journey with custom anchor count
- Perceptual biases (lightness, chroma, contrast, temperature, vibrancy)
- Discrete vs. continuous sampling
- Loop modes (open, closed, ping-pong)
- Variation layer (enabled/disabled, seeded)

**Verification Process**:
1. Compile with `gcc -std=c99 -o example Examples/CExample.c Sources/CColorJourney/ColorJourney.c -lm`
2. Run and verify output format and colors are in valid ranges
3. CI/CD should verify examples as part of build process

**Alternatives Considered**:
- Examples in documentation only: Hard to keep in sync with code
- Auto-generated examples from tests: Less readable; doesn't show typical workflows
- No examples: Developers must read implementation to understand usage

**Application**: 
- `Examples/CExample.c` – C core example with annotations
- `Examples/SwiftExample.swift` – Swift wrapper example with annotations

---

## 6. Documentation Maintenance Standards

**Decision**: Create `DOCUMENTATION.md` as the source of truth for documentation conventions, tools, and maintenance procedures.

**Rationale**:
- Establishes consistent standards across the codebase
- Guides new contributors on how to document code
- Documents tools used for generation (Doxygen, DocC, CI/CD integration)
- References this spec for context and rationale
- Enables future updates to standards without breaking changes

**Content Includes**:
- Style guide (tone, terminology, consistency)
- Comment format templates (Doxygen for C, DocC for Swift)
- Code examples of well-documented functions
- Tools and how to run them (Doxygen, DocC, validation)
- CI/CD integration (linting, example verification)
- Maintenance schedule and responsibility

**Alternatives Considered**:
- Inline comments only: No centralized guidance; inconsistency likely
- Wiki documentation: Diverges from code; hard to maintain
- Contributing guidelines only: Too brief; doesn't give enough detail

**Application**: Create `DOCUMENTATION.md` at repository root.

---

## 7. Terminology Consistency

**Decision**: Establish and enforce a glossary of terms used across C, Swift, and user-facing documentation.

**Rationale**:
- Users are confused by inconsistent terminology (e.g., "hue offset" vs. "hue rotation")
- Maintainers make mistakes when refactoring if terminology changes
- Consistency across C and Swift APIs builds trust in design

**Key Terms** (from Constitution & PRD):
- **Journey** – A continuous color path defined by anchors, configuration, and perceptual constraints
- **Anchor** – A keypoint color in OKLab space that defines a journey
- **Configuration** – High-level intent parameters (lightness bias, chroma bias, etc.)
- **Sampling** – Extracting a single color from a journey at parameter `t ∈ [0, 1]`
- **Perceptual Bias** – A modifier affecting lightness, chroma, contrast, temperature, or vibrancy
- **Contrast Enforcement** – Automatic adjustment to ensure minimum perceptual distance between samples
- **Variation** – Optional, seeded micro-adjustments for organic aesthetics (off by default)
- **Discrete Palette** – A finite set of colors extracted from a journey (typically 5-20 colors)
- **Continuous Journey** – Infinite, smooth color generation across parameter range [0, 1]
- **Determinism** – Property that same config always produces same output, bit-for-bit
- **Loop Mode** – Behavior at journey boundaries (open, closed loop, ping-pong)

**Alternatives Considered**:
- Allow mixed terminology: Confusing for users and maintainers
- Define terms inline: Hard to find and maintain consistency
- Use different terms per layer: Breaks discoverability and understanding

**Application**: Document glossary in `DOCUMENTATION.md`; enforce in code review.

---

## 8. References & External Documentation Integration

**Decision**: Code comments MUST reference external documents (Constitution, PRD, OKLab paper) with file paths and section numbers.

**Rationale**:
- Designers and maintainers need to understand the "why" behind constraints
- References prevent reinventing decisions or accidentally breaking constraints
- Links external knowledge (academic papers, design briefs) to implementation

**Format**:
```c
/**
 * Adjusts chroma according to the ChromaBias configuration.
 * 
 * This implements the perceptual bias principle from the ColorJourney Constitution
 * (see .specify/memory/constitution.md, Section III: Designer-Centric Configuration).
 * 
 * The adjustment uses OKLab chroma dimension (validated by Okabe & Ito, 2008;
 * see DevDocs/ANALYSIS_INDEX.md for reference).
 */
```

**References to Include**:
- `.specify/memory/constitution.md` – Design principles and governance
- `README.md` – Architecture and quick start
- `DevDocs/PRD.md` – Product requirements and design decisions
- `DevDocs/ANALYSIS_INDEX.md` – Performance analysis and trade-offs
- Academic papers (OKLab, perceptual color spaces) – External validation

**Alternatives Considered**:
- No references: Maintainers lose context; decisions are fragile
- Links to external wikis: URLs change; broken links; requires external storage
- Comments only: No traceability; hard to audit correctness

**Application**: All public API documentation and complex algorithm comments.

---

## 9. README and Entry Point Updates

**Decision**: Update `README.md` to link to documentation resources and establish clear entry points for different audiences.

**Rationale**:
- Most developers start with README
- Should guide developers to appropriate documentation (API reference, examples, guides)
- Establishes information architecture (where to find what)

**Content Additions**:
- **For New Users**: Link to examples and quick start
- **For API Users**: Link to API reference (generated by Doxygen/DocC) and usage guide
- **For Contributors**: Link to CONTRIBUTING.md and DOCUMENTATION.md
- **For Maintainers**: Link to architecture docs and Constitution

**Alternatives Considered**:
- No updates to README: Discoverable documentation requires external knowledge
- Duplicate documentation: Hard to keep in sync
- Wiki only: Separate from code; users may miss it

**Application**: Update `README.md` root-level links section.

---

## Summary of Research Findings

All major unknowns have been resolved:

| Unknown | Decision | Confidence |
|---------|----------|------------|
| C documentation format | Doxygen JavaDoc comments | Very High |
| Swift documentation format | DocC (`///`) comments | Very High |
| Architecture documentation location | In-code comments + separate `ARCHITECTURE.md` | High |
| Test documentation approach | Intent-focused comments explaining "why" | Very High |
| Example verification | CI/CD verification that examples compile/run | High |
| Maintenance standards | `DOCUMENTATION.md` as source of truth | High |
| Terminology consistency | Glossary in `DOCUMENTATION.md` | High |
| External references | Inline comments linking to Constitution, PRD, papers | Very High |
| README updates | Clear entry points for different audience types | High |

All decisions align with the ColorJourney Constitution (Universal Portability, Perceptual Integrity, Designer-Centric Controls, Deterministic Output, Comprehensive Testing).

---

**Phase 0 Complete** ✓
