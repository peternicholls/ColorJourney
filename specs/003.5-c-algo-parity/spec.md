# Feature Specification: C Algorithm Parity Testing

**Feature Branch**: `005-c-algo-parity`  
**Created**: 2025-12-12  
**Status**: Draft  
**Input**: User description: "we have two version of the C algorythm and calculations. 1. Sources/wasm/ 2. Sources/CColorJourney/ (recursive directories)

serious work has been made at making version 2. the canonical version. however, i am yet to see satisfactory output from it. Meanwhile, version 1. creates almost precisely the kind of output I expect in the web demo version.

Despite the work done, i am not satisfied. SO 

What I require is a number of tests that give the same inputs to each version and evaluates the output. We want data driven information: is the output the same, if not what is the difference, and then to find out what exactly might be causing any differences in the ouput of version 2.

create under spec 005-"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Parity Report For Both Engines (Priority: P1)

Engineering leads run a parity suite that feeds identical inputs to the canonical CColorJourney implementation (Sources/CColorJourney) and the wasm-target C build (Sources/wasm) treated as a plain C build, and receive a deterministic report showing which cases match within tolerance and which diverge. The canonical C core is the baseline.

**Why this priority**: Confirms whether the canonical path is safe to use and reveals divergences blocking adoption.

**Independent Test**: Trigger the parity suite with a fixed corpus and verify it generates a structured report with pass/fail per case and summary totals without needing any other tooling.

**Acceptance Scenarios**:

1. **Given** a fixed input corpus, **When** the suite runs both engines, **Then** all matching outputs are marked pass and aggregated in the summary.
2. **Given** a fixed input corpus with known mismatches injected, **When** the suite runs, **Then** mismatches are flagged with per-channel deltas and the summary shows failure counts.

---

### User Story 2 - Root Cause Hints For Divergences (Priority: P2)

Developers reviewing a failing case can see which parameters, stages, or components differ the most (e.g., specific function outputs, color channels, or derived metrics) to quickly narrow investigation.

**Why this priority**: Reduces time to diagnosis by pointing engineers to the most likely source of drift.

**Independent Test**: On a failing test case, confirm the report surfaces the top contributing differences (magnitude and direction) and maps them to the relevant computation stage or parameter.

**Acceptance Scenarios**:

1. **Given** a failing case, **When** the developer opens the detailed diff, **Then** the report lists the channels/metrics exceeding tolerance and their relative magnitude.
2. **Given** a failing case tied to a particular stage, **When** the diff is viewed, **Then** the stage or parameter involved is clearly indicated.

---

### User Story 3 - Traceable Regression Prevention (Priority: P3)

CI maintainers run the suite on demand or per change to prevent regressions; any new divergence automatically includes reproducible input/output artifacts for triage.

**Why this priority**: Keeps canonical implementation trustworthy over time and avoids shipping regressions.

**Independent Test**: Trigger the suite on a new change, confirm it fails the build if new mismatches appear, and that artifacts (inputs, outputs, diffs) are saved for each failing case.

**Acceptance Scenarios**:

1. **Given** a change that does not alter outputs, **When** the suite runs, **Then** it exits successfully with zero new failures recorded.
2. **Given** a change that introduces drift, **When** the suite runs, **Then** it fails and persists reproducible artifacts for the affected cases.

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- Inputs at numeric extremes (min/max channel values, near-zero, very high or low gamma) still normalize and compare without overflow/underflow errors.
- Non-deterministic or random-dependent paths use fixed seeds so both engines receive identical randomness.
- Unsupported or malformed inputs (invalid color space tags, NaNs, negative values) are rejected with clear errors and excluded from parity scoring.
- Platform-specific build flags or precision differences (e.g., SIMD, float width) are recorded so comparisons remain reproducible.
- Long-running or heavy test vectors time out gracefully with partial results logged.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: Provide a deterministic test harness that runs the same input corpus against both implementations (Sources/wasm and Sources/CColorJourney) in a single invocation.
- **FR-002**: Maintain a versioned, extensible input corpus covering typical palettes, boundary values, random seeds, and real-world samples used in the web demo.
- **FR-003**: Normalize outputs into a comparable representation (consistent color space, ordering, and precision) before evaluating differences.
- **FR-004**: Compute per-case differences with configurable absolute and relative tolerances, producing pass/fail status for each case.
- **FR-005**: Generate structured diff details for failing cases, including per-channel deltas, derived metric differences, and directionality of drift.
- **FR-006**: Produce aggregated summaries (counts, percentages, histograms of error magnitude) to highlight systemic bias or distribution of failures.
- **FR-007**: Record provenance for every run (commit hashes for both implementations, build flags, platform, corpus version) in the report header.
- **FR-008**: Emit reproducibility artifacts for every failing case (input payload, both raw outputs, computed deltas) suitable for rerunning a single case.
- **FR-009**: Allow targeted execution filters (by corpus subset, tag, or specific case IDs) to speed focused investigations.
- **FR-010**: Surface the top contributing stages or parameters for each failing case so reviewers see where divergence originates.

### Key Entities *(include if feature involves data)*

- **Input Case**: Structured set of parameters and expected processing stages used by both implementations; tagged with corpus identifiers and reproducibility seed.
- **Engine Output**: Normalized result from one implementation, including color values, derived metrics, and run metadata (commit, build flags, platform).
- **Comparison Result**: Pass/fail status plus per-channel deltas, derived metric differences, and references back to input case and both engine outputs.
- **Run Report**: Aggregated summary of all comparison results, environment provenance, and artifacts directory references.

### Assumptions & Dependencies

- Both implementations can be built from the same commit set and executed on the same platform so differences reflect logic, not environment skew.
- Outputs from both implementations can be normalized into a shared color space and precision without losing fidelity required for comparison.
- Test runners have access to persistent storage for reports and artifacts so failing cases remain reproducible over time.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: Parity suite completes the default corpus within 10 minutes on a standard CI runner while producing a full report and artifacts; runs exceeding this budget are flagged as failures.
- **SC-002**: At least 95% of cases in the default corpus pass within defined tolerances, with the canonical C core as the baseline and the alternate C build as the target.
- **SC-003**: Every failing case includes reproducibility artifacts (input, both outputs, computed deltas) automatically stored with the report.
- **SC-004**: For each failing case, the report highlights the top divergence contributor (channel or derived metric) so reviewers can identify a likely root-cause area without extra tooling.

### Default Tolerances and Corpus Versioning

- Default tolerances (used unless overridden): abs L=1e-4, abs a=1e-4, abs b=1e-4, ΔE<=0.5; relative tolerances L/a/b=1e-3.
- Corpus versioning: `vYYYYMMDD.n` (n increments per corpus change). Reports must record the corpus version and fail if missing.

---

## Phase 9: Swift Wrapper Parity Testing

**Status**: ✅ Phases 1-8 Complete → Phase 9 Specification Ready  
**Branch**: `005-c-algo-parity`  
**Next**: See [phase-9-swift-parity.md](phase-9-swift-parity.md) for full Phase 9 specification

After Phase 1-8 validates C algorithm parity (canonical vs wasm-derived C), Phase 9 extends validation to the Swift wrapper layer. This ensures the public Swift API (`Sources/ColorJourney/*`) accurately bridges to the C core without introducing deviations.

**Phase 9 Key Objectives**:
1. **Reuse corpus**: Apply same 7 test cases (98 colors) to Swift wrapper
2. **Reference-based validation**: Compare Swift outputs against known C reference outputs
3. **Zero-deviation requirement**: Identical tolerances enforce that Swift wrapper introduces no bugs
4. **Output format alignment**: Match C parity report schema for unified analysis
5. **CI integration**: Branch-specific GitHub Actions workflow for automated validation

**Phase 9 Documents**:
- **Full Specification**: [phase-9-swift-parity.md](phase-9-swift-parity.md)
- **Task Breakdown**: [phase-9-tasks.md](phase-9-tasks.md) - 29 tasks (T051-T079)
- **API Contract**: [contracts/swift-wrapper-parity-api.yaml](contracts/swift-wrapper-parity-api.yaml)
- **Executive Summary**: [PHASE-9-SPEC-SUMMARY.md](PHASE-9-SPEC-SUMMARY.md)
- **Complete Index**: [INDEX.md](INDEX.md)
