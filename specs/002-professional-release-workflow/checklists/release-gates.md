# Release Gates Checklist: Professional Release Workflow

**Purpose**: Formal release-gate requirements quality review focused on branch/RC workflow semantics, artifact cleanliness, and SemVer/badge documentation.
**Created**: 2025-12-09
**Feature**: [specs/002-professional-release-workflow/spec.md](specs/002-professional-release-workflow/spec.md)

## Requirement Completeness

- [x] CHK001 Are branch protection requirements specified for `develop`, `main`, and `release-candidate/*`, including required checks and merge restrictions? [Completeness, Spec §FR-016]
- [x] CHK002 Are naming, creation source, and deletion rules for RC branches fully documented (create from develop, pattern `release-candidate/X.Y.Z-rc.N`, delete after promotion/abandonment)? [Completeness, Spec §FR-003; Spec §FR-018]
- [x] CHK003 Are promotion rules to `main` including tag creation, changelog updates, and prohibition of `main` → `develop` merges specified end-to-end? [Completeness, Spec §FR-005; Spec §FR-006]
- [x] CHK004 Are required CI/CD checks for RC branches (unit, integration, build verification) explicitly enumerated with gating expectations? [Completeness, Spec §FR-004]

## Requirement Clarity

- [x] CHK005 Is the SemVer tagging scheme clearly defined (prefix, format, increment rules for breaking vs non-breaking changes)? [Clarity, Spec §FR-005; Spec §FR-009]
- [x] CHK006 Are artifact contents for Swift releases explicitly scoped to allowed items (Sources, Package.swift, README, LICENSE, CHANGELOG, Docs) and exclusions? [Clarity, Spec §FR-007]
- [x] CHK007 Are artifact contents for C releases explicitly scoped to allowed items (headers, static `.a`, optional C examples, Docs) and exclusions? [Clarity, Spec §FR-008]

## Requirement Consistency

- [x] CHK008 Are independent Swift vs C versioning rules consistent with dependency mapping requirements for Swift releases? [Consistency, Spec §FR-009]
- [x] CHK009 Are README badge requirements (which badges are essential, auto-update behavior) consistent across documentation and automation expectations? [Consistency, Spec §FR-011; Spec §FR-012]

## Acceptance Criteria Quality

- [x] CHK010 Are success criteria for RC workflow throughput (e.g., <30 minutes end-to-end) measurable and tied to CI timing requirements? [Acceptance Criteria, Spec §SC-003]
- [x] CHK011 Are measurable outcomes for badge update latency defined and traceable to automation steps? [Acceptance Criteria, Spec §SC-006]

## Scenario Coverage

- [x] CHK012 Are scenarios covering failed RC tests and subsequent rc.N increments documented with required steps and governance? [Coverage, Spec §User Story 2; Spec §FR-015]
- [x] CHK013 Are scenarios for simultaneous Swift and C releases, including unified announcements and dependency mapping, addressed? [Coverage, Spec §User Story 4; Spec §FR-009]

## Edge Case Coverage

- [x] CHK014 Is handling of abandoned RCs and superseded branches documented, including changelog/tag treatment? [Edge Case, Spec §User Story 2; Spec §FR-018]
- [x] CHK015 Is recovery behavior defined for partial or failed artifact generation (e.g., one platform build fails) before tagging a release? [Edge Case, Spec §FR-019; Spec §SC-013]

## Non-Functional Requirements

- [x] CHK016 Are reproducibility/determinism requirements for builds and artifacts stated, including allowable toolchain versions and variance tolerances? [Non-Functional, Spec §NFR-001; Spec §SC-014]

## Dependencies & Assumptions

- [x] CHK017 Are external service dependencies (GitHub Actions, branch protection permissions, artifact hosting) listed with readiness checks before release gating? [Dependency, Spec §Assumptions]

## Ambiguities & Conflicts

- [x] CHK018 Are rules about excluding DevDocs/examples consistent between Swift and C artifacts, with no conflicting inclusions across FR-007/FR-008? [Ambiguity, Spec §FR-007; Spec §FR-008]

## Notes

- Check items off as completed: `[x]`
- Add findings inline. Each run of `/speckit.checklist` creates a new checklist file.
