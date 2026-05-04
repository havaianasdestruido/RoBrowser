---
phase: 01
slug: css-layout-engine-native-rendering
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-03
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Roblox Luau — manual verification + Rojo sync |
| **Config file** | `selene.toml` (linter), `stylua.toml` (formatter) |
| **Quick run command** | `selene src/` + `stylua --check src/` |
| **Full suite command** | Manual verification in Roblox Studio after `rojo serve` |
| **Estimated runtime** | ~5-10 minutes (manual Studio testing) |

---

## Sampling Rate

- **After every task commit:** Run `selene src/` + `stylua --check src/`
- **After every plan wave:** Full manual verification in Roblox Studio
- **Before `/gsd-verify-work`:** All Wave 0 checks must pass (selene + stylua)
- **Max feedback latency:** 600 seconds (Studio load time)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | CSS-01 | T-01-01 / — | Flexbox layouts render correctly | manual | `rojo serve` + Studio test | ✅ / ❌ W0 | ⬜ pending |
| 01-02-01 | 01 | 1 | CSS-02 | T-01-02 / — | Grid layouts render correctly | manual | `rojo serve` + Studio test | ✅ / ❌ W0 | ⬜ pending |
| 01-03-01 | 01 | 2 | CSS-03 | T-01-03 / — | Positioning renders correctly | manual | `rojo serve` + Studio test | ✅ / ❌ W0 | ⬜ pending |
| 01-04-01 | 01 | 2 | CSS-04 | T-01-04 / — | Box model renders correctly | manual | `rojo serve` + Studio test | ✅ / ❌ W0 | ⬜ pending |
| 01-05-01 | 01 | 3 | REN-02 | T-01-05 / — | rbx-css StyleSheet compiles correctly | build | `npx rbx-css --check` | ✅ / ❌ W0 | ⬜ pending |
| 01-06-01 | 01 | 3 | REN-03 | T-01-06 / — | Native layouts (UIListLayout/UIGridLayout) work | manual | `rojo serve` + Studio test | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `selene src/` — linter passes (no errors)
- [x] `stylua --check src/` — formatter passes (no changes needed)
- [x] `npx rbx-css --check` — rbx-css config valid (if applicable)
- [x] Rojo build succeeds: `rojo build -o "robrowser.rbxlx"`

*If none needed: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Flexbox layout renders | CSS-01 | Requires visual inspection in Roblox Studio | 1. Run `rojo serve` 2. Open Roblox Studio 3. Navigate to test page 4. Verify flex containers position children correctly |
| Grid layout renders | CSS-02 | Requires visual inspection in Roblox Studio | 1. Run `rojo serve` 2. Open Roblox Studio 3. Navigate to test page with CSS Grid 4. Verify grid items in correct positions |
| Positioning renders | CSS-03 | Requires visual inspection in Roblox Studio | 1. Run `rojo serve` 2. Open Roblox Studio 3. Test position:absolute/relative/fixed elements 4. Verify z-index stacking |
| Box model renders | CSS-04 | Requires visual inspection in Roblox Studio | 1. Run `rojo serve` 2. Open Roblox Studio 3. Test margin/padding/overflow 4. Verify dimensions match CSS |
| rbx-css StyleSheet | REN-02 | Requires build verification | 1. Run `npx rbx-css compile` 2. Verify .rbxcss StyleSheets created 3. Check StyleSheet applies to Frame instances |
| Native layouts | REN-03 | Requires Studio testing | 1. Run `rojo serve` 2. Add UIListLayout to Frame 3. Verify Flexbox behavior 4. Add UIGridLayout 5. Verify Grid behavior |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 600s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
