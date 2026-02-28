--==============================================================================
-- List of Songs (LOS) Module
-- Generates sorted table of contents from .los file with Czech alphabet sorting.
-- "ch" is treated as a single letter between "h" and "i".
--==============================================================================

--[[
	Main function - reads .los file, sorts songs by title, prints list entries.
	@param jobname string: LaTeX job name for .los file
]]
function print_los(jobname)
	if io.open(jobname .. ".los", "r") ~= nil then
		local output = ""
		lines = {}
		for line in io.lines(jobname .. ".los") do
			number, name = line:match("([^|]+)|([^|]+)")
			lines[name] = tonumber(number)
		end
		sorted = {}
		for n in pairs(lines) do table.insert(sorted, n) end
		table.sort(sorted, wordSort)
		local i = 0
		for _, name in ipairs(sorted) do
			if math.fmod(i, 5) == 0 and i > 0 then
				output = output .. "\\songlistdivider"
			end
			i = i + 1
			output = output .. "\\songlistentry{" .. lines[name] .. "}{" .. name .. "}"
		end
		los = io.open(jobname .. ".los", "w")
		output = trim(output)
		tex.print(output)
	end
end

--==============================================================================
-- Czech Alphabet Sorting
--==============================================================================

-- Czech alphabet with accented characters, "ch" treated as single letter
-- Non-letter characters sort before all letters (negative values, roughly in Unicode order)
local CZECH_ALPHABET = {
	[" "]  = -14, -- space
	["!"]  = -13, -- exclamation mark
	["\""] = -12, -- double quotation mark
	["'"]  = -11, -- apostrophe
	["("]  = -10, -- left parenthesis
	[")"]  =  -9, -- right parenthesis
	[","]  =  -8, -- comma
	["-"]  =  -7, -- hyphen-minus
	["."]  =  -6, -- full stop
	["/"]  =  -5, -- slash
	[":"]  =  -4, -- colon
	[";"]  =  -3, -- semicolon
	["?"]  =  -2, -- question mark
	["´"]  =  -1, -- acute accent (U+00B4, used as apostrophe in some titles)
	["a"] = 0,
	["á"] = 1,
	["b"] = 2,
	["c"] = 3,
	["č"] = 4,
	["d"] = 5,
	["ď"] = 6,
	["e"] = 7,
	["é"] = 8,
	["ě"] = 9,
	["f"] = 10,
	["g"] = 11,
	["h"] = 12,
	["ch"] = 13,
	["i"] = 14,
	["í"] = 15,
	["j"] = 16,
	["k"] = 17,
	["l"] = 18,
	["m"] = 19,
	["n"] = 20,
	["ň"] = 21,
	["o"] = 22,
	["ó"] = 23,
	["p"] = 24,
	["q"] = 25,
	["r"] = 26,
	["ř"] = 27,
	["s"] = 28,
	["š"] = 29,
	["t"] = 30,
	["ť"] = 31,
	["u"] = 32,
	["ú"] = 33,
	["ů"] = 34,
	["v"] = 35,
	["w"] = 36,
	["x"] = 37,
	["y"] = 38,
	["ý"] = 39,
	["z"] = 40,
	["ž"] = 41,
}

--[[
	Comparison function for sorting - handles Czech alphabet.
	Treats "ch" as a single letter between "h" and "i".
	@param first string: First string to compare
	@param second string: Second string to compare
	returns: boolean: true if first < second
]]
function wordSort(first, second)
	if #first == 0 then
		return true
	end
	if #second == 0 then
		return false
	end
	local fi = 1
	local si = 1
	for i = 1, math.min(#first, #second) do
		local c = utf8sub(first, fi, 1)
		local d = utf8sub(second, si, 1)
		if c == "c" then
			local cc = utf8sub(first, fi + 1, 1)
			if cc == "h" then
				c = "ch"
				fi = fi + 1
			end
		end
		if d == "c" then
			local dd = utf8sub(second, si + 1, 1)
			if dd == "h" then
				d = "ch"
				si = si + 1
			end
		end
		if c ~= d then
			return lexicographicSort(c, d)
		end
		fi = fi + 1
		si = si + 1
	end
	return #first < #second
end

--[[
	Lexicographic comparison using Czech alphabet order.
	@param first string: First character
	@param second string: Second character
	returns: boolean: true if first < second in Czech order
]]
function lexicographicSort(first, second)
	a = czechLower(first)
	b = czechLower(second)
	if CZECH_ALPHABET[a] == nil then
		return false
	end
	if CZECH_ALPHABET[b] == nil then
		return true
	end
	return CZECH_ALPHABET[a] < CZECH_ALPHABET[b]
end

--==============================================================================
-- Utility Functions
--==============================================================================

--[[
	Gets the byte size of a UTF-8 character.
	@param char number: First byte of UTF-8 character
	returns: number: byte length (1-4)
]]
function chsize(char)
	if not char then
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end
end

--[[
	Extracts a substring from a UTF-8 string.
	@param str string: Input UTF-8 string
	@param startChar number: 1-based starting character position
	@param numChars number: Number of characters to extract
	returns: string: substring
]]
function utf8sub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local char = string.byte(str, startIndex)
		startIndex = startIndex + chsize(char)
		startChar = startChar - 1
	end

	local currentIndex = startIndex

	while numChars > 0 and currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		currentIndex = currentIndex + chsize(char)
		numChars = numChars -1
	end
	return str:sub(startIndex, currentIndex - 1)
end

--[[
	Converts string to lowercase with Czech-specific handling.
	@param str string: Input string
	returns: string: lowercased string
]]
function czechLower(str)
	local substitutions = {
		["Á"] = "á",
		["Č"] = "č",
		["Ď"] = "ď",
		["É"] = "é",
		["Ě"] = "ě",
		["Í"] = "í",
		["Ň"] = "ň",
		["Ó"] = "ó",
		["Ř"] = "ř",
		["Š"] = "š",
		["Ť"] = "ť",
		["Ú"] = "ú",
		["Ů"] = "ů",
		["Ý"] = "ý",
		["Ž"] = "ž",
	}
	local output = ""
	for i = 1, #str do
		local c = utf8sub(str, i, 1)
		if substitutions[c] then
			output = output .. substitutions[c]
		else
			output = output .. string.lower(c)
		end
	end
	return output
end

--[[
	Trims leading and trailing whitespace from string.
	@param s string: Input string
	returns: string: trimmed string
]]
function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
