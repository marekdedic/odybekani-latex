--==============================================================================
-- Song Processing Module
-- Processes song content from LaTeX environment, parses custom markup tags
-- (<v>, <ch>, <r>), converts to LaTeX commands, and writes to .los file
--==============================================================================

do
	-- Module-level state
	local BUFFER = ""
	local NUMBER = ""
	local TITLE = ""
	local AUTHOR = ""
	local URL = ""
	local RECORDING = false

	--[[
		Input buffer callback that accumulates song content.
		Returns empty string to suppress default output.
		@param buffer string: LaTeX input buffer chunk
		returns: string: empty string to suppress output
	]]
	function readbuf(buffer)
		BUFFER = BUFFER .. buffer .. "\n"
		if buffer:match("%s*\\end{song}") then
			return buffer
		end
		return ""
	end

	--[[
		Initializes song recording, sets up callback and writes to .los file.
		@param number string: Song number
		@param title string: Song title
		@param author string: Song artist/author
		@param url string: Song URL
		@param jobname string: LaTeX job name for .los file
	]]
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
		los:close()
	end

	--[[
		Stops song recording, removes callback and processes the accumulated buffer.
	]]
	function stoprecording()
		if RECORDING then
			luatexbase.remove_from_callback('process_input_buffer', 'readbuf')
		end
		RECORDING = false
	end

	--[[
		Main song printing function - parses song body and converts to LaTeX.
		Handles:
		- <v> or <s>: verse markers (numbered automatically)
		- <ch> or <r>: chorus markers
		- <Am>, <C>, etc.: chord annotations
		- |: |: and :|: repeat markers
	]]
	function print_song()
		local mode = "lyrics"
		local command = ""
		local output = "\\songsettitleurl{" .. NUMBER .. ") " .. TITLE .. "}{" .. URL .. "}"
		if AUTHOR ~= "" then
			output = output .. "\\songsetauthor{" .. AUTHOR .. "}"
		end
		local verse_number = 0
		local chorusline = ""
		local afterchord = false
		local last_nonspace_char = ""
		body = trim(BUFFER:gsub("\\end{song}\n*",""))
		for i = 1, #body do
			local c = body:sub(i, i)
			if mode == "lyrics" then
				if c == "<" then
					mode = "command"
					command = ""
				elseif c == "\n" then
					if afterchord then
						output = output .. "\\songchordkern{}"
						afterchord = false
					end
					output = output .. "\\\\"
					if body:sub(i + 1, i + 1) ~= "\n" then
						output = output .. "\\nopagebreak[4]"
					end
				elseif c == " " or c == "\t" then
					if last_nonspace_char ~= "\n" then
						output = output .. " "
					end
				else
					last_nonspace_char = c
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
			elseif mode == "command" then
				if c == ">" then
					mode = "lyrics"
					if command == "v" or command == "s" then
						verse_number = verse_number + 1
						output = output .. "\\songverse{" .. verse_number .. "}"
					elseif command == "ch" or command == "r" then
						output = output .. "\\songchorus "
						if chorusline == "" then
							mode = "first-chorus"
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
										mode = "first-chorus"
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
			elseif mode == "first-chorus" then
				if c == "<" then
					mode = "first-chorus-command"
					command = ""
				elseif c == "\n" then
					mode = "lyrics"
					if afterchord then
						output = output .. "\\songchordkern{}"
						afterchord = false
					end
					output = output .. " \\\\"
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
			elseif mode == "first-chorus-command" then
				if c == ">" then
					mode = "first-chorus"
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
end

--[[
	Escapes special LaTeX characters for safe output.
	@param c string: Single character to escape
	returns: string: escaped character or original
]]
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

--[[
	Trims leading and trailing whitespace from string.
	@param s string: Input string
	returns: string: trimmed string
]]
function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
