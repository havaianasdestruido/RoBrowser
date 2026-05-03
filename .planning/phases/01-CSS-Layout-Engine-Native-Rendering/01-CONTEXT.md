# Phase 1: CSS Layout Engine & Native Rendering - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

**Phase 1 Goal:** Users see websites with correct CSS layout (Flexbox, Grid, Positioning, Box Model) rendered via Roblox native GUI objects using rbx-css compiled StyleSheets.

**Scope:** This phase delivers CSS-01, CSS-02, CSS-03, CSS-04, REN-02, REN-03 (6 requirements).

**Out of scope:** JavaScript execution, DOM APIs, Web APIs — these are separate phases.
</domain>

<decisions>
## Implementation Decisions

### CSS Engine Strategy
- **D-01:** Use **rbx-css** to compile standard CSS to Roblox `StyleSheet` instances — replacing the current custom CSSParser entirely. This avoids months of wasted work building a custom CSS engine.
- **D-02:** Leverage native Roblox `UIListLayout` for Flexbox layouts and `UIGridLayout` for Grid layouts — using C++ native layouts for performance instead of per-frame Luau positioning.
- **D-03:** CSS Flexbox properties to support first: `display: flex`, `justify-content`, `align-items`, `flex-direction`, `flex-wrap`.

### Rendering Architecture
- **D-04:** Use Roblox native GUI objects for rendering: `Frame` (div), `TextLabel` (p, h1-h6, span), `TextButton` (button), `ImageLabel` (img).
- **D-05:** HTML → Roblox element mapping follows community standards: div→Frame, p→TextLabel, button→TextButton (from rbx-css and rbx-tsx patterns).

### Roblox Platform Constraints
- **D-06:** Design for instance limits from day one — use `UIListLayout`/`UIGridLayout` to reduce per-element Lua positioning overhead. Practical limit: ~500-1000 GUI instances per page.
- **D-07:** Implement chunked rendering for large pages — use `task.defer()` to avoid Roblox's 10-second script timeout. Target: ~50 DOM nodes per frame.
- **D-08:** Handle HTML pages >200K chars via chunking strategy — Roblox `StringValue` caps at 200,000 characters; large pages must be split.

### Module Architecture
- **D-09:** Phase 1 code should be structured as a separate reusable Luau module (matching project's separate modules architecture decision from PROJECT.md).
- **D-10:** CSS engine module should output to Roblox `StyleSheet` instances that can be applied to ScreenGui/Frame containers.

### the agent's Discretion
- **D-11:** Exact mapping of CSS properties to Roblox `StyleSheet` properties — agent should follow rbx-css conventions.
- **D-12:** Error handling for malformed CSS — agent should implement graceful fallbacks.
- **D-13:** Whether to implement CSS cascade/ Specificity in Phase 1 or defer to later — agent should assess feasibility within Roblox constraints.

### Folded Todos
None — no todos were folded into Phase 1 scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CSS & Layout
- `.planning/research/STACK.md` § CSS Styling — rbx-css recommendation with rationale
- `.planning/research/FEATURES.md` § CSS Layout — Table stakes features (Flexbox 99%+, Grid 98%+)
- `.planning/research/ARCHITECTURE.md` § Component Boundaries — HTML→DOM→CSSOM→Layout→Render pipeline
- `.planning/research/PITFALLS.md` § Pitfall 4 — Custom CSS engines are #1 time sink (use rbx-css)
- `.planning/codebase/CONCERNS.md` — Existing codebase concerns about CSS engine

### Roblox Platform
- `.planning/research/STACK.md` § Roblox Platform Constraints — StringValue 200K limit, instance limits, script timeout
- `.planning/research/PITFALLS.md` § Pitfall 1-3 — String truncation, instance explosion, blocking main thread
- `stylua.toml` — Luau formatting config (must follow project conventions)
- `selene.toml` — Luau linting config

### Project Context
- `.planning/PROJECT.md` § What This Is — robrowser is a Roblox game rendering websites
- `.planning/PROJECT.md` § Core Value — Site rendering parity (CSS layout is foundation)
- `.planning/PROJECT.md` § Decisions — Separate modules architecture, CSS-first order
- `.planning/ROADMAP.md` § Phase 1 Details — Goal, requirements, success criteria
- `.planning/REQUIREMENTS.md` § CSS Layout — CSS-01 through CSS-04 requirements
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Existing HTMLParser module** (`src/shared/` area) — can parse basic HTML, reuse for this phase
- **Existing CSSParser module** — to be replaced by rbx-css, but may inform migration strategy
- **BrowserEngine module** — existing rendering logic that Phase 1 will refactor to use rbx-css

### Established Patterns
- **Module pattern:** Return table with functions (Roblox module script pattern) — all new modules must follow
- **Naming:** PascalCase for modules/classes, camelCase for variables/functions (from PROJECT.md)
- **Formatting:** StyLua enforced (stylua.toml), Selene linting (selene.toml)

### Integration Points
- **Rojo build/serve workflow:** Phase 1 output must sync via Rojo to Roblox Studio
- **rbx-css integration:** New dependency — will need to be added to project workflow
- **Rendering pipeline:** Phase 1 CSS engine feeds into existing BrowserEngine rendering flow
</code_context>

<specifics>
## Specific Ideas

- User wants "site rendering parity" — CSS layout correctness is the most visible indicator of progress
- rbx-css was specifically mentioned as the recommended approach (from research STACK.md)
- Native `UIListLayout`/`UIGridLayout` preferred over custom Luau positioning for performance
- Performance matters: 60fps interactions + fast page loads (from PROJECT.md Core Value)
</specifics>

<deferred>
## Deferred Ideas

- **JavaScript Engine (ES6+):** Out of scope for Phase 1 — Phase 6 will handle this
- **DOM APIs (querySelector, addEventListener):** Out of scope — Phases 2-3 will handle these
- **Web APIs (Fetch, localStorage, WebSocket):** Out of scope — Phases 4-5 will handle these
- **CSS animations/transitions:** Deferred to v2 (from REQUIREMENTS.md)
- **CSS custom properties (variables):** Deferred to v2
- **Advanced CSS selectors (:hover, :nth-child):** Deferred to v2

### Reviewed Todos (not folded)
None — no todos were reviewed but not folded in this phase.
</deferred>

---
*Phase: 01-CSS-Layout-Engine-Native-Rendering*
*Context gathered: 2026-05-03*
