# 004 Incremental Creation - Implementation Plan

**Feature ID:** 004-incremental-creation  
**Status:** Specification complete, ready for implementation planning  
**Created:** December 16, 2025  
**Planned Start:** Next Sprint  

---

## Executive Summary

This document outlines the execution plan for completing feature 004 (Incremental Color Swatch Generation). The core API is already implemented (SC-001 to SC-007 ✅ shipped Dec 9, 2025). This plan addresses:
- **Phase 0 (Research):** Thread safety investigation (SC-011), chunk size optimization (SC-012)
- **Phase 1 (Implementation):** Delta Range Enforcement (SC-008), error handling (SC-009), index bounds (SC-010)
- **Phase 2 (Integration):** Comprehensive testing, performance regression validation
- **Phase 3 (Evaluation):** Effectiveness assessment, rollout decision for Delta Range Enforcement
- **Sequencing:** 4 phases, clear phase gates, dependencies documented
- **Success metrics:** Clear completion criteria linked to spec success criteria (SC-008 to SC-012)

**Traceability:** Each phase and task maps to specific functional requirements (FR-*) and success criteria (SC-*) in [spec.md](spec.md). See [Success Criteria & Task Traceability](#task-to-requirement-traceability) table below.

---

## Phase Overview & Requirement Traceability

| Phase | Focus | Success Criteria | Spec Requirements | Estimated Duration |
|-------|-------|------------------|------------------|-------------------|
| **Phase 0** | Research & Investigation | SC-011, SC-012 validated; recommendations documented | R-001 (chunk size), R-002 (thread safety), R-003 (index overflow/precision) | 2 weeks |
| **Phase 1** | Implementation | SC-008, SC-009, SC-010 complete; all tests passing | FR-007 (Delta Range), FR-006 (Errors), FR-008 (Bounds) | 2 weeks |
| **Phase 2** | Integration & Testing | All 86 tests passing; performance within <10% baseline | SC-008, SC-009, SC-010 verified via test suite | 1 week |
| **Phase 3** | Evaluation & Decision | Effectiveness assessed; rollout decision made | SC-008 effectiveness evaluation; rollout recommendation (general vs. incremental-only) | 1 week |

**Total:** ~6 weeks for complete feature delivery with evaluation and rollout decision

---

## Task-to-Requirement Traceability

| Spec Requirement | Phase | Task(s) | Description |
|---|---|---|---|
| **SC-011: Thread Safety** | Phase 0 | R-002-A, R-002-B, R-002-C | Code review → concurrent testing → stress testing & documentation |
| **SC-012: Chunk Size Optimization** | Phase 0 | R-001-A, R-001-B, R-001-D | Baseline measurement → benchmark chunk sizes → decision & rationale |
| **FR-008: Index Overflow Strategy** | Phase 0 → 1 | R-003-A, R-003-B, R-003-C → I-003-B, I-003-C | Precision analysis → codebase investigation → strategy selection → high index testing |
| **FR-007: Delta Range Enforcement** | Phase 1 → 3 | I-001-A, I-001-B, I-001-C, I-001-D → E-001-A, E-001-B, E-001-D | Algorithm design → C implementation → testing → code review → real-world evaluation → rollout decision |
| **FR-006: Error Handling** | Phase 1 → 2 | I-002-A, I-002-B, I-002-C → T-001-C | Error audit → implementation → testing → integration |
| **FR-008 (Bounds):** Index Bounds Validation | Phase 1 → 2 | I-003-A, I-003-B, I-003-C → T-001-D | Baseline testing → high index testing → documentation → integration |

---

## Phase Overview

| Phase | Focus | Success Criteria | Estimated Duration |
|-------|-------|------------------|-------------------|
| **Phase 0** | Research & Investigation | SC-011 to SC-012 validated | 2 weeks |
| **Phase 1** | Implementation | SC-008 to SC-010 complete | 2 weeks |
| **Phase 2** | Integration & Testing | All tests passing, performance baseline | 1 week |
| **Phase 3** | Evaluation & Decision | Rollout decision for general availability | 1 week |

**Total:** ~6 weeks for complete feature

---

## Phase 0: Research & Investigation

### Task R-001: Lazy Sequence Chunk Size Optimization (SC-012)

**Objective:** Find optimal chunk size for lazy sequence (currently 100)

**Approach:**
1. Establish baseline: Measure C core generation speed
   - Time to generate 1, 10, 50, 100, 500, 1000 colors
   - Memory allocation patterns
   - Cache behavior

2. Test chunk sizes: 10, 25, 50, 100, 200, 500
   - Measure: Generation time, memory overhead, iteration latency
   - Compare each to C core baseline
   - Identify inflection points

3. Real-world testing:
   - Measure with actual Swift UI operations
   - Profile memory under sustained iteration
   - Test on different hardware (iPhone, iPad, Mac)

4. Decision criteria:
   - Inflection point: Where memory savings plateau
   - Performance: Within 10% of C core baseline
   - Practical: Chunk size < 1 MB

**Deliverables:**
- Performance benchmark report
- Recommended chunk size with rationale
- Regression test thresholds

**Estimated Duration:** 3-4 days

**Dependencies:** None (can run immediately)

---

### Task R-002: Thread Safety Investigation & Testing (SC-011)

**Objective:** Verify thread safety guarantees and identify edge cases

**Approach:**
1. Code investigation:
   - Review stateless design for race conditions
   - Check contrast chain computation for thread conflicts
   - Verify C memory model assumptions

2. Testing strategy:
   - Concurrent reads: Multiple threads reading same index
   - Concurrent ranges: Multiple threads calling discrete_range
   - Stress test: High-concurrency access patterns
   - Tools: Thread sanitizer, race detector

3. Edge cases:
   - Journey lifecycle during concurrent access
   - Memory layout under concurrent modification
   - Cache coherency (if caching added later)

4. Documentation:
   - Document guarantees: "Safe for concurrent reads"
   - Document limitations: "Not thread-safe for concurrent modifications"
   - Recommendations: When to use locks

**Deliverables:**
- Thread safety test suite
- Documented guarantees and limitations
- Developer guidance

**Estimated Duration:** 4-5 days

**Dependencies:** None (can run immediately)

---

### Task R-003: Index Overflow & Precision Investigation

**Objective:** Define behavior and limits for high index values

**Approach:**
1. Precision analysis:
   - Test floating-point precision at indices 1M, 10M, 100M
   - Identify precision loss boundaries
   - Measure color difference at precision loss point

2. Codebase investigation:
   - Review overflow handling patterns in existing code
   - Check int vs. int32_t vs. int64_t usage
   - Look for established patterns (AGENTS.md, standards)

3. Strategy selection:
   - Match existing codebase approach
   - Document chosen strategy
   - Define max supported index

4. Testing:
   - Determinism at high indices
   - Precision guarantees
   - Graceful degradation

**Deliverables:**
- Overflow handling strategy (matching codebase)
- Precision guarantee documentation
- Test cases for boundary conditions

**Estimated Duration:** 2-3 days

**Dependencies:** None (parallel with R-001 and R-002)

---

### Research Phase Success Criteria

✅ All three research tasks complete  
✅ Recommendations documented with rationale  
✅ Test baselines established  
✅ Implementation strategy clear  

---

## Phase 1: Implementation

### Task I-001: Delta Range Enforcement (FR-007, SC-008)

**Objective:** Implement automatic min/max delta (ΔE) enforcement

**Requirements:**
- Minimum ΔE: 0.02 (prevents perceptually identical colors)
- Maximum ΔE: 0.05 (prevents excessive color jumps)
- Color space: OKLab (perceptual distance)
- Scope: Incremental workflow only
- Algorithm: As specified in spec

**Implementation Steps:**

1. **C Core Implementation** (ColorJourney.c)
   ```c
   // New helper function
   static float discrete_enforce_delta_range(
       CJ_Journey_Impl* j,
       float initial_t,      // Starting position
       CJ_RGB previous,      // Previous color
       float min_delta_e,    // 0.02
       float max_delta_e     // 0.05
   );
   ```

2. **Algorithm Implementation:**
   - Input: Initial position from index mapping
   - Calculate: Base color at position
   - Check: ΔE against previous color
   - Adjust: Position if needed
   - Return: Final position with delta constraints

3. **Integration:**
   - Update `discrete_color_at_index()` to use enforced position
   - Maintain determinism (same input → same output)
   - Preserve contrast enforcement (FR-002)

4. **C Tests:**
   - Minimum delta: Verify ΔE(n, n-1) ≥ 0.02
   - Maximum delta: Verify ΔE(n, n-1) ≤ 0.05
   - Conflict resolution: When constraints can't be satisfied
   - Effectiveness: Measure perceptual improvement

5. **Swift Wrapper:**
   - No API changes needed (already transparent)
   - Verify tests pass (automatic benefit)

**Deliverables:**
- C implementation with OKLab ΔE calculation
- 4 new test cases
- Performance measurements

**Estimated Duration:** 5-6 days

**Dependencies:** Research phase (baseline understanding)

---

### Task I-002: Error Handling Enhancement (FR-006, SC-009)

**Objective:** Improve error handling for invalid inputs

**Requirements:**
- Black (0,0,0) return for negative indices (existing)
- Black (0,0,0) return for NULL journey (existing)
- Graceful handling of invalid handles
- Swift: No crashes on bad input

**Implementation Steps:**

1. **Validation audit:**
   - Review current error paths
   - Check what errors are handled
   - Identify unhandled cases

2. **Enhancement:**
   - Add bounds checking
   - Add handle validation
   - Consider error state in Swift wrapper

3. **Testing:**
   - Negative indices → black
   - NULL journey → black (C), nil-safe (Swift)
   - Invalid handles → graceful degradation
   - No crashes under any input

4. **Documentation:**
   - Document error behavior
   - Add examples of error cases
   - Swift error handling guide

**Deliverables:**
- Enhanced error handling code
- 3-4 error case tests
- Developer documentation

**Estimated Duration:** 2-3 days

**Dependencies:** None (independent task)

---

### Task I-003: Index Bounds Validation (FR-008, SC-010)

**Objective:** Test and document index bounds (0 to 1,000,000)

**Implementation Steps:**

1. **Bounds testing:**
   - Test index 0: Baseline
   - Test index 999,999: Near limit
   - Test index 1,000,000: At limit
   - Test beyond 1M: Behavior undefined
   - Precision validation: Colors match expected

2. **Documentation:**
   - Document supported range
   - Document precision guarantees
   - Document behavior beyond max

3. **Warning system:**
   - Log warning if precision loss detected
   - Document developer responsibility
   - Suggest alternatives (batching, chunking)

**Deliverables:**
- Bounds test suite
- Precision documentation
- Developer warnings/guidance

**Estimated Duration:** 2-3 days

**Dependencies:** Research phase (precision investigation)

---

### Implementation Phase Success Criteria

✅ SC-008: Delta range enforcement working (ΔE: 0.02-0.05)  
✅ SC-009: Error handling robust (graceful degradation)  
✅ SC-010: Index bounds tested (0-1M, precision documented)  
✅ All new tests passing  
✅ No performance regression  

---

## Phase 2: Integration & Testing

### Task T-001: Comprehensive Test Suite

**Objective:** Full test coverage for all new features

**Test Structure:**
1. Unit tests (existing):
   - Determinism: Same index → same color
   - Consistency: Range matches individual calls
   - Contrast: ΔE ≥ configured minimum

2. New delta range tests:
   - Minimum enforcement: ΔE ≥ 0.02
   - Maximum enforcement: ΔE ≤ 0.05
   - Constraint conflict: Preferred resolution
   - Multi-contrast-level: MEDIUM vs. HIGH

3. Error handling tests:
   - Negative indices
   - NULL/invalid journeys
   - Handle validation

4. Bounds tests:
   - Index 0, 1, 10, 100, 1000, 999999, 1000000
   - Precision validation
   - Determinism across bounds

5. Integration tests:
   - All features together
   - Real-world usage patterns
   - Performance characteristics

**Deliverables:**
- Test suite: ~30 new tests
- Test report: Coverage, results, performance

**Estimated Duration:** 3-4 days

---

### Task T-002: Performance Baseline & Regression Tests

**Objective:** Establish performance metrics and regression prevention

**Measurements:**
1. C core performance:
   - `discrete_at(10)`: < 1ms
   - `discrete_at(100)`: < 5ms
   - `discrete_range(0, 100)`: < 5ms
   - `discreteColors.prefix(100)`: < 5ms

2. Regressions:
   - Compare new implementation to baseline
   - Accept <10% overhead for delta range
   - Document performance trade-offs

3. Memory profiling:
   - Lazy sequence chunk buffer: 1.2 KB
   - Stack allocation: ~24 bytes/call
   - No heap leaks

**Deliverables:**
- Performance baseline report
- Regression test thresholds
- Documentation

**Estimated Duration:** 2-3 days

---

### Integration Phase Success Criteria

✅ All tests passing (56 + 30 new = 86 tests)  
✅ Performance within <10% baseline  
✅ No regressions detected  
✅ Code review approved  
✅ Documentation complete  

---

## Phase 3: Evaluation & Decision

### Task E-001: Effectiveness Evaluation

**Objective:** Assess whether delta range should be rolled out generally

**Evaluation Criteria:**

1. **Perceptual Quality:**
   - Do users perceive improvement?
   - Are colors more balanced?
   - Any negative feedback?

2. **Performance:**
   - Is overhead acceptable?
   - Does it impact real-world applications?
   - Any bottlenecks?

3. **Correctness:**
   - All tests passing?
   - Edge cases handled?
   - No regressions?

4. **User Feedback:**
   - Trial with real applications
   - Gather qualitative feedback
   - Measure adoption

**Decision Options:**
1. **General Rollout:** Remove "incremental only" scope, enable for all APIs
2. **Incremental Only:** Keep as incremental-specific feature
3. **Configurable:** Add override API (FR-007 future enhancement)
4. **Defer:** More research needed

**Deliverables:**
- Evaluation report
- Effectiveness metrics
- Rollout recommendation
- Decision memo

**Estimated Duration:** 1 week (post-integration)

---

## Task Dependencies & Sequencing

```
Phase 0 (Research):
├─ R-001: Chunk size optimization (3-4 days)
├─ R-002: Thread safety investigation (4-5 days)
└─ R-003: Index overflow investigation (2-3 days)
   └─ All parallel

Phase 1 (Implementation):
├─ I-001: Delta range enforcement (5-6 days)
├─ I-002: Error handling (2-3 days)
└─ I-003: Index bounds validation (2-3 days)
   └─ I-001 depends on R-003
   └─ I-002 and I-003 parallel

Phase 2 (Integration):
├─ T-001: Test suite (3-4 days)
└─ T-002: Performance baseline (2-3 days)
   └─ Depends on Phase 1 complete

Phase 3 (Evaluation):
└─ E-001: Effectiveness evaluation (1 week)
   └─ Depends on Phase 2 complete
```

---

## Sprint Planning

### Sprint 1 (Week 1-2): Research Phase

**Goals:**
- Complete all research tasks
- Establish baselines
- Define implementation strategy

**Tasks:**
- R-001: Chunk size optimization
- R-002: Thread safety investigation
- R-003: Index overflow analysis

**Deliverables:**
- Research reports (3)
- Recommendations documented
- Implementation strategy clear

---

### Sprint 2 (Week 3-4): Implementation Phase

**Goals:**
- Implement SC-008 to SC-010
- Write comprehensive tests
- No regressions

**Tasks:**
- I-001: Delta range enforcement
- I-002: Error handling
- I-003: Index bounds validation
- T-001: Test suite

**Deliverables:**
- Code implementation
- Test suite (30 new tests)
- All tests passing

---

### Sprint 3 (Week 5): Integration & Baseline

**Goals:**
- Performance validation
- Regression prevention
- Ready for evaluation

**Tasks:**
- T-002: Performance baseline
- Code review
- Documentation finalization

**Deliverables:**
- Performance report
- Baseline thresholds
- Ready to merge

---

### Sprint 4 (Week 6): Evaluation & Decision

**Goals:**
- Assess effectiveness
- Make rollout decision
- Plan next steps

**Tasks:**
- E-001: Effectiveness evaluation
- Gather user feedback
- Rollout decision

**Deliverables:**
- Evaluation report
- Recommendation memo
- Rollout plan (if applicable)

---

## Risk Assessment & Mitigation

### Risk R1: Chunk Size Optimization Takes Longer Than Expected

**Impact:** High (blocks Phase 1 work)  
**Probability:** Medium  
**Mitigation:**
- Parallel investigation with implementation
- Use conservative initial estimate (100)
- Optimize later if needed
- Fallback: Document research findings, move forward

---

### Risk R2: Delta Range Algorithm Complex/Buggy

**Impact:** High (core feature)  
**Probability:** Medium  
**Mitigation:**
- Thorough specification (done ✓)
- Comprehensive test cases (planned)
- Code review focusing on algorithm
- Incremental testing: Test simple case first

---

### Risk R3: Performance Regression Discovered

**Impact:** Medium (must fix before rollout)  
**Probability:** Low  
**Mitigation:**
- Baseline established early
- Regression tests in place
- Performance budget: <10% overhead
- Analysis phase to understand and optimize

---

### Risk R4: Thread Safety Issues Found Late

**Impact:** High (may require redesign)  
**Probability:** Low (stateless design)  
**Mitigation:**
- Research phase tests comprehensively
- Use thread sanitizer
- Document guarantees clearly
- Plan mitigation: Add locks if needed

---

## Success Metrics & Go/No-Go Criteria

### Go/No-Go Decision Points

**Gate 1 (End Phase 0):** Research Complete
- ✅ All three research tasks done
- ✅ Recommendations documented
- ✅ Implementation strategy clear
- **Decision:** Proceed to Phase 1 or revise approach?

**Gate 2 (End Phase 1):** Implementation Complete
- ✅ All code changes merged
- ✅ All tests passing (86 tests)
- ✅ Code review approved
- ✅ No regressions detected
- **Decision:** Proceed to Phase 2 or fix issues?

**Gate 3 (End Phase 2):** Ready for Evaluation
- ✅ Performance baseline stable
- ✅ All tests still passing
- ✅ Documentation complete
- ✅ Real-world testing done
- **Decision:** Proceed to rollout or defer?

**Gate 4 (End Phase 3):** Rollout Decision
- ✅ Effectiveness evaluated
- ✅ Recommendation clear
- ✅ Next steps defined
- **Decision:** General rollout, incremental only, or defer?

---

## Resource Requirements

| Role | Hours | Notes |
|------|-------|-------|
| Developer | 120 | Implementation + testing + research |
| Code Reviewer | 20 | Multiple review passes |
| QA/Tester | 30 | Integration testing + validation |
| **Total** | **170** | ~4 weeks full-time effort |

---

## Communication Plan

### Weekly Status Updates
- **Research Phase:** Findings and blockers
- **Implementation Phase:** Progress on SC-008/009/010
- **Integration Phase:** Test results and performance
- **Evaluation Phase:** Feedback and rollout recommendation

### Stakeholder Decisions
- **Gate 1:** Continue with Phase 1?
- **Gate 2:** Acceptable performance/quality?
- **Gate 3:** Ready for general rollout?

### Documentation
- Research findings → Research reports
- Implementation → Commits with clear messages
- Testing → Test suite coverage report
- Evaluation → Rollout recommendation memo

---

## Next Steps

1. **Approve Plan** ← You are here
2. **Sprint 1 Start:** Research & Investigation
3. **Sprint 1 End:** Review research findings
4. **Sprint 2 Start:** Implementation
5. **Sprint 2 End:** Review implementation + tests
6. **Sprint 3 Start:** Integration & Baseline
7. **Sprint 3 End:** Performance validation
8. **Sprint 4 Start:** Evaluation & Decision
9. **Sprint 4 End:** Rollout decision made

---

## Appendix: Key Definitions

**Delta (ΔE):** Perceptual color distance in OKLab space

**Incremental Workflow:** When application doesn't know total color count at start

**Chunk Size:** Number of colors buffered in lazy sequence before recomputing

**Thread Safety:** Safe to call from multiple threads simultaneously

**Precision Loss:** Float rounding errors at high indices (> 1M)

**Rollout:** Enable feature for general use beyond incremental workflows
