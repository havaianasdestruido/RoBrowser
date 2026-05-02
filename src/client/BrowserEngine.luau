--!strict
--[[
  BrowserEngine – renders a lightweight DOM (produced by HTMLParser) into
  Roblox GUI objects (Frame, TextLabel, ImageLabel, etc.).
  Supports a subset of HTML tags and a few inline styles.
]]

local BrowserEngine = {}

-- Helper: apply basic style attributes to a Roblox Instance
local function applyStyles(instance, attrs)
    if not attrs then return end
    -- background-color (e.g. "#ff0000" or "rgb(255,0,0)")
    if attrs.style then
        for prop, val in attrs.style:gmatch("([%w%-]+):%s*([^;]+)") do
            prop = prop:lower()
            if prop == "background-color" then
                local ok, color = pcall(function() return Color3.fromHex(val) end)
                if ok then instance.BackgroundColor3 = color end
                instance.BackgroundTransparency = 0
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
            end
        end
    end
    -- id / class can be stored for later theming (optional)
    if attrs.id then instance.Name = attrs.id end
    if attrs.class then instance:SetAttribute("Class", attrs.class) end
end

-- Mapping of HTML tag → Roblox instance type and default properties
local tagMap = {
    div = function() return Instance.new("Frame") end,
    p = function() return Instance.new("TextLabel") end,
    span = function() return Instance.new("TextLabel") end,
    a = function() return Instance.new("TextButton") end,
    img = function() return Instance.new("ImageLabel") end,
    br = function() return Instance.new("Frame") end, -- thin spacer line
    h1 = function() return Instance.new("TextLabel") end,
    h2 = function() return Instance.new("TextLabel") end,
    h3 = function() return Instance.new("TextLabel") end,
    h4 = function() return Instance.new("TextLabel") end,
    h5 = function() return Instance.new("TextLabel") end,
    h6 = function() return Instance.new("TextLabel") end,
    ul = function() return Instance.new("Frame") end,
    ol = function() return Instance.new("Frame") end,
    li = function() return Instance.new("TextLabel") end,
    strong = function() return Instance.new("TextLabel") end,
    em = function() return Instance.new("TextLabel") end,
    pre = function() return Instance.new("TextLabel") end,
    code = function() return Instance.new("TextLabel") end,
    blockquote = function() return Instance.new("TextLabel") end,
    table = function() return Instance.new("Frame") end,
    tr = function() return Instance.new("Frame") end,
    td = function() return Instance.new("TextLabel") end,
    th = function() return Instance.new("TextLabel") end,
}

-- Render a single DOM node into a Roblox Instance
local function renderNode(node, parent)
    if node.type == "text" then
        local txt = Instance.new("TextLabel")
        txt.Text = node.text
        txt.Size = UDim2.new(1, 0, 0, 18)
        txt.BackgroundTransparency = 1
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextYAlignment = Enum.TextYAlignment.Top
        txt.Parent = parent
        return txt
    elseif node.type == "element" then
        local creator = tagMap[node.tag]
        if not creator then
            -- fallback: treat unknown tags as generic Frame container
            creator = function() return Instance.new("Frame") end
        end
        local inst = creator()
        applyStyles(inst, node.attrs)
        -- Basic defaults for text‑based elements
        if inst:IsA("TextLabel") or inst:IsA("TextButton") then
            inst.Text = node.attrs.title or ""
            inst.Size = UDim2.new(1, 0, 0, 24)
            inst.BackgroundTransparency = 0.7
            inst.TextXAlignment = Enum.TextXAlignment.Left
        elseif inst:IsA("ImageLabel") then
            inst.Image = node.attrs.src or ""
            inst.Size = UDim2.new(0, 200, 0, 200)
        else
            inst.Size = UDim2.new(1, 0, 0, 20)
            inst.BackgroundTransparency = 1
        end
        inst.Parent = parent
        -- Recursively render children
        for _, child in ipairs(node.children or {}) do
            renderNode(child, inst)
        end
        return inst
    end
end

-- Public API: render(domRoot, targetGui)
function BrowserEngine.render(domRoot, targetGui)
    if not targetGui or not targetGui:IsA("ScreenGui") then
        error("BrowserEngine.render: targetGui must be a ScreenGui instance")
    end
    -- Clear any previous content
    targetGui:ClearAllChildren()
    -- Create a container Frame that will hold the full page
    local container = Instance.new("Frame")
    container.Name = "BrowserContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = targetGui
    -- Render the children of the root (usually <body>)
    for _, child in ipairs(domRoot.children or {}) do
        renderNode(child, container)
    end
    return container
end

return BrowserEngine

