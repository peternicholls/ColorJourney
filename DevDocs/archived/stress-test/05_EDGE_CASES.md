# Part 5: Edge Case Vulnerabilities

---

## 5.1 🟡 Hue Wrapping Edge Cases

**Issue:** Hue wrapping logic has potential off-by-one errors.

```c
/* Hue range: [0, 2π) */
while (result.h < 0) result.h += 2.0f * M_PI;
while (result.h >= 2.0f * M_PI) result.h -= 2.0f * M_PI;

// What if result.h == exactly 2π?  Wraps to 0 (correct)
// What if result.h == -1e-10?      Wraps to ~6.28 (correct)
// What if result.h == 1e10?         Loops 1.6 million times (❌ slow)
```

**Severity:** 🟡 **Medium** (pathological input creates loops)

**Better:**
```c
result.h = fmodf(result.h, 2.0f * M_PI);
if (result.h < 0) result.h += 2.0f * M_PI;
```

**Sprint Assignment:** Fixable in 30 minutes, high priority

---

## 5.2 🟡 Loop Mode Boundary Conditions

**Issue:** Ping-pong mode has floating-point rounding edge case.

```c
if (j->config.loop_mode == CJ_LOOP_PINGPONG) {
    t = fmodf(t, 2.0f);
    if (t < 0) t += 2.0f;
    if (t > 1.0f) t = 2.0f - t;  // ❌ What if t == exactly 1.0?
}
```

**Edge Case:** If `t == 1.0` from floating-point rounding:
```c
if (t > 1.0f) → false (doesn't reverse)
// Result: asymmetry in ping-pong cycle
```

**Severity:** 🟡 **Medium** (rare, visually subtle)

**Fix:**
```c
if (t >= 1.0f) t = 2.0f - t;  // Use >= instead of >
```

**Sprint Assignment:** Fixable in 30 minutes, medium priority

---

## 5.3 🟡 Zero-Count Discrete Palette

**Issue:** `discrete(count: 0)` behavior undefined.

**Current:**
```swift
public func discrete(count: Int) -> [ColorJourneyRGB] {
    guard let handle = handle, count > 0 else {
        return []  // ✓ Returns empty array
    }
    // ...
}
```

**Status:** Okay in practice, but no explicit error message.

**Recommendation:** Add validation:
```swift
guard count > 0 else {
    throw ColorJourneyError.invalidColorCount(count)
}
```

**Sprint Assignment:** Fixable in 15 minutes, low priority

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| Hue Wrapping | 🟡 Medium | 0.5 hrs | 1st |
| Loop Boundary | 🟡 Medium | 0.5 hrs | 2nd |
| Zero Count | 🟡 Medium | 0.25 hrs | 3rd |

**Total Phase 5 Effort:** ~1.25 hours

**Impact:** Eliminates pathological slow cases, fixes boundary asymmetry, improves validation
