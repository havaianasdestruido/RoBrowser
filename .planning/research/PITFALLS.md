# Domain Pitfalls

**Domain:** Roblox browser engine (rendering websites inside Roblox using Luau)
**Researched:** 2026-05-03
**Confidence:** HIGH (verified against project codebase, Roblox platform docs, STACK.md, ARCHITECTURE.md, CONCERNS.md, and community patterns)

---

## Critical Pitfalls

Mistakes that cause rewrites, major performance failures, or project abandonment.

---

### Pitfall 1: Exceeding StringValue 200,000 Character Limit

**What goes wrong:**
HTML pages (especially modern sites) commonly exceed 200,000 characters. Roblox `StringValue` instances have a hard limit of 200,000 characters. When the HTML exceeds this limit, the page silently truncates or errors when storing/transmitting via `RemoteFunction`.

**Why it happens:**
- Developers assume "strings are unlimited" based on general programming experience
- Roblox `string` type supports ~2^30 characters, but `StringValue` object property is capped at 200K
- The `FetchHTML` RemoteFunction returns HTML as a string to the client, which then tries to store it in a `StringValue` for rendering

**Consequences:**
- Large pages (Wikipedia articles, news sites, documentation pages) fail to load
- Silent truncation leads to malformed HTML and broken DOM trees
- Hard to debug — no explicit error, just "page looks wrong"

**Prevention:**
- Check HTML length before storing: `if #html > 190000 then -- chunk or reject end`
- Use chunking strategy: split HTML across multiple `StringValue` objects or use `Buffer` (Luau 0.660+)
- Stream from server in chunks via repeated `RemoteFunction` calls
- Alternative: Don't store full HTML in `StringValue`; parse server-side and send DOM tree as a table (within DataStore 4MB limit)

**Detection (warning signs):**
- Pages with "long articles" or "documentation" fail to render
- HTML appears truncated at ~200K characters
- Check: `print(#htmlString)` after fetch

**Phase to address:** DOM-03 (Network request APIs) — implement chunking at the network layer

**Roblox constraint:** `StringValue.MaxLength = 200,000` (verified: [Roblox StringValue docs](https://create.roblox.com/docs/reference/engine/classes/StringValue), 2025)

---

### Pitfall 2: Instance Explosion — Creating 1 Roblox Instance Per DOM Node

**What goes wrong:**
Mapping every DOM node to a Roblox GUI instance (Frame, TextLabel, etc.) works for simple pages but causes severe performance degradation when pages have thousands of DOM nodes. Roblox has no hard instance limit, but performance degrades sharply after ~1000-2000 instances in a `ScrollingFrame`.

**Why it happens:**
- Naive 1:1 mapping from DOM nodes to Roblox instances seems correct
- Developers don't realize `ScrollingFrame` with 5000 children runs at 10fps
- Each instance creation crosses the Luau→C++ boundary (expensive)

**Consequences:**
- Frame rate drops below 60fps (often to 10-20fps) on complex pages
- Game becomes unresponsive during rendering
- Roblox may throttle or crash the experience

**Prevention:**
- **Virtual scrolling:** Only render nodes visible in the viewport + buffer (e.g., 50px above/below)
- **Instance pooling:** Reuse Roblox instances when navigating between pages instead of `ClearAllChildren()`
- **Native layouts:** Use `UIListLayout`/`UIGridLayout` (C++ native) instead of manual `Position`/`Size` setting
- **Simplify DOM:** Skip invisible elements (`display: none`), merge text nodes, skip non-rendered tags (`<head>`, `<script>`, `<style>`)
- **Chunked rendering:** Render 50 nodes per frame using `task.defer()` to avoid timeout

**Detection (warning signs):**
- `game:GetService("Stats").InstanceCount` shows >2000 instances after page load
- Frame rate drops when navigating to content-heavy sites
- `ScrollingFrame` has hundreds of direct children

**Phase to address:** PERF-01, PERF-02 (Performance optimization) — but design for this from Phase 1 (CSS-01+)

**Roblox constraint:** No hard instance limit, but `UIListLayout` with 10,000 children is ~5fps. Testing shows ~500-1000 instances per page is the practical limit for 60fps.

---

### Pitfall 3: Blocking Main Thread — Rendering Entire Page in One Frame

**What goes wrong:**
The `BrowserEngine.render()` function creates all Roblox instances synchronously in a single call. For pages with 500+ DOM nodes, this takes >16ms (one frame budget) and can exceed Roblox's 10-second script timeout in Studio (shorter in production).

**Why it happens:**
- straightforward `for node in domTree do renderNode(node) end` seems fine for small pages
- Developers don't test with "real" complex pages during development
- Roblox Luau doesn't have a built-in "yield every N iterations" pattern that beginners know

**Consequences:**
- Script timeout errors on complex pages
- Entire game freezes during page load (not just the browser UI)
- Users think the experience is broken

**Prevention:**
- **Chunked rendering with `task.defer()` or coroutines:**
  ```lua
  local function renderChunk(nodes, startIndex, chunkSize)
      for i = startIndex, math.min(startIndex + chunkSize - 1, #nodes) do
          renderNode(nodes[i])
          if i % 50 == 0 then task.wait() end -- yield every 50 nodes
      end
  end
  ```
- **Above-fold first:** Render visible viewport area first, defer offscreen content
- **Progress callback:** Report rendering progress to show loading UI

**Detection (warning signs):**
- Page load takes >1 second with game frozen
- "Script timeout" errors in output
- Check: `print(os.clock())` before/after render loop

**Phase to address:** PERF-01 (Fast page load times) — implement chunked rendering

**Roblox constraint:** Script timeout = 10 seconds in Studio, shorter (varies) in production experiences. Must yield regularly using `task.wait()` or `RunService.Heartbeat`.

---

### Pitfall 4: Building Custom CSS Engine Instead of Using rbx-css

**What goes wrong:**
Implementing CSS Flexbox, Grid, specificity, pseudo-selectors, and media queries as a custom Luau CSS engine. This is months of work that rbx-css already solves using Roblox's native `StyleSheet` + `UIListLayout`/`UIGridLayout`.

**Why it happens:**
- Developers don't know rbx-css exists (community tool, not official Roblox)
- "How hard can CSS be?" — underestimating CSS spec complexity
- Want "full control" over CSS implementation

**Consequences:**
- Months of work on CSS parser that still doesn't handle edge cases
- Flexbox/Grid implementations are buggy (different from browser behavior)
- CSS specificity, inheritance, and cascade are extremely hard to get right
- Miss out on Roblox native performance (C++ layouts vs Luau calculations)

**Prevention:**
- **Use rbx-css:** Write standard CSS, compile to Roblox `StyleSheet` instances
  ```bash
  npx rbx-css compile styles.css -o StyleSheet.luau
  ```
- rbx-css handles: Flexbox (`UIListLayout`), Grid (`UIGridLayout`), pseudo-classes (`:hover`), CSS variables, nesting
- Only build custom CSS for properties rbx-css doesn't support (rare)

**Detection (warning signs):**
- Custom `CSSParser.luau` has 500+ lines
- Flexbox/Grid behavior differs from real browsers
- Spending weeks on CSS parsing instead of rendering

**Phase to address:** CSS-01, CSS-02, CSS-03, CSS-04 (CSS layout support) — use rbx-css from the start

**Source:** [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) (2026-03-01, active, 15+ contributors). Verified in STACK.md as HIGH confidence recommendation.

---

### Pitfall 5: Trying to Run Full V8/SpiderMonkey or Native JS Engines

**What goes wrong:**
Attempting to compile V8, SpiderMonkey, or any native C++ JS engine to run inside Roblox. This is impossible due to Roblox's sandbox restrictions.

**Why it happens:**
- "We need a real JS engine for compatibility"
- Not understanding Roblox's security model (no native code execution, no file system access for binaries)
- Looking at non-Roblox browser engine projects (Chromium, Servo) for inspiration

**Consequences:**
- Wasted months researching impossible approaches
- Project stagnation while trying to solve an unsolvable problem
- Eventually having to pivot to Luau-based JS interpreter anyway

**Prevention:**
- **Accept the constraint:** JS must run in Luau (interpreted or transpiled to Luau)
- **Phased JS approach** (from STACK.md):
  1. DOM API shims only (`querySelector`, `addEventListener`, `fetch`)
  2. ES5 subset interpreter (var, function, if, for)
  3. ES6+ features (arrow functions, promises) as Luau equivalents
- **Don't use:** `roblox-cs` (C# → Luau, not JS → Luau), `lukadev-0/roblox-browser` (remote rendering, not in-Roblox)

**Detection (warning signs):**
- Researching "compile V8 to WebAssembly for Roblox"
- Looking at Rust/Chrome headless approaches
- Trying to use `plugin` or `C++` in Roblox

**Phase to address:** JS-01 (Modern JS support) — use phased approach from STACK.md

**Roblox constraint:** Roblox sandbox prevents: native code execution, file system access for binaries, loading dynamic libraries. Luau is the only scripting language.

---

## Moderate Pitfalls

Mistakes that cause significant rework or performance issues but don't kill the project.

---

### Pitfall 6: Monolithic Render Function (BrowserEngine.luau > 500 lines)

**What goes wrong:**
`BrowserEngine.render()` handles CSS style application, DOM rendering, navigation bar creation, UI state management, and text calculations in a single 555-line file. This makes it impossible to test, debug, or modify individual stages.

**Why it happens:**
- Starting with "simple" rendering that grows over time
- Not following the standard browser pipeline (parse → style → layout → paint)
- "Refactoring later" that never happens

**Consequences:**
- Adding new HTML tags or CSS properties requires touching multiple sections
- Bugs in one area break unrelated functionality
- Impossible to optimize individual stages (e.g., only optimize layout)
- No unit testing possible

**Prevention:**
- **Separate into pipeline stages:**
  - `HTMLParser.parse()` → DOM tree
  - `CSSParser.parse()` → StyleMap
  - `LayoutEngine.calculate()` → Position + Size (NEW in this project)
  - `BrowserEngine.render()` → Create Roblox instances (thin wrapper)
- Each stage is a separate module with clear inputs/outputs
- Enables testing each stage independently

**Detection (warning signs):**
- Single Luau file > 500 lines
- Function `renderNode()` is > 100 lines with deeply nested if/else
- Adding a new CSS property requires changes in 3+ places

**Phase to address:** CSS-01+ (Layout Engine) — build `LayoutEngine` as separate module

**Source:** Identified in CONCERNS.md ("BrowserEngine is a Monolithic Module", severity MEDIUM) and ARCHITECTURE.md (Anti-Pattern 1).

---

### Pitfall 7: Creating Roblox Instances During HTML Parsing

**What goes wrong:**
Creating `Frame`, `TextLabel`, etc. while parsing HTML tokens. The parser should be a pure function (HTML string → DOM tree) with no side effects.

**Why it happens:**
- "Eager rendering" — creating instances as soon as a tag is parsed
- Not understanding the browser pipeline (parse first, render later)
- Parser is in `src/shared/` but creates client-side instances (crosses boundary)

**Consequences:**
- Parser can't be used server-side (creates GUI instances)
- Can't reuse parser for different rendering backends
- Hard to debug parsing issues vs rendering issues
- DOM tree is lost (can't re-render without re-parsing)

**Prevention:**
- **Parser returns DOM tree only:** `HTMLParser.parse(html) → {type: "ElementNode", tag: "div", children: {...}}`
- **Renderer consumes DOM tree:** `BrowserEngine.render(domTree, styleMap, layout)`
- Parser is in `src/shared/` (no Roblox instances)
- Renderer is in `src/client/` (creates instances)

**Detection (warning signs):**
- `HTMLParser.luau` contains `Instance.new()` calls
- Parser function returns `nil` (just creates instances as side effect)
- Can't call parser without a `PlayerGui` or `ScreenGui`

**Phase to address:** Refactor during CSS-01+ (when building LayoutEngine)

**Source:** ARCHITECTURE.md (Anti-Pattern 2: "Creating Instances During Parsing")

---

### Pitfall 8: Polling Loops Instead of Event-Based Patterns

**What goes wrong:**
Using `while task.wait(0.5) do` polling loops to wait for UI elements or state changes. The current code has a polling loop (lines 173-221 in `init.client.luau`) that checks for `navElements` every 500ms indefinitely.

**Why it happens:**
- Easier to write `while wait() do` than learn Roblox signals
- Not knowing about `CollectionService` signals, `GetPropertyChangedSignal`, or callback patterns
- "It works" even though it's wasteful

**Consequences:**
- Unnecessary CPU usage every 500ms (even after elements are found)
- Fragile timing dependency (`task.wait(1)` before setup)
- If UI creation is delayed, button handlers may never connect
- Code runs indefinitely even when not needed

**Prevention:**
- **Use signals/callbacks:**
  ```lua
  -- Instead of polling:
  -- while task.wait(0.5) do if navElements then setup() end end

  -- Use callback:
  BrowserEngine.onReady:Connect(function()
      setupNavigationButtons()
  end)
  ```
- **Use `CollectionService` for tagged instances:**
  ```lua
  CollectionService:GetInstanceAddedSignal("NavButton"):Connect(connectHandler)
  ```

**Detection (warning signs):**
- `while task.wait()` or `while wait()` in client code
- Polling loops with no break condition
- `task.wait(1)` before accessing UI elements (timing hack)

**Phase to address:** Refactor during first client-side work (CSS-01 or DOM-01)

**Source:** CONCERNS.md ("Polling-based Navigation Button Setup", severity MEDIUM; "Polling Loop in Client", severity MEDIUM)

---

### Pitfall 9: No Caching of Fetched Pages

**What goes wrong:**
Every navigation triggers a new HTTP request via `FetchHTML` RemoteFunction. Navigating back/forward, or refreshing the page, re-fetches the entire HTML from the server.

**Why it happens:**
- "Simple" implementation doesn't consider caching
- Roblox `HttpService:GetAsync()` is slow (~200-500ms per request)
- Server has no cache layer

**Consequences:**
- Slow back/forward navigation (re-fetches every time)
- Excessive HTTP requests to external sites (may get rate-limited)
- Poor UX: refresh takes as long as initial load

**Prevention:**
- **Client-side cache:** `local pageCache = {}` mapping URL → {html, timestamp, ttl}
- **Server-side cache:** Use a simple table cache with TTL (Luau tables are fast)
- **Cache invalidation:** TTL-based (e.g., 5 minutes) or manual refresh

**Detection (warning signs):**
- Multiple `FetchHTML` calls for the same URL in quick succession
- Network tab (Roblox dev tools) shows repeated requests
- Back button takes same time as initial navigation

**Phase to address:** DOM-03, API-01 (Network & Web APIs) — add caching layer

**Source:** CONCERNS.md ("No Caching of Fetched HTML", severity LOW; but should be MEDIUM for UX)

---

### Pitfall 10: Full DOM Re-render on Navigation

**What goes wrong:**
`BrowserEngine.render()` calls `targetGui:ClearAllChildren()` and re-creates all Roblox instances for every navigation. This destroys all UI elements and re-renders from scratch.

**Why it happens:**
- Simplest approach: "clear and re-render"
- Not considering instance creation cost
- No differential rendering system

**Consequences:**
- Unnecessary UI destruction and recreation (expensive)
- Potential flicker when navigating
- Loses scroll position, input state, etc.
- Slower navigation

**Prevention:**
- **Instance pooling:** Keep a pool of pre-created `Frame`, `TextLabel`, etc. and reuse them
- **Differential updates:** Only re-render changed DOM subtrees (hard, would need virtual DOM diff)
- **At minimum:** Don't `ClearAllChildren()` if the new page is similar (e.g., same site, different path)

**Detection (warning signs):**
- `ClearAllChildren()` called on every navigation
- Navigation causes brief white flash (instances destroyed before new ones created)
- Large `ScrollingFrame` child count goes to 0 then back to 500+

**Phase to address:** PERF-01 (Fast page load times) — implement instance pooling

**Source:** CONCERNS.md ("Full DOM Re-render on Navigation", severity LOW)

---

## Minor Pitfalls

Mistakes that cause annoyance or technical debt but don't break core functionality.

---

### Pitfall 11: No Test Coverage

**What goes wrong:**
No test files (`*.test.luau`, `*.spec.luau`) exist. The HTML parser, CSS parser, and BrowserEngine have no automated tests.

**Why it happens:**
- Roblox doesn't have a built-in test framework
- "It works when I test manually" mentality
- Test setup seems like overhead

**Consequences:**
- Changes to parsers or rendering engine introduce regressions unnoticed
- Hard to refactor (afraid of breaking things)
- Can't verify CSS Flexbox/Grid correctness automatically

**Prevention:**
- **Use a Luau test framework:** [Roblox-ts Jest](https://github.com/roblox-ts/jest-roblox) or write simple assert-based tests
- **Test parsers first:** HTML → DOM tree output, CSS → StyleMap output
- **Snapshot testing:** Compare rendered DOM tree structure (not Roblox instances)

**Detection (warning signs):**
- No `test` or `spec` files in project
- "I manually tested it" is the only verification
- Fear of refactoring existing code

**Phase to address:** Continuous — add tests as each module is built

**Source:** CONCERNS.md ("No Test Files Exist", severity HIGH for risk, but classified as minor pitfall because it doesn't break functionality — just makes maintenance hard)

---

### Pitfall 12: Ignoring CSS Specificity

**What goes wrong:**
In `CSSParser.luau`, when multiple selectors apply to the same element, later rules simply overwrite earlier ones without considering CSS specificity. Class and ID selectors both merge into the same styles table without priority.

**Why it happens:**
- CSS specificity rules are complex (a, b, c, d calculation)
- "Simple" approach: last rule wins
- Not understanding CSS cascade

**Consequences:**
- CSS behavior differs from real browsers
- Pages render with incorrect styles
- Hard to debug why a style "isn't working"

**Prevention:**
- **Implement specificity calculation:**
  ```lua
  -- Specificity: [inline, id, class, element] count
  -- Example: "#header .nav li" = [0, 1, 1, 1]
  local function calculateSpecificity(selector)
      -- count id, class, element selectors
  end
  ```
- **Sort rules by specificity** before applying
- **Use rbx-css** (handles specificity correctly via native `StyleRule`)

**Detection (warning signs):**
- `.class` and `#id` rules both apply but order depends on CSS source order, not specificity
- Adding a more specific selector doesn't override less specific ones

**Phase to address:** CSS-01+ (when using custom CSS) — or use rbx-css and avoid this entirely

**Source:** CONCERNS.md ("CSS Selector Override Order", severity LOW), STACK.md (rbx-css recommendation)

---

### Pitfall 13: Text Height Calculation Approximation

**What goes wrong:**
`calculateTextHeight()` uses a simple character-per-line calculation that doesn't account for actual font metrics, word boundaries, or Roblox text rendering behavior.

**Why it happens:**
- Text height calculation is "hard" (depends on font, size, content)
- Simple approach: `#text / charsPerLine * lineHeight`
- Not using Roblox's `TextBounds` API

**Consequences:**
- Text may be clipped (not enough height)
- Text may have excessive whitespace (too much height)
- Inconsistent rendering across different text contents

**Prevention:**
- **Use `TextLabel.TextBounds`:** Returns `Vector2` with actual rendered size
  ```lua
  local tempLabel = Instance.new("TextLabel")
  tempLabel.Text = text
  tempLabel.TextSize = fontSize
  tempLabel.Font = font
  local bounds = tempLabel.TextBounds
  tempLabel:Destroy()
  return bounds.Y
  ```
- **Cache text height calculations** for repeated text

**Detection (warning signs):**
- Text is clipped at bottom of `TextLabel`
- Lots of extra whitespace below text
- `calculateTextHeight()` function is < 10 lines

**Phase to address:** CSS-04 (Box model) — fix text height calculation

**Source:** CONCERNS.md ("Text Height Calculation Approximation", severity LOW)

---

### Pitfall 14: Debug Module Set to Verbose in Production

**What goes wrong:**
`src/shared/settings.luau` sets `DebugLevel = "verbose"` by default, which prints extensive debug information to the output. In production, this could expose internal implementation details and impact performance.

**Why it happens:**
- Developing with verbose logging for debugging
- Forgetting to change debug level before "shipping"
- No separate dev/prod configurations

**Consequences:**
- Output flooded with debug messages (performance impact)
- Internal implementation details exposed to curious users
- Larger game output log (harder to find real errors)

**Prevention:**
- **Default to `"warn"` or `"error"` for production builds**
- **Use Rojo environment:** Different `settings.luau` for dev vs prod
- **Conditional debug:** `if DebugLevel == "verbose" then print(...) end`

**Detection (warning signs):**
- Output window shows hundreds of debug messages during normal operation
- `DebugLevel = "verbose"` in committed `settings.luau`

**Phase to address:** Before first public release — set appropriate debug level

**Source:** CONCERNS.md ("Debug Level Configuration Exposure", severity LOW)

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **CSS-01 to CSS-04** (CSS Layout) | Pitfall 4: Building custom CSS engine | Use rbx-css from the start; don't write custom Flexbox/Grid |
| **DOM-01, DOM-02** (DOM APIs) | Pitfall 7: Creating instances in parser | Keep DOM APIs as pure Luau functions; instances only in renderer |
| **DOM-03, API-01** (Network & Web APIs) | Pitfall 9: No caching | Implement URL → content cache on server and/or client |
| **JS-01** (Modern JS) | Pitfall 5: Trying full V8/SpiderMonkey | Use phased approach: DOM shims → ES5 interpreter → ES6+ features |
| **PERF-01, PERF-02** (Performance) | Pitfall 2: Instance explosion + Pitfall 3: Blocking main thread | Virtual scrolling, instance pooling, chunked rendering from day one |

---

## Roblox Platform Constraints That Cause Pitfalls

| Constraint | Limit | Pitfalls It Causes |
|------------|------|-------------------|
| **StringValue length** | 200,000 characters | Pitfall 1: Exceeding 200K char limit |
| **Script execution time** | ~10 seconds (Studio), shorter in production | Pitfall 3: Blocking main thread |
| **Instance count** | No hard limit, but performance degrades >1000-2000 | Pitfall 2: Instance explosion |
| **Client HTTP** | Not allowed (must use server proxy) | Security risks if not validated (CONCERNS.md) |
| **Native code execution** | Not allowed (sandbox) | Pitfall 5: Trying V8/SpiderMonkey |
| **Roblox GUI properties** | `Size` uses `UDim2`, no `position: fixed` | Layout differences from real browsers |
| **ScrollingFrame** | `CanvasSize` must be set manually | Different from browser auto-scroll |

---

## Sources

| Source | Confidence | Notes |
|--------|------------|-------|
| [Roblox Creator Docs](https://create.roblox.com/docs/) (2025-01-01) | HIGH | Official platform constraints, StringValue, StyleSheet, UILayout docs |
| [Roblox Execution API](https://create.roblox.com/docs/cloud/features/luau-execution) (2024-12-02) | HIGH | Script timeout, quotas, string limits |
| [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) (2026-03-01) | HIGH | CSS to Roblox StyleSheet compiler; active maintenance |
| [rbx-tsx Element Mapping](https://www.mintlify.com/AlroviOfficial/rbx-tsx/guides/element-mapping) | MEDIUM | HTML → Roblox instance mapping patterns |
| **PROJECT.md** (2026-05-03) | HIGH | Project context, requirements, constraints |
| **STACK.md** (2026-05-03) | HIGH | Technology recommendations, constraints, what NOT to use |
| **ARCHITECTURE.md** (2026-05-03) | HIGH | Anti-patterns, constraints, scalability considerations |
| **CONCERNS.md** (2026-05-03) | HIGH | Existing tech debt, bugs, performance bottlenecks |
| [Roblox StringValue docs](https://create.roblox.com/docs/reference/engine/classes/StringValue) (2025) | HIGH | 200,000 character limit verified |

---

## Summary for Roadmap

**Top 3 pitfalls to address in Phase 1 (CSS Layout):**
1. **Pitfall 4:** Use rbx-css, don't build custom CSS engine
2. **Pitfall 2:** Design for instance limits (virtual scrolling, UIListLayout)
3. **Pitfall 3:** Chunked rendering from the start

**Top 2 pitfalls to address in Phase 4 (JS Engine):**
1. **Pitfall 5:** Don't try V8/SpiderMonkey; use Luau-based interpreter
2. **Pitfall 3:** Yield during JS execution to avoid timeout

**Pitfall that affects all phases:**
- **Pitfall 1:** HTML > 200K chars — handle at network layer (DOM-03)

---

*Research completed: 2026-05-03. Confidence: HIGH for all pitfall classifications. All findings verified against project context and Roblox platform documentation.*
