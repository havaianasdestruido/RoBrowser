# Project Research Summary

**Project:** robrowser
**Domain:** Roblox browser engine (renders websites inside Roblox using Luau)
**Researched:** 2026-05-03
**Confidence:** HIGH (verified against official Roblox docs, project codebase, and active community tools)

## Executive Summary

robrowser is a browser engine built entirely in Luau that renders real websites inside Roblox games. Unlike remote rendering approaches (headless Chrome + proxy), robrowser parses HTML, applies CSS, and creates native Roblox GUI objects (Frame, TextLabel, TextButton, etc.) directly in-game. Experts building this type of project follow the standard browser pipeline—HTML parsing → DOM tree → CSS styling → layout calculation → rendering—adapted for Roblox's `UIListLayout`/`UIGridLayout` native layouts and `StyleSheet` objects.

The recommended approach leverages **rbx-css** to compile standard CSS (with Flexbox/Grid support) into Roblox native `StyleSheet` instances, replacing the current custom CSS parser that lacks modern layout support. For JavaScript execution, a phased approach is critical: start with DOM API shims (querySelector, addEventListener, fetch), then build an ES5 subset interpreter in Luau, deferring ES6+ features to later phases. Attempting to run V8/SpiderMonkey or transpile C# to Luau are dead ends—Roblox's sandbox prevents native code execution, and the only viable path is a Luau-based interpreter.

The key risks are platform constraints: `StringValue` objects cap at 200,000 characters (truncates large HTML pages), Roblox instance counts degrade performance beyond ~1000-2000 GUI objects per page, and Luau scripts must yield regularly to avoid the ~10-second timeout. Mitigation strategies include HTML chunking at the network layer, virtual scrolling with instance pooling for large DOM trees, and chunked rendering using `task.defer()` coroutines. The architecture separates shared parsers (pure Luau, no instances) from client-side rendering, with a server-side HTTP proxy since Roblox clients cannot make direct network requests.

## Key Findings

### Recommended Stack

Research confidence: **HIGH** for CSS/rendering stack, **MEDIUM** for JS engine (needs deeper research).

**Core technologies:**
- **Luau** (Roblox runtime 0.714+): The only scripting language allowed in Roblox. All game logic, parsers, renderers, and the JS engine must be written in Luau.
- **rbx-css** (CSS → Roblox StyleSheet compiler): Write standard CSS with Flexbox/Grid support; auto-compiles to native `StyleSheet` instances with `UIListLayout`, `UIGridLayout`, `UICorner`, `UIStroke`, and `UIPadding` pseudo-instances. Replaces custom CSSParser.
- **Rojo 7.7.0-rc.1**: Industry-standard sync tool for Roblox pro development. Enables live sync between file system and Roblox Studio.
- **StyLua 0.20.0 + Selene 0.26.1**: Official Roblox formatting and linting standards. Managed via Aftman 0.6.x toolchain manager.

**Critical stack decisions:**
- Use rbx-css from day one—building custom CSS Flexbox/Grid is months of work that rbx-css already solves natively
- JS engine: DOM API shims → ES5 interpreter → ES6+ features (phased approach over 3+ phases)
- Keep custom HTMLParser (improve incrementally)—no mature HTML5 Luau parser exists in the community

### Expected Features

Research confidence: **HIGH** (based on MDN, Can I Use, Web.dev Baseline, Roblox Creator Hub documentation).

**Must have (table stakes) — v1:**
- CSS Flexbox Layout (99%+ sites use it for component layouts)
- CSS Box Model + Positioning (foundation for all layouts)
- ES6+ Core: arrow functions, Promises, async/await, let/const
- DOM Selection APIs: querySelector, querySelectorAll, getElementById
- DOM Manipulation: createElement, appendChild, removeChild
- Fetch API (with XMLHttpRequest fallback)
- Basic CSS: typography, colors, backgrounds
- localStorage (5-10MB per domain, synchronous API)
- CSS Selectors Level 3: pseudo-classes, attribute selectors
- CSS Overflow & Scroll (maintain 60fps scrolling)

**Should have (differentiators) — v1/v2:**
- Fast Page Load Times (<2.5s LCP via chunked rendering, instance pooling)
- Smooth 60fps Interactions (native `UIListLayout`/`UIGridLayout`, no per-frame Lua calculations)
- Error Handling & Debug UI (users know *why* a site failed)
- URL Bar & Navigation (back/forward, URL entry)
- Form Support (login, search, contact forms)

**Defer (v2+):**
- CSS Grid Layout (complex, lower usage than Flexbox for components)
- WebSocket (requires proxy server, more complex)
- Multi-Tab Browsing, Web Workers, Service Workers/PWA
- WebGL/WebGPU, Video/Audio Playback, WebRTC, WebXR
- iframe/Embedded Content, Complex CSS Animations/Transitions

### Architecture Approach

Research confidence: **HIGH** (verified against existing project code, Roblox docs, and real-world implementations).

The architecture follows the standard browser pipeline adapted for Roblox:
1. **HTML Parser** (shared): HTML string → DOM tree (ElementNode/TextNode)
2. **CSS Parser** (shared): Extract `<style>`/inline CSS → StyleMap (replaced by rbx-css StyleSheet in v1)
3. **Style Match**: CSSParser.matchElement(element, styleMap) → computed styles per element
4. **Layout Engine** (client): Computed styles → Position + Size using Roblox `UDim2` properties
5. **BrowserEngine** (client): DOM + Layout → Roblox GUI instances (Frame, TextLabel, TextButton, etc.)
6. **JS Engine** (shared, future): Execute JavaScript in Luau with DOM API shims

**Major components:**
1. **Client Entry** (`src/client/init.client.luau`) — URL input, navigation, UI setup
2. **Server Proxy** (`src/server/init.server.luau`) — HTTP requests via HttpService (client cannot make direct HTTP)
3. **Layout Engine** (`src/client/modules/LayoutEngine.luau`) — Box Model + Flexbox/Grid calculations
4. **BrowserEngine** (`src/client/modules/BrowserEngine.luau`) — DOM → Roblox GUI objects
5. **JS Engine** (`src/shared/js/JSEngine.luau`, future) — Execute JS in Luau, DOM APIs

**Build order:** CSS Layout (Phase 1) → DOM APIs (Phase 2) → Network & Web APIs (Phase 3) → JS Engine (Phase 4) → Performance Optimization (Phase 5)

### Critical Pitfalls

Research confidence: **HIGH** (verified against project codebase, Roblox platform docs, and community patterns).

1. **Exceeding StringValue 200,000 Character Limit** — HTML pages commonly exceed this cap, causing silent truncation. **Prevention:** Check HTML length before storing, use chunking across multiple StringValues or `Buffer` (Luau 0.660+), or stream from server in chunks. **Address in:** DOM-03 (Network request APIs).

2. **Instance Explosion (1 Roblox Instance Per DOM Node)** — Complex pages with 1000+ DOM nodes = 1000+ GUI instances, causing frame rate drops to 10-20fps. **Prevention:** Virtual scrolling (viewport + buffer), instance pooling (reuse across page navigations), native layouts (`UIListLayout`/`UIGridLayout`), simplify DOM (skip invisible elements). **Address in:** PERF-01, PERF-02 (design for this from Phase 1).

3. **Blocking Main Thread (Render Entire Page in One Frame)** — Synchronous rendering of 500+ DOM nodes exceeds 16ms frame budget and risks 10-second script timeout. **Prevention:** Chunked rendering with `task.defer()` or coroutines (yield every 50 nodes), render above-fold first, progress callbacks. **Address in:** PERF-01.

4. **Building Custom CSS Engine Instead of Using rbx-css** — CSS Flexbox/Grid/specificity is months of work that rbx-css already solves using native `StyleSheet` + C++ layouts. **Prevention:** Use rbx-css from day one; only build custom CSS for rare unsupported properties. **Address in:** CSS-01 to CSS-04.

5. **Trying to Run Full V8/SpiderMonkey or Native JS Engines** — Impossible due to Roblox sandbox (no native code execution, no file system access for binaries). **Prevention:** Accept constraint—JS must run in Luau (interpreted or transpiled). Use phased approach: DOM shims → ES5 interpreter → ES6+ features. **Address in:** JS-01.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: CSS Layout Engine (CSS-01 to CSS-04)
**Rationale:** Visual layout is most visible to users; fixes deliver immediate value. CSS Flexbox/Grid requires LayoutEngine module that benefits all subsequent phases. rbx-css integration is the highest ROI change.

**Delivers:** LayoutEngine module with Flexbox (`UIListLayout`), Grid (`UIGridLayout`), positioning system (z-index, absolute/relative), and box model (margin, padding, overflow). Replace custom CSSParser with rbx-css StyleSheet compilation.

**Addresses:** CSS Flexbox, CSS Grid, CSS Box Model, CSS Positioning, Basic CSS Properties, CSS Variables, CSS Selectors Level 3 (table stakes from FEATURES.md)

**Avoids:** Pitfall 4 (building custom CSS engine), Pitfall 2 (instance explosion via native layouts), Pitfall 12 (CSS specificity—rbx-css handles this)

**Uses:** rbx-css (STACK.md), UIListLayout/UIGridLayout (ARCHITECTURE.md)

---

### Phase 2: DOM APIs (DOM-01, DOM-02)
**Rationale:** Enables dynamic content manipulation after rendering. Required foundation for JS engine in Phase 4. HTML Parser already exists; extend with DOM selection/manipulation APIs.

**Delivers:** DOMAPI module with `querySelector()`, `querySelectorAll()`, `getElementById()`, `createElement()`, `appendChild()`, `removeChild()`, `addEventListener()`, `removeEventListener()`, `classList` operations.

**Addresses:** DOM Selection APIs, DOM Manipulation APIs, DOM Event APIs (table stakes from FEATURES.md)

**Avoids:** Pitfall 7 (creating instances in parser—keep DOM APIs pure Luau), Pitfall 8 (polling loops—use signals/callbacks)

**Implements:** DOM APIs component (ARCHITECTURE.md)

---

### Phase 3: Network & Web APIs (DOM-03, API-01)
**Rationale:** Fetch API enables dynamic content loading. Server proxy already exists; add caching layer and localStorage for v1 persistence.

**Delivers:** Extended DOM APIs with `fetch()` (Promise-based), `XMLHttpRequest` fallback, `localStorage` (getItem/setItem/removeItem), client/server caching layer (URL → content with TTL).

**Addresses:** Fetch API, localStorage, URL Bar & Navigation (table stakes + differentiators from FEATURES.md)

**Avoids:** Pitfall 1 (StringValue 200K limit—implement chunking), Pitfall 9 (no caching—add cache layer), Pitfall 10 (full DOM re-render—add instance pooling)

**Uses:** HttpService (STACK.md), RemoteFunction pattern (ARCHITECTURE.md)

---

### Phase 4: Modern JS Engine (JS-01)
**Rationale:** Most complex phase; must follow stable DOM APIs. Phased approach: DOM shims first (querySelector, addEventListener, fetch as Luau functions), then ES5 subset interpreter.

**Delivers:** JSEngine module with:
- Phase 4a: DOM API shims only (no general JS execution; handle events via Roblox `MouseButton1Click`, etc.)
- Phase 4b (future): ES5 subset interpreter using Luau-based AST walker (handle `var`, `function`, `if`, `for`, basic expressions)
- Phase 4c (v2): ES6+ features (arrow functions → Luau closures, Promises → `task` library, async/await)

**Addresses:** ES6+ JavaScript (table stakes from FEATURES.md)

**Avoids:** Pitfall 5 (trying V8/SpiderMonkey—use Luau-based interpreter), Pitfall 3 (blocking main thread—yield during JS execution with `task.wait()`)

**Research needed:** Deeper research on "build JS interpreter in Luau" — riskiest part of the project. Consider `/gsd-research-phase` for JS engine architecture.

**Implements:** JS Engine component (ARCHITECTURE.md)

---

### Phase 5: Performance Optimization (PERF-01, PERF-02)
**Rationale:** Measure and optimize based on real usage patterns. All previous phases complete; now optimize for 60fps and <2.5s LCP.

**Delivers:** 
- Chunked rendering (50 nodes per frame using `task.defer()`)
- Instance pooling (reuse Roblox instances across page navigations)
- Virtual scrolling (only render viewport + buffer)
- Layout caching (cache layout for unchanged DOM subtrees)
- CSS indexing (O(1) selector matching for large StyleMaps)

**Addresses:** Fast Page Load Times, Smooth 60fps Interactions (differentiators from FEATURES.md)

**Avoids:** Pitfall 2 (instance explosion), Pitfall 3 (blocking main thread), Pitfall 10 (full DOM re-render)

**Uses:** Native `UIListLayout`/`UIGridLayout` (STACK.md), performance strategies (ARCHITECTURE.md)

---

### Phase Ordering Rationale

- **CSS first:** Visual layout is most visible; rbx-css integration is highest ROI. LayoutEngine benefits all subsequent phases.
- **DOM APIs second:** Enables dynamic content; required foundation for JS engine. Depends on HTML Parser (✓ exists) and LayoutEngine (Phase 1).
- **Network & Web APIs third:** Fetch API enables dynamic content loading. Depends on Server Proxy (✓ exists) and DOM APIs (Phase 2).
- **JS Engine fourth:** Most complex; must follow stable DOM. Phased approach delivers value sooner (DOM shims → ES5 → ES6+).
- **Performance last:** Measure real usage; optimize based on actual bottlenecks. Depends on all previous phases.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (JS Engine):** Complex integration, needs API research. JS engine architecture (interpreter vs transpiler) is the riskiest part. **Recommend:** `/gsd-research-phase` before planning.
- **Phase 5 (Performance):** Instance pooling and virtual scrolling patterns need experimentation. **Recommend:** Prototype before full planning.

Phases with standard patterns (skip research-phase):
- **Phase 1 (CSS Layout):** rbx-css is well-documented, active (2026-03-01), 15+ contributors. Standard CSS → StyleSheet compilation.
- **Phase 2 (DOM APIs):** Standard web APIs (querySelector, addEventListener) are well-documented on MDN. Many Roblox UI frameworks implement these.
- **Phase 3 (Network & Web APIs):** Fetch API, localStorage, caching patterns are standard. Server proxy already exists in project.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | Verified with official Roblox docs, rbx-css GitHub (active 2026), project aftman.toml versions |
| Features | **HIGH** | Based on MDN, Can I Use, Web.dev Baseline 2026, Roblox Creator Hub documentation |
| Architecture | **HIGH** | Verified against project codebase (HTMLParser, CSSParser, BrowserEngine), Roblox API docs |
| Pitfalls | **HIGH** | Verified against project CONCERNS.md, Roblox platform constraints, community patterns |

**Overall confidence:** **HIGH** for CSS/rendering stack and architecture; **MEDIUM** for JS engine (needs deeper research during Phase 4 planning).

### Gaps to Address

1. **JS Engine Architecture:** Need deeper research on "build JS interpreter in Luau." Current research recommends phased approach (DOM shims → ES5 → ES6+), but implementation details are sparse. **Handle during:** Phase 4 planning with `/gsd-research-phase`.

2. **HTML5 Compliance:** Current HTMLParser is basic (custom implementation). Might need a proper HTML5 parser for complex sites. Community doesn't have a mature HTML5 Luau parser yet. **Handle during:** Incremental improvements as needed; not a blocker for v1.

3. **Performance Benchmarks:** No data on "how many Roblox GUI instances before frame rate drops." Research suggests ~500-1000 instances per page for 60fps, but real testing needed. **Handle during:** Phase 5 (Performance Optimization) with in-experience testing.

4. **String Chunking Strategy:** Strategy for HTML > 200K chars not fully defined. Options: split across multiple StringValues, use `Buffer` (Luau 0.660+), or stream from server in chunks. **Handle during:** Phase 3 (DOM-03) implementation.

5. **Instance Recycling:** How to handle pages with 1000+ DOM elements within Roblox instance limits? Virtual scrolling and instance pooling patterns identified but not fully designed. **Handle during:** Phase 5 (PERF-01) implementation.

## Sources

### Primary (HIGH confidence)
- [Roblox Creator Docs](https://create.roblox.com/docs/) (2025-01-01) — Platform constraints, StyleSheet, UILayout, GUI objects, StringValue limits, Execution API quotas
- [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) (2026-03-01) — CSS to Roblox StyleSheet compiler; active maintenance, 15+ contributors
- [MDN Web Docs](https://developer.mozilla.org/) — DOM APIs, Fetch API, CSS Flexbox/Grid, ES6+ documentation
- [Can I Use](https://caniuse.com/) — Browser support tables for CSS Grid, Flexbox, ES6+ features, Fetch API
- **Project codebase:** `src/shared/parsers/HTMLParser.luau`, `src/shared/parsers/CSSParser.luau`, `src/client/modules/BrowserEngine.luau`

### Secondary (MEDIUM confidence)
- [LuauParser GitHub](https://github.com/vantoanvh/LuauParser) (2026-04-04) — Luau parser in Luau (for potential JS parser adaptation)
- [Roblox OSS Community Discord](https://discord.gg/mchCdAFPWU) — Community tools like Luaup, LuauParser discussed here
- [Web Almanac / HTTP Archive](https://almanac.httparchive.org/) — CSS Flexbox/Grid adoption statistics (72%+ for Grid, majority for Flexbox)
- [roBrowserLegacy GitHub](https://github.com/MrAntares/roBrowserLegacy) — Reference implementation patterns (wsProxy, packet handling)

### Tertiary (LOW confidence)
- [go-browser architecture](https://github.com/Jyotishmoy12/go-browser) — Non-Roblox browser engine for architectural inspiration only
- ES6+ feature implementation details in Luau — Will require experimentation during Phase 4

---

*Research completed: 2026-05-03*
*Ready for roadmap: yes*
