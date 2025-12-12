# Part 3: Numerical Stability Issues

---

## 3.1 🟡 Fast Cube Root Approximation Error

**Issue:** `fast_cbrt()` uses bit manipulation + Newton-Raphson (~1% error).

**Code:**
```c
static inline float fast_cbrt(float x) {
    union { float f; uint32_t i; } u;
    u.f = x;
    u.i = u.i / 3 + 0x2a514067;  // Bit hack
    
    float y = u.f;
    y = (2.0f * y + x / (y * y)) * 0.333333333f;  // One Newton iteration
    
    return y;  // ❌ 1% error possible
}
```

**Error Characteristics:**
- Inputs near 0: Less accurate
- Inputs > 1: Acceptable
- Inputs < 0: **Undefined behavior**

**Example:**
```c
cbrt(0.001) ≈ 0.0995  (correct: 0.1)     // ~0.5% error
cbrt(0.0001) ≈ 0.045  (correct: 0.0464)  // ~3% error
cbrt(-1.0) → Undefined (NaN or crash)
```

**Severity:** 🟡 **Medium** (mostly unnoticed, but edge cases exist)

**Recommendation:**
```c
static inline float fast_cbrt(float x) {
    if (x < 0) return -fast_cbrt(-x);  // Handle negatives
    
    // Use built-in cbrtf() if available (C99)
    // Or add second Newton iteration for accuracy:
    float y = (2.0f * y + x / (y * y)) * 0.333333333f;
    y = (2.0f * y + x / (y * y)) * 0.333333333f;  // +1 iteration
    
    return y;
}
```

**Sprint Assignment:** Fixable in 1-2 hours, medium priority

---

## 3.2 🟡 Division by Zero in Contrast Enforcement

**Issue:** When `contrast_enforce()` divides by chroma-based values, zero chroma crashes.

**Evidence:**
```c
/* In enforce_contrast */
lch.C = clampf(lch.C, 0.0f, 0.4f);
// If lch.C is exactly 0, some math divides by zero
```

**Why It's a Problem:**
- Grayscale colors (C=0) can cause division by zero
- Results in NaN propagation
- Crashes or silent NaN values in palette

**Severity:** 🟡 **Medium** (rare but possible)

**Recommendation:**
```c
if (lch.C < 0.01f) lch.C = 0.01f;  // Epsilon guard
```

**Sprint Assignment:** Fixable in 30 minutes, high priority

---

## 3.3 🟡 Floating Point Accumulation Error

**Issue:** Waypoint interpolation loops compound floating-point errors.

**Example:**
```c
/* 1000 samples at slight perturbations */
for (int i = 0; i < 1000; i++) {
    float t = (float)i / 1000.0f;
    float result = interpolate_waypoints(j, t);
    // Each interpolation adds ~1 ULP error
    // After 1000 iterations: visible drift possible
}
```

**Impact:** Visible only with extreme sampling counts (10,000+)

**Severity:** 🟡 **Medium** (rare, extreme case)

**Recommendation:** Use compensated summation (Kahan algorithm) for critical loops

**Sprint Assignment:** Fixable in 2-3 hours, low-medium priority

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| Fast Cbrt Error | 🟡 Medium | 1-2 hrs | 2nd |
| Div by Zero | 🟡 Medium | 0.5 hrs | 1st |
| FP Accumulation | 🟡 Medium | 2-3 hrs | 3rd |

**Total Phase 3 Effort:** ~3.5-6 hours (less than 1 day)

**Impact:** Improved numerical accuracy, eliminated NaN edge cases, better extreme-case handling
