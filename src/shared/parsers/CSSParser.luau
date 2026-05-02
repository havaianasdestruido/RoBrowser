--!strict
--!optimize 2
--!native
--[[
  CSSParser - Simple CSS parser for Roblox Luau
  Parses CSS text into a structured format that BrowserEngine can use
  Supports: selectors (tag, class, id), properties, basic inheritance
]]

local CSSParser = {}

-- Safe debug module loader
local Debug = nil
pcall(function()
	Debug = require(script.Parent.Parent:WaitForChild("debug"))
end)

local function debugLog(level, message, source)
	if Debug then
		Debug[level](message, source or "CSSParser")
	end
end

-- Parse a single CSS rule
local function parseRule(cssText)
	local rules = {}

	-- Remove comments
	cssText = cssText:gsub("/%*.-%*/", "")
	debugLog("verbose", "Removed CSS comments", "CSSParser")

	-- Find all rule blocks
	for selectorStr, body in cssText:gmatch("([^{]+)%s*{([^}]+)}") do
		local rule = {
			selectors = {},
			properties = {},
		}

		-- Parse selectors
		for selector in selectorStr:gmatch("[^,]+") do
			selector = selector:match("^%s*(.-)%s*$") -- trim
			if selector ~= "" then
				table.insert(rule.selectors, selector)
			end
		end

		-- Parse properties
		for prop, value in body:gmatch("([%w%-]+)%s*:%s*([^;]+);?") do
			prop = prop:match("^%s*(.-)%s*$"):lower()
			value = value:match("^%s*(.-)%s*$")
			if prop ~= "" and value ~= "" then
				rule.properties[prop] = value
			end
		end

		if #rule.selectors > 0 then
			table.insert(rules, rule)
			debugLog("verbose", `Parsed rule with {selectorStr} selectors`, "CSSParser")
		end
	end

	debugLog("log", `parseRule: found {rules} rules`, "CSSParser")
	return rules
end

-- Parse full CSS and return a lookup table
function CSSParser.parse(cssText)
	debugLog("log", `Parsing CSS ({#cssText} chars)`, "CSSParser")
	local rules = parseRule(cssText)
	local styleMap = {}

	for _, rule in ipairs(rules) do
		for _, selector in ipairs(rule.selectors) do
			if not styleMap[selector] then
				styleMap[selector] = {}
			end
			-- Merge properties
			for prop, value in pairs(rule.properties) do
				styleMap[selector][prop] = value
			end
		end
	end

	debugLog("log", `CSS parsed: {pairs(styleMap) and "selectors matched" or "no selectors"}`, "CSSParser")
	return styleMap
end

-- Match a DOM element against CSS selectors
function CSSParser.matchElement(element, styleMap)
	if not element or element.type ~= "element" then
		debugLog("verbose", "matchElement: not an element node, skipping", "CSSParser")
		return {}
	end

	local styles = {}
	debugLog("verbose", `matchElement: matching tag={element.tag}`, "CSSParser")

	-- Tag selector (e.g., "div")
	local tagStyles = styleMap[element.tag]
	if tagStyles then
		for prop, value in pairs(tagStyles) do
			styles[prop] = value
		end
		debugLog("verbose", `Matched tag selector: {element.tag}`, "CSSParser")
	end

	-- Class selector (e.g., ".myclass")
	local classAttr = element.attrs.class
	if classAttr then
		for className in classAttr:gmatch("%S+") do
			local classStyles = styleMap["." .. className]
			if classStyles then
				for prop, value in pairs(classStyles) do
					styles[prop] = value
				end
				debugLog("verbose", `Matched class selector: .{className}`, "CSSParser")
			end
		end
	end

	-- ID selector (e.g., "#myid")
	local id = element.attrs.id
	if id then
		local idStyles = styleMap["#" .. id]
		if idStyles then
			for prop, value in pairs(idStyles) do
				styles[prop] = value
			end
			debugLog("verbose", `Matched ID selector: #{id}`, "CSSParser")
		end
	end

	debugLog("verbose", `matchElement: returning {pairs(styles) and "styles" or "no styles"}`, "CSSParser")
	return styles
end

-- Convert CSS styles to inline style string for BrowserEngine
function CSSParser.toInlineStyle(cssStyles)
	local parts = {}
	for prop, value in pairs(cssStyles) do
		table.insert(parts, prop .. ": " .. value)
	end
	return table.concat(parts, "; ")
end

return CSSParser
