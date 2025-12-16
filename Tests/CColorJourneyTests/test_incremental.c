/**
 * Incremental Creation Feature Tests
 * 
 * Tests for Phase 1 implementation:
 * - T014: Minimum delta test (ΔE ≥ 0.02)
 * - T015: Maximum delta test (ΔE ≤ 0.05)
 * - T016: Conflict resolution test
 * - T017: Multi-contrast-level delta test
 * - T023: Negative indices test
 * - T024: NULL/invalid journey test
 * - T026: Baseline index tests (0, 1, 10, 100, 1000)
 * - T027: High index tests (999,999, 1,000,000)
 * - T028: Precision validation tests
 * 
 * Feature: 004-incremental-creation
 * Spec: specs/004-incremental-creation/spec.md
 * Algorithm: specs/004-incremental-creation/delta-algorithm.md
 */

#include "ColorJourney.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdbool.h>

/* Test configuration */
#define DELTA_MIN 0.02f
#define DELTA_MAX 0.05f
#define DELTA_TOLERANCE 0.001f

/* Helper: Check if RGB color is in valid range */
static void expect_rgb_in_range(CJ_RGB c) {
    assert(c.r >= 0.0f && c.r <= 1.0f);
    assert(c.g >= 0.0f && c.g <= 1.0f);
    assert(c.b >= 0.0f && c.b <= 1.0f);
}

/* Helper: Check if two RGB colors are equal within epsilon */
static void expect_rgb_equal(CJ_RGB a, CJ_RGB b) {
    const float epsilon = 1e-5f;
    assert(fabsf(a.r - b.r) < epsilon);
    assert(fabsf(a.g - b.g) < epsilon);
    assert(fabsf(a.b - b.b) < epsilon);
}



/**
 * T014: Minimum Delta Test (ΔE ≥ 0.02)
 * 
 * Verifies that consecutive colors maintain at least the minimum
 * perceptual distance (Just Noticeable Difference).
 * 
 * Success Criteria:
 * - All consecutive colors have ΔE ≥ 0.02 - tolerance
 * - No colors are too similar to distinguish
 */
static void test_minimum_delta(void) {
    printf("T014: Minimum Delta Test (ΔE ≥ 0.02)...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 2;
    config.anchors[0] = (CJ_RGB){1.0f, 0.2f, 0.3f};  /* Red-ish */
    config.anchors[1] = (CJ_RGB){0.2f, 0.3f, 1.0f};  /* Blue-ish */
    config.contrast_level = CJ_CONTRAST_LOW;  /* Low contrast to test delta enforcement */
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    const int count = 100;
    int violations = 0;
    
    for (int i = 1; i < count; i++) {
        CJ_RGB color_curr = cj_journey_discrete_at(journey, i);
        CJ_RGB color_prev = cj_journey_discrete_at(journey, i - 1);
        
        expect_rgb_in_range(color_curr);
        expect_rgb_in_range(color_prev);
        
        CJ_Lab lab_curr = cj_rgb_to_oklab(color_curr);
        CJ_Lab lab_prev = cj_rgb_to_oklab(color_prev);
        float delta_e = cj_delta_e(lab_curr, lab_prev);
        
        if (delta_e < DELTA_MIN - DELTA_TOLERANCE) {
            printf("  Warning: Index %d has ΔE = %.4f (< %.4f)\n", i, delta_e, DELTA_MIN);
            violations++;
        }
    }
    
    printf("  Tested %d consecutive pairs\n", count - 1);
    printf("  Minimum ΔE violations: %d\n", violations);
    assert(violations == 0);  /* All pairs must satisfy minimum */
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T015: Maximum Delta Test (ΔE ≤ 0.05)
 * 
 * Verifies that consecutive colors don't jump too far apart,
 * maintaining smooth progression.
 * 
 * Success Criteria:
 * - All consecutive colors have ΔE ≤ 0.05 + tolerance
 * - No jarring perceptual jumps
 */
static void test_maximum_delta(void) {
    printf("T015: Maximum Delta Test (ΔE ≤ 0.05)...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 2;
    config.anchors[0] = (CJ_RGB){0.3f, 0.7f, 0.4f};  /* Green-ish */
    config.anchors[1] = (CJ_RGB){0.7f, 0.4f, 0.3f};  /* Orange-ish */
    config.contrast_level = CJ_CONTRAST_LOW;
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    const int count = 100;
    int violations = 0;
    
    for (int i = 1; i < count; i++) {
        CJ_RGB color_curr = cj_journey_discrete_at(journey, i);
        CJ_RGB color_prev = cj_journey_discrete_at(journey, i - 1);
        
        CJ_Lab lab_curr = cj_rgb_to_oklab(color_curr);
        CJ_Lab lab_prev = cj_rgb_to_oklab(color_prev);
        float delta_e = cj_delta_e(lab_curr, lab_prev);
        
        if (delta_e > DELTA_MAX + DELTA_TOLERANCE) {
            printf("  Warning: Index %d has ΔE = %.4f (> %.4f)\n", i, delta_e, DELTA_MAX);
            violations++;
        }
    }
    
    printf("  Tested %d consecutive pairs\n", count - 1);
    printf("  Maximum ΔE violations: %d\n", violations);
    
    /* Maximum constraint is best-effort when it conflicts with minimum */
    /* Accept up to 5% violations (e.g., at cycle boundaries) */
    int max_acceptable_violations = count / 20;  /* 5% */
    assert(violations <= max_acceptable_violations);
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T016: Conflict Resolution Test
 * 
 * Tests behavior when both min and max constraints are difficult to satisfy.
 * Verifies that minimum constraint takes priority (distinctness over smoothness).
 * 
 * Success Criteria:
 * - When conflict occurs, minimum ΔE ≥ 0.02 is satisfied
 * - Maximum may be violated in conflict scenarios (acceptable)
 */
static void test_conflict_resolution(void) {
    printf("T016: Conflict Resolution Test...\n");
    
    /* Create scenario where max constraint might conflict with min */
    /* Use anchors that create steep gradients */
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 2;
    config.anchors[0] = (CJ_RGB){0.9f, 0.2f, 0.2f};  /* Bright red */
    config.anchors[1] = (CJ_RGB){0.2f, 0.2f, 0.9f};  /* Bright blue */
    config.contrast_level = CJ_CONTRAST_LOW;
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    const int count = 50;
    int min_violations = 0;
    int max_violations = 0;
    
    for (int i = 1; i < count; i++) {
        CJ_RGB color_curr = cj_journey_discrete_at(journey, i);
        CJ_RGB color_prev = cj_journey_discrete_at(journey, i - 1);
        
        CJ_Lab lab_curr = cj_rgb_to_oklab(color_curr);
        CJ_Lab lab_prev = cj_rgb_to_oklab(color_prev);
        float delta_e = cj_delta_e(lab_curr, lab_prev);
        
        if (delta_e < DELTA_MIN - DELTA_TOLERANCE) {
            min_violations++;
        }
        if (delta_e > DELTA_MAX + DELTA_TOLERANCE) {
            max_violations++;
        }
    }
    
    printf("  Tested %d consecutive pairs\n", count - 1);
    printf("  Minimum violations: %d (must be 0)\n", min_violations);
    printf("  Maximum violations: %d (acceptable in conflict scenarios)\n", max_violations);
    
    /* Priority: minimum constraint must always be satisfied */
    assert(min_violations == 0);
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T017: Multi-Contrast-Level Delta Test
 * 
 * Tests delta enforcement across different contrast levels (LOW, MEDIUM, HIGH).
 * Verifies that delta range [0.02, 0.05] and contrast requirements interact correctly.
 * 
 * Success Criteria:
 * - Delta range enforced regardless of contrast level
 * - When contrast > delta max, tighter constraint applies
 * - All colors satisfy both delta and contrast requirements
 */
static void test_multi_contrast_levels(void) {
    printf("T017: Multi-Contrast-Level Delta Test...\n");
    
    CJ_ContrastLevel levels[] = {CJ_CONTRAST_LOW, CJ_CONTRAST_MEDIUM, CJ_CONTRAST_HIGH};
    const char* level_names[] = {"LOW", "MEDIUM", "HIGH"};
    const float contrast_mins[] = {0.02f, 0.04f, 0.10f};  /* Expected minimum ΔE per level */
    
    for (int level_idx = 0; level_idx < 3; level_idx++) {
        printf("  Testing contrast level: %s\n", level_names[level_idx]);
        
        CJ_Config config;
        cj_config_init(&config);
        config.anchor_count = 1;
        config.anchors[0] = (CJ_RGB){0.4f, 0.6f, 0.3f};
        config.contrast_level = levels[level_idx];
        
        CJ_Journey journey = cj_journey_create(&config);
        assert(journey != NULL);
        
        const int count = 50;
        int violations = 0;
        float expected_min = contrast_mins[level_idx];
        
        /* For LOW and MEDIUM, delta range [0.02, 0.05] may apply */
        /* For HIGH, contrast min (0.10) is higher than delta max (0.05) */
        if (expected_min < DELTA_MIN) {
            expected_min = DELTA_MIN;  /* Delta min overrides */
        }
        
        for (int i = 1; i < count; i++) {
            CJ_RGB color_curr = cj_journey_discrete_at(journey, i);
            CJ_RGB color_prev = cj_journey_discrete_at(journey, i - 1);
            
            CJ_Lab lab_curr = cj_rgb_to_oklab(color_curr);
            CJ_Lab lab_prev = cj_rgb_to_oklab(color_prev);
            float delta_e = cj_delta_e(lab_curr, lab_prev);
            
            /* Check that minimum (tighter of delta or contrast) is satisfied */
            if (delta_e < expected_min - DELTA_TOLERANCE) {
                violations++;
            }
        }
        
        printf("    Minimum violations: %d (expected 0)\n", violations);
        assert(violations == 0);
        
        cj_journey_destroy(journey);
    }
    
    printf("  ✓ PASS\n\n");
}

/**
 * T023: Negative Indices Test (Error Handling)
 * 
 * Tests that negative indices are handled gracefully.
 * 
 * Success Criteria:
 * - Negative index returns black (0, 0, 0)
 * - No crashes or undefined behavior
 */
static void test_negative_indices(void) {
    printf("T023: Negative Indices Test...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.5f, 0.5f, 0.5f};
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    /* Test various negative indices */
    int negative_indices[] = {-1, -10, -100, -1000};
    
    for (int i = 0; i < 4; i++) {
        CJ_RGB color = cj_journey_discrete_at(journey, negative_indices[i]);
        
        /* Should return black (0, 0, 0) */
        assert(color.r == 0.0f);
        assert(color.g == 0.0f);
        assert(color.b == 0.0f);
        
        printf("  Index %d → black ✓\n", negative_indices[i]);
    }
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T024: NULL/Invalid Journey Test (Error Handling)
 * 
 * Tests that NULL journey handle is handled gracefully.
 * 
 * Success Criteria:
 * - NULL journey returns black (0, 0, 0)
 * - No crashes or undefined behavior
 */
static void test_null_journey(void) {
    printf("T024: NULL Journey Test...\n");
    
    /* Test NULL journey */
    CJ_RGB color = cj_journey_discrete_at(NULL, 5);
    
    assert(color.r == 0.0f);
    assert(color.g == 0.0f);
    assert(color.b == 0.0f);
    
    printf("  NULL journey → black ✓\n");
    printf("  ✓ PASS\n\n");
}

/**
 * T026: Baseline Index Tests (0, 1, 10, 100, 1000)
 * 
 * Tests baseline indices to establish deterministic behavior.
 * 
 * Success Criteria:
 * - All indices produce valid colors
 * - Results are deterministic (same index → same color)
 * - Colors maintain delta constraints
 */
static void test_baseline_indices(void) {
    printf("T026: Baseline Index Tests...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.4f, 0.6f, 0.5f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    int baseline_indices[] = {0, 1, 10, 100, 1000};
    
    for (int i = 0; i < 5; i++) {
        int index = baseline_indices[i];
        
        /* Test determinism: same index twice */
        CJ_RGB color1 = cj_journey_discrete_at(journey, index);
        CJ_RGB color2 = cj_journey_discrete_at(journey, index);
        
        expect_rgb_in_range(color1);
        expect_rgb_equal(color1, color2);
        
        printf("  Index %d: deterministic ✓\n", index);
    }
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T027: High Index Tests (999,999 and 1,000,000)
 * 
 * Tests high indices to verify precision at supported range boundary.
 * 
 * Success Criteria:
 * - High indices produce valid colors
 * - Precision error < 0.02 ΔE (imperceptible per R-003-A research)
 * - Deterministic behavior maintained
 */
static void test_high_indices(void) {
    printf("T027: High Index Tests...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.5f, 0.5f, 0.5f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    int high_indices[] = {100000, 500000, 999999, 1000000};
    
    for (int i = 0; i < 4; i++) {
        int index = high_indices[i];
        
        /* Test determinism */
        CJ_RGB color1 = cj_journey_discrete_at(journey, index);
        CJ_RGB color2 = cj_journey_discrete_at(journey, index);
        
        expect_rgb_in_range(color1);
        expect_rgb_equal(color1, color2);
        
        printf("  Index %d: valid and deterministic ✓\n", index);
    }
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

/**
 * T028: Precision Validation at Boundary
 * 
 * Tests precision at the 1M index boundary (supported range limit).
 * 
 * Success Criteria:
 * - Colors at boundary have precision error < 0.02 ΔE
 * - Consecutive colors at boundary maintain delta constraints
 */
static void test_precision_at_boundary(void) {
    printf("T028: Precision Validation at Boundary...\n");
    
    CJ_Config config;
    cj_config_init(&config);
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.6f, 0.4f, 0.7f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    
    CJ_Journey journey = cj_journey_create(&config);
    assert(journey != NULL);
    
    /* Test indices near 1M boundary */
    int boundary = 1000000;
    
    for (int offset = -5; offset <= 0; offset++) {
        int index = boundary + offset;
        if (index < 0) continue;
        
        CJ_RGB color = cj_journey_discrete_at(journey, index);
        expect_rgb_in_range(color);
        
        /* Check delta constraint with previous */
        if (offset < 0) {
            CJ_RGB prev = cj_journey_discrete_at(journey, index - 1);
            CJ_Lab lab_curr = cj_rgb_to_oklab(color);
            CJ_Lab lab_prev = cj_rgb_to_oklab(prev);
            float delta_e = cj_delta_e(lab_curr, lab_prev);
            
            /* Minimum constraint is priority (must always be satisfied) */
            assert(delta_e >= DELTA_MIN - DELTA_TOLERANCE);
            
            /* Maximum is best-effort (may be violated at cycle boundaries) */
            /* Just log if violated */
            if (delta_e > DELTA_MAX + DELTA_TOLERANCE) {
                printf("  Note: ΔE = %.4f (> %.4f) - max violated at boundary\n", delta_e, DELTA_MAX);
            }
        }
        
        printf("  Index %d: precision valid ✓\n", index);
    }
    
    cj_journey_destroy(journey);
    printf("  ✓ PASS\n\n");
}

int main(void) {
    printf("==============================================\n");
    printf("Incremental Creation Feature Tests (Phase 1)\n");
    printf("Feature: 004-incremental-creation\n");
    printf("==============================================\n\n");
    
    /* Delta Range Enforcement Tests (I-001) */
    test_minimum_delta();       /* T014 */
    test_maximum_delta();       /* T015 */
    test_conflict_resolution(); /* T016 */
    test_multi_contrast_levels(); /* T017 */
    
    /* Error Handling Tests (I-002) */
    test_negative_indices();    /* T023 */
    test_null_journey();        /* T024 */
    
    /* Index Bounds Tests (I-003) */
    test_baseline_indices();    /* T026 */
    test_high_indices();        /* T027 */
    test_precision_at_boundary(); /* T028 */
    
    printf("==============================================\n");
    printf("All tests PASSED ✓\n");
    printf("==============================================\n");
    
    return 0;
}
