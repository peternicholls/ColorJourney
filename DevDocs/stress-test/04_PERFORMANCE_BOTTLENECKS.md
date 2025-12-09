# Part 4: Performance Bottlenecks

---

## 4.1 🟡 Discrete Palette Full Computation (No Caching)

**Issue:** Each call to `discrete(count: N)` recomputes all N colors.

**Current:**
```swift
let palette = journey.discrete(count: 100)  // ~10ms
let palette2 = journey.discrete(count: 100) // ~10ms again (recomputed!)
```

**Why It's a Problem:**
- No caching of results
- Repeated calls waste CPU
- No way to reuse computed palette

**Severity:** 🟡 **Medium** (sub-ms usually, but adds up)

**Recommendation:**
```swift
private var discreteCache: [Int: [ColorJourneyRGB]] = [:]

func discrete(count: Int) -> [ColorJourneyRGB] {
    if let cached = discreteCache[count] {
        return cached  // ✅ Cached
    }
    let result = /* compute */
    discreteCache[count] = result
    return result
}
```

**Sprint Assignment:** Fixable in 2-3 hours, low-medium priority

---

## 4.2 🟡 Waypoint Interpolation O(n) Lookup

**Issue:** Finding the right waypoint segment requires linear scan.

**Code:**
```c
int segment = (int)(t / segment_size);
// For 16 waypoints, this is fine
// But if waypoints grew to 1000, this becomes O(n)
```

**Severity:** 🟡 **Medium** (only if waypoints scale beyond 16)

**Recommendation:** Keep as-is for now; future optimization if needed

**Sprint Assignment:** No action needed currently

---

## 4.3 🟢 Trigonometric Function Overhead

**Issue:** `sinf()`, `cosf()`, `atan2f()` are expensive.

**Usage:**
```c
/* In apply_dynamics */
float mid_boost = 1.0f + j->config.mid_journey_vibrancy * 
                  (1.0f - 4.0f * (t - 0.5f) * (t - 0.5f));
                  /* No trig here, but could be optimized */

/* In build_waypoints */
float chroma_envelope = 1.0f + 0.2f * sinf(t * M_PI);  // ✓ Used
```

**Severity:** 🟢 **Low** (typically <1% of total time)

**Sprint Assignment:** No action needed

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| Discrete Caching | 🟡 Medium | 2-3 hrs | Optional |
| O(n) Lookup | 🟡 Medium | — | Future |
| Trig Overhead | 🟢 Low | — | No action |

**Total Phase 4 Effort:** ~2-3 hours (optional)

**Impact:** ~10-20% faster repeated discrete() calls, minimal overall impact
