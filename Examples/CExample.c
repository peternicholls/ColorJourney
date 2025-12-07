#include "ColorJourney.h"
#include <stdio.h>

static void print_rgb(const char *label, CJ_RGB c) {
    printf("%s: r=%.3f g=%.3f b=%.3f\n", label, c.r, c.g, c.b);
}

int main(void) {
    CJ_Config config;
    cj_config_init(&config);

    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.30f, 0.50f, 0.80f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    config.loop_mode = CJ_LOOP_OPEN;

    CJ_Journey journey = cj_journey_create(&config);
    if (!journey) {
        fprintf(stderr, "Failed to create journey\n");
        return 1;
    }

    CJ_RGB palette[5];
    cj_journey_discrete(journey, 5, palette);

    printf("Discrete palette (5 colors):\n");
    for (int i = 0; i < 5; i++) {
        char label[32];
        snprintf(label, sizeof(label), "stop %d", i);
        print_rgb(label, palette[i]);
    }

    CJ_RGB mid = cj_journey_sample(journey, 0.42f);
    print_rgb("Sample at t=0.42", mid);

    cj_journey_destroy(journey);
    return 0;
}
