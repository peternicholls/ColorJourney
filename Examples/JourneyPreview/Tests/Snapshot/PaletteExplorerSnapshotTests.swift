import XCTest
@testable import JourneyPreview
import ColorJourney

/// Snapshot tests for the Palette Explorer view and SwatchGrid component.
///
/// These tests verify visual consistency of the UI components.
final class PaletteExplorerSnapshotTests: XCTestCase {
    
    // MARK: - Swatch Grid Tests
    
    func testSwatchGridRendersCorrectNumberOfSwatches() {
        // Given
        let colors: [ColorJourneyRGB] = (0..<8).map { i in
            ColorJourneyRGB(red: Float(i) / 8, green: 0.5, blue: 0.5)
        }
        let swatches = SwatchDisplay.fromPalette(colors, size: .medium, showLabels: true)
        
        // Then
        XCTAssertEqual(swatches.count, 8)
        XCTAssertEqual(swatches[0].label, "0")
        XCTAssertEqual(swatches[7].label, "7")
    }
    
    func testSwatchDisplayHexConversion() {
        // Given
        let color = ColorJourneyRGB(red: 1.0, green: 0.0, blue: 0.5)
        let swatch = SwatchDisplay(index: 0, color: color, size: .medium)
        
        // Then
        XCTAssertEqual(swatch.hexString, "#FF007F")
    }
    
    func testSwatchDisplayRGBConversion() {
        // Given
        let color = ColorJourneyRGB(red: 0.5, green: 0.5, blue: 0.5)
        let swatch = SwatchDisplay(index: 0, color: color, size: .medium)
        
        // Then
        XCTAssertEqual(swatch.rgbString, "rgb(127, 127, 127)")
    }
    
    func testSwatchSizeCornerRadius() {
        // Small
        XCTAssertEqual(SwatchSizePreference.small.cornerRadius, 8)
        // Medium
        XCTAssertEqual(SwatchSizePreference.medium.cornerRadius, 12)
        // Large
        XCTAssertEqual(SwatchSizePreference.large.cornerRadius, 16)
        // Extra Large
        XCTAssertEqual(SwatchSizePreference.extraLarge.cornerRadius, 20)
    }
    
    func testSwatchTextColorForLightBackground() {
        // Given - light color
        let lightColor = ColorJourneyRGB(red: 0.9, green: 0.9, blue: 0.9)
        let swatch = SwatchDisplay(index: 0, color: lightColor, size: .medium)
        
        // Then - should prefer dark text
        XCTAssertTrue(swatch.prefersDarkText)
    }
    
    func testSwatchTextColorForDarkBackground() {
        // Given - dark color
        let darkColor = ColorJourneyRGB(red: 0.1, green: 0.1, blue: 0.1)
        let swatch = SwatchDisplay(index: 0, color: darkColor, size: .medium)
        
        // Then - should prefer light text
        XCTAssertFalse(swatch.prefersDarkText)
    }
    
    // MARK: - Advisory Tests
    
    func testAdvisoryTypeIcons() {
        XCTAssertEqual(AdvisoryType.info.iconName, "info.circle.fill")
        XCTAssertEqual(AdvisoryType.warning.iconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(AdvisoryType.error.iconName, "xmark.octagon.fill")
        XCTAssertEqual(AdvisoryType.success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(AdvisoryType.performance.iconName, "gauge.with.needle.fill")
    }
}
