# Part 10: Future Extensibility Constraints

---

## 10.1 🟠 Adding New Enums Requires ABI Break

**Issue:** Adding enum variants breaks binary compatibility.

**Current:**
```c
typedef enum {
    CJ_LIGHTNESS_NEUTRAL = 0,
    CJ_LIGHTNESS_LIGHTER,
    CJ_LIGHTNESS_DARKER,
    CJ_LIGHTNESS_CUSTOM
} CJ_LightnessBias;
```

**Problem:** Adding a 5th option requires recompilation of all clients.

**Severity:** 🟠 **High** (blocks forward compatibility)

**Recommendation:** Use versioned config or separate feature flags:

```c
/* Option 1: Version the config */
typedef struct {
    int version;  // 1, 2, 3, ...
    union {
        CJ_Config_v1 v1;
        CJ_Config_v2 v2;
    } data;
} CJ_Config_Versioned;

/* Option 2: Use feature flags */
typedef struct {
    uint32_t flags;  // Bitmap of enabled features
    float custom_values[8];
} CJ_Config_Flexible;
```

**Sprint Assignment:** Fixable in 4-6 hours, medium priority

---

## 10.2 🟢 Language Wrapper Burden

**Issue:** Each new language needs its own complete wrapper (100+ lines).

**Current State:**
- ✓ C (core, 484 lines)
- ✓ Swift (wrapper, 600 lines)
- ❌ Python (planned, ~200 lines needed)
- ❌ Rust (planned, ~300 lines needed)
- ❌ JavaScript (planned, ~250 lines needed)

**Severity:** 🟢 **Low** (manageable, just effort)

**Recommendation:** Create wrapper template and code generation

**Sprint Assignment:** Fixable in 1-2 hours per language (planned for future)

---

## Summary

| Issue | Severity | Fix Time | Priority |
|-------|----------|----------|----------|
| ABI Breaking | 🟠 High | 4-6 hrs | Medium |
| Wrapper Burden | 🟢 Low | — | Future |

**Total Phase 10 Effort:** ~4-6 hours (optional, future-proofing)

**Impact:** Forward compatibility guaranteed, reduced future maintenance burden
