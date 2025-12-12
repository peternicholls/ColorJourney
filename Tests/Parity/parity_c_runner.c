#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "ColorJourney.h"
#include "cJSON.h"
#include "types.h"

#ifndef PARITY_BUILD_FLAGS
#define PARITY_BUILD_FLAGS "unknown"
#endif

static void print_usage(void) {
    fprintf(stderr, "Usage: parity_c_runner --corpus <file> --case-id <id>\n");
}

static InputCase *find_case(Corpus *corpus, const char *case_id) {
    if (!corpus || !case_id) return NULL;
    for (size_t i = 0; i < corpus->case_count; ++i) {
        if (strcmp(corpus->cases[i].id, case_id) == 0) {
            return &corpus->cases[i];
        }
    }
    return NULL;
}

static CJ_RGB anchor_to_rgb(const Anchor *anchor) {
    CJ_RGB rgb = {0.0f, 0.0f, 0.0f};
    if (anchor->has_srgb) {
        rgb.r = (float)anchor->srgb.r;
        rgb.g = (float)anchor->srgb.g;
        rgb.b = (float)anchor->srgb.b;
    } else if (anchor->has_oklab) {
        CJ_Lab lab = {
            .L = (float)anchor->oklab.l,
            .a = (float)anchor->oklab.a,
            .b = (float)anchor->oklab.b
        };
        rgb = cj_oklab_to_rgb(lab);
    }
    return cj_rgb_clamp(rgb);
}

static void map_config(const InputCase *input_case, CJ_Config *config) {
    cj_config_init(config);
    const size_t anchor_count = input_case->anchor_count > 8 ? 8 : input_case->anchor_count;
    config->anchor_count = (int)anchor_count;
    for (size_t i = 0; i < anchor_count; ++i) {
        config->anchors[i] = anchor_to_rgb(&input_case->anchors[i]);
    }

    config->lightness_bias = CJ_LIGHTNESS_CUSTOM;
    config->lightness_custom_weight = (float)input_case->config.lightness;
    config->chroma_bias = CJ_CHROMA_CUSTOM;
    config->chroma_custom_multiplier = (float)(input_case->config.chroma > 0.0 ? input_case->config.chroma : 1.0);
    config->contrast_level = CJ_CONTRAST_CUSTOM;
    config->contrast_custom_threshold = (float)(input_case->config.contrast > 0.0 ? input_case->config.contrast : 0.1);
    config->mid_journey_vibrancy = (float)input_case->config.vibrancy;

    if (input_case->config.temperature > 0.01) {
        config->temperature_bias = CJ_TEMPERATURE_WARM;
    } else if (input_case->config.temperature < -0.01) {
        config->temperature_bias = CJ_TEMPERATURE_COOL;
    } else {
        config->temperature_bias = CJ_TEMPERATURE_NEUTRAL;
    }

    if (input_case->config.loop_mode && strcmp(input_case->config.loop_mode, "closed") == 0) {
        config->loop_mode = CJ_LOOP_CLOSED;
    } else if (input_case->config.loop_mode && strcmp(input_case->config.loop_mode, "pingpong") == 0) {
        config->loop_mode = CJ_LOOP_PINGPONG;
    } else {
        config->loop_mode = CJ_LOOP_OPEN;
    }

    config->variation_enabled = input_case->config.has_variation_seed;
    config->variation_seed = input_case->config.has_variation_seed ? input_case->config.variation_seed : input_case->seed;
    config->variation_dimensions = CJ_VARIATION_HUE | CJ_VARIATION_LIGHTNESS | CJ_VARIATION_CHROMA;
    config->variation_strength = CJ_VARIATION_NOTICEABLE;
}

static cJSON *emit_output(const InputCase *input_case, const CJ_RGB *palette, size_t count, double duration_ms) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "engine", "canonical-c");
    cJSON_AddNumberToObject(root, "count", (double)count);
    cJSON_AddNumberToObject(root, "durationMs", duration_ms);
    cJSON_AddStringToObject(root, "inputCaseId", input_case->id);
    cJSON_AddStringToObject(root, "corpusVersion", input_case->corpus_version);
    cJSON_AddStringToObject(root, "buildFlags", PARITY_BUILD_FLAGS);

    cJSON *colors = cJSON_AddArrayToObject(root, "colors");
    for (size_t i = 0; i < count; ++i) {
        cJSON *entry = cJSON_CreateObject();
        CJ_Lab lab = cj_rgb_to_oklab(palette[i]);
        cJSON *oklab = cJSON_CreateObject();
        cJSON_AddNumberToObject(oklab, "l", lab.L);
        cJSON_AddNumberToObject(oklab, "a", lab.a);
        cJSON_AddNumberToObject(oklab, "b", lab.b);
        cJSON_AddItemToObject(entry, "oklab", oklab);

        cJSON *rgb = cJSON_CreateObject();
        cJSON_AddNumberToObject(rgb, "r", palette[i].r);
        cJSON_AddNumberToObject(rgb, "g", palette[i].g);
        cJSON_AddNumberToObject(rgb, "b", palette[i].b);
        cJSON_AddItemToObject(entry, "rgb", rgb);

        cJSON_AddItemToArray(colors, entry);
    }

    return root;
}

int main(int argc, char **argv) {
    const char *corpus_path = NULL;
    const char *case_id = NULL;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--corpus") == 0 && i + 1 < argc) {
            corpus_path = argv[++i];
        } else if (strcmp(argv[i], "--case-id") == 0 && i + 1 < argc) {
            case_id = argv[++i];
        } else if (strcmp(argv[i], "--help") == 0) {
            print_usage();
            return 0;
        }
    }

    if (!corpus_path || !case_id) {
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

    InputCase *input_case = find_case(&corpus, case_id);
    if (!input_case) {
        fprintf(stderr, "Case %s not found in corpus.\n", case_id);
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    CJ_Config config;
    map_config(input_case, &config);

    CJ_Journey journey = cj_journey_create(&config);
    if (!journey) {
        fprintf(stderr, "Failed to create journey for %s.\n", case_id);
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    const size_t count = input_case->config.count;
    CJ_RGB *palette = (CJ_RGB *)calloc(count, sizeof(CJ_RGB));
    if (!palette) {
        fprintf(stderr, "Failed to allocate palette.\n");
        cj_journey_destroy(journey);
        free_corpus(&corpus);
        free(error.message);
        return 1;
    }

    const clock_t start = clock();
    cj_journey_discrete(journey, (int)count, palette);
    const clock_t end = clock();
    const double duration_ms = ((double)(end - start) / CLOCKS_PER_SEC) * 1000.0;

    cJSON *json = emit_output(input_case, palette, count, duration_ms);
    char *rendered = cJSON_PrintUnformatted(json);
    printf("%s\n", rendered);

    free(rendered);
    cJSON_Delete(json);
    free(palette);
    cj_journey_destroy(journey);
    free_corpus(&corpus);
    free(error.message);
    return 0;
}
