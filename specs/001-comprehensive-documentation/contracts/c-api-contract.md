# C Core API Contract

**Version**: 1.0.0  
**Date**: 2025-12-07  
**Status**: Formal Specification

This document defines the stable contract for the C core API in ColorJourney.

---

## Function Signatures & Semantics

### Journey Creation & Destruction

```c
CJ_Journey* cj_journey_create(const CJ_Config* config);
```

**Contract**:
- **Purpose**: Create a color journey from configuration
- **Parameter**: `config` – Valid configuration with ≥1 anchor color
- **Returns**: Opaque journey handle; NULL on allocation failure
- **Allocation**: ~500 bytes per journey; must be freed with `cj_journey_destroy()`
- **Precondition**: config is not NULL; config.anchor_count >= 1
- **Postcondition**: Journey is initialized; all OKLab calculations precomputed
- **Errors**: Returns NULL if config invalid or memory allocation fails
- **Thread-safety**: Not thread-safe; each thread needs its own journey
- **Determinism**: Same config always produces same internal state

---

```c
void cj_journey_destroy(CJ_Journey* journey);
```

**Contract**:
- **Purpose**: Free journey resources
- **Parameter**: `journey` – Valid journey handle from `cj_journey_create()`
- **Returns**: Void
- **Precondition**: journey is valid or NULL (NULL is safe no-op)
- **Postcondition**: Memory freed; journey pointer becomes invalid
- **Errors**: Undefined behavior if journey is already destroyed or invalid
- **Memory**: Frees ~500 bytes

---

### Color Sampling

```c
CJ_RGB cj_sample(CJ_Journey* journey, float t);
```

**Contract**:
- **Purpose**: Sample a single color from journey at parameter t
- **Parameters**: 
  - `journey` – Valid journey handle
  - `t` – Parameter in [0, 1]; behavior outside range depends on loop mode
- **Returns**: Color in sRGB space (each channel 0.0 to 1.0)
- **Precondition**: journey is valid
- **Postcondition**: Returned color is valid sRGB (per-channel in [0.0, 1.0])
- **Performance**: < 1 microsecond per call
- **Allocations**: Zero (stack-only)
- **Determinism**: Same journey, same t → identical output (bit-for-bit)
- **Loop behavior**:
  - `CJ_LOOP_OPEN`: t > 1 clamps to last color; t < 0 clamps to first
  - `CJ_LOOP_CLOSED`: t wraps [0, 1] → [0, 1] with seamless wrap
  - `CJ_LOOP_PING_PONG`: t ∈ [0, 2] maps forward [0,1] then backward [1,2]; wraps

---

```c
size_t cj_discrete(CJ_Journey* journey, size_t count, CJ_RGB* out_colors);
```

**Contract**:
- **Purpose**: Generate a discrete palette of count colors with contrast enforcement
- **Parameters**:
  - `journey` – Valid journey handle
  - `count` – Number of colors to generate (≥ 1)
  - `out_colors` – Allocated array of CJ_RGB with capacity ≥ count
- **Returns**: Number of colors actually generated (≤ count; may be less if contrast constraints conflict)
- **Precondition**: journey valid; count > 0; out_colors allocated with capacity ≥ count
- **Postcondition**: out_colors[0..returned-1] filled with valid sRGB colors; minimum perceptual contrast enforced between adjacent colors
- **Performance**: < 1 millisecond for count ≤ 100
- **Allocations**: May allocate temporary buffers internally; returned array is pre-allocated by caller
- **Determinism**: Same journey, same count → identical palette (same colors in same order)
- **Contrast**: Minimum ΔE (in OKLab) enforced between adjacent palette colors; returned count may be less than requested if enforcement impossible

---

## Structure Definitions & Field Contracts

### CJ_Config

```c
struct {
    CJ_RGB anchors[CJ_MAX_ANCHORS];    // Array of anchor colors
    size_t anchor_count;                // Number of active anchors
    float lightness_bias;               // Lightness adjustment
    float chroma_bias;                  // Chroma (saturation) adjustment
    float contrast_bias;                // Contrast enhancement
    float temperature_bias;             // Color temperature adjustment
    float vibrancy_bias;                // Overall vibrancy
    CJ_LoopMode loop_mode;              // Boundary behavior
    CJ_VariationConfig variation_config; // Optional variation settings
} CJ_Config;
```

**Field Contracts**:

- **anchors**: Array of sRGB colors defining the journey path
  - Type: `CJ_RGB[CJ_MAX_ANCHORS]` where CJ_MAX_ANCHORS >= 10
  - Valid values: Each field (r, g, b) in [0.0, 1.0]
  - Semantics: Colors define keypoints; journey interpolates between them in OKLab
  - Note: Colors are auto-normalized to OKLab at journey creation

- **anchor_count**: Number of active anchors
  - Type: `size_t`
  - Valid values: 1 ≤ anchor_count ≤ CJ_MAX_ANCHORS
  - Semantics: Anchors[0..anchor_count-1] are used; rest ignored

- **lightness_bias**: Adjusts perceived brightness
  - Type: `float`
  - Valid values: [-100.0, +100.0] (clamped)
  - Semantics: Negative = darker; positive = lighter
  - Implementation: Shifts OKLab L dimension
  - Default: 0.0 (no adjustment)

- **chroma_bias**: Adjusts color saturation
  - Type: `float`
  - Valid values: [-100.0, +100.0] (clamped)
  - Semantics: Negative = muted (grayer); positive = vivid (more saturated)
  - Implementation: Scales OKLab a, b dimensions toward center (0,0)
  - Default: 0.0 (preserve original chroma)

- **contrast_bias**: Enhances or reduces perceptual contrast
  - Type: `float`
  - Valid values: [-100.0, +100.0]
  - Semantics: Positive = stronger separation; negative = softer transitions
  - Implementation: Affects discrete palette generation and interpolation slope
  - Default: 0.0 (auto-contrast based on anchors)

- **temperature_bias**: Shifts color toward warm or cool
  - Type: `float`
  - Valid values: [-100.0, +100.0] (clamped)
  - Semantics: Negative = cooler (bluer); positive = warmer (redder/yellower)
  - Implementation: Adjusts OKLab hue dimension
  - Default: 0.0 (neutral)

- **vibrancy_bias**: Overall color vitality adjustment
  - Type: `float`
  - Valid values: [-100.0, +100.0]
  - Semantics: Negative = desaturated; positive = enhanced chroma and saturation
  - Implementation: Combines chroma and contrast adjustments
  - Default: 0.0 (balanced)

- **loop_mode**: Defines journey boundary behavior
  - Type: `CJ_LoopMode` (enum)
  - Valid values: `CJ_LOOP_OPEN`, `CJ_LOOP_CLOSED`, `CJ_LOOP_PING_PONG`
  - Semantics: See loop mode contract below
  - Default: `CJ_LOOP_OPEN`

- **variation_config**: Optional deterministic variation
  - Type: `CJ_VariationConfig` (nested struct)
  - Semantics: Adds seeded micro-adjustments to colors (disabled by default)
  - See variation contract below

---

### CJ_RGB

```c
struct {
    float r, g, b;  // Red, Green, Blue channels
} CJ_RGB;
```

**Contract**:
- **Valid range**: Each channel [0.0, 1.0] (representing 0-255 in 8-bit context)
- **Out-of-range handling**: May occur internally during computation; clamped before output
- **Semantics**: Standard sRGB color; used for all input/output
- **Storage**: 12 bytes (3 × 4-byte floats)

---

### CJ_LoopMode

```c
enum {
    CJ_LOOP_OPEN = 0,       // Journey stops at boundaries
    CJ_LOOP_CLOSED = 1,     // Seamless loop back to start
    CJ_LOOP_PING_PONG = 2   // Bounce between start and end
} CJ_LoopMode;
```

**Contract**:

- **CJ_LOOP_OPEN**: 
  - Sampling with t > 1.0 returns last anchor color (clamped)
  - Sampling with t < 0.0 returns first anchor color (clamped)
  - Use case: Linear palettes with defined endpoints

- **CJ_LOOP_CLOSED**:
  - Sampling wraps: t ∈ [0, 1] maps normally; t > 1 wraps back to [0, 1)
  - Loop back respects perceptual continuity (last color connects smoothly to first)
  - Use case: Hue wheels, cyclic color schemes

- **CJ_LOOP_PING_PONG**:
  - t ∈ [0, 1] maps forward through anchors
  - t ∈ (1, 2] maps backward through anchors
  - t > 2 wraps at period 2.0
  - Use case: Symmetric palettes (e.g., for heatmaps with center)

---

### CJ_VariationConfig

```c
struct {
    bool enabled;           // Enable/disable variation
    uint32_t seed;          // PRNG seed for reproducibility
    bool per_channel;       // Per-channel vs global variation
    float magnitude;        // Strength [0.0, 1.0]
} CJ_VariationConfig;
```

**Contract**:

- **enabled**: Whether variation is applied
  - Default: false (no variation)
  - When false: Other fields ignored

- **seed**: PRNG seed for deterministic variation
  - Type: `uint32_t`
  - Semantics: Same seed → same variation (deterministic)
  - Default: 0 (or any seed if enabled)

- **per_channel**: Whether variation is per-channel or global
  - true: Each RGB channel varied independently
  - false: All channels varied by same amount (affects brightness less)
  - Default: false

- **magnitude**: Strength of variation
  - Type: `float` [0.0, 1.0]
  - 0.0: No variation
  - 1.0: Maximum variation (~5% color shift)
  - Default: 0.5 (moderate)

---

## Backward Compatibility & Versioning

**Version Contract**: 
- Current API version: 1.0.0
- Breaking changes (major version bump): May remove or reorder public APIs
- Non-breaking additions (minor version bump): New fields in structs, new functions, expanded enums
- Bug fixes (patch version bump): No API changes

**Struct Evolution**:
- New fields may be added at struct end (backward compatible)
- Existing field positions and types must not change within MAJOR version
- Struct size may increase with new MINOR versions
- sizeof() checks should use dynamic offsets, not hard-coded values

**Function Stability**:
- Stable public functions will not be removed or renamed within MAJOR version
- New overloads/variants may be added (new functions, not signature changes)
- Behavior must remain consistent; bugs should be fixed in patch versions

---

## Performance Guarantees

| Operation | Target | Constraint |
|-----------|--------|-----------|
| `cj_journey_create()` | < 1 ms | Precomputation is acceptable |
| `cj_sample(journey, t)` | < 1 μs | Per-call; zero allocations |
| `cj_discrete(journey, 100)` | < 1 ms | Full palette generation |
| Memory per journey | ~500 bytes | Minimal allocation |
| Samples per second | > 10,000 | For continuous sampling |

---

## Determinism Guarantees

1. **Exact bit-for-bit reproducibility**: Same config, same t → identical output on all platforms (C99-compatible)
2. **Seeded variation**: When enabled, variation is deterministic based on seed
3. **Platform independence**: Output is identical across macOS, Linux, Windows, WebAssembly
4. **Compiler independence**: Output is independent of C compiler (within C99 standard floating-point rules)

---

**Contract Version**: 1.0.0 | **Effective**: 2025-12-07
