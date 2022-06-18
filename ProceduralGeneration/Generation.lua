function StartGeneration(compositionCount, saveProjectToFile, renderToFile)
	ReaperUtils.BeginProjectModification()

	local seedSeparatorMultiplier = 100000
	local generationName = "Gen_" .. GetDateString()

	for i = 0, compositionCount - 1, 1 do
		local currentCompositionName = generationName .. GetIterationString(i, compositionCount)

		CurrentCompositionSeed = os.time() * seedSeparatorMultiplier + i
		AutomationPointsPerBeat = 4

		CreateComposition()

		if (saveProjectToFile) then
			ReaperUtils.SaveProjectAndCopyToPath(PathDirGeneratedProjectFiles .. Separator .. currentCompositionName .. ".rpp")
		end

		if (renderToFile) then
			ReaperUtils.RenderProjectToPath(PathDirMainRenders .. Separator .. currentCompositionName .. ".wav")
		end
	end

	ReaperUtils.EndProjectModification(generationName)
end

function GetDateString()
	return os.date("%Y_%m_%d_%H_%M_%S")
end

function GetIterationString(currentIteration, iterationCount)
	iterationCount = iterationCount or 0
	if iterationCount < 2 then
		return ""
	else
		return "_" .. (currentIteration + 1)
	end
end

function CreateOrnamentFile(sourceFiles)
	-- local ornamentSourceCount = 5
	-- local ornamentSourceFiles
	-- for i = 0, ornamentSourceCount, 1 do
	-- 	OrnamentSourceFiles =
	-- 		OrnamentSourceBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(OrnamentSourceBankDir))
	-- end
	--OrnamentFile = CreateOrnamentFile(OrnamentSourceFiles)
end
