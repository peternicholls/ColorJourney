import Foundation
import CColorJourney
import ColorJourney

// Corpus and configuration models (shared with C parity corpus format)
struct CorpusFile: Codable {
    let corpusVersion: String
    let description: String?
    let cases: [CorpusCase]
}

struct CorpusCase: Codable {
    let id: String
    let tags: [String]?
    let anchors: [CorpusAnchor]
    let config: CorpusConfig
    let seed: UInt64
    let corpusVersion: String
    let notes: String?
}

struct CorpusAnchor: Codable {
    let oklab: OKLabJSON?
    let rgb: RGBJSON?

    enum Representation {
        case oklab(OKLabJSON)
        case rgb(RGBJSON)
    }

    var representation: Representation {
        if let lab = oklab { return .oklab(lab) }
        if let rgb = rgb { return .rgb(rgb) }
        return .rgb(RGBJSON(r: 0, g: 0, b: 0))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        oklab = try container.decodeIfPresent(OKLabJSON.self, forKey: .oklab)
        rgb = try container.decodeIfPresent(RGBJSON.self, forKey: .rgb)
        if oklab == nil && rgb == nil {
            throw CorpusParserError.invalidAnchorRepresentation
        }
    }
}

struct CorpusConfig: Codable {
    let count: Int
    let lightness: Double
    let chroma: Double
    let contrast: Double
    let vibrancy: Double
    let temperature: Double
    let loopMode: String
    let variationSeed: UInt64?
}

struct OKLabJSON: Codable, Equatable {
    let l: Double
    let a: Double
    let b: Double
}

struct RGBJSON: Codable, Equatable {
    let r: Double
    let g: Double
    let b: Double
}

// Parser
enum CorpusParserError: LocalizedError {
    case emptyCorpus
    case missingAnchors(String)
    case versionMismatch(expected: String, found: String)
    case invalidAnchorRepresentation
    case malformed(String)

    var errorDescription: String? {
        switch self {
        case .emptyCorpus:
            return "Corpus contains no test cases"
        case .missingAnchors(let id):
            return "Corpus case \(id) has no anchors"
        case .versionMismatch(let expected, let found):
            return "Corpus version mismatch: expected \(expected) got \(found)"
        case .invalidAnchorRepresentation:
            return "Anchor must provide oklab or rgb"
        case .malformed(let message):
            return message
        }
    }
}

struct CorpusParser {
    func parse(url: URL) throws -> CorpusFile {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CorpusFile.self, from: data)
            guard !decoded.cases.isEmpty else { throw CorpusParserError.emptyCorpus }
            for testCase in decoded.cases {
                if testCase.corpusVersion != decoded.corpusVersion {
                    throw CorpusParserError.versionMismatch(expected: decoded.corpusVersion, found: testCase.corpusVersion)
                }
            }
            return decoded
        } catch let error as CorpusParserError {
            throw error
        } catch {
            throw CorpusParserError.malformed(error.localizedDescription)
        }
    }
}

// OKLab helpers
struct OKLabColor: Equatable, Codable {
    let l: Double
    let a: Double
    let b: Double

    init(l: Double, a: Double, b: Double) {
        self.l = l
        self.a = a
        self.b = b
    }

    init(rgb: ColorJourneyRGB) {
        let lab = cj_rgb_to_oklab(CJ_RGB(r: rgb.red, g: rgb.green, b: rgb.blue))
        self.l = Double(lab.L)
        self.a = Double(lab.a)
        self.b = Double(lab.b)
    }

    func toRGB() -> ColorJourneyRGB {
        let lab = CJ_Lab(L: Float(l), a: Float(a), b: Float(b))
        let rgb = cj_rgb_clamp(cj_oklab_to_rgb(lab))
        return ColorJourneyRGB(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    func deltaE(to other: OKLabColor) -> Double {
        let lhs = CJ_Lab(L: Float(l), a: Float(a), b: Float(b))
        let rhs = CJ_Lab(L: Float(other.l), a: Float(other.a), b: Float(other.b))
        return Double(cj_delta_e(lhs, rhs))
    }
}

struct DeltaMetrics: Codable {
    let l: Double
    let a: Double
    let b: Double
    let deltaE: Double
    let relL: Double
    let relA: Double
    let relB: Double
}

struct Tolerance: Codable {
    let absL: Double
    let absA: Double
    let absB: Double
    let absDeltaE: Double
    let relL: Double
    let relA: Double
    let relB: Double

    static let `default` = Tolerance(
        absL: 1e-4,
        absA: 1e-4,
        absB: 1e-4,
        absDeltaE: 0.5,
        relL: 1e-3,
        relA: 1e-3,
        relB: 1e-3
    )

    func contains(_ delta: DeltaMetrics) -> Bool {
        guard delta.deltaE <= absDeltaE else { return false }
        guard abs(delta.l) <= absL, abs(delta.a) <= absA, abs(delta.b) <= absB else { return false }
        guard delta.relL <= relL, delta.relA <= relA, delta.relB <= relB else { return false }
        return true
    }
}

// CLI options
struct CLIOptions {
    let corpusPath: String
    let referencePath: String
    let artifactsPath: String
    let caseFilter: Set<String>?
    let tagFilter: Set<String>?
    let passGate: Double
    let runId: String
    let swiftVersion: String
    let targetSDK: String?
}

struct ParsedPalette {
    let caseId: String
    let oklab: [OKLabColor]
}

// Reference report models (subset of C parity report)
struct ReferenceReport: Decodable {
    let corpusVersion: String
    let cases: [ReferenceCase]
}

struct ReferenceCase: Decodable {
    let inputCaseId: String
    let samples: [ReferenceSample]
}

struct ReferenceSample: Decodable {
    let index: Int
    let canonical: OKLabTriplet
}

struct OKLabTriplet: Decodable {
    let l: Double
    let a: Double
    let b: Double
}

// Comparison output models
struct CaseSampleResult: Codable {
    let index: Int
    let delta: DeltaValue
    let deltaE: Double
    let canonical: OKLabColor
    let alternate: OKLabColor
}

struct DeltaValue: Codable {
    let l: Double
    let a: Double
    let b: Double
}

struct CaseResult: Codable {
    let inputCaseId: String
    let passed: Bool
    let maxDeltaE: Double
    let meanDeltaE: Double
    let stddevDeltaE: Double
    let samples: [CaseSampleResult]
}

struct SummaryStats: Codable {
    let mean: Double
    let stddev: Double
    let p50: Double
    let p95: Double
    let p99: Double
    let min: Double
    let max: Double
}

struct RunSummary: Codable {
    let totalCases: Int
    let passed: Int
    let failed: Int
    let passRate: Double
    let deltaE: SummaryStats
}

struct Provenance: Codable {
    let corpusVersion: String
    let swiftVersion: String
    let targetSDK: String?
    let platform: String
    let referencePath: String
}

struct RunReport: Codable {
    let runId: String
    let corpusVersion: String
    let state: String
    let passGate: Double
    let passRate: Double
    let durationMs: Double
    let startedAt: String
    let finishedAt: String
    let withinPassGate: Bool
    let summary: RunSummary
    let cases: [CaseResult]
    let provenance: Provenance
    let artifactsRoot: String
}
