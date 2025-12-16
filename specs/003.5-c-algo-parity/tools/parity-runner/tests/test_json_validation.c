#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "types.h"

static int assert_true(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message);
        return 1;
    }
    return 0;
}

int main(void) {
    int failures = 0;
    ValidationError error = {.message = NULL};

    Corpus corpus;
    failures += assert_true(parse_corpus_file("tests/fixtures/test-corpus.json", &corpus, &error) == 0,
                             error.message ? error.message : "corpus parsed");
    free(error.message);
    error.message = NULL;

    if (failures == 0) {
        failures += assert_true(strcmp(corpus.corpus_version, "v20251212.1") == 0,
                                 "corpus version should match fixture");
        failures += assert_true(corpus.case_count == 2, "expected two cases in fixture");
    }

    ToleranceConfig tolerance;
    failures += assert_true(parse_tolerances_file("tests/fixtures/test-tolerances.json", &tolerance, &error) == 0,
                             error.message ? error.message : "tolerances parsed");
    free(error.message);
    error.message = NULL;

    if (failures == 0) {
        failures += assert_true(fabs(tolerance.abs.l - 0.0001) < 1e-9, "absolute tolerance l matches");
        failures += assert_true(fabs(tolerance.rel.a - 0.001) < 1e-9, "relative tolerance a matches");
        failures += assert_true(fabs(tolerance.abs.deltaE - 0.5) < 1e-9, "deltaE tolerance matches");
    }

    failures += assert_true(validate_corpus_version("v20251212.1") == 1, "valid corpus version accepted");
    failures += assert_true(validate_corpus_version("invalid") == 0, "invalid corpus version rejected");

    ComparisonDelta within = {.l = 0.00001, .a = 0.00002, .b = 0.00003, .deltaE = 0.2};
    failures += assert_true(comparison_within_tolerance(&within, &tolerance) == 1, "delta within tolerance should pass");

    ComparisonDelta outside = {.l = 0.01, .a = 0.01, .b = 0.01, .deltaE = 1.0};
    failures += assert_true(comparison_within_tolerance(&outside, &tolerance) == 0, "delta outside tolerance should fail");

    OklabColor color_a = {.l = 0.5, .a = 0.1, .b = -0.2};
    OklabColor color_b = {.l = 0.4, .a = 0.1, .b = -0.1};
    double delta = delta_e_oklab(&color_a, &color_b);
    failures += assert_true(delta > 0.0, "delta_e_oklab should compute positive distance");

    free_tolerances(&tolerance);
    free_corpus(&corpus);
    free(error.message);

    return failures == 0 ? 0 : 1;
}
