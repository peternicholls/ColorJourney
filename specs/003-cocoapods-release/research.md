```markdown
# Phase 0 Research — CocoaPods Release

## Decisions

### Decision: Ship a single podspec that includes Swift wrapper and C core
- **Rationale**: Ensures deterministic behavior identical to SPM by building from the same sources; avoids binary drift; keeps C core canonical. Maintains portability and OKLab guarantees.
- **Alternatives considered**: Binary XCFramework distribution (rejected for determinism and size); Swift-only pod excluding C core (rejected because wrapper depends on C core and would violate portability principle).

### Decision: Platform minimums iOS 13.0, macOS 10.15
- **Rationale**: Aligns with Swift 5.9 baseline and existing project targets; avoids legacy deployment complexity while covering modern devices.
- **Alternatives considered**: Lowering to iOS 12 / macOS 10.14 (rejected due to toolchain and SwiftUI constraints); raising to iOS 14 (rejected to avoid excluding viable users without benefit).

### Decision: Version parity with SPM and git tags
- **Rationale**: Prevents divergence between package managers; simplifies support and documentation; keeps semantic versioning consistent with constitution API stability.
- **Alternatives considered**: Independent pod versioning (rejected—adds confusion and coordination cost); branch-based source without tags (rejected—breaks reproducibility).

### Decision: Validate with `pod spec lint` and gate release on success
- **Rationale**: Ensures podspec correctness and dependency inclusion; catches platform or header misconfiguration before publishing.
- **Alternatives considered**: Manual lint in local dev (rejected—non-repeatable); skipping lint in CI (rejected—risk of broken releases).

### Decision: Automate `pod trunk push` in release workflow
- **Rationale**: Reduces manual error, keeps parity with SPM release cadence, and enforces gates (fail CI if push fails).
- **Alternatives considered**: Manual trunk push from maintainer laptop (rejected—credential and reproducibility risk); private spec repo (rejected—public discoverability required).

### Decision: Credentials via environment secrets in CI
- **Rationale**: Keeps trunk token out of repo; compatible with GitHub Actions secrets; avoids local state dependence.
- **Alternatives considered**: Committing `.netrc` or trunk session (rejected—security risk); prompting for manual input (rejected—breaks automation).

### Decision: README documents SPM and CocoaPods side-by-side
- **Rationale**: Minimizes onboarding friction; avoids bias toward one manager; keeps badge expectations from 002 workflow intact.
- **Alternatives considered**: Separate doc page (rejected—discoverability); CocoaPods-only section below fold (rejected—visibility requirement).

### Decision: Use source-only distribution (no prebuilt libs)
- **Rationale**: Matches SPM model; preserves determinism and portability; avoids binary signing/notarization overhead.
- **Alternatives considered**: Prebuilt static libs or XCFrameworks (rejected—larger artifacts, more CI complexity, less transparency).

### Decision: Include public headers explicitly via `public_header_files`
- **Rationale**: Ensures C API visibility for Swift bridging and any potential Objective-C interop; avoids accidental header omissions.
- **Alternatives considered**: Wildcard-only source_files without explicit headers (rejected—risk of missing headers or including private ones).

## Research Outcomes / Clarifications
- No open NEEDS CLARIFICATION items. All core parameters are set: platform mins, version parity, automation approach, credential handling, distribution model, and documentation placement.

## Risks to monitor
- Trunk push failures due to 2FA/session expiry → mitigate with fresh token in CI secret and dry-run lint before push.
- Pod install performance variance vs SPM → monitor install times in sample app; ensure within 20% target.
- Header path drift if source layout changes → keep podspec synced with `Sources/CColorJourney/include` and add CI check.
```
