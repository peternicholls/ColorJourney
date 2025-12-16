#include "Sources/CColorJourney/include/ColorJourney.h"
#include <stdio.h>

int main(void) {
    /* Create a journey with orange anchor (similar to the preview image) */
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    /* Orange-ish anchor matching preview */
    config.anchors[0] = (CJ_RGB){0.95f, 0.55f, 0.2f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    
    CJ_Journey journey = cj_journey_create(&config);
    if (!journey) {
        printf("Failed to create journey\n");
        return 1;
    }
    
    /* Generate 12 colors (like the preview shows) */
    const int count = 12;
    CJ_RGB colors[count];
    cj_journey_discrete(journey, count, colors);
    
    printf("Generated %d colors:\n", count);
    for (int i = 0; i < count; i++) {
        printf("  [%2d] R:%.3f G:%.3f B:%.3f  HEX:#%02X%02X%02X\n",
               i,
               colors[i].r, colors[i].g, colors[i].b,
               (int)(colors[i].r * 255),
               (int)(colors[i].g * 255),
               (int)(colors[i].b * 255));
        
        if (i > 0) {
            CJ_Lab prev = cj_rgb_to_oklab(colors[i - 1]);
            CJ_Lab curr = cj_rgb_to_oklab(colors[i]);
            float de = cj_delta_e(prev, curr);
            printf("       ΔE from previous: %.4f\n", de);
        }
    }
    
    cj_journey_destroy(journey);
    return 0;
}
