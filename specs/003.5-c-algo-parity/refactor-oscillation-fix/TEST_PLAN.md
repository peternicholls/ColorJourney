# Test Plan: Color Journey Smoothness Validation

## Overview

This test plan validates that the refactored C implementation produces **smooth, monotonic color trajectories** without oscillation, and that it matches the visual output of the Examples app.

---

## Unit Tests (C Core - `Tests/CColorJourneyTests/`)

### UT-1: Waypoint Envelope Removal

**Test:** `test_waypoint_no_oscillation`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 1;
config.anchors[0] = (CJ_RGB){0.5f, 0.2f, 0.8f};  // Purple
config.lightness_bias = CJ_LIGHTNESS_NEUTRAL;
config.chroma_bias = CJ_CHROMA_NEUTRAL;
config.loop_mode = CJ_LOOP_OPEN;

CJ_Journey journey = cj_journey_create(&config);
CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
```

**Assertion:**
```c
// Verify that waypoints have no sine-wave modulation
for (int i = 0; i < j->waypoint_count; i++) {
    // All waypoints should have the same L value (no lightness_envelope)
    assert_float_equal(j->waypoints[i].anchor.L, 
                       j->waypoints[0].anchor.L, 
                       0.001f);  // tolerance
    
    // All waypoints should have same C value (no chroma_envelope)
    assert_float_equal(j->waypoints[i].anchor.C, 
                       j->waypoints[0].anchor.C, 
                       0.001f);
}
```

**Expected Result:** ✅ All waypoints have identical L and C (only hue varies)

---

### UT-2: Chroma Pulse Removal

**Test:** `test_discrete_no_chroma_pulse`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 2;
config.anchors[0] = (CJ_RGB){1.0f, 0.0f, 0.0f};  // Red
config.anchors[1] = (CJ_RGB){0.0f, 0.0f, 1.0f};  // Blue
config.loop_mode = CJ_LOOP_OPEN;

CJ_Journey journey = cj_journey_create(&config);

CJ_RGB palette[40];
cj_journey_discrete(journey, 40, palette);
```

**Assertion:**
```c
// Extract chroma values and check for periodic modulation
float chroma_values[40];
for (int i = 0; i < 40; i++) {
    CJ_Lab lab = cj_rgb_to_oklab(palette[i]);
    chroma_values[i] = sqrtf(lab.a * lab.a + lab.b * lab.b);
}

// Check that chroma is smooth (not pulsing with cos pattern)
// Compute autocorrelation at lag=5 (pulse period)
// If pulsing exists, auto-correlation will be high
float auto_corr_lag5 = compute_autocorrelation(chroma_values, 40, 5);
assert(auto_corr_lag5 < 0.3f);  // Low correlation = no pulse pattern
```

**Expected Result:** ✅ Chroma values are smooth without periodic cosine pattern

---

### UT-3: Contrast Enforcement Non-Destructive

**Test:** `test_contrast_enforcement_minimal_nudge`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 1;
config.anchors[0] = (CJ_RGB){0.5f, 0.5f, 0.5f};  // Gray
config.contrast_level = CJ_CONTRAST_HIGH;  // Force enforcement

CJ_Journey journey = cj_journey_create(&config);

CJ_RGB palette[20];
cj_journey_discrete(journey, 20, palette);
```

**Assertion:**
```c
// Verify that enforcement nudges are small, not drastic
for (int i = 1; i < 20; i++) {
    CJ_Lab prev = cj_rgb_to_oklab(palette[i-1]);
    CJ_Lab curr = cj_rgb_to_oklab(palette[i]);
    
    // Check that L nudge is modest (< 0.1)
    float L_change = fabsf(curr.L - prev.L);
    assert(L_change < 0.15f);
    
    // Check that hue and chroma don't jump (they should be smooth from interpolation)
    float hue_prev = atan2f(prev.b, prev.a);
    float hue_curr = atan2f(curr.b, curr.a);
    float hue_change = fabsf(hue_curr - hue_prev);
    assert(hue_change < 0.3f);  // ~17 degrees
}
```

**Expected Result:** ✅ Adjustments are subtle nudges, not dramatic shifts

---

### UT-4: Hue Unidirectionality (Single Anchor)

**Test:** `test_hue_monotonic_single_anchor`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 1;
config.anchors[0] = (CJ_RGB){0.8f, 0.2f, 0.1f};  // Orange
config.loop_mode = CJ_LOOP_CLOSED;

CJ_Journey journey = cj_journey_create(&config);

CJ_RGB palette[50];
cj_journey_discrete(journey, 50, palette);
```

**Assertion:**
```c
// Extract hue angles and verify no backtracking
float hue_values[50];
for (int i = 0; i < 50; i++) {
    CJ_Lab lab = cj_rgb_to_oklab(palette[i]);
    hue_values[i] = atan2f(lab.b, lab.a);
    if (hue_values[i] < 0) hue_values[i] += 2 * M_PI;
}

// Check hue progression is unidirectional (allowing wrap at 2π)
for (int i = 1; i < 50; i++) {
    float hue_diff = hue_values[i] - hue_values[i-1];
    
    // Handle wrap: if diff is large negative, it's a wrap
    if (hue_diff < -M_PI) {
        hue_diff += 2 * M_PI;  // Wrapped forward
    }
    
    // All deltas should be positive (forward progression)
    assert(hue_diff >= -0.1f);  // Small tolerance for numerical errors
}
```

**Expected Result:** ✅ Hue progresses smoothly around the wheel without backtracking

---

### UT-5: Lightness Monotonicity in L-Space

**Test:** `test_lightness_smooth_trajectory`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 2;
config.anchors[0] = (CJ_RGB){0.1f, 0.1f, 0.1f};  // Dark
config.anchors[1] = (CJ_RGB){0.9f, 0.9f, 0.9f};  // Light
config.loop_mode = CJ_LOOP_OPEN;
config.lightness_bias = CJ_LIGHTNESS_NEUTRAL;

CJ_Journey journey = cj_journey_create(&config);

CJ_RGB palette[30];
cj_journey_discrete(journey, 30, palette);
```

**Assertion:**
```c
// Extract lightness and check for smooth progression
float L_values[30];
for (int i = 0; i < 30; i++) {
    CJ_Lab lab = cj_rgb_to_oklab(palette[i]);
    L_values[i] = lab.L;
}

// Check that L changes are small and consistent (not wavy)
float prev_delta = 0;
for (int i = 1; i < 30; i++) {
    float delta = L_values[i] - L_values[i-1];
    
    // All deltas should be similar (consistent pacing)
    float delta_change = fabsf(delta - prev_delta);
    assert(delta_change < 0.01f);  // Tight tolerance
    
    prev_delta = delta;
}
```

**Expected Result:** ✅ Lightness changes smoothly with consistent pacing

---

## Integration Tests

### IT-1: C Core vs Swift Wrapper Parity

**Test:** `test_c_swift_identical_output`

**Setup:**
```c
// C side
CJ_Config config = {
    .anchor_count = 2,
    .anchors = {{1.0f, 0.42f, 0.21f}, {0.0f, 0.31f, 0.53f}},
    .lightness_bias = CJ_LIGHTNESS_NEUTRAL,
    .chroma_bias = CJ_CHROMA_NEUTRAL,
    .contrast_level = CJ_CONTRAST_MEDIUM,
    .loop_mode = CJ_LOOP_OPEN
};

CJ_Journey c_journey = cj_journey_create(&config);
CJ_RGB c_palette[12];
cj_journey_discrete(c_journey, 12, c_palette);

// Swift side
let swiftConfig = ColorJourneyConfig(
    anchors: [
        ColorJourneyRGB(red: 1.0, green: 0.42, blue: 0.21),
        ColorJourneyRGB(red: 0.0, green: 0.31, blue: 0.53)
    ],
    lightness: .neutral,
    chroma: .neutral,
    contrast: .medium,
    loopMode: .open
)

let swiftJourney = ColorJourney(config: swiftConfig)
let swiftPalette = swiftJourney.discrete(count: 12)
```

**Assertion:**
```c
// Compare RGB values with small tolerance (±2/255 per component)
const float TOLERANCE = 2.0f / 255.0f;

for (int i = 0; i < 12; i++) {
    assert_float_equal_abs(c_palette[i].r, swiftPalette[i].rgb.r, TOLERANCE);
    assert_float_equal_abs(c_palette[i].g, swiftPalette[i].rgb.g, TOLERANCE);
    assert_float_equal_abs(c_palette[i].b, swiftPalette[i].rgb.b, TOLERANCE);
}
```

**Expected Result:** ✅ All 12 colors match within rounding tolerance

---

### IT-2: C Core vs Website Visual Parity

**Test:** `test_website_c_core_identical`

**Setup:**
```typescript
// Website side
const config: ColorJourneyConfig = {
  anchors: ["#FF6B35", "#004E89"],
  numColors: 12,
  loop: 'open',
  dynamics: {
    lightness: 0,
    chroma: 1.0,
    contrast: 0.05,
    vibrancy: 0.5,
    warmth: 0,
  },
  variation: { mode: 'off', seed: 0 }
};

const result = await ColorJourneyEngine.generate(config);
const websitePalette = result.palette;

// C side
CJ_RGB c_palette[12];
// ... generate with same config
```

**Assertion:**
```typescript
const TOLERANCE = 2;  // RGB units (0-255 scale)

for (let i = 0; i < 12; i++) {
    const webHex = websitePalette[i].hex;
    const cHex = rgbToHex(c_palette[i]);
    
    const webRGB = hexToRGB(webHex);
    const cRGB = hexToRGB(cHex);
    
    assert(Math.abs(webRGB.r - cRGB.r) <= TOLERANCE);
    assert(Math.abs(webRGB.g - cRGB.g) <= TOLERANCE);
    assert(Math.abs(webRGB.b - cRGB.b) <= TOLERANCE);
}
```

**Expected Result:** ✅ Website and C core produce visually identical hex codes

---

### IT-3: Visual Inspection - No Jet Stream

**Test:** `test_3d_visualization_smooth`

**Manual Verification:**
1. Open website
2. Set anchors: `#FF6B35` → `#004E89`
3. Set count: 20
4. Set dynamics: neutral
5. Toggle 3D View
6. Visually inspect:
   - No oscillating waves in 3D space
   - Path is smooth curve (not tangled)
   - No sudden direction changes
   - Hue rotates smoothly around the color sphere

**Expected Result:** ✅ 3D path is clean, smooth, unidirectional

---

## Performance Tests (Optional)

### PT-1: Generation Speed (No Regression)

**Test:** `test_discrete_generation_speed`

**Setup:**
```c
CJ_Config config;
cj_config_init(&config);
config.anchor_count = 2;
config.anchors[0] = (CJ_RGB){0.8f, 0.2f, 0.1f};
config.anchors[1] = (CJ_RGB){0.1f, 0.2f, 0.8f};

CJ_Journey journey = cj_journey_create(&config);

clock_t start = clock();
for (int iteration = 0; iteration < 1000; iteration++) {
    CJ_RGB palette[100];
    cj_journey_discrete(journey, 100, palette);
}
clock_t end = clock();
```

**Assertion:**
```c
double elapsed_ms = (double)(end - start) / CLOCKS_PER_SEC * 1000.0;
double per_palette_ms = elapsed_ms / 1000.0;

// Should be fast (< 1ms per 100-color palette on modern hardware)
assert(per_palette_ms < 1.0);  // Tolerance: 1ms
```

**Expected Result:** ✅ No performance regression (same or faster)

---

## Test Execution Order

1. **Phase 1 (After Change 1):** Run UT-1
2. **Phase 2 (After Change 2):** Run UT-2
3. **Phase 3 (After Change 3):** Run UT-3, UT-4, UT-5
4. **Phase 4 (All changes done):** Run IT-1, IT-2, IT-3
5. **Final (Before release):** Run PT-1

---

## Acceptance Criteria

| Test | Status | Notes |
|------|--------|-------|
| UT-1 | ✅/❌ | All waypoints have no envelope modulation |
| UT-2 | ✅/❌ | No cosine-pattern chroma pulsing |
| UT-3 | ✅/❌ | Contrast adjustments are small |
| UT-4 | ✅/❌ | Hue is unidirectional |
| UT-5 | ✅/❌ | Lightness is smooth and monotonic |
| IT-1 | ✅/❌ | C and Swift match to ±2/255 per component |
| IT-2 | ✅/❌ | Website and C match to ±2 RGB units |
| IT-3 | ✅/❌ | 3D visualization is clean and smooth |
| PT-1 | ✅/❌ | Performance within bounds |

**All tests must pass before PR merge.**

---

## Regression Testing

Before merging, also verify:
- [ ] Existing `Examples/SwatchDemo` still builds and runs
- [ ] Existing `Examples/JourneyPreview` output unchanged
- [ ] No compilation warnings
- [ ] No memory leaks (run with valgrind)

