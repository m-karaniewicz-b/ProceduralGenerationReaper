function Init()
	local path = ({reaper.get_action_context()})[2]:match("^.+[\\//]")
	package.path = path .. "?.lua"

	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		Separator = "\\"
	else
		Separator = "/"
	end

	require("MathUtils")
	require("ReaperUtils")
	require("FileUtils")
end

function Main()
	Init()

	MainRenderDir = "W:\\Samples\\Procedural\\Generated"
	SubgenerationRenderDir = "W:\\Samples\\Procedural\\SubGenerations"
	GeneratedProjectFilesDir = "W:\\Samples\\Procedural\\Generated\\ProjectFiles"

	KickDir = "W:\\Samples\\Procedural\\Banks\\Kicks"
	SnareDir = "W:\\Samples\\Procedural\\Banks\\Snares"
	OrnamentSourceDir = "W:\\Samples\\Procedural\\Banks\\Random"

	TemplateFileName = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"

	--Load file template
	--reaper.Main_openProject(templateFileName)

	ParentTrack = reaper.GetTrack(0, 0)
	KickTrack = reaper.GetTrack(0, 1)
	SideKickTrack = reaper.GetTrack(0, 2)
	SnareTrack = reaper.GetTrack(0, 3)
	ReverbSendTrack = reaper.GetTrack(0, 4)
	SynthbassTrack = reaper.GetTrack(0, 5)

	StartGenerating(1, true, true)

	ReaperUtils.ReaperUpdateView()
end

function StartGenerating(generationCount, saveProject, renderToFile)
	reaper.PreventUIRefresh(111)
	reaper.Undo_BeginBlock()

	for i = 0, generationCount - 1, 1 do
		ReaperUtils.ReaperClearProjectItems()

		CurrCompName = "Gen_" .. os.date("%Y_%m_%d_%H_%M_%S")

		CreateComposition()

		if (saveProject) then
			reaper.Main_SaveProject(0, false)

			local _, projFile = reaper.EnumProjects(-1, "")

			local projFileCopy = GeneratedProjectFilesDir .. Separator .. CurrCompName .. ".rpp"

			local ok, err
			CopyFile(projFile, projFileCopy)
			if ok == false then
				reaper.ShowConsoleMsg("Copying failed: \n" .. projFileCopy .. "\n")
			end
		end

		if (renderToFile) then
			ReaperUtils.RenderProjectToPath(MainRenderDir .. Separator .. CurrCompName .. ".wav")
		end
	end

	reaper.Undo_EndBlock("Generate", 1)
	reaper.PreventUIRefresh(-111)
end

function CreateComposition()
	--Samples
	local kickFile = KickDir .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(KickDir))
	local snareFile = SnareDir .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(SnareDir))

	local ornamentSourceFiles =
		OrnamentSourceDir .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(SnareDir))
	local ornamentSourceCount = 5
	for i = 0, ornamentSourceCount, 1 do
		ornamentSourceFiles =
			OrnamentSourceDir .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(SnareDir))
	end

	local ornamentFile = CreateOrnamentFile(ornamentSourceFiles)

	CurrSegmentPos = 0

	ReaperUtils.RandomizeBPM(90, 120)

	CreateSegment(8, 2, 16, kickFile, snareFile, ornamentFile)
end

function CreateSegment(length, division, noteDensity, kickFile, snareFile, ornamentFile)
	local timeLength = reaper.TimeMap2_beatsToTime(0, length)
	local offset = CurrSegmentPos

	local segmentRandomNoteValues = MathUtils.GenerateRandomValuesArray(noteDensity)

	local synthbassMel = CreateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 1, 3, 2)
	--local synthbassMel = GenerateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 24, 1, 2, 5); --jump at end
	--local synthbassMel = GenerateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 0, 1, 0); --octave

	for i = 0, length - 1, 1 do
		ReaperUtils.InsertAudioItemPercussive(kickFile, KickTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.25, 0.225)
		ReaperUtils.InsertAudioItemPercussive(
			kickFile,
			SideKickTrack,
			reaper.TimeMap2_beatsToTime(0, i) + offset,
			0.25,
			0.225
		)

		if i % 2 == 1 then
			ReaperUtils.InsertAudioItemPercussive(snareFile, SnareTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.4, 0.225)
		end

		if i % (length / division) == 0 then
			ReaperUtils.InsertMIDIItemFromPitchValues(
				synthbassMel,
				SynthbassTrack,
				reaper.TimeMap2_beatsToTime(0, i) + offset,
				reaper.TimeMap2_beatsToTime(0, (length / division))
			)
		end
	end

	CurrSegmentPos = CurrSegmentPos + timeLength
end

function CreateOrnamentFile(sourceFiles)
end

function CreateBasicMelodyFromWeights(weights, basePitch, semitoneRange, progressMult, progressCurve, weightsCurve)
	basePitch = basePitch or 36
	semitoneRange = semitoneRange or 18
	progressMult = progressMult or 1
	progressCurve = progressCurve or 3
	weightsCurve = weightsCurve or 1.5

	local ret = {}
	local bias = 0
	local noteCount = #weights
	for i = 0, noteCount, 1 do
		local currProgress = 1 * (1 - progressMult) + ((i / noteCount) ^ progressCurve) * progressMult

		local remapWeight = (weights[i] * 2) - 1

		local pitchDelta = currProgress * MathUtils.Sign(remapWeight) * math.abs(remapWeight) ^ weightsCurve
		--reaper.ShowConsoleMsg(pitchDelta.."\n")

		pitchDelta = pitchDelta * semitoneRange

		ret[i] = MathUtils.Round(basePitch + pitchDelta)
	end

	return ret
end

Main()
