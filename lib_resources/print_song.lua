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
		output = output .. "\\songsetauthor{" .. author .. "}\n"
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
			elseif c == "\n" then
				if afterchord then
					output = output .. "\\songchordkern{}"
					afterchord = false
				end
				output = output .. "\\\\\n"
				if body:sub(i + 1, i + 1) ~= "\n" then
					output = output .. "\\nopagebreak[4]"
				end
			elseif c == " " or c == "\t" then
				for j = i, 0, -1 do
					local d = body:sub(j, j)
					if d ~= " " and d ~= "\t" then
						if d ~= "\n" then
							output = output .. " "
						end
						break
					end
				end
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
				if c == "|" then
					if body:sub(i + 1, i + 1) == ":" then
						output = output .. "\\songrepeatstart{}"
					elseif body:sub(i - 1, i - 1) == ":" then
						output = output .. "\\songrepeatend{}"
					else
						output = output .. "|"
					end
				elseif c == ":" and (body:sub(i + 1, i + 1) == "|" or body:sub(i - 1, i - 1) == "|") then
				else
					output = output .. latexEscape(c)
				end
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
						if i + 1 >= #body then
							output = output .. chorusline .. "..."
						end
						for j = i + 1, #body do
							local d = body:sub(j, j)
							if d ~= " " then
								if d == "\n" then
									output = output .. chorusline .. "..."
								else
									chorusline = ""
									mode = 2
								end
								break
							end
						end
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
				output = output .. " \\\\\n"
				if body:sub(i + 1, i + 1) ~= "\n" then
					output = output .. "\\nopagebreak[4]"
				end
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
				if c == "|" then
					if body:sub(i + 1, i + 1) == ":" then
						output = output .. "\\songrepeatstart"
					elseif body:sub(i - 1, i - 1) == ":" then
						output = output .. "\\songrepeatend"
					else
						chorusline = chorusline .. "|"
						output = output .. "|"
					end
				elseif c == ":" and (body:sub(i + 1, i + 1) == "|" or body:sub(i - 1, i - 1) == "|") then
				else
					chorusline = chorusline .. latexEscape(c)
					output = output .. latexEscape(c)
				end
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
		--["\"] = "\\\\",
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
