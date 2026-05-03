# Architecture Patterns

**Domain:** Roblox browser engine (renders websites inside Roblox using Luau)
**Researched:** 2026-05-03
**Confidence:** HIGH (verified against existing project code, Roblox docs, and real-world implementations)

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     robrowser Architecture                     │
└─────────────────────────────────────────────────────────────────┘

        User enters URL
              │
              ▼
    ┌─────────────────┐
    │   Client Entry   │  src/client/init.client.luau
    │  (LocalScript)   │  Sets up UI, handles input
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │   FetchHTML     │  RemoteFunction → Server
    │  (Server Proxy) │  Server: HttpService:GetAsync()
    └────────┬────────┘
             │ HTML string returned
             ▼
    ┌─────────────────┐
    │   HTML Parser   │  src/shared/parsers/HTMLParser.luau
    │  (Tokenize →    │  → DOM Tree (ElementNode/TextNode)
    │   DOM Tree)     │
    └────────┬────────┘
             │ DOM tree
             ▼
    ┌─────────────────┐
    │   CSS Parser    │  src/shared/parsers/CSSParser.luau
    │  (Extract →    │  → StyleMap {selector → declarations}
    │  StyleMap)      │  Also parses inline styles
    └────────┬────────┘
             │ StyleMap
             ▼
    ┌─────────────────┐
    │  Style Match    │  CSSParser.matchElement(element, styleMap)
    │  (DOM + CSS →  │  → Computed styles per element
    │  Computed)      │
    └────────┬────────┘
             │ Computed styles
             ▼
    ┌─────────────────┐
    │ Layout Engine   │  src/client/modules/LayoutEngine.luau
    │ (Box Model +    │  Calculates position/size for each DOM node
    │  Flexbox/Grid) │  Using Roblox UDim2 properties
    └────────┬────────┘
             │ Layout bounds (Position, Size)
             ▼
    ┌─────────────────┐
    │ BrowserEngine   │  src/client/modules/BrowserEngine.luau
    │  (Render DOM    │  Creates Roblox instances:
    │   → Roblox)     │  Frame, TextLabel, TextButton, etc.
    └────────┬────────┘
             │ Roblox GUI objects
             ▼
    ┌─────────────────┐
    │   JS Engine     │  src/shared/js/ (future)
    │  (Execute JS    │  Luau-based interpreter or transpiler
    │   in Luau)      │  Handles DOM APIs, events
    └─────────────────┘
```

### Component Boundaries

| Component | Location | Responsibility | Communicates With |
|-----------|----------|-----------------|-------------------|
| **Client Entry** | `src/client/init.client.luau` | URL input, navigation, UI setup | FetchHTML (server), BrowserEngine |
| **Server Proxy** | `src/server/init.server.luau` | HTTP requests via HttpService | Client (RemoteFunction) |
| **HTML Parser** | `src/shared/parsers/HTMLParser.luau` | HTML → DOM tree | Used by Client, CSS Parser (inline styles) |
| **CSS Parser** | `src/shared/parsers/CSSParser.luau` | CSS → StyleMap | Used by Client (matchElement) |
| **Layout Engine** | `src/client/modules/LayoutEngine.luau` | Computed styles → Position/Size | BrowserEngine, CSS Parser |
| **BrowserEngine** | `src/client/modules/BrowserEngine.luau` | DOM → Roblox GUI objects | Layout Engine, JS Engine (events) |
| **JS Engine** | `src/shared/js/JSEngine.luau` | Execute JavaScript in Luau | DOM (querySelector, etc.), BrowserEngine (events) |
| **DOM APIs** | `src/shared/dom/DOMAPI.luau` | querySelector, addEventListener, etc. | JS Engine, BrowserEngine |

### Data Flow

```
1. User enters URL → Client Entry
2. Client Entry → FetchHTML RemoteFunction → Server Proxy
3. Server Proxy → HttpService:GetAsync(url) → HTML string
4. HTML string → HTMLParser.parse() → DOM Tree
5. DOM Tree traversal → extract <style>/inline CSS → CSSParser.parse() → StyleMap
6. DOM Tree + StyleMap → CSSParser.matchElement() per node → Computed Styles
7. Computed Styles → LayoutEngine.calculate() → Position + Size per node
8. Layout + DOM → BrowserEngine.render() → Create Roblox instances:
   - ElementNode (div, p, h1, etc.) → Frame / TextLabel / TextButton / etc.
   - Apply Position (UDim2), Size (UDim2), BackgroundColor3, etc.
   - Handle scrolling via ScrollingFrame
9. JS Engine (future) → Executes <script> content → DOM APIs → Modify DOM → Re-render
```

## Patterns to Follow

### Pattern 1: Standard Browser Pipeline
**What:** Replicate the standard browser rendering pipeline (HTML → DOM → CSSOM → Layout → Paint) adapted for Roblox
**When:** Building any web rendering system
**Why:** Predictable data flow, matches web standards, easier to debug

```lua
-- Conceptual data flow
local html = fetchUrl(url)
local dom = HTMLParser.parse(html)
local styleMap = CSSParser.parse(extractCSS(html))
local computed = computeStyles(dom, styleMap)
local layout = LayoutEngine.calculate(computed)
BrowserEngine.render(layout, screenGui)
```

### Pattern 2: HTML→Roblox Element Mapping
**What:** Map HTML elements to Roblox GUI classes consistently
**When:** Rendering DOM nodes as Roblox instances
**Why:** Established convention from rbx-css and rbx-tsx projects

| HTML Element | Roblox Class | Notes |
|-------------|--------------|-------|
| `div`, `nav`, `header`, `footer`, `main`, `section`, `article`, `aside` | `Frame` | Container elements |
| `span`, `p`, `h1`–`h6`, `label`, `td`, `th` | `TextLabel` | Text display elements |
| `button`, `a`, `summary` | `TextButton` | Interactive elements |
| `input`, `textarea` | `TextBox` | Input elements |
| `img` | `ImageLabel` | Image elements |
| `scroll` container | `ScrollingFrame` | Scrollable containers |
| `canvas` | `ViewportFrame` | 2D canvas (limited) |

### Pattern 3: Separate Shared/Client/Server Modules
**What:** Use Roblox's ModuleScript architecture with clear separation
**When:** Organizing browser engine code
**Why:** Reuse parsers across client/server, isolate rendering to client

- **Shared:** Parsers, utilities, DOM types, JS engine (pure logic, no Roblox instances)
- **Client:** Rendering, layout, UI events, navigation
- **Server:** HTTP proxy only

### Pattern 4: CSS Property → Roblox Mapping
**What:** Convert CSS properties to Roblox instance properties
**When:** Applying computed styles to Roblox GUI objects
**Why:** CSS and Roblox have different property models

| CSS Property | Roblox Property | Pseudo-Instance |
|-------------|-----------------|---------------|
| `background-color` | `BackgroundColor3` | - |
| `color` (text) | `TextColor3` | - |
| `font-size` | `TextSize` | - |
| `border-radius` | - | `UICorner.CornerRadius` |
| `border` | - | `UIStroke` |
| `padding` | - | `UIPadding` |
| `display: flex` | - | `UIListLayout` (with flex props) |
| `display: grid` | - | `UIGridLayout` |
| `width`, `height` | `Size` (UDim2) | - |
| `margin` | `Position` offset | - |
| `z-index` | `ZIndex` | - |

## Anti-Patterns to Avoid

### Anti-Pattern 1: Monolithic Render Function
**What:** Single function that parses HTML, computes styles, and creates all Roblox instances
**Why bad:** Hard to debug, can't optimize individual stages, doesn't match browser architecture
**Instead:** Separate into pipeline stages (parse → style → layout → render)

### Anti-Pattern 2: Creating Instances During Parsing
**What:** Creating Roblox instances while parsing HTML
**Why bad:** Parser should be pure (shared module), instances only created during render phase
**Instead:** Parse → DOM tree → render phase creates instances

### Anti-Pattern 3: Blocking on Large Pages
**What:** Rendering entire page in single frame/update
**Why bad:** Roblox has 10-second script timeout; large pages will hang or crash
**Instead:** Chunk rendering, use `task.defer()` or coroutines for large DOM trees

### Anti-Pattern 4: Ignoring Roblox Instance Limits
**What:** Creating one Roblox instance per DOM node without limits
**Why bad:** Roblox has instance count limits; large pages exceed them
**Instead:** Virtual scrolling, instance pooling, or simplify DOM for large pages

## Scalability Considerations

| Concern | At 10 pages | At 100 pages | At 1000+ pages |
|---------|--------------|----------------|-------------------|
| **DOM tree size** | ~100 nodes/page | ~1000 nodes (manageable) | ~10K nodes (need virtual scrolling) |
| **Instance count** | ~120 instances/page | ~1200 instances | ~12K instances (approaching limits) |
| **CSS matching** | Fast (small StyleMap) | Slower (more rules) | Need indexed StyleMap |
| **Layout calculation** | <16ms (one frame) | ~50ms (3 frames) | Need incremental layout |
| **JS execution** | Simple scripts OK | Complex scripts slow | Need optimized JS engine |

### Performance Strategies

1. **Incremental Rendering:** Render above-fold content first, defer below-fold
2. **Instance Pooling:** Reuse Roblox instances when navigating between pages
3. **CSS Indexing:** Build indexed StyleMap for O(1) selector matching
4. **Layout Caching:** Cache layout for unchanged DOM subtrees
5. **Chunked Processing:** Use `task.wait()` between processing chunks to avoid timeout

## Build Order Recommendations

Based on dependencies analysis, recommended build order:

```
Phase 1: CSS-01, CSS-02, CSS-03, CSS-04 (CSS Layout Engine)
   │
   ├─ Dependencies: HTML Parser (✓ exists), CSS Parser (✓ exists)
   ├─ Why first: Visual layout is most visible; fixes deliver immediate user value
   └─ Output: LayoutEngine module with Flexbox, Grid, positioning, box model

Phase 2: DOM-01, DOM-02 (DOM APIs)
   │
   ├─ Dependencies: HTML Parser (✓ exists), Layout Engine (Phase 1)
   ├─ Why: Enables dynamic content manipulation after rendering
   └─ Output: DOMAPI module with querySelector, createElement, etc.

Phase 3: DOM-03, API-01 (Network & Web APIs)
   │
   ├─ Dependencies: Server proxy (✓ exists), DOM APIs (Phase 2)
   ├─ Why: Fetch API enables dynamic content loading
   └─ Output: Extended DOM APIs with Fetch, XMLHttpRequest, localStorage

Phase 4: JS-01 (Modern JS Engine)
   │
   ├─ Dependencies: DOM APIs (Phase 2), all previous phases
   ├─ Why: Complex, must handle DOM APIs; build after stable DOM
   └─ Output: JSEngine module (interpreter or transpiler)

Phase 5: PERF-01, PERF-02 (Performance Optimization)
   │
   ├─ Dependencies: All previous phases complete
   ├─ Why: Measure and optimize based on real usage patterns
   └─ Output: Chunked rendering, instance pooling, layout caching
```

### Dependency Graph

```
HTML Parser ──────┐
                   ├─→ DOM Tree ──→ DOM APIs ──→ JS Engine
CSS Parser ──────┘       │              │
   │                      │              │
   ▼                      ▼              ▼
StyleMap ──────→ Computed Styles ──→ Layout Engine ──→ BrowserEngine (render)
                   │                        │
                   └────────────────────────┘
                            │
                            ▼
                   Roblox GUI Instances
```

## Roblox-Specific Constraints

### Instance Limits
- **Max instances per game:** ~100,000 (but performance degrades much earlier)
- **Recommended max per page:** ~500-1000 instances
- **Strategy:** Virtual scrolling for large pages, simplify DOM

### Execution Limits
- **Max script time:** 10 seconds in Studio, less on production
- **Strategy:** Use `task.defer()`, coroutines, chunk processing

### HTTP Limits
- **Client cannot make HTTP requests directly** → Must use Server proxy
- **HttpService must be enabled** → Configure in game settings
- **URL validation recommended** → Whitelist/blacklist patterns

### String Limits
- **Max string length:** ~2^30 characters (effectively unlimited for web pages)
- **Practical limit:** Process large HTML in chunks

## Sources

- **Project codebase:** `src/shared/parsers/HTMLParser.luau`, `src/shared/parsers/CSSParser.luau`, `src/client/modules/BrowserEngine.luau`
- **Roblox Documentation:** [CSS Comparisons](https://create.roblox.com/docs/ui/styling/css-comparisons), [UI Styling](https://create.roblox.com/docs/ui/styling)
- **Browser Architecture References:**
  - [MDN: How browsers work](https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/How_browsers_work)
  - [Browser Rendering Pipeline](https://www.webperf.tips/tip/browser-rendering-pipeline/)
  - [go-browser architecture](https://github.com/Jyotishmoy12/go-browser)
- **Existing Roblox Browser Projects:**
  - [rbx-css](https://github.com/AlroviOfficial/rbx-css) - CSS to Roblox StyleSheet compiler
  - [rbx-tsx Element Mapping](https://www.mintlify.com/AlroviOfficial/rbx-tsx/guides/element-mapping)
  - [react-lua Internal Architecture](https://deepwiki.com/Roblox/react-lua/8.6-internal-architecture-deep-dive)
- **Roblox Instance Docs:** [Frame](https://create.roblox.com/docs/reference/engine/classes/Frame), [TextLabel](https://create.roblox.com/docs/reference/engine/classes/TextLabel)

---

*Research confidence: HIGH - Based on project code analysis, official Roblox docs, and multiple real-world implementations*
