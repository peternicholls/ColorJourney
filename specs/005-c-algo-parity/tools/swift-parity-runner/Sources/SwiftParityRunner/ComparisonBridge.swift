import Foundation
import ColorJourney
import CColorJourney

struct ComparisonBridge {
    let tolerance: Tolerance

    func runComparisons(corpus: CorpusFile, reference: [String: [OKLabColor]], options: CLIOptions) throws -> (cases: [CaseResult], deltas: [Double]) {
        let filteredCases = filterCases(corpus.cases, options: options)
        var results: [CaseResult] = []
        var allDeltaE: [Double] = []

        for testCase in filteredCases {
            let swiftPalette = try generatePalette(for: testCase)
            guard let referencePalette = reference[testCase.id] else {
                // Missing reference, mark as failed with no samples
                results.append(
                    CaseResult(
                        inputCaseId: testCase.id,
                        passed: false,
                        maxDeltaE: .infinity,
                        meanDeltaE: 0,
                        stddevDeltaE: 0,
                        samples: []
                    )
                )
                continue
            }

            let limit = min(swiftPalette.count, referencePalette.count)
            var samples: [CaseSampleResult] = []
            var casePassed = true
            var caseMaxDeltaE = 0.0
            var caseDeltaEs: [Double] = []

            for index in 0..<limit {
                let swiftColor = swiftPalette[index]
                let refColor = referencePalette[index]
                let deltas = computeDeltas(swift: swiftColor, reference: refColor)
                let passed = tolerance.contains(deltas)
                casePassed = casePassed && passed
                caseMaxDeltaE = max(caseMaxDeltaE, deltas.deltaE)
                caseDeltaEs.append(deltas.deltaE)
                allDeltaE.append(deltas.deltaE)

                let sample = CaseSampleResult(
                    index: index,
                    delta: DeltaValue(l: deltas.l, a: deltas.a, b: deltas.b),
                    deltaE: deltas.deltaE,
                    canonical: refColor,
                    alternate: swiftColor
                )
                samples.append(sample)
            }

            let result = CaseResult(
                inputCaseId: testCase.id,
                passed: casePassed,
                maxDeltaE: caseMaxDeltaE,
                meanDeltaE: mean(caseDeltaEs),
                stddevDeltaE: stddev(caseDeltaEs),
                samples: samples
            )
            results.append(result)
        }

        return (results, allDeltaE)
    }

    // MARK: - Helpers

    private func filterCases(_ cases: [CorpusCase], options: CLIOptions) -> [CorpusCase] {
        cases.filter { testCase in
            if let caseFilter = options.caseFilter, !caseFilter.contains(testCase.id) { return false }
            if let tagFilter = options.tagFilter {
                let tags = Set(testCase.tags ?? [])
                if tags.isDisjoint(with: tagFilter) { return false }
            }
            return true
        }
    }

    private func generatePalette(for testCase: CorpusCase) throws -> [OKLabColor] {
        let anchors = testCase.anchors.map { anchor -> ColorJourneyRGB in
            switch anchor.representation {
            case .rgb(let rgb):
                return ColorJourneyRGB(red: Float(rgb.r), green: Float(rgb.g), blue: Float(rgb.b))
            case .oklab(let lab):
                let labStruct = CJ_Lab(L: Float(lab.l), a: Float(lab.a), b: Float(lab.b))
                let rgb = cj_rgb_clamp(cj_oklab_to_rgb(labStruct))
                return ColorJourneyRGB(red: rgb.r, green: rgb.g, blue: rgb.b)
            }
        }

        guard !anchors.isEmpty else { throw CorpusParserError.missingAnchors(testCase.id) }

        let config = buildConfig(from: testCase.config, anchors: anchors, seed: testCase.seed)
        let journey = ColorJourney(config: config)
        let palette = journey.discrete(count: testCase.config.count)
        return palette.map { OKLabColor(rgb: $0) }
    }

    private func buildConfig(from corpus: CorpusConfig, anchors: [ColorJourneyRGB], seed: UInt64) -> ColorJourneyConfig {
        // Match C parity runner behavior: enable variation if variationSeed is present
        let variationEnabled = corpus.variationSeed != nil
        let variationSeed = corpus.variationSeed ?? seed
        
        return ColorJourneyConfig(
            anchors: anchors,
            lightness: .custom(weight: Float(corpus.lightness)),
            chroma: .custom(multiplier: Float(corpus.chroma)),
            contrast: .custom(threshold: Float(corpus.contrast)),
            midJourneyVibrancy: Float(corpus.vibrancy),
            temperature: temperatureBias(from: corpus.temperature),
            loopMode: loopMode(from: corpus.loopMode),
            variation: VariationConfig(
                enabled: variationEnabled,
                dimensions: [.hue, .lightness, .chroma],
                strength: .noticeable,
                seed: variationSeed
            )
        )
    }

    private func temperatureBias(from value: Double) -> TemperatureBias {
        if value == 0 { return .neutral }
        return value > 0 ? .warm : .cool
    }

    private func loopMode(from value: String) -> LoopMode {
        switch value.lowercased() {
        case "open": return .open
        case "closed": return .closed
        case "pingpong": return .pingPong
        default: return .open
        }
    }

    private func computeDeltas(swift: OKLabColor, reference: OKLabColor) -> DeltaMetrics {
        let lDelta = swift.l - reference.l
        let aDelta = swift.a - reference.a
        let bDelta = swift.b - reference.b

        let relative: (Double, Double) -> Double = { current, ref in
            guard ref != 0 else { return 0 }
            return abs(current - ref) / abs(ref)
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

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }

    private func stddev(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let avg = mean(values)
        let variance = values.reduce(0) { $0 + pow($1 - avg, 2) } / Double(values.count)
        return sqrt(variance)
    }
}
