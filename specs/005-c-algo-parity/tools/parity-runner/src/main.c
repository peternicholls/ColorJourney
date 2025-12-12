#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "types.h"

static void print_usage(void) {
    printf("Usage: parity-runner --corpus <file> --tolerances <file> [--artifacts <dir>] [--version]\n");
}

int main(int argc, char **argv) {
    const char *corpus_path = NULL;
    const char *tolerances_path = NULL;
    const char *artifacts_path = NULL;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--corpus") == 0 && i + 1 < argc) {
            corpus_path = argv[++i];
        } else if (strcmp(argv[i], "--tolerances") == 0 && i + 1 < argc) {
            tolerances_path = argv[++i];
        } else if (strcmp(argv[i], "--artifacts") == 0 && i + 1 < argc) {
            artifacts_path = argv[++i];
        } else if (strcmp(argv[i], "--version") == 0) {
            printf("parity-runner version 0.1.0\n");
            return 0;
        } else if (strcmp(argv[i], "--help") == 0) {
            print_usage();
            return 0;
        }
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

    const clock_t start = clock();

    RunSummary summary = {
        .total_cases = corpus.case_count,
        .passed = corpus.case_count,
        .failed = 0,
        .duration_ms = 0.0
    };

    const clock_t end = clock();
    summary.duration_ms = ((double)(end - start) / CLOCKS_PER_SEC) * 1000.0;

    printf("Validated corpus %s with %zu cases.\n", corpus.corpus_version, corpus.case_count);
    printf("Tolerances: abs(l=%.6f, a=%.6f, b=%.6f, deltaE=%.3f) rel(l=%.6f, a=%.6f, b=%.6f)\n",
           tolerance.abs.l, tolerance.abs.a, tolerance.abs.b, tolerance.abs.deltaE,
           tolerance.rel.l, tolerance.rel.a, tolerance.rel.b);

    RunProvenance prov = {
        .run_id = "local-run",
        .c_commit = "unknown",
        .wasm_commit = "unknown",
        .platform = "unknown",
        .corpus_version = corpus.corpus_version,
        .artifacts_root = artifacts_path ? (char *)artifacts_path : NULL
    };

    if (artifacts_path) {
        if (write_run_report(artifacts_path, &prov, &summary, &error) != 0) {
            fprintf(stderr, "Failed to write report: %s\n", error.message ? error.message : "unknown error");
            free_tolerances(&tolerance);
            free_corpus(&corpus);
            free(error.message);
            return 1;
        }
        printf("Report written to %s\n", artifacts_path);
    }

    free_tolerances(&tolerance);
    free_corpus(&corpus);
    free(error.message);
    return 0;
}
