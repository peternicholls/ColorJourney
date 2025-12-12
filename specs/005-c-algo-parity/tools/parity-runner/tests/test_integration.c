#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>

static int file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
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

    char command[512];
    snprintf(command, sizeof(command), "./parity-runner --corpus %s --tolerances %s --artifacts %s",
             "tests/fixtures/test-corpus.json",
             "tests/fixtures/test-tolerances.json",
             artifacts);

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

    return failures == 0 ? 0 : 1;
}
