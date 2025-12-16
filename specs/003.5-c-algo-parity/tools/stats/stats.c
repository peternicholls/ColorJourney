#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "stats.h"

static int compare_double(const void *a, const void *b) {
    const double da = *(const double *)a;
    const double db = *(const double *)b;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

int init_histogram(Histogram *hist, double min_value, double max_value, size_t bucket_count) {
    if (!hist || bucket_count == 0 || max_value <= min_value) {
        return -1;
    }
    memset(hist, 0, sizeof(Histogram));
    hist->min_value = min_value;
    hist->max_value = max_value;
    hist->bucket_count = bucket_count;
    hist->bucket_size = (max_value - min_value) / (double)bucket_count;
    hist->counts = (size_t *)calloc(bucket_count, sizeof(size_t));
    return hist->counts ? 0 : -1;
}

void record_histogram(Histogram *hist, double value) {
    if (!hist || !hist->counts || hist->bucket_size <= 0) {
        return;
    }
    if (value < hist->min_value) {
        value = hist->min_value;
    }
    if (value > hist->max_value) {
        value = hist->max_value;
    }
    size_t index = (size_t)((value - hist->min_value) / hist->bucket_size);
    if (index >= hist->bucket_count) {
        index = hist->bucket_count - 1;
    }
    hist->counts[index] += 1;
}

void free_histogram(Histogram *hist) {
    if (!hist) {
        return;
    }
    free(hist->counts);
    memset(hist, 0, sizeof(Histogram));
}

void compute_metric_stats(const double *values, size_t count, MetricStats *out) {
    if (!out) {
        return;
    }
    memset(out, 0, sizeof(MetricStats));
    if (!values || count == 0) {
        return;
    }

    double sum = 0.0;
    out->min = values[0];
    out->max = values[0];
    for (size_t i = 0; i < count; ++i) {
        const double v = values[i];
        sum += v;
        if (v < out->min) out->min = v;
        if (v > out->max) out->max = v;
    }
    out->mean = sum / (double)count;

    double variance = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double diff = values[i] - out->mean;
        variance += diff * diff;
    }
    out->stddev = count > 1 ? sqrt(variance / (double)(count - 1)) : 0.0;

    double *sorted = (double *)malloc(count * sizeof(double));
    if (!sorted) {
        return;
    }
    memcpy(sorted, values, count * sizeof(double));
    qsort(sorted, count, sizeof(double), compare_double);

    const double mid = (double)(count - 1);
    out->p50 = sorted[(size_t)floor(0.50 * mid + 0.5)];
    out->p95 = sorted[(size_t)floor(0.95 * mid + 0.5)];
    out->p99 = sorted[(size_t)floor(0.99 * mid + 0.5)];

    free(sorted);
}
