#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cJSON.h"
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

static cJSON *oklab_to_json(const OklabColor *c) {
    cJSON *node = cJSON_CreateObject();
    cJSON_AddNumberToObject(node, "l", c->l);
    cJSON_AddNumberToObject(node, "a", c->a);
    cJSON_AddNumberToObject(node, "b", c->b);
    return node;
}

static cJSON *srgb_to_json(const SrgbColor *c) {
    cJSON *node = cJSON_CreateObject();
    cJSON_AddNumberToObject(node, "r", c->r);
    cJSON_AddNumberToObject(node, "g", c->g);
    cJSON_AddNumberToObject(node, "b", c->b);
    return node;
}

static cJSON *engine_output_json(const EngineOutput *output) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "engine", output->engine);
    cJSON_AddNumberToObject(root, "durationMs", output->duration_ms);
    cJSON_AddNumberToObject(root, "count", (double)output->color_count);
    if (output->commit) cJSON_AddStringToObject(root, "commit", output->commit);
    if (output->build_flags) cJSON_AddStringToObject(root, "buildFlags", output->build_flags);
    if (output->platform) cJSON_AddStringToObject(root, "platform", output->platform);

    cJSON *colors = cJSON_AddArrayToObject(root, "colors");
    for (size_t i = 0; i < output->color_count; ++i) {
        cJSON *entry = cJSON_CreateObject();
        cJSON_AddItemToObject(entry, "oklab", oklab_to_json(&output->colors[i].oklab));
        cJSON_AddItemToObject(entry, "rgb", srgb_to_json(&output->colors[i].srgb));
        cJSON_AddItemToArray(colors, entry);
    }
    return root;
}

static cJSON *comparison_json(const ComparisonResult *result) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "inputCaseId", result->input_case_id);
    cJSON_AddBoolToObject(root, "passed", result->passed ? 1 : 0);
    cJSON_AddNumberToObject(root, "maxDeltaE", result->max_delta_e);

    cJSON *samples = cJSON_AddArrayToObject(root, "samples");
    for (size_t i = 0; i < result->sample_count; ++i) {
        const SampleDelta *sample = &result->samples[i];
        cJSON *entry = cJSON_CreateObject();
        cJSON_AddNumberToObject(entry, "index", (double)sample->index);
        cJSON_AddItemToObject(entry, "delta", oklab_to_json(&(OklabColor){
            .l = sample->delta.l,
            .a = sample->delta.a,
            .b = sample->delta.b
        }));
        cJSON_AddNumberToObject(entry, "deltaE", sample->delta.deltaE);
        cJSON_AddItemToObject(entry, "rgbDelta", srgb_to_json(&(SrgbColor){
            .r = sample->rgb_delta.r,
            .g = sample->rgb_delta.g,
            .b = sample->rgb_delta.b
        }));
        cJSON_AddItemToObject(entry, "canonical", oklab_to_json(&sample->canonical.oklab));
        cJSON_AddItemToObject(entry, "alternate", oklab_to_json(&sample->alternate.oklab));
        cJSON_AddItemToArray(samples, entry);
    }

    if (result->contributors && result->contributor_count > 0) {
        cJSON *contributors = cJSON_AddArrayToObject(root, "topContributors");
        for (size_t i = 0; i < result->contributor_count; ++i) {
            const Contributor *hint = &result->contributors[i];
            cJSON *entry = cJSON_CreateObject();
            cJSON_AddStringToObject(entry, "metric", hint->metric);
            cJSON_AddNumberToObject(entry, "magnitude", hint->magnitude);
            cJSON_AddStringToObject(entry, "direction", hint->direction);
            if (hint->stage) cJSON_AddStringToObject(entry, "stage", hint->stage);
            if (hint->parameter) cJSON_AddStringToObject(entry, "parameter", hint->parameter);
            cJSON_AddNumberToObject(entry, "zScore", hint->z_score);
            cJSON_AddBoolToObject(entry, "significant", hint->significant ? 1 : 0);
            cJSON_AddItemToArray(contributors, entry);
        }
    }
    return root;
}

static cJSON *histogram_json(const Histogram *hist) {
    cJSON *root = cJSON_CreateObject();
    if (!hist || !hist->counts) {
        return root;
    }
    cJSON_AddNumberToObject(root, "min", hist->min_value);
    cJSON_AddNumberToObject(root, "max", hist->max_value);
    cJSON_AddNumberToObject(root, "bucketSize", hist->bucket_size);
    cJSON *counts = cJSON_AddArrayToObject(root, "counts");
    for (size_t i = 0; i < hist->bucket_count; ++i) {
        cJSON_AddItemToArray(counts, cJSON_CreateNumber((double)hist->counts[i]));
    }
    return root;
}

static cJSON *metric_stats_json(const MetricStats *stats) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "mean", stats->mean);
    cJSON_AddNumberToObject(root, "stddev", stats->stddev);
    cJSON_AddNumberToObject(root, "p50", stats->p50);
    cJSON_AddNumberToObject(root, "p95", stats->p95);
    cJSON_AddNumberToObject(root, "p99", stats->p99);
    cJSON_AddNumberToObject(root, "min", stats->min);
    cJSON_AddNumberToObject(root, "max", stats->max);
    return root;
}

int write_case_artifacts(const char *artifacts_root,
                         const InputCase *input_case,
                         const EngineOutput *canonical,
                         const EngineOutput *alternate,
                         const ComparisonResult *result,
                         ValidationError *error) {
    if (!artifacts_root || !input_case || !canonical || !alternate || !result) {
        set_error(error, "invalid artifacts arguments");
        return -1;
    }

    char case_dir[MAX_PATH_LENGTH];
    snprintf(case_dir, sizeof(case_dir), "%s/cases/%s", artifacts_root, input_case->id);
    if (ensure_directory(artifacts_root, error) != 0 || ensure_directory(case_dir, error) != 0) {
        return -1;
    }

    char path[MAX_PATH_LENGTH];

    snprintf(path, sizeof(path), "%s/canonical.json", case_dir);
    FILE *file = fopen(path, "w");
    if (!file) {
        set_error(error, "failed to write canonical artifact");
        return -1;
    }
    cJSON *canonical_json = engine_output_json(canonical);
    char *canonical_str = cJSON_PrintUnformatted(canonical_json);
    fprintf(file, "%s", canonical_str);
    fclose(file);
    cJSON_Delete(canonical_json);
    free(canonical_str);

    snprintf(path, sizeof(path), "%s/alternate.json", case_dir);
    file = fopen(path, "w");
    if (!file) {
        set_error(error, "failed to write alternate artifact");
        return -1;
    }
    cJSON *alternate_json = engine_output_json(alternate);
    char *alternate_str = cJSON_PrintUnformatted(alternate_json);
    fprintf(file, "%s", alternate_str);
    fclose(file);
    cJSON_Delete(alternate_json);
    free(alternate_str);

    snprintf(path, sizeof(path), "%s/diff.json", case_dir);
    file = fopen(path, "w");
    if (!file) {
        set_error(error, "failed to write diff artifact");
        return -1;
    }
    cJSON *diff_json = comparison_json(result);
    char *diff_str = cJSON_PrintUnformatted(diff_json);
    fprintf(file, "%s", diff_str);
    fclose(file);
    cJSON_Delete(diff_json);
    free(diff_str);

    return 0;
}

int write_case_metadata(const char *artifacts_root,
                        const InputCase *input_case,
                        const ComparisonResult *result,
                        ValidationError *error) {
    if (!artifacts_root || !input_case || !result) {
        set_error(error, "invalid metadata arguments");
        return -1;
    }

    char case_dir[MAX_PATH_LENGTH];
    snprintf(case_dir, sizeof(case_dir), "%s/cases/%s", artifacts_root, input_case->id);
    if (ensure_directory(artifacts_root, error) != 0 || ensure_directory(case_dir, error) != 0) {
        return -1;
    }

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "inputCaseId", input_case->id);
    cJSON_AddBoolToObject(root, "passed", result->passed ? 1 : 0);
    cJSON_AddNumberToObject(root, "maxDeltaE", result->max_delta_e);

    cJSON *input = cJSON_CreateObject();
    cJSON_AddStringToObject(input, "corpusVersion", input_case->corpus_version);
    cJSON_AddNumberToObject(input, "seed", (double)input_case->seed);
    cJSON_AddNumberToObject(input, "count", (double)input_case->config.count);
    if (input_case->tag_count > 0) {
        cJSON *tags = cJSON_AddArrayToObject(input, "tags");
        for (size_t i = 0; i < input_case->tag_count; ++i) {
            cJSON_AddItemToArray(tags, cJSON_CreateString(input_case->tags[i]));
        }
    }
    cJSON_AddItemToObject(root, "input", input);

    cJSON *artifacts = cJSON_CreateObject();
    cJSON_AddStringToObject(artifacts, "canonical", "canonical.json");
    cJSON_AddStringToObject(artifacts, "alternate", "alternate.json");
    cJSON_AddStringToObject(artifacts, "diff", "diff.json");
    cJSON_AddItemToObject(root, "artifacts", artifacts);

    if (result->contributors && result->contributor_count > 0) {
        cJSON *contributors = cJSON_AddArrayToObject(root, "topContributors");
        for (size_t i = 0; i < result->contributor_count; ++i) {
            const Contributor *hint = &result->contributors[i];
            cJSON *entry = cJSON_CreateObject();
            cJSON_AddStringToObject(entry, "metric", hint->metric);
            cJSON_AddNumberToObject(entry, "magnitude", hint->magnitude);
            cJSON_AddStringToObject(entry, "direction", hint->direction);
            if (hint->stage) cJSON_AddStringToObject(entry, "stage", hint->stage);
            if (hint->parameter) cJSON_AddStringToObject(entry, "parameter", hint->parameter);
            cJSON_AddNumberToObject(entry, "zScore", hint->z_score);
            cJSON_AddBoolToObject(entry, "significant", hint->significant ? 1 : 0);
            cJSON_AddItemToArray(contributors, entry);
        }
    }

    char path[MAX_PATH_LENGTH];
    snprintf(path, sizeof(path), "%s/metadata.json", case_dir);
    FILE *file = fopen(path, "w");
    if (!file) {
        cJSON_Delete(root);
        set_error(error, "failed to write case metadata");
        return -1;
    }

    char *rendered = cJSON_Print(root);
    fprintf(file, "%s", rendered);
    fclose(file);
    free(rendered);
    cJSON_Delete(root);
    return 0;
}

int write_run_report(const char *artifacts_root,
                     const RunProvenance *provenance,
                     const RunResults *results,
                     const ToleranceConfig *tolerance,
                     ValidationError *error) {
    if (!artifacts_root || !provenance || !results) {
        set_error(error, "invalid report arguments");
        return -1;
    }
    if (ensure_directory(artifacts_root, error) != 0) {
        return -1;
    }

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "runId", provenance->run_id ? provenance->run_id : "local-run");
    cJSON_AddStringToObject(root, "corpusVersion", provenance->corpus_version ? provenance->corpus_version : "unknown");
    cJSON_AddNumberToObject(root, "durationMs", results->summary.duration_ms);
    cJSON_AddNumberToObject(root, "passRate", results->summary.pass_rate);
    cJSON_AddBoolToObject(root, "withinPassGate", results->summary.pass_rate >= provenance->pass_gate ? 1 : 0);
    cJSON_AddBoolToObject(root, "withinDuration", results->summary.duration_ms <= provenance->max_duration_ms ? 1 : 0);
    if (provenance->artifact_policy) {
        cJSON_AddStringToObject(root, "artifactPolicy", provenance->artifact_policy);
    }

    cJSON *prov = cJSON_CreateObject();
    cJSON_AddStringToObject(prov, "cCommit", provenance->c_commit ? provenance->c_commit : "unknown");
    cJSON_AddStringToObject(prov, "wasmCommit", provenance->wasm_commit ? provenance->wasm_commit : "unknown");
    cJSON_AddStringToObject(prov, "platform", provenance->platform ? provenance->platform : "unknown");
    cJSON_AddStringToObject(prov, "artifactsRoot", provenance->artifacts_root ? provenance->artifacts_root : artifacts_root);
    if (provenance->c_build_flags) {
        cJSON_AddStringToObject(prov, "cBuildFlags", provenance->c_build_flags);
    }
    if (provenance->alt_build_flags) {
        cJSON_AddStringToObject(prov, "altBuildFlags", provenance->alt_build_flags);
    }
    if (tolerance) {
        cJSON *tol = cJSON_CreateObject();
        cJSON *abs = cJSON_CreateObject();
        cJSON_AddNumberToObject(abs, "l", tolerance->abs.l);
        cJSON_AddNumberToObject(abs, "a", tolerance->abs.a);
        cJSON_AddNumberToObject(abs, "b", tolerance->abs.b);
        cJSON_AddNumberToObject(abs, "deltaE", tolerance->abs.deltaE);
        cJSON_AddItemToObject(tol, "abs", abs);
        cJSON *rel = cJSON_CreateObject();
        cJSON_AddNumberToObject(rel, "l", tolerance->rel.l);
        cJSON_AddNumberToObject(rel, "a", tolerance->rel.a);
        cJSON_AddNumberToObject(rel, "b", tolerance->rel.b);
        cJSON_AddItemToObject(tol, "rel", rel);
        cJSON_AddItemToObject(prov, "appliedTolerances", tol);
    }
    cJSON_AddItemToObject(root, "provenance", prov);

    cJSON *summary = cJSON_CreateObject();
    cJSON_AddNumberToObject(summary, "totalCases", (double)results->summary.total_cases);
    cJSON_AddNumberToObject(summary, "passed", (double)results->summary.passed);
    cJSON_AddNumberToObject(summary, "failed", (double)results->summary.failed);
    cJSON_AddItemToObject(summary, "deltaE", metric_stats_json(&results->summary.stats.delta_e));
    cJSON_AddItemToObject(summary, "l", metric_stats_json(&results->summary.stats.l));
    cJSON_AddItemToObject(summary, "a", metric_stats_json(&results->summary.stats.a));
    cJSON_AddItemToObject(summary, "b", metric_stats_json(&results->summary.stats.b));
    cJSON_AddItemToObject(summary, "rgbR", metric_stats_json(&results->summary.stats.rgb_r));
    cJSON_AddItemToObject(summary, "rgbG", metric_stats_json(&results->summary.stats.rgb_g));
    cJSON_AddItemToObject(summary, "rgbB", metric_stats_json(&results->summary.stats.rgb_b));
    cJSON_AddItemToObject(summary, "deltaEHistogram", histogram_json(&results->summary.stats.delta_e_hist));
    cJSON_AddItemToObject(root, "summary", summary);

    cJSON *cases = cJSON_AddArrayToObject(root, "cases");
    for (size_t i = 0; i < results->result_count; ++i) {
        cJSON_AddItemToArray(cases, comparison_json(&results->results[i]));
    }

    char path[MAX_PATH_LENGTH];
    snprintf(path, sizeof(path), "%s/report.json", artifacts_root);
    FILE *file = fopen(path, "w");
    if (!file) {
        cJSON_Delete(root);
        set_error(error, "failed to write run report");
        return -1;
    }

    /* Pretty-print to keep summary fields visible to line-oriented test readers. */
    char *rendered = cJSON_Print(root);
    if (rendered) {
        /* Normalize indentation so substring searches with spaces succeed. */
        for (char *p = rendered; *p; ++p) {
            if (*p == '\t') {
                *p = ' ';
            }
        }
    }
    fprintf(file, "%s", rendered);
    fclose(file);
    free(rendered);
    cJSON_Delete(root);
    return 0;
}
