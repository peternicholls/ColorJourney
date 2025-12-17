# Research

- Decision: Parity compares two C builds: canonical C core (baseline) vs alternate C build (Sources/wasm compiled as plain C).
  Rationale: Constitution mandates the C core as canonical; focusing on C-only avoids wasm/runtime concerns.
  Alternatives considered: Treating wasm-specific pipeline as distinct runtime (not needed for pure parity of the C math).

- Decision: Implement the parity runner as a CLI orchestrator that shells out to both C binaries, producing JSON outputs for comparison.
  Rationale: Keeps tooling minimal and deterministic; avoids embedding additional runtimes.
  Alternatives considered: Embedding comparisons in Swift tests (mixes concerns); adding JS/Node layer (unnecessary for pure C parity).

- Decision: Define the corpus as JSON fixtures versioned under specs/003.5-c-algo-parity/corpus/, covering baseline palettes, boundary values, seeded random cases, and web-demo samples; track corpus version in reports.
  Rationale: JSON is language-agnostic and reviewable; supports deterministic snapshots.
  Alternatives considered: Binary fixtures (harder to diff); dynamic generation only (hurts reproducibility).

- Decision: Normalize both outputs to OKLab (double precision) before diffing, then emit per-channel deltas plus derived metrics (ΔE, RGB deltas) with configurable absolute/relative tolerances.
  Rationale: Aligns with constitutional OKLab requirement, prevents space-specific drift, and surfaces perceptual relevance.
  Alternatives considered: Raw sRGB comparison (less perceptual); single tolerance (misses channel nuance).
