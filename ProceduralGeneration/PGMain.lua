function Init()
	local path = ({reaper.get_action_context()})[2]:match("^.+[\\//]")
	package.path = path .. "?.lua"

	UMath = require("MathUtils")
	URea = require("ReaperUtils")
	UFile = require("FileUtils")
	ULog = require("LogUtils")
	require("DataStructures")
	require("Notes")
end

function DefineGlobalsPaths()
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		Separator = "\\"
	else
		Separator = "/"
	end

	MainRenderDirPath = "W:\\Samples\\Procedural\\Generated"
	SubgenerationRenderDirPath = "W:\\Samples\\Procedural\\SubGenerations"
	GeneratedProjectFilesDirPath = "W:\\Samples\\Procedural\\Generated\\ProjectFiles"

	PathDirBankKick = "W:\\Samples\\Procedural\\Banks\\Kicks"
	PathDirBankSnare = "W:\\Samples\\Procedural\\Banks\\Snares"
	OrnamentSourceBankDirPath = "W:\\Samples\\Procedural\\Banks\\Random"

	LogsDirPath = "W:\\Samples\\Procedural\\Logs"
	ProjectTemplateFilePath = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"

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
		URea.GetParameterEnvelopesFromTrackFXByNames(TrackBass, synthbassParamNames, reaper.TrackFX_GetInstrument(TrackBass))

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
	URea.BeginProjectModification()

	local seedSeparatorMultiplier = 100000
	local generationName = "Gen_" .. GetDateString()

	for i = 0, compositionCount - 1, 1 do
		local currentCompositionName = generationName .. GetIterationString(i, compositionCount)

		CurrentCompositionSeed = os.time() * seedSeparatorMultiplier + i
		AutomationPointsPerBeat = 1

		CreateComposition()

		if (saveProjectToFile) then
			URea.SaveProjectAndCopyToPath(GeneratedProjectFilesDirPath .. Separator .. currentCompositionName .. ".rpp")
		end

		if (renderToFile) then
			URea.RenderProjectToPath(MainRenderDirPath .. Separator .. currentCompositionName .. ".wav")
		end
	end

	URea.EndProjectModification(generationName)
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
	URea.ReaperClearProjectItems()
	EnvelopeTableDeleteAllPoints(BassEnvelopes)

	--Initialize
	local currentTimePosition = 0
	math.randomseed(CurrentCompositionSeed)

	--Generate
	URea.RandomizeBPM(90, 110)
	PathFileKick = PathDirBankKick .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(PathDirBankKick))
	PathFileSnare = PathDirBankSnare .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(PathDirBankSnare))

	--local bassNoteBlueprint = NoteSequence(,,32,16,4)--NoteSequenceBlueprint(32, 16, 1, 3, 2)
	local phrase = Phrase(32, PathFileKick, PathFileSnare, nil)
	--local phrase2 = Phrase(16, PathFileKick, PathFileSnare, nil)

	local phraseRandomNoteValues = UMath.GenerateRandomValuesArray(16)

	--Insert into project
	currentTimePosition =
		phrase.Insert(currentTimePosition, phraseRandomNoteValues, TrackKick, TrackSideKick, TrackSnare, TrackBass)

	--Sort
	EnvelopeTableSortPoints(BassEnvelopes)
end

function EnvelopeTableDeleteAllPoints(envelopeTable)
	for index, value in ipairs(envelopeTable) do
		reaper.DeleteEnvelopePointRange(value, 0, math.huge)
	end
end

function EnvelopeTableSortPoints(envelopeTable)
	for index, value in ipairs(envelopeTable) do
		reaper.Envelope_SortPoints(value)
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

Main()
