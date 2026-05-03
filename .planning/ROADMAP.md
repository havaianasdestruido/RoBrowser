# Roadmap: robrowser

**Project:** robrowser
**Core Value:** Site rendering parity — any website loads and displays with correct layout and behavior inside Roblox
**Granularity:** Fine (8-12 phases)
**Created:** 2026-05-03

## Phases

- [ ] **Phase 1: CSS Layout Engine & Native Rendering** - CSS Flexbox, Grid, Positioning, Box Model + rbx-css integration + native layouts
- [ ] **Phase 2: DOM Selection & Manipulation** - querySelector, getElementById, createElement, appendChild, removeChild, innerHTML
- [ ] **Phase 3: DOM Properties & Events** - classList, attributes, dataset, style access, addEventListener, removeEventListener
- [ ] **Phase 4: Web APIs - Network & Storage** - Fetch API (GET/POST), localStorage (getItem/setItem/removeItem)
- [ ] **Phase 5: Web APIs - Real-time Communication** - WebSocket (connect, send, onmessage, onopen, onclose)
- [ ] **Phase 6: JavaScript Engine** - ES5 subset, ES6+ features (arrow functions, let/const, template literals, destructuring), Promises, async/await
- [ ] **Phase 7: Performance - Load Time** - Fast page load (<2.5s LCP), incremental rendering (chunked with task.defer())
- [ ] **Phase 8: Performance - Runtime** - Smooth 60fps interactions, instance pooling/recycling (stay under ~1000 GUI instances)
- [ ] **Phase 9: Integration & Validation** - HTML parsing/rendering validation, cross-phase integration testing

## Phase Details

### Phase 1: CSS Layout Engine & Native Rendering
**Goal**: Users see websites with correct CSS layout (Flexbox, Grid, positioning, box model) rendered via Roblox native GUI objects using rbx-css compiled StyleSheets.

**Depends on**: Nothing (foundation phase)

**Requirements**: CSS-01, CSS-02, CSS-03, CSS-04, REN-02, REN-03

**Success Criteria** (what must be TRUE):
1. User can navigate to a website using CSS Flexbox and see elements correctly positioned (display: flex, justify-content, align-items, flex-direction, flex-wrap all work)
2. User can navigate to a website using CSS Grid and see grid items in correct positions (grid-template-columns, grid-template-rows, grid-area, grid-gap all work)
3. User can see elements with position:absolute/relative/fixed at correct positions with proper z-index stacking
4. User can see proper box model rendering (margin, padding, width, height, overflow: hidden/scroll/auto all work)
5. CSS styles are applied via rbx-css compiled Roblox StyleSheets (replacing custom CSSParser), with native UIListLayout for Flexbox and UIGridLayout for Grid

**Plans**: 6 plans

**Plan list**:
- [ ] 01-01-PLAN.md — Setup rbx-css build pipeline and StyleSheetLoader module
- [ ] 01-02-PLAN.md — Create LayoutEngine with Flexbox (UIListLayout) and Grid (UIGridLayout)
- [ ] 01-03-PLAN.md — Create PositioningEngine for CSS position/absolute/relative/fixed/z-index
- [ ] 01-04-PLAN.md — Create BoxModelRenderer for width/height/padding/overflow
- [ ] 01-05-PLAN.md — Refactor BrowserEngine to use StyleSheets and native layouts
- [ ] 01-06-PLAN.md — Finalize with demo CSS, README docs, and Rojo mapping

---

### Phase 2: DOM Selection & Manipulation
**Goal**: Users can select and manipulate DOM elements programmatically via standard web APIs.

**Depends on**: Phase 1 (LayoutEngine required for rendering DOM changes)

**Requirements**: DOM-01, DOM-02

**Success Criteria** (what must be TRUE):
1. User can use querySelector, querySelectorAll, getElementById, getElementsByClassName to find elements in the rendered page
2. User can dynamically create elements with createElement and add them to the page with appendChild
3. User can remove elements from the page with removeChild
4. User can modify element content via innerHTML and textContent properties

**Plans**: TBD

---

### Phase 3: DOM Properties & Events
**Goal**: Users can access element properties and set up event handlers that respond to user interactions.

**Depends on**: Phase 2 (DOM selection/manipulation foundation)

**Requirements**: DOM-03, DOM-04

**Success Criteria** (what must be TRUE):
1. User can read and modify element classList (add, remove, toggle, contains methods)
2. User can read and modify element attributes (getAttribute, setAttribute, removeAttribute)
3. User can access element dataset (data-* attributes)
4. User can access and modify element style properties programmatically (element.style.color = "red")
5. User can set up event handlers with addEventListener that fire correctly for click, scroll, and load events
6. User can remove event handlers with removeEventListener

**Plans**: TBD

---

### Phase 4: Web APIs - Network & Storage
**Goal**: Users can make network requests and persist data locally via standard web APIs.

**Depends on**: Phase 3 (DOM APIs needed for handling Fetch responses and storage events)

**Requirements**: API-01, API-02

**Success Criteria** (what must be TRUE):
1. User can make GET and POST requests to external URLs via Fetch API
2. Fetch API returns proper Response objects with JSON parsing support (response.json() works)
3. User can store data via localStorage.setItem and retrieve it with localStorage.getItem
4. User can remove data with localStorage.removeItem
5. localStorage persists across page navigations within the same domain

**Plans**: TBD

---

### Phase 5: Web APIs - Real-time Communication
**Goal**: Users can establish WebSocket connections for real-time communication.

**Depends on**: Phase 4 (Fetch API patterns inform WebSocket implementation)

**Requirements**: API-03

**Success Criteria** (what must be TRUE):
1. User can establish WebSocket connections to external servers
2. User can send messages via WebSocket send() method
3. User can receive messages via onmessage event handler
4. WebSocket onopen and onclose events fire correctly
5. Connection state is properly managed (readyState, close())

**Plans**: TBD

---

### Phase 6: JavaScript Engine
**Goal**: Users can execute modern JavaScript code (ES5+ES6+) including asynchronous operations within the Roblox environment.

**Depends on**: Phase 3 (DOM APIs required for JS engine to interact with page)

**Requirements**: JS-01, JS-02, JS-03

**Success Criteria** (what must be TRUE):
1. User can execute ES5 JavaScript code (functions, objects, arrays, basic syntax work correctly)
2. User can use ES6+ features: arrow functions, let/const declarations, template literals, destructuring assignments
3. User can create and use Promises (new Promise(), .then(), .catch())
4. User can use async/await syntax for asynchronous operations
5. JavaScript can manipulate the DOM via the APIs implemented in Phases 2-3

**Plans**: TBD

**Research needed**: JS engine architecture (interpreter vs transpiler approach in Luau)

---

### Phase 7: Performance - Load Time
**Goal**: Websites load quickly with progressive rendering, even for large pages.

**Depends on**: Phase 6 (JS execution can affect load time), Phase 4 (Fetch API affects loading)

**Requirements**: PERF-01, PERF-03

**Success Criteria** (what must be TRUE):
1. Typical websites under 200K chars load in under 2.5 seconds (LCP metric)
2. Large pages render incrementally without blocking the main thread (chunked rendering using task.defer() with ~50 nodes per frame)
3. User sees page content progressively appear as it renders (above-fold first, then scrollable content)
4. HTML pages exceeding 200K chars are handled via chunking (no silent truncation)

**Plans**: TBD

---

### Phase 8: Performance - Runtime
**Goal**: Interactions remain smooth at 60fps even with complex pages and many GUI instances.

**Depends on**: Phase 6 (JS execution), Phase 7 (load performance foundation)

**Requirements**: PERF-02, PERF-04

**Success Criteria** (what must be TRUE):
1. Scrolling interactions maintain 60fps (no frame drops during scroll)
2. Click/touch interactions are responsive (no delay in visual feedback)
3. Pages with 1000+ DOM elements stay under ~1000 Roblox GUI instances (via pooling/recycling)
4. Instance pooling reuses Roblox GUI objects across page navigations (no unbounded growth)
5. No script timeout warnings during normal usage (all operations yield appropriately)

**Plans**: TBD

---

### Phase 9: Integration & Validation
**Goal**: All v1 features work together correctly; HTML parsing and rendering is validated against real websites.

**Depends on**: All previous phases (integration testing)

**Requirements**: REN-01

**Success Criteria** (what must be TRUE):
1. Basic HTML parsing and rendering works correctly with all new CSS, JS, and DOM API features
2. User can navigate to popular websites (Wikipedia, basic news sites) and see correct layout + behavior
3. All 21 v1 requirements are validated through integration testing
4. Known edge cases and Roblox platform limits are documented with workarounds

**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. CSS Layout Engine & Native Rendering | 0/6 | Not started | - |
| 2. DOM Selection & Manipulation | 0/4 | Not started | - |
| 3. DOM Properties & Events | 0/6 | Not started | - |
| 4. Web APIs - Network & Storage | 0/5 | Not started | - |
| 5. Web APIs - Real-time Communication | 0/5 | Not started | - |
| 6. JavaScript Engine | 0/5 | Not started | - |
| 7. Performance - Load Time | 0/4 | Not started | - |
| 8. Performance - Runtime | 0/5 | Not started | - |
| 9. Integration & Validation | 0/4 | Not started | - |

---
*Roadmap created: 2026-05-03*
*Total v1 requirements: 21 - All mapped to phases ✓*
