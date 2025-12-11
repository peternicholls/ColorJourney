/*
 * ColorJourney System - Core Implementation
 * OKLab-based perceptually uniform color journeys
 *
 * CORE PRINCIPLES (See .specify/memory/constitution.md):
 *
 * Principle I - Portability:
 *   Pure C99, zero external dependencies. Usable everywhere: iOS, macOS,
 *   Linux, Windows, embedded, WebAssembly. No platform-specific code.
 *
 * Principle II - Perceptual Integrity:
 *   All color math in OKLab, a perceptually uniform space where distances
 *   correlate with human perception. Fast cube root maintains < 1% error
 *   (invisible to human eye). Contrast enforcement ensures palettes are
 *   visually distinct and perceptually balanced.
 *
 * Principle IV - Determinism:
 *   Deterministic within a given build/toolchain: identical inputs →
 *   identical outputs. Seeded variation (xoshiro-style) enables reproducible
 *   pseudo-randomness.
 *
 * Principle V - Performance:
 *   Optimized for real-time color generation:
 *   - Single sample: ~0.6 μs (M1 hardware)
 *   - Discrete palette: O(N) time, linear with count
 *   - No allocations for continuous sampling
 *   - Tight inner loops, opportunity for SIMD future
 *
 * Principle III (Designer-Centric) is embodied in the Swift wrapper
 * with presets and type-safe configuration.
 */

#include "ColorJourney.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* ========================================================================
 * Fast Math Helpers
 * ======================================================================== */

/**
 * STANDARD CUBE ROOT (Double Precision)
 * ======================================
 *
 * Purpose: Compute x^(1/3) with IEEE 754 double precision for maximum accuracy.
 *
 * Why double precision?
 * - Analysis of WASM implementation shows double precision produces significantly
 *   better output matching user expectations
 * - Eliminates ~1% cumulative error that compounds through color pipeline
 * - For 20-100 color palettes, accuracy improvement is visibly cleaner
 * - Modern hardware-accelerated cbrt() is highly optimized
 *
 * Trade-off Analysis:
 * - Previous: float (32-bit, ~7 decimal digits) with ~1% error
 * - Current: double (64-bit, ~15 decimal digits) with machine epsilon precision
 * - Speed: Hardware-accelerated cbrt() is comparable on modern CPUs
 * - Accuracy: Eliminates perceptual artifacts in large palettes
 *
 * Implementation Note:
 * Uses standard C library cbrt() which is:
 * - IEEE 754 compliant (consistent across platforms)
 * - Hardware-accelerated on modern CPUs
 * - Deterministic (same input → same output)
 *
 * References:
 * - OKLab paper: Ottosson, B. https://bottosson.github.io/posts/oklab/
 * - ALGORITHM_COMPARISON_ANALYSIS.md (WASM vs C core comparison)
 *
 * Constitution Reference:
 * - Principle I (Portability): Standard C99 library function
 * - Principle II (Perceptual Integrity): Maximum precision for best output
 * - Principle IV (Determinism): IEEE 754 guarantees consistent behavior
 */
static inline double precise_cbrt(double x) {
    return cbrt(x);  // Standard C library, hardware-accelerated
}

static inline float clampf(float x, float min, float max) {
    return x < min ? min : (x > max ? max : x);
}

static inline float lerpf(float a, float b, float t) {
    return a + (b - a) * t;
}

/* Smooth easing function (smoothstep) */
static inline float smoothstep(float t) {
    t = clampf(t, 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

/* ========================================================================
 * OKLab Color Space (Optimized)
 *
 * ARCHITECTURE OVERVIEW:
 * All ColorJourney color math operates in OKLab space because it is
 * perceptually uniform: distances in OKLab correlate with perceived
 * color differences. This enables:
 * - Accurate contrast calculations
 * - Predictable journey interpolation
 * - Consistent results across perception (Constitution Principle II)
 *
 * Conversion Pipeline:
 * RGB → LMS (cone response) → LMS' (nonlinear) → OKLab (opponent color)
 *
 * The conversion coefficients are from Björn Ottosson's reference
 * implementation: https://bottosson.github.io/posts/oklab/
 *
 * Constitution References:
 * - Principle II (Perceptual Integrity): OKLab ensures colors are
 *   perceptually uniform and distinct
 * - Principle V (Performance): Optimized with fast_cbrt for speed
 * ======================================================================== */

CJ_Lab cj_rgb_to_oklab(CJ_RGB c) {
    /* Stage 1: RGB → LMS (cone response simulation)
     * Linear transformation based on human cone cell sensitivities.
     * Coefficients are hardcoded from Ottosson's derivation.
     * Using double precision for maximum accuracy.
     */
    double l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    double m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    double s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;

    /* Stage 2: LMS → LMS' (nonlinear compression)
     * Apply cube root to compress the range, simulating human perception.
     * Uses precise_cbrt for IEEE 754 double precision accuracy.
     */
    double l_ = precise_cbrt(l);
    double m_ = precise_cbrt(m);
    double s_ = precise_cbrt(s);

    /* Stage 3: LMS' → OKLab (opponent encoding)
     * Transform to opponent color space (red-green and yellow-blue).
     * L = perceptual lightness, a/b = color opponency.
     * Using double precision throughout for accuracy.
     */
    CJ_Lab result;
    result.L = (float)(0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_);
    result.a = (float)(1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_);
    result.b = (float)(0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_);
    
    return result;
}

CJ_RGB cj_oklab_to_rgb(CJ_Lab c) {
    /* Inverse pipeline: OKLab → LMS' → LMS → RGB
     * Note: This is the mathematical inverse of cj_rgb_to_oklab.
     * May produce out-of-gamut RGB (values outside [0, 1]) if
     * the OKLab color is not representable in sRGB. Use cj_rgb_clamp
     * if needed.
     * Using double precision for accuracy.
     */
    
    /* Stage 1: OKLab → LMS' (inverse opponent encoding) */
    double l_ = c.L + 0.3963377774 * c.a + 0.2158037573 * c.b;
    double m_ = c.L - 0.1055613458 * c.a - 0.0638541728 * c.b;
    double s_ = c.L - 0.0894841775 * c.a - 1.2914855480 * c.b;

    /* Stage 2: LMS' → LMS (inverse nonlinear compression via cube)
     * Note: Using direct cube (x^3) as the inverse of precise_cbrt.
     * This is exact and fast.
     */
    double l = l_ * l_ * l_;
    double m = m_ * m_ * m_;
    double s = s_ * s_ * s_;

    /* Stage 3: LMS → RGB (inverse cone response transformation) */
    CJ_RGB result;
    result.r = (float)(+4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s);
    result.g = (float)(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s);
    result.b = (float)(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
    
    return result;
}

CJ_LCh cj_oklab_to_lch(CJ_Lab c) {
    CJ_LCh result;
    result.L = c.L;
    result.C = sqrtf(c.a * c.a + c.b * c.b);
    result.h = atan2f(c.b, c.a);
    if (result.h < 0.0f) result.h += 2.0f * M_PI;
    return result;
}

CJ_Lab cj_lch_to_oklab(CJ_LCh c) {
    CJ_Lab result;
    result.L = c.L;
    result.a = c.C * cosf(c.h);
    result.b = c.C * sinf(c.h);
    return result;
}

float cj_delta_e(CJ_Lab a, CJ_Lab b) {
    float dL = a.L - b.L;
    float da = a.a - b.a;
    float db = a.b - b.b;
    return sqrtf(dL * dL + da * da + db * db);
}

CJ_RGB cj_rgb_clamp(CJ_RGB c) {
    c.r = clampf(c.r, 0.0f, 1.0f);
    c.g = clampf(c.g, 0.0f, 1.0f);
    c.b = clampf(c.b, 0.0f, 1.0f);
    return c;
}

bool cj_is_readable(CJ_Lab c) {
    /* Avoid very dark (L < 0.2) or very light (L > 0.95) */
    return c.L >= 0.2f && c.L <= 0.95f;
}

CJ_Lab cj_enforce_contrast(CJ_Lab color, CJ_Lab reference, float min_delta_e) {
    float de = cj_delta_e(color, reference);
    if (de >= min_delta_e) return color;
    
    /* Nudge lightness to increase separation */
    float L_diff = color.L - reference.L;
    float sign = L_diff >= 0 ? 1.0f : -1.0f;
    
    /* Try adjusting L first */
    CJ_Lab adjusted = color;
    adjusted.L = reference.L + sign * min_delta_e * 0.7f;
    adjusted.L = clampf(adjusted.L, 0.0f, 1.0f);
    
    if (cj_delta_e(adjusted, reference) >= min_delta_e) {
        return adjusted;
    }
    
    /* If L adjustment isn't enough, boost chroma slightly */
    CJ_LCh lch = cj_oklab_to_lch(adjusted);
    lch.C *= 1.15f;
    lch.C = clampf(lch.C, 0.0f, 0.4f);
    
    return cj_lch_to_oklab(lch);
}


/* ========================================================================
 * Journey Internal Structure
 * ======================================================================== */

typedef struct CJ_Journey_Impl {
    CJ_Config config;
    
    /* Precomputed OKLab anchors */
    CJ_LCh anchor_lch[8];
    int anchor_count;
    
    /* Designed waypoints for hue/chroma/lightness shaping */
    struct {
        CJ_LCh anchor;
        float weight;  /* Influence at this waypoint */
    } waypoints[16];
    int waypoint_count;
    
    /* Variation state */
    uint64_t rng_state;
} CJ_Journey_Impl;

/* ========================================================================
 * Pseudo-random number generation (xoshiro-style)
 * For deterministic variation with seed
 *
 * DETERMINISM GUARANTEE (Constitution Principle IV):
 * All seeded variation is deterministic. Given the same seed, the same
 * sequence of random numbers is generated for this build. This enables:
 * - Reproducible palettes across runs and builds with the same toolchain
 * - Sharing seed values for consistent results in teams
 * - Testing and verification of variation behavior
 * - Predictable caching and reuse of palettes
 *
 * Implementation: lightweight xoshiro-inspired mixer
 * - 64-bit state composed of two 32-bit halves
 * - Fast and simple; not a full xoshiro128+ reference impl
 * - Reference inspiration: https://prng.di.unimi.it/
 *
 * Usage: Callers don't call these directly; they're used internally
 * during palette generation when variation is enabled.
 * ======================================================================== */

static inline uint64_t xoshiro_next(uint64_t* state) {
    uint64_t s0 = (uint32_t)*state;
    uint64_t s1 = (*state) >> 32;
    uint64_t result = s0 + s1;
    
    s1 ^= s0;
    s0 = ((s0 << 24) | (s0 >> 8)) ^ s1 ^ (s1 << 16);
    s1 = (s1 << 37) | (s1 >> 27);
    
    *state = ((uint64_t)s1 << 32) | s0;
    return result;
}

/* Convert xoshiro output to float in [0, 1) */
static inline float xoshiro_float(uint64_t* state) {
    return (float)(xoshiro_next(state) & 0xFFFFFF) / 16777216.0f;
}

/* ========================================================================
 * Journey Configuration & Creation
 * ======================================================================== */

void cj_config_init(CJ_Config* config) {
    memset(config, 0, sizeof(CJ_Config));
    
    /* Set sensible defaults */
    config->anchor_count = 0;
    config->lightness_bias = CJ_LIGHTNESS_NEUTRAL;
    config->chroma_bias = CJ_CHROMA_NEUTRAL;
    config->contrast_level = CJ_CONTRAST_MEDIUM;
    config->mid_journey_vibrancy = 0.3f;
    config->temperature_bias = CJ_TEMPERATURE_NEUTRAL;
    config->loop_mode = CJ_LOOP_OPEN;
    config->variation_enabled = false;
    config->variation_seed = 0x123456789ABCDEF0ULL;  /* Default deterministic seed */
}

/* Build designed waypoints based on anchors and dynamics */
static void build_waypoints(CJ_Journey journey) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    
    if (j->anchor_count == 1) {
        /* Single anchor: full wheel journey with shaped pacing */
        CJ_LCh base = j->anchor_lch[0];
        
        /* Create waypoints with non-linear hue distribution */
        const int num_waypoints = 8;
        
        j->waypoint_count = num_waypoints;
        for (int i = 0; i < num_waypoints; i++) {
            float t = (float)i / (float)(num_waypoints - 1);
            
            /* Non-linear hue progression using smoothstep */
            float hue_t = smoothstep(t);
            
            j->waypoints[i].anchor.h = base.h + hue_t * 2.0f * M_PI;
            
            /* Subtle chroma variation - peak at golden ratio point */
            float chroma_envelope = 1.0f + 0.2f * sinf(t * M_PI);
            j->waypoints[i].anchor.C = base.C * chroma_envelope;
            
            /* Lightness gentle wave */
            float lightness_envelope = 1.0f + 0.1f * sinf(t * 2.0f * M_PI);
            j->waypoints[i].anchor.L = base.L * lightness_envelope;
            
            j->waypoints[i].weight = 1.0f;
        }
    } else {
        /* Multi-anchor: interpolate between them */
        j->waypoint_count = j->anchor_count;
        for (int i = 0; i < j->anchor_count; i++) {
            j->waypoints[i].anchor = j->anchor_lch[i];
            j->waypoints[i].weight = 1.0f;
        }
    }
    
    /* Apply temperature bias to all waypoints */
    if (j->config.temperature_bias != CJ_TEMPERATURE_NEUTRAL) {
        float shift = (j->config.temperature_bias == CJ_TEMPERATURE_WARM) ? 0.3f : -0.3f;
        for (int i = 0; i < j->waypoint_count; i++) {
            j->waypoints[i].anchor.h += shift;
            while (j->waypoints[i].anchor.h < 0) j->waypoints[i].anchor.h += 2.0f * M_PI;
            while (j->waypoints[i].anchor.h >= 2.0f * M_PI) j->waypoints[i].anchor.h -= 2.0f * M_PI;
        }
    }
}

CJ_Journey cj_journey_create(const CJ_Config* config) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)malloc(sizeof(CJ_Journey_Impl));
    if (!j) return NULL;
    
    memcpy(&j->config, config, sizeof(CJ_Config));
    j->anchor_count = config->anchor_count;
    j->rng_state = config->variation_seed;
    
    /* Convert anchors to OKLab LCh */
    for (int i = 0; i < config->anchor_count; i++) {
        CJ_Lab lab = cj_rgb_to_oklab(config->anchors[i]);
        j->anchor_lch[i] = cj_oklab_to_lch(lab);
    }
    
    /* Build designed waypoints */
    build_waypoints((CJ_Journey)j);
    
    return (CJ_Journey)j;
}

void cj_journey_destroy(CJ_Journey journey) {
    if (!journey) return;
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    free(j);
}

/* ========================================================================
 * Journey Sampling
 *
 * JOURNEY DESIGN PHILOSOPHY:
 * Journeys are not simple linear interpolations. They use designed waypoints,
 * easing curves, and parametric envelopes to create intentional, curated
 * color paths that feel natural and cohesive.
 *
 * Key Design Principles:
 * 1. Non-uniform hue distribution: More perceptual distance between
 *    some hues than others (not mechanical equal steps)
 * 2. Easing curves (smoothstep): Natural, organic pacing (not linear)
 * 3. Parametric chroma/lightness envelopes: Colors evolve naturally
 *    along the journey (saturation peaks, brightness waves)
 * 4. Shortest-path hue wrapping: Hue transitions take the short way
 *    around the wheel (no accidental rainbow effects)
 * 5. Mid-journey vibrancy: Optional boost prevents muddy midpoints
 *
 * Constitution References:
 * - Principle II (Perceptual Integrity): Journey design ensures colors
 *   are visually distinct and perceptually balanced
 * - Principle III (Designer-Centric): Defaults produce good output
 *   without manual tuning
 * ======================================================================== */

/* Interpolate between waypoints with designed easing */
static CJ_LCh interpolate_waypoints(CJ_Journey_Impl* j, float t) {
    if (j->waypoint_count == 0) {
        CJ_LCh result = {0.5f, 0.1f, 0.0f};
        return result;
    }
    
    /* Handle looping behavior at boundaries */
    if (j->config.loop_mode == CJ_LOOP_CLOSED) {
        /* Seamless loop: wrap t to [0, 1] */
        t = fmodf(t, 1.0f);
        if (t < 0) t += 1.0f;
    } else if (j->config.loop_mode == CJ_LOOP_PINGPONG) {
        /* Ping-pong: reflect t as 0→1→0 */
        t = fmodf(t, 2.0f);
        if (t < 0) t += 2.0f;
        if (t > 1.0f) t = 2.0f - t;  /* Mirror second half */
    }
    
    /* Clamp to [0, 1] for open mode */
    t = clampf(t, 0.0f, 1.0f);
    
    /* Find which waypoint segment t falls into */
    float segment_size = 1.0f / (float)(j->waypoint_count - 1);
    int segment = (int)(t / segment_size);
    if (segment >= j->waypoint_count - 1) segment = j->waypoint_count - 2;
    
    /* Local parameter within segment */
    float local_t = (t - segment * segment_size) / segment_size;
    local_t = smoothstep(local_t);  /* Apply easing: cubic smoothstep for natural pacing */
    
    CJ_LCh a = j->waypoints[segment].anchor;
    CJ_LCh b = j->waypoints[segment + 1].anchor;
    
    /* Interpolate in LCh space (perceptually more intuitive than OKLab) */
    CJ_LCh result;
    result.L = lerpf(a.L, b.L, local_t);  /* Lightness transition */
    result.C = lerpf(a.C, b.C, local_t);  /* Chroma (saturation) transition */
    
    /* Handle hue wrapping for shortest path around the hue wheel
     * Example: from h=6.2 (red) to h=0.2 (red) should rotate 0.4,
     * not 6.0, to take the short way around. */
    float hue_diff = b.h - a.h;
    if (hue_diff > M_PI) hue_diff -= 2.0f * M_PI;      /* -π to 0 shorter than π to 2π */
    if (hue_diff < -M_PI) hue_diff += 2.0f * M_PI;     /* 0 to π shorter than -π to -2π */
    result.h = a.h + hue_diff * local_t;
    
    /* Normalize hue to [0, 2π) */
    while (result.h < 0) result.h += 2.0f * M_PI;
    while (result.h >= 2.0f * M_PI) result.h -= 2.0f * M_PI;
    
    return result;
}

/* Apply dynamics and biases */
static CJ_LCh apply_dynamics(CJ_Journey_Impl* j, CJ_LCh color, float t) {
    /* ========== LIGHTNESS BIAS ==========
     * Shifts the overall brightness of the palette while preserving
     * hue and chroma. Useful for adapting to light/dark modes.
     * Formula: L_adjusted = L + weight * 0.2
     * (0.2 bounds the shift to reasonable perceptual range)
     */
    switch (j->config.lightness_bias) {
        case CJ_LIGHTNESS_LIGHTER:
            color.L = lerpf(color.L, 1.0f, 0.2f);  /* Shift 20% toward white */
            break;
        case CJ_LIGHTNESS_DARKER:
            color.L = lerpf(color.L, 0.0f, 0.2f);  /* Shift 20% toward black */
            break;
        case CJ_LIGHTNESS_CUSTOM:
            color.L += j->config.lightness_custom_weight * 0.2f;
            break;
        default:
            break;
    }
    
    /* ========== CHROMA BIAS (SATURATION) ==========
     * Scales the saturation without changing lightness or hue.
     * - Muted (0.6x): Pastel, soft appearance
     * - Vivid (1.4x): Bold, saturated appearance
     */
    switch (j->config.chroma_bias) {
        case CJ_CHROMA_MUTED:
            color.C *= 0.6f;  /* Reduce saturation by 40% */
            break;
        case CJ_CHROMA_VIVID:
            color.C *= 1.4f;  /* Increase saturation by 40% */
            break;
        case CJ_CHROMA_CUSTOM:
            color.C *= j->config.chroma_custom_multiplier;
            break;
        default:
            break;
    }
    
    /* ========== MID-JOURNEY VIBRANCY BOOST ==========
     * Prevents muddy, desaturated colors at journey midpoint.
     * At t ≈ 0.5, saturation is boosted by vibrancy factor.
     * This adds energy to the center of the palette.
     * Constitution Principle II: Ensures perceptual vibrancy.
     * 
     * UPDATED: Uses sharper peak formula from WASM analysis for better output.
     * Formula: 1 + vibrancy * 0.6 * max(0, 1 - |t-0.5|/0.35)
     * This produces a more pronounced saturation at midpoint than the previous
     * parabolic formula, matching WASM's superior output quality.
     */
    float mid_boost = 1.0f + j->config.mid_journey_vibrancy * 0.6f * 
                      fmaxf(0.0f, 1.0f - fabsf(t - 0.5f) / 0.35f);
    color.C *= mid_boost;
    
    /* Clamp to reasonable ranges */
    color.L = clampf(color.L, 0.0f, 1.0f);
    color.C = clampf(color.C, 0.0f, 0.4f);
    
    return color;
}

/* Apply optional variation */
static CJ_LCh apply_variation(CJ_Journey_Impl* j, CJ_LCh color, float t) {
    if (!j->config.variation_enabled) return color;
    
    /* Use t to seed position-based variation */
    uint64_t local_state = j->rng_state ^ (uint64_t)(t * 1000000.0f);
    
    float magnitude = 0.02f;  /* Subtle by default */
    if (j->config.variation_strength == CJ_VARIATION_NOTICEABLE) {
        magnitude = 0.05f;
    } else if (j->config.variation_strength == CJ_VARIATION_CUSTOM) {
        magnitude = j->config.variation_custom_magnitude;
    }
    
    if (j->config.variation_dimensions & CJ_VARIATION_HUE) {
        float hue_var = (xoshiro_float(&local_state) - 0.5f) * magnitude * M_PI;
        color.h += hue_var;
        while (color.h < 0) color.h += 2.0f * M_PI;
        while (color.h >= 2.0f * M_PI) color.h -= 2.0f * M_PI;
    }
    
    if (j->config.variation_dimensions & CJ_VARIATION_LIGHTNESS) {
        float L_var = (xoshiro_float(&local_state) - 0.5f) * magnitude;
        color.L = clampf(color.L + L_var, 0.0f, 1.0f);
    }
    
    if (j->config.variation_dimensions & CJ_VARIATION_CHROMA) {
        float C_var = (xoshiro_float(&local_state) - 0.5f) * magnitude * 0.5f;
        color.C = clampf(color.C + C_var, 0.0f, 0.4f);
    }
    
    return color;
}

CJ_RGB cj_journey_sample(CJ_Journey journey, float t) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    
    /* Interpolate waypoints */
    CJ_LCh lch = interpolate_waypoints(j, t);
    
    /* Apply dynamics */
    lch = apply_dynamics(j, lch, t);
    
    /* Apply variation */
    lch = apply_variation(j, lch, t);
    
    /* Convert to RGB */
    CJ_Lab lab = cj_lch_to_oklab(lch);
    CJ_RGB rgb = cj_oklab_to_rgb(lab);
    
    return cj_rgb_clamp(rgb);
}

/* ========================================================================
 * Discrete Palette Generation
 * ======================================================================== */

static float discrete_min_delta_e(const CJ_Journey_Impl* j) {
    switch (j->config.contrast_level) {
        case CJ_CONTRAST_LOW:
            return 0.05f;
        case CJ_CONTRAST_HIGH:
            return 0.15f;
        case CJ_CONTRAST_CUSTOM:
            return j->config.contrast_custom_threshold;
        default:
            return 0.1f;
    }
}

/**
 * Calculate journey position from discrete index using adaptive spacing.
 * 
 * ADAPTIVE SPACING (matches WASM implementation):
 * Instead of fixed 0.05 spacing (20 positions per cycle), spacing now adapts
 * to the intended use:
 * - For cj_journey_discrete_at: Uses fixed spacing (backward compatible)
 * - For cj_journey_discrete: Uses count-based spacing (adaptive, better distribution)
 * 
 * This function maintains backward compatibility by defaulting to fixed spacing
 * when count information is not available.
 */
static float discrete_position_from_index(int index) {
    if (index < 0) return 0.0f;

    float t = fmodf((float)index * CJ_DISCRETE_DEFAULT_SPACING, 1.0f);
    return t;
}

/**
 * Calculate journey position with loop mode awareness (WASM-style).
 * 
 * This implements the WASM algorithm's adaptive spacing:
 * - Closed loop: Divides by num_colors (includes wraparound)
 * - Open loop: Divides by num_colors-1 (excludes end point)
 * - Ping-pong: Mirrors between 0→1→0
 */
static float discrete_position_with_loop_mode(const CJ_Journey_Impl* j, int index, int total_count) {
    if (index < 0) return 0.0f;
    if (total_count <= 0) return 0.0f;
    
    float t;
    
    switch (j->config.loop_mode) {
        case CJ_LOOP_CLOSED:
            /* Closed loop: evenly divide by count (includes wraparound) */
            t = (float)index / (float)total_count;
            break;
            
        case CJ_LOOP_PINGPONG:
            /* Ping-pong: mirrors between 0→1→0 */
            t = (total_count > 1) ? (float)index / (float)(total_count - 1) : 0.5f;
            t *= 2.0f;
            if (t > 1.0f) t = 2.0f - t;
            break;
            
        case CJ_LOOP_OPEN:
        default:
            /* Open loop: evenly divide by count-1 (excludes end point) */
            t = (total_count > 1) ? (float)index / (float)(total_count - 1) : 0.5f;
            break;
    }
    
    return t;
}

/**
 * Apply minimum contrast with iterative refinement (WASM-style).
 * 
 * ITERATIVE CONTRAST ENFORCEMENT:
 * The WASM implementation uses an iterative approach (up to 5 iterations)
 * instead of the previous single-pass approach. This produces smoother,
 * more natural-looking color adjustments.
 * 
 * Algorithm:
 * 1. Check ΔE between current and previous color
 * 2. If insufficient, apply small L nudge (10% of shortfall)
 * 3. If still insufficient, boost chroma
 * 4. Repeat until contrast is met or max iterations reached
 * 
 * This iterative approach prevents aggressive "pushing" of colors and
 * maintains better perceptual quality.
 * 
 * Reference: ALGORITHM_COMPARISON_ANALYSIS.md - Iterative contrast enforcement
 */
static CJ_RGB apply_minimum_contrast(CJ_RGB color,
                                     const CJ_RGB* previous,
                                     float min_delta_e) {
    if (!previous) return color;

    CJ_Lab prev_lab = cj_rgb_to_oklab(*previous);
    CJ_Lab curr_lab = cj_rgb_to_oklab(color);
    
    /* Iterative refinement (up to 5 iterations) */
    const int max_iterations = 5;
    for (int iter = 0; iter < max_iterations; iter++) {
        float dE = cj_delta_e(curr_lab, prev_lab);
        
        if (dE >= min_delta_e) {
            /* Sufficient contrast achieved */
            break;
        }
        
        /* Calculate how much contrast we need */
        float shortfall = min_delta_e - dE;
        
        /* Try multiple adjustment strategies in sequence */
        
        /* Strategy 1: Adjust lightness */
        float direction = (prev_lab.L < 0.5f) ? 1.0f : -1.0f;
        float L_nudge = shortfall * 0.5f;  /* Use 50% of shortfall for L adjustment */
        curr_lab.L = clampf(curr_lab.L + direction * L_nudge, 0.0f, 1.0f);
        
        /* Check if L adjustment helped */
        dE = cj_delta_e(curr_lab, prev_lab);
        if (dE >= min_delta_e) {
            break;
        }
        
        /* Strategy 2: Adjust both a and b components */
        shortfall = min_delta_e - dE;
        CJ_LCh lch = cj_oklab_to_lch(curr_lab);
        
        /* Try rotating hue to increase separation */
        float hue_rotation = 0.2f;  /* ~11 degrees */
        lch.h += hue_rotation * (float)iter;  /* Increase rotation each iteration */
        while (lch.h >= 2.0f * M_PI) lch.h -= 2.0f * M_PI;
        
        /* And boost chroma if possible */
        if (lch.C > 1e-5f) {
            float scale = 1.0f + shortfall * 0.5f;
            lch.C = fminf(lch.C * scale, 0.4f);
        }
        
        curr_lab = cj_lch_to_oklab(lch);
    }

    CJ_RGB adjusted = cj_oklab_to_rgb(curr_lab);
    return cj_rgb_clamp(adjusted);
}

static CJ_RGB discrete_color_at_index(CJ_Journey_Impl* j,
                                      int index,
                                      const CJ_RGB* previous,
                                      float min_delta_e) {
    float t = discrete_position_from_index(index);
    CJ_RGB color = cj_journey_sample((CJ_Journey)j, t);

    return apply_minimum_contrast(color, previous, min_delta_e);
}

CJ_RGB cj_journey_discrete_at(CJ_Journey journey, int index) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;

    if (!j || index < 0) {
        CJ_RGB zero = {0.0f, 0.0f, 0.0f};
        return zero;
    }

    float min_delta_e = discrete_min_delta_e(j);

    CJ_RGB previous;
    bool has_previous = false;

    for (int i = 0; i < index; i++) {
        previous = discrete_color_at_index(j, i, has_previous ? &previous : NULL, min_delta_e);
        has_previous = true;
    }

    return discrete_color_at_index(j, index, has_previous ? &previous : NULL, min_delta_e);
}

void cj_journey_discrete_range(CJ_Journey journey, int start, int count, CJ_RGB* out_colors) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;

    if (!j || !out_colors || count <= 0 || start < 0) return;

    float min_delta_e = discrete_min_delta_e(j);

    CJ_RGB previous;
    bool has_previous = false;

    for (int i = 0; i < start; i++) {
        previous = discrete_color_at_index(j, i, has_previous ? &previous : NULL, min_delta_e);
        has_previous = true;
    }

    for (int i = 0; i < count; i++) {
        int index = start + i;
        out_colors[i] = discrete_color_at_index(j, index, has_previous ? &previous : NULL, min_delta_e);
        previous = out_colors[i];
        has_previous = true;
    }
}

void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;

    if (count <= 0) return;

    /* Determine contrast threshold */
    float min_delta_e = discrete_min_delta_e(j);
    
    /* Generate evenly spaced samples using loop-mode-aware positioning */
    for (int i = 0; i < count; i++) {
        float t = discrete_position_with_loop_mode(j, i, count);

        CJ_RGB color = cj_journey_sample(journey, t);

        /* Enforce contrast with previous color */
        if (i > 0) {
            color = apply_minimum_contrast(color, &out_colors[i - 1], min_delta_e);
        }

        out_colors[i] = color;
    }
    
    /* ========== PERIODIC CHROMA PULSE (WASM Enhancement) ==========
     * For large palettes (>20 colors), apply a periodic chroma modulation
     * to create intentional "rhythm" in saturation across the palette.
     * This produces more "musical" color spacing that feels more curated.
     * 
     * Formula: chroma_pulse = 1.0 + 0.1 * cos(i * π/5)
     * 
     * This creates a gentle wave pattern in saturation that helps the eye
     * distinguish between adjacent colors in large palettes.
     * 
     * Reference: ALGORITHM_COMPARISON_ANALYSIS.md - WASM chroma modulation
     */
    if (count > 20) {
        for (int i = 0; i < count; i++) {
            /* Convert to OKLab to access chroma */
            CJ_Lab lab = cj_rgb_to_oklab(out_colors[i]);
            CJ_LCh lch = cj_oklab_to_lch(lab);
            
            /* Apply periodic pulse */
            double chroma_pulse = 1.0 + 0.1 * cos((double)i * M_PI / 5.0);
            lch.C = (float)((double)lch.C * chroma_pulse);
            lch.C = clampf(lch.C, 0.0f, 0.4f);
            
            /* Convert back to RGB */
            lab = cj_lch_to_oklab(lch);
            out_colors[i] = cj_oklab_to_rgb(lab);
            out_colors[i] = cj_rgb_clamp(out_colors[i]);
        }
    }
}
