#ifndef PARITY_TYPES_H
#define PARITY_TYPES_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ID_LENGTH 128
#define MAX_VERSION_LENGTH 32
#define MAX_ERROR_MESSAGE 512

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
    char *message;
} ValidationError;

typedef struct {
    size_t total_cases;
    size_t passed;
    size_t failed;
    double duration_ms;
} RunSummary;

typedef struct {
    char *run_id;
    char *c_commit;
    char *wasm_commit;
    char *platform;
    char *corpus_version;
    char *artifacts_root;
} RunProvenance;

// Validation helpers
int validate_corpus_version(const char *version);
int parse_corpus_file(const char *path, Corpus *out, ValidationError *error);
int parse_tolerances_file(const char *path, ToleranceConfig *out, ValidationError *error);
void free_corpus(Corpus *corpus);
void free_tolerances(ToleranceConfig *config);

// Comparison helpers
int comparison_within_tolerance(const ComparisonDelta *delta, const ToleranceConfig *tolerance);
double delta_e_oklab(const OklabColor *a, const OklabColor *b);

// Reporting helpers
int write_run_report(const char *artifacts_root,
                     const RunProvenance *provenance,
                     const RunSummary *summary,
                     ValidationError *error);
int ensure_directory(const char *path, ValidationError *error);

#endif // PARITY_TYPES_H
