function Init()
	local path = ({reaper.get_action_context()})[2]:match("^.+[\\//]")
	package.path = path .. "?.lua"

	UMath = require("MathUtils")
	URea = require("ReaperUtils")
	UFile = require("FileUtils")
	ULog = require("LogUtils")
	require("DataStructures")
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

	KickBankDirPath = "W:\\Samples\\Procedural\\Banks\\Kicks"
	SnareBankDirPath = "W:\\Samples\\Procedural\\Banks\\Snares"
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

function Main()
	Init()
	DefineGlobalsPaths()
	DefineGlobalsTracks()
	StartGenerating(1, false, false)
end

function StartGenerating(generationCount, saveProjectToFile, renderToFile)
	URea.BeginProjectModification()

	for i = 0, generationCount - 1, 1 do
		CreateComposition()

		local currentCompositionName = "Gen_" .. os.date("%Y_%m_%d_%H_%M_%S")

		if (saveProjectToFile) then
			URea.SaveProjectAndCopyToPath(GeneratedProjectFilesDirPath .. Separator .. currentCompositionName .. ".rpp")
		end

		if (renderToFile) then
			URea.RenderProjectToPath(MainRenderDirPath .. Separator .. currentCompositionName .. ".wav")
		end
	end

	URea.EndProjectModification("Generate")
end

function CreateComposition()
	math.randomseed(os.time())

	URea.ReaperClearProjectItems()

	local currentTimePosition = 0

	local kickFile = KickBankDirPath .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(KickBankDirPath))
	local snareFile = SnareBankDirPath .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(SnareBankDirPath))

	-- local ornamentSourceCount = 5
	-- local ornamentSourceFiles
	-- for i = 0, ornamentSourceCount, 1 do
	-- 	OrnamentSourceFiles =
	-- 		OrnamentSourceBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(OrnamentSourceBankDir))
	-- end

	--OrnamentFile = CreateOrnamentFile(OrnamentSourceFiles)

	--Macro 1 => Intensity
	--Macro 2 => Timbre 1
	--Macro 3 => Timbre 2
	--Macro 4 => Width
	local synthbassParamNames = {"Macro 1", "Macro 2", "Macro 3", "Macro 4"}

	local synthbassEnvelopes =
		URea.GetParameterEnvelopesFromTrackFXByNames(TrackBass, synthbassParamNames, reaper.TrackFX_GetInstrument(TrackBass))

	SBIntensityEnv = synthbassEnvelopes[1]
	SBTimbre1Env = synthbassEnvelopes[2]
	SBTimbre2Env = synthbassEnvelopes[3]
	SBWidthEnv = synthbassEnvelopes[4]

	for index, value in ipairs(synthbassEnvelopes) do
		reaper.DeleteEnvelopePointRange(value, 0, math.huge)
	end

	URea.RandomizeBPM(90, 110)

	--TODO: class for curves/envelopes
	--TODO: replace weigths with seed

	local bassNoteBlueprint = NoteSequenceBlueprint(32, 16, 1, 3, 2)
	local phrase = Phrase(32, kickFile, snareFile, nil, bassNoteBlueprint)
	local phrase2 = Phrase(16, kickFile, snareFile, nil, bassNoteBlueprint)

	local phraseRandomNoteValues = UMath.GenerateRandomValuesArray(16)

	currentTimePosition =
		phrase.Insert(currentTimePosition, phraseRandomNoteValues, TrackKick, TrackSideKick, TrackSnare, TrackBass)

	for index, value in ipairs(synthbassEnvelopes) do
		reaper.Envelope_SortPoints(value)
	end
end

-- function CreatePhrase(lengthInBeats, division, noteDensity)
-- 	local kickFile = KickFile
-- 	local snareFile = SnareFile
-- 	--local ornamentFile = OrnamentFile
-- 	local timeLength = reaper.TimeMap2_beatsToTime(0, lengthInBeats)
-- 	local offset = currentTimePosition

-- 	local phraseRandomNoteValues = UMath.GenerateRandomValuesArray(noteDensity)

-- 	local synthbassNoteBlueprint = NoteSequenceBlueprint(32, 12, 1, 3, 2)
-- 	local synthbassMelodyNotes = synthbassNoteBlueprint.GetNotes(phraseRandomNoteValues)
-- 	--32, 24, 1, 2, 5 --jump at end
-- 	--32, 12, 0, 1, 0 --octave

-- 	for i = 0, lengthInBeats - 1, 1 do
-- 		URea.InsertAudioItemPercussive(kickFile, KickTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.25, 0.225)
-- 		URea.InsertAudioItemPercussive(kickFile, SideKickTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.25, 0.225)

-- 		if i % 2 == 1 then
-- 			URea.InsertAudioItemPercussive(snareFile, SnareTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.4, 0.225)
-- 		end

-- 		if i % (lengthInBeats / division) == 0 then
-- 			URea.InsertMIDIItemFromPitchValues(
-- 				synthbassMelodyNotes,
-- 				SynthbassTrack,
-- 				reaper.TimeMap2_beatsToTime(0, i) + offset,
-- 				reaper.TimeMap2_beatsToTime(0, (lengthInBeats / division))
-- 			)
-- 		end
-- 	end

-- 	--Insert envelope points
-- 	local pointsPerBeat = 8
-- 	local increment = 1 / pointsPerBeat
-- 	for i = 0, lengthInBeats, increment do
-- 		URea.InsertEnvelopePointSimple(SBIntensityEnv, i, offset, UMath.SawUp01(i, lengthInBeats, 0.5))
-- 		URea.InsertEnvelopePointSimple(SBTimbre1Env, i, offset, UMath.Sin01(i, lengthInBeats / 2, 1))
-- 		URea.InsertEnvelopePointSimple(SBTimbre2Env, i, offset, UMath.Triangle01(i, lengthInBeats / 2, 1))
-- 		URea.InsertEnvelopePointSimple(SBWidthEnv, i, offset, 0.3)
-- 	end

-- 	currentTimePosition = currentTimePosition + timeLength
-- end

function CreateOrnamentFile(sourceFiles)
end

Main()
