# Feature Specification: JourneyPreview Demo Refresh

**Feature Branch**: `005-demo-app-refresh`  
**Created**: December 17, 2025  
**Status**: Draft  
**Input**: User description: "before we roll out the release, we will do spec 005 - where we update the demo app at ./Examples/JourneyPreview/ to include the new features. This App should become a featured demo epp for developers to try out the color engine and see the output. As part of the app, we should seperate the app in to pages, or views depending on what we are asking the user to look at / test. For each, we must allow user input, either by a slider with ticks, or a box to put a number in, or drop down, or radio buttons.... etc depending on context. Advisory copy, and also information boxes, such as the technical side (deltas, and performance), and what the code would look like if one wanted to implement that (together with a copy button so they can try it in their own code) We can also include css code for the colour set, (if within a reasonable number of colours!) we also need to handle requests larger than say 50 or 100 sensibly. yes its possible, but is it wise?! the look should be professional, the swatches should be rounded squares. the user can change the background, and using a slider make the swatches bigger or smaller (like the finder does, or photos app for examples)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Explore incremental palettes (Priority: P1)

Developers open JourneyPreview, navigate to the palette exploration view, set palette size, delta target, and background, then see rounded swatches update live with advisory copy and can copy example code.

**Why this priority**: Core promise of the demo is to showcase incremental color generation and deltas with immediate feedback.

**Independent Test**: From app launch, adjust sliders/inputs and generate a palette; verify swatches update, background and size controls apply, advisory text appears, and copy button copies code.

**Acceptance Scenarios**:

1. **Given** the app is opened on the palette view, **When** a developer changes palette count and delta spacing inputs, **Then** a refreshed set of rounded swatches renders reflecting the inputs and advisory text describes the change.
2. **Given** swatches are visible, **When** the developer taps copy code, **Then** the relevant code snippet is copied and a confirmation appears.

---

### User Story 2 - Compare usage examples (Priority: P2)

Developers switch to a view that shows how to consume the generated colors in code and CSS, adjust sample parameters, and copy snippets to try locally.

**Why this priority**: Demonstrates integration paths and reduces friction for adoption.

**Independent Test**: Navigate to the examples view, adjust parameters, observe code samples update, and copy both language and CSS snippets successfully.

**Acceptance Scenarios**:

1. **Given** the examples view is open, **When** the developer changes palette parameters, **Then** both language and CSS snippets refresh to reflect the new palette.
2. **Given** updated snippets are shown, **When** the developer uses copy controls, **Then** each snippet copies separately with confirmation.

---

### User Story 3 - Handle large palette requests (Priority: P3)

Developers request large palettes (50–100+ colors) and receive guidance, safe presentation (pagination or grouping), and performance notes before proceeding.

**Why this priority**: Prevents poor UX or misunderstandings for large sets while still enabling exploration.

**Independent Test**: Request a palette above the guidance threshold; verify warnings/advice appear, UI remains responsive, and swatches present safely (grouped/paged) without freezing.

**Acceptance Scenarios**:

1. **Given** the developer requests more than the recommended number of colors, **When** the request is submitted, **Then** the app shows advisory messaging and offers a safe display mode before rendering.
2. **Given** a large palette is displayed, **When** the developer adjusts size/background sliders, **Then** the UI updates without noticeable lag and maintains rounded swatch styling.

---

### Edge Cases

- Invalid numeric input (negative counts, non-numeric text) is rejected with inline guidance without crashing.
- Requests exceeding an upper bound (assume 200 colors) are capped or declined with rationale and suggestion to batch.
- Extremely small deltas that would produce near-identical colors trigger advisory and safe defaults.
- High-contrast or low-contrast backgrounds still keep swatches legible and interactive.
- Copy action unavailable (clipboard denied) surfaces a fallback instruction.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Provide distinct navigable views/pages separating palette exploration, code examples, and large-set handling.
- **FR-002**: Palette exploration view MUST accept user inputs for palette size, delta/spacing target, and seed/background via sliders, steppers, or numeric fields with tick marks where relevant.
- **FR-003**: Swatch presentation MUST use rounded square tiles whose size can be adjusted by a slider; tiles adapt to background color changes.
- **FR-004**: Display contextual advisory copy per view covering what inputs mean, expected results, and how deltas/performance behave.
- **FR-005**: Present code snippets showing how to generate/use the palette (language sample) plus CSS definitions when the palette size is within a reasonable limit; include per-snippet copy buttons with confirmations.
- **FR-006**: For palette sizes above a guidance threshold (default 50) and up to an upper limit (default 200), show warnings and render using safe layouts (paging/grouping) to avoid overload while still allowing inspection.
- **FR-007**: For requests beyond the upper limit, decline rendering and suggest alternative approaches (batching, sampling) with clear messaging.
- **FR-008**: Inputs MUST validate and clamp to safe ranges, surfacing inline errors without breaking the session.
- **FR-009**: The UI MUST remain responsive during parameter changes and rendering, with visual feedback on progress if rendering is delayed.
- **FR-010**: Swatch displays MUST remain legible under different backgrounds through automatic contrast-aware text or border treatment.

### Key Entities *(include if feature involves data)*

- **ColorSetRequest**: Represents requested palette parameters (count, delta target, background, size preference, safety flags).
- **SwatchDisplay**: Represents rendered swatch attributes (color value, label/index, size, accessibility contrast notes).
- **CodeSnippet**: Represents generated example code artifacts (language sample, CSS sample) tied to the current palette parameters and copy state.
- **UserAdjustment**: Captures recent input changes (controls, thresholds) to drive live updates and advisory messaging.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can generate and view a customized palette with updated swatches, background, and size within 15 seconds from app launch in 95% of test runs.
- **SC-002**: 90% of copy-code attempts for both language and CSS snippets succeed on the first try with confirmation feedback.
- **SC-003**: For palette requests above the guidance threshold, advisory messaging appears before rendering in 100% of cases and the UI remains responsive (no visible freezes longer than 1 second) in usability tests.
- **SC-004**: Usability testing reports at least 8/10 satisfaction for clarity of controls, messaging, and swatch readability across backgrounds.
- **SC-005**: All functional inputs enforce safe ranges with zero crashes or unhandled errors during validation and rendering walkthroughs.

## Assumptions

- Primary audience is developers evaluating the color engine; technical terms like delta and perceptual spacing are acceptable with brief explanations.
- Code examples will prioritize the platform’s native language sample plus CSS; additional languages can be deferred.
- Guidance threshold defaults: warn at 50 colors, allow up to 200 with safe layout; these can be configured without changing scope.
- Clipboard access is available in the demo environment; if denied, a fallback instruction suffices.
