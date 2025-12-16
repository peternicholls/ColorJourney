import XCTest
@testable import ColorJourney
import CColorJourney

final class OutputNormalizationTests: XCTestCase {
    private let parser = CorpusParser()

    func testNormalizationProducesFiniteOKLab() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let baseline = try XCTUnwrap(corpus.cases.first)
        let config = try baseline.toColorJourneyConfig()
        let journey = ColorJourney(config: config)

        let palette = journey.discrete(count: baseline.config.count)
        let normalized = normalizePalette(palette)

        XCTAssertEqual(normalized.count, baseline.config.count)
        for color in normalized {
            XCTAssert(color.l.isFinite)
            XCTAssert(color.a.isFinite)
            XCTAssert(color.b.isFinite)
            XCTAssertGreaterThanOrEqual(color.l, 0)
            XCTAssertLessThanOrEqual(color.l, 1)
        }
    }

    func testNormalizationMatchesCCoreConversion() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "edge-cases.json"))
        let edgeCase = try XCTUnwrap(corpus.cases.first { $0.id == "high-chroma" })
        let journey = ColorJourney(config: try edgeCase.toColorJourneyConfig())
        let palette = journey.discrete(count: edgeCase.config.count)

        for rgb in palette {
            let normalized = OKLabColor(rgb: rgb)
            let reference = cj_rgb_to_oklab(CJ_RGB(r: rgb.red, g: rgb.green, b: rgb.blue))
            XCTAssertEqual(normalized.l, Double(reference.L), accuracy: 1e-9)
            XCTAssertEqual(normalized.a, Double(reference.a), accuracy: 1e-9)
            XCTAssertEqual(normalized.b, Double(reference.b), accuracy: 1e-9)
        }
    }

    private func fixtureURL(named file: String) -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("specs/005-c-algo-parity/corpus/\(file)")
    }
}
