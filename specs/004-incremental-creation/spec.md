# Incremental Color Swatch Generation Specification

**Feature ID:** 004-incremental-creation  
**Status:** Implemented & Merged  
**Branch:** `004-incremental-creation`  
**Implementation Date:** December 9, 2025  

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
void cj_journey_discrete_range(CJ_Journey journey, int start, int count, CJ_RGB* out_colors);

// Constant defining default spacing
#define CJ_DISCRETE_DEFAULT_SPACING 0.05f
```

### Swift API

```swift
// Index-based access
func discrete(at index: Int) -> ColorJourneyRGB

// Range access
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
- **SHALL** handle edge cases gracefully

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
- Fixed spacing of 0.05 yields ~20 colors per full journey cycle
- Modulo wrapping creates infinite cyclic sequence
- Deterministic: same index always maps to same position

### Contrast Enforcement

Each color at index N must respect minimum contrast with color at index N-1:

```c
// Pseudocode
for i from 0 to index-1:
    previous_color = compute_color_at(i)

return compute_color_at(index, with_contrast_to: previous_color)
```

**Implication:** Index access requires computing all preceding colors to maintain contrast chain.

### Memory Model

- **No persistent state** - Each call is independent
- **Stack-only allocation** - No dynamic memory management
- **Contrast chain built on-demand** - Recomputed for each index access

---

## Implementation Status

### Completed Components ✅

1. **C Core Implementation** ([ColorJourney.c](../../Sources/CColorJourney/ColorJourney.c))
   - `cj_journey_discrete_at()` - Index access
   - `cj_journey_discrete_range()` - Range access
   - `discrete_position_from_index()` - Position calculation helper
   - `discrete_color_at_index()` - Color generation with contrast
   - `discrete_min_delta_e()` - Contrast threshold helper

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

4. **Edge Cases**
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

### Performance Guidance

- **Sequential access:** Use range access or lazy sequence for best performance
- **Random access:** O(n) cost acceptable for typical indices (< 1000)
- **Frequent access:** Consider implementing application-level caching

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

## Success Criteria

- ✅ **SC-001:** Index access returns deterministic colors
- ✅ **SC-002:** Range access matches individual calls
- ✅ **SC-003:** Contrast enforcement works identically to batch API
- ✅ **SC-004:** All tests passing (100% pass rate)
- ✅ **SC-005:** Backward compatibility maintained
- ✅ **SC-006:** Documentation complete (Doxygen + DocC)
- ✅ **SC-007:** Performance characteristics documented

**Status:** All success criteria met ✅
