# ColourJourney C Core Simple Caching Spec

**Status:** DRAFT (Forward Planning)  
**Feature ID:** 005-performance-caching (pending)  
**Created:** December 16, 2025  
**Decision Point:** Post-GATE-2 (Phase 2 complete in feature 004)  

---

## Overview

This is a forward-planning specification for an optional performance optimization layer in the C core. It is **NOT** part of feature 004 (Incremental Color Swatch Generation).

**Decision:** This spec will be evaluated after feature 004 Phase 2 performance benchmarking (GATE-2). If performance results warrant it, feature 005 will be created with this spec as the starting point.

---

## Goals

- Speed up common colour conversion hot paths (especially sRGB8 → linear and sRGB8 → Oklab)
- Keep the C core lightweight, deterministic, and policy-free
- Make caching opt-in and caller-owned so wrappers (Swift/Python/etc.) control lifetime, threading, and memory

## Non-goals

- No disk or persistent caching
- No dynamic allocation in hot paths
- No "smart" eviction policies (LRU/MRU) inside the core by default
- No alpha support (RGB only)

---

## Core Principles

1. **Correctness first:** Caching must never change numerical results versus the uncached implementation
2. **Determinism preserved:** Same inputs must yield the same outputs (within existing tolerance)
3. **No hidden global policy:** Conversions should be pure by default; caching is optional and explicit
4. **Wrapper-friendly:** Cache objects can be created per generator, per palette, per thread, etc.

---

## Caching Components

### A. sRGB8 → Linear LUT (Always-on)

**Purpose:**
Avoid repeated powf() / transfer-function evaluation for 8-bit sRGB decode.

**Behaviour:**
- A 256-entry LUT: `float cj_srgb8_to_linear_lut[256]`
- Must be initialised once before use

**API:**

```c
typedef enum {
    CJ_OK = 0,
    CJ_ERR_NOT_INITIALISED = 1
} CJ_Status;

/* Must be safe to call multiple times. */
CJ_Status cj_init(void);

/* Optional: expose whether init has occurred. */
int cj_is_initialised(void);

/* Accessor (inline ok): */
float cj_srgb8_to_linear(uint8_t v);
```

**Requirements:**
- `cj_init()` is idempotent
- After init, LUT is read-only
- Thread-safety: Either require user to call `cj_init()` single-threaded early, OR implement thread-safe one-time init (compile-time selectable)
  - Default: "call once at startup" to keep core minimal

---

### B. Memo Cache: RGB888 → Oklab (Optional, caller-owned)

**Purpose:**
Speed repeated conversions of the same RGB values (anchors, reused swatches, clamp/loop iterations).

**Cache Strategy:**
- Fixed-size direct-mapped table (power-of-two length)
- Key: packed 24-bit RGB `0x00RRGGBB` stored as uint32_t
- Collision behaviour: overwrite on miss (no chaining)

**Public Types:**

```c
typedef struct { float L, a, b; } CJ_Oklab;

typedef struct {
    uint32_t key;   /* 0x00RRGGBB */
    CJ_Oklab val;
    uint8_t  valid;
    uint8_t  _pad[3]; /* alignment */
} CJ_OklabCacheEntry;

typedef struct {
    CJ_OklabCacheEntry *entries;
    uint32_t capacity;   /* power of two */
    uint32_t mask;       /* capacity - 1 */
    uint32_t seed;       /* optional mixing seed; 0 allowed */
    /* Optional stats (can be compiled out): */
    uint64_t hits;
    uint64_t misses;
} CJ_OklabCache;
```

**Construction / Lifetime:**

**Mode 1: Caller supplies memory (preferred):**

```c
/* Initialise cache using caller-allocated entries[] buffer. */
CJ_Status cj_oklab_cache_init(CJ_OklabCache *cache,
                             CJ_OklabCacheEntry *entries,
                             uint32_t capacity_power_of_two,
                             uint32_t seed);

/* Clears entries; does not free memory. */
void cj_oklab_cache_clear(CJ_OklabCache *cache);
```

**Mode 2: Core allocates memory (optional, compile-time):**
- Only if you explicitly want it; default OFF to keep core minimal
- If enabled, provide `cj_oklab_cache_create()` / `cj_oklab_cache_destroy()`

**Cached Conversion API:**

```c
/* Pure conversion: no caching. */
CJ_Oklab cj_srgb8_to_oklab(uint8_t r, uint8_t g, uint8_t b);

/* Cached conversion: uses cache if non-NULL, otherwise behaves like pure conversion. */
CJ_Oklab cj_srgb8_to_oklab_cached(uint8_t r, uint8_t g, uint8_t b,
                                  CJ_OklabCache *cache);
```

**Hash / Indexing:**
- Pack key: `key = (r<<16) | (g<<8) | b`
- Index: `idx = mix(key, seed) & mask`
- Mix function should be:
  - Fast (integer ops only)
  - Deterministic
  - Stable across platforms
  - Example: multiplicative mix `key * 2654435761u` plus optional xor with seed

**Threading Rules:**
- Cache object is not internally locked
- Safe usage patterns:
  - One cache per thread, OR
  - Caller protects cache with a lock, OR
  - Accept benign races (possible extra recompute, but results remain correct)
- LUT is safe post-init

---

## Configuration

Provide compile-time switches in a single config header (e.g., `cj_config.h`):

```c
#define CJ_ENABLE_CACHE_STATS 0
#define CJ_ENABLE_CORE_ALLOCATORS 0
#define CJ_THREADSAFE_INIT 0
```

- Stats default OFF
- Core allocators default OFF
- Thread-safe init default OFF (startup init recommended)

---

## Determinism Contract

- Cache must not change results; it only short-circuits computation
- When stats are enabled, stats must not affect functional output
- No random behaviour; if a seed exists it only changes mapping of keys to slots, not output values

---

## Performance Targets

- **LUT:** Remove transfer-function cost in the hot path
- **Cache hit path:** A few integer ops + one array lookup + struct return
- **Cache miss path:** Exactly one underlying conversion + one entry write

---

## Testing Requirements

1. **Equivalence tests:** For many random RGB inputs, verify:
   - `cj_srgb8_to_oklab_cached(..., NULL) == cj_srgb8_to_oklab(...)`
   - Cached results equal uncached results for both hit and miss cases

2. **Collision tests:** Force collisions (small capacity), ensure correctness unchanged

3. **Init tests:** Calling `cj_init()` multiple times is safe

4. **Thread-safety guidance tests (optional):** Document expected behaviour with shared cache

---

## Documentation Requirements

- Explain that:
  - LUT is always on (after init)
  - Memo cache is opt-in and caller-owned
  - Cache is not thread-safe by default
  - Provide recommended wrapper patterns:
    - Swift: keep a `CJ_OklabCache` per palette generator instance or per thread
    - Python: one per worker / per process

---

## Suggested Default Sizes

- **LUT:** Fixed 256 entries
- **Oklab cache:**
  - Default capacity: 1024 entries (≈ tens of KB)
  - Allow caller to choose 256–8192 depending on workload

---

## Related Features

- **Feature 004 (Incremental Color Swatch Generation):** Phase 2 includes performance benchmarking (T-002-A/B/C). If caching is deemed beneficial, feature 005 will be created post-GATE-2.

---

## Next Steps

1. Complete feature 004 Phase 1–2 (implement SC-008/009/010, benchmark performance)
2. Review Phase 2 performance report at GATE-2
3. If caching optimization is warranted:
   - Spin up feature 005 with this spec as foundation
   - Establish FR-010, FR-011 (LUT, memo cache)
   - Create SC-013, SC-014 (caching success criteria)
   - Plan implementation tasks
4. If not warranted: Archive spec and revisit in future sprint

---

**Status:** Forward Planning (Decision: Post-GATE-2)  
**Approval:** Pending Phase 2 performance evaluation  
**Owner:** TBD (assigned when feature 005 is created)
