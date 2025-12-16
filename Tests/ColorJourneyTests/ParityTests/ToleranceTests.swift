import XCTest
@testable import ColorJourney

final class ToleranceTests: XCTestCase {
    func testAbsoluteTolerancePassesWhenUnderThresholds() {
        let tolerance = Tolerance.default
        let deltas = DeltaMetrics(
            l: 5e-5,
            a: 5e-5,
            b: 5e-5,
            deltaE: 0.25,
            relL: 5e-4,
            relA: 5e-4,
            relB: 5e-4
        )

        XCTAssertTrue(tolerance.contains(deltas))
    }

    func testFailsWhenDeltaEExceedsTolerance() {
        let tolerance = Tolerance.default
        let deltas = DeltaMetrics(
            l: 0,
            a: 0,
            b: 0,
            deltaE: tolerance.absDeltaE + 0.01,
            relL: 0,
            relA: 0,
            relB: 0
        )

        XCTAssertFalse(tolerance.contains(deltas))
    }

    func testRelativeToleranceEnforced() {
        let tolerance = Tolerance.default
        let deltas = DeltaMetrics(
            l: 0,
            a: 0,
            b: 0,
            deltaE: 0,
            relL: tolerance.relL + 1e-4,
            relA: 0,
            relB: 0
        )

        XCTAssertFalse(tolerance.contains(deltas))
    }

    func testPassRateCalculation() {
        let deltas: [DeltaMetrics] = [
            DeltaMetrics(l: 0, a: 0, b: 0, deltaE: 0, relL: 0, relA: 0, relB: 0),
            DeltaMetrics(l: 5e-5, a: 5e-5, b: 5e-5, deltaE: 0.4, relL: 5e-4, relA: 5e-4, relB: 5e-4),
            DeltaMetrics(l: 0, a: 0, b: 0, deltaE: 0.6, relL: 0, relA: 0, relB: 0)
        ]

        let tolerance = Tolerance.default
        let passCount = deltas.filter { tolerance.contains($0) }.count
        let passRate = Double(passCount) / Double(deltas.count)
        XCTAssertEqual(passRate, 2.0 / 3.0, accuracy: 1e-9)
    }
}
