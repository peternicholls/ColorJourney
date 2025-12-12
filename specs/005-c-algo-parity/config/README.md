# Parity Tolerance and Corpus Policy

## Tolerance Defaults
- Default tolerance set: abs L/a/b = 1e-4, abs ΔE = 0.5, rel L/a/b = 1e-3.
- Source of truth: `tolerances.example.json` (versioned via `toleranceVersion`).
- Policy: Runs exceeding ΔE or per-channel tolerances must fail; overrides are allowed per run or case when justified and recorded in provenance.

## Override Rules
- CLI should accept override files/flags to tweak tolerances for debugging; production/CI must pin to a reviewed tolerance file.
- Document overrides in run artifacts (report header + per-case snapshot).
- Never loosen tolerances without bumping `toleranceVersion` and recording rationale in `policy.notes`.

## Corpus Versioning
- Format: `vYYYYMMDD.n` (date-based with monotonic integer suffix).
- Every edit to corpus fixtures increments the suffix; resets when the date changes.
- `corpusVersion` must match across the corpus header and every `inputCase` entry; validation rejects mismatches.

## Validation Expectations
- The parity runner validates both the corpus version and tolerance version before execution.
- Schema alignment: see `corpus/schema.json` for structural rules; the runner enforces the same version regex and required fields.
- Reports must record the corpus version, tolerance version, and provenance (commits, platform, build flags) for determinism.
