/*
 * ColorJourney - Perceptually Uniform Color Palette Generator
 *
 * A high-level Swift API wrapping a high-performance C core.
 * Generate beautiful color palettes using perceptual color theory.
 *
 * ## Quick Start
 *
 * ```swift
 * // Create a journey from a base color
 * let journey = ColorJourney(
 *     config: .singleAnchor(
 *         ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
 *         style: .balanced
 *     )
 * )
 *
 * // Sample continuously for gradients
 * let color = journey.sample(at: 0.5)
 *
 * // Generate discrete palette for UI
 * let palette = journey.discrete(count: 8)
 *
 * // Create SwiftUI gradient
 * Rectangle().fill(journey.linearGradient(stops: 20))
 * ```
 *
 * ## Key Concepts
 *
 * - **Anchor Colors**: Base color(s) that drive the journey
 * - **Perceptual Biases**: Lightness, saturation, contrast, temperature adjustments
 * - **Loop Mode**: How colors wrap at boundaries (open, closed, pingpong)
 * - **Variation**: Optional deterministic micro-changes for organic appearance
 *
 * ## API Structure
 *
 * - ``ColorJourneyRGB``: Color type in linear sRGB
 * - ``ColorJourneyConfig``: Journey configuration
 * - ``JourneyStyle``: Preset combinations of biases
 * - ``ColorJourney``: Main palette generator
 * - Configuration enums: ``LightnessBias``, ``ChromaBias``, ``ContrastLevel``, etc.
 *
 * ## Platform Support
 *
 * Works across Apple platforms: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+, visionOS 1.0+
 */

// Main umbrella module - imports handled by subdirectories

