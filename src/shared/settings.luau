-- src/shared/settings.luau
-- Global project configuration settings
-- Debug Levels (default: "warn")
-- Supported values: "verbose", "log", "warn", "error", "none"

local Settings = {
    DebugLevel = "verbose"
}

-- Validate debug level on load
local ALLOWED_DEBUG_LEVELS = {"verbose", "log", "warn", "error", "none"}

local function isDebugLevelValid(level)
    for _, allowed in ipairs(ALLOWED_DEBUG_LEVELS) do
        if level == allowed then
            return true
        end
    end
    return false
end

if not isDebugLevelValid(Settings.DebugLevel) then
    warn(`Invalid debug level set: {Settings.DebugLevel}. Defaulting to "warn".`)
    Settings.DebugLevel = "warn"
end

return Settings