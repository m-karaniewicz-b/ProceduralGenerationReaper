if LogUtils then
	return
end
LogUtils = {}

function LogUtils.Print(message)
	reaper.ShowConsoleMsg(tostring(message) .. "\n")
end

--- Do not use for serialization
function LogUtils.GetStringTableAsString(table, print)
	print = print or false
	local tableAsString = ""
	for i, line in ipairs(table) do
		tableAsString = tableAsString .. i .. ": " .. tostring(line) .. "\n"
	end

	if print then
		LogUtils.Print(tableAsString)
	end

	return tableAsString
end

return LogUtils
