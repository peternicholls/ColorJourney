# 004 Incremental Creation - Task Breakdown

**Feature ID:** 004-incremental-creation  
**Status:** Core API shipped (SC-001–SC-007 ✅); Research complete (R-001, R-002, R-003 ✅); Implementation pending  
**Core Implementation Date:** December 9, 2025  
**Branch:** `004-incremental-creation`  
**Total Tasks:** 39 (T001-T039)  
**Phases:** 4 (Phase 0: Research ✅, Phase 1: Implementation, Phase 2: Integration, Phase 3: Evaluation)  
**Estimated Total Effort:** 170 hours / 6 weeks

**Task Format:** Each section includes both checklist format (T001-T039) and detailed specifications (original task IDs)  

**References:**
- Spec Success Criteria: See [spec.md § Success Criteria & Task Traceability](spec.md#success-criteria--task-traceability)
- Constitution: All principles maintained (C99 core, OKLab perceptual integrity, deterministic output, comprehensive testing)  

---

## Phase 0: Research & Investigation (6-12 days)

**Phase Goal:** Validate SC-011 (thread safety) and SC-012 (chunk size optimization) through research, measurement, and testing. Output: Recommendations & decision points to feed Phase 1 implementation.

**Gate:** GATE-0 (Research Phase Approval) required before Phase 1 start.

---

### R-001: Lazy Sequence Chunk Size Optimization (SC-012)

**Checklist:**
- [x] T001 [P] Establish C core performance baseline in Tests/CColorJourneyTests/performance_baseline.c
- [x] T002 [P] Benchmark chunk sizes (10, 25, 50, 100, 200, 500) in Tests/ColorJourneyTests/ChunkSizeBenchmarkTests.swift
- [x] T003 Document chunk size decision in specs/004-incremental-creation/chunk-size-decision.md

---

#### R-001-A: Establish C Core Performance Baseline ✅

**Task ID:** T001  
**Requirement:** SC-012 (Lazy sequence chunk size optimized)  
**Objective:** Establish C core color generation performance baseline as reference point for chunk size comparison  
**Effort:** 1 day  
**Status:** **COMPLETE** (December 16, 2025)  
**Deliverables:**
- Baseline performance measurements (1, 10, 50, 100, 500, 1000 colors generated)
- Performance test harness (reproducible benchmarking setup): `Tests/CColorJourneyTests/performance_baseline.c`
- Documentation of measurement methodology
- Baseline report (speeds, memory profile, cache behavior): `baseline-performance-report.md`

**Key Findings:**
- discrete_at: O(n) as expected, ~0.9ms for 100 colors, ~94ms for 1000 colors
- discrete_range: ~50x faster for 100 colors, ~492x faster for 1000 colors
- Range access provides 5-500x speedup depending on count
- Memory: Stack-only (~24 bytes/call), no heap allocations

**Success Criteria:**
- Baseline measurements documented and reproducible
- Test harness works across platforms
- Ready to compare chunk size implementations against baseline

---

#### R-001-B: Test Chunk Sizes (10, 25, 50, 100, 200, 500) ✅

**Task ID:** T002  
**Requirement:** SC-012  
**Objective:** Benchmark lazy sequence chunk buffer with 6 different chunk sizes; compare each to C core baseline to identify optimal tradeoff  
**Effort:** 1.5 days  
**Status:** **COMPLETE** (December 16, 2025)  
**Dependencies:** R-001-A (baseline established)  
**Deliverables:**
- Performance data for each chunk size (generation time, memory overhead, iteration latency)
- Memory profiling results (allocations, peak usage)
- Comparison showing each size vs. baseline: `chunk-size-benchmark-report.md`
- Inflection point analysis (where memory savings plateau)
- Test harness: `Tests/ColorJourneyTests/ChunkSizeBenchmarkTests.swift`

**Key Findings:**
- Chunk 100 at inflection point for 100 colors (most common use)
- Chunk 200 only 2% faster than 100 (within margin of error)
- Memory negligible for all sizes (<6 KB)
- **Recommendation:** Keep current chunk size 100 (optimal balance)

**Success Criteria:**
- All 6 chunk sizes benchmarked
- Data compared to C core baseline
- Inflection points identified
- Recommendation direction clear (chunk 100 optimal for common case)

---

#### R-001-C: Real-World Testing (UI, Memory, Hardware)

**Task ID:** R-001-C  
**Requirement:** SC-012  
**Objective:** Validate chunk size performance with actual Swift UI operations and multiple hardware platforms  
**Effort:** 1 day  
**Dependencies:** R-001-B (initial chunk size recommendations from benchmarking)  
**Deliverables:**
- Real-world app integration performance measurements
- Memory profiling under sustained iteration (iPhone, iPad, Mac)
- Hardware compatibility notes
- Anomaly report (if any)

**Success Criteria:**
- UI responsiveness acceptable on all platforms
- Memory stable across platforms (no leaks)
- No anomalies detected in real-world use

---

#### R-001-D: Chunk Size Decision & Documentation ✅

**Task ID:** T003  
**Requirement:** SC-012  
**Objective:** Synthesize R-001-A/B/C findings; recommend chunk size with rationale; define regression test thresholds  
**Effort:** 0.5 days  
**Status:** **COMPLETE** (December 16, 2025)  
**Dependencies:** R-001-C (deferred), R-001-A/B (complete)  
**Deliverables:**
- Recommended chunk size with rationale: **Keep chunk 100** (optimal balance)
- Rationale document: `chunk-size-decision.md` (tradeoffs, inflection point analysis)
- Regression test thresholds defined (100 colors: <0.075ms, 500 colors: <1.0ms, 1000 colors: <3.5ms)
- Alternative approaches documented (dynamic chunking - deferred)

**Decision:**
- **Chunk size: 100** (no changes required)
- Rationale: At inflection point for common case, good across all use cases, negligible memory (1.17 KB)
- Real-world validation (R-001-C) deferred with validation strategy defined

**Success Criteria:**
- Chunk size chosen (100 - optimal and conservative)
- Rationale documented with tradeoff analysis
- Regression thresholds defined for Phase 2 validation
- Ready for Phase 1 implementation

---

### R-002: Thread Safety Validation (SC-011)

**Checklist:**
- [x] T004 [P] Conduct thread safety code review in specs/004-incremental-creation/thread-safety-review.md
- [x] T005 [P] Implement concurrent read tests in Tests/ColorJourneyTests/ThreadSafetyTests.swift
- [x] T006 Conduct stress testing and document in specs/004-incremental-creation/thread-safety-stress-test-report.md

---

#### R-002-A: Code Review for Thread Safety ✅

**Task ID:** T004  
**Requirement:** SC-011 (Thread safety verified)  
**Objective:** Analyze incremental API codebase for potential race conditions, verify stateless design, document memory model assumptions  
**Effort:** 1 day  
**Status:** **COMPLETE** (December 16, 2025)  
**Deliverables:**
- Code review document: `thread-safety-review.md` (18 KB, comprehensive analysis)
- Identified potential issues: **NONE** - confirmed safe for concurrent reads
- Memory model assumptions documented (C99 stack, Swift value types)
- Recommendations for testing strategy (R-002-B/C)

**Key Findings:**
- **Stateless design:** No shared mutable state in C or Swift
- **Stack-only allocation:** All variables thread-local
- **Read-only journey access:** Journey config immutable after creation
- **No race conditions:** All functions are pure or read-only
- **Thread Safety Guarantee:** Safe for concurrent reads

**Caveats:**
- Journey handle must remain valid during concurrent access (caller responsibility)
- Individual iterators not thread-safe (standard Swift behavior, documented)

**Success Criteria:**
- Stateless design verified (no shared mutable state)
- Contrast chain computation checked for races (stack-based, safe)
- Memory model understood and documented (C99 + Swift)
- Testing strategy recommendations clear (R-002-B concurrent tests, R-002-C stress tests)

---

#### R-002-B: Concurrent Read Testing ✅

**Task ID:** T005  
**Requirement:** SC-011  
**Objective:** Test concurrent access from multiple threads; verify no race conditions with thread sanitizer  
**Effort:** 1.5 days  
**Status:** **COMPLETE** (December 16, 2025)  
**Dependencies:** R-002-A (code review complete; testing strategy defined)  
**Deliverables:**
- Concurrent read test suite: `Tests/ColorJourneyTests/ThreadSafetyTests.swift`
- Test results: All 5 tests PASS (0.013s total execution)
- Race condition check: Clean (compiler warnings addressed, tests pass)
- Concurrent range test results: 1000 reads, 0 mismatches

**Test Coverage:**
- Test 1: Concurrent read same index (10 threads × 100 iterations = 1000 reads) ✓
- Test 2: Concurrent read different indices (10 threads × 100 iterations) ✓
- Test 3: Concurrent range access (10 threads × 100 colors = 1000 colors) ✓
- Test 4: Concurrent lazy sequence iteration (5 threads × 50 colors) ✓
- Test 5: Summary validation ✓

**Results:**
- Total reads: 2000+ concurrent operations
- Mismatches: 0 (100% deterministic)
- Timing: <0.010s (acceptable variance)
- Memory: No leaks detected

**Success Criteria:**
- Concurrent read tests pass (5/5 tests)
- No race conditions detected (0 mismatches)
- Timing variations within acceptable bounds (<10ms)
- Ready for stress testing (R-002-C)

---

#### R-002-C: Stress Testing & Guarantees Documentation ✅

**Task ID:** T006  
**Requirement:** SC-011  
**Objective:** High-concurrency stress tests and thread safety guarantee documentation  
**Effort:** 1 day  
**Status:** **COMPLETE** (December 16, 2025)  
**Dependencies:** R-002-B (concurrent tests passing)  
**Deliverables:**
- Stress test results: `thread-safety-stress-test-report.md` (13.4 KB)
- Test scenarios: 100 threads (100K ops), sustained load (10s), mixed patterns
- Thread safety guarantees documented with code examples
- Developer guidance: safe patterns, unsafe patterns, best practices
- Production readiness: APPROVED for concurrent use

**Test Results:**
- High concurrency: 100 threads × 1000 ops = 100,000 operations, 0 errors ✓
- Sustained iteration: 10 threads × 10 seconds = 21,087 colors, no leaks ✓
- Mixed load: 100 threads, 3 patterns = 28,750 operations, 0 mismatches ✓
- Performance: 117K ops/second with 100 threads, 58% scaling efficiency
- Memory: Stable, no leaks detected

**Success Criteria:**
- Stress tests pass under high concurrency (100 threads, 100K+ operations)
- Thread safety guarantees clearly documented (safe/unsafe patterns with examples)
- Developer guidance helpful and complete (use cases, best practices)
- SC-011 validation complete (code review + concurrent tests + stress tests)

---

### R-003: Index Overflow & Precision Investigation (SC-010, FR-008)

**Checklist:**
- [x] T007 [P] Analyze floating-point precision at high indices in specs/004-incremental-creation/index-precision-analysis.md
- [x] T008 [P] Document codebase overflow patterns (appended to index-precision-analysis.md)
- [x] T009 Select overflow strategy and document supported range (0-1M) in index-precision-analysis.md

---

#### R-003-A: Precision Analysis at High Indices ✅

**Task ID:** T007  
**Requirement:** FR-008 (Index Overflow Strategy), SC-010 (Index bounds tested)  
**Objective:** Test floating-point precision limits; identify precision loss boundaries at high indices  
**Effort:** 1 day  
**Status:** **COMPLETE** (December 16, 2025)  
**Deliverables:**
- Precision test results documented: `index-precision-analysis.md` (17.3 KB)
- Precision loss boundaries identified: 1,000,000 (1M) with <0.02 ΔE error
- Color difference measurements: Imperceptible up to 1M, perceptible beyond 10M
- Determinism validation: IEEE 754 guarantees (same input → same output)

**Key Findings:**
- **Supported range:** 0 to 1,000,000 (precision guaranteed, <0.02 ΔE error)
- **Warning range:** 1M to 10M (error 0.02-0.10 ΔE, use with caution)
- **Unsupported:** Beyond 10M (error >0.10 ΔE, not recommended)
- **Float precision limit:** 16M (2^24) for exact integer representation
- **Recommendation:** Document 0-1M as supported range

**Success Criteria:**
- Precision loss boundary identified (1,000,000 indices)
- Color differences quantified (<0.02 ΔE up to 1M, imperceptible)
- Data reproducible (IEEE 754 standard guarantees)
- Determinism verified (same index → same color always)

---

#### R-003-B: Codebase Overflow Pattern Investigation ✅

**Task ID:** T008  
**Requirement:** FR-008, SC-010  
**Objective:** Survey existing codebase for overflow handling patterns; identify strategy to apply to index bounds  
**Effort:** 0.5 days  
**Status:** **COMPLETE** (December 16, 2025)  
**Deliverables:**
- Overflow handling pattern documented: Uses `int`, checks negatives, no upper bounds
- Examples from existing code: ColorJourney.c:634, 733, 746, 754, 770
- Recommended strategy: Match codebase (document limits, no runtime checks)

**Pattern Identified:**
- **Type:** `int` (signed 32-bit, range: -2.1B to +2.1B)
- **Negative handling:** Explicit checks, return default/black
- **Positive overflow:** Not checked (undefined behavior assumed impossible)
- **Philosophy:** "Trust but verify" - verify negatives, trust reasonable positives
- **Consistency:** Index handling matches broader codebase pattern

**Success Criteria:**
- Overflow patterns in codebase identified (`int`, negative checks only)
- Examples documented (5 code references analyzed)
- Strategy recommendation clear (document 0-1M, match codebase pattern)

---

#### R-003-C: Overflow Strategy Selection & Documentation ✅

**Task ID:** T009  
**Requirement:** FR-008, SC-010  
**Objective:** Select overflow strategy based on R-003-A/B analysis; document supported index range  
**Effort:** 0.5 days  
**Status:** **COMPLETE** (December 16, 2025)  
**Deliverables:**
- Strategy selected: Document supported range (0-1M), no runtime checks
- API documentation written: Doxygen and DocC examples in analysis doc
- Testing plan defined: High index tests (100K-1M) for Phase 1
- Developer guidance provided: Best practices, warnings, use cases

**Selected Strategy:**
- **Supported range:** 0 to 1,000,000 (precision guaranteed)
- **Warning range:** 1M to 10M (reduced precision, use with caution)
- **Unsupported:** Beyond 10M (undefined precision)
- **Error handling:** Negative → black (0,0,0) - current behavior maintained
- **No code changes:** Current implementation sufficient

**Documentation Updates for Phase 1:**
- Add Doxygen comments with range limits (I-003-C)
- Add DocC comments with usage examples (I-003-C)
- Add high index tests (I-003-B)

**Success Criteria:**
- Strategy selected (document 0-1M supported range)
- Documentation written (Doxygen + DocC examples provided)
- Testing plan (high index tests identified for I-003-B)
- Developer guidance (best practices, warnings documented)

---

**Task ID:** R-003-D (continuation)  
**Requirement:** FR-008, SC-010  
**Objective:** Choose overflow strategy matching codebase conventions; define max supported index and precision guarantees  
**Effort:** 0.5 days  
**Dependencies:** R-003-A (precision boundaries known), R-003-B (codebase patterns identified)  
**Deliverables:**
- Chosen overflow strategy (matching codebase pattern; e.g., "modulo wrapping with documented limits")
- Max supported index documented (likely 1,000,000 based on R-003-A findings)
- Behavior beyond max specified (undefined, graceful degradation, or saturation)
- Precision guarantees specified ("Deterministic up to index 1M; precision loss possible beyond 1M")
- Developer guidance (when to use alternatives, batching strategies)

**Success Criteria:**
- Strategy matches codebase conventions
- Max index defined with rationale
- Precision guarantees clear and documented
- Ready for Phase 1 implementation (I-003-B/C)

---

### GATE-0: Research Phase Approval

**Objective:** Review all Phase 0 research findings; approve proceeding to Phase 1 implementation  
**Effort:** 0.5 days  
**Dependencies:** R-001-D, R-002-C, R-003-C (all research complete)  
**Deliverables:**
- Research summary report (findings from R-001, R-002, R-003)
- Recommendations documented (chunk size, thread safety, index bounds strategy)
- Go/No-Go decision recorded

**Success Criteria:**
- All research tasks complete
- SC-011, SC-012 validated (or blocked with remediation plan)
- Stakeholder approval obtained
- Phase 1 implementation authorized

**Gate Decision:** Proceed to Phase 1 implementation if all success criteria met. If blocked, document remediation plan.

---

## Phase 1: Implementation (12-15 days)

**Phase Goal:** Implement SC-008, SC-009, SC-010 based on Phase 0 research findings. Output: Code changes + tests passing.

**Gate:** GATE-1 (Implementation Phase Approval) required before Phase 2 start.

---

### I-001: Delta Range Enforcement (SC-008, FR-007)

**Checklist:**
- [x] T010 Design delta range enforcement algorithm with conflict resolution in specs/004-incremental-creation/delta-algorithm.md
- [ ] T011 Implement `discrete_enforce_delta_range()` helper in Sources/CColorJourney/ColorJourney.c
- [ ] T012 Implement OKLab ΔE calculation in Sources/CColorJourney/ColorJourney.c
- [ ] T013 Integrate delta enforcement into `discrete_color_at_index()` in Sources/CColorJourney/ColorJourney.c
- [ ] T014 [P] Add minimum delta test (ΔE ≥ 0.02) in Tests/CColorJourneyTests/test_incremental.c
- [ ] T015 [P] Add maximum delta test (ΔE ≤ 0.05) in Tests/CColorJourneyTests/test_incremental.c
- [ ] T016 [P] Add conflict resolution test in Tests/CColorJourneyTests/test_incremental.c
- [ ] T017 Add multi-contrast-level delta test in Tests/CColorJourneyTests/test_incremental.c
- [ ] T018 Measure delta enforcement performance overhead vs baseline
- [ ] T019 Code review and refinement of delta range implementation

---

#### I-001-A: Delta Range Enforcement - Algorithm Design

**Task ID:** T010  
**Requirement:** SC-008 (Delta Range Enforcement ΔE: 0.02–0.05), FR-007  
**Objective:** Design Delta Range Enforcement algorithm in detail; define conflict resolution strategy with examples  
**Effort:** 1 day  
**Deliverables:**
- Detailed algorithm pseudocode (7 steps, see spec.md Technical Design)
- Position adjustment strategy (forward/backward search in OKLab space)
- Conflict resolution strategy with examples (prefer min ΔE ≥ 0.02 over max ≤ 0.05)
- OKLab ΔE calculation verification (using C standard library cbrt() for precision)
- Integration plan (how delta enforcement interacts with FR-002 contrast enforcement)

**Success Criteria:**
- Algorithm fully specified with all 7 steps documented
- Conflict cases covered with resolution strategy
- Code-ready pseudocode (ready for I-001-B implementation)
- Examples provided for edge cases

---

#### I-001-B: C Core Implementation

**Task ID:** T011-T013  
**Requirement:** SC-008, FR-007  
**Objective:** Implement Delta Range Enforcement in ColorJourney.c following algorithm from I-001-A  
**Effort:** 2 days  
**Dependencies:** I-001-A (algorithm designed)  
**Deliverables:**
- `discrete_enforce_delta_range()` helper function (position adjustment)
- OKLab ΔE calculation using C standard library
- Position adjustment logic (binary search or linear search forward/backward)
- Integration with `discrete_color_at_index()` (transparent to caller)

**Success Criteria:**
- Code compiles (C99, no warnings)
- Functions callable and deterministic
- Basic tests pass (ΔE within [0.02, 0.05] bounds)
- No performance regression (< 10% overhead vs. C baseline)
- OKLab ΔE calculation uses standard library `cbrt()` per constitution Principle II precision requirement
- Double precision (64-bit) used for all OKLab conversions

---

#### I-001-C: Delta Range Enforcement Testing

**Task ID:** T014-T018  
**Requirement:** SC-008, FR-007  
**Objective:** Comprehensive testing of Delta Range Enforcement algorithm and implementation  
**Effort:** 1.5 days  
**Dependencies:** I-001-B (implementation complete)  
**Deliverables:**
- Minimum delta test (ΔE(i, i-1) ≥ 0.02 for all colors)
- Maximum delta test (ΔE(i, i-1) ≤ 0.05 for all colors)
- Conflict resolution test (when constraint range < 0.03, verify min takes priority)
- Multi-contrast-level test (delta enforcement with MEDIUM, HIGH contrast levels)
- Performance measurements (generation time, memory, comparison to C baseline)

**Success Criteria:**
- All 4 test cases passing
- Edge cases verified (consecutive indices, conflict scenarios)
- No performance regression (< 10% overhead vs. baseline)
- SC-008 validation complete

---

#### I-001-D: Code Review & Refinement

**Task ID:** T019  
**Requirement:** SC-008, FR-007  
**Objective:** Code review, performance optimization, and approval of Delta Range Enforcement implementation  
**Effort:** 1 day  
**Dependencies:** I-001-C (tests passing)  
**Deliverables:**
- Code review feedback addressed
- Performance optimizations applied (if needed)
- Refactored code (for clarity/maintainability)
- Code review approval documented

**Success Criteria:**
- Code review approved
- All tests still passing
- Performance verified (< 10% overhead)
- SC-008 implementation complete, ready for Phase 2

---

### I-002: Error Handling Enhancement (SC-009, FR-006)

**Checklist:**
- [ ] T020 Audit current error handling paths in Sources/CColorJourney/ColorJourney.c
- [ ] T021 Implement enhanced bounds checking in Sources/CColorJourney/ColorJourney.c
- [ ] T022 Implement handle validation improvements in Sources/CColorJourney/ColorJourney.c
- [ ] T023 [P] Add negative indices test in Tests/CColorJourneyTests/test_incremental.c
- [ ] T024 [P] Add NULL/invalid journey test in Tests/CColorJourneyTests/test_incremental.c
- [ ] T025 Verify Swift nil-safety in Tests/ColorJourneyTests/IncrementalTests.swift

---

#### I-002-A: Error Handling Audit

**Task ID:** T020  
**Requirement:** SC-009 (Error handling for invalid inputs), FR-006  
**Objective:** Audit current error handling and identify gaps  
**Effort:** 0.5 days  
**Deliverables:**
- Current error path documentation
- Gap analysis (missing error checks, edge cases)
- Enhancement recommendations

**Success Criteria:**
- All error paths identified
- Gaps documented
- Enhancement list clear

---

#### I-002-B: Error Handling Implementation

**Task ID:** T021-T022  
**Requirement:** SC-009, FR-006  
**Objective:** Implement enhanced error handling for invalid inputs  
**Effort:** 1 day  
**Dependencies:** I-002-A (audit complete)  
**Deliverables:**
- Enhanced error validation logic
- Bounds checking implementation
- Handle validation improvements
- Graceful degradation enhancements

**Success Criteria:**
- Code compiles
- No crashes on invalid input
- Functions callable with errors

---

#### I-002-C: Error Handling Testing

**Task ID:** T023-T025  
**Requirement:** SC-009, FR-006  
**Objective:** Test error handling edge cases and verify graceful degradation  
**Effort:** 1 day  
**Dependencies:** I-002-B (implementation complete)  
**Deliverables:**
- Negative indices test (return black)
- NULL/invalid journey test
- Handle validation test
- Swift nil-safety verification

**Success Criteria:**
- All 3-4 error tests passing
- No crashes observed
- Graceful degradation verified
- SC-009 validation complete

---

### I-003: Index Bounds Validation (SC-010, FR-008)

**Checklist:**
- [ ] T026 [P] Add baseline index tests (0, 1, 10, 100, 1000) in Tests/CColorJourneyTests/test_incremental.c
- [ ] T027 [P] Add high index tests (999,999, 1,000,000) in Tests/CColorJourneyTests/test_incremental.c
- [ ] T028 Add precision validation tests at boundary in Tests/CColorJourneyTests/test_incremental.c
- [ ] T029 Add Doxygen bounds documentation to Sources/CColorJourney/include/ColorJourney.h
- [ ] T030 Add DocC bounds documentation to Sources/ColorJourney/Journey/ColorJourneyClass.swift

---

#### I-003-A: Index Bounds Testing - Baseline

**Task ID:** T026  
**Requirement:** SC-010, FR-008  
**Objective:** Test baseline indices (0, 1, 10, 100, 1000) to establish baseline behavior  
**Effort:** 1 day  
**Deliverables:**
- Baseline index tests passing (indices: 0, 1, 10, 100, 1000)
- Determinism verified for each index
- Precision validated at baseline

**Success Criteria:**
- Tests passing
- Results consistent
- Baseline established

---

#### I-003-B: Index Bounds Testing - High Indices

**Task ID:** T027-T028  
**Requirement:** SC-010, FR-008  
**Objective:** Test high indices (999,999, 1,000,000) and validate precision at bounds  
**Effort:** 1 day  
**Dependencies:** I-003-A (baseline complete), R-003 (precision limits known) ✅  
**Deliverables:**
- High index tests (indices: 100K, 500K, 999,999, 1,000,000)
- Precision validation at boundaries
- Determinism at high indices
- Precision loss detection (if any)

**Success Criteria (from R-003 research):**
- Tests passing at all indices 0-1M
- Precision error <0.02 ΔE (imperceptible, per R-003-A findings)
- Determinism maintained (same index → identical color)
- Float precision validated (IEEE 754 exact representation up to 16M)
- Boundary tests at 999,999 and 1,000,000 confirm supported range

---

#### I-003-C: Bounds Documentation & Warning System

**Task ID:** T029-T030  
**Requirement:** SC-010, FR-008  
**Objective:** Document bounds and precision guarantees based on R-003 research findings  
**Effort:** 0.5 days  
**Dependencies:** I-003-B (testing complete)  
**Deliverables:**
- Doxygen documentation with supported range (0-1M), warning ranges (1M-10M), unsupported (>10M)
- DocC documentation with usage examples and precision guarantees
- Precision guarantee specification: <0.02 ΔE up to 1M indices
- Developer guidance for high-index use cases

**Success Criteria (from R-003-C):**
- Documentation matches R-003 recommendations exactly
- Doxygen includes: supported range, warnings, precision guarantees, examples
- DocC includes: range table, usage examples, warnings for >1M
- Developer guidance clear (use 0-1M, avoid >1M, consider batching/caching for high indices)
- SC-010 validation complete

---

### GATE-1: Implementation Phase Approval  
**Effort:** 0.5 days  
**Dependencies:** I-001-D, I-002-C, I-003-C (all implementation complete)  
**Deliverables:**
- Implementation review summary
- All tests passing (basic validation)
- Code quality assessment
- Go/No-Go decision documented

**Success Criteria:**
- All implementation tasks complete
- Tests passing
- Proceed to Phase 2 authorized

---

## Phase 2: Integration & Testing (5-7 days)

**Checklist:**
- [ ] T031 Consolidate and expand unit tests (25+ cases) in Tests/CColorJourneyTests/test_incremental.c
- [ ] T032 Create integration tests for combined features in Tests/ColorJourneyTests/IntegrationTests.swift
- [ ] T033 Run performance regression tests vs R-001 baseline and document in specs/004-incremental-creation/performance-regression-report.md
- [ ] T034 Run memory profiling and leak detection, document in specs/004-incremental-creation/memory-profile-report.md
- [ ] T035 Final code review and document approval in specs/004-incremental-creation/code-review-final.md

---

### T-001: Comprehensive Test Suite - Unit Tests

**Task ID:** T031 (T-001-A through T-001-E)  
**Objective:** Consolidate and expand unit tests across all Phase 1 implementations  
**Effort:** 1 day  
**Deliverables:**
- **T-001-A**: Determinism tests (10+ cases) - same index returns identical color
- **T-001-B**: Delta range tests integrated (4 tests from I-001-C)
- **T-001-C**: Error handling tests integrated (3-4 tests from I-002-C)
- **T-001-D**: Bounds tests integrated (8+ tests from I-003-A/B)
- **T-001-E**: Integration tests (10+ combined feature tests)
- All tests documented and passing

**Success Criteria:**
- 25+ unit tests total (determinism + consistency + contrast)
- All delta range tests passing (min ΔE ≥ 0.02, max ΔE ≤ 0.05)
- All error tests passing (negative indices, NULL journey, graceful degradation)
- All bounds tests passing (0 to 1M indices with <0.02 ΔE precision)
- Integration tests cover real-world usage patterns
- Test coverage ≥ 95% for new code paths

---

### T-001: Delta Range Tests Integration

**Task ID:** T-001-B  
**Objective:** Integrate delta range tests into main suite  
**Effort:** 0.5 days  
**Deliverables:**
- Delta minimum tests integrated
- Delta maximum tests integrated
- Conflict resolution tests integrated
- Multi-level contrast tests integrated

**Success Criteria:**
- 4 delta tests in suite
- All passing
- Coverage >= 95%

---

### T-001: Error Handling Tests Integration

**Task ID:** T-001-C  
**Objective:** Integrate error handling tests  
**Effort:** 0.5 days  
**Deliverables:**
- Error case tests integrated
- Edge case tests integrated
- Crash prevention tests integrated

**Success Criteria:**
- 3-4 error tests integrated
- All passing
- No crashes

---

### T-001: Bounds Tests Integration

**Task ID:** T-001-D  
**Objective:** Integrate index bounds tests  
**Effort:** 0.5 days  
**Deliverables:**
- Baseline index tests integrated
- High index tests integrated
- Precision tests integrated
- Determinism across bounds verified

**Success Criteria:**
- 8+ bounds tests integrated
- All passing
- Coverage complete

---

### T-001: Integration Tests

**Task ID:** T032 (T-001-E)  
**Objective:** Real-world integration tests  
**Effort:** 1 day  
**Deliverables:**
- Combined feature tests
- Real-world usage patterns
- Performance integration tests
- Cross-feature interaction tests

**Success Criteria:**
- 10+ integration tests
- All passing
- Real-world scenarios covered

---

### T-002: Performance Baseline - C Core

**Task ID:** T033 (T-002-A, T-002-B)  
**Objective:** Performance regression testing against R-001-A baseline  
**Effort:** 1 day  
**Deliverables:**
- Performance regression tests vs R-001-A baseline
- Comparison report showing delta overhead
- Memory profiling vs baseline
- Baseline documentation

**Success Criteria (from R-001-D regression thresholds):**
- 100 colors: ≤0.075ms (baseline 0.050ms ± 0.011ms, +50% max)
- 500 colors: ≤1.000ms (baseline 0.685ms ± 0.017ms, +50% max)
- 1000 colors: ≤3.500ms (baseline 2.453ms ± 0.021ms, +50% max)
- Memory: ≤2.00 KB (baseline 1.17 KB)
- Delta enforcement overhead: <10% vs baseline (per SC-008)

---

### T-002: Regression Testing

**Task ID:** T-002-B  
**Objective:** Compare new implementation against baseline  
**Effort:** 1 day  
**Dependencies:** T-002-A (baseline established)  
**Deliverables:**
- Regression test results
- Performance overhead analysis
- Comparison report
- Approval for < 10% overhead

**Success Criteria:**
- Overhead < 10%
- No anomalies
- Regression tests pass

---

### T-002: Memory Profiling

**Task ID:** T034 (T-002-C)  
**Objective:** Verify memory usage and detect leaks  
**Effort:** 1 day  
**Deliverables:**
- Memory profiling results
- Leak detection (if any)
- Stack allocation verified
- Heap usage documented

**Success Criteria:**
- No memory leaks
- Stack allocations within spec (~24 bytes)
- Heap usage acceptable

---

### Integration Phase Gate

**Task ID:** T035 (GATE-2)  
**Objective:** Review all integration testing and approve Phase 3  
**Effort:** 0.5 days  
**Dependencies:** T-001-E, T-002-C (all testing complete)  
**Deliverables:**
- Test summary report (86 tests)
- Performance report
- Code review final approval
- Go/No-Go decision documented

**Success Criteria:**
- All 86 tests passing
- Performance verified
- Documentation complete
- Proceed to Phase 3 authorized

---

## Phase 3: Evaluation & Decision (1 week)

**Checklist:**
- [ ] T036 Evaluate perceptual quality improvement with user feedback, document in specs/004-incremental-creation/perceptual-quality-evaluation.md
- [ ] T037 Test delta range in real-world application integration, document in specs/004-incremental-creation/integration-test-report.md
- [ ] T038 Verify correctness and stability under real usage, document in specs/004-incremental-creation/stability-verification.md
- [ ] T039 Document rollout recommendation (general/incremental-only/defer) in specs/004-incremental-creation/rollout-decision.md

---

### E-001: Effectiveness Evaluation - Perceptual Quality

**Task ID:** T036 (E-001-A)  
**Objective:** Assess user-perceived quality improvement  
**Effort:** 2 days  
**Deliverables:**
- Qualitative feedback from trial users
- Perceptual quality assessment
- Comparison: with vs. without delta range
- User satisfaction metrics

**Quantitative Success Metrics:**
- User satisfaction score ≥ 7/10 (preference for delta range enforcement)
- Perceived distinctness improvement ≥ 20% vs. no delta enforcement
- No reported issues with "colors too similar" in incremental workflow
- Perceptual quality threshold: 90% of adjacent colors rated as "clearly distinct"

**Success Criteria:**
- User feedback collected
- Quality improvement evident (or documented)
- Feedback patterns identified

---

### E-001: Performance in Real-World Apps

**Task ID:** T037 (E-001-B)  
**Objective:** Test delta range in actual applications  
**Effort:** 1.5 days  
**Dependencies:** GATE-2 (approved for evaluation)  
**Deliverables:**
- Real-world app integration testing
- Performance measurements in context
- Bottleneck analysis (if any)
- Real-world performance report

**Success Criteria:**
- Apps integrate smoothly
- No performance issues detected
- No bottlenecks
- User experience positive

**Quantitative Performance Thresholds:**
- Performance overhead ≤ 15% vs. baseline (acceptable for perceptual improvement)
- Generation time for 100 colors ≤ 2ms (real-time threshold)
- Memory overhead ≤ 10% vs. baseline
- Zero crashes or undefined behavior in 8-hour stress test

---

### E-001: Correctness & Stability Verification

**Task ID:** T038 (E-001-C)  
**Objective:** Final correctness and stability checks  
**Effort:** 1 day  
**Deliverables:**
- All tests still passing
- Edge cases verified in context
- Stability under real usage
- No regression report

**Success Criteria:**
- All tests still passing
- No edge case failures
- Stability verified
- No regressions

---

### E-001: Rollout Decision & Recommendation

**Task ID:** T039 (E-001-D)  
**Objective:** Make decision on delta range general rollout  
**Effort:** 1 day  
**Dependencies:** E-001-A, E-001-B, E-001-C (all evaluation complete)  
**Deliverables:**
- Evaluation summary report
- Effectiveness metrics
- Rollout recommendation memo
- Decision document

**Decision Criteria (Quantitative):**
- **General Rollout** if: User satisfaction ≥7/10 AND performance overhead ≤15% AND zero critical bugs
- **Incremental Only** if: Benefits clear for incremental but concerns for batch API
- **Defer/Iterate** if: User feedback mixed OR performance >15% overhead OR stability issues
- **Document rationale** for chosen path with data supporting decision

**Rollout Options:**
1. **General Rollout** - Enable for all APIs
2. **Incremental Only** - Keep as incremental-specific
3. **Configurable** - Add override API (deferred)
4. **Defer** - More research needed

**Success Criteria:**
- Recommendation clear
- Decision rationale documented
- Next steps defined
- Stakeholder approval obtained

---

### Evaluation Phase Gate

**Task ID:** GATE-3  
**Objective:** Final approval and rollout decision  
**Effort:** 0.5 days  
**Dependencies:** E-001-D (evaluation complete)  
**Deliverables:**
- Final evaluation report
- Rollout decision approved
- Implementation plan (if rollout approved)
- Feature complete

**Success Criteria:**
- Evaluation complete
- Decision made
- Next steps clear
- Feature ready for next phase

---

## Task Summary

### By Phase

| Phase | Task Count | Estimated Days |
|-------|------------|-----------------|
| **Phase 0** | 11 | 6-12 |
| **Phase 1** | 12 | 12-15 |
| **Phase 2** | 8 | 5-7 |
| **Phase 3** | 5 | 7 |
| **Gates** | 4 | 2 |
| **TOTAL** | **32** | **39-43** |

### By Type

| Type | Count |
|------|-------|
| Research | 11 |
| Implementation | 12 |
| Integration | 8 |
| Evaluation | 5 |
| Gates | 4 |
| **TOTAL** | **40** |

---

## Task Dependencies

```
PHASE 0: RESEARCH (Parallel)
├─ R-001-A: C core baseline
│  └─ R-001-B: Test chunk sizes
│     └─ R-001-C: Real-world testing
│        └─ R-001-D: Decision
├─ R-002-A: Thread safety review
│  ├─ R-002-B: Concurrent testing
│  └─ R-002-C: Stress testing
└─ R-003-A: Precision analysis
   ├─ R-003-B: Codebase investigation
   └─ R-003-C: Strategy selection
   └─ GATE-0: Research gate

PHASE 1: IMPLEMENTATION (Mostly Parallel)
├─ I-001-A: Algorithm design
│  ├─ I-001-B: C implementation
│  ├─ I-001-C: Testing
│  └─ I-001-D: Code review
├─ I-002-A: Error audit
│  ├─ I-002-B: Implementation
│  └─ I-002-C: Testing
├─ I-003-A: Bounds baseline
│  ├─ I-003-B: High index testing (depends on R-003)
│  └─ I-003-C: Documentation
└─ GATE-1: Implementation gate

PHASE 2: INTEGRATION (Sequential)
├─ T-001-A: Unit tests
├─ T-001-B: Delta tests integration
├─ T-001-C: Error tests integration
├─ T-001-D: Bounds tests integration
├─ T-001-E: Integration tests
├─ T-002-A: Performance baseline
├─ T-002-B: Regression testing (depends on T-002-A)
├─ T-002-C: Memory profiling
└─ GATE-2: Integration gate

PHASE 3: EVALUATION (Sequential)
├─ E-001-A: Perceptual quality
├─ E-001-B: Real-world apps
├─ E-001-C: Correctness verification
├─ E-001-D: Rollout decision
└─ GATE-3: Final decision gate
```

---

## Execution Timeline

### Week 1-2: Phase 0 (Research)
- Days 1-4: R-001-A, R-001-B parallel with R-002-A, R-003-A
- Days 5-8: R-001-C, R-002-B, R-003-B parallel
- Days 9-10: R-001-D, R-002-C, R-003-C
- Day 11: GATE-0

### Week 3-4: Phase 1 (Implementation)
- Days 1-2: I-001-A, I-002-A, I-003-A parallel
- Days 3-4: I-001-B, I-002-B parallel
- Days 5-6: I-001-C, I-002-C, I-003-B parallel
- Days 7-8: I-001-D, I-003-C
- Day 9: GATE-1

### Week 5: Phase 2 (Integration)
- Day 1: T-001-A
- Days 2-3: T-001-B, T-001-C, T-001-D parallel
- Day 4: T-001-E
- Days 5-7: T-002-A, T-002-B, T-002-C
- Day 8: GATE-2

### Week 6: Phase 3 (Evaluation)
- Days 1-2: E-001-A
- Days 3-4: E-001-B
- Day 5: E-001-C
- Day 6: E-001-D
- Day 7: GATE-3

**Total: 40 days (6 weeks)** for complete feature delivery with evaluation and rollout decision.

---

## Task Summary & Status

| Phase | Checklist Tasks | Detailed Tasks | Status |
|-------|----------------|----------------|--------|
| Phase 0: Research | T001-T009 | R-001-A to R-003-C | ✅ Complete |
| Phase 1: Implementation | T010-T030 | I-001-A to I-003-C | Not Started |
| Phase 2: Integration | T031-T035 | T-001-A to T-002-C, GATE-2 | Not Started |
| Phase 3: Evaluation | T036-T039 | E-001-A to E-001-D | Not Started |
| **Total** | **39 tasks** | **32+ subtasks** | **9 complete** |

---

## Checklist-to-Detailed Task Mapping

| Checklist ID | Detailed Task ID | Description |
|--------------|------------------|-------------|
| T001 | R-001-A | C core performance baseline |
| T002 | R-001-B | Chunk size benchmarking |
| T003 | R-001-D | Chunk size decision |
| T004 | R-002-A | Thread safety code review |
| T005 | R-002-B | Concurrent read testing |
| T006 | R-002-C | Stress testing |
| T007 | R-003-A | Precision analysis |
| T008 | R-003-B | Overflow pattern investigation |
| T009 | R-003-C | Overflow strategy selection |
| T010 | I-001-A | Delta algorithm design |
| T011-T013 | I-001-B | Delta C implementation |
| T014-T018 | I-001-C | Delta testing |
| T019 | I-001-D | Delta code review |
| T020 | I-002-A | Error handling audit |
| T021-T022 | I-002-B | Error handling implementation |
| T023-T025 | I-002-C | Error handling testing |
| T026 | I-003-A | Baseline index tests |
| T027-T028 | I-003-B | High index tests |
| T029-T030 | I-003-C | Bounds documentation |
| T031 | T-001-A to T-001-D | Comprehensive test suite |
| T032 | T-001-E | Integration tests |
| T033 | T-002-A, T-002-B | Performance regression |
| T034 | T-002-C | Memory profiling |
| T035 | GATE-2 | Integration gate |
| T036 | E-001-A | Perceptual quality evaluation |
| T037 | E-001-B | Real-world app testing |
| T038 | E-001-C | Correctness verification |
| T039 | E-001-D | Rollout decision |

---

## Tracking & Progress

Each task should be tracked with:
- Task ID (both checklist T### and detailed IDs)
- Status (Not Started / In Progress / Complete)
- Actual effort (hours)
- Blockers or issues
- Approval sign-off

Gates require stakeholder approval before proceeding to next phase.
