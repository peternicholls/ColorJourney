#ifndef OKLAB_H
#define OKLAB_H
#include <stdint.h>
#include <math.h>
// Represents a color in the OKLab color space.
typedef struct {
    double l; // Lightness
    double a; // Green-Red axis
    double b; // Blue-Yellow axis
} oklab;
// Represents a color in linear sRGB space (0.0 to 1.0).
typedef union {
    struct { double r, g, b; };
    double v[3];
} linear_srgb;
// Represents a color in standard sRGB space (0-255).
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} srgb_u8;
// Function Prototypes
oklab srgb_to_oklab(srgb_u8 rgb);
srgb_u8 oklab_to_srgb(oklab c);
double delta_e_ok(oklab c1, oklab c2);
oklab lerp_oklab(oklab c1, oklab c2, double t);
double cubic_bezier(double t, double p1, double p2);
double get_easing(const char* style, double t, double p1, double p2);

// Utility: Linear interpolation
static inline double lerp(double a, double b, double t) {
    return a * (1.0 - t) + b * t;
}

#endif // OKLAB_H