if LogUtils then
	return
end
LogUtils = {}

function LogUtils.Print(message)
	reaper.ShowConsoleMsg(message .. "\n")
end

return LogUtils
