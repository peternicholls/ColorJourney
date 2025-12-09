# Incremental Swatch Implementation Plan

This document translates the draft "Incremental Color Swatch Generation Specification" into executable work items. It focuses on delivering the hybrid index-based + lazy access APIs, cache-backed implementation, and matching Swift conveniences while keeping backward compatibility.

## Goals
- Provide incremental discrete swatch access in C and Swift per the specification.
- Preserve existing `discrete(count:)` behavior while adding cache-backed index and range helpers.
- Keep cache lifecycle well-defined and thread-safety expectations documented.

## Atomic Task List
1. **Expose C headers for incremental access**: Declare `cj_journey_discrete_at` and `cj_journey_discrete_range` with spec-aligned comments in `Sources/CColorJourney/include/ColorJourney.h`.
2. **Implement cache-backed C helpers**: Add implementations in `Sources/CColorJourney/ColorJourney.c`, including cache growth, reuse, and cleanup in journey destroy paths.
3. **Align discrete position logic**: Implement the fixed-spacing `discrete_position` helper (or equivalent) that matches the spec’s `CJ_DISCRETE_DEFAULT_SPACING` guidance and integrates with existing color generation/contrast enforcement.
4. **Add C test coverage**: Extend `Tests/CColorJourneyTests` with cases for single index retrieval, range retrieval, cache reuse (no recomputation), and parity with `cj_journey_discrete` for equivalent ranges.
5. **Extend Swift API surface**: Introduce `discrete(at:)`, `discrete(range:)`, subscript access, and a lazy `discreteColors` sequence in the ColorJourney wrapper, invoking the new C functions.
6. **Swift-side validation**: Add Swift tests in `Tests/ColorJourneyTests` covering incremental access patterns, subscript usage, lazy sequence behavior, and consistency with `discrete(count:)`.
7. **Documentation and examples**: Update user-facing docs/examples to demonstrate incremental swatch usage alongside existing batch APIs.
8. **Thread-safety note**: Document that journey instances are not thread-safe across threads without external synchronization due to caching.

## Dependencies and Risks
- Cache growth must avoid reordering previously cached colors; geometric growth plus fill-forward iteration helps ensure stability.
- Contrast enforcement should mirror batch generation to avoid visible regressions between access patterns.
- Swift bridging must maintain memory safety when pulling ranges from the C API (buffer sizing and lifetime management).

