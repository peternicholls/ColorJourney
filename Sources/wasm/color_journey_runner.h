#ifndef COLOR_JOURNEY_RUNNER_H
#define COLOR_JOURNEY_RUNNER_H

#include <stdbool.h>
#include <stdint.h>

#include "oklab.h"

typedef struct {
    double lightness;
    double chroma;
    double contrast;
    double vibrancy;
    double warmth;
    double bezier_light[2];
    double bezier_chroma[2];
    uint32_t seed;
    int num_colors;
    int num_anchors;
    int loop_mode;       /* 0: open, 1: closed, 2: ping-pong */
    int variation_mode;  /* 0: off, 1: subtle, 2: noticeable */
    bool enable_color_circle;
    double arc_length;
    char curve_style[16];
    int curve_dimensions; /* bitflags: 1=L, 2=C, 4=H, 8=all */
    double curve_strength;
} CJ_Config;

typedef struct {
    oklab ok;
    srgb_u8 rgb;
    int enforcement_iters;
} CJ_ColorPoint;

CJ_ColorPoint *generate_discrete_palette(CJ_Config *config, oklab *anchors);
void wasm_free(void *ptr);

#endif
