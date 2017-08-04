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

	function startrecording(number, title, author, url)
		NUMBER = number
		TITLE = title
		AUTHOR = author
		URL = url
		BUFFER = ""
		luatexbase.add_to_callback('process_input_buffer', readbuf, 'readbuf')
		RECORDING = true
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
	local output = "\\section*{" .. number .. ") " .. title .. "} \n"
	if author ~= "" then
		output = output .. "AUTOR: " .. author .. "\\\\ \n"
	end
	output = output .. "\\songseturl{" .. url .. "}\n"
	local verse_number = 0
	local chorusline = ""
	local afterchord = false
	for c in body:gmatch(".") do
		if mode == 0 then -- Normal lyrics
			if c == "<" then
				mode = 1
				command = ""
			elseif c =="\n" then
				if afterchord then
					output = output .. "\\songchordkern "
					afterchord = false
				end
				output = output .. " \\\\ \n"
			else
				if c ~= " " and afterchord then
					output = output .. "\\songchordkern "
					afterchord = false
				end
				output = output .. c
			end
		elseif mode == 1 then -- inside a command
			if c == ">" then
				mode = 0
				if command == "v" or command == "s" then
					verse_number = verse_number + 1
					output = output .. "\\songverse{" .. verse_number .. "} "
				elseif command == "ch" or command == "r" then
					output = output .. "\\songchorus "
					if chorusline == "" then
						mode = 2
					else
						output = output .. chorusline .. "..."
					end
				else
					output = output .. "\\songchord{" .. command .. "} "
					afterchord = true
				end
			else
				command = command .. c
			end
		elseif mode == 2 then -- first occurence of chorus
			if c == "<" then
				mode = 3
				command = ""
			elseif c == "\n" then
				mode = 0
				if afterchord then
					output = output .. "\\songchordkern "
					afterchord = false
				end
				output = output .. " \\\\ \n"
			else
				if c ~= " " and afterchord then
					output = output .. "\\songchordkern "
					afterchord = false
				end
				chorusline = chorusline .. c
				output = output .. c
			end
		elseif mode == 3 then -- first occurence of chorus, inside a command
			if c == ">" then
				mode = 2
				output = output .. "\\songchord{" .. command .. "} "
				afterchord = true
			else
				command = command .. c
			end
		end
	end
	--print("\n" .. body)
	tex.print(output)
end
