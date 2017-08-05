do 
	local BUFFER = ""
	local NUMBER = ""
	local TITLE = ""
	local AUTHOR = ""
	local URL = ""
	local RECORDING = false
	function readbuf(buffer)
		BUFFER = BUFFER .. buffer .. "\n" 
		if buffer:match("%s*\\end{song}") then 
			return buffer
		end
		return ""
	end

	function startrecording(number, title, author, url, jobname)
		NUMBER = number
		TITLE = title
		AUTHOR = author
		URL = url
		BUFFER = ""
		luatexbase.add_to_callback('process_input_buffer', readbuf, 'readbuf')
		RECORDING = true
		los = io.open(jobname .. ".los", "a")
		los:write(number .. "|" .. title .. "\n")
	end

	function stoprecording()
		if RECORDING then
			luatexbase.remove_from_callback('process_input_buffer', 'readbuf')
		end
		RECORDING = false
		local clean_buffer = BUFFER:gsub("\\end{song}\n","")
		print_song(NUMBER, TITLE, AUTHOR, URL, clean_buffer)
	end
end

function print_song(number, title, author, url, body)
	local mode = 0
	local command = ""
	local output = "\\songsettitleurl{" .. number .. ") " .. title .. "}{" .. url .. "}\n"
	if author ~= "" then
		output = output .. "\\songsetauthor{" .. author .. "}\n\n"
	end
	local verse_number = 0
	local chorusline = ""
	local afterchord = false
	body = trim(body)
	for i = 1, #body do
		local c = body:sub(i, i)
		if mode == 0 then -- Normal lyrics
			if c == "<" then
				mode = 1
				command = ""
			elseif c =="\n" then
				if afterchord then
					output = output .. "\\songchordkern{}"
					afterchord = false
				end
				output = output .. " \\\\ \n"
			else
				if afterchord then
					for j = i, #body do
						local d = body:sub(j, j)
						if d ~= " " then
							if d ~= "<" then
								output = output .. "\\songchordkern{}"
								afterchord = false
							end
							break
						end
					end
				end
				output = output .. latexEscape(c)
			end
		elseif mode == 1 then -- inside a command
			if c == ">" then
				mode = 0
				if command == "v" or command == "s" then
					verse_number = verse_number + 1
					output = output .. "\\songverse{" .. verse_number .. "}"
				elseif command == "ch" or command == "r" then
					output = output .. "\\songchorus "
					if chorusline == "" then
						mode = 2
					else
						output = output .. chorusline .. "..."
					end
				else
					output = output .. "\\songchord{" .. command .. "}"
					afterchord = true
				end
			else
				if c == "b" then
					command = command .. "$\\boldsymbol{\\flat}$"
				else
					command = command .. latexEscape(c)
				end
			end
		elseif mode == 2 then -- first occurence of chorus
			if c == "<" then
				mode = 3
				command = ""
			elseif c == "\n" then
				mode = 0
				if afterchord then
					output = output .. "\\songchordkern{}"
					afterchord = false
				end
				output = output .. " \\\\ \n"
			else
				if afterchord then
					for j = i, #body do
						local d = body:sub(j, j)
						if d ~= " " then
							if d ~= "<" then
								output = output .. "\\songchordkern{}"
								afterchord = false
							end
							break
						end
					end
				end
				chorusline = chorusline .. latexEscape(c)
				output = output .. latexEscape(c)
			end
		elseif mode == 3 then -- first occurence of chorus, inside a command
			if c == ">" then
				mode = 2
				output = output .. "\\songchord{" .. command .. "}"
				afterchord = true
			else
				if c == "b" then
					command = command .. "$\\boldsymbol{\\flat}$"
				else
					command = command .. latexEscape(c)
				end
			end
		end
	end
	tex.print(output)
end

function latexEscape(c)
	local esc = {
		["%"] = "\\%",
		["$"] = "\\$",
		["{"] = "\\{",
		["_"] = "\\_",
		["#"] = "\\#",
		["&"] = "\\&",
		["}"] = "\\}",
		["~"] = "\\~{}",
	}
	local t = esc[c]
	if t then
		return t
	else
		return c
	end
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
