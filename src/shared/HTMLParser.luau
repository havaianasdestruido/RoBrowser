--!strict
--!optimize 2
--!native
-- Simple HTML parser for Roblox Luau
-- Parses a subset of HTML into a lightweight DOM structure
-- Node types: ElementNode, TextNode

local HTMLParser = {}

-- Node constructors
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

-- Helper to trim whitespace
local function trim(s)
    return string.match(s, "^%s*(.-)%s*$")
end

-- Simple attribute parser: converts key="value" pairs into a table
local function parseAttributes(attrString)
    local attrs = {}
    local pattern = '(%w+)%s*=%s*"(.-)"'
    for key, value in string.gmatch(attrString, pattern) do
        attrs[key] = value
    end
    return attrs
end

-- Tokeniser
local function tokenize(html)
    local tokens = {}
    local pos = 1
    local htmlLength = #html
    local lt = string.byte("<")
    local gt = string.byte(">")

    while pos <= htmlLength do
        local charCode = string.byte(html, pos, pos)
        if charCode == lt then
            -- find end of tag
            local close = string.find(html, ">", pos)
            if not close then
                break
            end
            local tagContent = string.sub(html, pos + 1, close - 1)
            table.insert(tokens, {type = "tag", content = tagContent})
            pos = close + 1
        else
            -- text node until next '<'
            local nextTag = string.find(html, "<", pos) or (htmlLength + 1)
            local text = string.sub(html, pos, nextTag - 1)
            table.insert(tokens, {type = "text", content = text})
            pos = nextTag
        end
    end
    return tokens
end

-- Parser
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
            if string.sub(content, 1, 1) == "/" then
                -- closing tag: pop stack if matches
                local closingTag = string.match(string.sub(content, 2), "^%s*(%w+)")
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
                local isSelfClosing = string.sub(content, -1) == "/"
                if isSelfClosing then
                    content = string.sub(content, 1, -2)
                end
                local parts = {}
                for part in string.gmatch(content, "[^%s]+") do
                    table.insert(parts, part)
                end
                local tagName = parts[1]
                local attrString = string.sub(content, #tagName + 1)
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
