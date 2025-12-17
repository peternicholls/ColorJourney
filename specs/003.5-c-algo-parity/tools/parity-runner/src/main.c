#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "types.h"
#include "../stats/stats.h"

typedef enum {
    ARTIFACT_POLICY_ALL,
    ARTIFACT_POLICY_FAILURES,
    ARTIFACT_POLICY_NONE
} ArtifactPolicy;

static const char *artifact_policy_to_string(ArtifactPolicy policy) {
    switch (policy) {
        case ARTIFACT_POLICY_ALL: return "all";
        case ARTIFACT_POLICY_FAILURES: return "failures";
        case ARTIFACT_POLICY_NONE: return "none";
        default: return "unknown";
    }
}

static int case_has_tag(const InputCase *input_case, const char **tags, size_t tag_count) {
    if (!input_case || !tags || tag_count == 0) {
        return 1;
    }
    for (size_t i = 0; i < input_case->tag_count; ++i) {
        for (size_t j = 0; j < tag_count; ++j) {
            if (strcmp(input_case->tags[i], tags[j]) == 0) {
                return 1;
            }
        }
    }
    return 0;
}

static void print_usage(void) {
    printf("Usage: parity-runner --corpus <file> --tolerances <file> [--artifacts <dir>]\\n");
    printf("       [--cases <id1,id2>] [--tags <tag1,tag2>] [--c-runner <path>] [--alt-runner <path>]\\n");
    printf("       [--run-id <id>] [--c-commit <hash>] [--wasm-commit <hash>]\\n");
    printf("       [--pass-gate <0-1>] [--max-duration-ms <ms>] [--platform <name>]\\n");
    printf("       [--tolerance-deltaE <val>] [--tolerance-l <val>] [--tolerance-a <val>] [--tolerance-b <val>]\\n");
    printf("       [--artifact-policy all|failures|none]\\n");
}

static const char *detect_platform(void) {
#if defined(__APPLE__)
    return "macOS";
#elif defined(__linux__)
    return "linux";
#elif defined(_WIN32)
    return "windows";
#else
    return "unknown";
#endif
}

static int is_selected_case(const char *id, char **filters, size_t filter_count) {
    if (filter_count == 0 || !filters) {
        return 1;
    }
    for (size_t i = 0; i < filter_count; ++i) {
        if (strcmp(id, filters[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static char **split_cases(const char *csv, size_t *count_out) {
    if (!csv) {
        *count_out = 0;
        return NULL;
    }
    char *copy = strdup(csv);
    if (!copy) {
        *count_out = 0;
        return NULL;
    }
    size_t count = 1;
    for (const char *c = csv; *c; ++c) {
        if (*c == ',') count++;
    }
    char **list = (char **)calloc(count, sizeof(char *));
    if (!list) {
        free(copy);
        *count_out = 0;
        return NULL;
    }
    size_t idx = 0;
    char *token = strtok(copy, ",");
    while (token && idx < count) {
        list[idx++] = strdup(token);
        token = strtok(NULL, ",");
    }
    *count_out = idx;
    free(copy);
    return list;
}

static void free_case_filters(char **filters, size_t count) {
    if (!filters) return;
    for (size_t i = 0; i < count; ++i) {
        free(filters[i]);
    }
    free(filters);
}

static InputCase *find_input_case(const Corpus *corpus, const char *id) {
    if (!corpus || !id) {
        return NULL;
    }
    for (size_t i = 0; i < corpus->case_count; ++i) {
        if (strcmp(corpus->cases[i].id, id) == 0) {
            return &corpus->cases[i];
        }
    }
    return NULL;
}

int main(int argc, char **argv) {
    const char *corpus_path = NULL;
    const char *tolerances_path = NULL;
    const char *artifacts_path = NULL;
    const char *cases_filter = NULL;
    const char *tags_filter = NULL;
    const char *c_runner = "./parity_c_runner";
    const char *alt_runner = "./parity_wasm_as_c_runner";
    const char *run_id = NULL;
    const char *c_commit = NULL;
    const char *wasm_commit = NULL;
    const char *platform_arg = NULL;
    double pass_gate = 0.95;
    double max_duration_ms = 600000.0; /* 10 minutes */
    double tolerance_deltaE_override = -1.0;
    double tolerance_l_override = -1.0;
    double tolerance_a_override = -1.0;
    double tolerance_b_override = -1.0;
    ArtifactPolicy artifact_policy = ARTIFACT_POLICY_ALL;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--corpus") == 0 && i + 1 < argc) {
            corpus_path = argv[++i];
        } else if (strcmp(argv[i], "--tolerances") == 0 && i + 1 < argc) {
            tolerances_path = argv[++i];
        } else if (strcmp(argv[i], "--artifacts") == 0 && i + 1 < argc) {
            artifacts_path = argv[++i];
        } else if (strcmp(argv[i], "--cases") == 0 && i + 1 < argc) {
            cases_filter = argv[++i];
        } else if (strcmp(argv[i], "--tags") == 0 && i + 1 < argc) {
            tags_filter = argv[++i];
        } else if (strcmp(argv[i], "--tolerance-deltaE") == 0 && i + 1 < argc) {
            tolerance_deltaE_override = atof(argv[++i]);
        } else if (strcmp(argv[i], "--tolerance-l") == 0 && i + 1 < argc) {
            tolerance_l_override = atof(argv[++i]);
        } else if (strcmp(argv[i], "--tolerance-a") == 0 && i + 1 < argc) {
            tolerance_a_override = atof(argv[++i]);
        } else if (strcmp(argv[i], "--tolerance-b") == 0 && i + 1 < argc) {
            tolerance_b_override = atof(argv[++i]);
        } else if (strcmp(argv[i], "--artifact-policy") == 0 && i + 1 < argc) {
            const char *policy = argv[++i];
            if (strcmp(policy, "all") == 0) {
                artifact_policy = ARTIFACT_POLICY_ALL;
            } else if (strcmp(policy, "failures") == 0) {
                artifact_policy = ARTIFACT_POLICY_FAILURES;
            } else if (strcmp(policy, "none") == 0) {
                artifact_policy = ARTIFACT_POLICY_NONE;
            }
        } else if (strcmp(argv[i], "--c-runner") == 0 && i + 1 < argc) {
            c_runner = argv[++i];
        } else if (strcmp(argv[i], "--alt-runner") == 0 && i + 1 < argc) {
            alt_runner = argv[++i];
        } else if (strcmp(argv[i], "--run-id") == 0 && i + 1 < argc) {
            run_id = argv[++i];
        } else if (strcmp(argv[i], "--c-commit") == 0 && i + 1 < argc) {
            c_commit = argv[++i];
        } else if (strcmp(argv[i], "--wasm-commit") == 0 && i + 1 < argc) {
            wasm_commit = argv[++i];
        } else if (strcmp(argv[i], "--pass-gate") == 0 && i + 1 < argc) {
            pass_gate = atof(argv[++i]);
        } else if (strcmp(argv[i], "--max-duration-ms") == 0 && i + 1 < argc) {
            max_duration_ms = atof(argv[++i]);
        } else if (strcmp(argv[i], "--platform") == 0 && i + 1 < argc) {
            platform_arg = argv[++i];
        } else if (strcmp(argv[i], "--version") == 0) {
            printf("parity-runner version 0.2.0\n");
            return 0;
        } else if (strcmp(argv[i], "--help") == 0) {
            print_usage();
            return 0;
        }
    }

    char generated_run_id[64];
    if (!run_id) {
        time_t now = time(NULL);
        snprintf(generated_run_id, sizeof(generated_run_id), "run-%lld", (long long)now);
        run_id = generated_run_id;
    }

    if (!corpus_path || !tolerances_path) {
        print_usage();
        return 1;
    }

    ValidationError error = {.message = NULL};
    Corpus corpus;
    if (parse_corpus_file(corpus_path, &corpus, &error) != 0) {
        fprintf(stderr, "Corpus validation failed: %s\n", error.message ? error.message : "unknown error");
        free(error.message);
        return 1;
    }

    ToleranceConfig tolerance;
    if (parse_tolerances_file(tolerances_path, &tolerance, &error) != 0) {
        fprintf(stderr, "Tolerance validation failed: %s\n", error.message ? error.message : "unknown error");
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    /* Apply CLI tolerance overrides */
    if (tolerance_deltaE_override >= 0.0) {
        tolerance.abs.deltaE = tolerance_deltaE_override;
    }
    if (tolerance_l_override >= 0.0) {
        tolerance.abs.l = tolerance_l_override;
    }
    if (tolerance_a_override >= 0.0) {
        tolerance.abs.a = tolerance_a_override;
    }
    if (tolerance_b_override >= 0.0) {
        tolerance.abs.b = tolerance_b_override;
    }

    size_t filter_count = 0;
    char **filters = split_cases(cases_filter, &filter_count);

    size_t tag_filter_count = 0;
    char **tag_filters = split_cases(tags_filter, &tag_filter_count);

    size_t selected_cases = 0;
    for (size_t i = 0; i < corpus.case_count; ++i) {
        if (is_selected_case(corpus.cases[i].id, filters, filter_count) &&
            case_has_tag(&corpus.cases[i], (const char **)tag_filters, tag_filter_count)) {
            selected_cases++;
        }
    }

    if (selected_cases == 0) {
        fprintf(stderr, "No cases selected for execution.\n");
        free_case_filters(filters, filter_count);
        free_tolerances(&tolerance);
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    RunResults results = {0};
    results.result_count = selected_cases;
    results.results = (ComparisonResult *)calloc(selected_cases, sizeof(ComparisonResult));
    if (!results.results) {
        fprintf(stderr, "Failed to allocate comparison results.\n");
        free_case_filters(filters, filter_count);
        free_tolerances(&tolerance);
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    size_t delta_capacity = 128;
    size_t delta_count = 0;
    double *delta_e_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_l_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_a_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_b_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_r_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_g_values = (double *)malloc(delta_capacity * sizeof(double));
    double *delta_b_rgb_values = (double *)malloc(delta_capacity * sizeof(double));

    if (!delta_e_values || !delta_l_values || !delta_a_values || !delta_b_values ||
        !delta_r_values || !delta_g_values || !delta_b_rgb_values) {
        fprintf(stderr, "Failed to allocate delta buffers.\n");
        free(delta_e_values);
        free(delta_l_values);
        free(delta_a_values);
        free(delta_b_values);
        free(delta_r_values);
        free(delta_g_values);
        free(delta_b_rgb_values);
        free_case_filters(filters, filter_count);
        free_tolerances(&tolerance);
        free_corpus(&corpus);
        free(results.results);
        free(error.message);
        return 1;
    }

    char artifacts_root_buf[MAX_PATH_LENGTH];
    const char *resolved_root = artifacts_path;
    if (!resolved_root) {
        snprintf(artifacts_root_buf, sizeof(artifacts_root_buf), "specs/005-c-algo-parity/artifacts/%s", run_id);
        resolved_root = artifacts_root_buf;
    }

    RunProvenance provenance = {
        .run_id = (char *)run_id,
        .c_commit = (char *)(c_commit ? c_commit : "unknown"),
        .wasm_commit = (char *)(wasm_commit ? wasm_commit : "unknown"),
        .platform = (char *)(platform_arg ? platform_arg : detect_platform()),
        .corpus_version = corpus.corpus_version,
        .artifacts_root = (char *)resolved_root,
        .max_duration_ms = max_duration_ms,
        .pass_gate = pass_gate,
        .c_build_flags = NULL,
        .alt_build_flags = NULL
    };

    int exit_code = 0;
    const clock_t start = clock();

    size_t output_index = 0;
    for (size_t i = 0; i < corpus.case_count; ++i) {
        InputCase *input_case = &corpus.cases[i];
        if (!is_selected_case(input_case->id, filters, filter_count) ||
            !case_has_tag(input_case, (const char **)tag_filters, tag_filter_count)) {
            continue;
        }

        EngineOutput canonical = {0};
        EngineOutput alternate = {0};

        if (run_c_engine(c_runner, corpus_path, input_case->id, &canonical, &error) != 0) {
            fprintf(stderr, "Canonical runner failed for case %s: %s\n", input_case->id, error.message ? error.message : "unknown error");
            free_engine_output(&canonical);
            free_engine_output(&alternate);
            exit_code = 1;
            break;
        }
        if (run_alt_engine(alt_runner, corpus_path, input_case->id, &alternate, &error) != 0) {
            fprintf(stderr, "Alternate runner failed for case %s: %s\n", input_case->id, error.message ? error.message : "unknown error");
            free_engine_output(&canonical);
            free_engine_output(&alternate);
            exit_code = 1;
            break;
        }

        if (!provenance.c_build_flags && canonical.build_flags) {
            provenance.c_build_flags = strdup(canonical.build_flags);
        }
        if (!provenance.alt_build_flags && alternate.build_flags) {
            provenance.alt_build_flags = strdup(alternate.build_flags);
        }

        if (compare_engine_outputs(&canonical, &alternate, &tolerance, input_case, &results.results[output_index]) != 0) {
            fprintf(stderr, "Comparison failed for case %s\n", input_case->id);
        }

        /* Accumulate delta metrics */
        for (size_t s = 0; s < results.results[output_index].sample_count; ++s) {
            const ComparisonDelta *delta = &results.results[output_index].samples[s].delta;
            if (delta_count + 1 >= delta_capacity) {
                delta_capacity *= 2;
                double *tmp_e = (double *)realloc(delta_e_values, delta_capacity * sizeof(double));
                double *tmp_l = (double *)realloc(delta_l_values, delta_capacity * sizeof(double));
                double *tmp_a = (double *)realloc(delta_a_values, delta_capacity * sizeof(double));
                double *tmp_b = (double *)realloc(delta_b_values, delta_capacity * sizeof(double));
                double *tmp_r = (double *)realloc(delta_r_values, delta_capacity * sizeof(double));
                double *tmp_g = (double *)realloc(delta_g_values, delta_capacity * sizeof(double));
                double *tmp_b_rgb = (double *)realloc(delta_b_rgb_values, delta_capacity * sizeof(double));
                if (!tmp_e || !tmp_l || !tmp_a || !tmp_b || !tmp_r || !tmp_g || !tmp_b_rgb) {
                    fprintf(stderr, "Failed to grow delta buffers.\n");
                    free(tmp_e);
                    free(tmp_l);
                    free(tmp_a);
                    free(tmp_b);
                    free(tmp_r);
                    free(tmp_g);
                    free(tmp_b_rgb);
                    exit_code = 1;
                    break;
                }
                delta_e_values = tmp_e;
                delta_l_values = tmp_l;
                delta_a_values = tmp_a;
                delta_b_values = tmp_b;
                delta_r_values = tmp_r;
                delta_g_values = tmp_g;
                delta_b_rgb_values = tmp_b_rgb;
            }
            delta_e_values[delta_count] = fabs(delta->deltaE);
            delta_l_values[delta_count] = fabs(delta->l);
            delta_a_values[delta_count] = fabs(delta->a);
            delta_b_values[delta_count] = fabs(delta->b);
            delta_r_values[delta_count] = fabs(results.results[output_index].samples[s].rgb_delta.r);
            delta_g_values[delta_count] = fabs(results.results[output_index].samples[s].rgb_delta.g);
            delta_b_rgb_values[delta_count] = fabs(results.results[output_index].samples[s].rgb_delta.b);
            delta_count++;
        }

        if (exit_code != 0) {
            free_engine_output(&canonical);
            free_engine_output(&alternate);
            break;
        }

        /* Write artifacts based on retention policy */
        int should_write = (artifact_policy == ARTIFACT_POLICY_ALL) ||
                          (artifact_policy == ARTIFACT_POLICY_FAILURES && !results.results[output_index].passed);
        if (should_write && write_case_artifacts(resolved_root, input_case, &canonical, &alternate, &results.results[output_index], &error) != 0) {
            fprintf(stderr, "Failed to write artifacts for case %s: %s\n", input_case->id, error.message ? error.message : "unknown error");
        }

        free_engine_output(&canonical);
        free_engine_output(&alternate);
        output_index++;
    }

    const clock_t end = clock();
    results.result_count = output_index;
    results.summary.total_cases = output_index;
    results.summary.passed = 0;
    results.summary.failed = 0;
    for (size_t i = 0; i < results.result_count; ++i) {
        if (results.results[i].passed) {
            results.summary.passed++;
        } else {
            results.summary.failed++;
        }
    }
    results.summary.duration_ms = ((double)(end - start) / CLOCKS_PER_SEC) * 1000.0;
    results.summary.pass_rate = results.summary.total_cases > 0 ? ((double)results.summary.passed / (double)results.summary.total_cases) : 0.0;

    compute_metric_stats(delta_e_values, delta_count, &results.summary.stats.delta_e);
    compute_metric_stats(delta_l_values, delta_count, &results.summary.stats.l);
    compute_metric_stats(delta_a_values, delta_count, &results.summary.stats.a);
    compute_metric_stats(delta_b_values, delta_count, &results.summary.stats.b);
    compute_metric_stats(delta_r_values, delta_count, &results.summary.stats.rgb_r);
    compute_metric_stats(delta_g_values, delta_count, &results.summary.stats.rgb_g);
    compute_metric_stats(delta_b_rgb_values, delta_count, &results.summary.stats.rgb_b);

    const double hist_max = results.summary.stats.delta_e.max > 0.0 ? results.summary.stats.delta_e.max : 1.0;
    init_histogram(&results.summary.stats.delta_e_hist, 0.0, hist_max, 20);
    for (size_t i = 0; i < delta_count; ++i) {
        record_histogram(&results.summary.stats.delta_e_hist, delta_e_values[i]);
    }

    for (size_t i = 0; i < results.result_count; ++i) {
        Contributor *contributors = NULL;
        size_t contributor_count = 0;
        if (compute_contributors(&results.results[i], &results.summary, 3, &contributors, &contributor_count, &error) != 0) {
            fprintf(stderr, "Failed to compute contributors for case %s: %s\n",
                    results.results[i].input_case_id,
                    error.message ? error.message : "unknown error");
        } else {
            results.results[i].contributors = contributors;
            results.results[i].contributor_count = contributor_count;
        }

        InputCase *matching_case = find_input_case(&corpus, results.results[i].input_case_id);
        if (matching_case) {
            int should_write_metadata = (artifact_policy == ARTIFACT_POLICY_ALL) ||
                                       (artifact_policy == ARTIFACT_POLICY_FAILURES && !results.results[i].passed);
            if (should_write_metadata && write_case_metadata(resolved_root, matching_case, &results.results[i], &error) != 0) {
                fprintf(stderr, "Failed to write metadata for case %s: %s\n",
                        results.results[i].input_case_id,
                        error.message ? error.message : "unknown error");
            }
        }
    }

    provenance.artifact_policy = artifact_policy_to_string(artifact_policy);
    if (write_run_report(resolved_root, &provenance, &results, &tolerance, &error) != 0) {
        fprintf(stderr, "Failed to write run report: %s\n", error.message ? error.message : "unknown error");
    } else {
        printf("Report written to %s/report.json\n", resolved_root);
    }

    printf("Cases: %zu total, %zu passed, %zu failed | pass rate %.2f%% | duration %.1fms\n",
           results.summary.total_cases,
           results.summary.passed,
           results.summary.failed,
           results.summary.pass_rate * 100.0,
           results.summary.duration_ms);

    if (results.summary.pass_rate < pass_gate || results.summary.duration_ms > max_duration_ms) {
        exit_code = 1;
    }

    /* Cleanup */
    for (size_t i = 0; i < results.result_count; ++i) {
        free_comparison_result(&results.results[i]);
    }
    free(results.results);
    free_case_filters(filters, filter_count);
    free_case_filters(tag_filters, tag_filter_count);
    free_tolerances(&tolerance);
    free_corpus(&corpus);
    free(error.message);
    free(delta_e_values);
    free(delta_l_values);
    free(delta_a_values);
    free(delta_b_values);
    free(delta_r_values);
    free(delta_g_values);
    free(delta_b_rgb_values);
    free_histogram(&results.summary.stats.delta_e_hist);
    free(provenance.c_build_flags);
    free(provenance.alt_build_flags);

    return exit_code;
}
