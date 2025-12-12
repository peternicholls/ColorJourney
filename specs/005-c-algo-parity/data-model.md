# Data Model

## Entities

### InputCase
- Fields: `id` (string UUID), `tags` (string array), `anchors` (array of RGB/OKLab triplets), `config` (lightness/chroma/contrast/vibrancy/temperature, loopMode, variation seed, count), `seed` (uint64), `corpusVersion` (string), `notes` (string optional).
- Validation: anchors must be valid sRGB (0–1) or OKLab doubles; `count` > 0; seeds required for determinism; tags optional but unique per case.
- Relationships: referenced by ComparisonResult and RunReport.

### EngineOutput
- Fields: `engine` (enum: CCore|Wasm), `commit` (string hash), `buildFlags` (string array), `platform` (string), `outputs` (array of OKLab triples + RGB u8), `durationMs` (float), `provenance` (timestamp, corpusVersion).
- Validation: outputs length matches InputCase count; OKLab values finite doubles; RGB within 0–255.
- Relationships: tied to one InputCase; two instances (one per engine) feed a ComparisonResult.

### ComparisonResult
- Fields: `inputCaseId` (string), `cOutputRef`, `wasmOutputRef`, `deltas` (per-index: OKLab delta components, ΔE, RGB deltas), `tolerance` (abs/rel per channel + ΔE thresholds), `status` (pass|fail), `topContributors` (ordered list of channels/metrics with magnitude), `artifactsPath` (string).
- Validation: status derives from deltas vs tolerance; artifactsPath required when status=fail; tolerance captured in report header and per-case snapshot.
- Relationships: aggregates two EngineOutputs; referenced by RunReport.

### RunReport
- Fields: `runId` (UUID), `timestamp`, `corpusVersion`, `cCommit`, `wasmCommit`, `buildFlags` (both engines), `platform` (runner OS/CPU), `summary` (total cases, passes, fails, histograms), `failures` (array of ComparisonResult ids), `artifactsRoot` (path/URI), `ciMetadata` (job URL, branch).
- Validation: corpusVersion required; commits and build flags required for reproducibility; summary totals must match ComparisonResult counts.
- Relationships: owns ComparisonResults; links to artifacts on disk/CI.

## State Transitions
- Run lifecycle: `queued` → `running` → `completed` (pass|fail). Fail if any ComparisonResult.status = fail.
- InputCase evolution: corpus version increments when cases added/modified; RunReport records the corpusVersion used.

## Derived Metrics
- ΔE (OKLab Euclidean) per output pair.
- Histograms: distribution of ΔE and per-channel absolute error.
- Top contributors: highest magnitude deltas (OKLab L/a/b, ΔE, RGB) per failing case.
