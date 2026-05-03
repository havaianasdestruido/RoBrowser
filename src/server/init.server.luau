--!strict
--!optimize 2
--!native
--[[
  Server script that provides a RemoteFunction for fetching HTML
  using HttpService. Clients invoke this to bypass the client‑side HTTP
  restriction. It also checks that HttpService is enabled in the game settings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Safe require for shared modules
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

-- Helper to log with fallback to warn
local function debugLog(level, message, source)
	if Debug then
		Debug[level](message, source or "Server")
	else
		warn(`[Server] {message}`)
	end
end

-- Verify HttpService is enabled (must be toggled in Game Settings > Security)
if not HttpService.HttpEnabled then
	debugLog("warn", "HttpService is disabled. Enable HTTP requests in game settings.", "Server")
end

-- Create RemoteFunction if it doesn't exist
local fetchHTML = ReplicatedStorage:FindFirstChild("FetchHTML")
if not fetchHTML then
	fetchHTML = Instance.new("RemoteFunction")
	fetchHTML.Name = "FetchHTML"
	fetchHTML.Parent = ReplicatedStorage
	debugLog("log", "Created FetchHTML RemoteFunction", "Server")
end

fetchHTML.OnServerInvoke = function(player, url)
	debugLog("verbose", `Request from {player.Name}: {url}`, "Server")

	-- Simple validation – only allow http/https URLs
	if typeof(url) ~= "string" or not url:match("^https?://") then
		debugLog("warn", `Invalid URL requested by {player.Name}: {url}`, "Server")
		return nil
	end

	local success, result = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		debugLog("log", `Successfully fetched {url} ({#result} chars)`, "Server")
		return result
	else
		debugLog("error", `Failed to fetch URL: {url}, error: {result}`, "Server")
		return nil
	end
end

debugLog("log", "Server ready: FetchHTML RemoteFunction created", "Server")


