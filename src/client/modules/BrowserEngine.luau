--!strict
--!optimize 2
--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrowserEngine = {}

-- Safe module loader
local function loadModule(name)
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	return require(Shared:WaitForChild("parsers"):WaitForChild(name))
end

local CSSParser = loadModule("CSSParser")

-- Load debug module
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

-- Helper to log with fallback
local function debugLog(level, message, source)
	if Debug then
		Debug[level](message, source or "BrowserEngine")
	else
		print(`[BrowserEngine] {message}`)
	end
end

BrowserEngine.onNavigate = nil
BrowserEngine.onFormSubmit = nil

local currentCSS = {}

-- Apply a single CSS property
local function applySingleStyle(instance, prop, val)
	prop = prop:lower()
	val = val:lower()

	debugLog("verbose", `Applying style: {prop}={val} to {instance.ClassName}`, "BrowserEngine")

	if prop == "background-color" then
		local ok, color = pcall(function()
			return Color3.fromHex(val)
		end)
		if ok then
			instance.BackgroundColor3 = color
			instance.BackgroundTransparency = 0
		else
			debugLog("warn", `Invalid background-color value: {val}`, "BrowserEngine")
		end
	elseif prop == "color" then
		local ok, color = pcall(function()
			return Color3.fromHex(val)
		end)
		if ok then
			instance.TextColor3 = color
		else
			debugLog("warn", `Invalid color value: {val}`, "BrowserEngine")
		end
	elseif prop == "font-size" then
		local num = tonumber(val:match("%d+"))
		if num then
			instance.TextSize = num
		else
			debugLog("warn", `Invalid font-size value: {val}`, "BrowserEngine")
		end
	elseif prop == "font-weight" and val == "bold" then
		instance.Font = Enum.Font.SourceSansBold
	elseif prop == "font-style" and val == "italic" then
		instance.Font = Enum.Font.SourceSansItalic
	elseif prop == "text-align" then
		if val == "center" then
			instance.TextXAlignment = Enum.TextXAlignment.Center
		elseif val == "right" then
			instance.TextXAlignment = Enum.TextXAlignment.Right
		end
	elseif prop == "width" then
		local num = tonumber(val:match("%d+"))
		if num then
			instance.Size = UDim2.new(0, num, instance.Size.Y.Scale, instance.Size.Y.Offset)
		end
	elseif prop == "height" then
		local num = tonumber(val:match("%d+"))
		if num then
			instance.Size = UDim2.new(instance.Size.X.Scale, instance.Size.X.Offset, 0, num)
		end
	elseif prop == "display" and val == "none" then
		instance.Visible = false
	end
end

-- Apply styles to instance
local function applyStyles(instance, attrs, cssStyles)
	debugLog("verbose", `Applying styles to {instance.ClassName}`, "BrowserEngine")
	if attrs and attrs.style then
		for prop, val in attrs.style:gmatch("([%w%-]+):%s*([^;]+)") do
			applySingleStyle(instance, prop:lower(), val)
		end
	end

	if cssStyles then
		for prop, val in pairs(cssStyles) do
			applySingleStyle(instance, prop, val)
		end
	end

	if attrs then
		if attrs.id then
			instance.Name = attrs.id
			debugLog("verbose", `Set instance name to ID: {attrs.id}`, "BrowserEngine")
		end
		if attrs.class then
			instance:SetAttribute("Class", attrs.class)
			debugLog("verbose", `Set class attribute: {attrs.class}`, "BrowserEngine")
		end
	end
end

-- Tag categories
local blockTags = {
	"html", "head", "body", "div", "section", "article", "nav", "aside", "header", "footer", "main",
	"ul", "ol", "li", "dl", "dt", "dd", "table", "thead", "tbody", "tfoot", "tr", "td", "th",
	"form", "fieldset", "legend", "details", "summary", "figure", "figcaption", "blockquote", "pre", "canvas", "svg",
	"math", "iframe", "video", "audio", "embed", "object",
	"metadata", "title", "meta", "link", "style", "script", "noscript", "template", "slot",
	"input", "button", "select", "option", "optgroup", "textarea", "label", "progress", "meter", "output",
	"hr"
}

local inlineTextTags = {
	"p", "span", "a", "b", "i", "strong", "em", "small", "sub", "sup", "mark", "abbr", "cite", "code", "kbd", "samp", "var", "del", "ins", "ruby", "rt", "rp", "q", "time", "u", "s", "strike", "bdi", "bdo",
	"label", "legend", "summary",
	"h1", "h2", "h3", "h4", "h5", "h6",
	"pre", "blockquote", "figcaption"
}

local imageTags = {"img", "image", "picture", "svg"}

-- Convert arrays to sets
local function arrayToSet(arr)
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end

local blockSet = arrayToSet(blockTags)
local inlineSet = arrayToSet(inlineTextTags)
local imageSet = arrayToSet(imageTags)

-- Creator for tag
local function creatorForTag(tag)
	if imageSet[tag] then
		return function() return Instance.new("ImageLabel") end
	elseif inlineSet[tag] then
		if tag == "a" then
			return function() return Instance.new("TextButton") end
		elseif tag == "input" then
			return function() return Instance.new("TextBox") end
		elseif tag == "button" then
			return function() return Instance.new("TextButton") end
		else
			return function() return Instance.new("TextLabel") end
		end
	else
		return function() return Instance.new("Frame") end
	end
end

-- Calculate text height
local function calculateTextHeight(text, textSize, width)
	local charsPerLine = math.floor(width / (textSize * 0.6))
	if charsPerLine <= 0 then
		return textSize + 4
	end
	local lines = math.ceil(#text / charsPerLine)
	return math.max(textSize + 4, lines * (textSize + 2))
end

-- Render a single DOM node
local function renderNode(node, parent, yOffset, maxWidth, cssMap)
	debugLog("verbose", `renderNode: type={node.type}, tag={node.tag or "N/A"}`, "BrowserEngine")
	if node.type == "text" then
		local txt = Instance.new("TextLabel")
		txt.Text = node.text
		txt.Size = UDim2.new(1, -20, 0, calculateTextHeight(node.text, 14, maxWidth or 600))
		txt.Position = UDim2.new(0, 10, 0, yOffset)
		txt.BackgroundTransparency = 1
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.TextYAlignment = Enum.TextYAlignment.Top
		txt.TextWrapped = true
		txt.Font = Enum.Font.SourceSans
		txt.TextSize = 14
		txt.Parent = parent
		debugLog("verbose", `Created TextLabel for text node`, "BrowserEngine")
		return txt, txt.Size.Y.Offset
	elseif node.type == "element" then
		local creator = creatorForTag(node.tag)
		local inst = creator()

		-- Get CSS styles
		local cssStyles = {}
		if cssMap and node.tag then
			cssStyles = CSSParser.matchElement(node, cssMap) or {}
			debugLog("verbose", `Matched {node.tag} to {pairs(cssStyles) and "CSS styles" or "no CSS"}`, "BrowserEngine")
		end

		-- Apply styles
		applyStyles(inst, node.attrs, cssStyles)

		-- Set defaults based on tag
		local height = 24
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			local text = node.attrs.title or node.attrs.alt or node.attrs.value or node.attrs.placeholder or ""
			-- Collect text from children
			for _, child in ipairs(node.children or {}) do
				if child.type == "text" then
					text = text .. child.text
				end
			end

			-- Handle different input types
			if node.tag == "input" then
				if inst:IsA("TextBox") then
					inst.PlaceholderText = node.attrs.placeholder or ""
					inst.Text = node.attrs.value or ""
					inst.Size = UDim2.new(1, -20, 0, 30)
					inst.BackgroundTransparency = 0
					inst.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					inst.BorderSizePixel = 1
					inst.Position = UDim2.new(0, 10, 0, yOffset)
					height = 30
				end
			elseif node.tag == "button" then
				inst.Text = text
				inst.Size = UDim2.new(0, math.max(100, #text * 8 + 20), 0, 32)
				inst.BackgroundTransparency = 0
				inst.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
				inst.Position = UDim2.new(0, 10, 0, yOffset)
				inst.Font = Enum.Font.SourceSans
				inst.TextSize = 14
				height = 32
			else
				-- Regular text element
				inst.Text = text
				inst.TextWrapped = true
				inst.Size = UDim2.new(1, -20, 0, calculateTextHeight(text, inst.TextSize, maxWidth or 600))
				inst.BackgroundTransparency = 0.7
				inst.TextXAlignment = Enum.TextXAlignment.Left
				inst.Position = UDim2.new(0, 10, 0, yOffset)
				inst.Font = Enum.Font.SourceSans

				-- Handle links
				if node.tag == "a" and node.attrs.href then
					inst.BackgroundTransparency = 1
					inst.TextColor3 = Color3.fromRGB(0, 102, 204)
					inst.Font = Enum.Font.SourceSans
					inst.MouseEnter:Connect(function()
						inst.TextColor3 = Color3.fromRGB(204, 0, 0)
						inst.Font = Enum.Font.SourceSansUnderline
					end)
					inst.MouseLeave:Connect(function()
						inst.TextColor3 = Color3.fromRGB(0, 102, 204)
						inst.Font = Enum.Font.SourceSans
					end)
					inst.MouseButton1Click:Connect(function()
						debugLog("log", `Link clicked: {node.attrs.href}`, "BrowserEngine")
						if BrowserEngine.onNavigate then
							BrowserEngine.onNavigate(node.attrs.href)
						end
					end)
				end
				height = inst.Size.Y.Offset
			end
		elseif inst:IsA("ImageLabel") then
			local src = node.attrs.src or ""
			if src ~= "" then
				inst.Image = src
				debugLog("verbose", `Set image source: {src}`, "BrowserEngine")
			end
			inst.Size = UDim2.new(0, 200, 0, 200)
			inst.Position = UDim2.new(0, 10, 0, yOffset)
			inst.BackgroundTransparency = 0
			inst.ScaleType = Enum.ScaleType.Fit
			height = 200
		else
			-- Block elements
			inst.Size = UDim2.new(1, -20, 0, 30)
			inst.Position = UDim2.new(0, 10, 0, yOffset)
			inst.BackgroundTransparency = 1

			-- Special handling for headings
			if node.tag == "h1" then
				inst.Size = UDim2.new(1, -20, 0, 40)
				height = 40
			elseif node.tag == "h2" then
				inst.Size = UDim2.new(1, -20, 0, 32)
				height = 32
			elseif node.tag == "h3" then
				inst.Size = UDim2.new(1, -20, 0, 28)
				height = 28
			elseif node.tag == "hr" then
				inst.Size = UDim2.new(1, -20, 0, 2)
				inst.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
				inst.BackgroundTransparency = 0
				height = 2
			elseif node.tag == "form" then
				inst.Size = UDim2.new(1, -20, 0, 100)
				inst.BackgroundTransparency = 0.9
				inst.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
				inst.BorderSizePixel = 1
				height = 100
			end
		end

		inst.Parent = parent
		debugLog("verbose", `Rendered {node.tag or "unknown"} element, height={height}`, "BrowserEngine")

		-- Render children
		local childYOffset = 0
		for _, child in ipairs(node.children or {}) do
			local _, childHeight = renderNode(child, inst, childYOffset, maxWidth, cssMap)
			childYOffset = childYOffset + (childHeight or 0)
		end

		-- Update parent height for containers
		if inst:IsA("Frame") and not inst:IsA("ScrollingFrame") then
			inst.Size = UDim2.new(inst.Size.X.Scale, inst.Size.X.Offset, 0, childYOffset + 10)
		end

		return inst, height
	end
	return nil, 0
end

-- Create navigation bar
local function createNavigationBar(parent, onNavigate)
	local navBar = Instance.new("Frame")
	navBar.Name = "NavigationBar"
	navBar.Size = UDim2.new(1, 0, 0, 40)
	navBar.Position = UDim2.new(0, 0, 0, 0)
	navBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	navBar.BorderSizePixel = 1
	navBar.Parent = parent

	-- Back button
	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackButton"
	backBtn.Size = UDim2.new(0, 40, 0, 30)
	backBtn.Position = UDim2.new(0, 5, 0, 5)
	backBtn.Text = "←"
	backBtn.Font = Enum.Font.SourceSansBold
	backBtn.TextSize = 18
	backBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backBtn.Parent = navBar

	-- Forward button
	local fwdBtn = Instance.new("TextButton")
	fwdBtn.Name = "ForwardButton"
	fwdBtn.Size = UDim2.new(0, 40, 0, 30)
	fwdBtn.Position = UDim2.new(0, 50, 0, 5)
	fwdBtn.Text = "→"
	fwdBtn.Font = Enum.Font.SourceSansBold
	fwdBtn.TextSize = 18
	fwdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fwdBtn.Parent = navBar

	-- Refresh button
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Name = "RefreshButton"
	refreshBtn.Size = UDim2.new(0, 40, 0, 30)
	refreshBtn.Position = UDim2.new(0, 95, 0, 5)
	refreshBtn.Text = "↻"
	refreshBtn.Font = Enum.Font.SourceSansBold
	refreshBtn.TextSize = 18
	refreshBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	refreshBtn.Parent = navBar

	-- Address bar
	local addressBar = Instance.new("TextBox")
	addressBar.Name = "AddressBar"
	addressBar.Size = UDim2.new(1, -200, 0, 30)
	addressBar.Position = UDim2.new(0, 140, 0, 5)
	addressBar.Text = "https://en.wikipedia.org/wiki/Main_Page"
	addressBar.Font = Enum.Font.SourceSans
	addressBar.TextSize = 14
	addressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	addressBar.BorderSizePixel = 1
	addressBar.ClearTextOnFocus = false
	addressBar.Parent = navBar

	-- Go button
	local goBtn = Instance.new("TextButton")
	goBtn.Name = "GoButton"
	goBtn.Size = UDim2.new(0, 40, 0, 30)
	goBtn.Position = UDim2.new(1, -45, 0, 5)
	goBtn.Text = "Go"
	goBtn.Font = Enum.Font.SourceSansBold
	goBtn.TextSize = 14
	goBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	goBtn.Parent = navBar

	-- Loading indicator
	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(0, 100, 0, 30)
	loadingLabel.Position = UDim2.new(1, -150, 0, 5)
	loadingLabel.Text = ""
	loadingLabel.Font = Enum.Font.SourceSans
	loadingLabel.TextSize = 12
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.TextColor3 = Color3.fromRGB(0, 120, 215)
	loadingLabel.Visible = false
	loadingLabel.Parent = navBar

	-- Navigation logic
	local function navigateToUrl()
		local url = addressBar.Text
		if url ~= "" then
			if not url:match("^https?://") then
				url = "https://" .. url
				addressBar.Text = url
			end
			if onNavigate then
				onNavigate(url)
			end
		end
	end

	goBtn.MouseButton1Click:Connect(navigateToUrl)
	addressBar.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			navigateToUrl()
		end
	end)

	return {
		Frame = navBar,
		AddressBar = addressBar,
		BackButton = backBtn,
		ForwardButton = fwdBtn,
		RefreshButton = refreshBtn,
		GoButton = goBtn,
		LoadingLabel = loadingLabel,
	}
end

-- Public API: render
function BrowserEngine.render(domRoot, targetGui)
	debugLog("log", `Rendering DOM to {targetGui:GetFullName()}`, "BrowserEngine")
	if not targetGui or not targetGui:IsA("ScreenGui") then
		debugLog("error", "render: targetGui must be a ScreenGui instance", "BrowserEngine")
		error("BrowserEngine.render: targetGui must be a ScreenGui instance")
	end

	targetGui:ClearAllChildren()
	debugLog("verbose", "Cleared existing children from targetGui", "BrowserEngine")

	-- Parse CSS from DOM
	local cssMap = {}
	if domRoot.css then
		debugLog("log", "Found CSS in DOM, parsing...", "BrowserEngine")
		cssMap = CSSParser.parse(domRoot.css)
		currentCSS = cssMap
		debugLog("verbose", `Parsed CSS with {pairs(cssMap) and "rules" or "no rules"}`, "BrowserEngine")
	end

	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "BrowserMainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = targetGui

	-- Navigation bar
	local nav = createNavigationBar(mainFrame, function(url)
		if BrowserEngine.onNavigate then
			BrowserEngine.onNavigate(url)
		end
	end)

	-- Content scrolling frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "BrowserContent"
	scrollFrame.Size = UDim2.new(1, 0, 1, -40)
	scrollFrame.Position = UDim2.new(0, 0, 0, 40)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	-- Render DOM into scrolling frame
	local yOffset = 0
	local maxWidth = scrollFrame.AbsoluteSize.X - 20

	-- Update maxWidth when frame resizes
	scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		maxWidth = scrollFrame.AbsoluteSize.X - 20
	end)

	debugLog("log", `Rendering {#domRoot.children or 0} top-level nodes`, "BrowserEngine")
	for _, child in ipairs(domRoot.children or {}) do
		local _, height = renderNode(child, scrollFrame, yOffset, maxWidth, cssMap)
		yOffset = yOffset + (height or 0)
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
	debugLog("verbose", `Canvas size updated, total height: {yOffset + 20}`, "BrowserEngine")

	return {
		MainFrame = mainFrame,
		NavigationBar = nav,
		ContentFrame = scrollFrame,
	}
end

-- Show loading state
function BrowserEngine.showLoading(navBarElements)
	debugLog("verbose", "Showing loading state", "BrowserEngine")
	if navBarElements and navBarElements.LoadingLabel then
		navBarElements.LoadingLabel.Text = "Loading..."
		navBarElements.LoadingLabel.Visible = true
	end
end

-- Hide loading state
function BrowserEngine.hideLoading(navBarElements)
	debugLog("verbose", "Hiding loading state", "BrowserEngine")
	if navBarElements and navBarElements.LoadingLabel then
		navBarElements.LoadingLabel.Visible = false
	end
end

-- Update address bar
function BrowserEngine.updateAddress(navBarElements, url)
	debugLog("verbose", `Updating address bar: {url}`, "BrowserEngine")
	if navBarElements and navBarElements.AddressBar then
		navBarElements.AddressBar.Text = url
	end
end

return BrowserEngine
