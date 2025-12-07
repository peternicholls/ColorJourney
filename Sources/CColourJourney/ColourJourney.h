/*
 * Colour Journey System - Core C Library
 * High-performance OKLab-based color journey generation
 * Designed for Swift integration but fully portable C
 */

#ifndef COLOUR_JOURNEY_H
#define COLOUR_JOURNEY_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================
 * Core Color Types
 * ======================================================================== */

typedef struct {
    float r, g, b;  /* Linear sRGB [0,1] */
} CJ_RGB;

typedef struct {
    float L, a, b;  /* OKLab */
} CJ_Lab;

typedef struct {
    float L;        /* Lightness [0,1] */
    float C;        /* Chroma [0,~0.4] */
    float h;        /* Hue [0,2π) */
} CJ_LCh;

/* ========================================================================
 * Configuration Enums
 * ======================================================================== */

typedef enum {
    CJ_LIGHTNESS_NEUTRAL = 0,
    CJ_LIGHTNESS_LIGHTER,
    CJ_LIGHTNESS_DARKER,
    CJ_LIGHTNESS_CUSTOM
} CJ_LightnessBias;

typedef enum {
    CJ_CHROMA_NEUTRAL = 0,
    CJ_CHROMA_MUTED,
    CJ_CHROMA_VIVID,
    CJ_CHROMA_CUSTOM
} CJ_ChromaBias;

typedef enum {
    CJ_CONTRAST_LOW = 0,
    CJ_CONTRAST_MEDIUM,
    CJ_CONTRAST_HIGH,
    CJ_CONTRAST_CUSTOM
} CJ_ContrastLevel;

typedef enum {
    CJ_TEMPERATURE_NEUTRAL = 0,
    CJ_TEMPERATURE_WARM,
    CJ_TEMPERATURE_COOL
} CJ_TemperatureBias;

typedef enum {
    CJ_LOOP_OPEN = 0,
    CJ_LOOP_CLOSED,
    CJ_LOOP_PINGPONG
} CJ_LoopMode;

typedef enum {
    CJ_VARIATION_NONE = 0,
    CJ_VARIATION_HUE = 1 << 0,
    CJ_VARIATION_LIGHTNESS = 1 << 1,
    CJ_VARIATION_CHROMA = 1 << 2
} CJ_VariationDimension;

typedef enum {
    CJ_VARIATION_SUBTLE = 0,
    CJ_VARIATION_NOTICEABLE,
    CJ_VARIATION_CUSTOM
} CJ_VariationStrength;

/* ========================================================================
 * Journey Configuration
 * ======================================================================== */

typedef struct {
    /* Anchors */
    CJ_RGB anchors[8];
    int anchor_count;
    
    /* Dynamics / Perceptual Biases */
    CJ_LightnessBias lightness_bias;
    float lightness_custom_weight;  /* [-1, 1] for custom */
    
    CJ_ChromaBias chroma_bias;
    float chroma_custom_multiplier; /* [0.5, 2.0] for custom */
    
    CJ_ContrastLevel contrast_level;
    float contrast_custom_threshold; /* OKLab ΔE minimum */
    
    float mid_journey_vibrancy;     /* [0, 1] boost at t≈0.5 */
    CJ_TemperatureBias temperature_bias;
    
    /* Looping */
    CJ_LoopMode loop_mode;
    
    /* Variation Layer */
    uint32_t variation_dimensions;  /* Bitfield of CJ_VariationDimension */
    CJ_VariationStrength variation_strength;
    float variation_custom_magnitude;
    uint64_t variation_seed;        /* 0 = deterministic default */
    bool variation_enabled;
    
} CJ_Config;

/* Opaque journey handle */
typedef struct CJ_Journey_Impl* CJ_Journey;

/* ========================================================================
 * Core API - Journey Creation & Sampling
 * ======================================================================== */

/* Initialize default configuration */
void cj_config_init(CJ_Config* config);

/* Create a journey from configuration */
CJ_Journey cj_journey_create(const CJ_Config* config);

/* Destroy a journey */
void cj_journey_destroy(CJ_Journey journey);

/* Sample journey at parameter t ∈ [0,1] → returns sRGB color */
CJ_RGB cj_journey_sample(CJ_Journey journey, float t);

/* Generate N discrete colors with enforced perceptual distinction */
void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors);

/* ========================================================================
 * Color Space Conversions (Fast OKLab)
 * ======================================================================== */

CJ_Lab cj_rgb_to_oklab(CJ_RGB c);
CJ_RGB cj_oklab_to_rgb(CJ_Lab c);

CJ_LCh cj_oklab_to_lch(CJ_Lab c);
CJ_Lab cj_lch_to_oklab(CJ_LCh c);

/* Perceptual distance in OKLab (ΔE) */
float cj_delta_e(CJ_Lab a, CJ_Lab b);

/* ========================================================================
 * Utility Functions
 * ======================================================================== */

/* Clamp RGB to valid range */
CJ_RGB cj_rgb_clamp(CJ_RGB c);

/* Check if color is readable (not too dark or light for UI) */
bool cj_is_readable(CJ_Lab c);

/* Adjust color to meet minimum contrast with another */
CJ_Lab cj_enforce_contrast(CJ_Lab color, CJ_Lab reference, float min_delta_e);

#ifdef __cplusplus
}
#endif

#endif /* COLOUR_JOURNEY_H */