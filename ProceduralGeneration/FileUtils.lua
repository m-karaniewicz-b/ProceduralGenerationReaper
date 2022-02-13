if FileUtils then
	return
end
FileUtils = {}

local fileOpsPath = reaper.GetResourcePath() .. "\\UserPlugins\\fileops.dll"
if not reaper.file_exists(fileOpsPath) then
	reaper.MB("Please copy fileops.dll to UserPlugins folder", "Warning", 0)
	return
end

local copyFile = package.loadlib(fileOpsPath, "copyFile")
assert(type(copyFile) == "function", "\nError: failed to load function from dll")

function FileUtils.CopyFileToPath(fileName, pathToCopy)
	return copyFile(fileName, pathToCopy)
end

function FileUtils.GetFilesInDirectory(directoryName)
	local files = {}
	local i = 0

	repeat
		local ret = reaper.EnumerateFiles(directoryName, i)
		table.insert(files, ret)
		i = i + 1
	until not ret

	return files
end

function FileUtils.GetDirectoryFromFile(str, sep)
	return select(2, str:match("((.*)" .. sep .. ")"))
end

function FileUtils.GetDirectoryFromFileWithSep(str, sep)
	return str:match("(.*" .. sep .. ")")
end

return FileUtils
