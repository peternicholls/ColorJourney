import XCTest
@testable import ColorJourney

final class ParameterMappingTests: XCTestCase {
    private let parser = CorpusParser()

    func testMapsNumericParametersToConfig() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let baseline = try XCTUnwrap(corpus.cases.first { $0.id == "baseline-wheel" })
        let config = try baseline.toColorJourneyConfig()

        switch config.lightness {
        case .custom(let weight):
            XCTAssertEqual(weight, 0.5, accuracy: 1e-6)
        default:
            XCTFail("Expected custom lightness mapping")
        }

        switch config.chroma {
        case .custom(let multiplier):
            XCTAssertEqual(multiplier, 0.9, accuracy: 1e-6)
        default:
            XCTFail("Expected custom chroma mapping")
        }

        switch config.contrast {
        case .custom(let threshold):
            XCTAssertEqual(threshold, 0.12, accuracy: 1e-6)
        default:
            XCTFail("Expected custom contrast mapping")
        }

        XCTAssertEqual(config.midJourneyVibrancy, 0.4, accuracy: 1e-6)
        XCTAssertEqual(config.temperature, .neutral)
        XCTAssertEqual(config.loopMode, .closed)
    }

    func testTemperatureMappingFromCorpus() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let warmCase = try XCTUnwrap(corpus.cases.first { $0.id == "seeded-multi-anchor" })
        let warmConfig = try warmCase.toColorJourneyConfig()
        XCTAssertEqual(warmConfig.temperature, .warm)

        let edgeCorpus = try parser.parse(url: fixtureURL(named: "edge-cases.json"))
        let coolCase = try XCTUnwrap(edgeCorpus.cases.first { $0.id == "low-lightness" })
        let coolConfig = try coolCase.toColorJourneyConfig()
        XCTAssertEqual(coolConfig.temperature, .cool)
    }

    func testPaletteSizeMatchesCorpusCount() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let rgbCase = try XCTUnwrap(corpus.cases.first { $0.id == "rgb-boundary" })
        let config = try rgbCase.toColorJourneyConfig()
        let journey = ColorJourney(config: config)
        let palette = journey.discrete(count: rgbCase.config.count)
        XCTAssertEqual(palette.count, rgbCase.config.count)
    }

    // MARK: - Helpers

    private func fixtureURL(named file: String) -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("specs/005-c-algo-parity/corpus/\(file)")
    }
}
