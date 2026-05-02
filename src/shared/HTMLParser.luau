--[[
  Simple HTML parser for Roblox Luau.
  Parses a subset of HTML into a lightweight DOM structure.
  Supported tags: div, p, span, a, img, br, h1-h6, ul, li, ol, strong, em.
  Attributes supported: id, class, src, href, style.
  The parser is intentionally minimal – it tokenises tags and builds a tree of Nodes.
  Node types: ElementNode, TextNode.
  Usage:
    local parser = require(script.HTMLParser)
    local dom = parser.parse(htmlString)
    -- dom is the root ElementNode representing the document body.
]]

local HTMLParser = {}

-- Node constructors ------------------------------------------------------------
local function ElementNode(tag, attrs)
    return {
        type = "element",
        tag = tag,
        attrs = attrs or {},
        children = {},
    }
end

local function TextNode(text)
    return {
        type = "text",
        text = text,
    }
end

-- Helper to trim whitespace ---------------------------------------------------
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Simple attribute parser: converts `key="value"` pairs into a table.
local function parseAttributes(attrString)
    local attrs = {}
    for key, value in attrString:gmatch("(%w+)%s*=%s*\"(.-)\"") do
        attrs[key] = value
    end
    return attrs
end

-- Tokeniser ------------------------------------------------------------------
local function tokenize(html)
    local tokens = {}
    local pos = 1
    while pos <= #html do
        local char = html:sub(pos, pos)
        if char == "<" then
            -- find end of tag
            local close = html:find(">", pos)
            if not close then break end
            local tagContent = html:sub(pos + 1, close - 1)
            table.insert(tokens, {type = "tag", content = tagContent})
            pos = close + 1
        else
            -- text node until next '<'
            local nextTag = html:find("<", pos) or (#html + 1)
            local text = html:sub(pos, nextTag - 1)
            table.insert(tokens, {type = "text", content = text})
            pos = nextTag
        end
    end
    return tokens
end

-- Parser ---------------------------------------------------------------------
function HTMLParser.parse(html)
    local tokens = tokenize(html)
    local stack = {}
    local root = ElementNode("body")
    table.insert(stack, root)

    for _, token in ipairs(tokens) do
        if token.type == "text" then
            local trimmed = trim(token.content)
            if #trimmed > 0 then
                local parent = stack[#stack]
                table.insert(parent.children, TextNode(trimmed))
            end
        elseif token.type == "tag" then
            local content = token.content
            if content:sub(1,1) == "/" then
                -- closing tag: pop stack if matches
                local closingTag = content:sub(2):match("^%s*(%w+)")
                while #stack > 1 do
                    local top = stack[#stack]
                    if top.tag == closingTag then
                        table.remove(stack)
                        break
                    else
                        table.remove(stack)
                    end
                end
            else
                local isSelfClosing = content:sub(-1) == "/"
                if isSelfClosing then
                    content = content:sub(1, -2)
                end
                local parts = {}
                for part in content:gmatch("[^%s]+") do
                    table.insert(parts, part)
                end
                local tagName = parts[1]
                local attrString = content:sub(#tagName + 1)
                local attrs = parseAttributes(attrString)
                local node = ElementNode(tagName, attrs)
                local parent = stack[#stack]
                table.insert(parent.children, node)
                if not isSelfClosing and not (tagName == "br" or tagName == "img" or tagName == "hr") then
                    table.insert(stack, node)
                end
            end
        end
    end
    return root
end

return HTMLParser
