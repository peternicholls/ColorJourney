# Phase 9: Swift Wrapper Parity - Specification Complete

**Date**: 2025-12-12  
**Status**: ✅ Specification Complete - Ready for Implementation  
**Branch**: 005-c-algo-parity  

---

## Overview

A comprehensive specification for validating that the Swift wrapper layer accurately interfaces with the C core, ensuring zero deviation from expected outputs. This mirrors the C Algorithm Parity Testing framework but focuses on the Swift API boundary.

---

## What Has Been Created

### 1. **Phase 9 Specification Document**
📄 [phase-9-swift-parity.md](phase-9-swift-parity.md)

**Contains**:
- Overview and rationale
- Test strategy (corpus reuse, execution path, tolerances)
- Test components (unit, integration, E2E)
- Data models (input, output, comparisons, reports)
- 29 detailed tasks organized in 5 phases
- CI/CD workflow specification
- Success criteria

**Key Design Decisions**:
- ✅ Reuse same corpus as C parity (default.json, edge-cases.json)
- ✅ Compare against C reference outputs from Phase 1-8
- ✅ Match C parity output format for easy statistical comparison
- ✅ Same tolerances (abs L/a/b=1e-4, ΔE=0.5, rel L/a/b=1e-3)
- ✅ Phase 9 of 005-c-algo-parity (sequential, not parallel spec)

### 2. **Detailed Task List**
📄 [phase-9-tasks.md](phase-9-tasks.md)

**Contains**:
- **Phase 9a** (T051-T058): Swift Unit Tests - 8 tasks
  - JSON corpus parsing
  - Color space conversions
  - Anchor loading and parameter mapping
  - Output normalization and delta calculations
  - Tolerance application and comparison logic
  - Test integration

- **Phase 9b** (T059-T065): Swift Integration & CLI - 7 tasks
  - Swift runner binary implementation
  - C reference loader
  - Comparison bridge
  - Report generator
  - CLI argument parsing
  - Makefile integration
  - Integration tests

- **Phase 9c** (T066-T070): Execution & Validation - 5 tasks
  - Run against default corpus
  - Run against edge cases
  - Verify artifacts
  - Run full test suite
  - Document sample run

- **Phase 9d** (T071-T075): Documentation & CI - 5 tasks
  - Update quickstart guide
  - Create testing guide
  - Document expected outputs
  - Create GitHub Actions workflow
  - Integrate into repository

- **Phase 9e** (T076-T079): Final Review - 4 tasks
  - Review reports
  - Analyze findings
  - Verify CI integration
  - Plan follow-ups

**Total**: 29 tasks with detailed acceptance criteria

### 3. **API Contract Specification**
📄 [contracts/swift-wrapper-parity-api.yaml](contracts/swift-wrapper-parity-api.yaml)

**Contains**:
- OpenAPI 3.1 specification for Swift parity API
- Request/response schemas
- Per-color comparison models
- Statistical analysis models
- Provenance tracking for Swift builds
- Example payloads

**Endpoints**:
- `POST /swift-runner/run` - Execute Swift parity test
- `GET /swift-runner/runs/{runId}` - Fetch run status
- `GET /swift-runner/runs/{runId}/results/{caseId}` - Get case comparison
- `GET /swift-runner/runs/{runId}/artifacts/{caseId}` - Download artifacts

---

## Test Architecture

### Data Flow

```
Corpus JSON
    ↓
[Swift API]  ← Swift Wrapper under test
    ↓
[C Core]     ← Reference implementation
    ↓
Palette Output (OKLab)
    ↓
[C Reference] (from Phase 8)
    ↓
Comparison & Deltas
    ↓
Pass/Fail Status
    ↓
Report (same schema as C parity)
```

### Test Layers

| Layer | Purpose | Location |
|-------|---------|----------|
| **Unit** | Verify individual components (parsing, conversion, comparison) | `Tests/ColorJourneyTests/ParityTests/` |
| **Integration** | Test Swift runner against fixture corpus | `specs/.../tools/swift-parity-runner/tests/` |
| **E2E** | Full corpus execution, report generation, CI validation | GitHub Actions + local execution |

### Test Scope

**What We're Testing**:
- ✅ Data marshaling: Swift inputs → C core
- ✅ Output accuracy: C outputs → Swift types
- ✅ Numerical equivalence: Swift palette matches C reference
- ✅ API correctness: Public API is faithful wrapper
- ✅ Type conversions: Float/Double precision
- ✅ Error handling: Invalid inputs, edge cases

**What We're NOT Testing**:
- ❌ C core correctness (already validated in Phase 1-8)
- ❌ SwiftUI integration (separate concern)
- ❌ Performance optimization (secondary goal)
- ❌ CocoaPods/SPM packaging (Phase 10+)

---

## Key Design Decisions

### 1. Corpus Reuse
**Decision**: Use exact same corpus files as C parity  
**Rationale**: Ensures consistency, simplifies comparison, validates wrapper doesn't modify inputs

### 2. Reference-Based Comparison
**Decision**: Compare Swift outputs against known C reference outputs  
**Rationale**: 
- C core already validated as correct
- Swift should produce identical results
- Easy to detect Swift wrapper bugs

### 3. Identical Tolerance Thresholds
**Decision**: Use same tolerances (abs L/a/b=1e-4, ΔE=0.5, rel L/a/b=1e-3)  
**Rationale**:
- Swift should introduce zero deviation
- Any tolerance difference indicates bugs
- Maintains consistency across metrics

### 4. Output Format Alignment
**Decision**: Match C parity report schema exactly  
**Rationale**:
- Enables direct statistical comparison
- Simplifies analysis across both reports
- Supports unified dashboarding/visualization

### 5. Phase 9 Sequential Placement
**Decision**: Phase 9 of 005-c-algo-parity, not separate spec  
**Rationale**:
- Builds on C parity infrastructure
- Reuses corpus, tolerances, comparison logic
- Natural progression (C core → Swift wrapper)

---

## Expected Outcomes

### Perfect Parity (Expected)
```
7 test cases, 98 color samples
✅ 100% pass rate (7/7 cases)
✅ All deltas = 0.0
✅ Reports match C parity structure
```

**Why**:
- Swift wrapper is thin interface to C core
- No data transformation in wrapper layer
- Identical algorithms on both sides

### Artifact Preservation
All tests generate reproducible artifacts:
- Input corpus (what was tested)
- Swift outputs (Swift palette JSON)
- C reference (from Phase 8)
- Deltas (per-color differences)
- Metadata (provenance, timestamps)

---

## CI/CD Strategy

### Workflow: `swift-parity.yml`
**Trigger**: Pushes/PRs to `005-c-algo-parity` branch only

**Steps**:
1. Checkout code
2. Setup Swift 5.9
3. Run Swift unit tests
4. Build C core parity runner
5. Generate C reference outputs
6. Build Swift parity runner
7. Run Swift parity (default corpus)
8. Run Swift parity (edge cases)
9. Check pass rate (≥95%)
10. Upload artifacts on failure

**Duration**: ~3-5 minutes on standard runner

**Reporting**:
- ✅ Pass: Green checkmark, artifacts available
- ❌ Fail: Red X, artifacts uploaded for investigation

---

## Implementation Roadmap

### Phase 9a: Unit Tests (Sprint 1)
**Effort**: 1-2 days  
**Parallelizable**: Yes  
**Blockers**: None

**Deliverables**:
- Corpus parser implementation
- Unit test suite (8 test classes)
- 100% test pass rate

### Phase 9b: Integration (Sprint 1-2)
**Effort**: 2-3 days  
**Parallelizable**: Partial (after 9a)  
**Blockers**: T051-T055 completion

**Deliverables**:
- Swift parity runner binary
- CLI interface with all options
- Integration test suite

### Phase 9c: Execution (Sprint 2)
**Effort**: 1 day  
**Parallelizable**: Yes (after 9b)  
**Blockers**: T059-T064 completion

**Deliverables**:
- Full corpus execution reports
- Sample run documentation
- Artifact validation

### Phase 9d: Documentation & CI (Sprint 2-3)
**Effort**: 1-2 days  
**Parallelizable**: Yes (after 9c)  
**Blockers**: T066-T069 completion

**Deliverables**:
- Updated quickstart
- Testing guide
- GitHub Actions workflow
- CI integration

### Phase 9e: Final Review (Sprint 3)
**Effort**: 1 day  
**Parallelizable**: No  
**Blockers**: 9a-9d completion

**Deliverables**:
- Comprehensive review document
- Findings and analysis
- Follow-up recommendations

**Total Effort**: ~5-7 days development + review

---

## Questions for Implementation

### Swift Type System
- Should we use `Double` or `Float` for precision? (Recommend: Double for consistency with C)
- Handle `Codable` errors gracefully? (Yes, with detailed error messages)

### Error Handling
- Fail fast on first divergence or accumulate all? (Accumulate for comprehensive reporting)
- How strict with JSON validation? (Use corpus schema, reject malformed)

### Extensibility
- Support additional metrics beyond ΔE? (No, keep aligned with C parity)
- Allow custom comparison functions? (No, standardize on C methodology)

### Performance
- Target runtime? (< 1 second for corpus, like C parity)
- Profile memory usage? (Not in initial phase, can add later)

---

## Success Metrics

| Metric | Target | Verification |
|--------|--------|--------------|
| **Unit test coverage** | >80% | Code coverage report |
| **Integration tests** | 100% pass | CI execution |
| **E2E pass rate** | 100% (7/7) | Report summary |
| **Parity achieved** | ΔE=0.0 across corpus | Per-case delta inspection |
| **Documentation** | Complete | Quickstart, guide, samples |
| **CI integration** | Operational | Workflow executes on push |
| **Implementation time** | <1 week | Sprint velocity tracking |

---

## Next Steps

1. **Review this specification** - Clarify any questions
2. **Allocate resources** - Assign to developer(s)
3. **Setup repository** - Create file structure, Makefile targets
4. **Begin Phase 9a** - Start with unit tests (T051-T058)
5. **Iterate through phases** - Follow task dependencies
6. **Validate results** - Run full suite, generate reports
7. **Integrate CI** - Deploy workflow to GitHub Actions
8. **Document findings** - Create final review

---

## References

- [Phase 1-8 Results](../artifacts/full-run-default/report.json)
- [C Parity Review](../review.md)
- [Test Corpus](../corpus/)
- [Tolerance Policy](../config/README.md)
- [Swift API Source](../../Sources/ColorJourney/ColorJourney.swift)
- [Existing Tests](../../Tests/ColorJourneyTests/)

---

## Appendix: Terminology

| Term | Definition |
|------|-----------|
| **C Core** | Canonical implementation in Sources/CColorJourney/ |
| **C Reference** | Outputs from C core (Phase 1-8 artifacts) |
| **Swift Wrapper** | Public API in Sources/ColorJourney/ |
| **Data Marshaling** | Converting between Swift and C type systems |
| **Parity** | Exact equivalence (ΔE ≈ 0) between implementations |
| **Tolerance** | Acceptable deviation threshold for colors |
| **Corpus** | Standardized test cases (input + expected behavior) |
| **Provenance** | Metadata tracking commits, platform, versions |
| **Artifacts** | Reproducible test inputs, outputs, artifacts |

---

**Specification Complete** ✅  
**Ready for Implementation** 🚀
