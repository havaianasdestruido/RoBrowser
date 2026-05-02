--[[
  Updated client entry point – fetches HTML, parses it, and renders
  the DOM using the BrowserEngine we just added.
]]

local HttpService = game:GetService("HttpService")
local HTMLParser = require(script:FindFirstChild("../shared/HTMLParser.luau"))
local BrowserEngine = require(script:FindFirstChild("BrowserEngine.luau"))

-- Simple helper to fetch a page. In a real app you’d add error handling,
-- caching, and user‑provided URLs.
local function fetchHtml(url)
    local success, result = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if success then
        return result
    else
        warn("Failed to fetch URL:", url, "error:", result)
        return "<p>Failed to load page.</p>"
    end
end

-- Main function – called when the client script runs.
local function init()
    -- Create a ScreenGui to hold the rendered page.
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrowserScreen"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- Example URL – replace with any site that serves simple HTML.
    local url = "https://example.com"
    local html = fetchHtml(url)
    local dom = HTMLParser.parse(html)
    BrowserEngine.render(dom, screenGui)
end

init()
