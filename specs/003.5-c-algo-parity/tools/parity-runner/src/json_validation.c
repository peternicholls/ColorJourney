#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "cJSON.h"
#include "types.h"

static void set_error(ValidationError *error, const char *message) {
    if (error == NULL) {
        return;
    }
    if (error->message != NULL) {
        free(error->message);
    }
    size_t len = strlen(message);
    error->message = (char *)malloc(len + 1);
    if (error->message != NULL) {
        memcpy(error->message, message, len + 1);
    }
}

static char *read_file_into_buffer(const char *path, long *length) {
    FILE *file = fopen(path, "rb");
    if (!file) {
        return NULL;
    }
    if (fseek(file, 0L, SEEK_END) != 0) {
        fclose(file);
        return NULL;
    }
    long file_size = ftell(file);
    if (file_size < 0) {
        fclose(file);
        return NULL;
    }
    rewind(file);
    char *buffer = (char *)malloc((size_t)file_size + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }
    size_t read_bytes = fread(buffer, 1, (size_t)file_size, file);
    fclose(file);
    if (read_bytes != (size_t)file_size) {
        free(buffer);
        return NULL;
    }
    buffer[file_size] = '\0';
    if (length) {
        *length = file_size;
    }
    return buffer;
}

int validate_corpus_version(const char *version) {
    if (!version) {
        return 0;
    }
    const size_t len = strlen(version);
    if (len < 11 || len >= MAX_VERSION_LENGTH) {
        return 0;
    }
    if (version[0] != 'v') {
        return 0;
    }
    for (size_t i = 1; i < 9; ++i) {
        if (version[i] < '0' || version[i] > '9') {
            return 0;
        }
    }
    if (version[9] != '.') {
        return 0;
    }
    for (size_t i = 10; i < len; ++i) {
        if (version[i] < '0' || version[i] > '9') {
            return 0;
        }
    }
    return 1;
}

static int parse_oklab(const cJSON *node, OklabColor *color, ValidationError *error) {
    const cJSON *l = cJSON_GetObjectItemCaseSensitive(node, "l");
    const cJSON *a = cJSON_GetObjectItemCaseSensitive(node, "a");
    const cJSON *b = cJSON_GetObjectItemCaseSensitive(node, "b");
    if (!cJSON_IsNumber(l) || !cJSON_IsNumber(a) || !cJSON_IsNumber(b)) {
        set_error(error, "oklab must contain numeric l/a/b");
        return -1;
    }
    color->l = l->valuedouble;
    color->a = a->valuedouble;
    color->b = b->valuedouble;
    return 0;
}

static int parse_srgb(const cJSON *node, SrgbColor *color, ValidationError *error) {
    const cJSON *r = cJSON_GetObjectItemCaseSensitive(node, "r");
    const cJSON *g = cJSON_GetObjectItemCaseSensitive(node, "g");
    const cJSON *b = cJSON_GetObjectItemCaseSensitive(node, "b");
    if (!cJSON_IsNumber(r) || !cJSON_IsNumber(g) || !cJSON_IsNumber(b)) {
        set_error(error, "rgb must contain numeric r/g/b");
        return -1;
    }
    color->r = r->valuedouble;
    color->g = g->valuedouble;
    color->b = b->valuedouble;
    return 0;
}

static int parse_anchor(const cJSON *node, Anchor *anchor, ValidationError *error) {
    memset(anchor, 0, sizeof(Anchor));
    const cJSON *oklab = cJSON_GetObjectItemCaseSensitive(node, "oklab");
    const cJSON *rgb = cJSON_GetObjectItemCaseSensitive(node, "rgb");

    if (oklab && cJSON_IsObject(oklab)) {
        if (parse_oklab(oklab, &anchor->oklab, error) != 0) {
            return -1;
        }
        anchor->has_oklab = true;
    }

    if (rgb && cJSON_IsObject(rgb)) {
        if (parse_srgb(rgb, &anchor->srgb, error) != 0) {
            return -1;
        }
        anchor->has_srgb = true;
    }

    if (!anchor->has_oklab && !anchor->has_srgb) {
        set_error(error, "anchor must contain oklab or rgb");
        return -1;
    }

    return 0;
}

static int parse_tags(const cJSON *tags_node, InputCase *input_case, ValidationError *error) {
    if (!tags_node) {
        input_case->tags = NULL;
        input_case->tag_count = 0;
        return 0;
    }
    if (!cJSON_IsArray(tags_node)) {
        set_error(error, "tags must be an array");
        return -1;
    }
    const int tag_count = cJSON_GetArraySize(tags_node);
    input_case->tags = (char **)calloc((size_t)tag_count, sizeof(char *));
    if (!input_case->tags) {
        set_error(error, "failed to allocate tags array");
        return -1;
    }
    for (int i = 0; i < tag_count; ++i) {
        const cJSON *tag = cJSON_GetArrayItem(tags_node, i);
        if (!cJSON_IsString(tag) || !tag->valuestring) {
            set_error(error, "tags must contain strings");
            for (int j = 0; j < i; ++j) {
                free(input_case->tags[j]);
            }
            free(input_case->tags);
            input_case->tags = NULL;
            input_case->tag_count = 0;
            return -1;
        }
        input_case->tags[i] = strdup(tag->valuestring);
    }
    input_case->tag_count = (size_t)tag_count;
    return 0;
}

static int parse_config(const cJSON *config_node, EngineConfig *config, ValidationError *error) {
    memset(config, 0, sizeof(EngineConfig));
    if (!cJSON_IsObject(config_node)) {
        set_error(error, "config must be an object");
        return -1;
    }
    const cJSON *count = cJSON_GetObjectItemCaseSensitive(config_node, "count");
    if (!cJSON_IsNumber(count) || count->valuedouble <= 0) {
        set_error(error, "config.count must be a positive number");
        return -1;
    }
    config->count = (uint32_t)count->valuedouble;

    const cJSON *loop_mode = cJSON_GetObjectItemCaseSensitive(config_node, "loopMode");
    if (cJSON_IsString(loop_mode) && loop_mode->valuestring) {
        config->loop_mode = strdup(loop_mode->valuestring);
    }

    const cJSON *variation_seed = cJSON_GetObjectItemCaseSensitive(config_node, "variationSeed");
    if (variation_seed && cJSON_IsNumber(variation_seed) && variation_seed->valuedouble >= 0) {
        config->variation_seed = (uint64_t)variation_seed->valuedouble;
        config->has_variation_seed = true;
    }

    const cJSON *lightness = cJSON_GetObjectItemCaseSensitive(config_node, "lightness");
    const cJSON *chroma = cJSON_GetObjectItemCaseSensitive(config_node, "chroma");
    const cJSON *contrast = cJSON_GetObjectItemCaseSensitive(config_node, "contrast");
    const cJSON *vibrancy = cJSON_GetObjectItemCaseSensitive(config_node, "vibrancy");
    const cJSON *temperature = cJSON_GetObjectItemCaseSensitive(config_node, "temperature");

    if (cJSON_IsNumber(lightness)) config->lightness = lightness->valuedouble;
    if (cJSON_IsNumber(chroma)) config->chroma = chroma->valuedouble;
    if (cJSON_IsNumber(contrast)) config->contrast = contrast->valuedouble;
    if (cJSON_IsNumber(vibrancy)) config->vibrancy = vibrancy->valuedouble;
    if (cJSON_IsNumber(temperature)) config->temperature = temperature->valuedouble;

    return 0;
}

static void free_input_case(InputCase *input_case) {
    if (!input_case) {
        return;
    }
    free(input_case->anchors);
    if (input_case->config.loop_mode) {
        free(input_case->config.loop_mode);
    }
    for (size_t i = 0; i < input_case->tag_count; ++i) {
        free(input_case->tags[i]);
    }
    free(input_case->tags);
    if (input_case->notes) {
        free(input_case->notes);
    }
}

static int parse_input_case(const cJSON *node, InputCase *input_case, ValidationError *error) {
    memset(input_case, 0, sizeof(InputCase));
    const cJSON *id = cJSON_GetObjectItemCaseSensitive(node, "id");
    const cJSON *anchors = cJSON_GetObjectItemCaseSensitive(node, "anchors");
    const cJSON *config = cJSON_GetObjectItemCaseSensitive(node, "config");
    const cJSON *seed = cJSON_GetObjectItemCaseSensitive(node, "seed");
    const cJSON *corpus_version = cJSON_GetObjectItemCaseSensitive(node, "corpusVersion");
    const cJSON *notes = cJSON_GetObjectItemCaseSensitive(node, "notes");
    const cJSON *tags = cJSON_GetObjectItemCaseSensitive(node, "tags");

    if (!cJSON_IsString(id) || !id->valuestring) {
        set_error(error, "inputCase.id must be a string");
        goto fail;
    }
    if (strlen(id->valuestring) >= MAX_ID_LENGTH) {
        set_error(error, "inputCase.id exceeds maximum length");
        goto fail;
    }
    strncpy(input_case->id, id->valuestring, MAX_ID_LENGTH - 1);

    if (!validate_corpus_version(corpus_version ? corpus_version->valuestring : NULL)) {
        set_error(error, "inputCase.corpusVersion must match vYYYYMMDD.n");
        goto fail;
    }
    strncpy(input_case->corpus_version, corpus_version->valuestring, MAX_VERSION_LENGTH - 1);

    if (!cJSON_IsArray(anchors) || cJSON_GetArraySize(anchors) < 1) {
        set_error(error, "anchors must be a non-empty array");
        goto fail;
    }
    input_case->anchor_count = (size_t)cJSON_GetArraySize(anchors);
    input_case->anchors = (Anchor *)calloc(input_case->anchor_count, sizeof(Anchor));
    if (!input_case->anchors) {
        set_error(error, "failed to allocate anchors");
        goto fail;
    }
    for (size_t i = 0; i < input_case->anchor_count; ++i) {
        const cJSON *anchor_node = cJSON_GetArrayItem(anchors, (int)i);
        if (parse_anchor(anchor_node, &input_case->anchors[i], error) != 0) {
            goto fail;
        }
    }

    if (parse_config(config, &input_case->config, error) != 0) {
        goto fail;
    }

    if (!cJSON_IsNumber(seed) || seed->valuedouble < 0) {
        set_error(error, "seed must be a non-negative number");
        goto fail;
    }
    input_case->seed = (uint64_t)seed->valuedouble;

    if (notes && cJSON_IsString(notes) && notes->valuestring) {
        input_case->notes = strdup(notes->valuestring);
    }

    if (parse_tags(tags, input_case, error) != 0) {
        goto fail;
    }

    return 0;

fail:
    free_input_case(input_case);
    return -1;
}

int parse_corpus_file(const char *path, Corpus *out, ValidationError *error) {
    if (!path || !out) {
        set_error(error, "invalid corpus arguments");
        return -1;
    }
    long length = 0;
    char *buffer = read_file_into_buffer(path, &length);
    if (!buffer) {
        set_error(error, "failed to read corpus file");
        return -1;
    }
    cJSON *root = cJSON_Parse(buffer);
    free(buffer);
    if (!root) {
        set_error(error, "failed to parse corpus JSON");
        return -1;
    }
    memset(out, 0, sizeof(Corpus));

    const cJSON *corpus_version = cJSON_GetObjectItemCaseSensitive(root, "corpusVersion");
    const cJSON *description = cJSON_GetObjectItemCaseSensitive(root, "description");
    const cJSON *cases = cJSON_GetObjectItemCaseSensitive(root, "cases");

    if (!validate_corpus_version(corpus_version ? corpus_version->valuestring : NULL)) {
        set_error(error, "corpusVersion must match vYYYYMMDD.n");
        cJSON_Delete(root);
        return -1;
    }
    strncpy(out->corpus_version, corpus_version->valuestring, MAX_VERSION_LENGTH - 1);

    if (description && cJSON_IsString(description) && description->valuestring) {
        out->description = strdup(description->valuestring);
    }

    if (!cJSON_IsArray(cases) || cJSON_GetArraySize(cases) == 0) {
        set_error(error, "cases must be a non-empty array");
        cJSON_Delete(root);
        return -1;
    }

    out->case_count = (size_t)cJSON_GetArraySize(cases);
    out->cases = (InputCase *)calloc(out->case_count, sizeof(InputCase));
    if (!out->cases) {
        set_error(error, "failed to allocate cases");
        cJSON_Delete(root);
        return -1;
    }
    for (size_t i = 0; i < out->case_count; ++i) {
        const cJSON *case_node = cJSON_GetArrayItem(cases, (int)i);
        if (parse_input_case(case_node, &out->cases[i], error) != 0) {
            out->case_count = i + 1;
            free_corpus(out);
            cJSON_Delete(root);
            return -1;
        }
    }

    cJSON_Delete(root);
    return 0;
}

static double parse_number_or_default(const cJSON *node, double default_value) {
    if (node && cJSON_IsNumber(node)) {
        return node->valuedouble;
    }
    return default_value;
}

int parse_tolerances_file(const char *path, ToleranceConfig *out, ValidationError *error) {
    if (!path || !out) {
        set_error(error, "invalid tolerances arguments");
        return -1;
    }
    long length = 0;
    char *buffer = read_file_into_buffer(path, &length);
    if (!buffer) {
        set_error(error, "failed to read tolerances file");
        return -1;
    }
    cJSON *root = cJSON_Parse(buffer);
    free(buffer);
    if (!root) {
        set_error(error, "failed to parse tolerances JSON");
        return -1;
    }
    memset(out, 0, sizeof(ToleranceConfig));

    const cJSON *version = cJSON_GetObjectItemCaseSensitive(root, "toleranceVersion");
    const cJSON *description = cJSON_GetObjectItemCaseSensitive(root, "description");
    const cJSON *abs = cJSON_GetObjectItemCaseSensitive(root, "abs");
    const cJSON *rel = cJSON_GetObjectItemCaseSensitive(root, "rel");
    const cJSON *policy = cJSON_GetObjectItemCaseSensitive(root, "policy");
    const cJSON *provenance = cJSON_GetObjectItemCaseSensitive(root, "provenance");

    if (!cJSON_IsString(version) || !version->valuestring) {
        set_error(error, "toleranceVersion is required");
        cJSON_Delete(root);
        return -1;
    }
    strncpy(out->version, version->valuestring, MAX_VERSION_LENGTH - 1);
    if (description && cJSON_IsString(description) && description->valuestring) {
        out->description = strdup(description->valuestring);
    }

    if (!cJSON_IsObject(abs) || !cJSON_IsObject(rel)) {
        set_error(error, "abs and rel tolerance objects are required");
        cJSON_Delete(root);
        return -1;
    }
    out->abs.l = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(abs, "l"), 0.0);
    out->abs.a = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(abs, "a"), 0.0);
    out->abs.b = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(abs, "b"), 0.0);
    out->abs.deltaE = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(abs, "deltaE"), 0.0);

    out->rel.l = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(rel, "l"), 0.0);
    out->rel.a = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(rel, "a"), 0.0);
    out->rel.b = parse_number_or_default(cJSON_GetObjectItemCaseSensitive(rel, "b"), 0.0);

    if (policy && cJSON_IsObject(policy)) {
        const cJSON *fail_threshold = cJSON_GetObjectItemCaseSensitive(policy, "failThreshold");
        if (cJSON_IsNumber(fail_threshold)) {
            out->fail_threshold = fail_threshold->valuedouble;
        }
        const cJSON *notes = cJSON_GetObjectItemCaseSensitive(policy, "notes");
        if (cJSON_IsString(notes) && notes->valuestring) {
            out->policy_notes = strdup(notes->valuestring);
        }
    }

    if (provenance && cJSON_IsObject(provenance)) {
        const cJSON *source = cJSON_GetObjectItemCaseSensitive(provenance, "source");
        if (cJSON_IsString(source) && source->valuestring) {
            out->provenance_source = strdup(source->valuestring);
        }
        const cJSON *updated = cJSON_GetObjectItemCaseSensitive(provenance, "updated");
        if (cJSON_IsString(updated) && updated->valuestring) {
            out->provenance_updated = strdup(updated->valuestring);
        }
    }

    cJSON_Delete(root);
    return 0;
}

void free_corpus(Corpus *corpus) {
    if (!corpus) {
        return;
    }
    for (size_t i = 0; i < corpus->case_count; ++i) {
        free_input_case(&corpus->cases[i]);
    }
    free(corpus->cases);
    if (corpus->description) {
        free(corpus->description);
    }
    corpus->cases = NULL;
    corpus->description = NULL;
    corpus->case_count = 0;
}

void free_tolerances(ToleranceConfig *config) {
    if (!config) {
        return;
    }
    free(config->description);
    free(config->policy_notes);
    free(config->provenance_source);
    free(config->provenance_updated);
    config->description = NULL;
    config->policy_notes = NULL;
    config->provenance_source = NULL;
    config->provenance_updated = NULL;
}

int ensure_directory(const char *path, ValidationError *error) {
    if (!path) {
        set_error(error, "path is null");
        return -1;
    }

    char buffer[512];
    memset(buffer, 0, sizeof(buffer));
    size_t length = strlen(path);
    if (length >= sizeof(buffer)) {
        set_error(error, "path too long");
        return -1;
    }

    strncpy(buffer, path, sizeof(buffer) - 1);
    for (size_t i = 1; i < length; ++i) {
        if (buffer[i] == '/' || buffer[i] == '\\') {
            buffer[i] = '\0';
            if (buffer[0] != '\0') {
                struct stat st = {0};
                if (stat(buffer, &st) != 0) {
#if defined(_WIN32)
                    if (_mkdir(buffer) != 0) {
#else
                    if (mkdir(buffer, 0775) != 0 && errno != EEXIST) {
#endif
                        set_error(error, "failed to create directory");
                        return -1;
                    }
                }
            }
            buffer[i] = '/';
        }
    }

    struct stat st = {0};
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
        return 0;
    }

#if defined(_WIN32)
    if (_mkdir(path) != 0 && errno != EEXIST) {
#else
    if (mkdir(path, 0775) != 0 && errno != EEXIST) {
#endif
        set_error(error, "failed to create directory");
        return -1;
    }
    return 0;
}
