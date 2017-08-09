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
		for _, name in ipairs(sorted) do
			output = output .. "\\songlistentry{" .. lines[name] .. "}{" .. name .. "}\n"
		end
		los = io.open(jobname .. ".los", "w")
		output = trim(output)
		tex.print(output)
	end
end

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

function lexicographicSort(first, second)
	local letters = {
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
	a = czechLower(first)
	b = czechLower(second)
	if letters[a] == nil then
		return false
	end
	if letters[b] == nil then
		return true
	end
	return letters[a] < letters[b]
end

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
