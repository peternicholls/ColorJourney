import XCTest
@testable import ColorJourney

final class CorpusParserTests: XCTestCase {
    private let parser = CorpusParser()

    func testParsesDefaultCorpus() throws {
        let url = fixtureURL(named: "default.json")
        let corpus = try parser.parse(url: url)
        XCTAssertEqual(corpus.cases.count, 3)
        XCTAssertEqual(corpus.corpusVersion, "v20251212.1")
        XCTAssertEqual(Set(corpus.cases.map { $0.id }), ["baseline-wheel", "rgb-boundary", "seeded-multi-anchor"])
    }

    func testParsesEdgeCasesCorpus() throws {
        let url = fixtureURL(named: "edge-cases.json")
        let corpus = try parser.parse(url: url)
        XCTAssertEqual(corpus.cases.count, 4)
        XCTAssertEqual(corpus.cases.first?.corpusVersion, corpus.corpusVersion)
    }

    func testRejectsMalformedCorpus() throws {
        let malformed = """
        { "corpusVersion": "v20251212.1", "cases": [{ "id": "bad", "anchors": [{}], "config": {"count": 1, "lightness": 0.0, "chroma": 1.0, "contrast": 0.1, "vibrancy": 0.0, "temperature": 0.0, "loopMode": "open"}, "seed": 1, "corpusVersion": "v20251212.0" }] }
        """
        let url = try writeTempFile(named: "malformed-corpus.json", contents: malformed)

        XCTAssertThrowsError(try parser.parse(url: url)) { error in
            guard let corpusError = error as? CorpusParserError else {
                return XCTFail("Unexpected error type: \(error)")
            }
            switch corpusError {
            case .invalidAnchorRepresentation, .versionMismatch:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected error: \(corpusError)")
            }
        }
    }

    // MARK: - Helpers

    private func fixtureURL(named file: String) -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("specs/003.5-c-algo-parity/corpus/\(file)")
    }

    private func writeTempFile(named: String, contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(named)
        try contents.data(using: .utf8)?.write(to: url)
        return url
    }
}
