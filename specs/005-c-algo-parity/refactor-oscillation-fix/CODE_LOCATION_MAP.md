# Visual Map of Code Changes in ColorJourney.c

## File: `Sources/CColorJourney/ColorJourney.c` (868 lines total)

```
┌─────────────────────────────────────────────────────────────┐
│  ColorJourney.c Structure                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Lines 1-30       | Header, includes, macros                │
│                   |                                          │
│  Lines 31-100     | Fast math helpers (cbrt, lerp, etc)     │
│                   |                                          │
│  Lines 100-200    | OKLab color space (conversion fns)      │
│                   |                                          │
│  Lines 200-250    | Helper fns (delta_e, clamp, etc)        │
│                   |                                          │
│  Lines 250-310    | RNG (xoshiro) and config init           │
│                   |                                          │
│ ╔═ Lines 310-380 ═╗ build_waypoints() function             │
│ ║ ⚠️  CHANGE 1    ║                                          │
│ ║ Remove envelopes║  - Delete sine-wave modulation          │
│ ║ HERE            ║  - Lines 330-345                        │
│ ╚═════════════════╝                                          │
│                   |                                          │
│  Lines 380-450    | CJ_Journey creation & destruction        │
│                   |                                          │
│  Lines 450-550    | interpolate_waypoints() function        │
│                   | apply_dynamics() function               │
│                   | apply_variation() function              │
│                   |                                          │
│  Lines 550-650    | cj_journey_sample() function            │
│                   |                                          │
│ ╔═ Lines 650-730 ═╗ apply_minimum_contrast() function      │
│ ║ ⚠️  CHANGE 3    ║                                          │
│ ║ Simplify to     ║  - Lines 670-720                        │
│ ║ L-only          ║  - Replace multi-strategy logic         │
│ ║ HERE            ║  - Use single L nudge                   │
│ ╚═════════════════╝                                          │
│                   |                                          │
│  Lines 730-810    | discrete_color_at_index()               │
│                   | cj_journey_discrete_at()                │
│                   | cj_journey_discrete_range()             │
│                   |                                          │
│ ╔═ Lines 810-860 ═╗ cj_journey_discrete() function         │
│ ║ ⚠️  CHANGE 2    ║                                          │
│ ║ Remove pulse    ║  - Lines 815-835                        │
│ ║ overlay         ║  - Delete chroma pulse block            │
│ ║ HERE            ║  - Keep main loop intact                │
│ ╚═════════════════╝                                          │
│                   |                                          │
│  Lines 860-868    | EOF                                      │
│                   |                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Change 1: Lines 330-345 (build_waypoints)

### Context: Single Anchor Waypoint Creation

```c
──────────────────────────────────────────────────────────────
325  {
326      CJ_Journey_Impl* j = (CJ_Journey_Impl*)journey;
327      
328      if (j->anchor_count == 1) {
329          /* Single anchor: full wheel journey with shaped pacing */
330          CJ_LCh base = j->anchor_lch[0];
331          
332          /* Create waypoints with non-linear hue distribution */
333          const int num_waypoints = 8;
334          
335          j->waypoint_count = num_waypoints;
336          for (int i = 0; i < num_waypoints; i++) {
337              float t = (float)i / (float)(num_waypoints - 1);
338              
339              /* Non-linear hue progression using smoothstep */
340              float hue_t = smoothstep(t);
341              
342              j->waypoints[i].anchor.h = base.h + hue_t * 2.0f * M_PI;
343              
344  ┌─────────────────────────────────────────────────────────┐
345  │ /* Subtle chroma variation - peak at golden ratio    │  ← DELETE
346  │    point */                                           │     LINES
347  │ float chroma_envelope = 1.0f + 0.2f * sinf(t * M_PI);│   345-351
348  │ j->waypoints[i].anchor.C = base.C * chroma_envelope; │
349  │                                                        │
350  │ /* Lightness gentle wave */                           │
351  │ float lightness_envelope = 1.0f + 0.1f * sinf(t *    │
352  │     2.0f * M_PI);                                     │
353  │ j->waypoints[i].anchor.L = base.L * lightness_       │
354  │     envelope;                                          │
355  └─────────────────────────────────────────────────────────┘
356              
357              j->waypoints[i].weight = 1.0f;
358          }
──────────────────────────────────────────────────────────────
```

### REPLACE WITH:

```c
              j->waypoints[i].anchor.h = base.h + hue_t * 2.0f * M_PI;
              
              /* No envelope - preserve base values */
              j->waypoints[i].anchor.C = base.C;
              j->waypoints[i].anchor.L = base.L;
              
              j->waypoints[i].weight = 1.0f;
```

---

## Change 2: Lines 815-835 (cj_journey_discrete)

### Context: Discrete Palette Generation (End)

```c
──────────────────────────────────────────────────────────────
810      }
811      
812  ┌────────────────────────────────────────────────────────────┐
813  │ /* ========== PERIODIC CHROMA PULSE (WASM Enhancement) │  ← DELETE
814  │  * For large palettes (>CJ_CHROMA_PULSE_MIN_COLORS),   │     ENTIRE
815  │  * apply a periodic chroma modulation...               │     BLOCK
816  │  *                                                      │    815-840
817  │  * Formula: chroma_pulse = 1.0 + 0.1 * cos(i * π/5)   │
818  │  * ...                                                 │
819  │  */                                                     │
820  │ if (count > CJ_CHROMA_PULSE_MIN_COLORS) {              │
821  │     for (int i = 0; i < count; i++) {                  │
822  │         CJ_Lab lab = cj_rgb_to_oklab(out_colors[i]);   │
823  │         CJ_LCh lch = cj_oklab_to_lch(lab);             │
824  │                                                         │
825  │         double chroma_pulse = 1.0 + 0.1 * cos((double)i│
826  │             * M_PI / 5.0);                             │
827  │         lch.C = (float)((double)lch.C * chroma_pulse); │
828  │         lch.C = clampf(lch.C, 0.0f, 0.4f);            │
829  │                                                         │
830  │         lab = cj_lch_to_oklab(lch);                    │
831  │         out_colors[i] = cj_oklab_to_rgb(lab);          │
832  │         out_colors[i] = cj_rgb_clamp(out_colors[i]);   │
833  │     }                                                   │
834  │ }                                                       │
835  └────────────────────────────────────────────────────────────┘
836  }
──────────────────────────────────────────────────────────────
```

### REPLACE WITH:

```c
      }
      /* Chroma pulse removed - colors from primary curve only */
  }
```

---

## Change 3: Lines 670-720 (apply_minimum_contrast)

### Context: Contrast Enforcement Function

```c
──────────────────────────────────────────────────────────────
665  static CJ_RGB apply_minimum_contrast(CJ_RGB color,
666                                       const CJ_RGB* previous,
667                                       float min_delta_e) {
668      if (!previous) return color;
669  
670      CJ_Lab prev_lab = cj_rgb_to_oklab(*previous);
671      CJ_Lab curr_lab = cj_rgb_to_oklab(color);
672      
673  ┌─────────────────────────────────────────────────────────┐
674  │ /* Iterative refinement (up to CJ_CONTRAST_MAX_ITERS) │  ← REPLACE
675  │  */                                                     │     ENTIRE
676  │ const int max_iterations = CJ_CONTRAST_MAX_ITERATIONS;│     LOOP
677  │ for (int iter = 0; iter < max_iterations; iter++) {  │
678  │     float dE = cj_delta_e(curr_lab, prev_lab);        │    673-730
679  │     ...                                                │
680  │     if (dE >= min_delta_e) break;                     │
681  │                                                        │
682  │     float shortfall = min_delta_e - dE;               │
683  │                                                        │
684  │     /* Strategy 1: Adjust lightness */                │
685  │     float direction = (prev_lab.L < 0.5f) ? 1.0f : -  │
686  │         1.0f;                                          │
687  │     float L_nudge = shortfall * 0.5f;                 │
688  │     curr_lab.L = clampf(curr_lab.L + direction *      │
689  │         L_nudge, 0.0f, 1.0f);                         │
690  │                                                        │
691  │     dE = cj_delta_e(curr_lab, prev_lab);              │
692  │     if (dE >= min_delta_e) break;                     │
693  │                                                        │
694  │     /* Strategy 2: Adjust a and b components */       │
695  │     shortfall = min_delta_e - dE;                     │
696  │     CJ_LCh lch = cj_oklab_to_lch(curr_lab);           │
697  │                                                        │
698  │     /* Try rotating hue */                            │
699  │     float hue_rotation = 0.2f;                        │ ← HUE JUMPING
700  │     lch.h += hue_rotation * (float)iter;              │   (REMOVED)
701  │     while (lch.h >= 2.0f * M_PI) lch.h -= 2.0f *     │
702  │         M_PI;                                          │
703  │                                                        │
704  │     if (lch.C > 1e-5f) {                              │
705  │         float scale = 1.0f + shortfall * 0.5f;        │
706  │         lch.C = fminf(lch.C * scale, 0.4f);           │
707  │     }                                                  │
708  │                                                        │
709  │     curr_lab = cj_lch_to_oklab(lch);                  │
710  │ }                                                      │
711  └─────────────────────────────────────────────────────────┘
712  
713      CJ_RGB adjusted = cj_oklab_to_rgb(curr_lab);
714      return cj_rgb_clamp(adjusted);
715  }
──────────────────────────────────────────────────────────────
```

### REPLACE WITH:

```c
    float dE = cj_delta_e(curr_lab, prev_lab);
    if (dE >= min_delta_e) {
        /* Already sufficient contrast */
        return color;
    }
    
    /* Single-pass L adjustment (monotonic, smooth) */
    float shortfall = min_delta_e - dE;
    
    /* Determine direction: always push away from previous L */
    float direction = (curr_lab.L >= prev_lab.L) ? 1.0f : -1.0f;
    if (direction > 0.0f && curr_lab.L > 0.95f) direction = -1.0f;
    if (direction < 0.0f && curr_lab.L < 0.05f) direction = 1.0f;
    
    /* Apply modest L adjustment */
    float L_nudge = shortfall * 0.8f;
    curr_lab.L = clampf(curr_lab.L + direction * L_nudge, 0.0f, 1.0f);
    
    CJ_RGB adjusted = cj_oklab_to_rgb(curr_lab);
    return cj_rgb_clamp(adjusted);
```

---

## Change 4: Constants (Optional Cleanup)

**Location:** Lines ~30-40  
**Current:**
```c
#define CJ_CHROMA_PULSE_MIN_COLORS 20
#define CJ_CONTRAST_MAX_ITERATIONS 5
```

**New:**
```c
/* REMOVED: CJ_CHROMA_PULSE_MIN_COLORS (no longer used) */
#define CJ_CONTRAST_MAX_ITERATIONS 1  /* Now single-pass */
```

---

## Change 5: Documentation (Optional)

**Location:** cj_journey_discrete() comment block  
**Update comment to clarify:**
```c
/**
 * Generate a discrete palette with N evenly-spaced colors.
 * 
 * ALGORITHM (SIMPLIFIED):
 * 1. Sample journey at N evenly-spaced positions
 * 2. Enforce minimum contrast using modest L adjustment only
 * 3. Return colors as continuous array
 * 
 * No post-hoc oscillatory overlays or periodic modulation.
 * The primary curve is smooth and monotonic in 3D OKLab space.
 */
```

---

## Summary of Changes

| Change | Location | Type | Complexity |
|--------|----------|------|------------|
| 1 | Lines 330-345 | Delete + Replace | Low |
| 2 | Lines 815-835 | Delete | Low |
| 3 | Lines 670-730 | Replace | Medium |
| 4 | Lines ~30-40 | Modify | Low |
| 5 | Comment block | Document | Low |

**Total impact:** ~70 lines modified out of 868 total (8% of file)

