#ifndef PARITY_TYPES_H
#define PARITY_TYPES_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ID_LENGTH 128
#define MAX_VERSION_LENGTH 32
#define MAX_ERROR_MESSAGE 512
#define MAX_ENGINE_NAME 32
#define MAX_PATH_LENGTH 512

struct Contributor;

typedef struct {
    double l;
    double a;
    double b;
} OklabColor;

typedef struct {
    double r;
    double g;
    double b;
} SrgbColor;

typedef struct {
    bool has_oklab;
    bool has_srgb;
    OklabColor oklab;
    SrgbColor srgb;
} Anchor;

typedef struct {
    double lightness;
    double chroma;
    double contrast;
    double vibrancy;
    double temperature;
    char *loop_mode;
    uint64_t variation_seed;
    bool has_variation_seed;
    uint32_t count;
} EngineConfig;

typedef struct {
    char id[MAX_ID_LENGTH];
    Anchor *anchors;
    size_t anchor_count;
    EngineConfig config;
    uint64_t seed;
    char corpus_version[MAX_VERSION_LENGTH];
    char *notes;
    char **tags;
    size_t tag_count;
} InputCase;

typedef struct {
    char corpus_version[MAX_VERSION_LENGTH];
    char *description;
    InputCase *cases;
    size_t case_count;
} Corpus;

typedef struct {
    double l;
    double a;
    double b;
    double deltaE;
} ToleranceAbs;

typedef struct {
    double l;
    double a;
    double b;
} ToleranceRel;

typedef struct {
    char version[MAX_VERSION_LENGTH];
    char *description;
    ToleranceAbs abs;
    ToleranceRel rel;
    double fail_threshold;
    char *policy_notes;
    char *provenance_source;
    char *provenance_updated;
} ToleranceConfig;

typedef struct {
    double l;
    double a;
    double b;
    double deltaE;
} ComparisonDelta;

typedef struct {
    OklabColor oklab;
    SrgbColor srgb;
} EngineColor;

typedef struct {
    char engine[MAX_ENGINE_NAME];
    EngineColor *colors;
    size_t color_count;
    double duration_ms;
    char *commit;
    char *build_flags;
    char *platform;
} EngineOutput;

typedef struct {
    size_t index;
    EngineColor canonical;
    EngineColor alternate;
    ComparisonDelta delta;
    SrgbColor rgb_delta;
} SampleDelta;

typedef struct {
    char input_case_id[MAX_ID_LENGTH];
    SampleDelta *samples;
    size_t sample_count;
    int passed;
    double max_delta_e;
    double max_l;
    double max_a;
    double max_b;
    double max_rgb_r;
    double max_rgb_g;
    double max_rgb_b;
    struct Contributor *contributors;
    size_t contributor_count;
} ComparisonResult;

typedef struct {
    double mean;
    double stddev;
    double p50;
    double p95;
    double p99;
    double min;
    double max;
} MetricStats;

typedef struct {
    double min_value;
    double max_value;
    double bucket_size;
    size_t bucket_count;
    size_t *counts;
} Histogram;

typedef struct {
    MetricStats delta_e;
    MetricStats l;
    MetricStats a;
    MetricStats b;
    MetricStats rgb_r;
    MetricStats rgb_g;
    MetricStats rgb_b;
    Histogram delta_e_hist;
} RunStats;

typedef struct {
    char *message;
} ValidationError;

typedef struct {
    size_t total_cases;
    size_t passed;
    size_t failed;
    double duration_ms;
    double pass_rate;
    RunStats stats;
} RunSummary;

typedef struct {
    char *run_id;
    char *c_commit;
    char *wasm_commit;
    char *platform;
    char *corpus_version;
    char *artifacts_root;
    char *c_build_flags;
    char *alt_build_flags;
    double max_duration_ms;
    double pass_gate;
    const char *artifact_policy;
} RunProvenance;

typedef struct {
    ComparisonResult *results;
    size_t result_count;
    RunSummary summary;
} RunResults;

typedef struct {
    const char *metric;
    const char *label;
    const char *stage;
    const char *parameter;
} StageHint;

typedef struct Contributor {
    char metric[32];
    double magnitude;
    double z_score;
    char direction[8];
    const char *stage;
    const char *parameter;
    int significant;
} Contributor;

// Validation helpers
int validate_corpus_version(const char *version);
int parse_corpus_file(const char *path, Corpus *out, ValidationError *error);
int parse_tolerances_file(const char *path, ToleranceConfig *out, ValidationError *error);
void free_corpus(Corpus *corpus);
void free_tolerances(ToleranceConfig *config);

// Engine execution and parsing
int run_c_engine(const char *binary_path,
                 const char *corpus_path,
                 const char *case_id,
                 EngineOutput *out,
                 ValidationError *error);

int run_alt_engine(const char *binary_path,
                   const char *corpus_path,
                   const char *case_id,
                   EngineOutput *out,
                   ValidationError *error);

int parse_engine_output(const char *buffer, EngineOutput *out, ValidationError *error);
void free_engine_output(EngineOutput *output);

// Comparison helpers
int comparison_within_tolerance(const ComparisonDelta *delta, const ToleranceConfig *tolerance);
double delta_e_oklab(const OklabColor *a, const OklabColor *b);
int compare_engine_outputs(const EngineOutput *canonical,
                           const EngineOutput *alternate,
                           const ToleranceConfig *tolerance,
                           const InputCase *input_case,
                           ComparisonResult *result);
void free_comparison_result(ComparisonResult *result);

// Statistics helpers
int init_histogram(Histogram *hist, double min_value, double max_value, size_t bucket_count);
void record_histogram(Histogram *hist, double value);
void free_histogram(Histogram *hist);
void compute_metric_stats(const double *values, size_t count, MetricStats *out);

// Analysis helpers
const StageHint *lookup_stage_hint(const char *metric);
int compute_contributors(const ComparisonResult *result,
                         const RunSummary *summary,
                         size_t top_n,
                         Contributor **out,
                         size_t *out_count,
                         ValidationError *error);

// Reporting helpers
int write_case_artifacts(const char *artifacts_root,
                         const InputCase *input_case,
                         const EngineOutput *canonical,
                         const EngineOutput *alternate,
                         const ComparisonResult *result,
                         ValidationError *error);

int write_case_metadata(const char *artifacts_root,
                        const InputCase *input_case,
                        const ComparisonResult *result,
                        ValidationError *error);

int write_run_report(const char *artifacts_root,
                     const RunProvenance *provenance,
                     const RunResults *results,
                     const ToleranceConfig *tolerance,
                     ValidationError *error);
int ensure_directory(const char *path, ValidationError *error);

#endif // PARITY_TYPES_H
