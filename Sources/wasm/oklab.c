#include "oklab.h"
#include <string.h> // For strcmp
#include <math.h>
// --- sRGB <-> Linear sRGB ---
static double srgb_to_linear(double c) {
    return c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92;
}
static double linear_to_srgb(double c) {
    return c > 0.0031308 ? 1.055 * pow(c, 1.0 / 2.4) - 0.055 : 12.92 * c;
}
// --- Matrix Constants ---
static const double M1[3][3] = {
    {0.4122214708, 0.5363325363, 0.0514459929},
    {0.2119034982, 0.6806995451, 0.1073969566},
    {0.0883024619, 0.2817188376, 0.6299787005},
};
static const double M2[3][3] = {
    {+0.2104542553, +0.7936177850, -0.0040720468},
    {+1.9779984951, -2.4285922050, +0.4505937099},
    {+0.0259040371, +0.7827717662, -0.8086757660},
};
static const double M2_INV[3][3] = {
    {1.0, +0.3963377774, +0.2158037573},
    {1.0, -0.1055613458, -0.0638541728},
    {1.0, -0.0894841775, -1.2914855480},
};
static const double M1_INV[3][3] = {
    {+4.0767416621, -3.3077115913, +0.2309699292},
    {-1.2684380046, +2.6097574011, -0.3413193965},
    {-0.0041960863, -0.7034186147, +1.7076147010},
};
// --- Core Conversion Functions ---
static linear_srgb oklab_to_linear_srgb(oklab c) {
    double l_ = c.l + M2_INV[0][1] * c.a + M2_INV[0][2] * c.b;
    double m_ = c.l + M2_INV[1][1] * c.a + M2_INV[1][2] * c.b;
    double s_ = c.l + M2_INV[2][1] * c.a + M2_INV[2][2] * c.b;
    double l = l_ * l_ * l_;
    double m = m_ * m_ * m_;
    double s = s_ * s_ * s_;
    linear_srgb result = {
        M1_INV[0][0] * l + M1_INV[0][1] * m + M1_INV[0][2] * s,
        M1_INV[1][0] * l + M1_INV[1][1] * m + M1_INV[1][2] * s,
        M1_INV[2][0] * l + M1_INV[2][1] * m + M1_INV[2][2] * s
    };
    return result;
}
oklab srgb_to_oklab(srgb_u8 rgb) {
    linear_srgb lin_rgb = {
        srgb_to_linear(rgb.r / 255.0),
        srgb_to_linear(rgb.g / 255.0),
        srgb_to_linear(rgb.b / 255.0)
    };
    double l = M1[0][0] * lin_rgb.r + M1[0][1] * lin_rgb.g + M1[0][2] * lin_rgb.b;
    double m = M1[1][0] * lin_rgb.r + M1[1][1] * lin_rgb.g + M1[1][2] * lin_rgb.b;
    double s = M1[2][0] * lin_rgb.r + M1[2][1] * lin_rgb.g + M1[2][2] * lin_rgb.b;
    double l_ = cbrt(l);
    double m_ = cbrt(m);
    double s_ = cbrt(s);
    oklab result = {
        M2[0][0] * l_ + M2[0][1] * m_ + M2[0][2] * s_,
        M2[1][0] * l_ + M2[1][1] * m_ + M2[1][2] * s_,
        M2[2][0] * l_ + M2[2][1] * m_ + M2[2][2] * s_
    };
    return result;
}
// --- Gamut Clipping ---
static double find_gamut_intersection(oklab a, oklab b) {
    double t = 1.0;
    for (int i = 0; i < 3; ++i) {
        linear_srgb la = oklab_to_linear_srgb(a);
        linear_srgb lb = oklab_to_linear_srgb(b);
        double c1 = la.v[i];
        double c2 = lb.v[i];
        if (c2 < 0.0) { t = fmin(t, c1 / (c1 - c2)); }
        if (c2 > 1.0) { t = fmin(t, (1.0 - c1) / (c2 - c1)); }
    }
    return t;
}
srgb_u8 oklab_to_srgb(oklab c) {
    linear_srgb lin_rgb = oklab_to_linear_srgb(c);
    if (lin_rgb.r < 0.0 || lin_rgb.r > 1.0 || lin_rgb.g < 0.0 || lin_rgb.g > 1.0 || lin_rgb.b < 0.0 || lin_rgb.b > 1.0) {
        double chroma = sqrt(c.a * c.a + c.b * c.b);
        if (chroma < 1e-7) {
            double L = fmax(0.0, fmin(1.0, c.l));
            oklab gray = {L, 0, 0};
            lin_rgb = oklab_to_linear_srgb(gray);
        } else {
            oklab mid = {c.l, 0, 0};
            double t = find_gamut_intersection(mid, c);
            c.a *= t;
            c.b *= t;
            lin_rgb = oklab_to_linear_srgb(c);
        }
    }
    srgb_u8 result = {
        (uint8_t)round(fmax(0.0, fmin(1.0, linear_to_srgb(lin_rgb.r))) * 255.0),
        (uint8_t)round(fmax(0.0, fmin(1.0, linear_to_srgb(lin_rgb.g))) * 255.0),
        (uint8_t)round(fmax(0.0, fmin(1.0, linear_to_srgb(lin_rgb.b))) * 255.0)
    };
    return result;
}
// --- Utility Functions ---
double delta_e_ok(oklab c1, oklab c2) {
    double dL = c1.l - c2.l;
    double da = c1.a - c2.a;
    double db = c1.b - c2.b;
    return sqrt(dL * dL + da * da + db * db);
}
oklab lerp_oklab(oklab c1, oklab c2, double t) {
    oklab result = {
        c1.l * (1.0 - t) + c2.l * t,
        c1.a * (1.0 - t) + c2.a * t,
        c1.b * (1.0 - t) + c2.b * t
    };
    return result;
}
double cubic_bezier(double t, double p1, double p2) {
    double u = 1.0 - t;
    double tt = t * t;
    double uu = u * u;
    return 3.0 * uu * t * p1 + 3.0 * u * tt * p2 + tt * t;
}
double get_easing(const char* style, double t, double p1, double p2) {
    if (strcmp(style, "ease-in") == 0) return cubic_bezier(t, 0.42, 0);
    if (strcmp(style, "ease-out") == 0) return cubic_bezier(t, 0, 0.58);
    if (strcmp(style, "sinusoidal") == 0) return 0.5 - 0.5 * cos(t * M_PI);
    if (strcmp(style, "stepped") == 0) return floor(t * 5.0) / 4.0;
    if (strcmp(style, "custom") == 0) return cubic_bezier(t, p1, p2);
    return t; // linear
}