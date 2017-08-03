do 
	local BUFFER = ""
	local TITLE = ""
	function readbuf(buffer)
		BUFFER = BUFFER .. buffer .. "\n" 
		if buffer:match("%s*\\end{song}") then 
			return buffer
		end
		return ""
	end

	function startrecording(title)
		TITLE = title
		luatexbase.add_to_callback('process_input_buffer', readbuf, 'readbuf')
	end

	function stoprecording()
		luatexbase.remove_from_callback('process_input_buffer', 'readbuf')
		local clean_buffer = BUFFER:gsub("\\end{song}\n","")
		BUFFER = ""
		print_song(TITLE, clean_buffer)
	end
end

function print_song(title, body)
	local mode = 0
	local command = ""
	local output = "\\section*{" .. title .. "} \n"
	local verse_number = 0
	local chorusline = ""
	local afterchord = false
	for c in body:gmatch(".") do
		if mode == 0 then -- Normal lyrics
			if c == "<" then
				mode = 1
				command = ""
			elseif c =="\n" then
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
				if command == "v" then
					verse_number = verse_number + 1
					output = output .. "\\songverse{" .. verse_number .. "} "
				elseif command == "ch" then
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
	--print("\n" .. output)
	tex.print(output)
end
