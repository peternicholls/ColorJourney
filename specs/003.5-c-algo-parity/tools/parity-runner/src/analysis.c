#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "types.h"

static void set_error(ValidationError *error, const char *message) {
    if (!error || !message) {
        return;
    }
    free(error->message);
    size_t len = strlen(message);
    error->message = (char *)malloc(len + 1);
    if (error->message) {
        memcpy(error->message, message, len + 1);
    }
}

static double compute_z_score(double magnitude, const MetricStats *stats) {
    if (!stats || stats->stddev <= 0.0) {
        return 0.0;
    }
    return (magnitude - stats->mean) / stats->stddev;
}

static const MetricStats *stats_for_metric(const char *metric, const RunSummary *summary) {
    if (!metric || !summary) {
        return NULL;
    }
    if (strcmp(metric, "deltaE") == 0) return &summary->stats.delta_e;
    if (strcmp(metric, "oklab.l") == 0) return &summary->stats.l;
    if (strcmp(metric, "oklab.a") == 0) return &summary->stats.a;
    if (strcmp(metric, "oklab.b") == 0) return &summary->stats.b;
    if (strcmp(metric, "srgb.r") == 0) return &summary->stats.rgb_r;
    if (strcmp(metric, "srgb.g") == 0) return &summary->stats.rgb_g;
    if (strcmp(metric, "srgb.b") == 0) return &summary->stats.rgb_b;
    return NULL;
}

int compute_contributors(const ComparisonResult *result,
                         const RunSummary *summary,
                         size_t top_n,
                         Contributor **out,
                         size_t *out_count,
                         ValidationError *error) {
    if (!result || !summary || !out || !out_count) {
        set_error(error, "invalid contributor arguments");
        return -1;
    }
    if (result->sample_count == 0) {
        *out = NULL;
        *out_count = 0;
        return 0;
    }

    const size_t metric_total = 7; /* deltaE, L, a, b, R, G, B */
    typedef struct {
        const char *metric;
        double magnitude;
        double signed_value;
        double z_score;
    } RawContributor;

    RawContributor metrics[7] = {
        {.metric = "deltaE", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "oklab.l", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "oklab.a", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "oklab.b", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "srgb.r", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "srgb.g", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
        {.metric = "srgb.b", .magnitude = 0.0, .signed_value = 0.0, .z_score = 0.0},
    };

    for (size_t i = 0; i < result->sample_count; ++i) {
        const SampleDelta *sample = &result->samples[i];

        const double diff_l = sample->alternate.oklab.l - sample->canonical.oklab.l;
        const double diff_a = sample->alternate.oklab.a - sample->canonical.oklab.a;
        const double diff_b = sample->alternate.oklab.b - sample->canonical.oklab.b;
        const double diff_r = sample->alternate.srgb.r - sample->canonical.srgb.r;
        const double diff_g = sample->alternate.srgb.g - sample->canonical.srgb.g;
        const double diff_b_rgb = sample->alternate.srgb.b - sample->canonical.srgb.b;

        const double mag_de = sample->delta.deltaE;
        if (mag_de > metrics[0].magnitude) {
            metrics[0].magnitude = mag_de;
            metrics[0].signed_value = mag_de; /* deltaE is magnitude only */
        }

        const double mag_l = fabs(diff_l);
        if (mag_l > metrics[1].magnitude) {
            metrics[1].magnitude = mag_l;
            metrics[1].signed_value = diff_l;
        }

        const double mag_a = fabs(diff_a);
        if (mag_a > metrics[2].magnitude) {
            metrics[2].magnitude = mag_a;
            metrics[2].signed_value = diff_a;
        }

        const double mag_b = fabs(diff_b);
        if (mag_b > metrics[3].magnitude) {
            metrics[3].magnitude = mag_b;
            metrics[3].signed_value = diff_b;
        }

        const double mag_r = fabs(diff_r);
        if (mag_r > metrics[4].magnitude) {
            metrics[4].magnitude = mag_r;
            metrics[4].signed_value = diff_r;
        }

        const double mag_g = fabs(diff_g);
        if (mag_g > metrics[5].magnitude) {
            metrics[5].magnitude = mag_g;
            metrics[5].signed_value = diff_g;
        }

        const double mag_b_rgb = fabs(diff_b_rgb);
        if (mag_b_rgb > metrics[6].magnitude) {
            metrics[6].magnitude = mag_b_rgb;
            metrics[6].signed_value = diff_b_rgb;
        }
    }

    for (size_t i = 0; i < metric_total; ++i) {
        metrics[i].z_score = compute_z_score(metrics[i].magnitude, stats_for_metric(metrics[i].metric, summary));
    }

    /* sort by magnitude descending */
    for (size_t i = 0; i < metric_total; ++i) {
        size_t max_idx = i;
        for (size_t j = i + 1; j < metric_total; ++j) {
            if (metrics[j].magnitude > metrics[max_idx].magnitude) {
                max_idx = j;
            }
        }
        if (max_idx != i) {
            RawContributor tmp = metrics[i];
            metrics[i] = metrics[max_idx];
            metrics[max_idx] = tmp;
        }
    }

    if (top_n == 0 || top_n > metric_total) {
        top_n = metric_total;
    }

    const size_t actual = top_n;

    Contributor *contributors = (Contributor *)calloc(actual, sizeof(Contributor));
    if (!contributors) {
        set_error(error, "failed to allocate contributors");
        return -1;
    }

    size_t placed = 0;
    for (size_t i = 0; i < top_n && placed < actual; ++i) {
        Contributor *dest = &contributors[placed];
        strncpy(dest->metric, metrics[i].metric, sizeof(dest->metric) - 1);
        dest->magnitude = metrics[i].magnitude;
        dest->z_score = metrics[i].z_score;
        if (metrics[i].signed_value > 1e-12) {
            strncpy(dest->direction, "higher", sizeof(dest->direction) - 1);
        } else if (metrics[i].signed_value < -1e-12) {
            strncpy(dest->direction, "lower", sizeof(dest->direction) - 1);
        } else {
            strncpy(dest->direction, "flat", sizeof(dest->direction) - 1);
        }
        dest->significant = (fabs(dest->z_score) >= 2.0) ? 1 : 0;

        const StageHint *hint = lookup_stage_hint(metrics[i].metric);
        dest->stage = hint && hint->stage ? hint->stage : "unknown-stage";
        dest->parameter = hint && hint->parameter ? hint->parameter : "unknown-parameter";
        placed++;
    }

    *out = contributors;
    *out_count = placed;
    return 0;
}
