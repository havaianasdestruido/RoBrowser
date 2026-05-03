# Codebase Concerns

**Analysis Date:** 2026-05-03

## Tech Debt

**[Polling-based Navigation Button Setup]:**
- **Severity:** MEDIUM
- **Issue:** `src/client/init.client.luau` lines 173-221 uses a `while task.wait(0.5) do` polling loop to set up navigation button click handlers. This runs continuously checking for `navElements` every 500ms.
- **Files:** `src/client/init.client.luau`
- **Impact:** Unnecessary CPU usage; fragile timing dependency (`task.wait(1)` on line 176). If UI creation is delayed, button handlers may not connect properly.
- **Fix approach:** Use signals or callbacks to trigger button setup after `BrowserEngine.render()` completes, eliminating the polling loop.

**[Empty Client Components Directory]:**
- **Severity:** LOW
- **Issue:** `src/client/components/` directory exists but contains no files. This suggests planned but unimplemented UI components.
- **Files:** `src/client/components/`
- **Impact:** Dead structure that may confuse contributors about the intended architecture.
- **Fix approach:** Either implement planned components or remove the empty directory.

**[Unused Hello Utility]:**
- **Severity:** LOW
- **Issue:** `src/shared/utils/Hello.luau` is a placeholder that simply prints "Hello, world!" and is not required anywhere in the codebase.
- **Files:** `src/shared/utils/Hello.luau`
- **Impact:** Dead code that adds noise to the codebase.
- **Fix approach:** Remove the file or implement actual utility functions.

**[Debug Module Safe Require Pattern Duplication]:**
- **Severity:** LOW
- **Issue:** The pattern of safely requiring the debug module with `pcall` is duplicated across `BrowserEngine.luau`, `CSSParser.luau`, and `HTMLParser.luau`. Each implements its own `safeRequire` or debug loading logic.
- **Files:** `src/client/modules/BrowserEngine.luau` (lines 17-25), `src/shared/parsers/CSSParser.luau` (lines 13-16), `src/shared/parsers/HTMLParser.luau` (lines 12-15)
- **Impact:** Code duplication; inconsistent debug loading patterns.
- **Fix approach:** Standardize debug module loading in a shared bootstrap or use the same pattern everywhere.

## Known Bugs

**[Mismatched HTML Tag Handling]:**
- **Severity:** MEDIUM
- **Issue:** In `src/shared/parsers/HTMLParser.luau` lines 183-194, when a closing tag doesn't match the current stack top, the parser pops the stack with a warning but doesn't create a proper recovery. This can lead to incorrect DOM structure for malformed HTML.
- **Files:** `src/shared/parsers/HTMLParser.luau`
- **Trigger:** Malformed HTML with mismatched tags (e.g., `<div><span></div>`)
- **Workaround:** Ensure HTML input has properly matched tags.

**[CSS Selector Override Order]:**
- **Severity:** LOW
- **Issue:** In `src/shared/parsers/CSSParser.luau` lines 72-82, when multiple selectors apply to the same element, later rules simply overwrite earlier ones without considering CSS specificity. Class and ID selectors both merge into the same styles table without priority.
- **Files:** `src/shared/parsers/CSSParser.luau`
- **Trigger:** CSS with conflicting rules for the same element.
- **Workaround:** Avoid CSS conflicts or use inline styles.

**[Text Height Calculation Approximation]:**
- **Severity:** LOW
- **Issue:** In `src/client/modules/BrowserEngine.luau` lines 181-188, `calculateTextHeight()` uses a simple character-per-line calculation that doesn't account for actual font metrics, word boundaries, or Roblox text rendering behavior.
- **Files:** `src/client/modules/BrowserEngine.luau`
- **Impact:** Text may be clipped or have excessive whitespace.
- **Workaround:** Manually adjust text content or use shorter strings.

## Security Considerations

**[No URL Validation Beyond Protocol Check]:**
- **Severity:** MEDIUM
- **Issue:** In `src/server/init.server.luau` lines 52-56, URL validation only checks for `http://` or `https://` prefix. No validation against malicious URLs, SSRF attacks, or allowed domains list.
- **Files:** `src/server/init.server.luau`
- **Current mitigation:** Basic protocol check.
- **Recommendations:** Implement URL validation against allowed domains, add rate limiting per player, consider timeout for `HttpService:GetAsync()`.

**[RemoteFunction No Rate Limiting]:**
- **Severity:** MEDIUM
- **Issue:** `FetchHTML` RemoteFunction in `src/server/init.server.luau` has no rate limiting. A malicious client could invoke it repeatedly, causing excessive HTTP requests from the server.
- **Files:** `src/server/init.server.luau`
- **Current mitigation:** None.
- **Recommendations:** Implement per-player rate limiting (e.g., max 1 request per second), track request counts.

**[Debug Level Configuration Exposure]:**
- **Severity:** LOW
- **Issue:** `src/shared/settings.luau` sets `DebugLevel = "verbose"` by default, which will print extensive debug information to the output. In production, this could expose internal implementation details.
- **Files:** `src/shared/settings.luau`
- **Current mitigation:** Debug level can be changed to "none".
- **Recommendations:** Default to "warn" or "error" for production builds.

## Performance Bottlenecks

**[Polling Loop in Client]:**
- **Severity:** MEDIUM
- **Issue:** The `while task.wait(0.5) do` loop in `src/client/init.client.luau` lines 177-221 runs indefinitely, checking for UI elements every 500ms even after they're found.
- **Files:** `src/client/init.client.luau`
- **Cause:** No mechanism to stop polling after successful setup.
- **Improvement path:** Break out of the loop after buttons are connected, or use event-based setup.

**[No Caching of Fetched HTML]:**
- **Severity:** LOW
- **Issue:** Each navigation triggers a new HTTP request via `FetchHTML` RemoteFunction. There's no caching mechanism for previously fetched pages.
- **Files:** `src/client/init.client.luau`, `src/server/init.server.luau`
- **Cause:** No cache layer implemented.
- **Improvement path:** Implement a simple URL-to-HTML cache on the server or client with TTL.

**[Full DOM Re-render on Navigation]:**
- **Severity:** LOW
- **Issue:** In `src/client/modules/BrowserEngine.luau` line 467, `targetGui:ClearAllChildren()` removes all UI elements and re-renders the entire DOM for each navigation. There's no differential rendering.
- **Files:** `src/client/modules/BrowserEngine.luau`
- **Impact:** Unnecessary UI destruction and recreation; potential flicker.
- **Improvement path:** Implement differential DOM updates or preserve static UI elements.

## Accessibility Issues

**[No Keyboard Navigation Support]:**
- **Severity:** MEDIUM
- **Issue:** The browser UI has no keyboard shortcuts for navigation (Back, Forward, Refresh, Go). Users must click buttons.
- **Files:** `src/client/init.client.luau`, `src/client/modules/BrowserEngine.luau`
- **Impact:** Poor UX for keyboard-oriented users.
- **Recommendations:** Add `ContextActionService` bindings for keyboard shortcuts.

**[No Focus Indicators on Links]:**
- **Severity:** LOW
- **Issue:** While links in `src/client/modules/BrowserEngine.luau` lines 264-281 change color on hover, there's no visible focus indicator for accessibility.
- **Files:** `src/client/modules/BrowserEngine.luau`
- **Recommendations:** Add underline or border on focus.

**[Text Size Not Configurable]:**
- **Severity:** LOW
- **Issue:** Default text size is hardcoded at 14px in multiple places (`src/client/modules/BrowserEngine.luau` lines 196, 203). No zoom or text scaling feature.
- **Files:** `src/client/modules/BrowserEngine.luau`
- **Impact:** Users with visual impairments cannot adjust text size.
- **Recommendations:** Add zoom controls or respect Roblox's UI scaling settings.

## Browser Compatibility Notes

**[Limited HTML Support]:**
- **Severity:** HIGH
- **Issue:** The HTML parser in `src/shared/parsers/HTMLParser.luau` only supports a subset of HTML: basic tags, attributes, comments, and doctype. No support for: scripts execution, iframes, complex forms, media elements, SVG rendering, or modern HTML5 features.
- **Files:** `src/shared/parsers/HTMLParser.luau`
- **Impact:** Most real-world websites will render incorrectly or incompletely.
- **Note:** This is expected for a Roblox in-game browser, but users should understand the limitations.

**[Limited CSS Support]:**
- **Severity:** HIGH
- **Issue:** The CSS parser in `src/shared/parsers/CSSParser.luau` only supports simple selectors (tag, class, ID) and a limited set of properties (background-color, color, font-size, font-weight, font-style, text-align, width, height, display). No support for: pseudo-selectors, media queries, CSS Grid/Flexbox, animations, or complex selectors.
- **Files:** `src/shared/parsers/CSSParser.luau`, `src/client/modules/BrowserEngine.luau` (applySingleStyle function)
- **Impact:** Most websites will not display as intended.

**[No JavaScript Execution]:**
- **Severity:** HIGH
- **Issue:** There is no JavaScript engine. The browser is static HTML/CSS only. Interactive websites, SPAs, and dynamic content will not work.
- **Files:** Entire codebase
- **Impact:** Only static websites can be rendered meaningfully.

## Deprecated Dependencies

**[No External Dependencies]:**
- **Severity:** N/A
- **Issue:** The project does not use any external packages or dependencies (no `package.json`, `rojo.json` only references Rojo 7.7.0-rc.1).
- **Files:** `default.project.json`, `README.md`
- **Impact:** No dependency-related deprecation risks. Rojo version is a release candidate but is the build tool, not a runtime dependency.

## Areas Needing Refactoring

**[BrowserEngine is a Monolithic Module]:**
- **Severity:** MEDIUM
- **Issue:** `src/client/modules/BrowserEngine.luau` is 555 lines and handles: CSS style application, DOM rendering, navigation bar creation, UI state management, and text calculations. The `renderNode` function alone is ~150 lines with deeply nested conditionals.
- **Files:** `src/client/modules/BrowserEngine.luau`
- **Why fragile:** Hard to test, understand, and modify. Adding new HTML tags or CSS properties requires touching multiple sections.
- **Safe modification:** Refactor one function at a time; maintain a list of supported tags/properties in a config table.
- **Test coverage:** None (no test files exist).

**[Client Navigation Logic Split Across Two Files]:**
- **Severity:** LOW
- **Issue:** Navigation state (history, bookmarks, currentUrl) is managed in `src/client/init.client.luau`, while rendering is in `BrowserEngine.luau`. The communication between them uses callbacks (`BrowserEngine.onNavigate`) which can lead to circular references.
- **Files:** `src/client/init.client.luau`, `src/client/modules/BrowserEngine.luau`
- **Why fragile:** State synchronization between the two modules is implicit.
- **Safe modification:** Consider a central state store or pass all navigation state into BrowserEngine explicitly.

**[HTML Parser Uses String Patterns for Complex Parsing]:**
- **Severity:** MEDIUM
- **Issue:** `src/shared/parsers/HTMLParser.luau` uses Lua string patterns (not a proper parser) which can fail on edge cases like: attributes with spaces, escaped quotes, nested angle brackets in text, or complex doctypes.
- **Files:** `src/shared/parsers/HTMLParser.luau`
- **Why fragile:** String pattern matching is inherently limited for HTML parsing; malformed input can cause incorrect tokenization.
- **Safe modification:** Add more test cases with edge-case HTML; consider a proper parsing library if available for Luau.

## Test Coverage Gaps

**[No Test Files Exist]:**
- **Severity:** HIGH
- **Issue:** No test files (`*.test.luau`, `*.spec.luau`) were found in the project. The HTML parser, CSS parser, and BrowserEngine have no automated tests.
- **Files:** Entire `src/` directory
- **What's not tested:** HTML parsing correctness, CSS parsing, DOM rendering output, navigation logic, error handling paths.
- **Risk:** Changes to parsers or rendering engine could introduce regressions that go unnoticed.
- **Priority:** HIGH - Add basic unit tests for parsers first, then integration tests for rendering.

**[Debug Module Error Function Doesn't Throw]:**
- **Severity:** LOW
- **Issue:** In `src/shared/debug.luau` lines 52-56, `Debug.error()` only logs a warning but doesn't throw or return an error value. This means calling code can't programmatically detect or handle errors from the debug module.
- **Files:** `src/shared/debug.luau`
- **Risk:** Silent failures if code relies on debug.error for error handling.

---

*Concerns audit: 2026-05-03*
