#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "cJSON.h"
#include "types.h"

int comparison_within_tolerance(const ComparisonDelta *delta, const ToleranceConfig *tolerance) {
    if (!delta || !tolerance) {
        return 0;
    }

    const double abs_l = fabs(delta->l);
    const double abs_a = fabs(delta->a);
    const double abs_b = fabs(delta->b);
    const double abs_de = fabs(delta->deltaE);

    if (abs_l > tolerance->abs.l && tolerance->abs.l > 0) {
        return 0;
    }
    if (abs_a > tolerance->abs.a && tolerance->abs.a > 0) {
        return 0;
    }
    if (abs_b > tolerance->abs.b && tolerance->abs.b > 0) {
        return 0;
    }
    if (tolerance->abs.deltaE > 0 && abs_de > tolerance->abs.deltaE) {
        return 0;
    }

    if (tolerance->rel.l > 0 && abs_l > tolerance->rel.l * fabs(tolerance->abs.l + 1.0)) {
        return 0;
    }
    if (tolerance->rel.a > 0 && abs_a > tolerance->rel.a * fabs(tolerance->abs.a + 1.0)) {
        return 0;
    }
    if (tolerance->rel.b > 0 && abs_b > tolerance->rel.b * fabs(tolerance->abs.b + 1.0)) {
        return 0;
    }

    return 1;
}

double delta_e_oklab(const OklabColor *a, const OklabColor *b) {
    if (!a || !b) {
        return 0.0;
    }
    const double dl = a->l - b->l;
    const double da = a->a - b->a;
    const double db = a->b - b->b;
    return sqrt((dl * dl) + (da * da) + (db * db));
}

int compare_engine_outputs(const EngineOutput *canonical,
                           const EngineOutput *alternate,
                           const ToleranceConfig *tolerance,
                           const InputCase *input_case,
                           ComparisonResult *result) {
    if (!canonical || !alternate || !tolerance || !input_case || !result) {
        return -1;
    }

    memset(result, 0, sizeof(ComparisonResult));
    strncpy(result->input_case_id, input_case->id, sizeof(result->input_case_id) - 1);

    const size_t expected = input_case->config.count;
    const size_t sample_count = (canonical->color_count < alternate->color_count)
                                    ? canonical->color_count
                                    : alternate->color_count;

    if (sample_count == 0 || expected == 0) {
        result->passed = 0;
        return -1;
    }

    if (sample_count != expected || canonical->color_count != alternate->color_count) {
        result->passed = 0;
    }

    result->samples = (SampleDelta *)calloc(sample_count, sizeof(SampleDelta));
    if (!result->samples) {
        return -1;
    }

    int passed = 1;
    double max_delta = 0.0;
    double max_l = 0.0;
    double max_a = 0.0;
    double max_b = 0.0;
    double max_rgb_r = 0.0;
    double max_rgb_g = 0.0;
    double max_rgb_b = 0.0;

    for (size_t i = 0; i < sample_count; ++i) {
        SampleDelta *sample = &result->samples[i];
        sample->index = i;
        sample->canonical = canonical->colors[i];
        sample->alternate = alternate->colors[i];

        sample->delta.l = sample->canonical.oklab.l - sample->alternate.oklab.l;
        sample->delta.a = sample->canonical.oklab.a - sample->alternate.oklab.a;
        sample->delta.b = sample->canonical.oklab.b - sample->alternate.oklab.b;
        sample->delta.deltaE = delta_e_oklab(&sample->canonical.oklab, &sample->alternate.oklab);

        sample->rgb_delta.r = sample->canonical.srgb.r - sample->alternate.srgb.r;
        sample->rgb_delta.g = sample->canonical.srgb.g - sample->alternate.srgb.g;
        sample->rgb_delta.b = sample->canonical.srgb.b - sample->alternate.srgb.b;

        if (!comparison_within_tolerance(&sample->delta, tolerance)) {
            passed = 0;
        }
        if (sample->delta.deltaE > max_delta) {
            max_delta = sample->delta.deltaE;
        }
        const double abs_l = fabs(sample->delta.l);
        const double abs_a = fabs(sample->delta.a);
        const double abs_b = fabs(sample->delta.b);
        const double abs_r = fabs(sample->rgb_delta.r);
        const double abs_g = fabs(sample->rgb_delta.g);
        const double abs_b_rgb = fabs(sample->rgb_delta.b);

        if (abs_l > max_l) max_l = abs_l;
        if (abs_a > max_a) max_a = abs_a;
        if (abs_b > max_b) max_b = abs_b;
        if (abs_r > max_rgb_r) max_rgb_r = abs_r;
        if (abs_g > max_rgb_g) max_rgb_g = abs_g;
        if (abs_b_rgb > max_rgb_b) max_rgb_b = abs_b_rgb;
    }

    result->sample_count = sample_count;
    result->passed = passed;
    result->max_delta_e = max_delta;
    result->max_l = max_l;
    result->max_a = max_a;
    result->max_b = max_b;
    result->max_rgb_r = max_rgb_r;
    result->max_rgb_g = max_rgb_g;
    result->max_rgb_b = max_rgb_b;
    return 0;
}

void free_comparison_result(ComparisonResult *result) {
    if (!result) {
        return;
    }
    free(result->samples);
    free(result->contributors);
    memset(result, 0, sizeof(ComparisonResult));
}
