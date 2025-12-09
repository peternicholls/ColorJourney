# Part 1: Architectural Weaknesses

---

## 1.1 🔴 RGB Value Validation Gap

**Issue:** RGB values are NOT validated or clamped at input time.

**Evidence:**
```swift
// Test shows this is allowed:
let color = ColorJourneyRGB(red: 1.5, green: -0.1, blue: 0.5)
// Creates invalid color; stored as-is
```

**Why It's a Problem:**
- Invalid RGB values (>1.0 or <0.0) propagate through the system
- `fast_cbrt()` and OKLab conversions expect [0,1] range
- Results in undefined behavior or incorrect color math
- Users might not realize they've created invalid colors

**Where It Happens:**
```swift
public struct ColorJourneyRGB: Hashable {
    public var red: Float
    public var green: Float
    public var blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red        // ❌ No validation
        self.green = green    // ❌ No validation
        self.blue = blue      // ❌ No validation
    }
}
```

**Severity:** 🟠 **High** (silent failures possible)

**Recommendation:**
```swift
public init(red: Float, green: Float, blue: Float) {
    self.red = max(0, min(1, red))      // ✅ Clamp at init
    self.green = max(0, min(1, green))
    self.blue = max(0, min(1, blue))
}
```

**Sprint Assignment:** Fixable in 1-2 hours, high priority

---

## 1.2 🟠 Hard-Coded Waypoint Limit (8 anchors)

**Issue:** System supports max 8 anchors due to fixed array size.

**Evidence:**
```c
/* In CJ_Config */
CJ_RGB anchors[8];              // 🔴 Fixed size
int anchor_count;

/* In implementation */
if (anchor_count > 8) {
    // ❌ Silently truncates or ignores
}
```

**Why It's a Problem:**
- A palette with 9+ colors can't be represented
- No error message; fails silently with truncation
- Users don't know their journey is incomplete
- Multi-anchor complexity increases with more points

**Impact:**
```swift
// This will silently fail:
let colors = [
    red, orange, yellow, green, cyan, blue, purple, magenta,
    pink  // ❌ 9th color silently ignored
]
let journey = ColorJourney(config: .multiAnchor(colors))
```

**Severity:** 🟠 **High** (silent failure)

**Root Cause:** C pre-allocation decision (anchors[8])

**Recommendation:**
```c
/* Option 1: Increase to 16 anchors */
CJ_RGB anchors[16];

/* Option 2: Dynamic allocation */
typedef struct {
    CJ_RGB* anchors;        // malloc'd
    int anchor_count;
    int anchor_capacity;
} CJ_Config;
```

**Sprint Assignment:** Fixable in 2-4 hours, high priority

---

## 1.3 🟠 Memory Leak Risk in Swift Wrapper

**Issue:** `discrete_cache` in C core may not be freed properly if bridge is interrupted.

**Evidence:**
```c
typedef struct CJ_Journey_Impl {
    CJ_RGB* discrete_cache;      // ❌ malloc'd
    int discrete_count;
} CJ_Journey_Impl;

void cj_journey_destroy(CJ_Journey journey) {
    if (!journey) return;
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    free(j->discrete_cache);     // ✅ Manual free
    free(j);
}
```

**Why It's a Problem:**
- If Swift's `deinit` fails (unlikely but possible), memory leaks
- No reference counting or leak protection
- Long-lived journeys accumulate if deinit misses

**Severity:** 🟡 **Medium** (unlikely in practice)

**Recommendation:**
```swift
deinit {
    if let handle = handle {
        // Add try-catch wrapper
        do {
            cj_journey_destroy(handle)
        } catch {
            // Log error
            print("Warning: journey cleanup failed")
        }
    }
}
```

**Sprint Assignment:** Fixable in 1 hour, medium priority

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| RGB Validation | 🟠 High | 1-2 hrs | 1st |
| Anchor Limit | 🟠 High | 2-4 hrs | 1st |
| Memory Leak | 🟡 Medium | 1 hr | 2nd |

**Total Phase 1 Effort:** ~4-7 hours (1 day)

**Impact:** Eliminates silent failures, improves validation, reduces robustness risk
