---
title: ColorJourney Usage & Architecture Diagram
---
classDiagram
    class ColorJourneyConfig {
        +anchors: [ColorJourneyRGB]
        +lightness: LightnessBias
        +chroma: ChromaBias
        +contrast: ContrastLevel
        +midJourneyVibrancy: Float
        +temperature: TemperatureBias
        +loopMode: LoopMode
        +variation: VariationConfig
        +singleAnchor(color, style)$ ColorJourneyConfig
        +multiAnchor(colors, style)$ ColorJourneyConfig
    }

    class ColorJourney {
        -handle: OpaquePointer
        +init(config: ColorJourneyConfig)
        +sample(at: Float) ColorJourneyRGB
        +discrete(count: Int) [ColorJourneyRGB]
        +gradient(stops: Int) Gradient
        +linearGradient(stops: Int, ...) LinearGradient
    }

    class ColorJourneyRGB {
        +red: Float
        +green: Float
        +blue: Float
        +color: Color
        +nsColor: NSColor
        +uiColor: UIColor
    }

    class JourneyStyle {
        <<enumeration>>
        balanced
        pastelDrift
        vividLoop
        nightMode
        warmEarth
        coolSky
    }

    class LoopMode {
        <<enumeration>>
        open
        closed
        pingPong
    }

    class LightnessBias {
        <<enumeration>>
        neutral
        lighter
        darker
        custom(weight)
    }

    class ChromaBias {
        <<enumeration>>
        neutral
        muted
        vivid
        custom(multiplier)
    }

    class ContrastLevel {
        <<enumeration>>
        low
        medium
        high
        custom(threshold)
    }

    class TemperatureBias {
        <<enumeration>>
        neutral
        warm
        cool
    }

    class VariationConfig {
        +enabled: Bool
        +dimensions: VariationDimensions
        +strength: VariationStrength
        +seed: UInt64
        +off$ VariationConfig
        +subtle(dimensions, seed)$ VariationConfig
    }

    class VariationDimensions {
        <<enumeration>>
        hue
        lightness
        chroma
        all
    }

    class VariationStrength {
        <<enumeration>>
        subtle
        noticeable
        custom(magnitude)
    }

    %% Relationships
    ColorJourneyConfig --> ColorJourneyRGB : uses
    ColorJourneyConfig --> JourneyStyle : applies
    ColorJourneyConfig --> LightnessBias : configures
    ColorJourneyConfig --> ChromaBias : configures
    ColorJourneyConfig --> ContrastLevel : configures
    ColorJourneyConfig --> TemperatureBias : configures
    ColorJourneyConfig --> LoopMode : configures
    ColorJourneyConfig --> VariationConfig : contains
    ColorJourney --> ColorJourneyConfig : consumes
    ColorJourney --> ColorJourneyRGB : returns
    VariationConfig --> VariationDimensions : uses
    VariationConfig --> VariationStrength : configures
