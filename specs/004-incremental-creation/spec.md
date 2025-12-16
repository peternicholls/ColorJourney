# Incremental Color Swatch Generation Specification

**Feature ID:** 004-incremental-creation  
**Status:** Partially Implemented (SC-001 to SC-007 ✅ shipped Dec 9; SC-008 to SC-012 🔄 planned)  
**Branch:** `004-incremental-creation` (core API implementation and enhancements)  
**Core Implementation Date:** December 9, 2025  
**Planned Enhancements:** See Phase 1–3 in [plan.md](plan.md)  

---

## Overview

This specification defines API patterns for generating color swatches incrementally when the total count is not known in advance. It addresses use cases where applications need to generate colors one at a time (progressive UI building, dynamic data loading, interactive workflows) rather than specifying a fixed count upfront.

---

## Problem Statement

The current ColorJourney API requires users to specify the exact number of colors needed upfront:

```c
// Current C API
CJ_RGB palette[5];
cj_journey_discrete(journey, 5, palette);

// Current Swift API
let colors = journey.discrete(count: 10)
```

This works well when the number of colors is known in advance, but fails in scenarios where:

1. **Progressive UI building** - Adding UI elements dynamically (timeline tracks, categories, labels)
2. **User-driven expansion** - Users add items one at a time (tags, labels, segments)
3. **Streaming data** - Processing data where the final count emerges over time
4. **Interactive design** - Designers exploring color options incrementally
5. **Responsive layouts** - Column counts change with screen size, requiring more/fewer colors

---

## Solution: Hybrid Index-Based + Range Access

### C API

```c
// Index-based access
CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index);

// Range access for batch operations
// Note: Uses count, not end - incremental steps don't know end at any time
void cj_journey_discrete_range(CJ_Journey journey, int start, int count, CJ_RGB* out_colors);

// Constant defining default spacing
#define CJ_DISCRETE_DEFAULT_SPACING 0.05f
```

### Swift API

```swift
// Index-based access
func discrete(at index: Int) -> ColorJourneyRGB

// Range access
// Note: Swift uses Range<Int> (0..<10) which translates to C's start=0, count=10
// Semantic difference is intentional: Swift idiomatic vs C count-based
func discrete(range: Range<Int>) -> [ColorJourneyRGB]

// Subscript convenience
subscript(index: Int) -> ColorJourneyRGB { get }

// Lazy sequence for streaming
var discreteColors: AnySequence<ColorJourneyRGB>
```

---

## Functional Requirements

### FR-001: Deterministic Index Mapping
- **MUST** map index to journey position deterministically
- **MUST** use fixed spacing: `t = (index * 0.05) % 1.0`
- **MUST** return identical colors for same index across calls

### FR-002: Contrast Enforcement
- **MUST** enforce configured minimum contrast between adjacent indices
- **MUST** respect contrast level (LOW/MEDIUM/HIGH)
- **MUST** match contrast behavior of existing `cj_journey_discrete()`

### FR-003: Index Access Performance
- **SHALL** accept complexity of O(n) for index access where n = index
- **SHALL** document performance characteristics clearly
- **SHALL** provide range access for efficient batch operations

### FR-004: Range Access Optimization
- **MUST** provide `discrete_range()` for efficient sequential access
- **MUST** ensure range access matches individual index calls
- **SHALL** have O(start + count) performance

### FR-005: Backward Compatibility
- **MUST NOT** break existing `cj_journey_discrete()` API
- **MUST NOT** change existing function signatures
- **MUST** preserve existing test behavior

### FR-006: Error Handling
- **MUST** return black (0,0,0) for negative indices
- **MUST** return black (0,0,0) for NULL journey
- **MUST** handle invalid journey handles gracefully (Swift: return black, no crash)
- **SHALL** handle edge cases gracefully (overflow, precision loss)
- **Strategy:** "Return black" approach matches existing codebase patterns (consistent with `cj_journey_discrete()` and other APIs)
- **Rationale:** Simple, predictable, no new error handling mechanisms required; maintains API simplicity and backward compatibility
- **Note:** Error vs. legitimate black color distinction deferred to future error reporting enhancement (post-1.0)

### FR-007: Delta Range Enforcement (Incremental Workflow)
- **MUST** enforce minimum perceptual delta (Delta ΔE in OKLab) of 0.02 between consecutive colors (default)
- **MUST** enforce maximum perceptual delta (Delta ΔE in OKLab) of 0.05 between consecutive colors (default)
- **SHALL** accept explicit overrides for min/max delta (future enhancement, SC-013+)
- **Scope:** Applies to incremental creation workflow only; effectiveness evaluation determines general rollout (Phase 3, E-001)
- **Color Space:** All perceptual measurements use OKLab color space
- **Research Status:** Not started (delta range is design decision, not research; effectiveness validated in Phase 3)
- **Implementation Status:** Pending (I-001, Phase 1); evaluation pending (E-001, Phase 3)
- **Override API:** Deferred to SC-013+ (post-evaluation sprint)

---

## Technical Design

### Position Calculation

```c
static float discrete_position_from_index(int index) {
    if (index < 0) return 0.0f;
    float t = fmodf((float)index * CJ_DISCRETE_DEFAULT_SPACING, 1.0f);
    return t;
}
```

**Key Properties:**
- Fixed position spacing of 0.05 yields ~20 colors per full journey cycle
- Modulo wrapping creates infinite cyclic sequence
- Deterministic: same index always maps to same position
- **Delta constraints (separate from spacing):** Perceptual ΔE minimum 0.02, maximum 0.05 (defaults, overridable in future)
- **Note:** Position spacing (0.05) and perceptual delta range (0.02-0.05) are distinct concepts

### Contrast Enforcement

Each color at index N must respect minimum contrast with color at index N-1:

```c
// Pseudocode
for i from 0 to index-1:
    previous_color = compute_color_at(i)

return compute_color_at(index, with_contrast_to: previous_color)
```

**Delta Range Constraints:**
- Minimum ΔE (OKLab): 0.02 (ensures sufficient perceptual distinctness)
- Maximum ΔE (OKLab): 0.05 (prevents excessive perceptual jumps)
- Default behavior: Enforced automatically in incremental workflow
- Future: API for explicit override (TODO)
- Research needed: Confirm optimal range for perceptual balance

**Delta Range Enforcement Algorithm:**

*Definition:* "Available range" = color space positions between index-1 and index where both ΔE(base, prev) ≥ 0.02 AND ΔE(base, prev) ≤ 0.05 can be satisfied.

1. Compute base color at position t = index × 0.05 in OKLab space (modulo wrapping via `fmod(t, 1.0)`)
2. Calculate ΔE(base, previous) where previous = color at index−1
3. **If ΔE < 0.02 (too similar):** Adjust position forward (increase t) until ΔE ≥ 0.02
4. **If ΔE > 0.05 (too different):** Adjust position backward (decrease t) until ΔE ≤ 0.05
5. **If constraints conflict** (e.g., no position exists where both ≥ 0.02 and ≤ 0.05): Prefer enforcing minimum ΔE ≥ 0.02 over maximum ≤ 0.05 (perceptual distinctness takes priority)
   - *Example:* If previous color forces ΔE to be either <0.02 (too similar) or >0.05 (too different), choose position that achieves ΔE ≥ 0.02 even if it exceeds 0.05 (better to have distinguishable colors than indistinguishable ones)
6. Apply standard contrast enforcement (FR-002) after delta adjustment (tighter bound applies)
7. Return final adjusted position and computed color

**Exhaustion and Fallback Strategy (Loop Closure):**

When local OKLab region around base position `t` is saturated (i.e., cannot satisfy constraints within reasonable search radius):

1. **Search Bounds**: Limit position adjustment to ±0.10 in `t` space (~2 position steps) to prevent unbounded search
2. **Modulo Wrapping**: If adjustment exceeds [0.0, 1.0], wrap via `fmod(t, 1.0)` to explore next cycle of closed loop
3. **Soft Chroma Reduction**: If no valid position found after wrapping, reduce chroma (saturation) by 10-20% while preserving hue and lightness, then retry constraint satisfaction
4. **Gamut Fallback**: If still failing, apply full gamut mapping (Section 9 of comprehensive spec): desaturate to sRGB boundary while maintaining perceptual continuity
5. **Guaranteed Termination**: After 3 fallback iterations, accept best-effort color (minimum ΔE ≥ 0.01, relaxed from 0.02) to ensure function always returns

**Loop Topology for 004:**
- **Mode**: Closed loop only (no open/ping-pong/Möbius variants in this feature)
- **Cycle Length**: ~20 colors per full cycle (1.0 / 0.05 spacing)
- **Infinite Sequence**: Index 0, 20, 40, ... map to same position (0.0) but with contrast chain history affecting final color
- **No Duplicate Prevention**: Unlike comprehensive engine, `discrete_at()` does not deduplicate; caller's responsibility to handle wrap-around if needed

**Relationship to FR-002 (Contrast):**
- FR-002: Minimum contrast enforcement (user-configured: LOW/MEDIUM/HIGH, e.g., 0.04–0.10 ΔE for MEDIUM)
- FR-007: Delta Range Enforcement (fixed 0.02–0.05 ΔE for incremental workflow)
- Both measured as ΔE in OKLab color space
- Delta Range Enforcement provides tighter perceptual bounds: If both apply, enforce intersection (e.g., MEDIUM contrast [0.04–0.10] ∩ delta range [0.02–0.05] = [0.04–0.05])
- Conflict Resolution: Prefer tighter lower bound (minimum) over maximum if ranges conflict (see I-001-A algorithm design in tasks.md)
- Evaluation: Assess effectiveness in Phase 3 (E-001) before considering general rollout

**Implication:** Index access requires computing all preceding colors to maintain contrast chain and delta constraints.

### Memory Model

- **No persistent state** - Each call is independent
- **Stack-only allocation** - No dynamic memory management
- **Contrast chain built on-demand** - Recomputed for each index access

### Precision & Accuracy (Constitution Compliance)

**Per Constitution Principle II (Perceptual Integrity via OKLab):**

- **Double precision OKLab conversions**: All internal color space conversions use IEEE 754 double precision (64-bit) to eliminate cumulative error
- **Standard library cbrt()**: Cube root calculations use `cbrt()` from C standard library (`<math.h>`), providing machine epsilon precision (~1e-15 relative error)
- **Perceptual ΔE calculations**: OKLab ΔE (Euclidean distance) computed with full double precision before final rounding
- **Deterministic output**: Bit-identical RGB output across all platforms for same configuration

This precision upgrade (adopted in ColorJourney v2.0.0) ensures maximum perceptual accuracy for contrast enforcement and delta range calculations, especially critical for large palettes where cumulative error could otherwise degrade quality.

### Index Precision Guarantees (R-003 Research)

**Supported Index Range: 0 to 1,000,000** (verified via R-003-A/B/C research)

- **0 to 1M**: Full precision guaranteed, perceptual error <0.02 ΔE (imperceptible)
- **1M to 10M**: Warning range, perceptual error 0.02-0.10 ΔE (may be perceptible, use with caution)
- **Beyond 10M**: Not recommended, precision error >0.10 ΔE
- **Negative indices**: Return black (0,0,0) per FR-006

**Float Precision Analysis:**
- IEEE 754 single precision guarantees exact integer representation up to 2^24 (~16M)
- Position calculation error remains imperceptible (<0.02 ΔE) up to 1M indices
- Deterministic behavior guaranteed via IEEE 754 standard (same input → same output)

---

## Implementation Status

### Completed Components ✅

1. **C Core Implementation** ([ColorJourney.c](../../Sources/CColorJourney/ColorJourney.c))
   - `cj_journey_discrete_at()` - Index access
   - `cj_journey_discrete_range()` - Range access
   - `discrete_position_from_index()` - Position calculation helper
   - `discrete_color_at_index()` - Color generation with contrast
   - `discrete_min_delta_e()` - Contrast threshold helper

### Pending Implementation 🔄

1. **Delta Range Enforcement** (FR-007)
   - Minimum delta: 0.02 (default, prevents colors too similar)
   - Maximum delta: 0.05 (default, prevents excessive jumps)
   - Research phase: Confirm optimal perceptual range
   - Future API: Allow explicit min/max override (TODO)

2. **C Header** ([ColorJourney.h](../../Sources/CColorJourney/include/ColorJourney.h))
   - Public API declarations with Doxygen documentation
   - `CJ_DISCRETE_DEFAULT_SPACING` constant definition

3. **Swift Wrapper** ([ColorJourneyClass.swift](../../Sources/ColorJourney/Journey/ColorJourneyClass.swift))
   - `discrete(at:)` method
   - `discrete(range:)` method
   - `subscript[index]` convenience
   - `discreteColors` lazy sequence

4. **Tests**
   - C Core: 4 tests covering determinism, consistency, contrast
   - Swift: 3 tests covering index, range, subscript, sequence access
   - All tests passing ✅

5. **Documentation**
   - Complete Doxygen comments on C functions
   - Complete DocC comments on Swift API
   - Performance notes included
   - Code review document: [CODE_REVIEW_INCREMENTAL_SWATCH.md](../../DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md)

---

## Usage Examples

### C Example: Progressive UI Building

```c
CJ_Journey journey = cj_journey_create(...);

// Add elements one at a time
for (int i = 0; i < user_element_count; i++) {
    CJ_RGB color = cj_journey_discrete_at(journey, i);
    assign_color_to_element(elements[i], color);
}
```

### Swift Example: Dynamic Tag System

```swift
let journey = ColorJourney(...)

// Generate colors as tags are added
func colorForTag(at index: Int) -> ColorJourneyRGB {
    return journey[index]  // Subscript access
}

// Or use lazy sequence for streaming
for (index, color) in journey.discreteColors.prefix(10).enumerated() {
    print("Tag \(index): \(color)")
}
```

---

## Testing Strategy

### Test Coverage

1. **Determinism Tests**
   - Verify same index returns identical color on repeated calls
   - Verify consistency across C and Swift APIs

2. **Consistency Tests**
   - Verify range access matches individual index calls
   - Verify subscript matches `discrete(at:)`
   - Verify lazy sequence matches range access

3. **Contrast Tests**
   - Verify minimum ΔE between adjacent colors
   - Verify contrast enforcement matches batch API

4. **Delta Range Tests** (FR-007)
   - Verify ΔE ≥ 0.02 between all adjacent colors (minimum enforcement)
   - Verify ΔE ≤ 0.05 between all adjacent colors (maximum enforcement)
   - Test constraint conflict resolution (prefer minimum)
   - Test delta enforcement with different contrast levels
   - Measure effectiveness for incremental workflow evaluation

5. **Edge Cases**
   - Negative indices return black
   - NULL journey handles gracefully
   - Single-color palettes work correctly

### Test Results

All 56 tests passing:
- C Core: 4 tests ✅
- Swift: 52 tests (including 3 new incremental tests) ✅

---

## Performance Characteristics

### Complexity Analysis

| Operation | Complexity | Notes |
|-----------|------------|-------|
| `discrete_at(index)` | O(n) | n = index; must compute contrast chain |
| `discrete_range(start, count)` | O(start + count) | More efficient for batches |
| `discreteColors.prefix(n)` | O(n) | Uses range access internally |

### Memory Usage

- Stack-only allocation: ~24 bytes per call
- No heap allocations
- No persistent cache (stateless design)
- Lazy sequence buffer: 1.17 KB (100 colors × 12 bytes) - **confirmed optimal via R-001-B research**

### Performance Benchmarking Strategy

**Baseline:** C core is known to be fast - all measurements compare to C core performance

**Metrics to Track:**
- Color generation time (individual and batched)
- Memory allocation overhead
- Thread contention under concurrent load
- Precision at high indices

**TODO:** Establish concrete performance regression thresholds

### Performance Guidance

- **Sequential access:** Use range access or lazy sequence for best performance
- **Random access:** O(n) cost acceptable for typical indices (< 1000)
- **Frequent access:** Consider implementing application-level caching

### Color Space Specification

**All perceptual reasoning uses OKLab:**
- Contrast measurements: ΔE in OKLab
- Delta range enforcement: ΔE in OKLab
- Perceptual distance calculations: OKLab
- Consistent with existing ColorJourney perceptual model

---

## Migration Guide

### For Existing Code

No migration required - all existing APIs remain unchanged:

```swift
// Old API still works
let colors = journey.discrete(count: 10)

// New APIs available for incremental use
let firstColor = journey[0]
let secondColor = journey[1]
let batch = journey.discrete(range: 0..<10)
```

### Recommended Usage

**When count is known:** Use existing batch API
```swift
let colors = journey.discrete(count: 10)
```

**When count is dynamic:** Use new incremental API
```swift
for i in 0..<dynamicCount {
    let color = journey[i]
}
```

**For streaming:** Use lazy sequence
```swift
for (index, color) in journey.discreteColors.enumerated() {
    if shouldStop { break }
    processColor(color, at: index)
}
```

---

## References

- **Full Specification:** [DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md](../../DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md)
- **Code Review:** [DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md](../../DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md)
- **Demo:** [Examples/SwatchDemo/](../../Examples/SwatchDemo/)
- **Implementation Commit:** `8ed337d` (December 9, 2025)

---

## Research & Investigation Tasks

### High Priority Research

1. **Delta Range Optimization (FR-007)**
   - Confirm 0.02-0.05 range provides optimal perceptual balance
   - Test effectiveness in incremental workflows
   - Evaluate: Should this be rolled out generally or remain incremental-specific?
   - Benchmark: Impact on generation time

### Completed Research (Phase 0) ✅

2. **Lazy Sequence Chunk Size (SC-012)** ✅
   - **Decision:** Keep chunk size 100 (confirmed optimal)
   - **Rationale:** At inflection point for common case (100 colors), only 2% difference vs larger chunks
   - **Memory:** 1.17 KB (negligible overhead)
   - **Performance:** Within 10% of C baseline for typical use
   - **Report:** [chunk-size-decision.md](analysis-reports-phase-0/chunk-size-decision.md)

3. **Index Overflow Strategy (FR-008)** ✅
   - **Decision:** Document supported range 0-1M, match codebase pattern
   - **Precision:** Guaranteed <0.02 ΔE up to 1,000,000 indices
   - **Strategy:** No runtime checks, developer responsibility
   - **Report:** [index-precision-analysis.md](analysis-reports-phase-0/index-precision-analysis.md)

4. **Thread Safety Validation (SC-011)** ✅
   - **Result:** Safe for concurrent reads (100K+ ops tested)
   - **Guarantee:** Stateless design, no shared mutable state
   - **Performance:** 117K ops/second with 100 threads
   - **Report:** [thread-safety-stress-test-report.md](analysis-reports-phase-0/thread-safety-stress-test-report.md)

5. **Error Reporting Enhancement (FR-006)**
   - Research: Error code vs. status return patterns in codebase
   - Design: Distinguish error-black from legitimate-black
   - Investigate: Swift error handling best practices
   - Plan: Future API versioning for error returns

---

## Success Criteria & Task Traceability

| Success Criterion | Status | Task(s) | Notes |
|---|---|---|---|
| **SC-001:** Index access returns deterministic colors | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-002:** Range access matches individual calls | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-003:** Contrast enforcement works identically to batch API | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-004:** All tests passing (100% pass rate) | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-005:** Backward compatibility maintained | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-006:** Documentation complete (Doxygen + DocC) | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-007:** Performance characteristics documented | ✅ | (Core API) | Shipped Dec 9, 2025 |
| **SC-008:** Delta Range Enforcement (ΔE: 0.02–0.05 in OKLab) | 🔄 | I-001-B, I-001-C | Phase 1 implementation; Phase 3 evaluation (E-001) |
| **SC-009:** Error handling for invalid inputs | 🔄 | I-002-A, I-002-B, I-002-C | Phase 1 implementation |
| **SC-010:** Index bounds tested (0 to 1,000,000) | 🔄 | I-003-A, I-003-B, I-003-C | Phase 1 implementation; depends on R-003 research |
| **SC-011:** Thread safety verified | 🔍 | R-002-A, R-002-B, R-002-C | Phase 0 research; no rollout decision yet |
| **SC-012:** Lazy sequence chunk size optimized | 🔍 | R-001-A, R-001-B, R-001-D | Phase 0 research; decision in R-001-D |

**Legend:**
- ✅ Completed & verified (shipped in core API)
- 🔄 Implementation required (Phase 1–2)
- 🔍 Research/investigation required (Phase 0) before rollout decision

**Legend:**
- ✅ Completed and verified
- 🔄 Implementation required
- 🔍 Research/investigation needed

**Status Summary:**
- **Current:** SC-001 to SC-007 met ✅ (core implementation complete)
- **Next Sprint:** SC-008 to SC-010 (delta range, error handling, bounds)
- **Research Phase:** SC-011 to SC-012 (thread safety, chunk size optimization)
- **Future:** Override API design, error code mechanism, general rollout evaluation

**Status:** SC-001 to SC-007 met ✅ | SC-008 to SC-010 require implementation 🔄 | SC-011 to SC-012 require research 🔍
