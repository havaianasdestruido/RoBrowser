--!strict
--[[
  Updated client entry point – fetches HTML via a server RemoteFunction, parses it, and renders
  the DOM using the BrowserEngine. Default homepage is Wikipedia.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules from ReplicatedStorage.Shared (Rojo maps src/shared here)
local HTMLParser = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HTMLParser"))
local BrowserEngine = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrowserEngine"))

-- RemoteFunction that the server provides for HTTP requests
local fetchHTML = ReplicatedStorage:WaitForChild("FetchHTML")

local function getHtml(url: string): string
    local result = fetchHTML:InvokeServer(url)
    if result then
        return result
    else
        warn("Failed to fetch URL via server:", url)
        return "<p>Failed to load page.</p>"
    end
end

local function init()
    -- Create a ScreenGui to hold the rendered page.
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrowserScreen"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local url = "https://en.wikipedia.org/wiki/Main_Page"
    local html = getHtml(url)
    local dom = HTMLParser.parse(html)
    BrowserEngine.render(dom, screenGui)
end

init()
