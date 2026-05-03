# Coding Conventions

**Analysis Date:** 2026-05-03

## Naming Patterns

**Files:**
- Use `.luau` extension for all Luau source files
- Entry points follow Roblox convention: `init.client.luau` (client), `init.server.luau` (server)
- Module files use PascalCase: `HTMLParser.luau`, `CSSParser.luau`, `BrowserEngine.luau`
- Utility files use PascalCase or camelCase: `Hello.luau`, `settings.luau`, `debug.luau`

**Functions:**
- Use camelCase for function names: `parseRule`, `renderNode`, `navigateToUrl`
- Local functions declared as: `local function functionName()`
- Module methods attached to table: `function Debug.verbose(message, source)`

**Variables:**
- Use camelCase: `htmlText`, `cssMap`, `navElements`
- Constants use UPPER_CASE: `LEVEL_PRIORITY`, `ALLOWED_DEBUG_LEVELS`
- Acronyms preserved in names: `CSSParser`, `HTMLParser`

**Types/Modules:**
- Module tables use PascalCase: `local HTMLParser = {}`, `local BrowserEngine = {}`
- Return the module table at end of file: `return HTMLParser`

## Code Style

**Formatting:**
- Formatter: StyLua v0.20.0 (configured in `stylua.toml`)
- Indentation: Tabs, width 4
- Column width: 120
- Quote style: AutoPreferDouble
- Call parentheses: Always required
- Collapse simple statements: Never
- Space before call parentheses: false
- Format expressions: true

**Linting:**
- Linter: Selene v0.26.1 (configured in `selene.toml`)
- Standard library: Roblox (`std = "roblox"`)
- Enabled warnings:
  - `synthetic_semicolon = "warn"`
  - `incorrect_standard_library = "warn"`
  - `shadowing = "warn"`
  - `unused_variable = "warn"`
  - `unused_function = "warn"`
  - `deprecated_function = "warn"`
- Disabled/allowed:
  - `unused_parameter = "allow"` (too strict for Roblox callbacks)
  - `global_usage = "allow"`
  - `shebang = "allow"`

**File Header Annotations:**
All Luau files should start with these compiler annotations:
```luau
--!strict
--!optimize 2
--!native
```

## Import Organization

**Module Loading Pattern:**
```luau
-- Safe require pattern used throughout codebase
local function safeRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    if success then
        return result
    end
    return nil
end

local Debug = safeRequire(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("debug"))
```

**Roblox Service Access:**
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
```

**Cross-Module References:**
- Client/Server access shared modules via `ReplicatedStorage:WaitForChild("Shared")`
- Parser modules accessed via: `require(Shared:WaitForChild("parsers"):WaitForChild("HTMLParser"))`
- Debug module loaded safely in most files with pcall wrapper

## Error Handling

**pcall Pattern:**
Primary error handling uses `pcall` for protected calls:
```luau
local success, result = pcall(function()
    return HttpService:GetAsync(url)
end)

if success then
    return result
else
    Debug.error(`Failed to fetch URL: {url}, error: {result}`, "Server")
    return nil
end
```

**Safe Require Pattern:**
Modules use pcall-wrapped require for optional dependencies:
```luau
local Debug = nil
pcall(function()
    Debug = require(script.Parent.Parent:WaitForChild("debug"))
end)
```

**Assertion Pattern:**
Custom assertion via Debug module:
```luau
function Debug.assert(condition: boolean, message: string, source: string?)
    if not condition then
        Debug.error(`Assertion failed: {message}`, source)
    end
    return condition
end
```

## Logging

**Framework:** Custom `Debug` module (`src/shared/debug.luau`)

**Log Levels (priority order):**
- `verbose` - Most detailed tracing (priority 0)
- `log` - General information (priority 1)
- `warn` - Potential issues (priority 2)
- `error` - Critical issues (priority 3)
- `none` - Disable all logging (priority 4)

**Usage Pattern:**
```luau
Debug.verbose(`Fetching HTML from: {url}`, "Client")
Debug.log(`Successfully fetched HTML ({#result} chars)`, "Client")
Debug.warn(`Failed to fetch URL via server: {url}`, "Client")
Debug.error(`Failed to navigate to: {url}`, "Client")
```

**Configuration:**
Debug level set in `src/shared/settings.luau`:
```luau
local Settings = {
    DebugLevel = "verbose"  -- Options: "verbose", "log", "warn", "error", "none"
}
```

## Comments

**Single-line Comments:**
Use `--` for single-line comments:
```luau
-- Helper to trim whitespace
local function trim(s)
```

**Multi-line Comments:**
Use `--[[ ]]` for multi-line documentation:
```luau
--[[
  Server script that provides a RemoteFunction for fetching HTML
  using HttpService. Clients invoke this to bypass the client‑side HTTP
  restriction.
]]
```

**File Headers:**
Files include purpose description in multi-line comments after compiler annotations.

**When to Comment:**
- Module purpose and public API documented at top of file
- Complex logic within functions gets inline comments
- Debug logging serves as runtime documentation

## Function Design

**Size:**
No enforced limit, but functions typically 10-30 lines for readability.

**Parameters:**
- Use explicit type annotations when possible: `function Debug.verbose(message: string, source: string?)`
- Optional parameters denoted with `?`: `source: string?`
- Self-documenting parameter names

**Return Values:**
- Explicit return type annotations: `local function getHtml(url: string): string`
- Return `nil` for error cases
- Table constructors for complex returns

## Module Design

**Exports:**
Modules use table-based export pattern:
```luau
local HTMLParser = {}

function HTMLParser.parse(html)
    -- implementation
end

function HTMLParser.serialize(node, indent)
    -- implementation
end

return HTMLParser
```

**Barrel Files:**
Not used. Modules are required directly from their paths via Roblox's `ReplicatedStorage` hierarchy.

**Instance Attributes:**
Roblox instances use attributes for state tracking:
```luau
backBtn:SetAttribute("ClickConnected", true)
if not backBtn:GetAttribute("ClickConnected") then
    -- connect handler
end
```

## Toolchain

**Package/Tool Management:**
- Aftman v0.20.0 manages tool versions (`aftman.toml`)
- Tools: Rojo 7.6.1, Selene 0.26.1, StyLua 0.20.0

**Build/Dev:**
- Rojo for syncing: `rojo build -o "robrowser.rbxlx"`
- Rojo server for live sync: `rojo serve`
- No npm/pip dependencies - pure Roblox Luau project

---

*Convention analysis: 2026-05-03*
