import Foundation
import CColorJourney
@testable import ColorJourney

// Shared support types for Swift wrapper parity testing.

// MARK: - Corpus Models

struct CorpusFile: Codable {
    let corpusVersion: String
    let description: String?
    let cases: [CorpusCase]

    func validated() throws -> CorpusFile {
        guard !cases.isEmpty else {
            throw CorpusParserError.emptyCorpus
        }

        for testCase in cases {
            if testCase.corpusVersion != corpusVersion {
                throw CorpusParserError.versionMismatch(expected: corpusVersion, found: testCase.corpusVersion)
            }
        }

        return self
    }
}

struct CorpusCase: Codable {
    let id: String
    let tags: [String]?
    let anchors: [CorpusAnchor]
    let config: CorpusConfig
    let seed: UInt64
    let corpusVersion: String
    let notes: String?

    func anchorRGB() throws -> [ColorJourneyRGB] {
        guard !anchors.isEmpty else {
            throw CorpusParserError.missingAnchors(id)
        }

        return anchors.map { anchor in
            switch anchor.representation {
            case .rgb(let rgb):
                return ColorJourneyRGB(red: Float(rgb.r), green: Float(rgb.g), blue: Float(rgb.b))
            case .oklab(let lab):
                return lab.toRGB()
            }
        }
    }

    func toColorJourneyConfig() throws -> ColorJourneyConfig {
        let rgbAnchors = try anchorRGB()
        return config.toColorJourneyConfig(anchors: rgbAnchors)
    }
}

struct CorpusAnchor: Codable {
    let oklab: OKLabJSON?
    let rgb: RGBJSON?

    enum Representation {
        case oklab(OKLabJSON)
        case rgb(RGBJSON)
    }

    var representation: Representation {
        if let oklab {
            return .oklab(oklab)
        }
        if let rgb {
            return .rgb(rgb)
        }
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

    func toColorJourneyConfig(anchors: [ColorJourneyRGB]) -> ColorJourneyConfig {
        let config = ColorJourneyConfig(
            anchors: anchors,
            lightness: .custom(weight: Float(lightness)),
            chroma: .custom(multiplier: Float(chroma)),
            contrast: .custom(threshold: Float(contrast)),
            midJourneyVibrancy: Float(vibrancy),
            temperature: temperatureBias,
            loopMode: loopModeEnum,
            variation: VariationConfig(enabled: false, dimensions: [], strength: .subtle, seed: variationSeed ?? 0x123456789ABCDEF0)
        )

        return config
    }

    private var temperatureBias: TemperatureBias {
        if temperature == 0 { return .neutral }
        return temperature > 0 ? .warm : .cool
    }

    private var loopModeEnum: LoopMode {
        switch loopMode.lowercased() {
        case "open": return .open
        case "closed": return .closed
        case "pingpong": return .pingPong
        default: return .open
        }
    }
}

struct OKLabJSON: Codable, Equatable {
    let l: Double
    let a: Double
    let b: Double

    func toRGB() -> ColorJourneyRGB {
        let lab = CJ_Lab(L: Float(l), a: Float(a), b: Float(b))
        let rgb = cj_oklab_to_rgb(lab)
        let clamped = cj_rgb_clamp(rgb)
        return ColorJourneyRGB(red: clamped.r, green: clamped.g, blue: clamped.b)
    }
}

struct RGBJSON: Codable, Equatable {
    let r: Double
    let g: Double
    let b: Double
}

// MARK: - Parser

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
            return try decoded.validated()
        } catch let error as CorpusParserError {
            throw error
        } catch {
            throw CorpusParserError.malformed(error.localizedDescription)
        }
    }
}

// MARK: - OKLab helpers

struct OKLabColor: Equatable {
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

// MARK: - Delta + Tolerance

struct DeltaMetrics {
    let l: Double
    let a: Double
    let b: Double
    let deltaE: Double
    let relL: Double
    let relA: Double
    let relB: Double
}

struct Tolerance {
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

func computeDeltas(swift: OKLabColor, reference: OKLabColor) -> DeltaMetrics {
    let lDelta = swift.l - reference.l
    let aDelta = swift.a - reference.a
    let bDelta = swift.b - reference.b

    let relative: (Double, Double) -> Double = { current, reference in
        guard reference != 0 else { return 0 }
        return abs(current - reference) / abs(reference)
    }

    let deltaE = swift.deltaE(to: reference)

    return DeltaMetrics(
        l: lDelta,
        a: aDelta,
        b: bDelta,
        deltaE: deltaE,
        relL: relative(swift.l, reference.l),
        relA: relative(swift.a, reference.a),
        relB: relative(swift.b, reference.b)
    )
}

func normalizePalette(_ palette: [ColorJourneyRGB]) -> [OKLabColor] {
    palette.map { OKLabColor(rgb: $0) }
}
