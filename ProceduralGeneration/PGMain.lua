function Init()
	local path = ({reaper.get_action_context()})[2]:match("^.+[\\//]")
	package.path = path .. "?.lua"

	MathUtils = require("MathUtils")
	ReaperUtils = require("ReaperUtils")
	FileUtils = require("FileUtils")
	LogUtils = require("LogUtils")
	NormalizedFunctionsUtils = require("NormalizedFunctionsUtils")
	require("ClassPhrase")
	require("ClassFormula")
	require("ClassNoteSequence")
	require("ClassNoteData")
end

function DefineGlobalsPaths()
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		Separator = "\\"
	else
		Separator = "/"
	end

	PathDirMainRenders = "W:\\Samples\\Procedural\\Generated"
	PathDirSubgenerationRenders = "W:\\Samples\\Procedural\\SubGenerations"
	PathDirGeneratedProjectFiles = "W:\\Samples\\Procedural\\Generated\\ProjectFiles"

	PathDirBankVitalVST3Bass = "C:\\Repositories\\ReaperScripts\\ProceduralGeneration\\VitalVST3Presets\\Bass"
	PathDirBankKick = "W:\\Samples\\Procedural\\Banks\\Kicks"
	PathDirBankSnare = "W:\\Samples\\Procedural\\Banks\\Snares"
	PathDirBankOrnamentSource = "W:\\Samples\\Procedural\\Banks\\Random"

	PathDirLogs = "W:\\Samples\\Procedural\\Logs"
	PathFileProjectTemplate = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"

	--Load file template
	--reaper.Main_openProject(templateFileName)
end

function DefineGlobalsTracks()
	ParentTrack = reaper.GetTrack(0, 0)
	TrackKick = reaper.GetTrack(0, 1)
	TrackSideKick = reaper.GetTrack(0, 2)
	TrackSnare = reaper.GetTrack(0, 3)
	ReverbSendTrack = reaper.GetTrack(0, 4)
	TrackBass = reaper.GetTrack(0, 5)
end

function DefineGlobalsEnvelopes()
	--Macro 1 => Intensity
	--Macro 2 => Timbre 1
	--Macro 3 => Timbre 2
	--Macro 4 => Width
	local synthbassParamNames = {"Macro 1", "Macro 2", "Macro 3", "Macro 4"}

	BassEnvelopes =
		ReaperUtils.GetParameterEnvelopesFromTrackFXByNames(
		TrackBass,
		synthbassParamNames,
		reaper.TrackFX_GetInstrument(TrackBass)
	)

	BassEnvelopeIntensity = BassEnvelopes[1]
	BassEnvelopeTimbre1 = BassEnvelopes[2]
	BassEnvelopeTimbre2 = BassEnvelopes[3]
	BassEnvelopeWidth = BassEnvelopes[4]
end

function Main()
	Init()
	DefineGlobalsPaths()
	DefineGlobalsTracks()
	DefineGlobalsEnvelopes()
	StartGeneration(1, false, false)
end

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

function CreateComposition()
	--Clear project
	ReaperUtils.ReaperClearProjectItems()
	ReaperUtils.EnvelopeTableDeleteAllPoints(BassEnvelopes)

	--Initialize
	local currentTimePosition = 0
	math.randomseed(CurrentCompositionSeed)

	--Generate
	PathFileKick = PathDirBankKick .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankKick))
	PathFileSnare =
		PathDirBankSnare .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankSnare))
	PathFilePresetBass =
		PathDirBankVitalVST3Bass ..
		"\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankVitalVST3Bass))

	reaper.TrackFX_SetPreset(TrackBass, 0, PathFilePresetBass)
	ReaperUtils.RandomizeBPM(90, 110)

	local phraseLength = 32
	local phraseRandomValueCache = MathUtils.GenerateRandomValuesArray(1000)

	local phrase = Phrase(phraseLength, phraseRandomValueCache, PathFileKick, PathFileSnare, nil)
	phrase.SetTracks(TrackKick, TrackSideKick, TrackSnare, TrackBass)

	local phrase2 = Phrase(phraseLength, phraseRandomValueCache, PathFileKick, PathFileSnare, nil)
	phrase2.SetTracks(TrackKick, TrackSideKick, TrackSnare, TrackBass)

	--Insert into project
	currentTimePosition = phrase.Insert(currentTimePosition)
	currentTimePosition = phrase2.Insert(currentTimePosition)

	--Sort
	ReaperUtils.EnvelopeTableSortPoints(BassEnvelopes)
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

Main()
