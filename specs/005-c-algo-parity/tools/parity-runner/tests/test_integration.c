#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>

static int file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static void remove_path(const char *path) {
    char command[256];
    snprintf(command, sizeof(command), "rm -rf %s", path);
    system(command);
}

static int assert_true(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "Assertion failed: %s\n", message);
        return 1;
    }
    return 0;
}

static int file_contains(const char *path, const char *needle) {
    FILE *file = fopen(path, "r");
    if (!file) {
        return 0;
    }
    char buffer[256];
    int found = 0;
    while (fgets(buffer, sizeof(buffer), file)) {
        if (strstr(buffer, needle) != NULL) {
            found = 1;
            break;
        }
    }
    fclose(file);
    return found;
}

int main(void) {
    const char *artifacts = "tests/output/integration";
    const char *report_path = "tests/output/integration/report.json";
    const char *metadata_path = "tests/output/integration/cases/case-baseline/metadata.json";

    remove_path(artifacts);

    char command[512];
    snprintf(command, sizeof(command), "./parity-runner --corpus %s --tolerances %s --artifacts %s",
             "tests/fixtures/test-corpus.json",
             "tests/fixtures/test-tolerances.json",
             artifacts);
    strncat(command, " --pass-gate 0", sizeof(command) - strlen(command) - 1);

    int result = system(command);
    if (result == -1) {
        fprintf(stderr, "Failed to spawn parity-runner\n");
        return 1;
    }
    int exit_code = WEXITSTATUS(result);

    int failures = 0;
    failures += assert_true(exit_code == 0, "parity-runner should exit successfully");
    failures += assert_true(file_exists(report_path), "report.json should be created");
    failures += assert_true(file_contains(report_path, "v20251212.1"), "report should include corpus version");
    failures += assert_true(file_contains(report_path, "totalCases\": 2"), "report should include summary totals");
    failures += assert_true(file_contains(report_path, "topContributors"), "report should include top contributors");
    failures += assert_true(file_exists(metadata_path), "metadata.json should exist for at least one case");
    failures += assert_true(file_contains(metadata_path, "topContributors"), "metadata should include contributors");

    /* Test tag-based filtering */
    const char *tagged_artifacts = "tests/output/integration-tags";
    const char *tagged_report = "tests/output/integration-tags/report.json";
    remove_path(tagged_artifacts);

    snprintf(command, sizeof(command), "./parity-runner --corpus %s --tolerances %s --artifacts %s --tags baseline",
             "tests/fixtures/test-corpus.json",
             "tests/fixtures/test-tolerances.json",
             tagged_artifacts);
    strncat(command, " --pass-gate 0", sizeof(command) - strlen(command) - 1);

    result = system(command);
    if (result == -1) {
        fprintf(stderr, "Failed to spawn parity-runner for tag filter\n");
        return 1;
    }
    exit_code = WEXITSTATUS(result);
    failures += assert_true(exit_code == 0, "tag-filtered run should exit successfully");
    failures += assert_true(file_exists(tagged_report), "tag-filtered report should be created");
    failures += assert_true(file_contains(tagged_report, "totalCases\": 1"), "tag-filtered report should include filtered totals");

    /* Test tolerance override */
    const char *override_artifacts = "tests/output/integration-tolerance";
    const char *override_report = "tests/output/integration-tolerance/report.json";
    remove_path(override_artifacts);

    snprintf(command, sizeof(command), "./parity-runner --corpus %s --tolerances %s --artifacts %s",
             "tests/fixtures/test-corpus.json",
             "tests/fixtures/test-tolerances.json",
             override_artifacts);
    strncat(command, " --tolerance-deltaE 0.123", sizeof(command) - strlen(command) - 1);
    strncat(command, " --pass-gate 0", sizeof(command) - strlen(command) - 1);

    result = system(command);
    if (result == -1) {
        fprintf(stderr, "Failed to spawn parity-runner for tolerance override\n");
        return 1;
    }
    exit_code = WEXITSTATUS(result);
    failures += assert_true(exit_code == 0, "tolerance override run should exit successfully");
    failures += assert_true(file_exists(override_report), "tolerance override report should be created");
    failures += assert_true(file_contains(override_report, "\"deltaE\": 0.123"), "report should include overridden deltaE");

    return failures == 0 ? 0 : 1;
}
