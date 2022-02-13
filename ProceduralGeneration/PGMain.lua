function Init()
	local path = ({reaper.get_action_context()})[2]:match("^.+[\\//]")
	package.path = path .. "?.lua"

	UMath = require("MathUtils")
	URea = require("ReaperUtils")
	UFile = require("FileUtils")
	ULog = require("LogUtils")

	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		Separator = "\\"
	else
		Separator = "/"
	end
end

function Main()
	Init()

	MainRenderDir = "W:\\Samples\\Procedural\\Generated"
	SubgenerationRenderDir = "W:\\Samples\\Procedural\\SubGenerations"
	GeneratedProjectFilesDir = "W:\\Samples\\Procedural\\Generated\\ProjectFiles"

	KickBankDir = "W:\\Samples\\Procedural\\Banks\\Kicks"
	SnareBankDir = "W:\\Samples\\Procedural\\Banks\\Snares"
	OrnamentSourceBankDir = "W:\\Samples\\Procedural\\Banks\\Random"

	LogsDir = "W:\\Samples\\Procedural\\Logs"
	TemplateFileName = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"
	--Load file template
	--reaper.Main_openProject(templateFileName)

	ParentTrack = reaper.GetTrack(0, 0)
	KickTrack = reaper.GetTrack(0, 1)
	SideKickTrack = reaper.GetTrack(0, 2)
	SnareTrack = reaper.GetTrack(0, 3)
	ReverbSendTrack = reaper.GetTrack(0, 4)
	SynthbassTrack = reaper.GetTrack(0, 5)

	StartGenerating(1, true, false)
end

function StartGenerating(generationCount, saveProject, renderToFile)
	reaper.PreventUIRefresh(111)
	reaper.Undo_BeginBlock()

	for i = 0, generationCount - 1, 1 do
		URea.ReaperClearProjectItems()

		CurrCompName = "Gen_" .. os.date("%Y_%m_%d_%H_%M_%S")

		CreateComposition()

		if (saveProject) then
			reaper.Main_SaveProject(0, false)

			local _, projFile = reaper.EnumProjects(-1, "")

			local projFileCopy = GeneratedProjectFilesDir .. Separator .. CurrCompName .. ".rpp"

			local ok, _
			UFile.CopyFileToPath(projFile, projFileCopy)

			if ok == false then
				ULog.Print("Copying failed: " .. projFileCopy)
			end
		end

		if (renderToFile) then
			URea.RenderProjectToPath(MainRenderDir .. Separator .. CurrCompName .. ".wav")
		end
	end

	URea.ReaperUpdateView()

	reaper.Undo_EndBlock("Generate", 1)
	reaper.PreventUIRefresh(-111)
end

function CreateComposition()
	KickFile = KickBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(KickBankDir))
	SnareFile = SnareBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(SnareBankDir))

	-- local ornamentSourceFiles =
	-- 	OrnamentSourceBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(SnareBankDir))
	-- local ornamentSourceCount = 5

	-- for i = 0, ornamentSourceCount, 1 do
	-- 	ornamentSourceFiles =
	-- 		OrnamentSourceBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(SnareBankDir))
	-- end

	-- OrnamentFile = CreateOrnamentFile(ornamentSourceFiles)

	local synthbassInstrumentIndex = reaper.TrackFX_GetInstrument(SynthbassTrack)
	local synthbassInstrumentFXParameterNames =
		ReaperUtils.GetTrackFXParameterNames(SynthbassTrack, synthbassInstrumentIndex)

	Macro1Env =
		reaper.GetFXEnvelope(
		SynthbassTrack,
		synthbassInstrumentIndex,
		UMath.GetFirstIndexMatchingString(synthbassInstrumentFXParameterNames, "Macro 1"),
		true
	)
	Macro2Env =
		reaper.GetFXEnvelope(
		SynthbassTrack,
		synthbassInstrumentIndex,
		UMath.GetFirstIndexMatchingString(synthbassInstrumentFXParameterNames, "Macro 2"),
		true
	)
	Macro3Env =
		reaper.GetFXEnvelope(
		SynthbassTrack,
		synthbassInstrumentIndex,
		UMath.GetFirstIndexMatchingString(synthbassInstrumentFXParameterNames, "Macro 3"),
		true
	)
	Macro4Env =
		reaper.GetFXEnvelope(
		SynthbassTrack,
		synthbassInstrumentIndex,
		UMath.GetFirstIndexMatchingString(synthbassInstrumentFXParameterNames, "Macro 4"),
		true
	)

	reaper.DeleteEnvelopePointRange(Macro1Env, 0, math.huge)
	reaper.DeleteEnvelopePointRange(Macro2Env, 0, math.huge)
	reaper.DeleteEnvelopePointRange(Macro3Env, 0, math.huge)
	reaper.DeleteEnvelopePointRange(Macro4Env, 0, math.huge)

	CurrSegmentPos = 0

	URea.RandomizeBPM(90, 120)

	CreateSegment(8, 2, 16)
	CreateSegment(8, 2, 16)
	CreateSegment(8, 2, 16)

	reaper.Envelope_SortPoints(Macro1Env)
	reaper.Envelope_SortPoints(Macro2Env)
	reaper.Envelope_SortPoints(Macro3Env)
	reaper.Envelope_SortPoints(Macro4Env)
end

function CreateSegment(length, division, noteDensity)
	local kickFile = KickFile
	local snareFile = SnareFile
	--local ornamentFile = OrnamentFile
	local timeLength = reaper.TimeMap2_beatsToTime(0, length)
	local offset = CurrSegmentPos

	local segmentRandomNoteValues = UMath.GenerateRandomValuesArray(noteDensity)

	local synthbassMel = CreateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 1, 3, 2)
	--local synthbassMel = CreateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 24, 1, 2, 5); --jump at end
	--local synthbassMel = CreateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 0, 1, 0) --octave

	for i = 0, length - 1, 1 do
		URea.InsertAudioItemPercussive(kickFile, KickTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.25, 0.225)
		URea.InsertAudioItemPercussive(kickFile, SideKickTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.25, 0.225)

		if i % 2 == 1 then
			URea.InsertAudioItemPercussive(snareFile, SnareTrack, reaper.TimeMap2_beatsToTime(0, i) + offset, 0.4, 0.225)
		end

		if i % (length / division) == 0 then
			URea.InsertMIDIItemFromPitchValues(
				synthbassMel,
				SynthbassTrack,
				reaper.TimeMap2_beatsToTime(0, i) + offset,
				reaper.TimeMap2_beatsToTime(0, (length / division))
			)
		end

		local envelopePointValue = i / length
		reaper.InsertEnvelopePoint(
			Macro1Env,
			reaper.TimeMap2_beatsToTime(0, i) + offset,
			envelopePointValue,
			0,
			1,
			false,
			true
		)
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

		local pitchDelta = currProgress * UMath.Sign(remapWeight) * math.abs(remapWeight) ^ weightsCurve

		pitchDelta = pitchDelta * semitoneRange

		ret[i] = UMath.Round(basePitch + pitchDelta)
	end

	return ret
end

Main()
