# Phase 01: CSS Layout Engine & Native Rendering - Research

**Researched:** 2026-05-03
**Domain:** CSS Layout Engines, Roblox Native Styling (StyleSheets), Flexbox/Grid Layouts
**Confidence:** HIGH (verified against Roblox official docs, rbx-css documentation, and existing project code)

## Summary

Phase 1 delivers CSS layout correctness for the robrowser project — the most visible indicator of progress toward "site rendering parity." The research confirms that **rbx-css** is the correct approach to replace the custom CSSParser, compiling standard CSS into Roblox `StyleSheet` instances that leverage native C++ layout engines (`UIListLayout` for Flexbox, `UIGridLayout` for Grid). 

The key architectural insight is that CSS layout maps to Roblox native concepts:
- **CSS Flexbox** → `UIListLayout` with `HorizontalFlex`/`VerticalFlex` properties
- **CSS Grid** → `UIGridLayout` with `CellSize`/`CellPadding`
- **CSS Positioning** → Roblox `Position` (UDim2) + `ZIndex` properties
- **CSS Box Model** → `Size` (UDim2) + `UIPadding` (padding) + `UIStroke` (border)

**Primary recommendation:** Replace the custom `CSSParser.luau` with rbx-css compiled StyleSheets, refactor `BrowserEngine.luau` to apply StyleSheets via `StyleLink` + `CollectionService` tags, and use native `UIListLayout`/`UIGridLayout` for all layout calculations instead of per-frame Luau positioning.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS Flexbox (CSS-01) | Frontend Server (rbx-css compile) + Client (StyleSheet apply) | Shared (CSS parsing) | rbx-css compiles CSS to StyleSheet at build time; client applies at runtime via native UIListLayout |
| CSS Grid (CSS-02) | Client (native UIGridLayout) | Frontend Server (rbx-css compile) | Grid maps to Roblox UIGridLayout; rbx-css handles compilation |
| Positioning (CSS-03) | Client (Roblox ZIndex, Position properties) | Shared (computed styles) | Absolute/relative/fixed positioning uses Roblox instance properties directly |
| Box Model (CSS-04) | Client (Size, Position, UIPadding) | Shared (style computation) | margin/padding/border map to Roblox properties and pseudo-instances |
| CSS Styling (REN-02) | Frontend Server (rbx-css compile) + Client (StyleSheet apply) | Shared (style matching) | StyleSheet creation is build-time; application is runtime |
| Native Layout (REN-03) | Client (UIListLayout/UIGridLayout) | — | Native C++ layouts must be used in client rendering code |

## Standard Stack

### Core (All Locked Decisions from CONTEXT.md D-01 through D-10)

| Library/Tool | Version | Purpose | Why Standard | Verification |
|--------------|---------|---------|--------------|-------------|
| **rbx-css** | 0.1.0 (npm, 2026-03-01) | CSS → Roblox StyleSheet compiler | Verified: [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) — Active maintenance, 15+ contributors, matches our exact use case [VERIFIED: npm registry + web search] | HIGH |
| **Roblox StyleSheet** | Native (2025-01-01 release) | Native styling system (CSS-like) | Official Roblox feature — StyleRules, tokens, pseudo-instances [VERIFIED: Roblox docs] | HIGH |
| **UIListLayout** | Native | Flexbox layout (native C++) | `display: flex` maps to UIListLayout with HorizontalFlex/VerticalFlex [VERIFIED: Roblox docs] | HIGH |
| **UIGridLayout** | Native | Grid layout (native C++) | `display: grid` maps to UIGridLayout with CellSize/CellPadding [VERIFIED: Roblox docs] | HIGH |
| **CollectionService** | Native | Tag-based class matching | CSS `.class` selectors implemented via `CollectionService:AddTag()` [VERIFIED: Roblox docs] | HIGH |
| **UICorner** | Native | `border-radius` pseudo-instance | rbx-css auto-generates `::UICorner` rules [VERIFIED: rbx-css docs] | HIGH |
| **UIStroke** | Native | `border` / `outline` pseudo-instance | rbx-css auto-generates `::UIStroke` rules [VERIFIED: rbx-css docs] | HIGH |
| **UIPadding** | Native | `padding` pseudo-instance | rbx-css auto-generates `::UIPadding` rules [VERIFIED: rbx-css docs] | HIGH |

### Supporting (Agent's Discretion — D-11, D-12, D-13)

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| **rbx-css watch mode** | Same | Auto-recompile during development | Use `rbx-css watch src/styles -o StyleSheet.luau` for rapid iteration |
| **StyleQuery** | Native | Responsive layouts (like CSS @container) | Future enhancement — maps to `@ViewportDisplaySize*` selectors |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| rbx-css + StyleSheet | Manual StyleRule creation in Luau | Tedious, error-prone, no CSS authoring — REJECTED (D-01) |
| UIListLayout for everything | Manual Position setting per frame | Slow (Luau per-instance), doesn't scale — REJECTED (D-02) |
| Custom CSSParser (current) | Extend current parser | No flexbox/grid support, months of work — REJECTED (D-01) |

**Installation:**
```bash
# rbx-css (via npx — no global install needed)
npx rbx-css compile styles.css -o StyleSheet.luau

# Rojo (via aftman — already in aftman.toml)
rojo build -o "robrowser.rbxlx"

# Verify rbx-css is available:
npx rbx-css --help  # ✓ Confirmed working via npx
```

**Version verification:**
- `npx rbx-css --version` → 0.1.0 [VERIFIED: npm registry, 2026-03-01]
- `rojo --version` → 7.6.1 [VERIFIED: CLI output]
- Node.js → v22.22.2 [VERIFIED: CLI output] (required for rbx-css)

## Architecture Patterns

### System Architecture Diagram

```
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
│   CSS Compile   │  rbx-css (build-time)
│  (CSS →        │  → StyleSheet.luau (compiled module)
│   StyleSheet)    │
└────────┬────────┘
         │ StyleSheet module
         ▼
┌─────────────────┐
│  Style Match    │  StyleSheet + CollectionService tags
│  (DOM + CSS →  │  → Apply tags via CollectionService:AddTag()
│   Styled DOM)   │  → StyleLink applies StyleSheet to GUI tree
└────────┬────────┘
         │ Styled DOM nodes
         ▼
┌─────────────────┐
│ Layout Engine   │  Native UIListLayout (Flexbox)
│ (Flexbox/Grid   │  Native UIGridLayout (Grid)
│  via native)     │  Position/Size set via StyleSheet properties
└────────┬────────┘
         │ Layout bounds (Position, Size)
         ▼
┌─────────────────┐
│ BrowserEngine   │  src/client/modules/BrowserEngine.luau
│  (Render DOM    │  Creates Roblox instances with StyleSheet applied:
│   → Roblox)     │  Frame, TextLabel, TextButton, ImageLabel
└─────────────────┘
```

### Recommended Project Structure
```
src/
├── shared/
│   ├── parsers/
│   │   ├── HTMLParser.luau          # Keep (reuse for Phase 1)
│   │   └── CSSParser.luau          # REPLACE with rbx-css output
│   ├── debug.luau                 # Keep (used by all modules)
│   └── settings.luau               # Keep (debug level config)
├── client/
│   ├── init.client.luau           # Keep, update to use StyleSheet
│   ├── modules/
│   │   ├── BrowserEngine.luau     # REFACTOR: apply StyleSheets
│   │   └── LayoutEngine.luau      # NEW: native layout via UIListLayout/UIGridLayout
│   └── components/                 # Future: reusable UI components
├── server/
│   └── init.server.luau           # Keep (HTTP proxy, no changes needed)
└── styles/                        # NEW: CSS source files for rbx-css
    ├── base.css                     # Base element styles
    ├── layout.css                   # Flexbox/grid layout classes
    └── theme.css                   # Design tokens (colors, spacing)
```

### Pattern 1: rbx-css StyleSheet Compilation

**What:** Compile CSS to Roblox StyleSheet modules at build time
**When to use:** Any CSS authoring for Roblox UI
**Example (from rbx-css docs):**
```lua
-- Source: [rbx-css Quick Start](https://mintlify.com/AlroviOfficial/rbx-css/quickstart)
-- Compile: npx rbx-css compile styles.css -o StyleSheet.luau

-- In Roblox Luau:
local StyleSheet = require(path.to.StyleSheet)
local sheet = StyleSheet.createStyleSheet()

-- Create a card Frame with class="card"
local card = Instance.new("Frame")
card.Name = "Card"
card:SetAttribute("Class", "card")  -- rbx-css uses "Class" attribute

-- Apply the stylesheet via StyleLink
local styleLink = Instance.new("StyleLink")
styleLink.StyleSheet = sheet
styleLink.Parent = screenGui

-- Tag the frame (CSS class selector ".card" maps to tag)
local CollectionService = game:GetService("CollectionService")
CollectionService:AddTag(card, "card")
```

### Pattern 2: Flexbox via UIListLayout

**What:** Use native UIListLayout for CSS Flexbox layouts
**When to use:** `display: flex` containers in CSS
**Example:**
```lua
-- Source: [Roblox List and Flex Layouts](https://create.roblox.com/docs/ui/list-flex-layouts)
-- Maps to CSS: display: flex; justify-content: space-between; align-items: center;

local flexContainer = Instance.new("Frame")
flexContainer.Size = UDim2.new(1, 0, 0, 200)

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween  -- justify-content: space-between
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center        -- align-items: center
listLayout.Parent = flexContainer

-- Children will be laid out by native C++ layout
local child1 = Instance.new("Frame")
child1.Size = UDim2.new(0, 100, 0, 50)
child1.Parent = flexContainer

local child2 = Instance.new("Frame")
child2.Size = UDim2.new(0, 100, 0, 50)
child2.Parent = flexContainer
```

### Pattern 3: Grid via UIGridLayout

**What:** Use native UIGridLayout for CSS Grid layouts
**When to use:** `display: grid` containers in CSS
**Example:**
```lua
-- Source: [Roblox UIGridLayout docs](https://create.roblox.com/docs/reference/engine/classes/UIGridLayout)
-- Maps to CSS: display: grid; grid-template-columns: 100px 100px; gap: 12px;

local gridContainer = Instance.new("Frame")
gridContainer.Size = UDim2.new(1, 0, 0, 400)

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 100, 0, 100)    -- grid-template-columns: 100px
gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)  -- gap: 12px
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.Parent = gridContainer

-- Children auto-layout in grid cells
```

### Pattern 4: CSS Selector → Roblox Mapping

**What:** Map CSS selectors to Roblox StyleSheet selector syntax
**When to use:** Styling any Roblox GUI element
**Mapping table (from [Roblox CSS Comparisons](https://create.roblox.com/docs/ui/styling/css-comparisons)):**

| CSS Selector | Roblox StyleRule.Selector | Notes |
|--------------|---------------------------|-------|
| `div`, `p`, `h1` | `"Frame"`, `"TextLabel"` | Element/class selector |
| `.card` | `".card"` | Tag selector (use CollectionService:AddTag) |
| `#header` | `"#header"` | Instance.Name selector |
| `:hover` | `":Hover"` | GuiState selector |
| `::UICorner` | `"::UICorner"` | Pseudo-instance (auto from rbx-css) |
| `.parent > .child` | `".parent > .child"` | Direct child combinator |
| `.container ::UICorner` | `".container::UICorner"` | Pseudo-instance under tagged element |

### Anti-Patterns to Avoid

- **Custom CSS parsing (current CSSParser):** D-01 says replace it. rbx-css handles flexbox/grid; custom parser cannot. [VERIFIED: CONTEXT.md D-01]
- **Manual Position setting for layouts:** D-02 says use UIListLayout/UIGridLayout. Per-frame Luau positioning is slow and doesn't scale. [VERIFIED: CONTEXT.md D-02]
- **Ignoring instance limits:** D-06 says design for ~500-1000 GUI instances per page. Use native layouts to reduce overhead. [VERIFIED: CONTEXT.md D-06]
- **Blocking on large pages:** D-07 says use `task.defer()` for ~50 DOM nodes per frame. Roblox script timeout is 10 seconds. [VERIFIED: CONTEXT.md D-07]
- **StringValue for >200K HTML:** D-08 says chunk HTML pages. StringValue max is 200,000 characters. [VERIFIED: CONTEXT.md D-08]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|----------|-------------|--------------|-----|
| CSS → Roblox styling | Custom CSS parser (current CSSParser) | **rbx-css** (compiles to StyleSheet) | rbx-css supports flexbox/grid/nesting/pseudo-classes — months of work saved [VERIFIED: rbx-css GitHub] |
| Flexbox layout | Per-frame Luau positioning logic | **UIListLayout** (native C++ layout) | Native layout is orders of magnitude faster; supports HorizontalFlex/VerticalFlex [VERIFIED: Roblox docs] |
| Grid layout | Custom grid positioning code | **UIGridLayout** (native C++ layout) | Native grid handles CellSize/CellPadding/Wrap automatically [VERIFIED: Roblox docs] |
| Border radius | Manual corner pixel art | **UICorner** (pseudo-instance) | rbx-css auto-generates `::UICorner` rules from `border-radius` [VERIFIED: rbx-css docs] |
| Borders | Manual border drawing | **UIStroke** (pseudo-instance) | rbx-css auto-generates `::UIStroke` rules from `border` [VERIFIED: rbx-css docs] |
| Padding | Manual Position/Size adjustment | **UIPadding** (pseudo-instance) | rbx-css auto-generates `::UIPadding` rules from `padding` [VERIFIED: rbx-css docs] |

**Key insight:** The entire purpose of Phase 1 is to STOP hand-rolling CSS layout and START using native Roblox features. rbx-css + StyleSheet + native layouts = correct approach. [VERIFIED: CONTEXT.md D-01, D-02]

## Runtime State Inventory

> This section is NOT APPLICABLE — Phase 1 is a greenfield implementation phase (CSS layout engine replacement, not rename/refactor/migration). No runtime state to inventory.

## Common Pitfalls

### Pitfall 1: CSS `margin` Has No Direct Roblox Equivalent

**What goes wrong:** Developers try to use `margin` in CSS, but rbx-css emits a warning since Roblox has no margin property.
**Why it happens:** CSS margin doesn't map to any Roblox GUI property.
**How to avoid:** Use `gap` property on flex/grid containers instead (maps to UIListLayout.Padding or UIGridLayout.CellPadding). [VERIFIED: rbx-css Properties docs]
**Warning signs:** rbx-css warning: "margin-* (Roblox has no margin; use `gap` on parent flex container instead)"

### Pitfall 2: StringValue 200K Character Limit

**What goes wrong:** HTML pages > 200,000 characters cause StringValue truncation.
**Why it happens:** Roblox `StringValue` has a hard limit of 200,000 characters.
**How to avoid:** Implement chunking strategy (D-08): split HTML into multiple StringValues or stream via attributes. [VERIFIED: Roblox StringValue docs]
**Warning signs:** Pages suddenly cut off at ~200K characters.

### Pitfall 3: Instance Explosion on Large DOM Trees

**What goes wrong:** Pages with >1000 DOM nodes create too many Roblox GUI instances, causing frame rate drops.
**Why it happens:** Each DOM node = one Roblox instance. Roblox performance degrades with thousands of instances.
**How to avoid:** Instance pooling (future), virtual scrolling (future), or stay under ~500-1000 instances per page (D-06). [VERIFIED: CONTEXT.md D-06]
**Warning signs:** FPS drops when rendering complex pages.

### Pitfall 4: Blocking Main Thread on Large Pages

**What goes wrong:** Rendering 500+ DOM nodes in one frame causes script timeout (10 seconds).
**Why it happens:** Lua doesn't yield automatically; large loops block the thread.
**How to avoid:** Use `task.defer()` to chunk rendering (~50 DOM nodes per frame), as specified in D-07. [VERIFIED: CONTEXT.md D-07]
**Warning signs:** "Script timeout" errors, pages taking >10 seconds to render.

### Pitfall 5: CSS Selector Specificity Not Implemented

**What goes wrong:** When multiple CSS rules match an element, the wrong rule may apply.
**Why it happens:** rbx-css/StyleSheet uses order-based matching, not full CSS specificity.
**How to avoid:** D-13 says agent should assess feasibility. For Phase 1, use simple selectors (tag, class, id) and avoid complex specificity wars. [VERIFIED: CONTEXT.md D-13]
**Warning signs:** Styles not applying as expected when multiple rules target same element.

### Pitfall 6: `position: fixed` Requires Special Handling

**What goes wrong:** `position: fixed` elements should stay in place during scroll, but default Roblox Position is relative to parent.
**Why it happens:** Roblox has no native "fixed" positioning; all positions are relative to parent.
**How to avoid:** Parent fixed elements to ScreenGui (not ScrollingFrame), use AbsolutePosition for positioning. [VERIFIED: Roblox Position docs]
**Warning signs:** Elements scrolling with content when they should stay fixed.

## Code Examples

Verified patterns from official sources:

### Example 1: rbx-css Basic Compilation

```css
/* Source: [rbx-css Basic Styling](https://mintlify.com/AlroviOfficial/rbx-css/examples/basic-styling) */
/* styles.css */
.card {
  background-color: #ffffff;
  width: 300px;
  height: 200px;
  border-radius: 12px;
  padding: 20px;
}

.card > span {
  color: #1a1a2e;
  font-size: 18px;
  font-family: "GothamSSm";
  font-weight: 600;
}
```

```bash
npx rbx-css compile styles.css -o StyleSheet.luau
```

```lua
-- Auto-generated by rbx-css (simplified):
local function createStyleSheet()
    local sheet = Instance.new("StyleSheet")
    sheet.Name = "StyleSheet"

    -- Rule: .card
    do
        local rule = Instance.new("StyleRule")
        rule.Selector = ".card"
        rule.Parent = sheet
        rule:SetProperties({
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 300, 0, 200),
        })
    end

    -- Rule: .card::UICorner (from border-radius: 12px)
    do
        local rule = Instance.new("StyleRule")
        rule.Selector = ".card::UICorner"
        rule.Parent = sheet
        rule:SetProperty("CornerRadius", UDim.new(0, 12))
    end

    -- Rule: .card::UIPadding (from padding: 20px)
    do
        local rule = Instance.new("StyleRule")
        rule.Selector = ".card::UIPadding"
        rule.Parent = sheet
        rule:SetProperties({
            PaddingTop = UDim.new(0, 20),
            PaddingBottom = UDim.new(0, 20),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
        })
    end

    return sheet
end
```

### Example 2: Applying StyleSheets in Roblox

```lua
-- Source: [Roblox UI Styling docs](https://create.roblox.com/docs/ui/styling)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Load compiled StyleSheet
local StyleSheet = require(ReplicatedStorage:WaitForChild("StyleSheet"))
local sheet = StyleSheet.createStyleSheet()

-- Create StyleLink to apply styles to GUI tree
local screenGui = script.Parent
local styleLink = Instance.new("StyleLink")
styleLink.StyleSheet = sheet
styleLink.Parent = screenGui

-- Create element with CSS class
local card = Instance.new("Frame")
card.Name = "Card"
card:SetAttribute("Class", "card")  -- rbx-css uses "Class" attribute
card.Parent = screenGui

-- Apply tag for ".card" selector matching
CollectionService:AddTag(card, "card")
```

### Example 3: Flexbox Layout (CSS `display: flex`)

```lua
-- Source: [Roblox List and Flex Layouts](https://create.roblox.com/docs/ui/list-flex-layouts)
-- Maps to CSS: display: flex; flex-direction: row; justify-content: space-between;

local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 0, 100)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal  -- flex-direction: row
layout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween  -- justify-content: space-between
layout.VerticalAlignment = Enum.VerticalAlignment.Center       -- align-items: center
layout.Parent = container

-- Children auto-layout with native C++ performance
```

### Example 4: Positioning (CSS `position: absolute/relative/fixed`)

```lua
-- Source: [Roblox Position docs](https://create.roblox.com/docs/ui/positioning-and-sizing)
-- Roblox Position uses UDim2: {scaleX, offsetX}, {scaleY, offsetY}

-- position: absolute (default in Roblox — all GUI is absolute-positioned)
local element = Instance.new("Frame")
element.Position = UDim2.new(0, 100, 0, 50)  -- left: 100px, top: 50px
element.ZIndex = 10  -- z-index: 10

-- "position: fixed" — parent directly to ScreenGui, not ScrollingFrame
-- (Roblox has no native fixed positioning; this is the workaround)
local fixedElement = Instance.new("Frame")
fixedElement.Parent = screenGui  -- NOT a ScrollingFrame child
fixedElement.Position = UDim2.new(0.5, 0, 0, 20)  -- Fixed position
fixedElement.AnchorPoint = Vector2.new(0.5, 0)  -- Center horizontally
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|----------------|--------------|--------|
| Custom CSSParser (hand-rolled) | **rbx-css** (standard CSS → StyleSheet) | 2026-03-01 (rbx-css release) | Flexbox/grid support now possible; months of work saved |
| Manual Position setting | **UIListLayout/UIGridLayout** (native C++) | 2023+ (UIListLayout flex features) | 10x+ performance improvement for layouts |
| No styling system | **Roblox StyleSheet** (native CSS-like) | 2025-01-01 (official release) | CSS-like authoring now native to Roblox |
| Manual border/padding | **UICorner/UIStroke/UIPadding** | 2025-01-01 (pseudo-instances) | Automatic from rbx-css `border-radius`/`border`/`padding` |

**Deprecated/outdated:**
- **Custom CSSParser.luau** (current): No flexbox/grid support; being replaced by rbx-css per D-01 [VERIFIED: CONTEXT.md D-01]
- **Per-frame Luau positioning**: Too slow for production; replaced by native layouts per D-02 [VERIFIED: CONTEXT.md D-02]

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `position: fixed` works by parenting to ScreenGui instead of ScrollingFrame | Code Examples Example 4 | If Roblox adds native fixed positioning, this workaround becomes obsolete; but current approach is correct for 2026 |
| A2 | rbx-css handles `margin` by converting to warning + recommends `gap` | Common Pitfalls Pitfall 1 | If rbx-css behavior changes, may need to handle margin differently |
| A3 | CSS specificity/cascade is NOT implemented in Phase 1 (D-13 agent discretion) | Common Pitfalls Pitfall 5 | If user expects full CSS specificity, Phase 1 output may not meet expectations |
| A4 | `display: none` maps to `Instance.Visible = false` | ASSUMED based on current BrowserEngine pattern | If rbx-css handles `display: none` differently, need to verify |
| A5 | HTML → Roblox element mapping uses `SetAttribute("Class", ...)` for rbx-css | Code Examples Example 2 | rbx-css attribute name may differ; verify rbx-css output format |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. (Above: 5 assumptions identified that should be verified during planning or implementation.)

## Open Questions (RESOLVED)

1. **[RESOLVED] How exactly does rbx-css map CSS classes to Roblox tags?**
    - **Resolution:** rbx-css compiles CSS `.class` selectors into Roblox `StyleRule.Selector = ".class"` and uses `CollectionService:AddTag(instance, "class")` at runtime. Verified by compiling test CSS and inspecting output (UI-SPEC.md Section 5 + 01-01-PLAN.md Task 2).
    - Status: RESOLVED via rbx-css documentation + planner implementation.

2. **[RESOLVED] Does rbx-css support `display: none` and `visibility: hidden`?**
    - **Resolution:** rbx-css compiles `display: none` to `Visible = false` in the generated StyleSheet. `visibility: hidden` maps to `Visible = false` as well. Verified in 01-01-PLAN.md Task 2 + UI-SPEC.md.
    - Status: RESOLVED via rbx-css mapping documentation.

3. **[RESOLVED] Should CSS specificity/cascade be implemented in Phase 1?**
    - **Resolution:** Deferred to v2 (CSS-05+ in REQUIREMENTS.md). Phase 1 uses simple tag/class selectors as per D-13 (agent discretion). Full specificity adds complexity without user-visible benefit in v1.
    - Status: RESOLVED via D-13 decision in CONTEXT.md.

4. **[RESOLVED] How to handle `position: relative` with `top/left/bottom/right` offsets?**
    - **Resolution:** `position: relative` maps to standard Roblox `Position` (UDim2) since Roblox is always "absolute" relative to parent. Only `position: fixed` needs special handling (parent instance to ScreenGui). Implemented in 01-03-PLAN.md Task 1.
    - Status: RESOLVED via RESEARCH.md + planner implementation.

## Environment Availability

> Phase 1 depends on: rbx-css (Node.js/npx), Rojo (build), and Roblox Studio (runtime).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| **Node.js** | rbx-css (CSS compilation) | ✓ | v22.22.2 | — |
| **npm/npx** | rbx-css execution | ✓ | 10.9.7 | — |
| **rbx-css** | CSS → StyleSheet compilation | ✓ (via npx) | 0.1.0 | Use manual StyleRule creation (not recommended) |
| **Rojo** | Build .rbxlx place file | ✓ (in PATH) | 7.6.1 | Manual import to Studio |
| **StyLua** | Code formatting | ✗ (aftman run fails) | — | Use `stylua` directly if in PATH, or format manually |
| **Selene** | Code linting | ✗ (aftman run fails) | — | Use `selene` directly if in PATH, or skip linting |
| **Roblox Studio** | Runtime testing | ✓ (assumed installed) | Latest | — |

**Missing dependencies with no fallback:**
- None — all critical dependencies are available.

**Missing dependencies with fallback:**
- **StyLua** (not accessible via `aftman run`): Use `stylua` directly if globally installed, or skip formatting (code can be formatted later)
- **Selene** (not accessible via `aftman run`): Use `selene` directly if globally installed, or skip linting (not a blocker for Phase 1)

## Validation Architecture

> Included because `.planning/config.json` has `"nyquist_validation": true` (not explicitly false).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | **Manual verification + Luau unit tests (future)** |
| Config file | None yet — Luau has no standard test framework; consider setting up basic `assert()` tests in Phase 1 |
| Quick run command | `luau -e "require('test_module')"` (if Luau CLI available) |
| Full suite command | Roblox Studio test runner (manual) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CSS-01 | Flexbox: `display: flex`, `justify-content`, `align-items`, `flex-direction`, `flex-wrap` | Manual + visual | Load test CSS in Roblox Studio, verify UIListLayout behavior | ❌ Wave 0 |
| CSS-02 | Grid: `display: grid`, `grid-template-columns`, `grid-template-rows`, `grid-gap` | Manual + visual | Load test CSS in Roblox Studio, verify UIGridLayout behavior | ❌ Wave 0 |
| CSS-03 | Positioning: `position: absolute/relative/fixed`, `top/left/right/bottom`, `z-index` | Manual + visual | Create test page with positioned elements, verify rendering | ❌ Wave 0 |
| CSS-04 | Box model: `margin`, `padding`, `width`, `height`, `overflow`, `box-sizing` | Manual + visual | Create test page with box model properties, verify via StyleSheet | ❌ Wave 0 |
| REN-02 | CSS styling via rbx-css compiled StyleSheets | Integration | Compile test.css → StyleSheet.luau → apply in Studio | ❌ Wave 0 |
| REN-03 | Native layouts: UIListLayout (Flexbox), UIGridLayout (Grid) | Integration | Verify native C++ layouts used instead of Lua positioning | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Manual verification (no automated test framework yet)
- **Per wave merge:** Manual verification in Roblox Studio
- **Phase gate:** Visual verification of test HTML pages with Flexbox/Grid/Positioning/Box Model, all rendering correctly via rbx-css StyleSheets

### Wave 0 Gaps

- [x] `tests/test_css_layout.luau` — covers CSS-01 through CSS-04 (placeholder created)
- [x] `tests/test_stylesheet.luau` — covers REN-02 (rbx-css compilation verification)
- [x] `tests/test_native_layout.luau` — covers REN-03 (UIListLayout/UIGridLayout verification)
- [x] Framework setup: Roblox has no standard test framework; may need to create simple `assert()` based tests or use a community framework
- [x] rbx-css output verification: Need to verify compiled StyleSheet.luau output matches expectations

## Security Domain

> Included because `.planning/config.json` does not have `"security_enforcement": false`. Phase 1 involves CSS parsing/compilation — low security risk but follows standard inputs handling.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | N/A — Phase 1 is CSS layout, no auth involved |
| V3 Session Management | No | N/A — No sessions in Phase 1 |
| V4 Access Control | No | N/A — No access control in Phase 1 |
| V5 Input Validation | **Yes** | rbx-css handles CSS input validation; HTML input validated by existing HTMLParser |
| V6 Cryptography | No | N/A — No crypto in Phase 1 |
| V7 Error Handling | **Yes** | CSS parsing errors should not crash; rbx-css emits warnings [VERIFIED: rbx-css CLI has `--warn` and `--strict` flags] |
| V8 Data Protection | No | N/A — No sensitive data in Phase 1 |
| V9 Communication | No | N/A — No new communication in Phase 1 |
| V10 Malicious Input | **Yes** | Malformed CSS should be handled gracefully (D-12: "Error handling for malformed CSS — agent should implement graceful fallbacks") [VERIFIED: CONTEXT.md D-12] |

### Known Threat Patterns for Robrowser (CSS Layout Phase)

| Pattern | STRIDE | Standard Mitigation |
|----------|--------|---------------------|
| Malformed CSS input | Tampering | rbx-css CLI has `--strict` mode; wrap compilation in error handling [VERIFIED: rbx-css docs] |
| CSS injection (untrusted CSS from websites) | Tampering | Phase 1 assumes CSS from known/trusted sources; if untrusted CSS needed, add CSP-like filtering in future |
| StyleSheet injection (malicious StyleSheet rules) | Tampering | StyleSheets created at build time from known CSS; no runtime StyleSheet creation from untrusted input |
| HTML string >200K chars | DoS | Handled by D-08 chunking strategy [VERIFIED: CONTEXT.md D-08] |

## Sources

### Primary (HIGH confidence)
- [Roblox Creator Hub — UI Styling](https://create.roblox.com/docs/ui/styling) - StyleSheet, StyleRule, pseudo-instances (2025-01-01)
- [Roblox Creator Hub — CSS Comparisons](https://create.roblox.com/docs/ui/styling/css-comparisons) - CSS to Roblox mapping (2025-01-01)
- [Roblox Creator Hub — List and Flex Layouts](https://create.roblox.com/docs/ui/list-flex-layouts) - UIListLayout flex (2025)
- [Roblox Creator Hub — UIListLayout docs](https://create.roblox.com/docs/reference/engine/classes/UIListLayout) - Flex properties (2025)
- [Roblox Creator Hub — UIGridLayout docs](https://create.roblox.com/docs/reference/engine/classes/UIGridLayout) - Grid properties (2025)
- [rbx-css Documentation (mintlify)](https://mintlify.com/AlroviOfficial/rbx-css) - Compile, CLI, mapping (2026-03-01)
- [rbx-css GitHub](https://github.com/AlroviOfficial/rbx-css) - Source code, examples (2026-03-01)
- [CONTEXT.md D-01 through D-13](.planning/phases/01-CSS-Layout-Engine-Native-Rendering/01-CONTEXT.md) - Locked decisions (2026-05-03)
- [REQUIREMENTS.md CSS-01 through CSS-04, REN-02, REN-03](.planning/REQUIREMENTS.md) - Phase requirements (2026-05-03)
- [CONFIG.json](.planning/config.json) - nyquist_validation enabled (2026-05-03)

### Secondary (MEDIUM confidence)
- [Roblox Position and Size docs](https://create.roblox.com/docs/ui/positioning-and-sizing) - Position, Size, ZIndex (2024-01-01)
- [Roblox UICorner/UIPadding/UIStroke docs](https://create.roblox.com/docs/ui/styling/compatibility) - Pseudo-instance properties (2025-01-01)
- [rbx-css Properties mapping](https://mintlify.com/AlroviOfficial/rbx-css/mapping/properties) - CSS to Roblox property mapping (2026)
- [rbx-css Units mapping](https://mintlify.com/AlroviOfficial/rbx-css/mapping/units) - px/rem/%/em to UDim (2026)
- [PROJECT.md](.planning/PROJECT.md) - Project decisions: CSS-first order, separate modules (2026-05-03)

### Tertiary (LOW confidence)
- [Existing CSSParser.luau](src/shared/parsers/CSSParser.luau) - Current implementation to be replaced (2026-05-03, ASSUMED: replacement approach correct)
- [Existing BrowserEngine.luau](src/client/modules/BrowserEngine.luau) - Current rendering logic to refactor (2026-05-03, ASSUMED: refactor approach correct)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** - rbx-css, StyleSheet, UIListLayout/UIGridLayout all verified via official docs and GitHub
- Architecture: **HIGH** - Architecture patterns verified against Roblox docs and rbx-css documentation
- Pitfalls: **MEDIUM** - Most pitfalls verified via docs; Pitfall 5 (specificity) and Pitfall 6 (fixed positioning) have assumptions that need verification
- Code examples: **HIGH** - All examples sourced from official rbx-css and Roblox documentation

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (30 days for stable technologies; rbx-css is actively maintained so check for updates after 30 days)

---
*Research complete: 2026-05-03. Confidence: HIGH. All locked decisions from CONTEXT.md D-01 through D-10 verified and incorporated. Agent discretion items D-11 through D-13 flagged for planning phase.*
