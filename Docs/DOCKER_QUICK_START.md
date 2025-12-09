# Quick Start - Docker Documentation Server

## Requirements

- Docker Desktop: https://www.docker.com/products/docker-desktop

## One Command to Rule Them All

```bash
make docs && make serve-docs
```

This will:
1. Generate all documentation (Swift-DocC + Doxygen)
2. Start Docker container with nginx
3. Serve unified documentation at http://localhost:8000/

## What You Get

| URL | Content |
|-----|---------|
| http://localhost:8000/index.html | 📚 Unified hub with links to all APIs |
| http://localhost:8000/generated/swift-docc/ | 📱 Interactive Swift API documentation |
| http://localhost:8000/generated/doxygen/html/ | 🔧 C API documentation |

## Stop the Server

```bash
make serve-stop
```

## Alternatives (No Docker Required)

### View Swift API Only
```bash
make serve-swift
# Visit: http://localhost:8000/
```

### View C API Only
```bash
make serve-c
# Visit: http://localhost:8000/
```

## Architecture

The Docker setup uses **nginx** to:
- ✅ Serve the unified documentation hub
- ✅ Automatically rewrite Swift-DocC asset paths (`/js/` → `/generated/swift-docc/js/`)
- ✅ No 404 errors on JavaScript, CSS, or image assets
- ✅ Handle SPA (Single-Page Application) routing

## Files

- `Dockerfile` - nginx image configuration
- `docker-compose.yml` - Container orchestration
- `.dockerignore` - Build exclusions

## Development Workflow

```bash
# Generate documentation
make docs

# Start server
make serve-docs

# Make code changes...
# (Server stays running, refresh browser to see new content after regenerating docs)

# Regenerate docs
make docs

# Stop server when done
make serve-stop
```

## Troubleshooting

**Q: "Docker not installed"**
A: Install Docker Desktop from https://www.docker.com/products/docker-desktop

**Q: "Port 8000 already in use"**
A: Edit `docker-compose.yml` change `8000:80` to `8001:80` (or any other port)

**Q: "Container won't start"**
A: Run `docker-compose logs` to see error messages

**Q: "Assets still showing 404"**
A: Try: `docker-compose down && docker-compose up --build`

## See Also

- [SWIFT_DOCC_404_SOLUTION.md](SWIFT_DOCC_404_SOLUTION.md) - Detailed explanation and alternatives
- [../DevDocs/guides/](../DevDocs/guides/) - Developer documentation
