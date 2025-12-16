# Refactor Plan: Fix Oscillatory Behavior in Color Journey

## Problem Statement

The C implementation produces **oscillating, chaotic color paths** ("jet stream behavior") instead of smooth, monotonic trajectories through OKLab 3D space. Despite passing C-to-Swift parity tests, the visual output is wildly different from user expectations.

## Root Causes Identified

### 1. **Chroma Pulsing Overlay** (Lines ~815-835 in ColorJourney.c)
```c
if (count > CJ_CHROMA_PULSE_MIN_COLORS) {
    double chroma_pulse = 1.0 + 0.1 * cos((double)i * M_PI / 5.0);
    lch.C = (float)((double)lch.C * chroma_pulse);
}
```
- Creates periodic **wave pattern** on top of smooth journey
- Every ~5 colors: saturation peaks then drops (like a sine wave)
- This overlay interferes with the primary trajectory

### 2. **Oscillatory Waypoint Envelopes** (Lines ~330-345 in ColorJourney.c)
```c
float chroma_envelope = 1.0f + 0.2f * sinf(t * M_PI);
float lightness_envelope = 1.0f + 0.1f * sinf(t * 2.0f * M_PI);
```
- Lightness and chroma have **sine wave modulation** baked into waypoints
- Creates artificial undulation in what should be smooth curves
- Compounds with the chroma pulse overlay

### 3. **Hue Jumping in Contrast Enforcement** (Lines ~703-710 in ColorJourney.c)
```c
float hue_rotation = 0.2f;  /* ~11 degrees */
lch.h += hue_rotation * (float)iter;  /* Increase rotation each iteration */
```
- When contrast enforcement activates, hue **jumps by 11°** per iteration
- Creates visible discontinuities in the hue path
- No smoothing or geodesic awareness

### 4. **Multi-Strategy Contrast Enforcement** (Lines ~670-720)
- Tries L adjustment, then chroma boost, then hue rotation
- Each strategy can move the color in different directions
- Creates scattered, non-linear adjustments that break trajectory smoothness

---

## Proposed Solution Architecture

### Phase 1: Simplify to Core Trajectory (Clean Foundation)

**Goal:** Create a **single, smooth path** through OKLab 3D space with zero overlays.

**Changes:**
1. **Remove chroma pulsing overlay entirely** (Lines ~815-835)
   - This is post-hoc interference with the primary curve
   - Doesn't solve fundamental design—just adds noise
   
2. **Remove oscillatory envelopes from waypoints** (Lines ~330-345)
   - Replace sine-wave modulation with identity (no envelope)
   - Let interpolation and dynamics handle curve shape
   
3. **Simplify contrast enforcement to single strategy** (Lines ~670-720)
   - Use **lightness adjustment only** (not rotation/chroma changes)
   - Monotonic push: always adjust in same direction for same color
   - Max 2 iterations (not 5)

**Code Changes:**
- `build_waypoints()`: Remove `sinf()` envelopes
- `cj_journey_discrete()`: Remove chroma pulse block
- `apply_minimum_contrast()`: Simplify to L-only, 2 iterations max

---

### Phase 2: Topology-Aware Interpolation (Smooth Curves)

**Goal:** Ensure the **primary path is smooth** with no backtracking or oscillation.

**Changes:**
1. **Use Catmull-Rom spline interpolation** instead of waypoint lerp
   - Smoothly interpolate between 4 control points at a time
   - Ensures $C^1$ continuity (no kinks)
   
2. **Hue path uses geodesic on unit circle**
   - Shortest rotation angle (not arbitrary)
   - Wrapped hue stays in [0, 2π]
   
3. **Validate no inversions**
   - Check that L is monotonic (or gently varies, not oscillates)
   - Check that C increases then decreases smoothly (not sharp peaks)
   - Check that hue rotation is unidirectional (no backtracking)

---

### Phase 3: Dynamics as Deformations (Not Overlays)

**Goal:** Apply user preferences as **smooth deformations** of the curve, not post-hoc adjustments.

**Changes:**
1. **Bake `lightness_bias`, `chroma_bias`, `temperature_bias` into waypoints at creation time**
   - Not applied during `apply_dynamics()`
   - Ensures all bias effects are part of the primary interpolation
   
2. **Mid-journey vibrancy as smooth envelope**
   - Replace sharp peak with Hann window: $1 + v \cdot (0.5 + 0.5 \cos(2\pi(t - 0.5)))$
   - Smooth ramp up/down, no artifacts
   
3. **Variation as small noise, not hue jumps**
   - Keep magnitude small (±0.01 in L, ±0.02 in C)
   - Gaussian-distributed (not uniform random)
   - Applied after primary curve (transparent layer)

---

## Test Plan

### Unit Tests (C Core)

**Test 1: Monotonicity**
```
Given: single-anchor journey, no dynamics
Expected: L and C values form smooth curves with no reversals
Verify: For all i, curve[i].L ≤ curve[i+1].L + ε (ε = 0.01 tolerance)
```

**Test 2: Hue Unidirectionality**
```
Given: single-anchor journey, closed loop
Expected: Hue progresses 0 → 2π with no backtracking
Verify: All hue deltas are positive (except wrap at 2π)
```

**Test 3: Contrast Enforcement is Non-Destructive**
```
Given: palette with contrast enforcement enabled
Expected: Enforcement nudges colors slightly, doesn't cause huge jumps
Verify: Max ΔE adjustment per color ≤ 0.05 (perceptually small)
```

**Test 4: Chroma Pulse Removed**
```
Given: 30-color palette from build_waypoints()
Expected: No periodic wave pattern in chroma values
Verify: Chroma values are smooth, not cos/sin modulated
```

**Test 5: Consistency with Examples App**
```
Given: JourneyPreview app output and website output for same config
Expected: Output is visually identical (no jet stream)
Verify: Hex codes match to within ±2 RGB units per component
```

### Integration Tests

**Test 6: Website vs Examples App Visual Parity**
```
Create reference palette with:
  - Anchors: [#FF6B35, #004E89]
  - Dynamics: neutral bias, medium contrast
  - Count: 12 colors
  
Compare:
  - C core output
  - Examples app (Swift wrapper)
  - Website (after WASM fix)
  
Expected: All three produce identical swatches
```

**Test 7: Smooth Interpolation in 3D**
```
Generate 100-color palette
Check 3D path in OKLab:
  - No crossing or self-intersection
  - Arc length is monotonic (no doubling back)
  - Minimum ΔE between adjacent colors ≥ 0.05
```

---

## Files to Modify

| File | Lines | Change | Complexity |
|------|-------|--------|------------|
| `ColorJourney.c` | 330-345 | Remove envelopes in `build_waypoints()` | Low |
| `ColorJourney.c` | 815-835 | Remove chroma pulse in `cj_journey_discrete()` | Low |
| `ColorJourney.c` | 670-720 | Simplify `apply_minimum_contrast()` | Medium |
| `ColorJourney.c` | 455-500 | Refactor `interpolate_waypoints()` for spline | High |
| `ColorJourney.h` | - | Add `CJ_Spline` struct (optional) | Low |

---

## Rollout Strategy

### Step 1: Remove Oscillatory Patterns (Quick Win)
- Delete chroma pulse code
- Delete envelope modulation
- Simplify contrast enforcement
- Test: Visual inspection should show smoother curves immediately

### Step 2: Implement Spline Interpolation
- Replace linear waypoint lerp with Catmull-Rom
- Add geodesic hue rotation
- Validate no inversions
- Test: Unit tests pass, monotonicity verified

### Step 3: Bake Dynamics into Waypoints
- Move bias application to creation time
- Apply vibrancy as envelope at sample time
- Keep variation separate
- Test: Configuration changes produce expected effects

### Step 4: Integration & Validation
- Wire up WASM in website
- Compare C ↔ Swift ↔ Website outputs
- Verify visual parity with Examples app
- Test: Cross-implementation consistency

---

## Success Criteria

1. ✅ **No oscillation visible** in 3D color space (checked with OKLab3DViewer)
2. ✅ **Smooth curves** in both website and Examples app (visual inspection)
3. ✅ **Monotonic trajectory** (at least locally smooth, no backtracking)
4. ✅ **Consistency** between C core and Swift wrapper (Hex codes match)
5. ✅ **All tests pass** (unit + integration)
6. ✅ **Examples app output matches website** for identical inputs

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Breaking existing API | Core `cj_journey_*` signatures stay the same; only internals change |
| Regression in contrast | Comprehensive testing; fallback to old algorithm if needed |
| WASM build failure | Separate task; fallback to TypeScript stub already exists |
| Performance degradation | Spline is O(1) per sample; no perf impact |

