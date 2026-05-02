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

-- Verify HttpService is enabled (must be toggled in Game Settings > Security)
if not HttpService.HttpEnabled then
    warn("[FetchHTML] HttpService is disabled. Enable HTTP requests in game settings.")
end

-- Create RemoteFunction if it doesn't exist
local fetchHTML = ReplicatedStorage:FindFirstChild("FetchHTML")
if not fetchHTML then
    fetchHTML = Instance.new("RemoteFunction")
    fetchHTML.Name = "FetchHTML"
    fetchHTML.Parent = ReplicatedStorage
end

fetchHTML.OnServerInvoke = function(player, url)
    -- Simple validation – only allow http/https URLs
    if typeof(url) ~= "string" or not url:match("^https?://") then
        warn("Invalid URL requested by", player.Name, ":", url)
        return nil
    end
    local success, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if success then
        return result
    else
        warn("Failed to fetch URL on server:", url, "error:", result)
        return nil
    end
end

print("Server ready: FetchHTML RemoteFunction created")


