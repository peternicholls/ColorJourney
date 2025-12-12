# Parity Tolerance and Corpus Policy

## Tolerance Defaults
- Default tolerance set: abs L/a/b = 1e-4, abs ΔE = 0.5, rel L/a/b = 1e-3.
- Source of truth: `tolerances.example.json` (versioned via `toleranceVersion`).
- Policy: Runs exceeding ΔE or per-channel tolerances must fail; overrides are allowed per run or case when justified and recorded in provenance.

## Tolerance Configuration Format

The tolerance file is a JSON document with the following structure:

```json
{
  "toleranceVersion": "v20251212.0",
  "description": "Human-readable description",
  "abs": {
    "l": 0.0001,
    "a": 0.0001,
    "b": 0.0001,
    "deltaE": 0.5
  },
  "rel": {
    "l": 0.001,
    "a": 0.001,
    "b": 0.001
  },
  "policy": {
    "failThreshold": 0.5,
    "notes": "Rationale for these tolerances"
  },
  "provenance": {
    "source": "path/to/this/file",
    "updated": "2025-12-12T00:00:00Z"
  }
}
```

### Field Descriptions

- **toleranceVersion** (required): Version identifier in the form `vYYYYMMDD.n`
- **description** (optional): Human-readable summary of this tolerance configuration
- **abs** (required): Absolute tolerances for OKLab channels and deltaE
  - `l`, `a`, `b`: Per-channel absolute differences
  - `deltaE`: Maximum allowed deltaE76 distance
- **rel** (required): Relative tolerances for OKLab channels (as fraction of value)
- **policy** (optional): Policy metadata
  - `failThreshold`: Maximum acceptable deltaE before failure
  - `notes`: Rationale and context
- **provenance** (optional): Tracking information
  - `source`: Source file path
  - `updated`: Last modification timestamp (ISO 8601)

## Override Rules
- CLI should accept override files/flags to tweak tolerances for debugging; production/CI must pin to a reviewed tolerance file.
- Document overrides in run artifacts (report header + per-case snapshot).
- Never loosen tolerances without bumping `toleranceVersion` and recording rationale in `policy.notes`.

### CLI Override Examples

**Per-channel overrides:**
```bash
parity-runner --tolerances config/tolerances.example.json \
  --tolerance-deltaE 1.0 \
  --tolerance-l 0.001
```

**Complete tolerance file override:**
```bash
parity-runner --tolerances config/tolerances.debug.json
```

**Override provenance tracking:**
All CLI overrides are recorded in the run report under `provenance.toleranceOverrides`.

## Corpus Versioning
- Format: `vYYYYMMDD.n` (date-based with monotonic integer suffix).
- Every edit to corpus fixtures increments the suffix; resets when the date changes.
- `corpusVersion` must match across the corpus header and every `inputCase` entry; validation rejects mismatches.

### Version Increment Rules

1. **Same day edits**: Increment suffix (e.g., `v20251212.0` → `v20251212.1`)
2. **New day**: Reset suffix (e.g., `v20251212.5` → `v20251213.0`)
3. **Breaking changes**: Always bump and document in corpus description
4. **Validation**: Runner enforces version consistency across all cases

### Corpus File Structure

```json
{
  "corpusVersion": "v20251212.0",
  "description": "Default test corpus",
  "cases": [
    {
      "id": "case_id",
      "corpusVersion": "v20251212.0",
      "tags": ["baseline", "monochrome"],
      "anchors": [...],
      "config": {...},
      "seed": 42,
      "notes": "Optional context"
    }
  ]
}
```

## Validation Expectations
- The parity runner validates both the corpus version and tolerance version before execution.
- Schema alignment: see `corpus/schema.json` for structural rules; the runner enforces the same version regex and required fields.
- Reports must record the corpus version, tolerance version, and provenance (commits, platform, build flags) for determinism.

## Best Practices

1. **Version discipline**: Always bump versions when changing tolerances or corpus
2. **Provenance tracking**: Record all changes with timestamps and rationale
3. **CI stability**: Pin specific tolerance/corpus versions in CI; avoid "latest"
4. **Override documentation**: Document any overrides in run artifacts
5. **Tolerance tightening**: Prefer tightening over loosening; justify loosening with data
6. **Corpus completeness**: Ensure corpus covers baseline, boundary, and edge cases
7. **Reproducibility**: Lock commits, build flags, and platform info in provenance
