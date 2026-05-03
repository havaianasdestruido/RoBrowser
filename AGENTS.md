## Project
robrowser

## Technology Stack

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

## Build Tools

- **Rojo 7.7.0-rc.1** - Roblox Studio sync tool
  - Build: `rojo build -o "robrowser.rbxlx"`
  - Serve: `rojo serve`
- **StyLua** - Lua/Luau code formatter (`stylua.toml`)
- **Selene** - Luau linter (`selene.toml`)
- **Aftman** - Toolchain manager (`aftman.toml`)

## Key Dependencies

- **rbx-css** (recommended) - CSS to Roblox StyleSheet compiler for Flexbox/Grid support
- **Roblox native UIListLayout** - Native Flexbox implementation (performance)
- **Roblox native UIGridLayout** - Native Grid implementation (performance)

## Project Structure

```
robrowser/
├── src/                    # Luau source code
│   ├── shared/           # Shared modules (HTML parser, CSS engine, JS engine)
│   ├── client/           # Client-side code (rendering, UI events)
│   └── server/           # Server-side code (HTTP proxy)
├── documentation/         # Project documentation
├── examples/              # Example usage
├── tools/                # Build/development tools
├── utils/                # Utility scripts
├── default.project.json   # Rojo project manifest
├── sourcemap.json        # Rojo source mapping
├── selene.toml          # Luau linter config
├── stylua.toml           # Luau formatter config
└── aftman.toml          # Toolchain manager config
```

## Coding Conventions

- **Language:** Luau (typed Lua) - use type annotations where possible
- **Naming:** PascalCase for modules/classes, camelCase for variables/functions
- **Formatting:** StyLua (enforced via `stylua.toml`)
- **Linting:** Selene (enforced via `selene.toml`)
- **File naming:** `.luau` extension for all Lua files
- **Module pattern:** Return table with functions (Roblox module script pattern)

## Workflow

This project uses GSD (Get Shit Done) workflow:
- `/gsd-new-project` - Initialize project (completed)
- `/gsd-discuss-phase N` - Discuss phase approach
- `/gsd-plan-phase N` - Create implementation plans
- `/gsd-execute-phase N` - Execute plans

**Current Milestone:** v1 Initial Release
**Current Phase:** Phase 1 (CSS Layout Engine & Native Rendering)
**Mode:** YOLO (auto-approve)
**Granularity:** Fine (9 phases, 4-6 plans each)
