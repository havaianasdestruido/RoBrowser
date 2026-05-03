# Technology Stack

**Project:** robrowser  
**Research Date:** 2026-05-03  
**Overall Confidence:** HIGH (Roblox platform docs + active community tools)

---

## Recommended Stack

### Core Language & Runtime

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Luau** | Roblox runtime (0.714+) | All game logic, parsers, renderers, JS engine | Roblox's native scripting language; typed, safe, gradually typed. All code must be Luau. | HIGH |
| **Roblox Engine API** | Latest | GUI objects (Frames, TextLabels, etc.), Services | Native rendering surface; no alternative for in-game UI. | HIGH |

**Why not standard Lua:** Roblox uses Luau (Lua 5.1 derivative with type system, sandboxed runtime). Standard Lua interpreters cannot run in Roblox.

---

### Build & Dev Tools

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Rojo** | 7.7.0-rc.1 (per aftman.toml) | Sync Lua/u files to Roblox Studio | Industry standard for Roblox pro development; supports live sync. | HIGH |
| **StyLua** | 0.20.0 | Luau code formatter | Official Roblox formatting standard; 120 col width, tabs (4 spaces). | HIGH |
| **Selene** | 0.26.1 | Luau linter | Roblox standard library linting; catches errors early. | HIGH |
| **Aftman** | 0.6.x | Toolchain manager | Manages Rojo, StyLua, Selene versions declaratively. | HIGH |

**Why not alternatives:**  
- *Manual Studio editing*: No version control, no diff, no collaboration.  
- *Roblox CLI*: Limited; Rojo is the community standard.

---

### CSS Styling — Critical Decision

| Approach | Recommendation | Rationale | Confidence |
|----------|----------------|----------|------------|
| **rbx-css** (CSS → Roblox StyleSheet compiler) | ✅ **Use this** | Write standard CSS; auto-compiles to Roblox `StyleSheet` instances with native `StyleRule`, `UIListLayout` (flexbox), `UIGridLayout` (grid), pseudo-instances (`UICorner`, `UIStroke`, `UIPadding`). Supports nesting, CSS variables, pseudo-classes (`:hover`, `:active`). | HIGH |
| **Custom CSSParser (current)** | ❌ **Replace** | Limited to basic properties; no flexbox/grid support; manual mapping to Roblox properties is error-prone and incomplete. | HIGH |
| **Manual Roblox StyleSheet creation** | ❌ **Don't** | Writing `Instance.new("StyleRule")` by hand is tedious; rbx-css generates correct native structures automatically. | HIGH |

**rbx-css Usage in robrowser:**
```bash
# Install  
npx rbx-css compile styles.css -o StyleSheet.luau

# In Luau:
local StyleSheet = require(path.to.StyleSheet)
local sheet = StyleSheet.createStyleSheet()
sheet:Apply(someGuiObject)
```

**CSS → Roblox Mapping (rbx-css handles these automatically):**

| CSS | Roblox Native |
|-----|----------------|
| `div`, `span`, `p`, `h1`-`h6` | `Frame`, `TextLabel` (auto element mapping) |
| `.class` | `StyleRule.Selector = ".class"` + `:SetAttribute("Class", "class")` |
| `#id` | `StyleRule.Selector = "#id"` (matches `Instance.Name`) |
| `display: flex` + flex properties | `UIListLayout` with `HorizontalFlex`/`VerticalFlex` |
| `display: grid` + grid properties | `UIGridLayout` |
| `border-radius` | `UICorner` pseudo-instance |
| `border` | `UIStroke` pseudo-instance |
| `padding` | `UIPadding` pseudo-instance |
| `:hover` | `:Hover` state selector |
| CSS custom properties (`--var`) | `StyleSheet` attributes (tokens) |

**Source:** [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) (2026-03-01, active), [Roblox StyleSheet docs](https://create.roblox.com/docs/ui/styling) (2025-01-01)

---

### HTML Parsing

| Technology | Recommendation | Rationale | Confidence |
|------------|----------------|----------|------------|
| **Custom HTMLParser (current)** | ⚠️ **Improve incrementally** | Basic but functional for subset of HTML. Handles tags, attributes, nesting, self-closing tags, comments. Sufficient for initial phases. | MEDIUM |
| **Upgrade to formal parser** | 🔄 **Later** | Consider a proper HTML5-compliant parser if needed. Luau community doesn't have a mature HTML parser yet; current one works for basic rendering. | LOW |

**Current HTMLParser supports:**  
- Tags: `<div>`, `<span>`, `<a>`, `<img>`, `<button>`, `<input>`, `<form>`, headings, etc.  
- Attributes: `class`, `id`, `href`, `src`, `style`, etc.  
- Structure: Nesting, self-closing tags (`<br>`, `<img>`), comments, DOCTYPE skipping.  
- CSS extraction: Pulls `<style>` tag content for StyleSheet compilation.

**Not supported yet:**  
- Malformed HTML recovery (current parser fails on weird markup)  
- HTML5 semantic elements full mapping  
- SVG parsing (would need separate `ViewportFrame` rendering)

---

### JavaScript Engine — Open Problem

**Context:** robrowser needs JS execution for interactive websites. This is the hardest part of the stack.

| Approach | Pros | Cons | Recommendation | Confidence |
|----------|------|------|----------------|------------|
| **Pure Luau interpreter** (build AST, walk + evaluate) | Pure Luau; no external deps; full control | Extremely complex; Luau is slow for meta-programming; limited execution budget (~5 min timeout, must yield) | 🔄 **Feasible for ES5 subset** | MEDIUM |
| **JS → Luau transpiler** | Faster execution (native Luau); can pre-compile | Complex tooling; need to map JS runtime to Roblox APIs; DOM API shims needed | ⚠️ **Consider for v2** | LOW |
| **Hybrid: Minimal interpreter for DOM APIs** | Focus on `querySelector`, `addEventListener`, `fetch` shims; ignore full JS | Achieves 80% of browser parity with 20% effort | ✅ **Recommended first approach** | MEDIUM |

**Recommended JS Engine Architecture (phased):**

1. **Phase 1 (MVP):** DOM API shims only  
   - Implement `document.querySelector()`, `addEventListener()`, `fetch()` as Luau functions  
   - No general JS execution; handle events via Roblox `MouseButton1Click`, etc.  
   - **Confidence:** HIGH (done in many Roblox UI frameworks)

2. **Phase 2 (ES5 subset interpreter):**  
   - Use **LuauParser** (v0.715, [GitHub](https://github.com/vantoanvh/LuauParser), 2026-04-04) to parse JS syntax into AST  
   - Walk AST with Luau interpreter: handle `var`, `function`, `if`, `for`, basic expressions  
   - **Why LuauParser:** Written in Luau, returns both AST and CST, type-checked with New Type Solver, optimized singleton design (~30ms for typical files).  
   - **Constraint:** LuauParser is for parsing *Luau* syntax, not JavaScript. Would need adaptation or a JS-specific parser.  
   - **Alternative:** Write a minimal JS parser using Luau string patterns (similar to current HTMLParser approach).  
   - **Confidence:** MEDIUM (JS parser in Luau is a significant project)

3. **Phase 3 (ES6+ features):**  
   - Arrow functions, promises, async/await → implement as Luau closures + `task` library  
   - Use **luau-regexp** ([GitHub](https://github.com/Roblox/luau-regexp), MIT, 2023-10-23) for `RegExp` support  
   - **Confidence:** LOW (lots of work, may hit Roblox execution limits)

**What NOT to do:**  
- ❌ **Don't use `roblox-cs` (C# → Luau transpiler)** for JS engine. It's for C# to Luau, not JS to Luau. Wrong tool.  
- ❌ **Don't use `lukadev-0/roblox-browser` approach** (Rust server + headless Chrome). That's a remote rendering approach, not in-Roblox Luau rendering.  
- ❌ **Don't try to run full V8/SpiderMonkey in Roblox.** Impossible; Roblox sandbox prevents native code execution.

---

### DOM & Rendering

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Roblox GUI objects** | Native | `Frame`, `TextLabel`, `TextButton`, `TextBox`, `ScrollingFrame`, `ImageLabel` | Native rendering surface; 1:1 mapping from HTML elements to Roblox instances. | HIGH |
| **UIListLayout** | Native | Flexbox layouts (row/column, justify, align, gap, flex, wrap) | Roblox native flexbox; integrates with StyleSheets via rbx-css. | HIGH |
| **UIGridLayout** | Native | Grid layouts (equal cells, auto-flow) | Roblox native grid; use for table-like structures. | HIGH |
| **CollectionService** | Native | Tag-based CSS class matching (`.class` selectors) | Complements rbx-css class selectors; tag elements for styling. | HIGH |

**Current BrowserEngine mapping (to be enhanced with rbx-css):**

| HTML Element | Current Roblox Instance | Recommended Update |
|--------------|----------------------|-------------------|
| `<div>`, `<section>`, etc. | `Frame` | Same, but apply rbx-css StyleSheets for styling |
| `<span>`, `<p>`, `<h1>`-`<h6>` | `TextLabel` | Same, style via StyleSheets |
| `<a>`, `<button>` | `TextButton` | Same, add `:Hover`/`:Press` states via StyleSheets |
| `<img>` | `ImageLabel` | Same |
| `<input>` | `TextBox` | Same |
| `<form>` | `Frame` with children | Same |

---

### Networking & Data

| Technology | Purpose | Why | Confidence |
|------------|---------|-----|------------|
| **HttpService** (Roblox native) | Server-side HTTP requests (proxy for client) | Client cannot make direct HTTP requests; server must proxy via `HttpService:GetAsync()`. | HIGH |
| **RemoteFunction** (`FetchHTML`) | Client → Server communication for page fetches | Standard Roblox pattern; client invokes server to fetch HTML. | HIGH |
| **StringValue** | Store HTML/CSS content | Max 200,000 characters per string. **Constraint:** Large pages may exceed this. | HIGH |

**Roblox Platform Constraints (CRITICAL for architecture):**

| Constraint | Limit | Implication for robrowser |
|------------|------|--------------------------|
| **String length** (StringValue) | 200,000 characters | HTML pages > 200K chars need chunking or alternative storage (e.g., split across multiple StringValues, or stream via attributes). |
| **Script execution timeout** | ~5 minutes (Luau Execution API); must yield regularly | Long-running JS engines must yield via `task.wait()` or `RunService.Heartbeat`. Never block main thread. |
| **Data store value size** | 4,194,304 chars (~4 MB) | OK for typical pages; not a bottleneck for rendering. |
| **Instance count** (implicit) | No hard limit, but performance degrades with thousands of GUI instances | Complex pages with deep DOM trees could hit frame rate issues. Use UIListLayout/UIGridLayout (native C++ layouts) instead of manual positioning. |
| **Roblox GUI object properties** | `Size` uses `UDim2`, `Position` uses `UDim2` | Need to convert CSS pixels to Roblox's scale/offset system. rbx-css handles this in StyleSheet compilation. |

**Source:** [Roblox StringValue docs](https://create.roblox.com/docs/reference/engine/classes/StringValue) (2025), [ScriptContext:SetTimeout](https://create.roblox.com/docs/reference/engine/classes/ScriptContext) (2025), [Execution API quotas](https://create.roblox.com/docs/cloud/features/luau-execution) (2024-12-02)

---

## Installation & Setup

```bash
# Toolchain (managed by Aftman)
aftman install  # installs Rojo, StyLua, Selene per aftman.toml

# rbx-css (CSS compiler, separate from Roblox toolchain)
npm install -g rbx-css  # or: npx rbx-css compile ...

# Build place file
rojo build -o "robrowser.rbxlx"

# Live sync (development)
rojo serve

# Lint & format
selene src/
stylua src/
```

---

## Key Decisions Summary

| Decision | Rationale | Status |
|----------|----------|--------|
| Use **rbx-css** for CSS → StyleSheet compilation | Leverages Roblox native styling (flexbox/grid); standard CSS authoring; active maintenance (2026). | ✅ **Approved** |
| Replace custom CSSParser with rbx-css output | Custom parser lacks flexbox/grid; rbx-css generates correct native StyleSheets. | ✅ **Approved** |
| JS engine: Start with DOM API shims, then ES5 subset interpreter | Full JS engine is years of work; phased approach delivers value sooner. | ⚠️ **Pending research** |
| Use LuauParser (if building JS parser) | Written in Luau, type-checked, active (v0.715, 2026-04). But: parses Luau, not JS. Need adaptation. | 🔄 **Consider** |
| Keep custom HTMLParser (improve incrementally) | Functional for subset; no mature HTML5 Luau parser exists. Upgrade when needed. | ✅ **Approved** |
| Network: Server-side HttpService proxy | Roblox client cannot make HTTP requests; server must proxy. | ✅ **Existing, keep** |

---

## What NOT to Use & Why

| Technology | Why Not |
|------------|---------|
| **Custom CSS parsing** (current CSSParser.luau) | No flexbox/grid support; manual property mapping is incomplete; rbx-css + native StyleSheets is superior. |
| **Manual GUI positioning** (setting `Position`/`Size` per element) | Slow (Luau per-instance updates); use native `UIListLayout`/`UIGridLayout` (C++ layouts). |
| **`roblox-cs` (C# → Luau)** | For C# transpilation, not JS. Wrong tool for JS engine. |
| **Remote rendering (Rust/Chrome headless)** | `lukadev-0/roblox-browser` approach; not in-Roblox rendering; requires external server. |
| **Full V8/SpiderMonkey in Roblox** | Impossible; Roblox sandbox prevents native code; no file system access for native binaries. |
| **`StringValue` for >200K char HTML** | Exceeds max length; use chunking or alternative storage. |

---

## Sources & Confidence

| Source | Confidence | Notes |
|--------|------------|-------|
| [Roblox Creator Docs](https://create.roblox.com/docs/) (2025-01-01) | HIGH | Official platform constraints, StyleSheet, UILayout docs |
| [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) (2026-03-01) | HIGH | Active CSS compiler; 15+ contributors; matches our exact use case |
| [LuauParser GitHub](https://github.com/vantoanvh/LuauParser) (2026-04-04) | MEDIUM | Luau parser in Luau; for JS engine would need adaptation |
| [Roblox Luau Releases](https://github.com/Roblox/luau/releases) (0.714, 2026-03-27) | HIGH | Official Luau runtime; version reference |
| [Roblox OSS Community Discord](https://discord.gg/mchCdAFPWU) | MEDIUM | Community tools like Luaup, LuauParser discussed here |
| [Roblox Execution API](https://create.roblox.com/docs/cloud/features/luau-execution) (2024-12-02) | HIGH | Script timeout, string limits, quotas |

---

## Gaps & Open Questions

1. **JS Engine Architecture:** Need deeper research on "build JS interpreter in Luau" — this is the riskiest part. ConsiderPhase-specific research after CSS/rendering phases are done.  
2. **HTML5 Compliance:** Current parser is basic. Might need a proper HTML5 parser for complex sites. Community doesn't have one yet.  
3. **Performance Benchmarks:** No data on "how many Roblox GUI instances before frame rate drops." Need in-experience testing with typical pages.  
4. **String Chunking:** Strategy for HTML > 200K chars not defined. Options: split across multiple `StringValue`, use `Buffer` (Luau 0.660+), or stream from server in chunks.

---

*Research completed: 2026-05-03. Confidence: HIGH for CSS/rendering stack, MEDIUM for JS engine (needs deeper research).*
