# 004 Incremental Creation - Technical Plan

**Feature:** Incremental Color Swatch Generation  
**Status:** Implemented  
**Implementation Date:** December 9, 2025  

---

## Tech Stack

- **Primary Language:** C99
- **Wrapper Language:** Swift 5.9+
- **Build System:** CMake 3.16+ (C), Swift Package Manager (Swift)
- **Testing:** C unit tests, Swift XCTest
- **Documentation:** Doxygen (C), Swift-DocC (Swift)

---

## Architecture

### C Core Layer

**Files:**
- `Sources/CColorJourney/ColorJourney.c` - Implementation
- `Sources/CColorJourney/include/ColorJourney.h` - Public API

**Components:**
1. **Position Calculator** - Maps index to journey position
2. **Contrast Enforcer** - Ensures minimum ΔE between adjacent colors
3. **Color Generator** - Produces RGB colors at specific positions
4. **Range Processor** - Batch generation with contrast chain

### Swift Wrapper Layer

**Files:**
- `Sources/ColorJourney/Journey/ColorJourneyClass.swift`

**Components:**
1. **Index Access** - `discrete(at:)` method
2. **Range Access** - `discrete(range:)` method
3. **Subscript** - `journey[index]` convenience
4. **Lazy Sequence** - `discreteColors` property

---

## Data Flow

```
User Request (index N)
    ↓
Swift API (discrete(at:) or subscript)
    ↓
C API (cj_journey_discrete_at)
    ↓
Compute positions [0...N-1] for contrast chain
    ↓
Generate color at index N with contrast enforcement
    ↓
Return RGB color
```

---

## Key Design Decisions

### Decision 1: O(n) Index Access Complexity

**Choice:** Accept O(n) complexity for index access  
**Rationale:**
- Maintains determinism (no state)
- Ensures perfect consistency
- Typical use case is sequential access (amortized O(1))
- Range API available for batch operations
- Simplicity over micro-optimization

**Trade-off:** Random access to high indices is slower, but:
- Documented clearly in API
- Acceptable for practical indices (< 1000)
- Can be mitigated with application-level caching

### Decision 2: Fixed Spacing (0.05)

**Choice:** Use constant `CJ_DISCRETE_DEFAULT_SPACING = 0.05f`  
**Rationale:**
- Produces ~20 colors per full journey cycle
- Balances color variation with perceptual distinctness
- Simple to understand and predict
- Matches existing batch API behavior

**Alternative Considered:** Configurable spacing  
**Rejected Because:** Adds complexity without clear user benefit

### Decision 3: Stateless Design

**Choice:** No persistent cache in C core  
**Rationale:**
- Simpler implementation
- Thread-safe by default
- Predictable behavior
- Easier to reason about

**Trade-off:** Performance cost for random access  
**Mitigation:** Range API + lazy sequence provide efficient patterns

### Decision 4: Hybrid API Approach

**Choice:** Provide both index and range access  
**Rationale:**
- Index access: Simple mental model, perfect for single colors
- Range access: Efficient for batch operations
- Covers all use cases without forcing complexity on users

---

## Performance Profile

### Benchmarks (Typical Hardware)

| Operation | Complexity | Typical Time |
|-----------|------------|--------------|
| `discrete_at(10)` | O(10) | < 1ms |
| `discrete_at(100)` | O(100) | < 5ms |
| `discrete_range(0, 100)` | O(100) | < 5ms |
| `discreteColors.prefix(100)` | O(100) | < 5ms |

### Memory Usage

- Stack per call: ~24 bytes
- No heap allocations
- Lazy sequence buffer: 1.2 KB (100 colors × 12 bytes)

---

## Testing Strategy

### C Core Tests

**File:** `Tests/CColorJourneyTests/test_c_core.c`

1. **test_discrete_contrast()** - Verifies ΔE ≥ minimum between adjacent colors
2. **test_discrete_index_and_range_access()** - Verifies determinism and consistency
3. **test_discrete_range_contrast()** - Verifies contrast in range context

### Swift Tests

**File:** `Tests/ColorJourneyTests/ColorJourneyTests.swift`

1. **testDiscreteIndexAccess()** - Index vs range consistency
2. **testDiscreteRangeMatchesIndividualCalls()** - Range vs individual consistency
3. **testDiscreteSubscriptAndSequence()** - Subscript and lazy sequence validation

---

## Implementation Files

### Core Implementation
- [Sources/CColorJourney/ColorJourney.c](../../Sources/CColorJourney/ColorJourney.c#L621-L721)
  - Lines 621-665: Helper functions
  - Lines 678-696: Index access implementation
  - Lines 699-721: Range access implementation

### Public API
- [Sources/CColorJourney/include/ColorJourney.h](../../Sources/CColorJourney/include/ColorJourney.h#L460-L490)
  - Function declarations
  - API documentation

### Swift Wrapper
- [Sources/ColorJourney/Journey/ColorJourneyClass.swift](../../Sources/ColorJourney/Journey/ColorJourneyClass.swift#L138-L215)
  - Lines 138-150: Index access
  - Lines 158-178: Range access
  - Lines 182-185: Subscript
  - Lines 189-215: Lazy sequence

---

## Dependencies

### C Core
- **Required:** C99 standard library (`math.h`, `string.h`)
- **External:** None

### Swift Wrapper
- **Required:** Foundation framework
- **External:** None

---

## Deployment Strategy

### Integration Points

1. **C Static Library** - libCColorJourney.a
2. **Swift Package** - ColorJourney module
3. **CocoaPods** - ColorJourney pod

### Backward Compatibility

- All existing APIs unchanged ✅
- New APIs are additive only ✅
- No version bump required (minor feature addition)

---

## Build & Test Commands

### C Core
```bash
# Build library
make lib

# Run C tests
make test-c
```

### Swift
```bash
# Build
swift build

# Test
swift test

# Test specific suite
swift test --filter ColorJourneyTests
```

---

## Documentation Structure

### Generated Documentation

1. **C API Docs** - Doxygen HTML (Docs/api/c/)
2. **Swift API Docs** - DocC HTML (Docs/api/swift/)

### Developer Documentation

1. **Specification** - [spec.md](spec.md)
2. **Code Review** - [DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md](../../DevDocs/CODE_REVIEW_INCREMENTAL_SWATCH.md)
3. **Full Design** - [DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md](../../DevDocs/archived/INCREMENTAL_SWATCH_SPECIFICATION.md)

---

## Future Enhancements

### Potential Improvements

1. **Optional Caching** - Add internal cache to avoid O(n) recomputation
   - Trade-off: Memory vs computation
   - Requires cache lifecycle management

2. **Configurable Spacing** - Allow customization of spacing constant
   - Requires API design for configuration

3. **Performance Instrumentation** - Add timing assertions to tests
   - Ensure performance regressions are caught

4. **Extended Examples** - More real-world usage patterns
   - Timeline editor demo
   - Tag system demo
   - Dashboard demo

**Status:** Deferred to future feature requests
