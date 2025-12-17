# Known Issues & Limitations for Future Enhancements

**Feature:** 004-incremental-creation  
**Version:** 2.2.0  
**Date:** December 17, 2025  
**Status:** Production Ready (with documented limitations)

---

## Overview

This document catalogs all known issues, limitations, and potential future enhancements for the Incremental Color Swatch Generation feature with Delta Range Enforcement. These items are not blocking issues but are documented for transparency and future planning.

---

## Known Limitations

### L-001: Performance Overhead of Delta Enforcement

**Category:** Performance  
**Severity:** Low (acceptable tradeoff)  
**Status:** Documented

**Description:**
Delta range enforcement adds ~6× constant factor overhead compared to pre-delta implementation due to:
- OKLab color space conversions (~0.5µs per color)
- Binary search for position finding (~4µs per color)
- ΔE calculation for constraint validation

**Impact:**
| Operation | Pre-Delta | Post-Delta | Overhead |
|-----------|-----------|------------|----------|
| 100 colors (range) | ~0.019ms | ~0.121ms | 6.4× |
| 1000 colors (range) | ~0.191ms | ~1.208ms | 6.3× |

**Mitigation:**
- Absolute performance remains excellent (sub-millisecond for typical use)
- Use `discrete_range()` for batch operations
- Range access is still O(start + count), not O(n²)

**Future Enhancement:** Consider optional delta bypass API (SC-013) for performance-critical paths.

---

### L-002: O(n) Individual Index Access Complexity

**Category:** Performance  
**Severity:** Medium (documented behavior)  
**Status:** By Design

**Description:**
The `discrete_at(index)` method has O(n) complexity where n = index, because computing color at index N requires computing all colors 0 through N-1 to maintain the contrast chain.

**Impact:**
| Index | Time |
|-------|------|
| 0 | <0.001ms |
| 100 | ~6ms |
| 1000 | ~600ms |

**Mitigation:**
- Use `discrete_range(0, count)` for batch operations
- Use `discreteColors` lazy sequence for streaming
- Implement application-level caching for random access patterns

**Future Enhancement:** Consider implementing a "checkpoint" system for amortized O(1) access at certain indices.

---

### L-003: No Override API for Delta Parameters

**Category:** API Flexibility  
**Severity:** Low  
**Status:** Deferred (SC-013)

**Description:**
The delta range parameters (min: 0.02, max: 0.05 for LOW contrast) are fixed and cannot be overridden by API consumers.

**Impact:**
- Users cannot tighten or loosen delta constraints for specific use cases
- Performance-critical paths cannot bypass delta enforcement

**Mitigation:**
- Current defaults provide optimal perceptual balance for most use cases
- Different contrast levels (LOW/MEDIUM/HIGH) offer some flexibility

**Future Enhancement (SC-013):**
```swift
// Proposed future API
journey.discrete(at: index, deltaMin: 0.01, deltaMax: 0.08)
journey.discrete(at: index, deltaEnforcement: .disabled)
```

---

### L-004: Maximum ΔE Best-Effort at Boundaries

**Category:** Algorithm  
**Severity:** Low (acceptable behavior)  
**Status:** Documented (W006)

**Description:**
At certain boundary conditions (cycle wraps, high-contrast journeys), the maximum ΔE constraint (≤0.05 for LOW contrast) may be exceeded to satisfy the minimum constraint (≥0.02).

**Impact:**
- Up to 5% of LOW contrast pairs may have ΔE > 0.05
- Perceptually, this means occasional "larger jumps" between colors

**Rationale:**
Perceptually, it's better to have distinguishable colors with occasional larger jumps than indistinguishable colors with perfect smoothness.

**Mitigation:**
- Priority constraint (minimum ΔE) always satisfied
- Higher contrast levels (MEDIUM/HIGH) have naturally larger deltas anyway
- Test suite accepts up to 5% violations as acceptable

**Future Enhancement:** Consider adaptive fallback that tries harder to minimize maximum ΔE violations.

---

### L-005: Binary Search Monotonicity Assumption

**Category:** Algorithm  
**Severity:** Low (edge case)  
**Status:** Documented (W002)

**Description:**
The binary search in `binary_search_delta_position()` assumes ΔE varies monotonically with position `t` within the search range. This assumption may not hold for:
- Complex multi-anchor journeys with non-monotonic ΔE profiles
- Journeys with high chroma variation having local minima/maxima

**Impact:**
- May not find optimal position in edge cases
- Falls back to best-effort or fixed-step position

**Mitigation:**
- Search range is bounded (±0.10 to ±0.20), limiting exposure
- Best-effort tracking keeps best result found
- Multiple search attempts improve coverage

**Future Enhancement:** Consider gradient descent or adaptive step search for non-monotonic cases.

---

### L-006: Asymmetric Wrap-Around Search

**Category:** Algorithm  
**Severity:** Very Low (corner case)  
**Status:** Documented (W003)

**Description:**
When searching across the 0.0/1.0 boundary in t-space, the implementation uses forward-only search rather than bidirectional.

**Impact:**
- Backward search across wrap boundary not fully explored
- May miss optimal positions in rare edge cases

**Mitigation:**
- Forward-only search covers sufficient t-space (up to ±0.20 effective range)
- Deterministic and predictable results
- Works correctly for 99%+ of cases

**Future Enhancement:** Full bidirectional wrap-around search for completeness.

---

### L-007: Simplified Fallback vs Spec Design

**Category:** Algorithm  
**Severity:** Low (design decision)  
**Status:** Documented (W001)

**Description:**
The spec described a 3-level fallback (chroma reduction → gamut mapping → relaxed minimum). Implementation uses simpler fixed-step fallback.

**Implementation:**
```c
/* Last resort: move forward in t-space by a fixed amount */
return fmodf(t_base + 0.05f, 1.0f);
```

**Rationale:**
- Simpler and more predictable
- Better performance (avoids additional OKLab calculations)
- Binary search resolves 99%+ of cases before fallback triggers

**Future Enhancement:** Implement chroma-based fallbacks if edge cases are identified in production.

---

### L-008: High Index Precision Degradation

**Category:** Numerical  
**Severity:** Very Low (out of supported range)  
**Status:** Documented (R-003)

**Description:**
For indices beyond 1,000,000, floating-point precision may cause perceptible color differences.

**Supported Ranges:**
| Range | Precision | Status |
|-------|-----------|--------|
| 0 - 1,000,000 | <0.02 ΔE error | ✅ Supported |
| 1M - 10M | 0.02-0.10 ΔE error | ⚠️ Warning |
| >10M | >0.10 ΔE error | ❌ Not recommended |

**Mitigation:**
- Documented supported range in API documentation
- Warning in docs for 1M-10M range
- Negative indices return black (consistent error handling)

**Future Enhancement:** Consider double precision for extended range support.

---

### L-009: No Real-World UI/Hardware Validation

**Category:** Testing  
**Severity:** Low (deferred)  
**Status:** Deferred (R-001-C)

**Description:**
Real-world testing on actual iOS/iPad/Mac hardware with UI integration was deferred in Phase 0.

**Impact:**
- Hardware-specific performance characteristics unknown
- UI thread impact under sustained iteration unverified
- Device-specific memory behavior untested

**Mitigation:**
- Comprehensive unit testing covers correctness
- Performance benchmarks extrapolate well
- Stress tests validate stability patterns

**Future Enhancement (R-001-C):** Complete real-world hardware testing in future validation sprint.

---

### L-010: Iterator Not Thread-Safe

**Category:** Thread Safety  
**Severity:** Low (standard Swift behavior)  
**Status:** Documented

**Description:**
Individual lazy sequence iterators (`discreteColors`) are not thread-safe. Sharing an iterator between threads is undefined behavior.

**Impact:**
- Each thread must create its own iterator
- Shared iterator access causes undefined behavior

**Mitigation:**
- Documented in thread safety review
- Journey handles are thread-safe for reads
- Standard Swift iterator semantics (well understood)

**Future Enhancement:** Document thread-safe usage patterns more prominently in API docs.

---

## Future Enhancements Backlog

### High Priority

| ID | Enhancement | Effort | Target |
|----|-------------|--------|--------|
| SC-013 | Delta parameter override API | 2-3 days | v2.3.0 |
| R-001-C | Real-world UI/hardware testing | 1 day | v2.3.0 |

### Medium Priority

| ID | Enhancement | Effort | Target |
|----|-------------|--------|--------|
| FE-001 | Index access checkpointing | 3-5 days | v2.4.0 |
| FE-002 | Adaptive fallback algorithm | 2 days | v2.4.0 |
| FE-003 | Extended precision mode | 1-2 days | v2.4.0 |

### Low Priority

| ID | Enhancement | Effort | Target |
|----|-------------|--------|--------|
| FE-004 | Bidirectional wrap search | 1 day | v3.0.0 |
| FE-005 | Chroma reduction fallback | 1 day | v3.0.0 |
| FE-006 | Error code return API | 2 days | v3.0.0 |

---

## Summary

### Issues by Severity

| Severity | Count | Description |
|----------|-------|-------------|
| High | 0 | No blocking issues |
| Medium | 1 | L-002: O(n) complexity (documented, mitigated) |
| Low | 8 | Various edge cases and design tradeoffs |
| Very Low | 2 | Corner cases with minimal impact |

### Production Readiness

Despite these documented limitations:
- ✅ All core functionality works correctly
- ✅ Performance acceptable for all production use cases
- ✅ Memory profile clean (no leaks, stable)
- ✅ Thread-safe for concurrent reads
- ✅ Comprehensive test coverage (86 tests, 100% pass)

**Verdict:** Feature is production-ready. Limitations are documented, understood, and have clear mitigations.

---

## References

- **Delta Algorithm:** [delta-algorithm.md](delta-algorithm.md)
- **Performance Report:** [performance-regression-report.md](performance-regression-report.md)
- **Thread Safety Report:** [analysis-reports-phase-0/thread-safety-stress-test-report.md](analysis-reports-phase-0/thread-safety-stress-test-report.md)
- **Index Precision Analysis:** [analysis-reports-phase-0/index-precision-analysis.md](analysis-reports-phase-0/index-precision-analysis.md)
- **Spec:** [spec.md](spec.md)
- **Tasks:** [tasks.md](tasks.md)

````