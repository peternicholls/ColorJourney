#ifndef PARITY_STATS_H
#define PARITY_STATS_H

#include "types.h"

int init_histogram(Histogram *hist, double min_value, double max_value, size_t bucket_count);
void record_histogram(Histogram *hist, double value);
void free_histogram(Histogram *hist);
void compute_metric_stats(const double *values, size_t count, MetricStats *out);

#endif
