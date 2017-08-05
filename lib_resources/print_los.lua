function print_los(jobname)
	local output = ""
	lines = {}
	for line in io.lines(jobname .. ".los") do
		number, name = line:match("([^|]+)|([^|]+)")
		lines[name] = tonumber(number)
	end
	sorted = {}
	for n in pairs(lines) do table.insert(sorted, n) end
	table.sort(sorted)
	for _, name in ipairs(sorted) do
		output = output .. "\\songlistentry{" .. lines[name] .. "}{" .. name .. "}\n"
	end
	los = io.open(jobname .. ".los", "w")
	tex.print(output)
end
