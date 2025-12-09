# Data Model & API Contracts: Comprehensive Code Documentation

**Date**: 2025-12-07  
**Feature**: 001-comprehensive-documentation  
**Phase**: 1 – Design & Contracts

This document describes the core entities in ColorJourney and their documentation patterns.

---

## Data Model Overview

This feature does not introduce new data structures. Instead, it establishes documentation standards for existing entities. The key entities are:

### Entity: CJ_Config

**Purpose**: High-level journey configuration using designer-intent parameters.

**Fields** (C struct):
- `anchors[CJ_MAX_ANCHORS]` – Array of anchor colors (sRGB)
  - **Documentation**: "Keypoint colors defining the color path. Minimum 1, maximum CJ_MAX_ANCHORS."
  - **Validation**: Valid sRGB values (0.0 to 1.0 per channel)
  
- `anchor_count` – Number of anchors
  - **Documentation**: "Number of active anchors. Must be >= 1."
  - **Validation**: 1 ≤ anchor_count ≤ CJ_MAX_ANCHORS
  
- `lightness_bias` – Adjusts perceived brightness
  - **Documentation**: "Perceptual lightness adjustment (-100 to +100). Negative makes darker, positive makes brighter."
  - **Validation**: Range [-100, +100]; impacts all colors proportionally
  
- `chroma_bias` – Adjusts color saturation
  - **Documentation**: "Perceptual chroma (saturation) adjustment (-100 to +100). Negative = muted, positive = vivid."
  - **Validation**: Range [-100, +100]; clipped to valid OKLab bounds
  
- `contrast_bias` – Enhances or reduces contrast
  - **Documentation**: "Perceptual contrast adjustment (-100 to +100). Higher values enforce stronger separation between samples."
  - **Validation**: Range [-100, +100]
  
- `temperature_bias` – Shifts colors toward warm/cool
  - **Documentation**: "Color temperature bias (-100 to +100). Negative = cooler (bluer), positive = warmer (redder/yellower)."
  - **Validation**: Range [-100, +100]
  
- `vibrancy_bias` – Affects overall color vitality
  - **Documentation**: "Vibrancy adjustment (-100 to +100). Negative = desaturated, positive = enhanced chroma and contrast."
  - **Validation**: Range [-100, +100]
  
- `loop_mode` – Behavior at boundaries
  - **Documentation**: "How the journey repeats: OPEN (stops at anchors), CLOSED (loops back), PING_PONG (bounces)."
  - **Validation**: One of CJ_LOOP_OPEN, CJ_LOOP_CLOSED, CJ_LOOP_PING_PONG
  
- `variation_config` – Optional variation settings
  - **Documentation**: "Optional deterministic micro-adjustments for organic aesthetics. Disabled by default."
  - **Sub-fields**:
    - `enabled` – Whether variation is applied
    - `seed` – PRNG seed; determines variation reproducibly
    - `per_channel` – Whether variation applies per-channel or globally
    - `magnitude` – Strength of variation (0.0 to 1.0)

**State Transitions**:
- Created by user with desired parameters
- Validated before journey creation
- Passed to `cj_journey_create()` (read-only reference)
- Config does not change after journey initialization

---

### Entity: CJ_Journey

**Purpose**: Opaque handle to a color journey. Encapsulates internal state, sampling logic, and constraints.

**Public Interface** (C):
```c
CJ_Journey* cj_journey_create(const CJ_Config* config);
void cj_journey_destroy(CJ_Journey* journey);
CJ_RGB cj_sample(CJ_Journey* journey, float t);
size_t cj_discrete(CJ_Journey* journey, size_t count, CJ_RGB* out_colors);
```

**Documentation Pattern**:
- `cj_journey_create()` – "Creates a journey from configuration. Journey must be destroyed with cj_journey_destroy()."
  - **Precondition**: config is valid (anchors in range, anchor_count >= 1)
  - **Postcondition**: Journey is initialized; all OKLab math precomputed
  - **Memory**: Allocates ~500 bytes per journey
  
- `cj_sample(journey, t)` – "Samples a single color at parameter t ∈ [0, 1]."
  - **Precondition**: journey is valid; 0 ≤ t ≤ 1
  - **Postcondition**: Returned color is in valid sRGB (0.0 to 1.0 per channel)
  - **Performance**: < 1 microsecond; zero allocations
  - **Determinism**: Same t always returns same color (deterministic)
  
- `cj_discrete(journey, count, out_colors)` – "Generates a discrete palette of count colors."
  - **Precondition**: count >= 1; out_colors array large enough
  - **Postcondition**: out_colors filled with count colors; minimum contrast enforced
  - **Performance**: < 1 millisecond for 100 colors
  
- `cj_journey_destroy(journey)` – "Frees journey resources. Journey pointer invalid after this call."
  - **Precondition**: journey is valid
  - **Postcondition**: All memory freed; pointer dangling

**Lifecycle**:
```
create → sample/discrete (many times) → destroy
         ↑_____________________________↑
                   (no modification)
```

---

### Entity: Color Representations

**CJ_RGB** (sRGB color):
- **Fields**: `float r, g, b` (each 0.0 to 1.0)
- **Documentation**: "sRGB color. Values should be clamped to [0, 1] for display. No alpha channel."
- **Usage**: Input to journey, output from sampling

**CJ_Lab** (OKLab color):
- **Fields**: `float L, a, b` (perceptually uniform)
- **Documentation**: "OKLab color space. Internal representation for all perceptual operations. Not exposed to end users."
- **Usage**: Internal only; referenced in algorithm documentation

**CJ_LCh** (OKLch color):
- **Fields**: `float L, C, h` (lightness, chroma, hue)
- **Documentation**: "OKLch cylindrical color space (derived from OKLab). Useful for understanding perceptual bias effects."
- **Usage**: Documented in advanced guides; not directly used in API

---

### Entity: Loop Modes

**Enum: CJ_LoopMode**

- `CJ_LOOP_OPEN` – "Journey stops at the end anchor. Sampling beyond t=1.0 clamps to last color."
  - **Effect**: t ∈ [0, 1] interpolates anchors; t > 1 returns last color
  
- `CJ_LOOP_CLOSED` – "Journey loops back to start seamlessly. Parameter wraps [0, 1] → [0, 1]."
  - **Effect**: Useful for cyclic color schemes (e.g., hue wheels)
  - **Note**: Loop back must respect perceptual continuity
  
- `CJ_LOOP_PING_PONG` – "Journey bounces between start and end. Parameter t ∈ [0, 2] maps to forward-then-backward."
  - **Effect**: t ∈ [0, 1] forward; t ∈ [1, 2] backward; wraps at boundaries
  - **Use case**: Symmetric palettes

---

### Entity: Perceptual Biases

**ChromaBias** (Swift enum):
```swift
case normal          // Preserve chroma from journey
case muted           // Reduce chroma (more grayscale)
case vivid           // Increase chroma (more saturated)
case veryVivid       // Aggressive chroma boost
```

**Documentation Pattern** for each case:
- "Describes the perceptual effect on color saturation."
- "Does not directly expose Lab values; effect is perceptually meaningful."

**TemperatureBias** (Swift enum):
```swift
case neutral         // Preserve color temperature
case cool            // Shift toward blue (lower color temperature)
case warm            // Shift toward red/yellow (higher color temperature)
case veryWarm        // Aggressive warmth
```

**LightnessBias** (Swift enum):
```swift
case normal          // Preserve lightness
case lighter         // Increase perceived brightness
case darker          // Decrease perceived brightness
```

---

### Entity: Variation Layer

**CJ_VariationConfig** (C struct):
```c
struct {
    bool enabled;              // Disabled by default
    uint32_t seed;             // PRNG seed; same seed = same variation
    bool per_channel;          // Per-channel or global variation
    float magnitude;           // Strength (0.0 to 1.0)
} variation_config;
```

**Documentation**:
- "Optional feature for organic, natural-looking palettes."
- "Variation is deterministic: same seed always produces same variation."
- "Does not affect determinism guarantees; all variation is seeded."
- "Magnitude controls how much colors shift: 0.0 = no variation, 1.0 = maximum."

**Behavior**:
- When disabled: No variation applied (default)
- When enabled: Adds seeded micro-adjustments to each color
- Respects all constraints: contrast, lightness bounds, chroma limits

---

## Documentation Contracts

The documentation must establish clear contracts for:

### 1. API Stability Contract

**C API Contract**:
- Public function signatures are stable (semantic versioning)
- Struct field order and types are stable within MAJOR version
- New fields may be added at struct end (backward compatible)
- Deprecated APIs documented with `@deprecated` tags

**Swift API Contract**:
- Public types and functions are stable within MAJOR version
- New parameters may have defaults (backward compatible)
- Deprecated APIs marked with `@available` attributes

### 2. Behavior Contract

**Determinism Contract**:
- Same config, same parameter t → same output color, always
- Variation is deterministic if seeded (same seed → same variation)
- Output colors are valid sRGB (0.0 to 1.0)

**Perceptual Contract**:
- Biases affect perception, not raw math
- Contrast enforcement guarantees minimum perceptual distance
- All operations use OKLab as canonical space

**Performance Contract**:
- Sampling: < 1 microsecond per call, zero allocations
- Discrete palette: < 1 millisecond for 100 colors
- Memory: ~500 bytes per journey

### 3. Platform Contract

**Portability Contract**:
- C core compiles on any C99 system
- No platform-specific code in core (only standard library + math)
- All platforms produce identical output for same config

**Language Contract**:
- C API is canonical; Swift API is transparent bridge
- Swift API docs explain high-level intent; C docs explain implementation
- No behavior divergence between languages

---

## Documentation Compliance Checklist

- [ ] All public C functions have Doxygen comments (purpose, parameters, return, pre/post)
- [ ] All public C structs have field documentation
- [ ] All public Swift types have DocC comments (with perceptual explanation)
- [ ] All non-trivial algorithms have explanatory block comments
- [ ] All examples in documentation are runnable and verified
- [ ] Terminology is consistent across C and Swift documentation
- [ ] All behavioral contracts are explicitly documented
- [ ] References to Constitution, PRD, papers are included in appropriate sections
- [ ] Test code explains intent, not just assertions
- [ ] Architecture documentation explains two-layer design and rationale

---

**Phase 1: Data Model Complete** ✓
