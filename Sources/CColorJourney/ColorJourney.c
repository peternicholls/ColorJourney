/*
 * ColorJourney System - Core Implementation
 * OKLab-based perceptually uniform color journeys
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

static inline float fast_cbrt(float x) {
    union { float f; uint32_t i; } u;
    u.f = x;
    u.i = u.i / 3 + 0x2a514067;
    
    float y = u.f;
    y = (2.0f * y + x / (y * y)) * 0.333333333f;
    
    return y;
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
 * ======================================================================== */

CJ_Lab cj_rgb_to_oklab(CJ_RGB c) {
    /* RGB to LMS */
    float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
    float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
    float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

    float l_ = fast_cbrt(l);
    float m_ = fast_cbrt(m);
    float s_ = fast_cbrt(s);

    CJ_Lab result;
    result.L = 0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_;
    result.a = 1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_;
    result.b = 0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_;
    
    return result;
}

CJ_RGB cj_oklab_to_rgb(CJ_Lab c) {
    /* Oklab to LMS */
    float l_ = c.L + 0.3963377774f * c.a + 0.2158037573f * c.b;
    float m_ = c.L - 0.1055613458f * c.a - 0.0638541728f * c.b;
    float s_ = c.L - 0.0894841775f * c.a - 1.2914855480f * c.b;

    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;

    CJ_RGB result;
    result.r = +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s;
    result.g = -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s;
    result.b = -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s;
    
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
    
    /* Precomputed discrete palette (if requested) */
    CJ_RGB* discrete_cache;
    int discrete_count;
    
    /* Variation state */
    uint64_t rng_state;
} CJ_Journey_Impl;

/* ========================================================================
 * Pseudo-random number generation (xoshiro128+)
 * For deterministic variation with seed
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
    j->discrete_cache = NULL;
    j->discrete_count = 0;
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
    free(j->discrete_cache);
    free(j);
}

/* ========================================================================
 * Journey Sampling
 * ======================================================================== */

/* Interpolate between waypoints with designed easing */
static CJ_LCh interpolate_waypoints(CJ_Journey_Impl* j, float t) {
    if (j->waypoint_count == 0) {
        CJ_LCh result = {0.5f, 0.1f, 0.0f};
        return result;
    }
    
    /* Handle looping */
    if (j->config.loop_mode == CJ_LOOP_CLOSED) {
        t = fmodf(t, 1.0f);
        if (t < 0) t += 1.0f;
    } else if (j->config.loop_mode == CJ_LOOP_PINGPONG) {
        t = fmodf(t, 2.0f);
        if (t < 0) t += 2.0f;
        if (t > 1.0f) t = 2.0f - t;
    }
    
    t = clampf(t, 0.0f, 1.0f);
    
    /* Find segment */
    float segment_size = 1.0f / (float)(j->waypoint_count - 1);
    int segment = (int)(t / segment_size);
    if (segment >= j->waypoint_count - 1) segment = j->waypoint_count - 2;
    
    float local_t = (t - segment * segment_size) / segment_size;
    local_t = smoothstep(local_t);  /* Apply easing */
    
    CJ_LCh a = j->waypoints[segment].anchor;
    CJ_LCh b = j->waypoints[segment + 1].anchor;
    
    /* Interpolate in LCh space */
    CJ_LCh result;
    result.L = lerpf(a.L, b.L, local_t);
    result.C = lerpf(a.C, b.C, local_t);
    
    /* Handle hue wrapping for shortest path */
    float hue_diff = b.h - a.h;
    if (hue_diff > M_PI) hue_diff -= 2.0f * M_PI;
    if (hue_diff < -M_PI) hue_diff += 2.0f * M_PI;
    result.h = a.h + hue_diff * local_t;
    while (result.h < 0) result.h += 2.0f * M_PI;
    while (result.h >= 2.0f * M_PI) result.h -= 2.0f * M_PI;
    
    return result;
}

/* Apply dynamics and biases */
static CJ_LCh apply_dynamics(CJ_Journey_Impl* j, CJ_LCh color, float t) {
    /* Lightness bias */
    switch (j->config.lightness_bias) {
        case CJ_LIGHTNESS_LIGHTER:
            color.L = lerpf(color.L, 1.0f, 0.2f);
            break;
        case CJ_LIGHTNESS_DARKER:
            color.L = lerpf(color.L, 0.0f, 0.2f);
            break;
        case CJ_LIGHTNESS_CUSTOM:
            color.L += j->config.lightness_custom_weight * 0.2f;
            break;
        default:
            break;
    }
    
    /* Chroma bias */
    switch (j->config.chroma_bias) {
        case CJ_CHROMA_MUTED:
            color.C *= 0.6f;
            break;
        case CJ_CHROMA_VIVID:
            color.C *= 1.4f;
            break;
        case CJ_CHROMA_CUSTOM:
            color.C *= j->config.chroma_custom_multiplier;
            break;
        default:
            break;
    }
    
    /* Mid-journey vibrancy boost */
    float mid_boost = 1.0f + j->config.mid_journey_vibrancy * 
                      (1.0f - 4.0f * (t - 0.5f) * (t - 0.5f));
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

void cj_journey_discrete(CJ_Journey journey, int count, CJ_RGB* out_colors) {
    CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
    
    if (count <= 0) return;
    
    /* Determine contrast threshold */
    float min_delta_e = 0.1f;
    switch (j->config.contrast_level) {
        case CJ_CONTRAST_LOW:
            min_delta_e = 0.05f;
            break;
        case CJ_CONTRAST_HIGH:
            min_delta_e = 0.15f;
            break;
        case CJ_CONTRAST_CUSTOM:
            min_delta_e = j->config.contrast_custom_threshold;
            break;
        default:
            min_delta_e = 0.1f;
            break;
    }
    
    /* Generate evenly spaced samples */
    for (int i = 0; i < count; i++) {
        float t = (float)i / (float)(count - 1);
        if (count == 1) t = 0.5f;
        
        CJ_RGB color = cj_journey_sample(journey, t);
        
        /* Enforce contrast with previous color */
        if (i > 0) {
            CJ_Lab prev_lab = cj_rgb_to_oklab(out_colors[i - 1]);
            CJ_Lab curr_lab = cj_rgb_to_oklab(color);
            
            curr_lab = cj_enforce_contrast(curr_lab, prev_lab, min_delta_e);
            color = cj_oklab_to_rgb(curr_lab);
            color = cj_rgb_clamp(color);
        }
        
        out_colors[i] = color;
    }
}