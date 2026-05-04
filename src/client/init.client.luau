--!strict
--!optimize 2
--!native
--[[
  Client entry point – fetches HTML via a server RemoteFunction, parses it, and renders
  the DOM using the BrowserEngine. Supports navigation, back/forward history,
  bookmarks, refresh, and error handling. Default homepage is Wikipedia.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules from ReplicatedStorage.Shared (Rojo maps src/shared here)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local HTMLParser = require(Shared:WaitForChild("parsers"):WaitForChild("HTMLParser"))
local BrowserEngine = require(Shared:WaitForChild("modules"):WaitForChild("BrowserEngine"))
local Debug = require(Shared:WaitForChild("debug"))

-- RemoteFunction that the server provides for HTTP requests
local fetchHTML = ReplicatedStorage:WaitForChild("FetchHTML")

-- Navigation history
local history = {}
local historyIndex = 0
local currentUrl = ""
local isNavigating = false

-- Bookmarks
local bookmarks = {
	{title = "Wikipedia", url = "https://en.wikipedia.org/wiki/Main_Page"},
	{title = "Google", url = "https://www.google.com"},
	{title = "FrogFind!", url = "https://frogfind.com/"}
}

-- UI elements reference
local navElements = nil
local currentScreenGui = nil

local function getHtml(url: string): string
	Debug.verbose(`Fetching HTML from: {url}`, "Client")
	local result = fetchHTML:InvokeServer(url)
	if result then
		Debug.log(`Successfully fetched HTML ({#result} chars)`, "Client")
		return result
	else
		Debug.warn(`Failed to fetch URL via server: {url}`, "Client")
		return nil
	end
end

local function updateNavButtons()
	if not navElements then return end
	navElements.BackButton.AutoButtonColor = historyIndex > 1
	navElements.ForwardButton.AutoButtonColor = historyIndex < #history
end

local function navigateToUrl(url: string)
	if url == "" or isNavigating then
		Debug.verbose(`Navigation skipped: url="{url}", isNavigating={isNavigating}`, "Client")
		return
	end
	isNavigating = true
	Debug.log(`Navigating to: {url}`, "Client")

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
		Debug.verbose(`Fetched HTML, parsing...`, "Client")
		-- Parse HTML
		local success2, dom = pcall(function()
			return HTMLParser.parse(html)
		end)

		if success2 and dom then
			Debug.log(`DOM parsed successfully`, "Client")
			-- Extract title
			local pageTitle = "Untitled"
			for _, child in ipairs(dom.children or {}) do
				if child.type == "element" and child.tag == "head" then
					for _, headChild in ipairs(child.children or {}) do
						if headChild.type == "element" and headChild.tag == "title" then
							pageTitle = headChild.children[1] and headChild.children[1].text or "Untitled"
							break
						end
					end
					break
				end
			end
			Debug.log(`Page title: {pageTitle}`, "Client")

			-- Render
			if currentScreenGui then
				navElements = BrowserEngine.render(dom, currentScreenGui)
				-- Reconnect navigation callbacks
				BrowserEngine.onNavigate = function(newUrl)
					Debug.verbose(`Navigation callback triggered: {newUrl}`, "Client")
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
				Debug.log(`History updated: index={historyIndex}, total={#history}`, "Client")
			end

			-- Update button states
			updateNavButtons()

			-- Hide loading
			if navElements then
				BrowserEngine.hideLoading(navElements)
			end
		else
			Debug.warn(`Failed to parse HTML from: {url}`, "Client")
			if navElements then
				BrowserEngine.hideLoading(navElements)
			end
		end
	else
		Debug.error(`Failed to navigate to: {url}`, "Client")
		if navElements then
			BrowserEngine.hideLoading(navElements)
			-- Show error page
			local errorHtml = "<html><head><title>Error</title></head><body><h1>Failed to load page</h1><p>Unable to fetch: " .. url .. "</p></body></html>"
			local dom = HTMLParser.parse(errorHtml)
			if currentScreenGui then
				navElements = BrowserEngine.render(dom, currentScreenGui)
			end
		end
	end

	isNavigating = false
end

local function init()
	Debug.log("Client initializing", "Client")
	-- Create a ScreenGui to hold the rendered page
	currentScreenGui = Instance.new("ScreenGui")
	currentScreenGui.Name = "BrowserScreen"
	currentScreenGui.ResetOnSpawn = false
	currentScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	Debug.verbose("ScreenGui created and parented to PlayerGui", "Client")

	-- Set up navigation callback
	BrowserEngine.onNavigate = function(url)
		navigateToUrl(url)
	end

	-- Navigate to default homepage
	local defaultUrl = "https://frogfind.com/"
	Debug.log(`Navigating to default URL: {defaultUrl}`, "Client")
	navigateToUrl(defaultUrl)
end

-- Set up back/forward button handlers
local function setupNavigationButtons()
	Debug.verbose("Setting up navigation button handlers", "Client")
	task.spawn(function()
		task.wait(1) -- Wait for UI to be created
		while task.wait(0.5) do
			if navElements then
				local backBtn = navElements.BackButton
				local fwdBtn = navElements.ForwardButton
				local refreshBtn = navElements.RefreshButton

				if backBtn and not backBtn:GetAttribute("ClickConnected") then
					backBtn:SetAttribute("ClickConnected", true)
					backBtn.MouseButton1Click:Connect(function()
						Debug.log(`Back button clicked, historyIndex={historyIndex}`, "Client")
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
						Debug.log(`Forward button clicked, historyIndex={historyIndex}`, "Client")
						if historyIndex < #history then
							historyIndex = historyIndex + 1
							local url = history[historyIndex]
							navigateToUrl(url)
						end
					end)
				end

				if refreshBtn and not refreshBtn:GetAttribute("ClickConnected") then
					refreshBtn:SetAttribute("ClickConnected", true)
					refreshBtn.MouseButton1Click:Connect(function()
						Debug.log(`Refresh button clicked, url={currentUrl}`, "Client")
						if currentUrl ~= "" then
							navigateToUrl(currentUrl)
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
