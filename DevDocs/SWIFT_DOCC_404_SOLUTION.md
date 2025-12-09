# Swift-DocC 404 Error - Root Cause & Solutions

## Problem

When serving Swift-DocC documentation via HTTP from `/Docs/`, Safari console shows:
```
Failed to load resource: the server responded with a status of 404 (File not found)
```

The page loads but remains blank/white because JavaScript assets fail to load.

## Root Cause

Swift-DocC is a **Single-Page Application (SPA)** generated with hardcoded `baseUrl = "/"` in the index.html:

```html
<script>var baseUrl = "/"</script>
<script defer="defer" src="/js/chunk-vendors.bdb7cbba.js"></script>
```

When served from a subdirectory like `/generated/swift-docc/`, this causes path mismatches:

| Request | Looking For | Actually At | Result |
|---------|------------|-------------|--------|
| `/js/chunk-vendors.bdb7cbba.js` | `/js/...` | `/generated/swift-docc/js/...` | ❌ 404 |
| `/css/index.d0b63544.css` | `/css/...` | `/generated/swift-docc/css/...` | ❌ 404 |

## Solutions

### Solution 1: Docker + Nginx (RECOMMENDED ✅ - Unified)

The best solution - serves unified documentation with automatic path rewriting via nginx.

**Prerequisites:**
- Docker Desktop installed (https://www.docker.com/products/docker-desktop)

**Start the server:**
```bash
make serve-docs
```

**Open in browser:**
- Unified Hub: `http://localhost:8000/index.html`
- Swift API: `http://localhost:8000/generated/swift-docc/`
- C API: `http://localhost:8000/generated/doxygen/html/`

**Stop the server:**
```bash
make serve-stop
```

**Why it works:**
- ✅ Serves unified documentation with all APIs visible
- ✅ Nginx automatically rewrites `/js/`, `/css/`, `/img/` → `/generated/swift-docc/...`
- ✅ No 404 errors on assets
- ✅ Works perfectly in all browsers
- ✅ Production-ready setup

### Solution 2: Swift-DocC from Its Own Root

Simplest option if you want to view Swift documentation independently.

```bash
make serve-swift
```

**Open in browser:**
- `http://localhost:8000/`

**Why it works:**
- Serves from `/Docs/generated/swift-docc/` as the root
- `baseUrl = "/"` is now correct
- All assets load from correct paths
- Perfect for isolated testing

### Solution 3: Separate Servers

For viewing both documentation types side-by-side:

**Terminal 1 - Swift API:**
```bash
make serve-swift
# Visit: http://localhost:8000/
```

**Terminal 2 - C API:**
```bash
make serve-c
# Visit: http://localhost:8001/ (or change port)
```

## Available Make Targets

| Command | Purpose | Method |
|---------|---------|--------|
| `make serve` | **Unified docs (Docker)** | Docker + nginx |
| `make serve-docs` | **Unified docs (Docker)** | Docker + nginx |
| `make serve-stop` | Stop Docker containers | Docker |
| `make serve-swift` | Swift API only | Python built-in server |
| `make serve-c` | C API (Doxygen) | Python built-in server |
| `make serve-all` | Entire project | Python built-in server |

## Complete Workflow

```bash
# 1. Generate documentation (one-time)
make docs

# 2. Start Docker + unified server
make serve-docs

# 3. Open browser to unified hub
open http://localhost:8000/index.html

# 4. Browse:
#    - Swift API: http://localhost:8000/generated/swift-docc/
#    - C API: http://localhost:8000/generated/doxygen/html/
#    - All with search, dark mode, cross-references

# 5. Stop when done
make serve-stop
```

## Installation Requirements

**For Docker solution (recommended):**
- Docker Desktop: https://www.docker.com/products/docker-desktop
- Includes Docker and docker-compose

**For Python-only solutions:**
- Python 3.6+ (usually pre-installed on macOS)
- No additional dependencies

## Browser Compatibility

All solutions tested and working on:
- ✅ Safari (macOS/iOS)
- ✅ Chrome
- ✅ Firefox
- ✅ Edge

## Files in This Solution

**Docker configuration:**
- `Dockerfile` - nginx image with SPA routing rules
- `docker-compose.yml` - Docker Compose configuration
- `.dockerignore` - Docker build exclusions

**Python servers (for individual components):**
- Built-in to Python, no separate script needed
- `make serve-swift`, `make serve-c`, `make serve-all` use Python's built-in server

## FAQs

**Q: Do I need Docker to serve documentation?**
A: No, use `make serve-swift` for just the Swift API (Python built-in server).

**Q: Do I need to regenerate docs if I change code?**
A: Yes, run `make docs` again, then `make serve-docs` (Docker restarts automatically).

**Q: Can I view Doxygen and Swift-DocC together?**
A: Yes, use `make serve-docs` (Docker handles routing).

**Q: What if port 8000 is in use?**
A: Edit `docker-compose.yml` to change the port mapping, or use `make serve-swift`/`make serve-c`.

**Q: Can this be deployed to production?**
A: Yes, the Docker setup is production-ready. Use `make docs-publish` for GitHub Pages.

**Q: Why Docker instead of Python server?**
A: nginx handles SPA routing more robustly than Python rewrites. Docker is cleaner and more maintainable.

## Summary

✅ **Docker + nginx for unified, production-ready serving**
✅ **Automatic asset path rewriting (no 404 errors)**
✅ **Python alternatives available for specific components**
✅ **All documentation fully functional and browsable**
✅ **Easy one-command startup/shutdown**

