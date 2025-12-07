# Part 2: API & Design Limitations

---

## 2.1 🟡 No Error Handling for Invalid Configurations

**Issue:** Invalid configs silently degrade to defaults.

**Examples:**
```swift
// This doesn't fail; it just silently defaults:
var config = ColorJourneyConfig(anchors: [])  // Empty anchors
let journey = ColorJourney(config: config)

// Or:
let config = ColorJourneyConfig(
    anchors: [color],
    midJourneyVibrancy: -1.5  // Invalid; should be [0,1]
)
```

**Why It's a Problem:**
- No validation error messages
- Users don't know their config is wrong
- Debugging becomes harder
- Silent failures are worse than loud ones

**Severity:** 🟡 **Medium**

**Recommendation:**
```swift
public init(anchors: [ColorJourneyRGB]) throws {
    guard !anchors.isEmpty else {
        throw ColorJourneyError.noAnchorsProvided
    }
    guard anchors.count <= 8 else {
        throw ColorJourneyError.tooManyAnchors(anchors.count)
    }
    self.anchors = anchors
}
```

**Sprint Assignment:** Fixable in 2-3 hours, high priority

---

## 2.2 🟡 No Direct Index-Based Sampling

**Issue:** Must use `discrete()` + index, can't sample directly by index.

**Current:**
```swift
let palette = journey.discrete(count: 10)  // Allocates array
let color = palette[3]                     // Then index
```

**Better:**
```swift
let color = journey.color(at: 3, totalCount: 10)  // Direct
```

**Why It's a Problem:**
- Forces full palette generation even for single color
- Wastes memory for large palettes (just need one color)
- Doesn't match user mental model (index-based access)

**Severity:** 🟡 **Medium** (workaround exists)

**Recommendation:** Add convenience method:
```swift
func sampleDiscrete(at index: Int, totalCount: Int) -> ColorJourneyRGB {
    guard totalCount > 0 else { return sample(at: 0) }
    let t = Float(index) / Float(totalCount - 1)
    return sample(at: t)
}
```

**Sprint Assignment:** Fixable in 1-2 hours, low-medium priority

---

## 2.3 🟡 Variation Seed Synchronization

**Issue:** Variation seed is per-journey, not per-platform-global.

**Problem:**
```swift
// On iOS:
let journey1 = ColorJourney(config: config)  // Uses default seed
let palette1 = journey1.discrete(count: 10)

// On Python (hypothetically):
journey2 = ColorJourney(config)  # Same seed
palette2 = journey2.discrete(10)  # Different results!
```

**Why:** Default seed is hardcoded in C core:
```c
config->variation_seed = 0x123456789ABCDEF0ULL;  // Fixed
```

**Why It's a Problem:**
- Same config doesn't guarantee same output across platforms if seed drifts
- Variation is supposed to be deterministic but seeding is unclear
- No way to get "fresh" randomness vs. "locked" randomness

**Severity:** 🟡 **Medium** (affects reproducibility)

**Recommendation:** Add seed generation option:
```swift
enum VariationSeed {
    case deterministic(UInt64)   // Fixed seed
    case default                  // 0x123456789ABCDEF0
    case random                   // New seed each time
}
```

**Sprint Assignment:** Fixable in 2-3 hours, medium priority

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| Error Handling | 🟡 Medium | 2-3 hrs | 2nd |
| Index Sampling | 🟡 Medium | 1-2 hrs | 3rd |
| Seed Sync | 🟡 Medium | 2-3 hrs | 2nd |

**Total Phase 2 Effort:** ~5-8 hours (1-1.5 days)

**Impact:** Better error messages, improved API ergonomics, clearer semantics
