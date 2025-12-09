#if canImport(SwiftUI)
import SwiftUI

// MARK: - SwiftUI Extensions

extension ColorJourney {
    /// Create a SwiftUI `Gradient` from the journey.
    ///
    /// Samples at N stops for use with SwiftUI gradient views.
    ///
    /// ```swift
    /// Rectangle()
    ///     .fill(journey.gradient(stops: 20))
    /// ```
    ///
    /// - Parameter stops: Number of color stops (default: 10)
    /// - Returns: SwiftUI `Gradient`
    ///
    /// - SeeAlso: ``linearGradient(stops:startPoint:endPoint:)``
    public func gradient(stops: Int = 10) -> Gradient {
        let colors = (0..<stops).map { index in
            sample(at: Float(index) / Float(stops - 1)).color
        }
        return Gradient(colors: colors)
    }

    /// Create a SwiftUI `LinearGradient` from the journey.
    ///
    /// Use directly with SwiftUI view modifiers.
    ///
    /// ```swift
    /// Rectangle()
    ///     .fill(journey.linearGradient(stops: 20))
    ///
    /// Rectangle()
    ///     .fill(journey.linearGradient(
    ///         stops: 20,
    ///         startPoint: .topLeading,
    ///         endPoint: .bottomTrailing
    ///     ))
    /// ```
    ///
    /// - Parameters:
    ///   - stops: Number of color stops (default: 10)
    ///   - startPoint: Gradient start (default: `.leading`)
    ///   - endPoint: Gradient end (default: `.trailing`)
    /// - Returns: SwiftUI `LinearGradient`
    ///
    /// - SeeAlso: ``gradient(stops:)``
    public func linearGradient(
        stops: Int = 10,
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> LinearGradient {
        LinearGradient(
            gradient: gradient(stops: stops),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

#endif
