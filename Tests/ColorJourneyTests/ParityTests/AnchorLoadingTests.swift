import XCTest
@testable import ColorJourney

final class AnchorLoadingTests: XCTestCase {
    private let parser = CorpusParser()

    func testLoadsOKLabAnchors() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let caseUnderTest = try XCTUnwrap(corpus.cases.first { $0.id == "baseline-wheel" })

        let anchors = try caseUnderTest.anchorRGB()
        XCTAssertEqual(anchors.count, 1)

        let normalized = normalizePalette(anchors)
        XCTAssertEqual(normalized.count, 1)
        XCTAssertEqual(normalized.first?.l ?? 0, 0.62, accuracy: 1e-3)
        XCTAssertEqual(normalized.first?.a ?? 0, 0.05, accuracy: 1e-3)
        XCTAssertEqual(normalized.first?.b ?? 0, 0.02, accuracy: 1e-3)

        XCTAssertEqual(caseUnderTest.seed, 424242)
        XCTAssertEqual(Set(caseUnderTest.tags ?? []), ["baseline", "oklab", "wheel"])
        XCTAssertEqual(caseUnderTest.notes, "Single-anchor OKLab wheel for deterministic coverage")
    }

    func testLoadsRGBAnchors() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let caseUnderTest = try XCTUnwrap(corpus.cases.first { $0.id == "rgb-boundary" })

        let anchors = try caseUnderTest.anchorRGB()
        XCTAssertEqual(anchors.count, 2)
        XCTAssertEqual(anchors[0].red, 0.0, accuracy: 1e-6)
        XCTAssertEqual(anchors[1].blue, 1.0, accuracy: 1e-6)

        let journeyConfig = try caseUnderTest.toColorJourneyConfig()
        XCTAssertEqual(journeyConfig.anchors.count, 2)
        XCTAssertEqual(journeyConfig.loopMode, .open)
    }

    func testMultiAnchorMixedRepresentations() throws {
        let corpus = try parser.parse(url: fixtureURL(named: "default.json"))
        let caseUnderTest = try XCTUnwrap(corpus.cases.first { $0.id == "seeded-multi-anchor" })

        let anchors = try caseUnderTest.anchorRGB()
        XCTAssertEqual(anchors.count, 3)
        let normalized = normalizePalette(anchors)
        XCTAssertEqual(normalized.count, 3)
    }

    // MARK: - Helpers

    private func fixtureURL(named file: String) -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("specs/005-c-algo-parity/corpus/\(file)")
    }
}
