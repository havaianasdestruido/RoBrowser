# Architecture

**Analysis Date:** 2026-05-03

## Pattern Overview

**Overall:** Client-Server with Shared Module Architecture (Roblox standard pattern)

**Key Characteristics:**
- Client-side rendering engine that parses and displays HTML content within Roblox
- Server-side HTTP proxy using Roblox's HttpService (client cannot make direct HTTP requests)
- Shared parsers and utilities accessible from both client and server via ModuleScripts
- Communication via RemoteFunction (`FetchHTML`) from client to server
- Navigation state managed client-side (history, bookmarks)

## Layers

**Client Layer:**
- Purpose: Fetch web pages, parse HTML/CSS, render DOM as Roblox GUI elements
- Location: `src/client/`
- Contains: Entry point (`init.client.luau`), BrowserEngine module (`modules/BrowserEngine.luau`), UI components directory (`components/`)
- Depends on: ReplicatedStorage.Shared (parsers, debug, settings)
- Used by: Roblox client runtime (runs as LocalScript in StarterPlayerScripts)

**Server Layer:**
- Purpose: Proxy HTTP requests for the client via HttpService
- Location: `src/server/`
- Contains: Entry point (`init.server.luau`) with RemoteFunction handler
- Depends on: ReplicatedStorage.Shared (debug module)
- Used by: Roblox server runtime (runs as Script in ServerScriptService)

**Shared Layer:**
- Purpose: Code shared between client and server (parsers, utilities, configuration)
- Location: `src/shared/`
- Contains: Debug logging (`debug.luau`), Settings (`settings.luau`), Parsers (`parsers/`), Utilities (`utils/`)
- Depends on: Roblox services (game:GetService)
- Used by: Both client and server via `require()`

## Data Flow

**Page Navigation Flow:**

1. Client calls `navigateToUrl(url)` in `src/client/init.client.luau`
2. Client invokes `FetchHTML` RemoteFunction: `fetchHTML:InvokeServer(url)`
3. Server `init.server.luau` receives call, validates URL, calls `HttpService:GetAsync(url)`
4. Server returns HTML string to client
5. Client passes HTML to `HTMLParser.parse(html)` in `src/shared/parsers/HTMLParser.luau`
6. HTMLParser tokenizes and parses HTML into DOM tree (ElementNode/TextNode structure)
7. If `<style>` tags present, CSS is extracted and passed to `CSSParser.parse(cssText)` in `src/shared/parsers/CSSParser.luau`
8. Client calls `BrowserEngine.render(dom, screenGui)` in `src/client/modules/BrowserEngine.luau`
9. BrowserEngine iterates DOM tree, creates Roblox instances (Frame, TextLabel, TextButton, ImageLabel)
10. CSS styles are applied via `CSSParser.matchElement(element, styleMap)`
11. Rendered content displayed in ScrollingFrame within ScreenGui

**Navigation State Flow:**
1. URL added to `history` table with index tracking
2. Back/Forward buttons navigate through history array
3. Refresh re-calls `navigateToUrl(currentUrl)`

## Key Abstractions

**HTMLParser (`src/shared/parsers/HTMLParser.luau`):**
- Purpose: Parse HTML string into lightweight DOM structure
- Node types: `ElementNode` (tag, attrs, children) and `TextNode` (text)
- Key methods: `HTMLParser.parse(html)` → root ElementNode, `HTMLParser.serialize(node)` for debugging
- Pattern: Tokenizer → Parser → DOM tree

**CSSParser (`src/shared/parsers/CSSParser.luau`):**
- Purpose: Parse CSS and match selectors to DOM elements
- Key methods: `CSSParser.parse(cssText)` → styleMap, `CSSParser.matchElement(element, styleMap)` → styles table
- Pattern: Rule-based parser with selector matching (tag, class, id)

**BrowserEngine (`src/client/modules/BrowserEngine.luau`):**
- Purpose: Render DOM tree as Roblox GUI elements
- Key methods: `BrowserEngine.render(domRoot, targetGui)` → UI elements, `BrowserEngine.showLoading()`, `BrowserEngine.hideLoading()`
- Pattern: Recursive DOM traversal → Instance creation → Style application
- Callbacks: `BrowserEngine.onNavigate(url)` for link clicks

**Debug (`src/shared/debug.luau`):**
- Purpose: Configurable logging with severity levels
- Levels: verbose (0), log (1), warn (2), error (3), none (4)
- Controlled by `Settings.DebugLevel` in `src/shared/settings.luau`
- Pattern: Module returning functions (Debug.verbose, Debug.log, Debug.warn, Debug.error)

## Entry Points

**Client Entry (`src/client/init.client.luau`):**
- Location: `src/client/init.client.luau`
- Triggers: Roblox loads as LocalScript in StarterPlayer → StarterPlayerScripts
- Responsibilities:
  - Initialize ScreenGui in PlayerGui
  - Set up BrowserEngine navigation callback
  - Navigate to default URL (Wikipedia)
  - Set up back/forward/refresh button handlers
  - Manage navigation history

**Server Entry (`src/server/init.server.luau`):**
- Location: `src/server/init.server.luau`
- Triggers: Roblox loads as Script in ServerScriptService
- Responsibilities:
  - Verify HttpService is enabled
  - Create FetchHTML RemoteFunction if not exists
  - Register `OnServerInvoke` handler for HTTP requests
  - Validate URLs (must match `^https?://`)
  - Proxy HTTP requests via `HttpService:GetAsync()`

## Error Handling

**Strategy:** Defensive programming with pcall wrappers and Debug logging

**Patterns:**
- `pcall()` wraps HTTP requests and HTML parsing: `local success, result = pcall(function() ... end)`
- RemoteFunction returns `nil` on failure, client checks `if success and html then`
- Error pages rendered as fallback: `local errorHtml = "<html>..."` parsed and rendered
- Server validates URLs before HTTP request, returns nil for invalid URLs
- Debug module provides structured error logging: `Debug.error(message, source)`

## Cross-Cutting Concerns

**Logging:** `src/shared/debug.luau` module with configurable severity (verbose/log/warn/error/none)
- Client source tag: `"Client"`
- Server source tag: `"Server"`
- Parser source tags: `"HTMLParser"`, `"CSSParser"`, `"BrowserEngine"`

**Validation:** URL validation in server (`^https?://` pattern), debug level validation in settings

**Configuration:** `src/shared/settings.luau` with `DebugLevel` setting (default: `"verbose"`)

**State Management:** Client-side history array with index pointer, currentUrl tracking, isNavigating flag to prevent concurrent navigations

---

*Architecture analysis: 2026-05-03*
