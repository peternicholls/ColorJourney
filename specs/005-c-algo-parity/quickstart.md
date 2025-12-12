# Quickstart

1. **Install toolchains**
   - C (required): `clang` or `gcc` with C99 support. Verify with `cc --version` and `cc -std=c99 -v`. Run `make test-c` from repo root to confirm the C harness builds and tests pass.
   - Swift (optional for wrapper tests): Xcode 15 / Swift 5.9 for `swift test`.

2. **Build C reference binary**
   - Preferred: `make test-c` (verifies the core math and produces C artifacts).
   - Direct build (for parity emitter): `gcc -std=c99 Sources/CColorJourney/ColorJourney.c -I Sources/CColorJourney/include -lm -o .build/parity-c-ref`.

3. **Prepare corpus**
   - Add/inspect JSON fixtures under `specs/005-c-algo-parity/corpus/`.
   - Each case includes anchors, config, seed, and expected count.

4. **Run parity suite**
   - Build the C parity runner: `make -C specs/005-c-algo-parity/tools/parity-runner parity-runner`.
   - Execute the binary against the corpus: `./specs/005-c-algo-parity/tools/parity-runner/parity-runner --corpus specs/005-c-algo-parity/corpus/default.json --tolerances specs/005-c-algo-parity/config/tolerances.example.json --artifacts specs/005-c-algo-parity/artifacts/<runId>/`.
   - Configure tolerances and case filters via CLI flags (e.g., `--cases boundary,default --tolerance-deltaE 0.5`).

5. **Review results**
   - Open the generated report JSON/HTML for summary, then inspect per-case artifacts for failures (inputs, both outputs, deltas, top contributors).
   - Capture provenance (commits, build flags, corpus version) in the report header for reproducibility.
