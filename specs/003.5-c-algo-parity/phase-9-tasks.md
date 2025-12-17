# Phase 9 Task Details: Swift Wrapper Parity Testing

**Phase**: 9 of 005-c-algo-parity  
**Focus**: Swift API wrapper fidelity testing  
**Duration**: Estimated 2-3 sprints  
**Dependencies**: Phase 1-8 (C parity complete)

---

## Phase 9a: Swift Unit Tests (Marshaling & Normalization)

### T051: Implement JSON corpus parser in Swift

**Description**: Build Codable Swift structures to parse the same corpus JSON as the C parity runner.

**Acceptance Criteria**:
- [X] Swift structs created for CorpusFile, InputCase, Anchor, Config
- [X] `Codable` conformance for JSON deserialization
- [X] Parser handles both OKLab and sRGB anchor representations
- [X] Unit test: Load default.json and confirm 3 cases parse correctly
- [X] Unit test: Load edge-cases.json and confirm 4 cases parse correctly
- [X] Unit test: Rejects malformed corpus with clear error messages

**Location**: `Tests/ColorJourneyTests/ParityTests/CorpusParserTests.swift`

**Dependencies**: None

---

### T052: Add unit tests for OKLab↔RGB conversions

**Description**: Validate color space conversion accuracy matches C core.

**Acceptance Criteria**:
- [X] Test OKLab → RGB conversion against known reference values
- [X] Test RGB → OKLab conversion (round-trip accuracy)
- [X] Compare against C reference outputs from Phase 8 artifacts
- [X] Verify absolute error < 1e-6 (better than tolerance threshold)
- [X] Test boundary cases (pure white, pure black, highly saturated)

**Location**: `Tests/ColorJourneyTests/ParityTests/ColorConversionTests.swift`

**Dependencies**: T051

---

### T053: Add unit tests for anchor color loading from corpus

**Description**: Verify anchors are correctly loaded from corpus JSON.

**Acceptance Criteria**:
- [X] Test loading OKLab anchors and converting to internal representation
- [X] Test loading sRGB anchors and converting to internal representation
- [X] Confirm per-anchor parameters (tags, notes) are preserved
- [X] Test with single and multi-anchor cases
- [X] Verify seed values are correctly passed to randomizer

**Location**: `Tests/ColorJourneyTests/ParityTests/AnchorLoadingTests.swift`

**Dependencies**: T051, T052

---

### T054: Add unit tests for parameter mapping

**Description**: Verify all configuration parameters map correctly to C core calls.

**Acceptance Criteria**:
- [X] Map corpus lightness → ColorJourneyConfig parameter
- [X] Map corpus chroma → ColorJourneyConfig parameter
- [X] Map corpus contrast → ColorJourneyConfig parameter
- [X] Map corpus count → expected palette size
- [X] Test optional parameters (vibrancy, temperature, loopMode)
- [X] Confirm default values when parameters omitted

**Location**: `Tests/ColorJourneyTests/ParityTests/ParameterMappingTests.swift`

**Dependencies**: T051

---

### T055: Add unit tests for output normalization

**Description**: Verify palette output is correctly normalized to OKLab.

**Acceptance Criteria**:
- [X] Generate palette with Swift API
- [X] Normalize output colors to OKLab
- [X] Confirm conversion matches C conversion (T052 validated)
- [X] Test with all corpus cases
- [X] Verify no color loss or clipping in conversion

**Location**: `Tests/ColorJourneyTests/ParityTests/OutputNormalizationTests.swift`

**Dependencies**: T051, T052, T054

---

### T056: Add unit tests for ΔE and per-channel delta calculations

**Description**: Validate delta computations match C parity metrics.

**Acceptance Criteria**:
- [X] Implement deltaE76 calculation in Swift
- [X] Compare against C reference (Phase 8 artifacts)
- [X] Test per-channel absolute delta (L, a, b)
- [X] Test per-channel relative delta
- [X] Verify calculations with synthetic deltas (known inputs/outputs)
- [X] Confirm math precision (double, not float)

**Location**: `Tests/ColorJourneyTests/ParityTests/DeltaCalculationTests.swift`

**Dependencies**: T052, T055

---

### T057: Add unit tests for tolerance application and comparison logic

**Description**: Verify tolerance thresholds and pass/fail logic.

**Acceptance Criteria**:
- [X] Test absolute tolerance application (L/a/b = 1e-4, ΔE = 0.5)
- [X] Test relative tolerance application (L/a/b = 1e-3)
- [X] Verify pass when delta < tolerance
- [X] Verify fail when delta >= tolerance
- [X] Test override tolerances via options
- [X] Confirm pass rate calculation (passed / total)

**Location**: `Tests/ColorJourneyTests/ParityTests/ToleranceTests.swift`

**Dependencies**: T056

---

### T058: Wire unit tests into `swift test`

**Description**: Ensure all unit tests are discoverable and run via standard Swift test command.

**Acceptance Criteria**:
- [X] All test files import XCTest and follow naming convention
- [X] `swift test` discovers and runs all ParityTests
- [X] Test output shows per-test results
- [X] All tests pass (green)
- [ ] Code coverage reporting enabled (if desired)

**Location**: `Tests/ColorJourneyTests/`

**Dependencies**: T051-T057

---

## Phase 9b: Swift Integration & CLI

### T059: Create Swift parity runner binary

**Description**: Build a command-line tool that generates palettes using Swift API and outputs JSON.

**Acceptance Criteria**:
- [X] Executable accepts --corpus argument
- [X] Reads corpus JSON and iterates cases
- [X] For each case: creates ColorJourney instance
- [X] Generates palette (count specified in corpus)
- [X] Outputs JSON with case ID and color array
- [X] JSON format matches C runner output structure
- [X] Handles errors gracefully (corpus not found, invalid seed)

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Sources/main.swift`

**Dependencies**: T051, T055

---

### T060: Implement C reference loader

**Description**: Load C reference outputs from Phase 8 artifacts.

**Acceptance Criteria**:
- [X] Read C parity report JSON (full-run-default/report.json)
- [X] Extract per-case outputs (canonical colors)
- [X] Index by case ID for fast lookup
- [X] Normalize to same OKLab representation as Swift output
- [X] Handle missing case gracefully (skip comparison)

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Sources/ReferenceLoader.swift`

**Dependencies**: T055

---

### T061: Build comparison bridge linking Swift output to C reference

**Description**: Compare Swift-generated palettes against C reference.

**Acceptance Criteria**:
- [X] For each case: compare Swift colors to C reference
- [X] Compute per-color deltas (ΔE, L, a, b)
- [X] Compute per-case statistics (mean, max, stddev)
- [X] Apply tolerances and generate pass/fail status
- [X] Output ComparisonResult JSON (per-case)
- [X] Accumulate summary statistics

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Sources/ComparisonBridge.swift`

**Dependencies**: T056, T057, T060

---

### T062: Implement report generator

**Description**: Generate JSON report matching C parity schema.

**Acceptance Criteria**:
- [X] Report matches `RunStatus` schema from contracts/parity-api.yaml
- [X] Include runId, phase (9), corpusVersion
- [X] Add Swift-specific metadata (version, target SDK)
- [X] Include summary (total, passed, failed, pass rate)
- [X] Include statistical analysis (mean/stddev/percentiles for ΔE)
- [X] Include per-case results (status, deltas, artifacts path)
- [X] Include provenance (commits, platform, timestamp)
- [X] Output to JSON file in artifacts directory

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Sources/ReportGenerator.swift`

**Dependencies**: T061

---

### T063: Add CLI options

**Description**: Extend Swift runner with command-line argument parsing.

**Options**:
- [X] `--corpus <file>`: Path to corpus JSON (required)
- [X] `--c-reference <file>`: Path to C reference report (required)
- [X] `--artifacts <dir>`: Output directory for artifacts (default: ./artifacts/)
- [X] `--cases <id1,id2>`: Filter to specific case IDs (optional)
- [X] `--tags <tag1,tag2>`: Filter by tags (optional)
- [X] `--pass-gate <0-1>`: Pass rate threshold (default: 0.95)
- [X] `--run-id <id>`: Custom run ID (default: timestamp-based)
- [X] `--swift-version <ver>`: Explicit Swift version (else: detect)
- [X] `--target-sdk <name>`: Target SDK for provenance (else: detect)

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Sources/main.swift`

**Dependencies**: T059-T062

---

### T064: Wire Makefile target in specs/005-c-algo-parity

**Description**: Add build targets for Swift runner.

**Acceptance Criteria**:
- [X] Create Makefile in `specs/005-c-algo-parity/tools/swift-parity-runner/`
- [X] Target `make build` builds Swift binary (release mode)
- [X] Target `make clean` removes artifacts
- [X] Target `make test` runs Swift unit tests
- [X] Main Makefile in `specs/005-c-algo-parity/` includes swift targets
- [X] All targets work from repo root or specs dir

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/Makefile`

**Dependencies**: T059-T063

---

### T065: Create integration tests for Swift runner

**Description**: Test Swift runner against fixture corpus.

**Acceptance Criteria**:
- [X] Create fixture corpus (minimal, 1-2 cases)
- [X] Create fixture C reference report
- [X] Test Swift runner with fixture inputs
- [X] Verify output JSON structure matches schema
- [X] Test with all CLI options (case filter, tags, pass gate)
- [X] Test error handling (missing corpus, invalid reference)
- [X] Confirm artifacts directory created and populated

**Location**: `specs/005-c-algo-parity/tools/swift-parity-runner/tests/integration_tests.sh`

**Dependencies**: T059-T063

---

## Phase 9c: Execution & Validation

### T066: Run Swift parity against default corpus

**Description**: Execute Swift runner on default corpus.

**Acceptance Criteria**:
- [X] Swift runner builds successfully
- [X] Runs against `corpus/default.json`
- [X] Uses C reference from `artifacts/full-run-default/report.json`
- [X] Outputs report to `artifacts/swift-parity-default/report.json`
- [X] Report shows 3 cases processed
- [X] Confirm 100% pass rate (3/3 passed)
- [X] Per-case deltas all approximately 0.0

**Duration**: < 1 second execution

**Dependencies**: T059-T064

---

### T067: Run Swift parity against edge cases

**Description**: Execute Swift runner on edge cases corpus.

**Acceptance Criteria**:
- [X] Runs against `corpus/edge-cases.json`
- [X] Uses C reference from `artifacts/full-run-edge/report.json`
- [X] Outputs report to `artifacts/swift-parity-edge/report.json`
- [X] Report shows 4 cases processed
- [X] Confirm 100% pass rate (4/4 passed)
- [X] Per-case deltas all approximately 0.0
- [X] Summary stats show mean ΔE = 0.0

**Duration**: < 1 second execution

**Dependencies**: T066

---

### T068: Verify per-case artifacts match expected deltas

**Description**: Inspect generated artifacts for correctness.

**Acceptance Criteria**:
- [X] Each failing case (if any) has artifacts directory
- [X] Each artifact includes: inputs.json, swift_output.json, c_reference.json, deltas.json
- [X] deltas.json shows computed differences for each color
- [X] All deltas ≈ 0.0 (within numerical precision)
- [X] metadata.json includes provenance (Swift version, commit, platform)
- [X] HTML or markdown report generated for easy viewing (optional)

**Dependencies**: T066-T067

---

### T069: Run unit + integration tests, confirm all passing

**Description**: Execute full test suite.

**Acceptance Criteria**:
- [X] `swift test` runs all unit tests from T051-T058
- [X] All unit tests pass
- [X] Integration tests (T065) run and pass
- [X] No test failures reported
- [X] Code coverage > 80% for parity-specific code

**Duration**: < 5 seconds

**Dependencies**: T058, T065

---

### T070: Document sample run in artifacts/swift-parity-sample/README.md

**Description**: Create human-readable summary of sample run.

**Acceptance Criteria**:
- [X] README explains run purpose and results
- [X] Include command executed
- [X] Summary table: total cases, passed, failed, pass rate
- [X] Per-case results with status (PASS/FAIL)
- [X] Statistical analysis (mean, stddev, percentiles)
- [X] Links to full report.json and per-case artifacts
- [X] Notes on what perfect parity means and implications

**Location**: `specs/005-c-algo-parity/artifacts/swift-parity-sample/README.md`

**Dependencies**: T066-T069

---

## Phase 9d: Documentation & CI

### T071: Update quickstart with Swift runner CLI usage

**Description**: Add Swift-specific sections to existing quickstart.

**Acceptance Criteria**:
- [ ] Document how to build Swift runner
- [ ] Show complete example CLI invocation
- [ ] Explain all CLI options and defaults
- [ ] Include troubleshooting section (build errors, missing dependencies)
- [ ] Show how to interpret report output

**Location**: `specs/005-c-algo-parity/quickstart.md`

**Dependencies**: T059-T063

---

### T072: Add Swift wrapper testing guide to documentation

**Description**: Create new guide explaining Swift wrapper validation strategy.

**Acceptance Criteria**:
- [ ] Explain why Swift wrapper testing is necessary
- [ ] Describe test architecture (unit, integration, E2E)
- [ ] Document data marshaling validation
- [ ] Explain comparison methodology
- [ ] Describe tolerance policy
- [ ] Include example output (redacted report)

**Location**: `specs/005-c-algo-parity/SWIFT_TESTING_GUIDE.md`

**Dependencies**: T071

---

### T073: Document expected outputs and tolerance policy

**Description**: Clarify what "perfect parity" means for Swift wrapper.

**Acceptance Criteria**:
- [ ] Explain why Swift deltas should be ~0.0
- [ ] Document acceptable floating-point error margins
- [ ] Note any known limitations (e.g., Float vs Double on specific platforms)
- [ ] Provide examples of pass/fail scenarios
- [ ] Include decision tree for troubleshooting failures

**Location**: `specs/005-c-algo-parity/config/README.md` (add Swift section)

**Dependencies**: T072

---

### T074: Create GitHub Actions workflow for Swift parity

**Description**: Build CI workflow specifically for this branch.

**Acceptance Criteria**:
- [ ] Workflow file: `.github/workflows/swift-parity.yml`
- [ ] Triggers on pushes to `005-c-algo-parity` branch only
- [ ] Triggers on PRs to `005-c-algo-parity` branch only
- [ ] Steps: checkout, setup Swift, build C runner, run C parity, build Swift runner, run Swift parity
- [ ] Uploads artifacts on failure
- [ ] Checks pass rate >= 95%
- [ ] Reports clear success/failure

**Location**: `.github/workflows/swift-parity.yml`

**Dependencies**: T071-T073

---

### T075: Integrate Swift parity into existing `.github/workflows/`

**Description**: Ensure Swift parity runs automatically.

**Acceptance Criteria**:
- [ ] Workflow added to repository
- [ ] First test push to `005-c-algo-parity` triggers workflow
- [ ] Workflow completes successfully
- [ ] Artifacts visible in GitHub Actions UI
- [ ] Status badge can be added to README (optional)

**Location**: `.github/workflows/swift-parity.yml`

**Dependencies**: T074

---

## Phase 9e: Final Review

### T076: Review generated reports for summary and per-case artifacts

**Description**: Manual inspection of parity reports.

**Acceptance Criteria**:
- [ ] Read default corpus report summary
- [ ] Read edge cases report summary
- [ ] Confirm both show 100% pass rate
- [ ] Inspect 2-3 per-case artifact bundles
- [ ] Verify artifact structure and completeness
- [ ] Note any anomalies or unexpected patterns

**Duration**: 15-20 minutes

**Dependencies**: T066-T070

---

### T077: Analyze results and document findings

**Description**: Write comprehensive review of Swift wrapper parity.

**Acceptance Criteria**:
- [ ] Document findings in `swift-review.md`
- [ ] Summarize test coverage (unit, integration, E2E)
- [ ] Confirm perfect parity achieved (0 failures)
- [ ] Analyze any deviations (if found)
- [ ] Validate data marshaling accuracy
- [ ] Confirm output fidelity
- [ ] Note implications for wrapper reliability

**Location**: `specs/005-c-algo-parity/swift-review.md`

**Dependencies**: T076

---

### T078: Verify CI integration (workflow runs on branch pushes)

**Description**: Confirm GitHub Actions workflow is operational.

**Acceptance Criteria**:
- [ ] Make test commit to `005-c-algo-parity` branch
- [ ] GitHub Actions workflow triggers automatically
- [ ] Workflow completes (either pass or fail)
- [ ] Artifacts are uploaded
- [ ] Status reported in PR or commit

**Duration**: Depends on CI queue (typically < 5 min)

**Dependencies**: T074-T075

---

### T079: Plan follow-ups

**Description**: Document next steps and future work.

**Acceptance Criteria**:
- [ ] Assess readiness for CocoaPods validation
- [ ] Identify additional platforms to test (Android?, Windows?)
- [ ] Plan corpus expansion (parametric sweeps, real-world cases)
- [ ] Estimate effort for continuous integration improvements
- [ ] Document success criteria and acceptance thresholds

**Location**: `specs/005-c-algo-parity/swift-review.md` (next steps section)

**Dependencies**: T077

---

## Parallel Execution Notes

**Can run in parallel**:
- T051-T054 (all unit test implementations)
- T055-T057 (all test implementations)
- T059-T062 (runner components)
- T066-T067 (corpus executions)

**Execution order dependencies**:
- T051 → T052-T058
- T059-T062 → T063
- T063 → T064-T065
- T065 → T066-T069

---

## Completion Criteria

**Phase 9 is complete when**:
1. ✅ All unit tests pass (T051-T058)
2. ✅ All integration tests pass (T059-T065, T069)
3. ✅ Full corpus runs successful (T066-T067)
4. ✅ 100% pass rate achieved (default + edge cases)
5. ✅ Documentation complete (T071-T073)
6. ✅ CI workflow operational (T074-T075, T078)
7. ✅ Review and findings documented (T076-T077)
8. ✅ Follow-up actions planned (T079)

---

## References

- [Phase 9 Specification](phase-9-swift-parity.md)
- [Swift API](../../Sources/ColorJourney/ColorJourney.swift)
- [C Parity Results](../artifacts/full-run-default/report.json)
- [Test Corpus](../corpus/)
- [Tolerance Policy](../config/README.md)
