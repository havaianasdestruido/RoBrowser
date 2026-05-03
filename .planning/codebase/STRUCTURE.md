# Codebase Structure

**Analysis Date:** 2026-05-03

## Directory Layout

```
robrowser/
├── src/                       # Source code (mapped to Roblox services via Rojo)
│   ├── client/                # Client-side code → StarterPlayer.StarterPlayerScripts.Client
│   │   ├── init.client.luau   # Client entry point (LocalScript)
│   │   ├── components/         # UI components (currently empty)
│   │   └── modules/
│   │       └── BrowserEngine.luau  # HTML renderer (ModuleScript)
│   ├── server/                # Server-side code → ServerScriptService.Server
│   │   └── init.server.luau   # Server entry point (Script)
│   └── shared/                # Shared modules → ReplicatedStorage.Shared
│       ├── debug.luau          # Debug logging utility (ModuleScript)
│       ├── settings.luau       # Configuration (ModuleScript)
│       ├── parsers/
│       │   ├── HTMLParser.luau # HTML parser (ModuleScript)
│       │   └── CSSParser.luau  # CSS parser (ModuleScript)
│       └── utils/
│           └── Hello.luau     # Example utility (ModuleScript)
├── tools/                     # Build tools (binaries)
│   ├── selene                 # Luau linter binary
│   └── stylua                 # Luau formatter binary
├── documentation/             # Project documentation
│   ├── html-tags-chart.pdf    # HTML tags reference
│   └── html_tags.txt          # HTML tags list
├── examples/                  # Example files
│   └── basic/                 # Basic examples (empty)
├── .planning/                 # GSD planning directory
│   └── codebase/              # Codebase analysis documents
├── default.project.json        # Rojo project configuration
├── sourcemap.json             # Rojo source map (generated)
├── selene.toml                # Selene linter configuration
├── stylua.toml                # StyLua formatter configuration
├── aftman.toml                # Aftman tool manager configuration
└── README.md                  # Project readme
```

## Directory Purposes

**`src/client/`:**
- Purpose: Client-side Lua code that runs on the Roblox client
- Contains: Entry point, BrowserEngine module, components directory
- Key files: `init.client.luau`, `modules/BrowserEngine.luau`

**`src/server/`:**
- Purpose: Server-side Lua code that runs on Roblox servers
- Contains: Entry point with HTTP proxy handler
- Key files: `init.server.luau`

**`src/shared/`:**
- Purpose: Code accessible from both client and server via `require()`
- Contains: Parsers, utilities, debug module, settings
- Key files: `debug.luau`, `settings.luau`, `parsers/HTMLParser.luau`, `parsers/CSSParser.luau`

**`tools/`:**
- Purpose: Pre-compiled binaries for development tooling
- Contains: `selene` (linter), `stylua` (formatter)
- Generated: No (committed binaries)

**`documentation/`:**
- Purpose: Reference materials for HTML/CSS development
- Contains: PDF charts, text references

## Key File Locations

**Entry Points:**
- `src/client/init.client.luau`: Client entry point (LocalScript)
- `src/server/init.server.luau`: Server entry point (Script)

**Configuration:**
- `default.project.json`: Rojo project mapping (Roblox services ↔ filesystem)
- `selene.toml`: Linter rules for Luau
- `stylua.toml`: Code formatting rules
- `aftman.toml`: Tool versions (rojo, selene, stylua)

**Core Logic:**
- `src/client/modules/BrowserEngine.luau`: Main rendering engine
- `src/shared/parsers/HTMLParser.luau`: HTML → DOM parser
- `src/shared/parsers/CSSParser.luau`: CSS → styleMap parser

**Testing:**
- Not applicable (no test framework configured)

## Naming Conventions

**Files:**
- Pattern: `init.{context}.luau` for entry points (e.g., `init.client.luau`, `init.server.luau`)
- Pattern: `PascalCase.luau` for modules/parsers (e.g., `BrowserEngine.luau`, `HTMLParser.luau`, `CSSParser.luau`)
- Pattern: `camelCase.luau` for utilities (e.g., `Hello.luau`)
- Extension: `.luau` (Luau format with strict mode, optimize, and native annotations)

**Directories:**
- Pattern: `lowercase/` for feature directories (e.g., `parsers/`, `utils/`, `components/`, `modules/`)

## Where to Add New Code

**New Feature (Client-side):**
- Primary code: `src/client/modules/FeatureName.luau`
- Components: `src/client/components/NewComponent.luau`
- Entry update: Add require in `src/client/init.client.luau`

**New Feature (Server-side):**
- Primary code: `src/server/init.server.luau` (or split into modules in new `src/server/modules/` directory)

**New Shared Module:**
- Implementation: `src/shared/modules/ModuleName.luau` or `src/shared/utils/utility.luau`
- Accessed via: `require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleName"))`

**New Parser:**
- Implementation: `src/shared/parsers/NewParser.luau`
- Follow pattern: Return table with `parse()` function

## Special Directories

**`tools/`:**
- Purpose: Pre-compiled binaries for development
- Generated: No (binaries committed to repo)
- Committed: Yes

**`documentation/`:**
- Purpose: Reference materials
- Generated: No
- Committed: Yes

**`examples/`:**
- Purpose: Example code/snippets
- Generated: No
- Committed: Yes (currently empty)

## Roblox Service Mapping

Defined in `default.project.json`:
- `src/shared/` → `ReplicatedStorage.Shared` (accessible to both client and server)
- `src/server/` → `ServerScriptService.Server` (server-only Scripts)
- `src/client/` → `StarterPlayer.StarterPlayerScripts.Client` (client-only LocalScripts)

## Configuration Files

**`default.project.json`:**
- Rojo project definition
- Maps filesystem paths to Roblox DataModel paths
- Defines instance types (`$className`) and properties (`$properties`)

**`selene.toml`:**
- Linter configuration for Luau
- Standard: `std = "roblox"`
- Enabled lints: `synthetic_semicolon`, `incorrect_standard_library`, `shadowing`, `unused_variable`, `unused_function`, `deprecated_function`

**`stylua.toml`:**
- Formatter configuration
- Column width: 120
- Indent: Tabs, width 4
- Quote style: AutoPreferDouble
- Call parentheses: Always

**`aftman.toml`:**
- Tool manager configuration
- Tools: rojo@7.6.1, selene@0.26.1, stylua@0.20.0

---

*Structure analysis: 2026-05-03*
