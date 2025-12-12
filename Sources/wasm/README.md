# Color Journey C Core & WebAssembly Build Guide
This document outlines the process for compiling the C core of the Color Journey engine into a WebAssembly (`.wasm`) module for use in the browser and on Cloudflare Workers.
## Phase 2 Goal
The objective is to replace the TypeScript fallback implementation in `src/lib/color-journey/index.ts` with a high-performance, portable C implementation compiled to WASM. The public JavaScript API exposed by the wrapper must remain identical.
## Build Toolchain
We recommend using the **Emscripten SDK (emsdk)** for compiling C to WASM, as it provides robust tooling and JS glue code generation.
1.  **Install Emscripten:**
    Follow the official instructions at https://emscripten.org/docs/getting_started/downloads.html
2.  **Activate the SDK:**
    ```bash
    # Navigate to your emsdk directory
    ./emsdk activate latest
    source ./emsdk_env.sh
    ```
## Compilation Command
The following command compiles `color_journey.c` into a `.wasm` file and a JavaScript loader (`.js`) file.
```bash
emcc src/wasm/color_journey.c \
  -o public/assets/color_journey.js \
  -s WASM=1 \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s USE_ES6_IMPORT_META=0 \
  -s EXPORTED_RUNTIME_METHODS='["cwrap"]' \
  -s EXPORTED_FUNCTIONS='["_malloc", "_free", "_generate_discrete_palette"]' \
  -O3
```
**Command Breakdown:**
-   `emcc ...`: The Emscripten compiler.
-   `-o public/assets/color_journey.js`: The output path. The app expects to find `color_journey.wasm` and its loader in `/assets/`. **Note:** The template uses `public` directory for static assets.
-   `-s WASM=1`: Ensures WASM output.
-   `-s MODULARIZE=1`, `-s EXPORT_ES6=1`: Wraps the output in a modern ES6 module.
-   `-s EXPORTED_RUNTIME_METHODS='["cwrap"]'`: Exports the `cwrap` function, which is essential for creating a typed JS wrapper around a C function.
-   `-s EXPORTED_FUNCTIONS='...'`: A list of C functions to expose to the JavaScript environment. `_malloc` and `_free` are needed for memory management.
-   `-O3`: Aggressive optimization level for performance.
## C API Contract
The C code must expose a function with the following signature. This function will receive a configuration object, allocate memory for the output palette, and return a pointer to it.
**`color_journey.c`:**
```c
#include <stdint.h>
#include <stdbool.h>
// Expected input structure (packed for consistency)
typedef struct {
    // ... fields matching ColorJourneyConfig ...
    double lightness;
    double chroma;
    double contrast;
    double vibrancy;
    double warmth;
    double bezier_light[2];
    double bezier_chroma[2];
    uint32_t seed;
    int num_colors;
    int num_anchors;
    int loop_mode;
    int variation_mode;
    bool enable_color_circle;
    double arc_length;
} CJ_Config;
// Output structure
typedef struct {
    oklab ok;
    srgb_u8 rgb;
} CJ_ColorPoint;
/**
 * @brief Generates a discrete color palette.
 * @param config Pointer to the configuration struct.
 * @param anchors Pointer to an array of anchor colors (e.g., packed oklab structs).
 * @return A pointer to an array of CJ_ColorPoint structs. The caller in JS is responsible for freeing this memory.
 */
CJ_ColorPoint* generate_discrete_palette(CJ_Config* config, oklab* anchors);
```
## JavaScript Integration
The `src/lib/color-journey/index.ts` wrapper will be responsible for loading, calling, and managing memory for the WASM module.
**Logic Notes:**
-   **Single-anchor mode**: If `enable_color_circle` is false, the engine first generates colors by varying lightness and chroma before traversing hue. If true, it uses `arc_length` to travel along the hue wheel.
-   **Multi-anchor mode**: A midpoint chroma boost is applied if `vibrancy` is low to prevent muddy mid-tones.
**Example JS Snippet:**
```typescript
// Inside src/lib/color-journey/index.ts after loading the module
const wasmApi = {
  generate: Module.cwrap('generate_discrete_palette', 'number', ['number', 'number']),
  malloc: Module._malloc,
  free: Module._free,
};
// ... inside the generate function ...
// 1. Allocate memory for config and anchors
const configPtr = wasmApi.malloc(configSize);
const anchorsPtr = wasmApi.malloc(anchorsSize);
// 2. Write data to WASM memory using DataView or HEAP TypedArrays
// e.g., Module.HEAPF64.set([config.dynamics.lightness, ...], configPtr / 8);
// Module.HEAPU8.set([config.dynamics.enableColorCircle ? 1 : 0], boolOffset);
// 3. Call C function
const resultPtr = wasmApi.generate(configPtr, anchorsPtr);
// 4. Read data from resultPtr
// new Float64Array(Module.HEAPF64.buffer, resultPtr, numColors * 3) // for OKLab
// new Uint8Array(Module.HEAPU8.buffer, resultPtr + oklabSize, numColors * 3) // for sRGB
// 5. Free all allocated memory
wasmApi.free(configPtr);
wasmApi.free(anchorsPtr);
wasmApi.free(resultPtr);