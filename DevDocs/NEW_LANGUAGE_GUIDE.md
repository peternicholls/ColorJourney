# New Language Binding Integration Guide

## Quick Start

This guide walks you through adding a new language binding to Color Journey while leveraging the existing C core, release infrastructure, and CI/CD pipeline.

**Before starting**: Review [FUTURE_BINDINGS.md](FUTURE_BINDINGS.md) for architectural overview and design principles.

## 5-Step Integration Process

### Step 1: Set Up Project Structure

Create a new directory under `bindings/` for your language:

```bash
mkdir -p bindings/LANGUAGE
cd bindings/LANGUAGE
```

**Required structure** (example for Python):

```
bindings/python/
├── colorjourney/          # Package source
│   ├── __init__.py
│   ├── journey.py         # Main API wrapper
│   ├── config.py          # Configuration classes
│   └── _core.py           # C FFI interface (ctypes or C extension)
├── tests/                 # Comprehensive test suite
│   ├── test_basic.py
│   ├── test_seeding.py    # Determinism tests
│   └── conftest.py
├── examples/              # Integration examples
│   └── example.py
├── setup.py               # Package configuration
├── pyproject.toml         # Modern Python packaging
├── README.md              # Language-specific docs
└── .gitignore             # Language-specific ignores
```

**Minimal structure** (languages with single file):

```
bindings/javascript/
├── src/
│   ├── index.js           # Main entry point
│   ├── wasm-binding.js    # WASM interface
│   └── api.ts             # TypeScript types (if applicable)
├── tests/
│   └── test.js
├── examples/
│   └── example.js
├── package.json
└── README.md
```

### Step 2: Implement FFI to C Core

The C core is the source of truth. Your binding must interface with it.

#### Option A: Direct FFI (Simplest)

```python
# bindings/python/colorjourney/_core.py (ctypes example)
import ctypes
from pathlib import Path

# Load compiled C library
lib_path = Path(__file__).parent / "_colorjourney.so"  # or .dylib, .dll
_lib = ctypes.CDLL(str(lib_path))

# Define C structures and functions
class ColorJourneyConfig(ctypes.Structure):
    pass

# Wrap C functions
_lib.ColorJourney_create.argtypes = [ctypes.POINTER(ColorJourneyConfig)]
_lib.ColorJourney_create.restype = ctypes.c_void_p
```

**Pros**: Direct, fast, no build complexity  
**Cons**: Requires pre-compiled C libraries in package; platform-specific binaries

**Distribution**: Package pre-compiled `.so`/`.dylib`/`.dll` in wheel or distribute at runtime.

#### Option B: WASM (For Web/Node.js)

```javascript
// bindings/javascript/src/wasm-binding.js
import { instantiateAsync } from './wasm-module';

export async function createJourney(config) {
  const wasmModule = await instantiateAsync();
  return new Journey(wasmModule, config);
}
```

**Build Process**:
1. Compile C core to WASM with Emscripten or wasm-bindgen
2. Generate JavaScript bindings
3. Package `.wasm` + `.js` together

**Pros**: Universal (web, Node.js); no platform-specific binaries  
**Cons**: Additional build tool (Emscripten); separate toolchain

#### Option C: Language-Specific C Extension

```c
// bindings/python/src/_colorjourney.c (Python C extension)
#include <Python.h>
#include "ColorJourney.h"

static PyObject* create_journey(PyObject* self, PyObject* args) {
  // Call C functions directly
  ColorJourneyConfig config = {...};
  ColorJourney_t* journey = ColorJourney_create(&config);
  // Wrap result in Python object
}
```

**Pros**: Optimal performance, tight integration  
**Cons**: Language-specific build complexity; requires C extension knowledge

---

### Step 3: Implement Language-Idiomatic API

Wrap the C FFI with language-native patterns.

#### Python Example

```python
# bindings/python/colorjourney/__init__.py
from dataclasses import dataclass
from typing import List, Tuple
from ._core import _lib, ColorJourneyConfig as _CConfig

@dataclass
class ColorJourneyConfig:
    """Configuration for a color journey."""
    anchors: List[Tuple[float, float, float]]  # RGB tuples
    style: str = "balanced"
    
    def to_c_config(self):
        """Convert to C structure."""
        c_config = _CConfig()
        c_config.num_anchors = len(self.anchors)
        # ... populate C structure
        return c_config

class ColorJourney:
    """Main API entry point."""
    
    def __init__(self, config: ColorJourneyConfig):
        self._c_config = config.to_c_config()
        self._handle = _lib.ColorJourney_create(self._c_config)
    
    def sample(self, t: float) -> Tuple[float, float, float]:
        """Sample color at position t ∈ [0, 1]."""
        r = ctypes.c_float()
        g = ctypes.c_float()
        b = ctypes.c_float()
        _lib.ColorJourney_sample(self._handle, t, 
                                 ctypes.byref(r), 
                                 ctypes.byref(g), 
                                 ctypes.byref(b))
        return (r.value, g.value, b.value)
    
    def discrete(self, count: int) -> List[Tuple[float, float, float]]:
        """Generate discrete palette."""
        palette = []
        for i in range(count):
            t = i / (count - 1) if count > 1 else 0
            palette.append(self.sample(t))
        return palette
    
    def __del__(self):
        """Cleanup C resources."""
        _lib.ColorJourney_destroy(self._handle)
```

#### JavaScript Example

```typescript
// bindings/javascript/src/api.ts
export interface RGBColor {
  r: number;
  g: number;
  b: number;
}

export interface ColorJourneyConfig {
  anchors: RGBColor[];
  style?: 'balanced' | 'pastelDrift' | 'vividLoop';
}

export class ColorJourney {
  private _handle: number;
  private _module: WasmModule;
  
  constructor(config: ColorJourneyConfig, wasmModule: WasmModule) {
    this._module = wasmModule;
    // Convert config to C structure
    this._handle = this._module.createJourney(config);
  }
  
  sample(t: number): RGBColor {
    const [r, g, b] = this._module.sampleJourney(this._handle, t);
    return { r, g, b };
  }
  
  discrete(count: number): RGBColor[] {
    const colors: RGBColor[] = [];
    for (let i = 0; i < count; i++) {
      const t = count > 1 ? i / (count - 1) : 0;
      colors.push(this.sample(t));
    }
    return colors;
  }
}
```

**Key Principles**:
- Keep API surface consistent across languages
- Use language idioms (dataclasses in Python, classes in JS, traits in Rust)
- Handle memory management (destruction, garbage collection)
- Type safety where language supports it (TypeScript, mypy)

---

### Step 4: Write Comprehensive Tests

Your binding must test both functionality and compatibility with the C core.

#### Test Categories

**1. Basic Functionality Tests**
```python
# bindings/python/tests/test_basic.py
def test_create_journey():
    config = ColorJourneyConfig(
        anchors=[(0.5, 0.5, 0.5)],
        style="balanced"
    )
    journey = ColorJourney(config)
    assert journey is not None

def test_sample():
    journey = ColorJourney(...)
    color = journey.sample(0.5)
    assert isinstance(color, tuple)
    assert len(color) == 3
    assert all(0 <= c <= 1 for c in color)

def test_discrete():
    journey = ColorJourney(...)
    palette = journey.discrete(10)
    assert len(palette) == 10
```

**2. Determinism Tests** (Critical!)
```python
def test_seeded_variation_deterministic():
    """Verify that seeded variation produces identical results."""
    config1 = ColorJourneyConfig(
        anchors=[(0.5, 0.5, 0.5)],
        variation={"seed": 42}
    )
    config2 = ColorJourneyConfig(
        anchors=[(0.5, 0.5, 0.5)],
        variation={"seed": 42}
    )
    
    journey1 = ColorJourney(config1)
    journey2 = ColorJourney(config2)
    
    # Generate palettes with same seed
    palette1 = journey1.discrete(10)
    palette2 = journey2.discrete(10)
    
    # Verify identical (within floating point precision)
    assert palette1 == palette2
```

**3. Integration Tests**
```python
def test_c_core_version_compatibility():
    """Verify binding works with expected C core version."""
    core_version = _lib.ColorJourney_version()
    assert core_version >= (1, 0, 0)

def test_reproducibility_across_platforms():
    """Test that same config produces same palette on different platforms."""
    # This test should pass on macOS, Linux, Windows
    # Use frozen test data
    expected_palette = [(0.4, 0.5, 0.6), (0.5, 0.6, 0.7), ...]
    actual_palette = ColorJourney(...).discrete(3)
    assert actual_palette == pytest.approx(expected_palette)
```

**4. Performance Tests**
```python
def test_performance_discrete_generation():
    """Verify discrete palette generation performance."""
    journey = ColorJourney(...)
    
    import time
    start = time.time()
    journey.discrete(1000)
    elapsed = time.time() - start
    
    # Should complete in < 10ms
    assert elapsed < 0.01
```

**Test Execution**:
```bash
# Python
python -m pytest tests/ -v

# JavaScript
npm test

# Rust
cargo test
```

---

### Step 5: Add CI/CD Integration

#### Update .github/workflows/core-ci.yml

```yaml
# Add new job for your language binding

jobs:
  # ... existing swift/c jobs ...
  
  python-build-and-test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [macos-latest, ubuntu-latest, windows-latest]
        python-version: ['3.8', '3.9', '3.10', '3.11', '3.12']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Build C core
        run: |
          cd Sources/CColorJourney
          make lib
      
      - name: Install Python dependencies
        run: |
          cd bindings/python
          pip install -e ".[dev]"
      
      - name: Run tests
        run: |
          cd bindings/python
          pytest tests/ -v
```

#### Update .github/workflows/release-artifacts.yml

```yaml
# Add artifact building step for your language

jobs:
  # ... existing swift/c artifact jobs ...
  
  build-python-artifacts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Build wheels
        run: |
          cd bindings/python
          pip install build
          python -m build
      
      - name: Upload to PyPI
        env:
          TWINE_REPOSITORY: pypi
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_TOKEN }}
        run: |
          cd bindings/python
          twine upload dist/*
```

---

## Distribution & Publishing

### Python (PyPI)

```bash
# 1. Build distribution
cd bindings/python
python -m build

# 2. Publish
twine upload dist/

# 3. Verify
pip install colorjourney==1.0.0
python -c "from colorjourney import ColorJourney; print('OK')"
```

### JavaScript (npm)

```bash
# 1. Build
cd bindings/javascript
npm run build

# 2. Publish
npm publish

# 3. Verify
npm install @colorjourney/js
node -e "const {ColorJourney} = require('@colorjourney/js'); console.log('OK')"
```

### Rust (crates.io)

```bash
# 1. Build
cd bindings/rust
cargo build --release

# 2. Publish
cargo publish

# 3. Verify
cargo add colorjourney
```

---

## Documentation Requirements

Every binding must document:

1. **Installation**
   ```
   # Python
   pip install colorjourney
   
   # JavaScript
   npm install @colorjourney/js
   ```

2. **Quick Start** (minimal working example)
   ```python
   from colorjourney import ColorJourney, ColorJourneyConfig
   
   config = ColorJourneyConfig(
       anchors=[(0.5, 0.5, 0.5)],
       style="balanced"
   )
   journey = ColorJourney(config)
   palette = journey.discrete(10)
   print(palette)
   ```

3. **API Reference** (all public methods)
   - Constructor
   - Configuration options
   - Key methods (`sample()`, `discrete()`)
   - Error handling

4. **Examples**
   - Basic usage
   - All configuration options
   - Real-world use case (e.g., matplotlib integration)

5. **Compatibility Matrix**
   - Language version support
   - Platform support
   - C core version dependency

---

## Checklist: Before Release

- [ ] Code is in `bindings/LANGUAGE/`
- [ ] FFI or wrapper is complete and tested
- [ ] All tests pass on all target platforms
- [ ] Documentation complete (README, API, examples)
- [ ] CI job exists and passes on main branch
- [ ] Version dependency on C core documented in [VERSION_MAPPING.md](../VERSION_MAPPING.md)
- [ ] Package manager account set up (PyPI, npm, crates.io, etc.)
- [ ] Release process tested end-to-end (build + publish)
- [ ] Example code verified in [Examples/](../../Examples/)
- [ ] Performance benchmarks documented

---

## Troubleshooting

### "C library not found during installation"
**Solution**: Ensure C core is built before Python/JS/Rust build. Update CI to run CMake build first.

### "Determinism tests fail across platforms"
**Solution**: Verify floating-point handling. Use `pytest.approx()` for tolerance. Document platform-specific precision limits.

### "Performance is slow compared to C"
**Solution**: Expected for interpreted languages. Profile and optimize hot paths. Consider C extension for critical paths. Document performance characteristics.

### "WASM module fails to initialize"
**Solution**: Verify Emscripten toolchain. Check memory initialization. Ensure WASM memory is properly sized for C data structures.

---

## Questions & Support

**Q: Can I skip tests?**  
A: No. Tests are required before any release. They ensure compatibility with C core and prevent regressions.

**Q: What if my language isn't listed?**  
A: Follow this guide with your language's FFI mechanism. Contact maintainers if you want to add it to the planned roadmap.

**Q: How do I handle breaking changes in C core?**  
A: See [FUTURE_BINDINGS.md](FUTURE_BINDINGS.md) for version mapping strategy. Update your binding's minimum C core version.

---

**Last Updated**: 2025-12-09  
**Related**: [FUTURE_BINDINGS.md](FUTURE_BINDINGS.md), [VERSION_MAPPING.md](VERSION_MAPPING.md), [RELEASE_PLAYBOOK.md](RELEASE_PLAYBOOK.md)
