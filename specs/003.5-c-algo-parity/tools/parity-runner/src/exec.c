#include <errno.h>
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

static int capture_command(const char *command, char **out_buffer, ValidationError *error) {
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        set_error(error, "failed to spawn runner process");
        return -1;
    }

    size_t capacity = 4096;
    size_t length = 0;
    char *buffer = (char *)malloc(capacity);
    if (!buffer) {
        set_error(error, "failed to allocate output buffer");
        pclose(pipe);
        return -1;
    }

    int ch;
    while ((ch = fgetc(pipe)) != EOF) {
        if (length + 1 >= capacity) {
            capacity *= 2;
            char *tmp = (char *)realloc(buffer, capacity);
            if (!tmp) {
                free(buffer);
                pclose(pipe);
                set_error(error, "failed to grow output buffer");
                return -1;
            }
            buffer = tmp;
        }
        buffer[length++] = (char)ch;
    }
    buffer[length] = '\0';

    int status = pclose(pipe);
    if (status != 0) {
        free(buffer);
        set_error(error, "runner process exited with failure");
        return -1;
    }

    *out_buffer = buffer;
    return 0;
}

int parse_engine_output(const char *buffer, EngineOutput *out, ValidationError *error) {
    if (!buffer || !out) {
        set_error(error, "invalid engine output buffer");
        return -1;
    }

    cJSON *root = cJSON_Parse(buffer);
    if (!root) {
        set_error(error, "failed to parse engine JSON output");
        return -1;
    }

    memset(out, 0, sizeof(EngineOutput));

    const cJSON *engine = cJSON_GetObjectItemCaseSensitive(root, "engine");
    const cJSON *duration = cJSON_GetObjectItemCaseSensitive(root, "durationMs");
    const cJSON *count = cJSON_GetObjectItemCaseSensitive(root, "count");
    const cJSON *colors = cJSON_GetObjectItemCaseSensitive(root, "colors");
    const cJSON *commit = cJSON_GetObjectItemCaseSensitive(root, "commit");
    const cJSON *build_flags = cJSON_GetObjectItemCaseSensitive(root, "buildFlags");
    const cJSON *platform = cJSON_GetObjectItemCaseSensitive(root, "platform");

    if (!cJSON_IsString(engine) || !cJSON_IsNumber(duration) || !cJSON_IsNumber(count) || !cJSON_IsArray(colors)) {
        cJSON_Delete(root);
        set_error(error, "engine output missing required fields");
        return -1;
    }

    strncpy(out->engine, engine->valuestring, sizeof(out->engine) - 1);
    out->duration_ms = duration->valuedouble;
    const size_t declared_count = (size_t)count->valuedouble;

    if (cJSON_IsString(commit) && commit->valuestring) {
        out->commit = strdup(commit->valuestring);
    }
    if (cJSON_IsString(build_flags) && build_flags->valuestring) {
        out->build_flags = strdup(build_flags->valuestring);
    }
    if (cJSON_IsString(platform) && platform->valuestring) {
        out->platform = strdup(platform->valuestring);
    }

    const int array_size = cJSON_GetArraySize(colors);
    if (array_size <= 0) {
        cJSON_Delete(root);
        set_error(error, "engine output contains no colors");
        return -1;
    }

    out->color_count = (size_t)array_size;
    if (declared_count > 0 && declared_count != out->color_count) {
        /* Prefer actual array size but keep declared count mismatch noted */
    }

    out->colors = (EngineColor *)calloc(out->color_count, sizeof(EngineColor));
    if (!out->colors) {
        cJSON_Delete(root);
        set_error(error, "failed to allocate engine colors");
        return -1;
    }

    for (int i = 0; i < array_size; ++i) {
        const cJSON *item = cJSON_GetArrayItem(colors, i);
        const cJSON *oklab = cJSON_GetObjectItemCaseSensitive(item, "oklab");
        const cJSON *rgb = cJSON_GetObjectItemCaseSensitive(item, "rgb");
        if (!cJSON_IsObject(oklab) || !cJSON_IsObject(rgb)) {
            free_engine_output(out);
            cJSON_Delete(root);
            set_error(error, "engine color missing oklab or rgb");
            return -1;
        }
        const cJSON *l = cJSON_GetObjectItemCaseSensitive(oklab, "l");
        const cJSON *a = cJSON_GetObjectItemCaseSensitive(oklab, "a");
        const cJSON *b = cJSON_GetObjectItemCaseSensitive(oklab, "b");
        const cJSON *r = cJSON_GetObjectItemCaseSensitive(rgb, "r");
        const cJSON *g = cJSON_GetObjectItemCaseSensitive(rgb, "g");
        const cJSON *bl = cJSON_GetObjectItemCaseSensitive(rgb, "b");
        if (!cJSON_IsNumber(l) || !cJSON_IsNumber(a) || !cJSON_IsNumber(b) ||
            !cJSON_IsNumber(r) || !cJSON_IsNumber(g) || !cJSON_IsNumber(bl)) {
            free_engine_output(out);
            cJSON_Delete(root);
            set_error(error, "engine color components must be numeric");
            return -1;
        }
        out->colors[i].oklab.l = l->valuedouble;
        out->colors[i].oklab.a = a->valuedouble;
        out->colors[i].oklab.b = b->valuedouble;
        out->colors[i].srgb.r = r->valuedouble;
        out->colors[i].srgb.g = g->valuedouble;
        out->colors[i].srgb.b = bl->valuedouble;
    }

    cJSON_Delete(root);
    return 0;
}

void free_engine_output(EngineOutput *output) {
    if (!output) {
        return;
    }
    free(output->colors);
    free(output->commit);
    free(output->build_flags);
    free(output->platform);
    memset(output, 0, sizeof(EngineOutput));
}

int run_c_engine(const char *binary_path,
                 const char *corpus_path,
                 const char *case_id,
                 EngineOutput *out,
                 ValidationError *error) {
    char command[MAX_PATH_LENGTH];
    snprintf(command, sizeof(command), "%s --corpus \"%s\" --case-id \"%s\"", binary_path, corpus_path, case_id);

    char *buffer = NULL;
    if (capture_command(command, &buffer, error) != 0) {
        return -1;
    }

    int status = parse_engine_output(buffer, out, error);
    free(buffer);
    return status;
}

int run_alt_engine(const char *binary_path,
                   const char *corpus_path,
                   const char *case_id,
                   EngineOutput *out,
                   ValidationError *error) {
    char command[MAX_PATH_LENGTH];
    snprintf(command, sizeof(command), "%s --corpus \"%s\" --case-id \"%s\"", binary_path, corpus_path, case_id);

    char *buffer = NULL;
    if (capture_command(command, &buffer, error) != 0) {
        return -1;
    }

    int status = parse_engine_output(buffer, out, error);
    free(buffer);
    return status;
}
