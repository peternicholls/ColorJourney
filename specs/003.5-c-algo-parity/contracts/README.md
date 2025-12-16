# Contracts and API Reference

This directory contains the API specifications and data schemas for the C Algorithm Parity Testing framework.

## Files

- **parity-api.yaml**: OpenAPI 3.1 specification for the parity runner HTTP API (future extension)
- **../corpus/schema.json**: JSON Schema for corpus input files
- **../config/tolerances.example.json**: Reference tolerance configuration

## API Overview

The parity framework provides both a CLI interface (implemented) and a future HTTP API (specified in parity-api.yaml for reference).

### Current CLI Interface

The parity runner is invoked as a command-line tool:

```bash
parity-runner --corpus <file> --tolerances <file> [options]
```

See [../quickstart.md](../quickstart.md) for complete CLI documentation.

### Future HTTP API (Reference)

The `parity-api.yaml` specification defines a potential HTTP interface for:
- Queueing and managing parity runs
- Retrieving run status and summaries
- Accessing detailed per-case comparison results
- Downloading failure artifacts

This specification serves as a reference for future API development and ensures consistency in data structures between CLI and potential HTTP implementations.

## Data Schemas

### Corpus Schema

Location: `../corpus/schema.json`

Defines the structure of corpus input files used to drive parity tests.

**Key types:**
- `Corpus`: Top-level container with version and cases
- `InputCase`: Individual test case with anchors, config, seed
- `Anchor`: Color specification (OKLab and/or sRGB)
- `Config`: Generation parameters (count, lightness, chroma, etc.)

**Version format:** `vYYYYMMDD.n` (date-based with monotonic suffix)

**Validation rules:**
- Version must match across corpus header and all cases
- Each case requires stable ID, anchors, config, and seed
- Anchors must provide at least one color representation
- Config must specify expected palette count

### Tolerance Schema

Location: `../config/tolerances.example.json`

Defines acceptable differences between engine outputs.

**Structure:**
```json
{
  "toleranceVersion": "vYYYYMMDD.n",
  "abs": {
    "l": number,
    "a": number,
    "b": number,
    "deltaE": number
  },
  "rel": {
    "l": number,
    "a": number,
    "b": number
  },
  "policy": {
    "failThreshold": number,
    "notes": string
  }
}
```

**Validation:**
- Absolute tolerances apply to OKLab channel differences
- Relative tolerances apply as fraction of reference value
- DeltaE tolerance uses deltaE76 metric
- Policy defines pass/fail thresholds and rationale

### Report Format

Reports follow the `RunStatus` and `ComparisonResult` schemas from `parity-api.yaml`.

**Report structure:**
```json
{
  "runId": "uuid",
  "state": "completed|failed",
  "summary": {
    "totalCases": number,
    "passed": number,
    "failed": number,
    "histograms": {...},
    "topContributors": [...]
  },
  "provenance": {
    "cCommit": "hash",
    "wasmCommit": "hash",
    "buildFlags": [...],
    "corpusVersion": "vYYYYMMDD.n",
    "platform": "string"
  },
  "results": [
    {
      "inputCaseId": "string",
      "status": "pass|fail",
      "tolerance": {...},
      "deltas": [...],
      "topContributors": [...],
      "artifactsPath": "path"
    }
  ]
}
```

### Artifact Structure

Per-case artifacts are stored under `artifacts/<runId>/<caseId>/`:

```
artifacts/
└── <runId>/
    ├── report.json               # Overall run report
    ├── summary.json              # Quick summary stats
    └── <caseId>/                 # Per-case artifacts (failures only by default)
        ├── inputs.json           # Original input case
        ├── c_output.json         # Canonical engine output
        ├── alt_output.json       # Alternate engine output
        ├── deltas.json           # Per-color differences
        ├── hints.json            # Analysis and contributors
        └── metadata.json         # Provenance
```

## Key Types and Definitions

### InputCase
Corpus test case with deterministic inputs.

**Required fields:**
- `id`: Stable identifier
- `anchors`: Color anchors (OKLab/sRGB)
- `config`: Generation parameters
- `seed`: Deterministic seed
- `corpusVersion`: Version string

**Optional fields:**
- `tags`: Filtering/grouping tags
- `notes`: Human-readable context

### ComparisonResult
Output comparison for a single case.

**Fields:**
- `inputCaseId`: Reference to input case
- `status`: pass|fail
- `tolerance`: Applied tolerances
- `deltas[]`: Per-color OKLab/deltaE differences
- `topContributors[]`: Ranked failure causes
- `artifactsPath`: Location of detailed artifacts
- `provenance`: Execution metadata

### DeltaEntry
Per-color difference metrics.

**Fields:**
- `index`: Color position in palette
- `okLabDelta`: {l, a, b} absolute differences
- `deltaE`: DeltaE76 distance
- `rgbDelta`: {r, g, b} differences (optional)

### Contributor
Analysis of failure causes.

**Fields:**
- `metric`: Channel or metric name (e.g., "deltaE", "okLab.l")
- `magnitude`: Absolute difference value
- `direction`: "higher" | "lower"

### Provenance
Execution metadata for reproducibility.

**Required:**
- `cCommit`: Canonical engine git commit
- `wasmCommit`: Alternate engine git commit
- `corpusVersion`: Input corpus version

**Optional:**
- `buildFlags[]`: Compiler flags used
- `platform`: OS/hardware identifier
- `toleranceOverrides`: CLI override values

## Usage Examples

### Validate Corpus Against Schema

```bash
# Using jsonschema-cli or similar
jsonschema -i corpus/default.json corpus/schema.json
```

### Generate Test Corpus

```python
import json

corpus = {
    "corpusVersion": "v20251212.0",
    "description": "Test corpus",
    "cases": [
        {
            "id": "test_case",
            "corpusVersion": "v20251212.0",
            "tags": ["baseline"],
            "anchors": [
                {"oklab": {"l": 0.5, "a": 0.0, "b": 0.0}}
            ],
            "config": {"count": 5},
            "seed": 42
        }
    ]
}

with open("corpus/test.json", "w") as f:
    json.dump(corpus, f, indent=2)
```

### Parse Report Output

```python
import json

with open("artifacts/<runId>/report.json") as f:
    report = json.load(f)
    
print(f"Pass rate: {report['summary']['passed'] / report['summary']['totalCases']}")
print(f"Failed cases: {[r['inputCaseId'] for r in report['results'] if r['status'] == 'fail']}")
```

## Testing Contracts

The parity runner includes validation tests that ensure:
1. Corpus files match `schema.json`
2. Tolerance files are well-formed
3. Reports conform to `parity-api.yaml` schemas
4. Artifacts include all required files

Run validation tests:
```bash
make -C tools/parity-runner test
```

## References

- [Quickstart Guide](../quickstart.md) - CLI usage and examples
- [Configuration Guide](../config/README.md) - Tolerance and corpus versioning
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.0) - API schema standard
- [JSON Schema](https://json-schema.org/specification) - Data validation standard
