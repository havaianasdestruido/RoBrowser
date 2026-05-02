--!strict
--!optimize 2
--!native
--[[
  BrowserEngine – renders a lightweight DOM (produced by HTMLParser) into
  Roblox GUI objects (Frame, TextLabel, ImageLabel, etc.).
  Supports a wide range of HTML tags (see utils/html_tags.txt).
  Tags are grouped into block elements, inline text elements, and media.
  Includes navigation bar, scrolling, link handling, loading states, and CSS support.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrowserEngine = {}

-- Require CSS parser
local CSSParser = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CSSParser"))

-- Navigation callback (set by client)
BrowserEngine.onNavigate = nil

-- Store parsed CSS for current page
local currentCSS = {}

-- Apply a single CSS property
local function applySingleStyle(instance, prop, val)
	prop = prop:lower()
	val = val:lower()

	if prop == "background-color" then
		local ok, color = pcall(function() return Color3.fromHex(val) end)
		if ok then
			instance.BackgroundColor3 = color
			instance.BackgroundTransparency = 0
		end
	elseif prop == "color" then
		local ok, color = pcall(function() return Color3.fromHex(val) end)
		if ok then instance.TextColor3 = color end
	elseif prop == "font-size" then
		local num = tonumber(val:match("%d+"))
		if num then instance.TextSize = num end
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
		if num then instance.Size = UDim2.new(0, num, instance.Size.Y.Scale, instance.Size.Y.Offset) end
	elseif prop == "height" then
		local num = tonumber(val:match("%d+"))
		if num then instance.Size = UDim2.new(instance.Size.X.Scale, instance.Size.X.Offset, 0, num) end
	elseif prop == "display" and val == "none" then
		instance.Visible = false
	end
end

-- Helper: apply styles to a Roblox Instance
local function applyStyles(instance, attrs, cssStyles)
	-- Apply inline styles first
	if attrs and attrs.style then
		for prop, val in attrs.style:gmatch("([%w%-]+):%s*([^;]+)") do
			prop = prop:lower()
			applySingleStyle(instance, prop, val)
		end
	end

	-- Apply CSS styles
	if cssStyles then
		for prop, val in pairs(cssStyles) do
			applySingleStyle(instance, prop, val)
		end
	end

	if attrs then
		if attrs.id then instance.Name = attrs.id end
		if attrs.class then instance:SetAttribute("Class", attrs.class) end
	end
end

-- Tag categories
local blockTags = {
	"html","head","body","div","section","article","nav","aside","header","footer","main",
	"ul","ol","li","dl","dt","dd","table","thead","tbody","tfoot","tr","td","th",
	"form","fieldset","legend","details","summary","figure","figcaption","blockquote","pre","canvas","svg",
	"math","iframe","video","audio","embed","object","g","path","rect","circle","ellipse","line","polygon","polyline",
	"mask","filter","lineargradient","radialgradient","pattern","defs","symbol","use","marker","clipPath",
	"metadata","title","meta","link","style","script","noscript","template","slot","input","button","select","option","optgroup",
	"textarea","label","progress","meter","output",
	"hr",
}

local inlineTextTags = {
	"p","span","a","b","i","strong","em","small","sub","sup","mark","abbr","cite","code","kbd","samp","var","del","ins","ruby","rt","rp","q","time","u","s","strike","bdi","bdo",
	"label","legend","summary",
	"h1","h2","h3","h4","h5","h6",
	"pre","blockquote","figcaption",
}

local imageTags = {"img","image","picture","svg"}

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

-- Mapping function: returns a creator based on tag
local function creatorForTag(tag)
	if imageSet[tag] then
		return function() return Instance.new("ImageLabel") end
	elseif inlineSet[tag] then
		if tag == "a" then
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
	if charsPerLine <= 0 then return textSize + 4 end
	local lines = math.ceil(#text / charsPerLine)
	return math.max(textSize + 4, lines * (textSize + 2))
end

-- Render a single DOM node
local function renderNode(node, parent, yOffset, maxWidth, cssMap)
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
		return txt, txt.Size.Y.Offset
	elseif node.type == "element" then
		local creator = creatorForTag(node.tag)
		local inst = creator()

		-- Get CSS styles
		local cssStyles = {}
		if cssMap and node.tag then
			cssStyles = CSSParser.matchElement(node, cssMap) or {}
		end

		-- Apply styles
		applyStyles(inst, node.attrs, cssStyles)

		-- Set defaults based on tag
		local height = 24
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then
			local text = node.attrs.title or node.attrs.alt or ""
			for _, child in ipairs(node.children or {}) do
				if child.type == "text" then
					text = text .. child.text
				end
			end
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
				inst.MouseEnter:Connect(function()
					inst.TextColor3 = Color3.fromRGB(204, 0, 0)
					inst.Font = Enum.Font.SourceSansUnderline
				end)
				inst.MouseLeave:Connect(function()
					inst.TextColor3 = Color3.fromRGB(0, 102, 204)
					inst.Font = Enum.Font.SourceSans
				end)
				inst.MouseButton1Click:Connect(function()
					if BrowserEngine.onNavigate then
						BrowserEngine.onNavigate(node.attrs.href)
					end
				end)
			end
			height = inst.Size.Y.Offset
		elseif inst:IsA("ImageLabel") then
			local src = node.attrs.src or ""
			if src ~= "" then
				inst.Image = src
			end
			inst.Size = UDim2.new(0, 200, 0, 200)
			inst.Position = UDim2.new(0, 10, 0, yOffset)
			inst.BackgroundTransparency = 0
			inst.ScaleType = Enum.ScaleType.Fit
			height = 200
		else
			inst.Size = UDim2.new(1, -20, 0, 30)
			inst.Position = UDim2.new(0, 10, 0, yOffset)
			inst.BackgroundTransparency = 1

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
			end
		end

		inst.Parent = parent

		-- Render children
		local childYOffset = 0
		for _, child in ipairs(node.children or {}) do
			local _, childHeight = renderNode(child, inst, childYOffset, maxWidth, cssMap)
			childYOffset = childYOffset + (childHeight or 0)
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

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackButton"
	backBtn.Size = UDim2.new(0, 40, 0, 30)
	backBtn.Position = UDim2.new(0, 5, 0, 5)
	backBtn.Text = "←"
	backBtn.Font = Enum.Font.SourceSansBold
	backBtn.TextSize = 18
	backBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backBtn.Parent = navBar

	local fwdBtn = Instance.new("TextButton")
	fwdBtn.Name = "ForwardButton"
	fwdBtn.Size = UDim2.new(0, 40, 0, 30)
	fwdBtn.Position = UDim2.new(0, 50, 0, 5)
	fwdBtn.Text = "→"
	fwdBtn.Font = Enum.Font.SourceSansBold
	fwdBtn.TextSize = 18
	fwdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fwdBtn.Parent = navBar

	local addressBar = Instance.new("TextBox")
	addressBar.Name = "AddressBar"
	addressBar.Size = UDim2.new(1, -150, 0, 30)
	addressBar.Position = UDim2.new(0, 95, 0, 5)
	addressBar.Text = "https://en.wikipedia.org/wiki/Main_Page"
	addressBar.Font = Enum.Font.SourceSans
	addressBar.TextSize = 14
	addressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	addressBar.BorderSizePixel = 1
	addressBar.ClearTextOnFocus = false
	addressBar.Parent = navBar

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
		GoButton = goBtn,
		LoadingLabel = loadingLabel,
	}
end

-- Public API: render(domRoot, targetGui)
function BrowserEngine.render(domRoot, targetGui)
	if not targetGui or not targetGui:IsA("ScreenGui") then
		error("BrowserEngine.render: targetGui must be a ScreenGui instance")
	end

	targetGui:ClearAllChildren()

	-- Parse CSS from DOM
	local cssMap = {}
	if domRoot.css then
		cssMap = CSSParser.parse(domRoot.css)
		currentCSS = cssMap
	end

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "BrowserMainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = targetGui

	local nav = createNavigationBar(mainFrame, function(url)
		if BrowserEngine.onNavigate then
			BrowserEngine.onNavigate(url)
		end
	end)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "BrowserContent"
	scrollFrame.Size = UDim2.new(1, 0, 1, -40)
	scrollFrame.Position = UDim2.new(0, 0, 0, 40)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	local yOffset = 0
	local maxWidth = scrollFrame.AbsoluteSize.X - 20

	scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		maxWidth = scrollFrame.AbsoluteSize.X - 20
	end)

	for _, child in ipairs(domRoot.children or {}) do
		local _, height = renderNode(child, scrollFrame, yOffset, maxWidth, cssMap)
		yOffset = yOffset + (height or 0)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)

	return {
		MainFrame = mainFrame,
		NavigationBar = nav,
		ContentFrame = scrollFrame,
	}
end

-- Show/hide loading state
function BrowserEngine.showLoading(navBarElements)
	if navBarElements and navBarElements.LoadingLabel then
		navBarElements.LoadingLabel.Text = "Loading..."
		navBarElements.LoadingLabel.Visible = true
	end
end

function BrowserEngine.hideLoading(navBarElements)
	if navBarElements and navBarElements.LoadingLabel then
		navBarElements.LoadingLabel.Visible = false
	end
end

function BrowserEngine.updateAddress(navBarElements, url)
	if navBarElements and navBarElements.AddressBar then
		navBarElements.AddressBar.Text = url
	end
end

return BrowserEngine
