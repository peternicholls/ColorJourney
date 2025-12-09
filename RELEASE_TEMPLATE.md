# Release Entry Template

When cutting a new release, create a new section following this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features, presets, or public APIs

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes or corrections

### Deprecated
- Features marked for removal in future versions

### Removed
- Features or APIs removed in this release

### Security
- Security-related fixes or disclosures

### Performance
- Performance improvements or optimizations

### Notes
- Swift version requirement: ≥X.Y
- C core version requirement: ≥X.Y.Z
- Platform support: [list platforms with minimum versions]
```

**Guidelines**:
- Use semantic versioning for all releases (MAJOR.MINOR.PATCH)
- Tag releases as `vX.Y.Z` (e.g., `v1.0.0`)
- Include version mapping note: "Requires C core ≥vX.Y.Z" for Swift releases
- Link to GitHub releases: `[X.Y.Z]: https://github.com/peternicholls/ColorJourney/releases/tag/vX.Y.Z`
- Document breaking changes clearly in the release notes
- For multi-language releases, separate [C] and [Swift] sections if versions differ