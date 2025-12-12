# Parity Artifacts

This directory is the root for parity run outputs. Each run should create a timestamped/UUID folder (e.g., `specs/005-c-algo-parity/artifacts/2025-12-12T00-00-00Z/`) containing:

- `report.json` — run-level summary (corpus version, provenance, totals, pass/fail gate).
- `cases/<caseId>/` — per-case payloads including inputs, both engine outputs, deltas, and hints.
- `logs/` — optional stdout/stderr or build logs for the C and wasm invocations.

Keep this README committed; per-run contents should be git-ignored to avoid noise while preserving directory structure for CI uploads.
