--!strict
--!optimize 2
--!native
--[[
  Client entry point – fetches HTML via a server RemoteFunction, parses it, and renders
  the DOM using the BrowserEngine. Supports navigation, back/forward history,
  and loading states. Default homepage is Wikipedia.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules from ReplicatedStorage.Shared (Rojo maps src/shared here)
local HTMLParser = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HTMLParser"))
local BrowserEngine = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrowserEngine"))

-- RemoteFunction that the server provides for HTTP requests
local fetchHTML = ReplicatedStorage:WaitForChild("FetchHTML")

-- Navigation history
local history = {}
local historyIndex = 0
local currentUrl = ""

-- UI elements reference
local navElements = nil

local function getHtml(url: string): string
	local result = fetchHTML:InvokeServer(url)
	if result then
		return result
	else
		warn("Failed to fetch URL via server:", url)
		return "<html><body><h1>Failed to load page</h1><p>Unable to fetch: " .. url .. "</p></body></html>"
	end
end

local function navigateToUrl(url: string)
	if url == "" then return end

	-- Show loading state
	if navElements then
		BrowserEngine.showLoading(navElements)
		BrowserEngine.updateAddress(navElements, url)
	end

	-- Fetch and render
	local success, html = pcall(function()
		return getHtml(url)
	end)

	if success and html then
		-- Parse HTML
		local dom = HTMLParser.parse(html)

		-- Render
		local screenGui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("BrowserScreen")
		if screenGui then
			navElements = BrowserEngine.render(dom, screenGui)
		end

		-- Update history
		if url ~= currentUrl then
			-- Remove forward history if we're not at the end
			if historyIndex < #history then
				for i = #history, historyIndex + 1, -1 do
					table.remove(history, i)
				end
			end
			table.insert(history, url)
			historyIndex = #history
			currentUrl = url
		end

		-- Update button states
		if navElements then
			BrowserEngine.hideLoading(navElements)
			navElements.BackButton.AutoButtonColor = historyIndex > 1
			navElements.ForwardButton.AutoButtonColor = historyIndex < #history
		end
	else
		warn("Failed to navigate to:", url)
		if navElements then
			BrowserEngine.hideLoading(navElements)
		end
	end
end

local function init()
	-- Create a ScreenGui to hold the rendered page
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrowserScreen"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Set up navigation callback
	BrowserEngine.onNavigate = function(url)
		navigateToUrl(url)
	end

	-- Navigate to default homepage
	local defaultUrl = "https://en.wikipedia.org/wiki/Main_Page"
	navigateToUrl(defaultUrl)
end

-- Set up back/forward button handlers (will be connected after first render)
local function setupNavigationButtons()
	-- This will be called after first render
	task.spawn(function()
		task.wait(0.5) -- Wait for UI to be created
		local screenGui = Players.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("BrowserScreen")
		if screenGui then
			local mainFrame = screenGui:FindFirstChild("BrowserMainFrame")
			if mainFrame then
				local navBar = mainFrame:FindFirstChild("NavigationBar")
				if navBar then
					local backBtn = navBar:FindFirstChild("BackButton")
					local fwdBtn = navBar:FindFirstChild("ForwardButton")

					if backBtn then
						backBtn.MouseButton1Click:Connect(function()
							if historyIndex > 1 then
								historyIndex = historyIndex - 1
								local url = history[historyIndex]
								navigateToUrl(url)
							end
						end)
					end

					if fwdBtn then
						fwdBtn.MouseButton1Click:Connect(function()
							if historyIndex < #history then
								historyIndex = historyIndex + 1
								local url = history[historyIndex]
								navigateToUrl(url)
							end
						end)
					end
				end
			end
		end
	end)
end

init()
setupNavigationButtons()
