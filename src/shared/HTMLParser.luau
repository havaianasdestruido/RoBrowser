--!strict
--!optimize 2
--!native
-- Simple HTML parser for Roblox Luau
-- Parses a subset of HTML into a lightweight DOM structure
-- Node types: ElementNode, TextNode
-- Supports: tags, attributes, nested structures, self-closing tags, comments, doctype

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
	-- Match key="value" or key='value' pairs
	local pattern = '(%w+)[%s]*=[%s]*["\'](.-)["\']'
	for key, value in string.gmatch(attrString, pattern) do
		attrs[key] = value
	end
	-- Also handle boolean attributes (key without value)
	for key in string.gmatch(attrString, "(%w+)[%s/>]") do
		if not attrs[key] then
			attrs[key] = true
		end
	end
	return attrs
end

-- Tokeniser: breaks HTML into tags and text
local function tokenize(html)
	local tokens = {}
	local pos = 1
	local htmlLength = #html
	local lt = string.byte("<")
	local gt = string.byte(">")

	while pos <= htmlLength do
		local charCode = string.byte(html, pos, pos)
		if charCode == lt then
			-- Check for comment or doctype
			if string.sub(html, pos, pos + 3) == "<!--" then
				-- Skip comment
				local commentEnd = string.find(html, "-->", pos + 4)
				if commentEnd then
					pos = commentEnd + 3
				else
					pos = htmlLength + 1
				end
			elseif string.sub(html, pos, pos + 8) == "<!DOCTYPE" then
				-- Skip doctype
				local gtPos = string.find(html, ">", pos)
				if gtPos then
					pos = gtPos + 1
				else
					pos = htmlLength + 1
				end
			else
				-- Find end of tag
				local close = string.find(html, ">", pos)
				if not close then
					break
				end
				local tagContent = string.sub(html, pos + 1, close - 1)
				table.insert(tokens, {type = "tag", content = tagContent})
				pos = close + 1
			end
		else
			-- Text node until next '<'
			local nextTag = string.find(html, "<", pos) or (htmlLength + 1)
			local text = string.sub(html, pos, nextTag - 1)
			if trim(text) ~= "" then
				table.insert(tokens, {type = "text", content = text})
			end
			pos = nextTag
		end
	end
	return tokens
end

-- Check if tag is self-closing
local selfClosingTags = {
	"img", "br", "hr", "input", "meta", "link", "area", "base", "col", "embed",
	"param", "source", "track", "wbr", "path", "circle", "ellipse", "line",
	"polyline", "polygon", "rect", "stop", "use",
}

local function isSelfClosing(tagName)
	return selfClosingTags[tagName] == true
end

-- Extract text content from a node and its children
local function extractText(node)
	if node.type == "text" then
		return node.text
	elseif node.type == "element" then
		local text = ""
		for _, child in ipairs(node.children or {}) do
			text = text .. extractText(child)
		end
		return text
	end
	return ""
end

-- Parser: converts tokens into a DOM tree
function HTMLParser.parse(html)
	local tokens = tokenize(html)
	local stack = {}
	local root = ElementNode("html") -- Root node
	table.insert(stack, root)

	-- Collect CSS from style tags
	local cssBlocks = {}

	for _, token in ipairs(tokens) do
		if token.type == "text" then
			local trimmed = trim(token.content)
			if #trimmed >0 then
				local parent = stack[#stack]
				if parent then
					table.insert(parent.children, TextNode(trimmed))
				end
			end
		elseif token.type == "tag" then
			local content = token.content

			-- Check if it's a closing tag
			if string.sub(content, 1, 1) == "/" then
				local closingTag = string.match(string.sub(content, 2), "^%s*(%w+)")
				if closingTag then
					-- Special handling for style tags - extract CSS
					if closingTag == "style" and stack[#stack] and stack[#stack].tag == "style" then
						local styleNode = stack[#stack]
						local cssText = extractText(styleNode)
						if cssText and cssText ~= "" then
							table.insert(cssBlocks, cssText)
						end
					end

					-- Pop stack until we find matching opening tag
					while #stack > 1 do
						local top = stack[#stack]
						if top.tag == closingTag then
							table.remove(stack)
							break
						else
							table.remove(stack)
						end
					end
				end
			else
				-- Opening tag
				local isSelfClosingTag = string.sub(content, -1) == "/"
				if isSelfClosingTag then
					content = string.sub(content, 1, -2)
				end

				-- Extract tag name and attributes
				local parts = {}
				for part in string.gmatch(content, "[^%s]+") do
					table.insert(parts, part)
				end

				local tagName = parts[1]
				local attrString = string.sub(content, #tagName + 1)
				local attrs = parseAttributes(attrString)

				-- Create node
				local node = ElementNode(tagName, attrs)
				local parent = stack[#stack]

				if parent then
					table.insert(parent.children, node)
				else
					table.insert(root.children, node)
				end

				-- Push to stack if not self-closing
				if not isSelfClosingTag and not isSelfClosing(tagName) then
					table.insert(stack, node)
				end
			end
		end
	end

	-- Attach collected CSS to root node
	if #cssBlocks > 0 then
		root.css = table.concat(cssBlocks, "\n")
	end

	return root
end
			end
		elseif token.type == "tag" then
			local content = token.content

			-- Check if it's a closing tag
			if string.sub(content, 1, 1) == "/" then
				local closingTag = string.match(string.sub(content, 2), "^%s*(%w+)")
				if closingTag then
					-- Pop stack until we find matching opening tag
					while #stack > 1 do
						local top = stack[#stack]
						if top.tag == closingTag then
							table.remove(stack)
							break
						else
							table.remove(stack)
						end
					end
				end
			else
				-- Opening tag
				local isSelfClosingTag = string.sub(content, -1) == "/"
				if isSelfClosingTag then
					content = string.sub(content, 1, -2)
				end

				-- Extract tag name and attributes
				local parts = {}
				for part in string.gmatch(content, "[^%s]+") do
					table.insert(parts, part)
				end

				local tagName = parts[1]
				local attrString = string.sub(content, #tagName + 1)
				local attrs = parseAttributes(attrString)

				-- Create node
				local node = ElementNode(tagName, attrs)
				local parent = stack[#stack]

				if parent then
					table.insert(parent.children, node)
				else
					table.insert(root.children, node)
				end

				-- Push to stack if not self-closing
				if not isSelfClosingTag and not isSelfClosing(tagName) then
					table.insert(stack, node)
				end
			end
		end
	end

	return root
end

-- Serialize DOM back to HTML (for debugging)
function HTMLParser.serialize(node, indent)
	indent = indent or 0
	local pad = string.rep("  ", indent)

	if node.type == "text" then
		return pad .. node.text
	elseif node.type == "element" then
		local attrs = ""
		for k, v in pairs(node.attrs) do
			if type(v) == "string" then
				attrs = attrs .. " " .. k .. '="' .. v .. '"'
			end
		end
		local result = pad .. "<" .. node.tag .. attrs .. ">\n"
		for _, child in ipairs(node.children or {}) do
			result = result .. HTMLParser.serialize(child, indent + 1) .. "\n"
		end
		result = result .. pad .. "</" .. node.tag .. ">"
		return result
	end
	return ""
end

return HTMLParser
