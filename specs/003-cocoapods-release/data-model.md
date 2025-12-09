```markdown
# Data Model — CocoaPods Release

## Entities

### Podspec
- Fields: name (ColorJourney), version (SemVer), summary, description, homepage, license, authors, source (git URL + tag), swift_version, ios.deployment_target, osx.deployment_target, source_files, public_header_files, preserve_paths
- Validation: `pod spec lint` must succeed; version must match git tag and SPM release; headers must resolve; deployment targets iOS ≥13.0, macOS ≥10.15

### ReleaseVersion
- Fields: semantic_version (MAJOR.MINOR.PATCH), git_tag (X.Y.Z without 'v' prefix), release_notes (CHANGELOG), parity_with_spm (bool)
- Relationships: Podspec.source.tag references ReleaseVersion.git_tag
- Validation: parity_with_spm must be true; CHANGELOG entry must exist for the version

### PlatformTarget
- Fields: ios_min (13.0), macos_min (10.15)
- Validation: Values must align with podspec and README installation docs; lint must pass for all declared platforms

### CIJob
- Types: pod_spec_lint, pod_trunk_push
- Fields: job_name, inputs (podspec path, trunk token secret), outputs (lint status, publication URL), status
- Validation: pod_spec_lint must succeed before pod_trunk_push; push blocked if lint fails

### CredentialSecret
- Fields: trunk_token (stored in CI secret store), owner_email
- Validation: Token present in CI runtime; not committed to repo; rotation procedure documented in playbook

## Relationships
- Podspec uses PlatformTarget values for deployment targets
- Podspec references ReleaseVersion via git tag
- CIJob pod_spec_lint consumes Podspec; CIJob pod_trunk_push depends on successful lint
- CredentialSecret required by pod_trunk_push

## State/Transitions
- Draft podspec → Linted → Published
- ReleaseVersion draft → Tagged → Published (SPM) → Published (CocoaPods)
- CIJob pod_spec_lint: pending → success/fail; pod_trunk_push: pending (gated on lint success) → success/fail
```
