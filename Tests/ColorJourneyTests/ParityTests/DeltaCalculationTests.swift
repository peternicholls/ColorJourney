import XCTest
@testable import ColorJourney

final class DeltaCalculationTests: XCTestCase {
    func testDeltaCalculationMatchesExpected() {
        let reference = OKLabColor(l: 0.5, a: 0.1, b: -0.05)
        let candidate = OKLabColor(l: 0.50005, a: 0.1001, b: -0.0499)

        let deltas = computeDeltas(swift: candidate, reference: reference)
        XCTAssertGreaterThan(deltas.deltaE, 0)
        XCTAssertLessThan(deltas.deltaE, 0.001)
        XCTAssertEqual(deltas.l, 0.00005, accuracy: 1e-6)
        XCTAssertEqual(deltas.a, 0.0001, accuracy: 1e-6)
        XCTAssertEqual(deltas.b, 0.0001, accuracy: 1e-6)
    }

    func testZeroDeltaForIdenticalColors() {
        let reference = OKLabColor(l: 0.7061368227005005, a: 0.04555131122469902, b: 0.014189556241035461)
        let deltas = computeDeltas(swift: reference, reference: reference)
        XCTAssertEqual(deltas.deltaE, 0, accuracy: 1e-12)
        XCTAssertEqual(deltas.l, 0)
        XCTAssertEqual(deltas.a, 0)
        XCTAssertEqual(deltas.b, 0)
        XCTAssertEqual(deltas.relL, 0)
        XCTAssertEqual(deltas.relA, 0)
        XCTAssertEqual(deltas.relB, 0)
    }
}
