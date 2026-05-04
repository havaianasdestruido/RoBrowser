# robrowser

## What This Is

A Roblox game that renders and runs real websites inside the Roblox engine. It parses HTML/CSS, lays out pages using Roblox GUI objects (Frames, TextLabels, etc.), and executes JavaScript via a Luau-based JS engine. The goal is full modern web standard compatibility so that popular sites render and behave correctly within Roblox — on desktop, mobile, and console.

## Core Value

Site rendering parity — any website loads and displays with correct layout and behavior inside Roblox, matching what users expect from a real browser.

## Requirements

### Validated

- ✓ Basic HTML parsing and rendering via Roblox GUI objects — existing
- ✓ Partial JavaScript execution in Luau — existing
- ✓ Runs as a Roblox game (supports desktop, mobile, console via Roblox platform) — existing

### Active

- [x] **CSS-01**: CSS Flexbox layout support (display: flex, justify-content, align-items, etc.)
- [x] **CSS-02**: CSS Grid layout support (grid-template, grid-area, etc.)
- [x] **CSS-03**: Positioning system (position: absolute/relative/fixed, top, left, z-index)
- [x] **CSS-04**: Box model (margin, padding, width, height, overflow)
- [x] **DOM-01**: Basic DOM selection APIs (querySelector, getElementById, addEventListener)
- [x] **DOM-02**: DOM manipulation APIs (createElement, appendChild, removeChild, innerHTML)
- [x] **DOM-03**: Network request APIs (Fetch API, XMLHttpRequest basic support)
- [x] **JS-01**: Modern JS support (ES6+ features: arrow functions, promises, async/await)
- [x] **PERF-01**: Fast page load times for typical websites
- [x] **PERF-02**: Smooth 60fps interactions (scrolling, click/touch handling)
- [x] **API-01**: Web APIs: localStorage, WebSocket basic support

### Out of Scope

- Full Chrome/Firefox extension ecosystem — out of scope for v1, focus on core rendering
- WebGL / WebGPU rendering — Roblox platform limits make this impractical
- Video/audio playback within rendered pages — out of scope for v1
- Multi-tab browsing — single page view for v1

## Context

**Technical environment:**
- Language: Luau (Roblox fork of Lua) — all browser logic implemented in Luau
- Rendering: Roblox GUI objects (Frames, TextLabels, TextButtons, UIGradient, etc.)
- JS Engine: To be implemented as a Luau-based interpreter or transpiler (module approach)
- Build tool: Rojo 7.7.0-rc.1 for syncing to Roblox Studio
- Platform: Roblox game client (desktop, mobile, console support)

**Current state:**
- Basic HTML/CSS rendering works using Roblox GUI objects
- Partial JavaScript support exists but many features are missing
- CSS layout engines (Flexbox, Grid) are incomplete — major gap
- DOM APIs are partially implemented
- Performance needs improvement for complex pages

**Key research needed:**
- Roblox platform limits: max instances, string length, script execution time
- Feasibility of full ES6+ JS in Luau (interpreter vs transpiler approach)
- CSS layout engine architecture suitable for Roblox's instance limits

## Constraints

- **Platform**: Must run within Roblox engine limits (instance count, string length, execution time) — research needed to quantify
- **Performance**: Must maintain 60fps during interactions while rendering complex pages
- **Module architecture**: Must be structured as separate reusable modules (HTML parser, CSS engine, JS engine, DOM) for use in other Roblox projects
- **Compatibility**: Must support desktop, mobile (touch), and console input methods
- **Roblox Studio**: Must work with Rojo build/serve workflow

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| CSS-first development order | Layout correctness is most visible to users; fixing CSS first delivers immediate visual parity | — Pending |
| Separate modules architecture | Reusable across projects; easier to maintain and replace individual components | — Pending |
| Roblox GUI objects for rendering | Native Roblox approach; no canvas/custom drawing needed | ✓ Good |
| Full browser parity goal | Drives all feature decisions; aware of Roblox platform constraints | — Pending |
| JS engine as Luau module | Consistent with Roblox ecosystem; reusable for other projects | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-03 after initialization*
