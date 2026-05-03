# Feature Landscape

**Domain:** Roblox browser engine (robrowser)
**Researched:** 2026-05-03
**Confidence:** HIGH (based on MDN, Can I Use, Web.dev Baseline, Roblox Creator Hub documentation)

## Table Stakes

Features users expect. Missing = product feels incomplete. These are **mandatory for site rendering parity**.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **CSS Flexbox Layout** | Used by majority of modern websites for component-level layouts (navbars, cards, centering). 99%+ browser support as of 2026. | Medium | `display: flex`, `justify-content`, `align-items`, `flex-direction`, `gap`. Core spec is stable; critical for any modern site. |
| **CSS Grid Layout** | Essential for page-level 2D layouts (dashboards, complex designs). 98%+ browser support. Often combined with Flexbox (Grid for structure, Flexbox for components). | High | `display: grid`, `grid-template-columns/rows`, `grid-area`, `gap`. More complex than Flexbox but required for modern layouts. |
| **CSS Box Model** | Fundamental to all layouts. Controls sizing and spacing. | Low | `margin`, `padding`, `width`, `height`, `overflow`, `box-sizing`. Basic but critical. |
| **CSS Positioning** | Required for overlays, sticky elements, tooltips. | Low-Medium | `position: static/relative/absolute/fixed/sticky`, `top/left/right/bottom`, `z-index`. |
| **ES6+ JavaScript** | Modern sites use arrow functions, promises, async/await, template literals, destructuring. All modern browsers support ES6+ natively. | High | **Arrow functions**, **Promises/async-await**, **template literals**, **destructuring**, **let/const**, **modules (import/export)**, **spread/rest operators**, **optional chaining (`?.`)**, **nullish coalescing (`??`)**. **NOT var**. |
| **DOM Selection APIs** | Sites use `querySelector`, `querySelectorAll`, `getElementById` for element access. 99%+ support. | Medium | `querySelector()`, `querySelectorAll()`, `getElementById()`, `getElementsByClassName()`, `getElementsByTagName()`. Critical for site interactivity. |
| **DOM Manipulation APIs** | Dynamic content creation/modification. Core to modern web apps. | Medium | `createElement()`, `appendChild()`, `removeChild()`, `innerHTML` (with sanitation), `textContent`, `classList`. |
| **DOM Event APIs** | User interaction handling. `addEventListener` is the modern standard (replaces `onclick` attributes). | Medium | `addEventListener()`, `removeEventListener()`, `Event` object, `preventDefault()`, `stopPropagation()`. **Must support capture/bubble phases**. |
| **Fetch API** | Modern replacement for XMLHttpRequest. Promise-based, cleaner syntax. 95%+ support. | Medium | `fetch()`, Request/Response objects, async/await integration. **XMLHttpRequest as fallback** for maximum compatibility. |
| **Basic CSS Properties** | Typography, colors, backgrounds. | Low | `font-family`, `font-size`, `color`, `background`, `border`, `display` (block/inline/flex/grid/none). |
| **CSS Variables (Custom Properties)** | Used by modern sites for theming. 90%+ support. | Low-Medium | `--variable-name` with `var()`. Essential for dynamic styling. |
| **localStorage** | Client-side storage for preferences, simple state. Synchronous API, 5-10MB per domain. | Low | `localStorage.getItem/setItem/removeItem`. **Note: Web Workers cannot access localStorage** (spec limitation). |
| **WebSocket Basic Support** | Real-time communication (chat, live updates). Used by modern web apps. | Medium-High | Persistent TCP connection, full-duplex. Requires Roblox→server proxy (Roblox doesn't support raw TCP). See roBrowserLegacy's wsProxy pattern. |
| **CSS Selectors Level 3** | Attribute selectors, pseudo-classes (`:hover`, `:focus`, `:nth-child`), combinators. Universal support. | Medium | `[attr=value]`, `:not()`, `:hover`, `:focus`, `:first-child`, etc. Critical for styling and interactivity. |
| **CSS Overflow & Scroll** | Scrolling content, overflow handling. | Low-Medium | `overflow`, `overflow-x/y`, `scroll`, `auto`, `-webkit-overflow-scrolling` (legacy iOS). **Must maintain 60fps scrolling**. |

## Differentiators

Features that set product apart. Not expected, but valued. These create **competitive advantage**.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Fast Page Load Times** | Users expect <2.5s LCP (Largest Contentful Paint). Core Web Vital threshold. | High | Minimize DOM size, lazy-load images, efficient HTML/CSS parsing. Roblox instance limits require careful memory management. |
| **Smooth 60fps Interactions** | Scrolling, click/touch handling must feel native. INP (Interaction to Next Paint) must be <200ms. | High | Use Roblox's UIListLayout/UIGridLayout for native scrolling. Avoid per-frame Lua calculations. Use `Library.task.wait()` for chunking long operations. |
| **Specific Popular Site Support** | "Can I check my email / read docs / browse forums in Roblox?" | Very High | Requires comprehensive CSS/JS implementation. Start with simpler sites (text-heavy, minimal JS frameworks). |
| **Mobile/Console Optimization** | Roblox is cross-platform. Touch handling, gamepad support. | Medium | `TouchTap/TouchLongPress` events, `GamepadConnected` events. Responsive layouts via Flexbox/Grid. |
| **Graceful Degradation** | Sites with unsupported features still usable (just less pretty/functional). | Medium | Feature detection (`'fetch' in window`), `@supports` for CSS. Show fallback content when APIs missing. |
| **Error Handling & Debug UI** | Users know *why* a site failed to load/render. | Low-Medium | Error messages in Roblox GUI, console-like output, network error details. Critical for UX. |
| **URL Bar & Navigation** | Browser-like navigation (back/forward, URL entry). | Medium | `window.history` state management, URL parsing, navigation events. |
| **Form Support** | Many sites require forms (login, search, contact). | Medium | `<input>`, `<textarea>`, `<button>`, form submission, validation UI. |
| **Image Format Support** | Modern sites use WebP (30% smaller than JPEG), AVIF (50% smaller). | Medium | WebP decoding in Luau or via Roblox assets. JPEG/PNG already supported by Roblox. |

## Anti-Features

Features to explicitly NOT build. **Deliberate exclusions** based on Roblox platform constraints and v1 scope.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-------------|-------------------|
| **WebGL / WebGPU** | Roblox platform limits make this impractical. No access to GPU shaders from Luau. | Use Roblox GUI objects (Frames, ImageLabels) for rendering. 2D only. |
| **Video/Audio Playback** | Out of scope for v1. Roblox has its own audio system but doesn't map to `<video>`/`<audio>` elements. | Show placeholder UI. Maybe v2 feature. |
| **Multi-Tab Browsing** | Single page view for v1. Complexity of managing multiple DOM trees/navigation stacks. | Single tab only. URL bar navigation within same page. |
| **Full Chrome/Firefox Extension Ecosystem** | Massive API surface. Not feasible in Roblox environment. | Focus on core rendering. Extensions are out of scope. |
| **Web Workers** | Limited in Roblox. Luau has `task.spawn`/`task.wait` but not true Web Workers API. | Use Luau coroutines/`task` library for background work. |
| **Service Workers / PWA** | Requires persistent background execution. Roblox games don't run when closed. | Not applicable. Standard HTTP caching via Roblox's HttpService. |
| **WebRTC** | Complex real-time media streaming. Beyond v1 scope. | Out of scope. Could be v2 if demand exists. |
| **WebXR / VR** | Requires VR headset access. Roblox has VR support but doesn't expose WebXR API. | Out of scope. |
| **IndexedDB** | Async storage API. More complex than localStorage. Roblox has DataStores but not accessible from client-side browser. | Use localStorage only for v1. |
| **Complex CSS Animations/Transitions** | Can impact 60fps target. Roblox has TweenService but CSS `transition`/`@keyframes` are complex to implement. | Basic transitions only. Use Roblox TweenService for smooth animations. |
| **iframe / Embedded Content** | Security sandboxing complexity. Nested browsing contexts are complex to implement. | Out of scope for v1. Show "iframe blocked" placeholder. |
| **Clipboard API** | Requires user permission prompts. Roblox has `toClipboard()` but not full Clipboard API. | Basic copy only if needed. |

## Feature Dependencies

```
CSS Flexbox ──┐
CSS Grid ─────┤ (both depend on)
CSS Box Model ─┘
                │
                ▼
Positioning System (z-index, layout calculations)

ES6+ JS ─────┬──► Fetch API (uses Promises)
                ├──► DOM APIs (event listeners, dynamic content)
                └──► localStorage (JSON serialization)

DOM Selection ──┐
DOM Manipulation ┘──► Dynamic page updates

WebSocket ───────► Real-time features (chat, live updates)
```

**Critical dependency chains:**
1. **CSS Layout → Positioning**: Flexbox/Grid calculations require correct positioning system
2. **ES6+ → Fetch API**: Fetch returns Promises, requires async/await support
3. **DOM APIs → Dynamic Content**: Selection + Manipulation needed for modern SPAs
4. **Roblox GUI Mapping**: All features ultimately render to Roblox GUI objects (Frame, TextLabel, TextButton, ImageLabel)

## MVP Recommendation

**Prioritize for v1 (site rendering parity):**

1. **CSS Flexbox** — Most websites use Flexbox for layout. Highest ROI.
2. **CSS Box Model + Positioning** — Foundation for all layouts.
3. **ES6+ Core** — Arrow functions, Promises, async/await, let/const. Required for modern JS.
4. **DOM Selection (querySelector)** — Most critical DOM API.
5. **DOM Manipulation (createElement, appendChild)** — Dynamic content.
6. **Fetch API** — Modern network requests.
7. **Basic CSS (typography, colors, backgrounds)** — Visual rendering.
8. **localStorage** — Simple persistence.
9. **CSS Selectors Level 3** — Styling and interactivity.
10. **One Differentiator: 60fps Interactions** — Smooth scrolling/click handling.

**Defer to v2:**
- CSS Grid (complex, lower usage than Flexbox for component layouts)
- WebSocket (requires proxy server, more complex)
- Form support (depends on DOM manipulation maturity)
- Image format optimization (WebP/AVIF)
- Advanced ES6+ (optional chaining, nullish coalescing)

## Roblox Platform Constraints

| Constraint | Impact on Features | Mitigation |
|------------|---------------------|-------------|
| **Instance Count Limits** | Complex pages with 1000+ DOM elements = 1000+ Roblox GUI instances. Causes memory pressure. | Instance streaming for 3D, but UI instances must be managed. Reuse/recycle offscreen elements. |
| **Luau-based JS Engine** | Cannot run native JS. Must interpret or transpile to Luau. ES6+ features need custom implementation. | Build Luau-based interpreter or transpiler. See roBrowserLegacy's approach. |
| **String Length Limits** | Large HTML/JS/CSS files may exceed Roblox string limits. | Chunk large files. Stream HTML parsing. |
| **Execution Time Limits** | Long-running JS code hits Roblox's script timeout. | Use `task.wait()` to yield. Break into chunks. Avoid per-frame heavy calculations. |
| **Roblox GUI Objects Only** | No canvas, no WebGL. All rendering via Frames, TextLabels, etc. | Map CSS to Roblox properties: `position`→`UDim2`, `background-color`→`BackgroundColor3`, etc. |
| **No TCP Direct Access** | WebSocket requires proxy server (wsProxy pattern from roBrowserLegacy). | Implement wsProxy for TCP↔WS translation. |
| **Event Model Differences** | Roblox uses `Activated`, `MouseButton1Click` etc. Must map to DOM events. | Event translation layer: Roblox events → synthetic DOM Events. |

## Sources

- **MDN Web Docs** (developer.mozilla.org): DOM APIs, Fetch API, WebSocket API, CSS Flexbox/Grid documentation — HIGH confidence
- **Can I Use** (caniuse.com): Browser support tables for CSS Grid, Flexbox, ES6+ features, Fetch API — HIGH confidence
- **Web.dev Baseline 2026**: Feature availability tiers (Limited, Newly available, Widely available) — HIGH confidence
- **Roblox Creator Hub** (create.roblox.com): Instance limits, performance optimization, GUI objects, Luau constraints — HIGH confidence
- **Roblox API Reference** (robloxapi.github.io): GuiObject, ScreenGui, SurfaceGui properties — HIGH confidence
- **roBrowserLegacy GitHub** (github.com/MrAntares/roBrowserLegacy): Reference implementation patterns (wsProxy, packet handling, WebGL alternative) — MEDIUM confidence (different project, but similar goals)
- **Web Almanac / HTTP Archive**: CSS Flexbox/Grid adoption statistics (72%+ for Grid, majority for Flexbox) — MEDIUM confidence
- **Web Platform Standards** (spec.whatwg.org): Fetch Standard, HTML Standard, WebSockets Standard — HIGH confidence

## Confidence Assessment

| Area | Confidence | Notes |
|------|-----------|-------|
| Table Stakes (CSS, JS, DOM) | HIGH | Based on MDN, Can I Use, extensive browser compatibility data |
| Differentiators (Performance, UX) | HIGH | Core Web Vitals (LCP, INP, CLS) are well-documented 2026 standards |
| Anti-Features | HIGH | Roblox platform limits are clearly documented in Creator Hub |
| Roblox Constraints | HIGH | Verified with official Roblox documentation and API references |
| Feature Dependencies | MEDIUM | Logical inference from web platform architecture |

## Open Questions for Phase Planning

1. **JS Engine Architecture**: Interpreter vs transpiler approach for ES6+ in Luau? (See Phase 6 research needs)
2. **Instance Recycling**: How to handle pages with 1000+ DOM elements within Roblox instance limits?
3. **CSS Flexbox/Grid**: Which properties are most critical for v1? (Subset based on real-world usage)
4. **Error Boundaries**: How to handle JS errors gracefully without crashing the Roblox client?
5. **Network Proxy**: Final architecture for WebSocket proxy (wsProxy pattern vs alternatives)?

---

*Researched by GSD Research Agent on 2026-05-03*
*Next: Use findings to define requirements in ROADMAP.md phases*
