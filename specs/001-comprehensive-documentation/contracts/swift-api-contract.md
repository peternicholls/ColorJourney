# Swift API Contract

**Version**: 1.0.0  
**Date**: 2025-12-07  
**Status**: Formal Specification

This document defines the stable contract for the Swift wrapper API in ColorJourney.

---

## Type Definitions & Semantics

### ColorJourney (Main Type)

```swift
public struct ColorJourney {
    public init(config: Config)
    public func sample(at t: Float) -> RGB
    public func discrete(count: Int) -> [RGB]
}
```

**Contract**:

- **Initialization**: 
  - Parameter: `config` – Valid configuration with ≥1 anchor
  - Behavior: Creates journey from configuration
  - Error handling: FatalError if config invalid (invalid configs caught at compile-time via type system)
  - Memory: ~500 bytes per instance
  
- **sample(at:)**:
  - Parameter: `t` – Float in [0, 1]; behavior outside range depends on loop mode
  - Returns: RGB color in valid range
  - Performance: < 1 microsecond
  - Allocations: Zero (returns stack-allocated struct)
  - Determinism: Same instance, same t → identical output
  
- **discrete(count:)**:
  - Parameter: `count` – Number of colors (≥ 1)
  - Returns: Array of RGB colors with minimum perceptual contrast enforced
  - Performance: < 1 millisecond for 100 colors
  - Allocations: Returns [RGB] array (Swift-managed)
  - Determinism: Same instance, same count → identical array

---

### Config (Nested Type)

```swift
public struct ColorJourney {
    public struct Config {
        public var anchors: [RGB]
        public var lightnessBias: Float = 0
        public var chromaBias: Float = 0
        public var contrastBias: Float = 0
        public var temperatureBias: Float = 0
        public var vibrancyBias: Float = 0
        public var loopMode: LoopMode = .open
        public var variation: Variation? = nil
        
        public init(
            anchors: [RGB],
            lightnessBias: Float = 0,
            chromaBias: Float = 0,
            contrastBias: Float = 0,
            temperatureBias: Float = 0,
            vibrancyBias: Float = 0,
            loopMode: LoopMode = .open,
            variation: Variation? = nil
        )
    }
}
```

**Field Contracts**:

- **anchors**: Array of sRGB colors
  - Type: `[RGB]` (Array of RGB structs)
  - Semantics: At least 1 color required; defines journey path
  - Validation: Performed at Config creation (invalid anchors cause initialization failure)
  - Conversion: sRGB converted to OKLab internally

- **lightnessBias**: Perceived brightness adjustment
  - Type: `Float`
  - Valid range: [-100, +100] (clamped)
  - Default: 0 (no adjustment)
  - Semantics: Negative = darker; positive = lighter
  - Perceptual effect: Shifts all colors in lightness uniformly

- **chromaBias**: Color saturation adjustment
  - Type: `Float`
  - Valid range: [-100, +100]
  - Default: 0 (preserve saturation)
  - Semantics: Negative = muted; positive = vivid
  - Perceptual effect: Colors range from grayscale to highly saturated

- **contrastBias**: Perceptual contrast
  - Type: `Float`
  - Valid range: [-100, +100]
  - Default: 0 (auto)
  - Semantics: Positive = stronger separation between colors
  - Perceptual effect: Affects discrete palette distribution and sample spacing

- **temperatureBias**: Color temperature shift
  - Type: `Float`
  - Valid range: [-100, +100]
  - Default: 0 (neutral)
  - Semantics: Negative = cooler/bluer; positive = warmer/redder
  - Perceptual effect: Shifts hue dimension toward cool or warm

- **vibrancyBias**: Overall vitality
  - Type: `Float`
  - Valid range: [-100, +100]
  - Default: 0 (balanced)
  - Semantics: Negative = muted; positive = vivid
  - Perceptual effect: Combined saturation and contrast enhancement

- **loopMode**: Journey boundary behavior
  - Type: `LoopMode` (enum)
  - Default: `.open`
  - Semantics: See LoopMode contract below

- **variation**: Optional deterministic variation
  - Type: `Variation?` (optional struct)
  - Default: `nil` (no variation)
  - Semantics: Adds seeded micro-adjustments for organic aesthetics

---

### RGB (Color Type)

```swift
public struct RGB {
    public var red: Float      // [0.0, 1.0]
    public var green: Float    // [0.0, 1.0]
    public var blue: Float     // [0.0, 1.0]
    
    public init(red: Float, green: Float, blue: Float)
}
```

**Contract**:
- **Valid range**: Each channel [0.0, 1.0]
- **Semantics**: Standard sRGB color
- **Storage**: 12 bytes (3 × 4-byte floats)
- **Display**: For display, convert to 8-bit per channel: (value * 255).rounded()
- **Out-of-range**: Internally clamped to valid range before output

---

### LoopMode (Enum)

```swift
public enum LoopMode {
    case open          // Journey stops at boundaries
    case closed        // Seamless loop back to start
    case pingPong      // Bounce between start and end
}
```

**Case Contracts**:

- **.open**:
  - Sampling t > 1.0 returns last color (clamped)
  - Sampling t < 0.0 returns first color (clamped)
  - Use case: Linear palettes with defined endpoints
  - Example: Grayscale (white to black, doesn't loop)

- **.closed**:
  - Sampling wraps: t ∈ [0, 1] maps normally; t > 1 wraps back to [0, 1)
  - Loop back maintains perceptual continuity
  - Use case: Hue wheels, cyclic schemes
  - Example: Rainbow that returns to red at the end

- **.pingPong**:
  - t ∈ [0, 1] forward through anchors
  - t ∈ (1, 2] backward through anchors
  - t > 2 wraps at period 2.0
  - Use case: Symmetric palettes
  - Example: Diverging colormap (cool → neutral → warm → cool)

---

### Variation (Optional Struct)

```swift
public struct Variation {
    public var seed: UInt32
    public var perChannel: Bool = false
    public var magnitude: Float = 0.5
    
    public init(seed: UInt32, perChannel: Bool = false, magnitude: Float = 0.5)
}
```

**Field Contracts**:

- **seed**: PRNG seed for reproducibility
  - Type: `UInt32`
  - Semantics: Same seed → same variation (deterministic)
  - Default: None (required parameter)

- **perChannel**: Per-channel vs. global variation
  - Type: `Bool`
  - Default: `false`
  - true: Each RGB channel varied independently
  - false: All channels varied together (affects brightness less)

- **magnitude**: Strength of variation
  - Type: `Float` [0.0, 1.0]
  - Default: 0.5
  - 0.0: No variation
  - 1.0: Maximum (~5% color shift)

---

## API Behavior & Guarantees

### Type Safety

- **Compile-time validation**: Config invalid anchors are caught by type system
- **No force-unwrapping needed**: All public APIs return valid values or are non-optional
- **Discoverability**: IDE autocomplete shows all available parameters with descriptions

### Error Handling

- **No thrown errors**: All error conditions are prevented by type system
- **Safe defaults**: All parameters have sensible defaults
- **Graceful limits**: If constraints conflict (e.g., too many colors with enforced contrast), returned count may be less than requested

### Memory & Allocations

- **Value types**: ColorJourney and Config are `struct` (stack or copy, no heap for structure itself)
- **sample()**: Zero allocations; returns stack-allocated RGB
- **discrete()**: Returns Swift Array (heap-allocated, Swift-managed lifetime)
- **Cleanup**: No explicit destroy needed; Swift ARC handles lifetime

### Determinism

- **Exact reproducibility**: Same Config → same colors every time
- **Cross-platform**: Identical output on iOS, macOS, Linux (via Foundation compatibility)
- **Seeded variation**: When enabled, variation is deterministic based on seed

### Thread-Safety

- **Not thread-safe**: Each thread should have its own ColorJourney instance
- **Config sharing**: Config structs can be shared between threads (no mutable state)
- **Concurrent use**: No locking; users responsible for synchronization if needed

---

## Backward Compatibility & Versioning

**Version Contract**:
- Current API version: 1.0.0
- MAJOR version bump: Breaking changes to types or function signatures
- MINOR version bump: New parameters (with defaults), new types, new cases
- PATCH version bump: Bug fixes, performance improvements (no API changes)

**Struct Evolution**:
- New fields may be added with default values (backward compatible)
- Existing field positions and types must not change within MAJOR version
- New initializer overloads may be added (convenience, doesn't break existing code)

**Enum Evolution**:
- New cases may be added (minor version bump)
- Existing cases must not be removed or renamed within MAJOR version
- Users should include `@unknown default` in switch statements to handle future cases

---

## Performance Guarantees

| Operation | Target | Constraint |
|-----------|--------|-----------|
| `ColorJourney(config:)` | < 1 ms | Initialization acceptable |
| `sample(at:)` | < 1 μs | Per-call; stack-only |
| `discrete(count:100)` | < 1 ms | Full palette generation |
| Memory per instance | ~500 bytes | Minimal footprint |
| Samples per second | > 10,000 | Continuous sampling |

---

## Comparison with C API

| Aspect | C API | Swift API |
|--------|-------|----------|
| Configuration | CJ_Config struct | ColorJourney.Config struct with builder |
| Creation | cj_journey_create() | ColorJourney(config:) init |
| Sampling | cj_sample(journey, t) | journey.sample(at: t) |
| Discrete | cj_discrete(journey, count, out) | journey.discrete(count: count) |
| Cleanup | cj_journey_destroy(journey) | Automatic (Swift ARC) |
| Memory safety | Manual responsibility | Type-safe, automatic |
| Thread-safety | User responsible | Not thread-safe; document assumption |
| Determinism | Bit-for-bit identical | Identical (bit-compatible with C core) |

---

**Contract Version**: 1.0.0 | **Effective**: 2025-12-07
