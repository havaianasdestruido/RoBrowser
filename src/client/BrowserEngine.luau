--!strict
--!optimize 2
--!native
--[[
  BrowserEngine – renders a lightweight DOM (produced by HTMLParser) into
  Roblox GUI objects (Frame, TextLabel, ImageLabel, etc.).
  Supports a wide range of HTML tags (see utils/html_tags.txt).
  Tags are grouped into block elements, inline text elements, and media.
]]

local BrowserEngine = {}

-- Helper: apply basic style attributes to a Roblox Instance
local function applyStyles(instance, attrs)
    if not attrs then return end
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
    if attrs.id then instance.Name = attrs.id end
    if attrs.class then instance:SetAttribute("Class", attrs.class) end
end

-- Tag categories ------------------------------------------------------------
local blockTags = {
    "html","head","body","div","section","article","nav","aside","header","footer","main",
    "ul","ol","li","dl","dt","dd","table","thead","tbody","tfoot","tr","td","th",
    "form","fieldset","legend","details","summary","figure","figcaption","blockquote","pre","canvas","svg",
    "math","iframe","video","audio","embed","object","canvas","g","path","rect","circle","ellipse","line","polygon","polyline",
    "mask","filter","lineargradient","radialgradient","pattern","defs","symbol","use","marker","clipPath",
    "metadata","title","meta","link","style","script","noscript","template","slot","input","button","select","option","optgroup",
    "textarea","label","fieldset","legend","progress","meter","output","fieldset",
    "hr","br","wbr",
}

local inlineTextTags = {
    "p","span","a","b","i","strong","em","small","sub","sup","mark","abbr","cite","code","kbd","samp","var","del","ins","ruby","rt","rp","q","time","u","s","strike","bdi","bdo","cite","dfn","address","cite","cite","cite",
    "label","legend","summary",
    "h1","h2","h3","h4","h5","h6",
    "pre","blockquote","figcaption",
}

local imageTags = {"img","image","picture","svg"}

-- Helper to check table membership
local function inSet(set, key)
    return set[key] ~= nil
end

-- Convert arrays to set tables for O(1) lookup
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
    if inSet(imageSet, tag) then
        return function() return Instance.new("ImageLabel") end
    elseif inSet(inlineSet, tag) then
        if tag == "a" then
            return function() return Instance.new("TextButton") end
        else
            return function() return Instance.new("TextLabel") end
        end
    else
        -- default to Frame for block elements and unknown tags
        return function() return Instance.new("Frame") end
    end
end

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
        local creator = creatorForTag(node.tag)
        local inst = creator()
        applyStyles(inst, node.attrs)
        -- Set sensible defaults
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
    targetGui:ClearAllChildren()
    local container = Instance.new("Frame")
    container.Name = "BrowserContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = targetGui
    for _, child in ipairs(domRoot.children or {}) do
        renderNode(child, container)
    end
    return container
end

return BrowserEngine


