-- src/shared/debug.luau
-- Debug logging utility with source tracing
-- Respects settings.luau DebugLevel configuration

local Settings = require("./settings")

local Debug = {}

-- Priority: lower = more verbose
local LEVEL_PRIORITY = {
	verbose = 0,
	log = 1,
	warn = 2,
	error = 3,
	none = 4,
}

local function shouldLog(level)
	local configPriority = LEVEL_PRIORITY[Settings.DebugLevel] or LEVEL_PRIORITY.warn
	local msgPriority = LEVEL_PRIORITY[level] or LEVEL_PRIORITY.log
	return msgPriority >= configPriority
end

-- Format message with optional source context
local function formatMessage(level, source, message)
	local src = source and `[{source}]` or ""
	return `[{string.upper(level)}]{src} {message}`
end

-- Verbose: most detailed tracing
function Debug.verbose(message: string, source: string?)
	if shouldLog("verbose") then
		print(formatMessage("verbose", source, message))
	end
end

-- Log: general information
function Debug.log(message: string, source: string?)
	if shouldLog("log") then
		print(formatMessage("log", source, message))
	end
end

-- Warn: potential issues
function Debug.warn(message: string, source: string?)
	if shouldLog("warn") then
		warn(formatMessage("warn", source, message))
	end
end

-- Error: critical issues (does not throw, just logs)
function Debug.error(message: string, source: string?)
	if shouldLog("error") then
		warn(formatMessage("error", source, message))
	end
end

-- Assert with debug context
function Debug.assert(condition: boolean, message: string, source: string?)
	if not condition then
		Debug.error(`Assertion failed: {message}`, source)
	end
	return condition
end

return Debug