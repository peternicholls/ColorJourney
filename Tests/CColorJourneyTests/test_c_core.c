#include "ColorJourney.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>

static void expect_rgb_in_range(CJ_RGB c) {
    assert(c.r >= 0.0f && c.r <= 1.0f);
    assert(c.g >= 0.0f && c.g <= 1.0f);
    assert(c.b >= 0.0f && c.b <= 1.0f);
}

static void expect_rgb_equal(CJ_RGB a, CJ_RGB b) {
    const float epsilon = 1e-5f;
    assert(fabsf(a.r - b.r) < epsilon);
    assert(fabsf(a.g - b.g) < epsilon);
    assert(fabsf(a.b - b.b) < epsilon);
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

static void test_discrete_index_and_range_access(void) {
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.25f, 0.6f, 0.4f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;

    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);

    /* Single index access is deterministic */
    CJ_RGB index_color_first = cj_journey_discrete_at(journey, 3);
    CJ_RGB index_color_second = cj_journey_discrete_at(journey, 3);
    expect_rgb_equal(index_color_first, index_color_second);

    /* Range access matches individual index calls */
    const int start = 2;
    const int count = 4;
    CJ_RGB range[count];
    cj_journey_discrete_range(journey, start, count, range);

    for (int i = 0; i < count; i++) {
        CJ_RGB single = cj_journey_discrete_at(journey, start + i);
        expect_rgb_equal(single, range[i]);
    }

    cj_journey_destroy(journey);
}

static void test_discrete_range_contrast(void) {
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.7f, 0.2f, 0.4f};
    config.contrast_level = CJ_CONTRAST_HIGH;

    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);

    const int start = 5;
    const int count = 3;
    CJ_RGB range[count];
    cj_journey_discrete_range(journey, start, count, range);

    for (int i = 1; i < count; i++) {
        CJ_Lab prev = cj_rgb_to_oklab(range[i - 1]);
        CJ_Lab curr = cj_rgb_to_oklab(range[i]);
        float de = cj_delta_e(prev, curr);
        assert(de >= 0.15f);
    }

    cj_journey_destroy(journey);
}

int main(void) {
    test_samples_in_range();
    test_discrete_contrast();
    test_discrete_index_and_range_access();
    test_discrete_range_contrast();
    printf("C core tests passed\n");
    return 0;
}
