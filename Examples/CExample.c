/*
 * ColorJourney - C API Usage Example
 * ===================================
 *
 * This example demonstrates the core C API for the ColorJourney system.
 * It shows:
 *   1. Journey initialization with a single anchor point
 *   2. Configuration of contrast levels and loop behavior
 *   3. Discrete palette generation (fixed number of color stops)
 *   4. Continuous sampling at arbitrary interpolation points
 *   5. Proper resource cleanup with journey destruction
 *
 * Constitutional Alignment (see .specify/memory/constitution.md):
 * - Principle I: Universal Portability - Pure C99 with no external dependencies
 * - Principle II: Perceptual Integrity - Uses OKLab color space (internally)
 * - Principle IV: Deterministic Output - Same config produces identical results
 *
 * User Story US5: Examples are clear and runnable
 * - Compiles: gcc -std=c99 -Wall -lm Examples/CExample.c Sources/CColorJourney/ColorJourney.c -o example
 * - All functions are documented with purpose and parameters
 * - Output is deterministic and reproducible
 */

#include "ColorJourney.h"
#include <stdio.h>

/* Helper function to display RGB color values with consistent formatting */
static void print_rgb(const char *label, CJ_RGB c) {
    printf("%s: r=%.3f g=%.3f b=%.3f\n", label, c.r, c.g, c.b);
}

int main(void) {
    /* Initialize configuration structure with safe defaults.
     * cj_config_init() sets reasonable starting values for all fields.
     */
    CJ_Config config;
    cj_config_init(&config);

    /* Configure the journey with a single blue anchor point and basic parameters.
     * 
     * Single Anchor:
     *   - anchor_count: 1 means the journey interpolates from dark to light variations of one color
     *   - anchors[0]: RGB(0.30, 0.50, 0.80) = medium blue
     * 
     * Loop Mode & Contrast:
     *   - CJ_LOOP_OPEN: Journey goes from dark to light, no wraparound
     *   - CJ_CONTRAST_MEDIUM: Moderate distinction between color stops (see Principle II)
     * 
     * See ColorJourney.h for CJ_Config struct definition and valid ranges.
     */
    config.anchor_count = 1;
    config.anchors[0] = (CJ_RGB){0.30f, 0.50f, 0.80f};
    config.contrast_level = CJ_CONTRAST_MEDIUM;
    config.loop_mode = CJ_LOOP_OPEN;

    /* Create the journey object from configuration.
     * 
     * The journey object is opaque; it maintains internal state for interpolation,
     * contrast enforcement, and perceptual color space conversions.
     * 
     * Error handling:
     *   - Returns NULL if allocation fails (should rarely happen)
     *   - Returns NULL if config is invalid (e.g., anchor_count == 0)
     */
    CJ_Journey journey = cj_journey_create(&config);
    if (!journey) {
        fprintf(stderr, "Failed to create journey\n");
        return 1;
    }

    /* Generate a discrete palette of 5 evenly-spaced colors.
     * 
     * Discrete palettes are ideal for:
     *   - UI color systems (categorical colors for buttons, badges, tags)
     *   - Data visualization (fixed number of categories)
     *   - Design systems (predefined palette sizes)
     * 
     * The function fills the provided array with CJ_RGB values in sequence.
     * All colors are deterministic given the same config and sample count.
     */
    CJ_RGB palette[5];
    cj_journey_discrete(journey, 5, palette);

    printf("Discrete palette (5 colors):\n");
    for (int i = 0; i < 5; i++) {
        char label[32];
        snprintf(label, sizeof(label), "stop %d", i);
        print_rgb(label, palette[i]);
    }

    /* Continuous sampling at an arbitrary point along the journey (t=0.42).
     * 
     * Continuous sampling is ideal for:
     *   - Gradient generation (smooth color transitions)
     *   - Dynamic color assignment (data-driven parameter)
     *   - Real-time UI effects (interpolate based on scroll, progress, etc.)
     * 
     * Parameter t:
     *   - Range: [0.0, 1.0] where 0.0 = journey start, 1.0 = journey end
     *   - Values outside [0, 1] depend on loop_mode:
     *     * CJ_LOOP_OPEN: clamped to [0.0, 1.0]
     *     * CJ_LOOP_CLOSED: wraps around (t=1.1 same as t=0.1)
     *     * CJ_LOOP_PINGPONG: bounces (t=1.1 interpolates backward)
     * 
     * Result: Smooth perceptually-spaced color at exact position (see Principle II).
     */
    CJ_RGB mid = cj_journey_sample(journey, 0.42f);
    print_rgb("Sample at t=0.42", mid);

    /* Seeded Variation Example
     * ========================
     * 
     * Demonstrates deterministic variation - same seed produces identical results
     * across runs, allowing auditable randomization for user-specific color schemes.
     * 
     * Use case: Generate unique but reproducible color systems for each user
     * by varying the seed based on user ID or session hash.
     * 
     * See Principle IV: Determinism guarantees apply to seeded variation.
     * Same seed + same config = identical output across sessions/devices.
     */
    printf("\nSeeded Variation Example (Principle IV - Determinism):\n");
    
    CJ_Config var_config;
    cj_config_init(&var_config);
    var_config.anchor_count = 1;
    var_config.anchors[0] = (CJ_RGB){0.70f, 0.40f, 0.20f};  /* Orange anchor */
    var_config.contrast_level = CJ_CONTRAST_MEDIUM;
    var_config.loop_mode = CJ_LOOP_OPEN;
    
    /* Enable variation with seed 42 (demonstrating seeded randomness) */
    var_config.variation_enabled = 1;
    var_config.variation_seed = 42;
    var_config.variation_strength = CJ_VARIATION_SUBTLE;
    
    CJ_Journey var_journey = cj_journey_create(&var_config);
    if (!var_journey) {
        fprintf(stderr, "Failed to create variation journey\n");
        return 1;
    }
    
    /* First run with seed 42 */
    CJ_RGB varied_palette_1[3];
    cj_journey_discrete(var_journey, 3, varied_palette_1);
    
    printf("Varied palette (seed=42, run 1):\n");
    for (int i = 0; i < 3; i++) {
        char label[32];
        snprintf(label, sizeof(label), "  varied %d", i);
        print_rgb(label, varied_palette_1[i]);
    }
    
    cj_journey_destroy(var_journey);
    
    /* Second run with same seed - demonstrates determinism */
    CJ_Journey var_journey_2 = cj_journey_create(&var_config);
    CJ_RGB varied_palette_2[3];
    cj_journey_discrete(var_journey_2, 3, varied_palette_2);
    
    printf("Varied palette (seed=42, run 2 - should be identical):\n");
    for (int i = 0; i < 3; i++) {
        char label[32];
        snprintf(label, sizeof(label), "  varied %d", i);
        print_rgb(label, varied_palette_2[i]);
    }
    
    /* Verify determinism: compare first and second run */
    int match = 1;
    for (int i = 0; i < 3; i++) {
        if (varied_palette_1[i].r != varied_palette_2[i].r ||
            varied_palette_1[i].g != varied_palette_2[i].g ||
            varied_palette_1[i].b != varied_palette_2[i].b) {
            match = 0;
            break;
        }
    }
    printf("Determinism check: %s\n\n", match ? "PASS (identical)" : "FAIL (different)");
    
    cj_journey_destroy(var_journey_2);

    /* Always destroy the journey when done to free allocated memory.
     * 
     * This is critical for:
     *   - Long-running applications (prevent memory leaks)
     *   - Tests (ensure reproducible memory state between runs)
     *   - Embedded systems (limited memory availability)
     * 
     * See Principle I (universal portability) - memory must be managed explicitly
     * because the library has zero external dependencies (no garbage collection).
     */
    cj_journey_destroy(journey);
    return 0;
}
