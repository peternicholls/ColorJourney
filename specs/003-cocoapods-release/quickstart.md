```markdown
# Quickstart — CocoaPods Release

**Reference**: Based on proven [HexColor](https://github.com/kevinabram111/HexColor) Xcode-native pattern and [HexColor publishing guide](https://kevinabram1000.medium.com/how-to-build-and-share-your-own-swift-library-with-swift-package-manager-1905fcc4716b)

## Prerequisites
- Xcode 12+ with Swift 5.9 toolchain
- Ruby with CocoaPods 1.10.0+ installed (`gem install cocoapods`)
- Git tag for the release (e.g., `1.0.0`, no 'v' prefix) pushed to origin
- CocoaPods Trunk token available as environment variable `COCOAPODS_TRUNK_TOKEN`
- Existing SPM release flow from feature 002

## Local Validation (HexColor Pattern)

### Step 1: Lint podspec locally
```bash
pod spec lint ColorJourney.podspec --verbose
```
✅ Should pass with zero errors and zero warnings

### Step 2: Test pod install with local sources (optional)
```bash
cd Examples/CocoaPodsDemo
pod install --repo-update
```
✅ Should succeed without build errors
✅ Verify `import ColorJourney` works in the generated Xcode workspace
✅ Open `CocoaPodsDemo.xcworkspace` to verify compilation and preview Usage.swift examples

### Step 3: Check version parity
```bash
# Confirm podspec version matches git tag (with 'v' prefix)
PODSPEC_VERSION=$(grep "spec.version" ColorJourney.podspec | sed 's/.*"\([^"]*\)".*/\1/')
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "none")

echo "Podspec version: $PODSPEC_VERSION"
echo "Git tag: $GIT_TAG"
echo "Expected tag format: v${PODSPEC_VERSION}"

# Verify tag exists with 'v' prefix
git tag | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$"
```

## Publish to CocoaPods Trunk (Manual Fallback - HexColor Approach)

### Step 1: Export token
```bash
export COCOAPODS_TRUNK_TOKEN=<your-token>
```

### Step 2: Lint one more time (safety check)
```bash
pod spec lint ColorJourney.podspec --verbose --allow-warnings=false
```

### Step 3: Push to CocoaPods Trunk
```bash
pod trunk push ColorJourney.podspec --verbose
```

### Step 4: Verify listing
Visit https://cocoapods.org/pods/ColorJourney or run:
```bash
pod search ColorJourney
```
✅ New version should appear within 10 minutes

## CI/CD Integration (GitHub Actions - Expected)

The release workflow will be extended to:
1) Run `pod spec lint ColorJourney.podspec --verbose` as a gate (must pass before push)
2) Run `pod trunk push ColorJourney.podspec` using secret `COCOAPODS_TRUNK_TOKEN`
3) Fail the entire release if lint or trunk push fails (coordinated with SPM release)

## User Installation (CocoaPods)

### Add to Podfile
```ruby
pod 'ColorJourney', '~> 1.2'  # Using version pinning
```

### Or with specific version
```ruby
pod 'ColorJourney', '1.2.0'   # Pin to exact version
```

### Run pod install
```bash
pod install
```

### Import and use
```swift
import ColorJourney

let palette = ColorJourney.generatePalette(...)  // API as per documentation
```

## User Installation (SPM - Unchanged)

For comparison, existing SPM installation:

### In Xcode: File > Add Packages
Paste: `https://github.com/peternicholls/ColorJourney.git`  
Select: `Up to Next Major Version` from `1.2.0`

Or in Package.swift:
```swift
.package(url: "https://github.com/peternicholls/ColorJourney.git", from: "1.2.0")
```

## Troubleshooting

### If lint fails: ❌
- Check `public_header_files` paths match `Sources/CColorJourney/include/*.h`
- Verify deployment targets: iOS 13.0+, macOS 10.15+
- Ensure C headers are included and publicly accessible
- Run `pod lib lint ColorJourney.podspec --verbose` for more detail

### If trunk push fails: ❌
- Verify `COCOAPODS_TRUNK_TOKEN` is valid: `pod trunk me`
- Check that lint passed first
- Ensure git tag `X.Y.Z` (no 'v') exists on origin
- Try dry-run: `pod trunk push ColorJourney.podspec --allow-warnings --verbose`

### If install is slow: ⏱️
- Compare against SPM install time; target within 20% difference
- Clear local CocoaPods caches: `rm -rf ~/.cocoapods/repos/trunk/`
- Check network connectivity to GitHub and CocoaPods.org

## Design Philosophy (Xcode-Native)

ColorJourney follows the HexColor pattern:
- **Package.swift at repository root** (matches folder name)
- **Minimal, clean structure** for maintenance
- **Single git tag** consumed by both SPM and CocoaPods
- **No 'v' prefix** in version tags (SPM requirement)
- **Public APIs marked explicitly** (C headers + Swift wrappers)

This ensures:
✅ Easy to develop locally  
✅ Consistent with Xcode guidelines  
✅ Simple for contributors to understand  
✅ Maximum compatibility across package managers
```
