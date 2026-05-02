--!strict
--!optimize 2
--!native
--[[
  Client entry point – fetches HTML via a server RemoteFunction, parses it, and renders
  the DOM using the BrowserEngine. Supports navigation, back/forward history,
  loading states, and error handling. Default homepage is Wikipedia.
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
local isNavigating = false

-- UI elements reference
local navElements = nil
local currentScreenGui = nil

local function getHtml(url: string): string
	local result = fetchHTML:InvokeServer(url)
	if result then
		return result
	else
		warn("Failed to fetch URL via server:", url)
		return nil
	end
end

local function updateNavButtons()
	if not navElements then return end
	navElements.BackButton.AutoButtonColor = historyIndex > 1
	navElements.ForwardButton.AutoButtonColor = historyIndex < #history
end

local function navigateToUrl(url: string)
	if url == "" or isNavigating then return end
	isNavigating = true

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
		local success2, dom = pcall(function()
			return HTMLParser.parse(html)
		end)

		if success2 and dom then
			-- Render
			if currentScreenGui then
				navElements = BrowserEngine.render(dom, currentScreenGui)
				-- Reconnect navigation callbacks
				BrowserEngine.onNavigate = function(newUrl)
					navigateToUrl(newUrl)
				end
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
			updateNavButtons()

			-- Hide loading
			if navElements then
				BrowserEngine.hideLoading(navElements)
			end
		else
			warn("Failed to parse HTML from:", url)
			if navElements then
				BrowserEngine.hideLoading(navElements)
			end
		end
	else
		warn("Failed to navigate to:", url)
		if navElements then
			BrowserEngine.hideLoading(navElements)
			-- Show error page
			local errorHtml = "<html><body><h1>Failed to load page</h1><p>Unable to fetch: " .. url .. "</p></body></html>"
			local dom = HTMLParser.parse(errorHtml)
			if currentScreenGui then
				navElements = BrowserEngine.render(dom, currentScreenGui)
			end
		end
	end

	isNavigating = false
end

local function init()
	-- Create a ScreenGui to hold the rendered page
	currentScreenGui = Instance.new("ScreenGui")
	currentScreenGui.Name = "BrowserScreen"
	currentScreenGui.ResetOnSpawn = false
	currentScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Set up navigation callback
	BrowserEngine.onNavigate = function(url)
		navigateToUrl(url)
	end

	-- Navigate to default homepage
	local defaultUrl = "https://en.wikipedia.org/wiki/Main_Page"
	navigateToUrl(defaultUrl)
end

-- Set up back/forward button handlers
local function setupNavigationButtons()
	task.spawn(function()
		task.wait(1) -- Wait for UI to be created
		while task.wait(0.5) do
			if navElements then
				local backBtn = navElements.BackButton
				local fwdBtn = navElements.ForwardButton

				if backBtn and not backBtn:GetAttribute("ClickConnected") then
					backBtn:SetAttribute("ClickConnected", true)
					backBtn.MouseButton1Click:Connect(function()
						if historyIndex > 1 then
							historyIndex = historyIndex - 1
							local url = history[historyIndex]
							navigateToUrl(url)
						end
					end)
				end

				if fwdBtn and not fwdBtn:GetAttribute("ClickConnected") then
					fwdBtn:SetAttribute("ClickConnected", true)
					fwdBtn.MouseButton1Click:Connect(function()
						if historyIndex < #history then
							historyIndex = historyIndex + 1
							local url = history[historyIndex]
							navigateToUrl(url)
						end
					end)
				end

				-- Update button states
				updateNavButtons()
			end
		end
	end)
end

init()
setupNavigationButtons()
