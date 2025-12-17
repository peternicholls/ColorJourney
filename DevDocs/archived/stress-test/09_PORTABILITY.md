# Part 9: Portability Issues

---

## 9.1 🟢 Platform-Specific Float Behavior

**Issue:** Different platforms have slightly different float rounding.

**Impact:** Very subtle (sub-ULP), visible only in extreme comparisons.

**Example:**
```c
// IEEE 754 guarantees same results within ULP
// But rounding direction can differ:
// Intel (rounds to nearest):  0.333...
// ARM (can use different mode): 0.333...001
```

**Verdict:** Practically negligible for color calculations

**Severity:** 🟢 **Low** (determinism still maintained)

**Sprint Assignment:** No action needed

---

## 9.2 🟡 Fast Cube Root Only Tested on Intel/ARM

**Issue:** Bit manipulation in `fast_cbrt()` assumes specific float layout.

```c
union { float f; uint32_t i; } u;
u.f = x;
u.i = u.i / 3 + 0x2a514067;  // ❌ Assumes IEEE 754 little-endian
```

**Works on:** x86-64, ARM, MIPS (all IEEE 754)  
**Might break on:** Exotic architectures (rare, but possible)

**Severity:** 🟡 **Medium** (unlikely in practice)

**Recommendation:** Add compile-time check:

```c
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    // Use fast_cbrt with bit manipulation
#else
    // Fallback to cbrtf()
#endif
```

**Sprint Assignment:** Fixable in 1-2 hours, low priority

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| Float Rounding | 🟢 Low | — | No action |
| Cbrt Portability | 🟡 Medium | 1-2 hrs | Optional |

**Total Phase 9 Effort:** ~1-2 hours (optional)

**Impact:** Guaranteed portability to non-IEEE 754 systems (unlikely needed)
