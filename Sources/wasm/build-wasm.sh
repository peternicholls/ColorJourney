#!/bin/bash
# build-wasm.sh
# Ensures the Emscripten SDK is active in your environment before running.
# This script compiles the C core into a JavaScript loader and a .wasm file.
# Pre-build check for Emscripten environment
# Check if emcc command is available (global installation or emsdk)
if ! command -v emcc &> /dev/null
then
  if [[ -z "$EMSDK" ]]; then
    echo "❌ emcc command not found and EMSDK not set. Please install Emscripten globally or activate the SDK."
    echo "See: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
  fi
fi
echo "Building Color Journey WASM module..."
# Create output directory if it doesn't exist
mkdir -p public/assets
# Compile C sources to a JS loader + WASM file
emcc src/wasm/oklab.c src/wasm/color_journey.c \
  -o public/assets/color_journey.js \
  -s WASM=1 \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORTED_FUNCTIONS='["_generate_discrete_palette", "_wasm_malloc", "_wasm_free"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap", "HEAPU8", "HEAPU32", "wasmMemory"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3
# Clear Vite's cache to prevent dependency hashing errors on asset changes
rm -rf node_modules/.vite && echo "✅ Vite cache cleared to prevent update errors."
# Check if the build was successful and files exist
# Use stat command compatible with macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  JS_SIZE=$(stat -f%z public/assets/color_journey.js 2>/dev/null || echo 0)
  WASM_SIZE=$(stat -f%z public/assets/color_journey.wasm 2>/dev/null || echo 0)
else
  JS_SIZE=$(stat -c%s public/assets/color_journey.js 2>/dev/null || echo 0)
  WASM_SIZE=$(stat -c%s public/assets/color_journey.wasm 2>/dev/null || echo 0)
fi

if [[ ! -f public/assets/color_journey.js ]] || [[ ! -f public/assets/color_journey.wasm ]]; then
  echo "❌ Build failed: Output files not created."
  echo "   Ensure Emscripten SDK is active: run 'source ./emsdk_env.sh' in your emsdk directory."
  exit 1
fi

if [[ $JS_SIZE -lt 1024 ]] || [[ $WASM_SIZE -lt 1024 ]]; then
  echo "❌ Build incomplete: Files are suspiciously small."
  echo "   - JS size: $JS_SIZE bytes (expected >1KB)"
  echo "   - WASM size: $WASM_SIZE bytes (expected >1KB)"
  exit 1
fi
if [[ $JS_SIZE -gt 0 && $WASM_SIZE -gt 0 ]]; then
  echo "Build verified: No Vite dependency conflicts."
else
  echo "⚠️ Potential Vite hash error - retry build."
fi
echo "✅ WASM built successfully:"
echo "   - public/assets/color_journey.js ($(du -h public/assets/color_journey.js | cut -f1))"
echo "   - public/assets/color_journey.wasm ($(du -h public/assets/color_journey.wasm | cut -f1))"