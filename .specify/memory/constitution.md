<!-- 
╔════════════════════════════════════════════════════════════════╗
║           COLORJOURNEY CONSTITUTION SYNC REPORT                ║
╚════════════════════════════════════════════════════════════════╝

VERSION: 1.0.0 (NEW)
RATIFICATION: 2025-12-07
PRINCIPLES: 5 core principles established
GOVERNANCE: Amendment process, compliance rules defined

KEY UPDATES:
  ✅ Universal Portability (C99 core as canonical)
  ✅ Perceptual Integrity (OKLab as truth)
  ✅ Designer-Centric Controls (high-level intent)
  ✅ Deterministic Output (reproducible, seeded variation)
  ✅ Comprehensive Testing (mandatory coverage)

SECTIONS ADDED:
  • Development Standards (code org, performance, API stability)
  • Governance (amendment process, compliance, guidance)
  • Version History

TEMPLATES REVIEWED:
  ✅ CONTRIBUTING.md: Already emphasizes C99 standards & testing
  ✅ README.md: Already documents portability & determinism
  ⚠ Templates: Recommend reviewing for constitutional alignment

NO BREAKING CHANGES TO PROJECT STRUCTURE
-->

# ColorJourney Constitution

A design and engineering constitution for the ColorJourney color palette generation system.

---

## Core Principles

### I. Universal Portability First

**MUST:** The C99 core library is the canonical implementation and the gateway to all platforms and languages.

Every feature implementation prioritizes the C core over language-specific optimizations. The C core must:
- Compile on any C99-capable system (macOS, iOS, Linux, Windows, embedded, browsers via WASM)
- Have zero external dependencies beyond the C standard library (only `-lm` for math)
- Be deterministic and produce identical output across all platforms
- Remain forward-compatible for at least 20 years (no breaking changes to the core C API)

Language wrappers (Swift, future Python/Rust/JavaScript) are convenience layers. They MUST NOT expose behavior that diverges from the C core. When in doubt, the C core behavior is canonical.

**Rationale:** The core vision is that ColorJourney works everywhere forever. C is the only universal language. This principle ensures the library can be embedded in any project, on any platform, in any language, without vendor lock-in or runtime dependencies.

---

### II. Perceptual Integrity via OKLab

**MUST:** All color math operates internally in OKLab color space. All perceptual decisions (contrast, lightness, chroma, hue) use OKLab as truth.

Every journey, every palette, and every sampling operation MUST:
- Convert input sRGB to OKLab at initialization
- Perform all interpolation, distance, and adjustment logic in OKLab space
- Enforce minimum perceptual contrast using OKLab ΔE (Euclidean distance)
- Maintain lightness, chroma, and hue continuity using OKLab's perceptually uniform geometry
- Convert back to sRGB only at output (final sampling or discrete palette generation)

Output colors MUST be reproducible—same input config always produces same output RGB values, bit-for-bit, on all platforms.

**Rationale:** OKLab was chosen because it maps human perception reliably. Using it consistently ensures colors that look good, avoid muddy midpoints, and maintain readable contrast. No surprises, no platform-specific drifts. Designers trust the output because OKLab guarantees perceptual uniformity.

---

### III. Designer-Centric Configuration

**MUST:** Configuration MUST use high-level aesthetic intent (lightness, chroma, contrast, temperature, vibrancy), never low-level RGB or HSL sliders.

Every configuration option (whether via C struct, Swift enum, or future binding) MUST:
- Express design intent, not math parameters
- Be independently adjustable without side effects
- Have clear documentation of its perceptual effect
- Support reasonable defaults and presets

Users should never need to understand OKLab internally. Configuration SHOULD feel natural: "I want this lighter, more vivid, and warmer"—not "adjust a=12.4, b=-8.3 in Lab space."

**Rationale:** Designers think in terms of perception and intent. Engineers can implement the intent. By enforcing high-level controls, we ensure the API is discoverable, the output is predictable, and misuse is harder.

---

### IV. Deterministic Output with Optional Variation

**MUST:** By default, output is fully deterministic: same config always produces same palette.

Variation (micro-adjustments for organic feel) is OPTIONAL and MUST:
- Be disabled by default
- Use seeded, deterministic PRNG (currently xoshiro128+) if enabled
- Never leak non-determinism unless explicitly configured with a seed
- Respect all perceptual constraints (contrast, hue continuity, lightness bounds)

Determinism is a feature for designers: they can bake a palette config into their design system and share it across teams, codebases, and platforms with zero surprises.

**Rationale:** Production design systems require reproducibility. Variation is a nice-to-have for organic aesthetics, but it must never be a surprise. Seeded randomness gives the best of both worlds: controlled, reproducible variation.

---

### V. Comprehensive Testing & Quality Assurance

**MUST:** Every feature (in C core and language wrappers) MUST have corresponding unit tests. No exceptions.

Test coverage expectations:
- All public APIs tested
- All configuration options tested (including edge cases)
- All loop modes (open, closed, ping-pong) tested
- All perceptual biases (lightness, chroma, contrast, temperature, vibrancy) tested
- Discrete and continuous sampling both tested
- Variation layer tested (enabled/disabled, per-dimension, deterministic seeding)
- Performance benchmarked (target: 10,000+ samples/sec, <1ms for 100-color palette)
- Cross-platform output validation (same config produces identical sRGB on all platforms)

Tests MUST be readable, focused, and documented. Integration tests preferred where they cover real use cases.

**Rationale:** Quality is non-negotiable. The library is used in design systems and production UIs. A single perceptual inconsistency or platform drift could break workflows. Comprehensive tests catch issues early and protect against future regressions.

---

## Development Standards

### Code Organization

The codebase is organized in two layers:

**Layer 1: C Core** (`Sources/CColorJourney/`)
- Pure C99, self-contained
- Public API in `ColorJourney.h`
- Implementation in `ColorJourney.c` (~500 lines)
- No external dependencies
- Optimized for performance and portability

**Layer 2: Language Wrappers** (e.g., `Sources/ColorJourney/`)
- Swift wrapper provides ergonomic API
- Value-type configuration (structs, enums)
- Type-safe, discoverable in IDE autocomplete
- Transparent bridging to C core (no logic duplication)
- Platform integrations (SwiftUI, AppKit, UIKit as needed)

Future wrappers (Python, Rust, JavaScript) MUST follow the same structure: thin, idiomatic layers over the C core.

### Performance Requirements

The C core MUST maintain:
- **Continuous sampling:** ≤1 microsecond per `sample(at: t)` call
- **Discrete palette:** ≤1 millisecond for 100-color palette generation
- **Zero allocations** for continuous sampling
- **Minimal allocations** for discrete palette (~2KB per journey)
- **Deterministic performance** across platforms (no unexplained variance)

Any optimization MUST NOT compromise perceptual accuracy or determinism.

### API Stability

The C API is considered stable. Changes MUST adhere to semantic versioning:
- **MAJOR**: Breaking changes to C function signatures or behavior
- **MINOR**: New features, expanded options, non-breaking additions
- **PATCH**: Bug fixes, documentation, performance improvements

Swift API and language wrappers can evolve more freely but MUST maintain backward compatibility within MAJOR versions.

---

## Governance

### Amendment Process

This constitution supersedes all other development practices. Amendments MUST:

1. **Be documented** – A clear issue or RFC explaining the change and rationale
2. **Maintain existing principles** – Do not remove or contradict existing principles without clear justification
3. **Update version** – Bump MAJOR, MINOR, or PATCH according to the scale of change
4. **Update affected templates** – Ensure `.specify/templates/` files reflect constitutional changes
5. **Be validated** – All tests pass, documentation updated, stakeholders informed

### Compliance

All PRs MUST verify compliance with this constitution:
- C core changes maintain zero external dependencies and C99 compatibility
- API changes remain deterministic and perceptually sound
- Tests added for every feature change
- Documentation updated for user-facing changes
- Version bumps justified and recorded

Maintainers SHOULD reference this constitution in code reviews when requesting alignment.

### Runtime Development Guidance

For day-to-day development, refer to:
- `CONTRIBUTING.md` – Contribution process, coding standards, commit conventions
- `README.md` – User-facing architecture, quick start, API reference
- `DevDocs/` – Detailed analysis, requirements, implementation notes
- Test suite – Reference implementation of all features

### Living Document

This constitution is a living document. As the project evolves (new platforms, new wrapper languages, new requirements), the constitution MUST evolve with it. However, core principles (Universal Portability, Perceptual Integrity, Designer-Centric Controls, Deterministic Output, Testing) are non-negotiable and should remain stable.

---

## Version History

| Version | Date | Amendment |
|---------|------|-----------|
| 1.0.0 | 2025-12-07 | Initial constitution based on ColorJourney design principles |

---

**Version**: 1.0.0 | **Ratified**: 2025-12-07 | **Last Amended**: 2025-12-07
