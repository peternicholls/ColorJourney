import XCTest
@testable import ColorJourney
import CColorJourney

final class ColorConversionTests: XCTestCase {
    func testRGBToOKLabMatchesCReference() {
        let rgb = ColorJourneyRGB(red: 0.8, green: 0.2, blue: 0.1)
        let labFromHelper = OKLabColor(rgb: rgb)

        let cLab = cj_rgb_to_oklab(CJ_RGB(r: rgb.red, g: rgb.green, b: rgb.blue))
        XCTAssertEqual(labFromHelper.l, Double(cLab.L), accuracy: 1e-9)
        XCTAssertEqual(labFromHelper.a, Double(cLab.a), accuracy: 1e-9)
        XCTAssertEqual(labFromHelper.b, Double(cLab.b), accuracy: 1e-9)
    }

    func testRoundTripOKLabToRGBAndBack() {
        // Values sourced from Phase 8 C parity artifacts (baseline-wheel case, index 0)
        let referenceLab = OKLabColor(l: 0.7061368227005005, a: 0.04555131122469902, b: 0.014189556241035461)
        let roundTripped = OKLabColor(rgb: referenceLab.toRGB())

        XCTAssertEqual(roundTripped.l, referenceLab.l, accuracy: 1e-6)
        XCTAssertEqual(roundTripped.a, referenceLab.a, accuracy: 1e-6)
        XCTAssertEqual(roundTripped.b, referenceLab.b, accuracy: 1e-6)
    }

    func testBoundaryColorsRoundTrip() {
        let boundaryColors: [ColorJourneyRGB] = [
            ColorJourneyRGB(red: 0.0, green: 0.0, blue: 0.0),
            ColorJourneyRGB(red: 1.0, green: 1.0, blue: 1.0),
            ColorJourneyRGB(red: 0.0, green: 1.0, blue: 0.0)
        ]

        for rgb in boundaryColors {
            let lab = OKLabColor(rgb: rgb)
            let roundTrip = OKLabColor(rgb: lab.toRGB())
            XCTAssertEqual(roundTrip.l, lab.l, accuracy: 1e-6)
            XCTAssertEqual(roundTrip.a, lab.a, accuracy: 1e-6)
            XCTAssertEqual(roundTrip.b, lab.b, accuracy: 1e-6)
        }
    }
}
