#include "ColorJourney.h"
#include <assert.h>
#include <stdio.h>

static void expect_rgb_in_range(CJ_RGB c) {
    assert(c.r >= 0.0f && c.r <= 1.0f);
    assert(c.g >= 0.0f && c.g <= 1.0f);
    assert(c.b >= 0.0f && c.b <= 1.0f);
}

static void test_samples_in_range(void) {
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.3f, 0.5f, 0.8f};

    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);

    expect_rgb_in_range(cj_journey_sample(journey, 0.0f));
    expect_rgb_in_range(cj_journey_sample(journey, 0.5f));
    expect_rgb_in_range(cj_journey_sample(journey, 1.0f));

    cj_journey_destroy(journey);
}

static void test_discrete_contrast(void) {
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.4f, 0.6f, 0.2f};
    config.contrast_level = CJ_CONTRAST_MEDIUM; /* ΔE >= 0.1 enforced */

    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);

    const int count = 5;
    CJ_RGB palette[count];
    cj_journey_discrete(journey, count, palette);

    for (int i = 0; i < count; i++) {
        expect_rgb_in_range(palette[i]);
        if (i > 0) {
            CJ_Lab prev = cj_rgb_to_oklab(palette[i - 1]);
            CJ_Lab curr = cj_rgb_to_oklab(palette[i]);
            float de = cj_delta_e(prev, curr);
            assert(de >= 0.1f);
        }
    }

    cj_journey_destroy(journey);
}

int main(void) {
    test_samples_in_range();
    test_discrete_contrast();
    printf("C core tests passed\n");
    return 0;
}
