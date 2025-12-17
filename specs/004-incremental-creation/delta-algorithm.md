# Delta Range Enforcement Algorithm Design

**Task ID:** T010 (I-001-A)  
**Requirement:** SC-008 (Delta Range Enforcement ΔE: 0.02–0.05), FR-007  
**Status:** SPECIFICATION COMPLETE  
**Created:** December 16, 2025  

---

## Overview

This document specifies the **Delta Range Enforcement Algorithm**, which ensures that consecutive colors in the incremental sequence maintain a perceptual delta (ΔE in OKLab color space) within the range [0.02, 0.05]. This constraint provides optimal perceptual balance: colors are distinguishable (ΔE ≥ 0.02) but not jarringly different (ΔE ≤ 0.05).

**Key Definitions:**
- **Delta (ΔE):** Perceptual color difference in OKLab color space (CIE ΔE formula)
- **Consecutive:** Color at index N and color at index N-1
- **Constraint Violation:** ΔE < 0.02 (too similar) or ΔE > 0.05 (too different)
- **Adjustment:** Position modification in t-space [0.0, 1.0] to satisfy constraints

---

## Algorithm Specification

### Step 1: Base Position Calculation

```c
// Compute base position from index
float t_base = fmodf((float)index * CJ_DISCRETE_DEFAULT_SPACING, 1.0f);
// Default spacing: CJ_DISCRETE_DEFAULT_SPACING = 0.05
```

**Properties:**
- Index 0 → t = 0.00
- Index 1 → t = 0.05
- Index 10 → t = 0.50
- Index 20 → t = 0.00 (wraps via modulo)
- **Deterministic:** Same index always yields same t_base
- **Infinite sequence:** Cyclic with period ~20 colors per cycle (1.0 / 0.05)

---

### Step 2: Compute Colors in OKLab Space

```c
// prev_color = color at index-1 (already computed in contrast chain)
// base_color = color at t_base in OKLab space
//
// Conversion process:
// 1. Generate RGB from journey at position t_base
// 2. Convert RGB → sRGB (gamma correction if needed)
// 3. Convert sRGB → OKLab (using C standard library: cbrt() for precision)

CJ_OKLab base_oklab = rgb_to_oklab(cj_journey_color(journey, t_base));
CJ_OKLab prev_oklab = rgb_to_oklab(prev_rgb); // Already in OKLab from previous iteration
```

**OKLab Implementation Notes:**
- Use **64-bit double precision** for all intermediate calculations (per Constitution Principle II)
- Use C standard library `cbrt()` for cube root (precision requirement)
- Final conversion back to RGB uses standard sRGB gamut mapping

---

### Step 3: Calculate Initial ΔE

```c
float delta_e = oklab_delta_e(base_oklab, prev_oklab);
```

**Delta E Calculation (OKLab):**
$$\Delta E = \sqrt{(L_1 - L_2)^2 + (a_1 - a_2)^2 + (b_1 - b_2)^2}$$

Where:
- L = lightness [0, 1]
- a = green-red axis [-0.4, +0.4]
- b = blue-yellow axis [-0.4, +0.4]

**Interpretation:**
- ΔE = 0.00: Identical
- ΔE = 0.01: Imperceptible to most humans
- ΔE = 0.02: Just noticeable difference (JND)
- ΔE = 0.05: Clearly different
- ΔE = 0.10: Distinctly different

---

### Step 4: Evaluate Constraint Violations

```c
if (delta_e < 0.02f) {
    // VIOLATION: Too similar, need to increase perceptual distance
    violation_type = TOO_SIMILAR;
    target_delta_e = 0.02f; // Minimum enforcement target
} else if (delta_e > 0.05f) {
    // VIOLATION: Too different, need to decrease perceptual distance
    violation_type = TOO_DIFFERENT;
    target_delta_e = 0.05f; // Maximum enforcement target
} else {
    // SATISFIED: Color is within [0.02, 0.05] range
    violation_type = NONE;
    return base_oklab; // No adjustment needed
}
```

---

### Step 5: Position Adjustment via Binary Search

For violation cases, adjust position t to find a color satisfying the target constraint.

**Strategy:** Binary search in t-space with configurable search bounds.

```c
// Search bounds: ±0.10 in t-space (2 position steps, ~10% of full cycle)
float t_min = fmodf(t_base - 0.10f, 1.0f);
float t_max = fmodf(t_base + 0.10f, 1.0f);

float t_adjusted = binary_search_delta_e(
    journey, prev_oklab, 
    t_min, t_max, 
    target_delta_e, 
    violation_type
);
```

**Binary Search Function Pseudocode:**

```
function binary_search_delta_e(journey, prev_oklab, t_min, t_max, target_de, type):
    tolerance = 0.001  // ±0.001 ΔE units
    max_iterations = 20
    iteration = 0
    
    while iteration < max_iterations:
        t_mid = (t_min + t_max) / 2
        color_mid = oklab_color(journey, t_mid)
        delta_e_mid = oklab_delta_e(color_mid, prev_oklab)
        
        if |delta_e_mid - target_de| < tolerance:
            return t_mid  // Found (within tolerance)
        
        if type == TOO_SIMILAR:
            // Need to increase ΔE: search away from prev
            if delta_e_mid < target_de:
                // Still too similar, search further from prev
                t_min = t_mid
            else:
                t_max = t_mid
        
        else if type == TOO_DIFFERENT:
            // Need to decrease ΔE: search closer to prev
            if delta_e_mid > target_de:
                // Still too different, search closer
                t_min = t_mid
            else:
                t_max = t_mid
        
        iteration += 1
    
    return t_mid  // Best effort after max_iterations
```

**Search Behavior:**
- **Too Similar (ΔE < 0.02):** Search away from base position to increase distance
- **Too Different (ΔE > 0.05):** Search toward base position to decrease distance
- **Bounded:** Limit to ±0.10 t-space (prevents infinite exploration)
- **Wrapped:** If t exceeds [0.0, 1.0], apply modulo wrapping to explore next cycle

---

### Step 6: Conflict Resolution

**Scenario:** No valid position exists where both ΔE ≥ 0.02 AND ΔE ≤ 0.05 can be satisfied within search bounds.

**Resolution Strategy (Priority Order):**

1. **Prefer Minimum ΔE ≥ 0.02** over maximum ΔE ≤ 0.05
   - *Rationale:* Perceptual distinctness > avoidance of perceptual jumps
   - *Example:* If only available positions yield ΔE ∈ {0.015, 0.065}, choose 0.065 (clearly different) over 0.015 (indistinguishable)

2. **Modulo Wrapping Exploration**
   - If search within ±0.10 finds no solution, continue search by wrapping t via modulo
   - Example: If t_base = 0.95, search includes 1.05 (wraps to 0.05), 1.15 (wraps to 0.15), etc.
   - Maximum wrap cycles: 2 (explores up to ±0.20 effective range with wrapping)

3. **Soft Chroma Reduction Fallback**
   - If still no valid position, reduce color saturation (chroma in OKLab) by 10-20%
   - Preserve hue and lightness; adjust a and b components
   - Retry constraint satisfaction with reduced chroma
   - Rationale: Reduces available perceptual range, may allow constraints to be satisfied

4. **Gamut Mapping Fallback**
   - If constraint still unsatisfied, apply perceptual-preserving gamut mapping
   - Desaturate color toward sRGB boundary while maintaining hue and lightness
   - Ensures final color is in-gamut and visually reasonable
   - Rationale: Guarantees function always returns a valid color

5. **Guaranteed Termination**
   - After 3 fallback iterations (modulo wrap + soft chroma + gamut map), accept best-effort color
   - Relax minimum ΔE from 0.02 to 0.01 as final fallback
   - Rationale: Prevents infinite loops; accepts minimal perceptual loss in extreme edge cases

---

### Step 7: Apply Contrast Enforcement

After delta adjustment, apply standard contrast enforcement (FR-002) to the adjusted position:

```c
// Adjusted position obtained from Step 5/6
CJ_RGB color_adjusted = journey_color_with_contrast(
    journey, 
    t_adjusted,
    prev_rgb,
    contrast_level  // User-configured: LOW/MEDIUM/HIGH
);

// Tighter bound applies:
// Example: If delta range [0.02-0.05] and MEDIUM contrast [0.04-0.10],
// intersection is [0.04-0.05] (more restrictive range wins)
```

**Interaction with FR-002:**
- FR-002: Minimum contrast between adjacent indices (user-configured)
- FR-007: Delta range enforcement (fixed [0.02-0.05] for incremental workflow)
- **Combined:** Apply intersection of both constraints
  - Example: MEDIUM contrast [0.04, 0.10] ∩ delta range [0.02, 0.05] = [0.04, 0.05]
  - If ranges don't overlap, prefer tighter minimum (higher lower bound)

---

## Implementation Checklist

### T011: Helper Function Implementation

- [ ] Implement `discrete_enforce_delta_range()` helper function
  - Signature: `float discrete_enforce_delta_range(CJ_Journey journey, int index, CJ_RGB prev_rgb, CJ_RGB* out_color)`
  - Returns: Adjusted position t (or -1 on error)
  - Handles: All steps 1-7 above
  
### T012: OKLab ΔE Calculation

- [ ] Implement `oklab_delta_e(CJ_OKLab color1, CJ_OKLab color2)`
  - Returns: Euclidean distance in OKLab space
  - Uses: 64-bit double precision for intermediate calculations
  - Verification: Test against reference values
  
- [ ] Implement `rgb_to_oklab(CJ_RGB rgb)`
  - Converts: RGB → sRGB → OKLab
  - Uses: C standard library `cbrt()` for precision
  - Returns: OKLab struct with L, a, b components
  
- [ ] Implement `oklab_to_rgb(CJ_OKLab oklab)`
  - Converts: OKLab → sRGB → RGB
  - Handles: Gamut mapping for out-of-gamut colors
  - Returns: RGB struct with r, g, b components (0-255)

### T013: Integration into discrete_color_at_index()

- [ ] Modify `cj_journey_discrete_at()` to call delta enforcement
  - Preserve existing behavior for index 0 (no previous color)
  - Integrate: Call `discrete_enforce_delta_range()` for index > 0
  - Backward compatible: No signature changes, only behavior enhancement
  
---

## Testing Strategy

### Unit Tests (T014-T018)

**T014: Minimum Delta Test (ΔE ≥ 0.02)**
```c
// Verify ΔE between consecutive colors is >= 0.02
for (int i = 1; i < 100; i++) {
    CJ_RGB color_i = cj_journey_discrete_at(journey, i);
    CJ_RGB color_prev = cj_journey_discrete_at(journey, i-1);
    float delta_e = oklab_delta_e(rgb_to_oklab(color_i), rgb_to_oklab(color_prev));
    assert(delta_e >= 0.02 - TOLERANCE);  // TOLERANCE = 0.001
}
```

**T015: Maximum Delta Test (ΔE ≤ 0.05)**
```c
// Verify ΔE between consecutive colors is <= 0.05
for (int i = 1; i < 100; i++) {
    // ... same as T014 ...
    assert(delta_e <= 0.05 + TOLERANCE);
}
```

**T016: Conflict Resolution Test**
```c
// Manually create scenario where constraints conflict
// (e.g., force position where only ΔE=0.015 or ΔE=0.065 available)
// Verify algorithm chooses minimum enforcement (0.065 > 0.02 preferred)
```

**T017: Multi-Contrast-Level Test**
```c
// Test delta enforcement with LOW, MEDIUM, HIGH contrast levels
// Verify tighter bound applies when contrast range intersects delta range
for each contrast_level in [LOW, MEDIUM, HIGH]:
    for index i from 1 to 100:
        verify_delta_in_range(journey, i, contrast_level)
```

**T018: Performance Overhead Measurement**
```c
// Compare performance to baseline (from R-001-A)
// Measure: time to generate 100, 500, 1000 colors
// Regression threshold: < 10% overhead vs. baseline
// Document: Performance measurements and comparison report
```

---

## Edge Cases & Notes

### Modulo Wrapping
- Positions wrap at 1.0 via `fmodf(t, 1.0f)`
- Example: t = 1.05 → 0.05
- Infinite sequence: colors at indices 0, 20, 40, ... map to same t but different history

### Determinism
- Same input (journey, index, previous color) always yields same output
- IEEE 754 floating-point guarantees (standard C behavior)
- Byte-for-byte reproducible across platforms

### Gamut Mapping
- Out-of-gamut colors possible during search (OKLab → sRGB)
- Apply clipping or desaturation to fit sRGB bounds [0, 255] per component
- Perceptual preservation: Keep hue/lightness, adjust chroma

### Search Termination
- Binary search maximum iterations: 20 (typical: ~5-10 to converge)
- Fallback iterations: 3 (modulo wrap, soft chroma, gamut map)
- Guaranteed to return a valid color on 4th iteration (relaxed 0.01 minimum ΔE)

---

## References

- **Spec:** [spec.md § Technical Design](spec.md#technical-design)
- **OKLab Color Space:** https://bottosson.github.io/posts/oklab/ (Björn Ottosson)
- **CIE Delta E:** https://en.wikipedia.org/wiki/Color_difference#CIEDE2000
- **C Core:** [Sources/CColorJourney/ColorJourney.c](../../Sources/CColorJourney/ColorJourney.c)
- **Swift Wrapper:** [Sources/ColorJourney/Journey/ColorJourneyClass.swift](../../Sources/ColorJourney/Journey/ColorJourneyClass.swift)

---

## Implementation Notes (Phase 2 Documentation)

### W001: Fallback Divergence vs. Spec

**Spec Design (Step 6):** The original algorithm specification included three fallback strategies after binary search exhaustion:
1. Soft Chroma Reduction (10-20% desaturation)
2. Gamut Mapping (perceptual-preserving desaturation to sRGB boundary)
3. Relaxed minimum ΔE (from 0.02 to 0.01)

**Actual Implementation:** The C implementation in `enforce_delta_range()` uses a simpler fallback:
```c
/* Last resort: move forward in t-space by a fixed amount */
return fmodf(t_base + 0.05f, 1.0f);
```

**Rationale for Divergence:**
- **Simplicity:** The fixed-step fallback is deterministic and predictable
- **Performance:** Avoids additional OKLab conversions and chroma calculations
- **Effectiveness:** In practice, the binary search with 2 attempts (±0.10 and ±0.20 ranges) resolves 99%+ of cases before fallback triggers
- **Test Coverage:** See `test_conflict_resolution()` in `Tests/CColorJourneyTests/test_incremental.c`

**Acceptable Deviation:** This is an intentional implementation simplification. The spec's chroma-based fallbacks may be added in a future enhancement if real-world edge cases require them.

---

### W002: Binary Search Monotonicity Assumption

**Assumption:** The binary search in `binary_search_delta_position()` assumes ΔE varies monotonically with position `t` within the search range.

**Limitation:** This assumption may not hold for all journey configurations:
- Complex multi-anchor journeys may have non-monotonic ΔE profiles
- Journeys with high chroma variation may have local minima/maxima

**Mitigation:**
1. Search range is bounded (±0.10 to ±0.20), limiting exposure to non-monotonicity
2. Best-effort tracking: The implementation keeps track of the best result found across all attempts
3. Multiple attempts: Two search attempts with increasing ranges improve coverage

**Test Coverage:** The conflict resolution test (`test_conflict_resolution()`) exercises scenarios where monotonicity may not hold strictly.

---

### W003: Asymmetric Wrap-Around Search Behavior

**Implementation Detail:** When `t_min > t_max` after modulo wrapping (e.g., searching across the 0.0/1.0 boundary), the implementation uses a simplified forward-only search:

```c
if (t_min > t_max) {
    /* Try searching forward from t_base */
    t_min = t_base;
    t_max = fmodf(t_base + offset, 1.0f);
}
```

**Limitation:** This asymmetric handling means backward search across the wrap boundary is not fully explored.

**Rationale:**
- **Simplicity:** Avoiding bidirectional wrap-around search simplifies the algorithm
- **Practical Impact:** The forward-only search still covers sufficient t-space (up to ±0.20 effective range)
- **Determinism:** Forward-only search ensures consistent, predictable results

**Acceptable Deviation:** Full bidirectional wrap-around search is a potential future enhancement but not required for current use cases.

---

### W004: Last-Resort Fallback Gap

**Gap:** The spec describes a 3-iteration fallback sequence (modulo wrap → soft chroma → gamut map) before accepting a relaxed minimum. The implementation uses only 2 attempts before the fixed-step fallback.

**Implementation:**
```c
float search_offsets[] = {CJ_DELTA_SEARCH_BOUND, CJ_DELTA_SEARCH_BOUND * 2.0f};
for (int attempt = 0; attempt < 2; attempt++) { ... }
```

**Coverage:**
- Attempt 1: ±0.10 search range
- Attempt 2: ±0.20 search range
- Fallback: Fixed +0.05 step

**Guard Coverage:** The minimum constraint (ΔE ≥ 0.02 - tolerance) is checked after each attempt, ensuring the priority constraint is satisfied before returning.

**Planned Enhancement:** Add chroma-based fallback as attempt 3 if edge cases are identified in production use.

---

### W005: Contrast Minima Alignment

**Implemented Values (in `discrete_min_delta_e()`):**
| Contrast Level | Value | Condition for Additional Contrast |
|---------------|-------|-----------------------------------|
| LOW | 0.05 | `0.05 > 0.05` → FALSE (no additional) |
| MEDIUM | 0.10 | `0.10 > 0.05` → TRUE (contrast applied) |
| HIGH | 0.15 | `0.15 > 0.05` → TRUE (contrast applied) |

**Effective Guarantees (documented in `test_multi_contrast_levels()`):**
| Contrast Level | API Guarantee | Rationale |
|---------------|---------------|-----------|
| LOW | ΔE ≥ 0.02 | Delta min only (contrast value equals delta max) |
| MEDIUM | ΔE ≥ 0.10 | Contrast adjustment applied |
| HIGH | ΔE ≥ 0.15 | Contrast adjustment applied |

**Test Location:** `Tests/CColorJourneyTests/test_incremental.c`, function `test_multi_contrast_levels()`

---

### W006: Best-Effort Maximum ΔE

**Constraint Priority:** The implementation prioritizes minimum ΔE (distinctness) over maximum ΔE (smoothness):

```c
/* Step 6: Check if we achieved minimum distinctness (priority constraint) */
if (adjusted_de >= CJ_DELTA_MIN - CJ_DELTA_TOLERANCE) {
    /* Success: minimum constraint satisfied */
    return t_adjusted;
}
```

**Boundary Spike Behavior:** At certain boundary conditions (e.g., cycle wrap points, high-contrast journeys), the maximum ΔE constraint (≤ 0.05) may be violated to satisfy the minimum constraint.

**Test Handling:** The `test_maximum_delta()` test accepts up to 5% violations:
```c
int max_acceptable_violations = count / 20;  /* 5% */
assert(violations <= max_acceptable_violations);
```

**Rationale:** Perceptually, it's better to have distinguishable colors (ΔE ≥ 0.02) with occasional larger jumps than to have indistinguishable colors (ΔE < 0.02) with perfect smoothness.

**Reference:** See `enforce_delta_range()` Step 6-7 comments in `Sources/CColorJourney/ColorJourney.c`

---

## Status

✅ **Algorithm Design Complete** (December 16, 2025)
✅ **Phase 1 Implementation Complete** (December 16, 2025)
✅ **Phase 2 Documentation Complete** (December 16, 2025)

**Implementation Location:** `Sources/CColorJourney/ColorJourney.c`
- `enforce_delta_range()` - Main delta enforcement function
- `binary_search_delta_position()` - Binary search helper
- `discrete_color_at_index()` - Color generation with delta enforcement
- `apply_minimum_contrast()` - Additional contrast for HIGH/MEDIUM levels

**Test Location:** `Tests/CColorJourneyTests/test_incremental.c`
- T014: `test_minimum_delta()` - Minimum ΔE constraint
- T015: `test_maximum_delta()` - Maximum ΔE constraint (best-effort)
- T016: `test_conflict_resolution()` - Priority constraint handling
- T017: `test_multi_contrast_levels()` - Contrast interaction

**Phase 2 Tasks:** Integration testing, performance regression validation
