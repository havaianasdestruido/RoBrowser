# Technology Stack

**Analysis Date:** 2026-05-03

## Languages

**Primary:**
- Luau (typed dialect of Lua) - Roblox game engine scripting language
  - Version: Luau (Roblox runtime)
  - Used in all source files: `src/**/*.luau`

**Secondary:**
- JSON - Configuration and project manifest files
  - Used in: `default.project.json`, `sourcemap.json`

## Runtime

**Environment:**
- Roblox Game Engine (Roblox Lua runtime with Luau VM)
- Platform: Windows/Mac/Linux (Roblox Studio), iOS/Android (Roblox Player)

**Package Manager:**
- Not applicable (Roblox uses asset-based dependency management)
- Toolchain manager: Aftman 0.6.x (managed via `aftman.toml`)
- Lockfile: Not present (Aftman uses declarative config)

## Frameworks

**Core:**
- Roblox Engine API (built-in)
  - Services used: `game:GetService("Players")`, `game:GetService("ReplicatedStorage")`, `game:GetService("HttpService")`
  - GUI framework: Roblox `ScreenGui`, `Frame`, `TextLabel`, `TextButton`, `ScrollingFrame`, `ImageLabel`

**Build/Dev Tools:**
- Rojo 7.6.1 - Roblox project synchronization tool
  - Config: `default.project.json`
  - Output: `robrowser.rbxlx` (place file)
  - Sourcemap: `sourcemap.json` (auto-generated)
- Selene 0.26.1 - Luau linter
  - Config: `selene.toml`
  - Standard library: `roblox`
- StyLua 0.20.0 - Luau code formatter
  - Config: `stylua.toml`
  - Column width: 120, Indent: Tabs (4 spaces)

## Key Dependencies

**Critical (bundled in project):**
- None (pure Luau standard library + Roblox API)

**Internal Modules:**
- `src/shared/debug.luau` - Debug logging utility with configurable log levels
- `src/shared/settings.luau` - Global configuration (debug level)
- `src/shared/parsers/HTMLParser.luau` - HTML parser (tokenizer + DOM tree builder)
- `src/shared/parsers/CSSParser.luau` - CSS parser (selectors + properties)
- `src/client/modules/BrowserEngine.luau` - Rendering engine (HTML/CSS to Roblox GUI)
- `src/client/init.client.luau` - Client entry point
- `src/server/init.server.luau` - Server entry point

## Configuration

**Environment:**
- Roblox game settings (HttpEnabled must be enabled for HTTP requests)
- No `.env` files (Roblox uses game settings for configuration)

**Build:**
- `default.project.json` - Rojo project structure definition
  - Maps `src/` directories to Roblox game hierarchy
  - `src/shared/` → `ReplicatedStorage.Shared`
  - `src/server/` → `ServerScriptService.Server`
  - `src/client/` → `StarterPlayer.StarterPlayerScripts.Client`
- `aftman.toml` - Toolchain versions
- `selene.toml` - Linting rules (Roblox standard library, style warnings)
- `stylua.toml` - Formatting rules

## Platform Requirements

**Development:**
- Roblox Studio (for opening `.rbxlx` place files)
- Rojo CLI (`rojo` via Aftman)
- Luau toolchain: Selene + StyLua (via Aftman)
- Git (version control)

**Production:**
- Roblox Game Server (hosted by Roblox)
- HTTP requests require `HttpService.HttpEnabled = true` in game settings

## Build Commands

```bash
# Build place file from source
rojo build -o "robrowser.rbxlx"

# Start Rojo live sync server (for development)
rojo serve

# Run linter
selene src/

# Run formatter
stylua src/
```

---

*Stack analysis: 2026-05-03*
