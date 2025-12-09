/*
 * ColorJourney System - Core C Library
 * High-performance OKLab-based color journey generation
 * Designed for Swift integration but fully portable C
 */

#ifndef COLORJOURNEY_H
#define COLORJOURNEY_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================
 * Core Color Types
 * ======================================================================== */

/**
 * @struct CJ_RGB
 * @brief Represents a color in linear sRGB color space.
 *
 * Colors are specified as linear RGB components (not gamma-corrected).
 * All components are clamped or expected in the range [0, 1]:
 * - 0.0 = darkest component
 * - 1.0 = brightest component
 *
 * Values outside [0, 1] are technically valid (extended RGB) but may
 * be clamped by @ref cj_rgb_clamp or during conversion to other spaces.
 *
 * @note This is the color format used for input/output throughout the API.
 * @see cj_rgb_clamp to normalize to valid range
 * @see cj_rgb_to_oklab to convert to perceptual space
 */
typedef struct {
    float r;  ///< Red component [0, 1]
    float g;  ///< Green component [0, 1]
    float b;  ///< Blue component [0, 1]
} CJ_RGB;

/**
 * @struct CJ_Lab
 * @brief Represents a color in OKLab perceptual color space.
 *
 * OKLab is a perceptually uniform color space designed by Björn Ottosson.
 * Unlike RGB, distances in OKLab space correlate with perceived color
 * differences. This property makes OKLab ideal for journey generation,
 * contrast enforcement, and perceptual analysis.
 *
 * Components:
 * - **L** (Lightness): Perceived brightness, range [0, 1]
 *   - 0.0 = pure black
 *   - ~0.5 = medium gray
 *   - 1.0 = pure white
 *
 * - **a** (Red-Green opponent): Ranges approximately [-0.4, 0.4]
 *   - Negative = greenish
 *   - Positive = reddish
 *
 * - **b** (Yellow-Blue opponent): Ranges approximately [-0.4, 0.4]
 *   - Negative = bluish
 *   - Positive = yellowish
 *
 * @note All ColorJourney math operates in OKLab space internally.
 * @note For analysis, convert to @ref CJ_LCh for hue and chroma.
 * @see cj_rgb_to_oklab to convert from RGB
 * @see cj_oklab_to_rgb to convert back to RGB
 * @see cj_delta_e to compute perceptual distance
 *
 * **Reference**: Ottosson, B. (2020). https://bottosson.github.io/posts/oklab/
 */
typedef struct {
    float L;  ///< Lightness [0, 1]. Perceived brightness (0=black, 1=white)
    float a;  ///< Red-Green component [~-0.4, ~0.4]. Negative=greenish, positive=reddish
    float b;  ///< Yellow-Blue component [~-0.4, ~0.4]. Negative=bluish, positive=yellowish
} CJ_Lab;

/**
 * @struct CJ_LCh
 * @brief Represents a color in OKLab cylindrical (LCh) form.
 *
 * This is an alternative representation of OKLab that uses cylindrical
 * coordinates: Lightness, Chroma (saturation), and Hue angle.
 * Useful for thinking about color journeys in terms of hue rotation,
 * saturation levels, and brightness.
 *
 * Conversion:
 * - L (Lightness): Same as OKLab L [0, 1]
 * - C (Chroma): Saturation magnitude = √(a² + b²), range [0, ~0.4]
 * - h (Hue): Angular position = atan2(b, a), range [0, 2π)
 *
 * @note LCh is more intuitive for journey design but OKLab is more efficient for math.
 * @see cj_oklab_to_lch to convert from OKLab
 * @see cj_lch_to_oklab to convert back to OKLab
 */
typedef struct {
    float L;  ///< Lightness [0, 1]. Same as OKLab L (perceived brightness)
    float C;  ///< Chroma [0, ~0.4]. Saturation/colorfulness magnitude
    float h;  ///< Hue [0, 2π). Angular position: 0=red, π/2=yellow, π=cyan, 3π/2=blue
} CJ_LCh;

/* ========================================================================
 * Configuration Enums
 * ======================================================================== */

/**
 * @enum CJ_LightnessBias
 * @brief Controls overall brightness adjustment across the journey.
 *
 * Lightness bias shifts the entire journey toward brighter or darker
 * colors while preserving the hue and chroma structure. This is useful
 * for adapting palettes to different contexts (e.g., light mode vs dark mode).
 *
 * @see CJ_Config.lightness_bias
 * @see CJ_Config.lightness_custom_weight for custom fine-tuning
 */
typedef enum {
    CJ_LIGHTNESS_NEUTRAL = 0,  ///< Preserve original lightness from anchor(s)
    CJ_LIGHTNESS_LIGHTER,       ///< Shift toward brighter colors (L increased)
    CJ_LIGHTNESS_DARKER,        ///< Shift toward darker colors (L decreased)
    CJ_LIGHTNESS_CUSTOM         ///< Use custom weight (-1 darker, +1 lighter)
} CJ_LightnessBias;

/**
 * @enum CJ_ChromaBias
 * @brief Controls saturation (colorfulness) across the journey.
 *
 * Chroma bias scales the saturation of colors. Higher chroma produces
 * vibrant, bold colors. Lower chroma produces muted, pastel colors.
 *
 * @see CJ_Config.chroma_bias
 * @see CJ_Config.chroma_custom_multiplier for custom scaling [0.5, 2.0]
 */
typedef enum {
    CJ_CHROMA_NEUTRAL = 0,  ///< Preserve original saturation from anchor(s)
    CJ_CHROMA_MUTED,        ///< Reduce saturation (×0.6 multiplier) for pastel feel
    CJ_CHROMA_VIVID,        ///< Increase saturation (×1.4 multiplier) for bold colors
    CJ_CHROMA_CUSTOM        ///< Use custom multiplier
} CJ_ChromaBias;

/**
 * @enum CJ_ContrastLevel
 * @brief Enforces minimum perceptual separation between adjacent colors.
 *
 * Contrast level defines the minimum perceptual distance (OKLab ΔE)
 * between adjacent colors in discrete palettes. Higher contrast ensures
 * colors are easily distinguishable in UIs, but may reduce available
 * variations if the anchor color range is narrow.
 *
 * The thresholds are:
 * - `.low`: ΔE ≥ 0.05 (soft, subtle separation)
 * - `.medium`: ΔE ≥ 0.10 (balanced, readable at normal viewing)
 * - `.high`: ΔE ≥ 0.15 (strong, distinct even at a glance)
 * - `.custom`: Use custom ΔE threshold value
 *
 * @note Contrast enforcement may slightly nudge color values (L, C) to meet
 *       the threshold, but preserves overall palette character.
 *
 * @see cj_enforce_contrast for the adjustment algorithm
 * @see cj_delta_e for perceptual distance calculation
 */
typedef enum {
    CJ_CONTRAST_LOW = 0,   ///< Minimum ΔE ≥ 0.05 (soft, subtle separation)
    CJ_CONTRAST_MEDIUM,    ///< Minimum ΔE ≥ 0.10 (balanced, recommended for UIs)
    CJ_CONTRAST_HIGH,      ///< Minimum ΔE ≥ 0.15 (strong distinction)
    CJ_CONTRAST_CUSTOM     ///< Use custom threshold in config.contrast_custom_threshold
} CJ_ContrastLevel;

/**
 * @enum CJ_TemperatureBias
 * @brief Shifts hue toward warm or cool color regions.
 *
 * Temperature bias rotates the hue wheel without changing lightness
 * or saturation. This is useful for creating color-coordinated palettes
 * that feel warm (reds, oranges, yellows) or cool (blues, cyans, purples).
 *
 * - `.warm`: Hue rotated +0.3 radians (~17°) toward warm colors
 * - `.cool`: Hue rotated -0.3 radians (~17°) toward cool colors
 *
 * @see CJ_Config.temperature_bias
 */
typedef enum {
    CJ_TEMPERATURE_NEUTRAL = 0,  ///< No temperature bias (preserve hue)
    CJ_TEMPERATURE_WARM,         ///< Shift toward warm colors (reds, oranges, yellows)
    CJ_TEMPERATURE_COOL          ///< Shift toward cool colors (blues, cyans, purples)
} CJ_TemperatureBias;

/**
 * @enum CJ_LoopMode
 * @brief Defines how the journey behaves at its boundaries (t=0 and t=1).
 *
 * For continuous sampling (animations, gradients), the loop mode controls
 * what happens as the parameter t approaches the boundaries.
 *
 * - `.open`: Journey is one-way; color at t=0 and t=1 are different
 * - `.closed`: Journey loops seamlessly; color at t=1 matches t=0
 * - `.pingPong`: Journey reverses at boundaries; goes 0→1→0
 *
 * For discrete palettes, loop mode affects the final sampling pattern.
 *
 * @see CJ_Config.loop_mode
 * @see cj_journey_sample for continuous sampling behavior
 */
typedef enum {
    CJ_LOOP_OPEN = 0,    ///< One-way journey: start ≠ end
    CJ_LOOP_CLOSED,      ///< Seamless loop: end wraps back to start
    CJ_LOOP_PINGPONG     ///< Reversal: goes forward then backward
} CJ_LoopMode;

/**
 * @enum CJ_VariationDimension
 * @brief Selects which color dimensions are subject to seeded variation.
 *
 * When variation is enabled, this bitfield specifies which dimensions
 * get micro-variation applied. Multiple dimensions can be combined.
 *
 * Variation is deterministic (seeded by config.variation_seed) so identical
 * configurations always produce identical output.
 *
 * @see CJ_Config.variation_dimensions
 * @see CJ_Config.variation_enabled
 */
typedef enum {
    CJ_VARIATION_NONE = 0,              ///< No variation (seed ignored)
    CJ_VARIATION_HUE = 1 << 0,          ///< Vary hue randomly (within strength bounds)
    CJ_VARIATION_LIGHTNESS = 1 << 1,    ///< Vary lightness randomly
    CJ_VARIATION_CHROMA = 1 << 2        ///< Vary saturation randomly
} CJ_VariationDimension;

/**
 * @enum CJ_VariationStrength
 * @brief Controls the magnitude of seeded variation.
 *
 * - `.subtle`: Small variations (~1-2% change per dimension)
 * - `.noticeable`: Medium variations (~3-5% change per dimension)
 * - `.custom`: Use custom magnitude in config.variation_custom_magnitude
 *
 * Higher strengths produce more "organic" but less predictable palettes.
 * Variation is always deterministic (seeded).
 *
 * @see CJ_Config.variation_strength
 * @see CJ_Config.variation_enabled
 */
typedef enum {
    CJ_VARIATION_SUBTLE = 0,  ///< Soft, barely noticeable variation (~1-2% per dimension)
    CJ_VARIATION_NOTICEABLE,  ///< Medium variation (~3-5% per dimension)
    CJ_VARIATION_CUSTOM       ///< Use custom magnitude in config.variation_custom_magnitude
} CJ_VariationStrength;

/* ========================================================================
 * Journey Configuration
 * ======================================================================== */

/**
 * @struct CJ_Config
 * @brief Complete configuration for a color journey.
 *
 * CJ_Config specifies all parameters that shape a color journey:
 * the anchor color(s), perceptual biases, looping behavior, and
 * optional seeded variation. Initialize with @ref cj_config_init
 * before use.
 *
 * **Perceptual Biases**:
 * - lightness_bias: Controls overall brightness
 * - chroma_bias: Controls saturation
 * - contrast_level: Minimum perceptual separation (discrete only)
 * - mid_journey_vibrancy: Boost saturation at center of journey [0, 1]
 * - temperature_bias: Shift toward warm or cool hues
 *
 * **Looping & Variation**:
 * - loop_mode: How journey behaves at boundaries (open/closed/pingpong)
 * - variation_enabled: Apply seeded micro-variation to discrete colors
 * - variation_seed: Deterministic seed for reproducible variation
 *
 * @note Always initialize with @ref cj_config_init before modification.
 * @see cj_config_init
 * @see cj_journey_create
 */
typedef struct {
    /* ========== Anchor Colors ========== */
    
    /// Array of anchor colors (RGB). Single anchor (1 color) produces a full hue wheel journey.
    /// Multiple anchors (2-8) produce interpolated journeys between them.
    CJ_RGB anchors[8];
    
    /// Number of valid anchors in the anchors[] array. Must be ≥ 1, ≤ 8.
    int anchor_count;
    
    /* ========== Perceptual Dynamics ========== */
    
    /// Lightness bias type. See CJ_LightnessBias for options.
    CJ_LightnessBias lightness_bias;
    /// Custom lightness weight if lightness_bias == CJ_LIGHTNESS_CUSTOM. Range: [-1, 1]
    /// where -1 = darkest, 0 = neutral, +1 = lightest
    float lightness_custom_weight;
    
    /// Chroma (saturation) bias type. See CJ_ChromaBias for options.
    CJ_ChromaBias chroma_bias;
    /// Custom chroma multiplier if chroma_bias == CJ_CHROMA_CUSTOM. Range: [0.5, 2.0]
    /// where 0.5 = muted (half saturation), 1.0 = neutral, 2.0 = vivid (double saturation)
    float chroma_custom_multiplier;
    
    /// Contrast enforcement level. See CJ_ContrastLevel for options.
    CJ_ContrastLevel contrast_level;
    /// Custom contrast threshold if contrast_level == CJ_CONTRAST_CUSTOM.
    /// Specified as minimum OKLab ΔE (perceptual distance) between adjacent colors in discrete palettes.
    /// Typical range: [0.05, 0.20]. Higher = more distinct colors.
    float contrast_custom_threshold;
    
    /// Vibrancy boost at journey midpoint (t ≈ 0.5). Range: [0, 1]
    /// 0.0 = no boost (natural fade at midpoint)
    /// 0.5 = moderate boost (typical for pleasing appearance)
    /// 1.0 = maximum boost (saturated midpoint)
    /// Prevents muddy, desaturated colors in the middle of the journey.
    float mid_journey_vibrancy;
    
    /// Temperature bias (warm/cool hue shift). See CJ_TemperatureBias.
    CJ_TemperatureBias temperature_bias;
    
    /* ========== Looping ========== */
    
    /// How the journey wraps at boundaries. See CJ_LoopMode.
    CJ_LoopMode loop_mode;
    
    /* ========== Variation Layer (Seeded Randomness) ========== */
    
    /// Bitfield of CJ_VariationDimension specifying which color aspects vary.
    /// Combine multiple: e.g., (CJ_VARIATION_HUE | CJ_VARIATION_LIGHTNESS)
    /// Ignored if variation_enabled == false.
    uint32_t variation_dimensions;
    
    /// Strength of variation. See CJ_VariationStrength.
    CJ_VariationStrength variation_strength;
    /// Custom variation magnitude if variation_strength == CJ_VARIATION_CUSTOM.
    /// Typical range: [0.01, 0.10] (1% to 10% per-dimension variation).
    float variation_custom_magnitude;
    
    /// Deterministic seed for variation PRNG. Same seed = same variation pattern.
    /// If 0, uses default deterministic seed (0x123456789ABCDEF0).
    /// Variation is fully deterministic: no true randomness.
    uint64_t variation_seed;
    
    /// Enable/disable variation layer entirely.
    bool variation_enabled;
    
} CJ_Config;

/// Opaque handle to a color journey. Created with @ref cj_journey_create,
/// destroyed with @ref cj_journey_destroy.
typedef struct CJ_Journey_Impl* CJ_Journey;

/* ========================================================================
 * Core API - Journey Creation & Sampling
 * ======================================================================== */

/**
 * @brief Initialize a configuration struct to sensible defaults.
 *
 * This function zeroes the configuration and sets reasonable defaults:
 * - No anchor colors (you must set anchors manually)
 * - Neutral biases (no lightness/chroma/temperature shifts)
 * - Medium contrast level
 * - Open loop mode (non-wrapping)
 * - Variation disabled
 *
 * Always call this before modifying a CJ_Config struct to ensure
 * all fields are properly initialized.
 *
 * @param config Pointer to configuration struct to initialize.
 *               Must not be NULL.
 *
 * @return Nothing. Modifies @c config in-place.
 *
 * @note This function always succeeds.
 *
 * **Example:**
 * ```c
 * CJ_Config config;
 * cj_config_init(&config);
 * config.anchors[0] = (CJ_RGB){ 0.3f, 0.5f, 0.8f };
 * config.anchor_count = 1;
 * ```
 *
 * @see CJ_Config for field descriptions
 * @see cj_journey_create to create a journey from this config
 */
void cj_config_init(CJ_Config* config);

/**
 * @brief Create a color journey from a configuration.
 *
 * Allocates and initializes a journey handle with the provided configuration.
 * The journey is ready for immediate sampling via @ref cj_journey_sample
 * or @ref cj_journey_discrete.
 *
 * **Memory Ownership:**
 * The returned handle must be freed with @ref cj_journey_destroy when
 * no longer needed. Responsibility is on the caller.
 *
 * **Determinism Guarantee:**
 * Given identical @c config inputs, this function produces identical
 * journey output on all platforms (bit-for-bit consistency).
 * Variation randomness is deterministic (seeded).
 *
 * @param config Pointer to journey configuration. Must not be NULL,
 *               and config.anchor_count must be ≥ 1.
 *
 * @return Opaque journey handle, or NULL if allocation fails.
 *         Check for NULL before using the handle.
 *
 * @note The function does not validate config fields; invalid ranges
 *       may cause undefined behavior. Ensure all fields are in valid ranges
 *       as specified in CJ_Config documentation.
 *
 * **Example:**
 * ```c
 * CJ_Config config;
 * cj_config_init(&config);
 * config.anchors[0] = (CJ_RGB){ 0.2f, 0.4f, 0.8f };
 * config.anchor_count = 1;
 * config.contrast_level = CJ_CONTRAST_MEDIUM;
 *
 * CJ_Journey journey = cj_journey_create(&config);
 * if (!journey) { printf("Failed to allocate journey\n"); return; }
 *
 * // Use journey...
 * cj_journey_destroy(journey);
 * ```
 *
 * @see cj_journey_destroy to free the handle
 * @see cj_journey_sample to sample colors
 * @see cj_journey_discrete to generate palettes
 */
CJ_Journey cj_journey_create(const CJ_Config* config);

/**
 * @brief Destroy a journey and free its resources.
 *
 * Deallocates the journey handle and any cached data (discrete palettes).
 * After calling, the handle is invalid and must not be used.
 *
 * **Safety:** It is safe to pass NULL (no-op).
 *
 * @param journey Journey handle to destroy. May be NULL (no-op).
 *
 * @return Nothing.
 *
 * **Example:**
 * ```c
 * CJ_Journey journey = cj_journey_create(&config);
 * // ... use journey ...
 * cj_journey_destroy(journey);  // journey is now invalid
 * ```
 *
 * @see cj_journey_create
 */
void cj_journey_destroy(CJ_Journey journey);

/**
 * @brief Sample a continuous color from the journey at parameter t.
 *
 * Returns the color at position t ∈ [0, 1] along the journey.
 * Useful for generating smooth gradients or animated color transitions.
 *
 * **Parameter Ranges:**
 * - t = 0.0: Color at start (first anchor or journey start)
 * - t = 0.5: Color at midpoint
 * - t = 1.0: Color at end (last anchor or journey end)
 * - t < 0 or t > 1: Clamped to [0, 1] (open loop) or wrapped (closed/pingpong)
 *
 * **Performance:**
 * ~0.6 microseconds per sample on modern hardware (M1/M2).
 * No allocations; real-time safe.
 *
 * **Determinism:**
 * Deterministic: identical journey + identical t → identical RGB output.
 *
 * @param journey Journey handle from @ref cj_journey_create. Must not be NULL.
 * @param t Parameter along journey, typically [0, 1]. Outside range may be
 *          clamped or wrapped depending on loop_mode.
 *
 * @return Color at position t in linear sRGB. May be outside [0, 1] if
 *         anchor colors or biases produce out-of-gamut values. Use
 *         @ref cj_rgb_clamp if needed.
 *
 * @note No error checking; NULL journey causes undefined behavior.
 *
 * **Example (Smooth Gradient):**
 * ```c
 * CJ_Journey journey = cj_journey_create(&config);
 * for (float t = 0.0f; t <= 1.0f; t += 0.1f) {
 *     CJ_RGB color = cj_journey_sample(journey, t);
 *     printf("t=%.1f: R=%.3f G=%.3f B=%.3f\n", t, color.r, color.g, color.b);
 * }
 * cj_journey_destroy(journey);
 * ```
 *
 * @see cj_journey_discrete for palette generation
 * @see CJ_LoopMode for boundary behavior
 */
CJ_RGB cj_journey_sample(CJ_Journey journey, float t);

/**
 * @brief Generate a discrete palette of N distinct colors from the journey.
 *
 * Samples the journey at N evenly-spaced parameters and enforces minimum
 * perceptual contrast (OKLab ΔE) between adjacent colors. Useful for
 * generating categorical color sets (UI elements, timeline tracks, labels).
 *
 * **Contrast Enforcement:**
 * If adjacent colors don't meet the configured contrast threshold, their
 * lightness and chroma are nudged slightly to ensure distinction while
 * preserving the overall palette character.
 *
 * **Memory:**
 * Caller allocates @c out_colors and retains ownership; this function only writes
 * into the provided buffer and never allocates or frees it.
 *
 * **Output Format:**
 * Colors are in linear sRGB [0, 1] but may be out-of-gamut. Use
 * @ref cj_rgb_clamp if needed.
 *
 * **Performance:**
 * ~0.1 ms for 100 colors on modern hardware.
 * Scales linearly with count.
 *
 * @param journey Journey handle from @ref cj_journey_create. Must not be NULL.
 * @param count Number of discrete colors to generate. Must be ≥ 1.
 * @param out_colors Output buffer for colors. Caller allocates and is
 *                   responsible for freeing. Size must be ≥ count * sizeof(CJ_RGB).
 *
 * @return Nothing. Results written to @c out_colors.
 *
 * @note If count <= 0, behavior is undefined (no validation).
 * @note NULL journey causes undefined behavior.
 *
 * **Example (UI Palette):**
 * ```c
 * CJ_Config config;
 * cj_config_init(&config);
 * config.anchors[0] = (CJ_RGB){ 0.5f, 0.2f, 0.8f };
 * config.anchor_count = 1;
 * config.contrast_level = CJ_CONTRAST_HIGH;
 *
 * CJ_Journey journey = cj_journey_create(&config);
 * CJ_RGB palette[8] = {0};
 * cj_journey_discrete(journey, 8, palette);
 *
 * for (int i = 0; i < 8; i++) {
 *     printf("Color %d: RGB(%.3f, %.3f, %.3f)\n", i, palette[i].r, palette[i].g, palette[i].b);
 * }
 *
 * cj_journey_destroy(journey);
 * ```
 *
 * @see cj_journey_sample for continuous sampling
 * @see CJ_ContrastLevel for contrast enforcement options
 * @see cj_enforce_contrast for the adjustment algorithm
 */
void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors);

/* ========================================================================
 * Color Space Conversions (Fast OKLab)
 * ======================================================================== */

/**
 * @brief Convert a color from linear sRGB to OKLab perceptual space.
 *
 * Converts linear RGB [0, 1] to OKLab, a perceptually uniform color space.
 * In OKLab, Euclidean distance correlates with perceived color difference.
 * This makes OKLab ideal for contrast calculations and journey generation.
 *
 * **Algorithm:**
 * Uses the reference OKLab conversion from Björn Ottosson:
 * 1. RGB → LMS (cone response)
 * 2. LMS → LMS' (nonlinear compression using fast cube root)
 * 3. LMS' → OKLab (opponent color encoding)
 *
 * **Accuracy:**
 * The fast cube root (~1% error) is acceptable for color journeys because
 * perceptual OKLab distances remain accurate at this precision, and the
 * slight error is unnoticeable to human vision.
 *
 * **Performance:**
 * ~3-5x faster than standard cbrtf() via bit manipulation + Newton-Raphson.
 *
 * @param c Color in linear sRGB [0, 1] (or extended RGB for out-of-gamut colors)
 *
 * @return Color in OKLab space
 *
 * @note RGB values should be linear (gamma-corrected sRGB must be
 *       linearized first). The function does not validate ranges.
 *
 * **Example:**
 * ```c
 * CJ_RGB rgb = { 0.5f, 0.7f, 0.3f };
 * CJ_Lab lab = cj_rgb_to_oklab(rgb);
 * printf("L=%.3f a=%.3f b=%.3f\n", lab.L, lab.a, lab.b);
 * ```
 *
 * **Reference:**
 * Ottosson, B. (2020). OKLab. https://bottosson.github.io/posts/oklab/
 *
 * @see cj_oklab_to_rgb for inverse conversion
 * @see cj_delta_e for perceptual distance
 */
CJ_Lab cj_rgb_to_oklab(CJ_RGB c);

/**
 * @brief Convert a color from OKLab perceptual space to linear sRGB.
 *
 * Inverse of @ref cj_rgb_to_oklab. Converts OKLab back to linear sRGB.
 * May produce out-of-gamut values (RGB outside [0, 1]). Use
 * @ref cj_rgb_clamp if needed.
 *
 * @param c Color in OKLab space
 *
 * @return Color in linear sRGB (may be out-of-gamut)
 *
 * **Example:**
 * ```c
 * CJ_Lab lab = { 0.5f, 0.1f, -0.05f };
 * CJ_RGB rgb = cj_oklab_to_rgb(lab);
 * CJ_RGB clamped = cj_rgb_clamp(rgb);  // Normalize if needed
 * ```
 *
 * @see cj_rgb_to_oklab for forward conversion
 * @see cj_rgb_clamp to normalize out-of-gamut colors
 */
CJ_RGB cj_oklab_to_rgb(CJ_Lab c);

/**
 * @brief Convert OKLab to cylindrical LCh representation.
 *
 * OKLab (L, a, b) → LCh (Lightness, Chroma, Hue).
 * LCh is more intuitive for thinking about color: hue as an angle,
 * chroma as saturation magnitude, lightness as brightness.
 *
 * **Conversion:**
 * - L = L (unchanged)
 * - C = √(a² + b²) (magnitude)
 * - h = atan2(b, a) ∈ [0, 2π)
 *
 * @param c Color in OKLab space
 *
 * @return Color in OKLab cylindrical (LCh) form
 *
 * @see cj_lch_to_oklab for inverse conversion
 * @see CJ_LCh for structure details
 */
CJ_LCh cj_oklab_to_lch(CJ_Lab c);

/**
 * @brief Convert cylindrical LCh to Cartesian OKLab representation.
 *
 * Inverse of @ref cj_oklab_to_lch. LCh → OKLab.
 *
 * **Conversion:**
 * - L = L (unchanged)
 * - a = C × cos(h)
 * - b = C × sin(h)
 *
 * @param c Color in LCh form
 *
 * @return Color in OKLab space
 *
 * @see cj_oklab_to_lch for forward conversion
 */
CJ_Lab cj_lch_to_oklab(CJ_LCh c);

/**
 * @brief Compute perceptual distance (ΔE) between two OKLab colors.
 *
 * Calculates Euclidean distance in OKLab space, which approximates
 * human perception of color difference. Used for contrast enforcement
 * and color distinction checks.
 *
 * **Formula:**
 * ΔE = √((L₁ - L₂)² + (a₁ - a₂)² + (b₁ - b₂)²)
 *
 * **Interpretation:**
 * - ΔE ≈ 0.0: Colors are identical (to human eye)
 * - ΔE ≈ 0.05: Just noticeably different (JND)
 * - ΔE ≈ 0.10: Clearly different but harmonious
 * - ΔE ≈ 0.15: Distinct, easily distinguishable
 * - ΔE ≥ 0.20: Very different, bold contrast
 *
 * @param a First color in OKLab
 * @param b Second color in OKLab
 *
 * @return Perceptual distance (ΔE), always ≥ 0.0
 *
 * **Example:**
 * ```c
 * CJ_Lab color1 = cj_rgb_to_oklab((CJ_RGB){ 1.0f, 0.0f, 0.0f });  // Red
 * CJ_Lab color2 = cj_rgb_to_oklab((CJ_RGB){ 0.0f, 0.0f, 1.0f });  // Blue
 * float distance = cj_delta_e(color1, color2);
 * printf("ΔE = %.3f\n", distance);  // ~0.30
 * ```
 *
 * @see cj_enforce_contrast to adjust colors to meet minimum ΔE
 * @see CJ_ContrastLevel for typical ΔE thresholds
 */
float cj_delta_e(CJ_Lab a, CJ_Lab b);

/* ========================================================================
 * Utility Functions
 * ======================================================================== */

/**
 * @brief Clamp RGB color components to valid range [0, 1].
 *
 * Useful for normalizing colors that may have gone out-of-gamut during
 * conversions or biasing operations. Simply clamps each component.
 *
 * @param c Color in RGB space (possibly out-of-gamut)
 *
 * @return Color with all components clamped to [0, 1]
 *
 * **Example:**
 * ```c
 * CJ_RGB rgb = { 1.5f, -0.1f, 0.8f };  // Out-of-gamut
 * CJ_RGB clamped = cj_rgb_clamp(rgb);  // { 1.0f, 0.0f, 0.8f }
 * ```
 *
 * @see cj_oklab_to_rgb which may produce out-of-gamut colors
 */
CJ_RGB cj_rgb_clamp(CJ_RGB c);

/**
 * @brief Check if a color is readable (sufficient lightness for UI text/elements).
 *
 * Returns true if the color's lightness is in a readable range:
 * - L ≥ 0.2 (not too dark to read on light backgrounds)
 * - L ≤ 0.95 (not too light to read on white backgrounds)
 *
 * Useful for determining if a color is suitable for foreground use
 * (text, icons) without additional contrast treatment.
 *
 * @param c Color in OKLab space
 *
 * @return true if color is in readable lightness range, false otherwise
 *
 * **Example:**
 * ```c
 * CJ_Lab darkGray = cj_rgb_to_oklab((CJ_RGB){ 0.2f, 0.2f, 0.2f });
 * CJ_Lab nearWhite = cj_rgb_to_oklab((CJ_RGB){ 0.98f, 0.98f, 0.98f });
 *
 * printf("darkGray readable: %d\n", cj_is_readable(darkGray));      // 1 (true)
 * printf("nearWhite readable: %d\n", cj_is_readable(nearWhite));    // 0 (false)
 * ```
 *
 * @note This is a simple heuristic; actual readability depends on
 *       background color and font properties.
 */
bool cj_is_readable(CJ_Lab c);

/**
 * @brief Enforce minimum perceptual contrast between two colors.
 *
 * Adjusts @c color's L and C (via OKLab) to ensure ΔE ≥ min_delta_e
 * from @c reference. Used internally for discrete palette generation.
 *
 * **Algorithm:**
 * 1. Compute ΔE between color and reference
 * 2. If ΔE < min_delta_e:
 *    - Adjust L (lightness) first
 *    - If insufficient, boost C (chroma)
 * 3. Clamp results to valid ranges
 *
 * **Trade-offs:**
 * Small adjustments preserve palette character while ensuring distinction.
 * Extreme configurations may produce less natural colors.
 *
 * @param color Color to adjust (input in OKLab)
 * @param reference Reference color to contrast against (OKLab)
 * @param min_delta_e Minimum ΔE threshold to enforce (typically 0.05 to 0.20)
 *
 * @return Adjusted color in OKLab (guaranteed ΔE ≥ min_delta_e from reference)
 *
 * **Example:**
 * ```c
 * CJ_Lab color1 = cj_rgb_to_oklab((CJ_RGB){ 0.5f, 0.5f, 0.5f });
 * CJ_Lab color2 = cj_rgb_to_oklab((CJ_RGB){ 0.51f, 0.49f, 0.52f });
 *
 * float distance = cj_delta_e(color1, color2);  // Maybe only 0.01
 * CJ_Lab adjusted = cj_enforce_contrast(color2, color1, 0.10f);
 * distance = cj_delta_e(color1, adjusted);  // Now >= 0.10
 * ```
 *
 * @see cj_delta_e for distance calculation
 * @see CJ_ContrastLevel for typical thresholds
 */
CJ_Lab cj_enforce_contrast(CJ_Lab color, CJ_Lab reference, float min_delta_e);

#ifdef __cplusplus
}
#endif

#endif /* COLORJOURNEY_H */
