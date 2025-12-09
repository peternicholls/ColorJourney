Pod::Spec.new do |spec|
  spec.name         = "ColorJourney"
  spec.version      = "1.0.2"
  spec.summary      = "Perceptually Uniform Color Palette Generator"

  spec.description  = <<-DESC
    ColorJourney is a high-performance color palette generator using perceptually uniform color math based on OKLab.
    It provides both continuous sampling for smooth gradients and discrete palette generation for UI design.
    The library combines a high-performance C99 core with an elegant Swift wrapper for iOS/macOS development.

    ## Features

    - **OKLab Color Math**: Perceptually uniform colors based on OKLab color space
    - **Continuous Sampling**: Generate infinite palette points along the color journey
    - **Discrete Palettes**: Generate N distinct colors with enforced contrast for UI design
    - **Deterministic Output**: Same input always produces same colors
    - **Cross-Platform**: iOS, macOS, tvOS, watchOS, visionOS support
    - **High Performance**: C99 core optimized for speed

    ## Quick Start

    ```swift
    import ColorJourney

    // Create a journey from a base color
    let journey = ColorJourney(
        config: .singleAnchor(
            ColorJourneyRGB(red: 0.5, green: 0.2, blue: 0.8),
            style: .balanced
        )
    )

    // Sample continuously for gradients
    let midColor = journey.sample(at: 0.5)

    // Generate discrete palette for UI
    let palette = journey.discrete(count: 8)
    ```

    See the [GitHub repository](https://github.com/peternicholls/ColorJourney) for detailed documentation.
  DESC

  spec.homepage     = "https://github.com/peternicholls/ColorJourney"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Peter Nicholls" => "peter@colorjourney.dev" }
  spec.social_media_url = "https://github.com/peternicholls/ColorJourney"
  
  spec.ios.deployment_target     = "13.0"
  spec.osx.deployment_target     = "10.15"
  spec.tvos.deployment_target    = "13.0"
  spec.watchos.deployment_target = "6.0"
  spec.visionos.deployment_target = "1.0"

  spec.source       = { :git => "https://github.com/peternicholls/ColorJourney.git", :tag => "v#{spec.version}" }

  spec.swift_version = "5.9"

  # Source files: Swift wrapper and C core
  spec.source_files = "Sources/ColorJourney/**/*.swift", "Sources/CColorJourney/**/*.c"
  
  # Public headers for C core (required for module bridging)
  spec.public_header_files = "Sources/CColorJourney/include/**/*.h"
  
  # Preserve header directory structure
  spec.preserve_paths = "Sources/CColorJourney/include"

  # Compiler settings for C core integration
  spec.pod_target_xcconfig = {
    "SWIFT_INCLUDE_PATHS" => "$(PODS_TARGET_SRCROOT)/Sources/CColorJourney/include",
    "GCC_PREPROCESSOR_DEFINITIONS" => "_GNU_SOURCE",
    "CLANG_ENABLE_OBJC_ARC" => "YES",
    "GCC_OPTIMIZATION_LEVEL" => "3"  # Enable O3 optimization for release builds
  }

  spec.user_target_xcconfig = {
    "SWIFT_INCLUDE_PATHS" => "$(PODS_ROOT)/ColorJourney/Sources/CColorJourney/include"
  }

end
