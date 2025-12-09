# Serving Documentation Locally

Swift-DocC generates a **single-page application (SPA)** that requires HTTP server routing. Opening `index.html` directly as a file won't work because:

1. JavaScript modules can't load properly with `file://` protocol
2. Asset paths need proper resolution
3. SPA routing requires HTTP server support

## Quick Start

### Option 1: Use Make (Recommended)

```bash
# Serve unified documentation (all docs)
make serve-docs

# Serve Swift API only
make serve-swift

# Serve C API (Doxygen) only
make serve-c

# Serve entire project
make serve-all
```

Then open your browser to the displayed URL (typically `http://localhost:8000/`).

### Option 2: Manual Python Server

```bash
# From Docs directory (unified hub + all generated docs)
cd Docs && python3 -m http.server 8000

# From Swift-DocC directory only
cd Docs/generated/swift-docc && python3 -m http.server 8000

# From Doxygen directory only
cd Docs/generated/doxygen/html && python3 -m http.server 8000
```

Then open `http://localhost:8000/` in your browser.

### Option 3: Alternative Servers

**Node.js http-server** (if installed):
```bash
npm install -g http-server
cd Docs/generated/swift-docc
http-server -p 8000
```

**Ruby WEBrick**:
```bash
cd Docs/generated/swift-docc
ruby -run -ehttpd . -p 8000
```

**PHP** (if available):
```bash
cd Docs/generated/swift-docc
php -S localhost:8000
```

## Serving from Make

### `make serve` or `make serve-docs`
Serves the entire `Docs/` directory containing:
- Unified index: `http://localhost:8000/index.html`
- Swift API: `http://localhost:8000/generated/swift-docc/`
- C API: `http://localhost:8000/generated/doxygen/html/`

### `make serve-swift`
Serves only Swift-DocC from the correct root directory.
- Access at: `http://localhost:8000/`
- Proper path resolution for all assets

### `make serve-c`
Serves only Doxygen from the correct root directory.
- Access at: `http://localhost:8000/`

### `make serve-all`
Serves entire project from root directory.
- Access unified docs at: `http://localhost:8000/Docs/index.html`
- Access all project files

## Why This Works

When you serve via HTTP:
1. ✅ JavaScript modules load correctly
2. ✅ CSS stylesheets load properly
3. ✅ Asset paths resolve correctly
4. ✅ SPA routing works as expected
5. ✅ Dark mode detection works
6. ✅ Search functionality works

## Browser Access

Once the server is running:

1. **Unified Documentation Hub**
   ```
   http://localhost:8000/index.html
   ```

2. **Swift API Documentation**
   ```
   http://localhost:8000/generated/swift-docc/
   ```

3. **C API Documentation**
   ```
   http://localhost:8000/generated/doxygen/html/
   ```

## Stop the Server

Press `Ctrl+C` in the terminal running the server.

## Troubleshooting

**Port 8000 already in use?**
```bash
# Use a different port
python3 -m http.server 9000

# Then access at http://localhost:9000/
```

**Swift-DocC still shows blank page?**
1. Check browser console (F12) for JavaScript errors
2. Verify files exist: `ls Docs/generated/swift-docc/js/`
3. Try a different browser
4. Clear browser cache and reload

**Need to regenerate documentation?**
```bash
make docs-clean
make docs
make serve-swift
```

## Production Deployment

For production, use the web-ready format:

```bash
make docs-publish
```

Then deploy the contents of `Docs/generated/publish/` to:
- GitHub Pages
- Netlify
- Vercel
- AWS S3
- Custom hosting

See [DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md](../DevDocs/guides/SWIFT_DOCC_PLUGIN_GUIDE.md) for deployment details.
