# ColourJourney Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-09

## Core Architecture Philosophy

ColourJourney is a **C-first, wrapper-friendly** library with maximum portability. The C core is the canonical implementation; all wrappers (Swift, Python, Ruby, etc.) are interfaces to this core.

**Architecture Principles:**
- **C core is canonical**: All performance-critical algorithms and data structures live in C99
- **Wrappers provide ergonomics**: Swift, CocoaPods, and other wrappers expose idiomatic interfaces to the C core
- **Always keep in sync**: Public API changes in the C core must be reflected immediately in all wrappers
- **Performance first, UX second**: C core prioritizes efficiency; wrappers prioritize developer experience

---

## Project Structure

```text
Sources/
├── CColorJourney/       # Canonical C99 core + headers
└── ColorJourney/        # Swift wrapper and configuration

Tests/
├── CColorJourneyTests/  # C core tests
└── ColorJourneyTests/   # Swift tests

Docs/                    # Generated API docs (include in releases)
DevDocs/                 # Developer docs (exclude from release artifacts)
.github/workflows/       # CI/CD automation
Examples/                # C + Swift example programs
```

---

## Active Technologies & Build Commands

| Component | Version | Build Command |
|-----------|---------|---|
| **C Core** | C99 + CMake 3.16+ | `make lib` (static library), `make test-c` (tests), `make verify-examples` (sanity check) |
| **Swift Wrapper** | Swift 5.9 + SPM | `swift build` (debug), `swift test` (tests), `swift build -c release` (release) |
| **CocoaPods** | Ruby 2.6+ + CocoaPods 1.10.0+ | `pod lib lint` (validate), `pod trunk push ColorJourney.podspec` (publish) |
| **Documentation** | Doxygen 1.9.6+ + Swift-DocC | `make docs` (full), `make docs-clean` (remove generated) |

**CI/CD & Tools**: Git/GitHub Actions, Xcode 26+, Make 4.0+, CMake 3.16+, Homebrew

---

## Code Style

| Language | Guidelines |
|----------|---|
| **C99** | [GNU Coding Standards](https://www.gnu.org/prep/standards/), K&R style |
| **Swift** | [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) + [SwiftLint](https://github.com/realm/SwiftLint) |
| **Others** | Follow respective language/framework conventions |

---

## Critical Principles for Agents

### 1. Synchronization Requirement (Non-negotiable)
- C core API changes → must update Swift wrapper immediately
- New C functions → must expose in Swift wrapper
- Breaking changes → increment major version in CHANGELOG.md per semantic versioning
- Failure to sync = broken library contract

### 2. Testing Discipline (Non-negotiable)
- **New features**: Write tests before code (TDD)
- **Bug fixes**: Reproduce first, write failing test, then fix
- **All components**: C core + Swift wrapper + examples must all have tests
- **Coverage**: Unit tests required; integration tests for cross-language calls

### 3. Documentation Standards (Non-negotiable)
- **C core**: Use Doxygen (comment format: `/** ... */`)
- **Swift**: Use DocC (comment format: `/// ... `)
- **Public APIs**: Always document parameters, return values, exceptions, example usage
- **Unified index**: Run `make docs` to verify both generate correctly
- **DRY principle**: No duplication between DevDocs/, Docs/, and code comments

### 4. Release & Versioning (Semantic Versioning)
- **Major**: Breaking API changes in C core or Swift wrapper
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes
- Example: `1.2.3` = major.minor.patch
- Update CHANGELOG.md concisely; update all wrapper versions in sync

### 5. Incremental, Tested Changes (Preferred Workflow)
- Small, focused PRs over large rewrites
- Each commit has a clear purpose
- Tests pass after every semantic unit of change
- Back up configurations before model-driven refactors
- Prefer incremental refactors to complete rewrites

---

## Workflow Expectations

### Code Quality
- Prioritize correctness and maintainability over premature optimization
- Clean variable names, modular functions, clear separation of concerns
- Automated tools enforce standards (SwiftLint for Swift, etc.)
- Code reviews are mandatory; engage collaboratively

### Documentation
- Keep DevDocs organized, precise, concise (no duplication)
- Update README.md and CHANGELOG.md for user-facing changes
- Write commit messages following [Conventional Commits](https://www.conventionalcommits.org/)
- For complex algorithms or decisions, add comments explaining *why*, not just *what*

### Collaboration
- Use feature branches + pull requests for all changes
- Automate repetitive tasks via GitHub Actions
- Check DevDocs and existing docs before asking questions
- Communicate early if blockers arise
- Engage in knowledge-sharing code reviews

### Problem-Solving
- Always reproduce bugs; write tests first
- Prefer established libraries over custom solutions
- Automate code generation (e.g., splitting large files) programmatically
- Ask for clarification rather than assume requirements
- When stuck, check DevDocs/ (especially ARCHITECTURE.md, PRD.md, README_IMPLEMENTATION.md)

## Recent Changes
- 005-c-algo-parity: Added C99 core (Sources/CColorJourney), Swift 5.9 wrapper, C→WASM build via Emscripten emsdk 3.1.67 (pinned) + SwiftPM with `swift-docc-plugin`; Emscripten toolchain; clang/gcc for C harness; Node 20 LTS + Vite 5.x runtime for wasm consumer
