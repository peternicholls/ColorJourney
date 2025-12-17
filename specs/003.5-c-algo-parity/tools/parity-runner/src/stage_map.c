#include <string.h>

#include "types.h"

static const StageHint STAGE_HINTS[] = {
    {"deltaE", "ΔE overall distance", "Comparison/Scoring", "overall-delta"},
    {"oklab.l", "OKLab L", "OKLab normalization", "lightness"},
    {"oklab.a", "OKLab a", "OKLab normalization", "chroma-a"},
    {"oklab.b", "OKLab b", "OKLab normalization", "chroma-b"},
    {"srgb.r", "sRGB R", "sRGB encoding", "red-channel"},
    {"srgb.g", "sRGB G", "sRGB encoding", "green-channel"},
    {"srgb.b", "sRGB B", "sRGB encoding", "blue-channel"},
};

const StageHint *lookup_stage_hint(const char *metric) {
    if (!metric) {
        return NULL;
    }
    for (size_t i = 0; i < sizeof(STAGE_HINTS) / sizeof(STAGE_HINTS[0]); ++i) {
        if (strcmp(metric, STAGE_HINTS[i].metric) == 0) {
            return &STAGE_HINTS[i];
        }
    }
    return NULL;
}
