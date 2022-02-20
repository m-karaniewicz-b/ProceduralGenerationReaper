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
		math.randomseed(os.time())

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
	CurrentTimePosition = 0

	KickFile = KickBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(KickBankDir))
	SnareFile = SnareBankDir .. "\\" .. UMath.GetRandomArrayValue(UFile.GetFilesInDirectory(SnareBankDir))

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
		URea.GetParameterEnvelopesFromTrackFXByNames(
		SynthbassTrack,
		synthbassParamNames,
		reaper.TrackFX_GetInstrument(SynthbassTrack)
	)

	SBIntensityEnv = synthbassEnvelopes[1]
	SBTimbre1Env = synthbassEnvelopes[2]
	SBTimbre2Env = synthbassEnvelopes[3]
	SBWidthEnv = synthbassEnvelopes[4]

	for index, value in ipairs(synthbassEnvelopes) do
		reaper.DeleteEnvelopePointRange(value, 0, math.huge)
	end

	URea.RandomizeBPM(90, 110)

	CreatePhrase(8, 2, 16)
	--CreatePhrase(8, 2, 16)
	--CreatePhrase(8, 2, 16)

	for index, value in ipairs(synthbassEnvelopes) do
		reaper.Envelope_SortPoints(value)
	end
end

function CreatePhrase(length, division, noteDensity)
	local kickFile = KickFile
	local snareFile = SnareFile
	--local ornamentFile = OrnamentFile
	local timeLength = reaper.TimeMap2_beatsToTime(0, length)
	local offset = CurrentTimePosition

	local phraseRandomNoteValues = UMath.GenerateRandomValuesArray(noteDensity)

	local synthbassMel = CreateBasicMelodyFromWeights(phraseRandomNoteValues, 32, 12, 1, 3, 2)
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
	end

	--Insert envelope points
	local pointsPerBeat = 8
	local increment = 1 / pointsPerBeat
	for i = 0, length, increment do
		URea.InsertEnvelopePointSimple(SBIntensityEnv, i, offset, UMath.SawUp01(i, length, 0.5))
		URea.InsertEnvelopePointSimple(SBTimbre1Env, i, offset, UMath.Sin01(i, length / 2, 1))
		URea.InsertEnvelopePointSimple(SBTimbre2Env, i, offset, UMath.Triangle01(i, length / 2, 1))
		URea.InsertEnvelopePointSimple(SBWidthEnv, i, offset, 0.3)
	end

	CurrentTimePosition = CurrentTimePosition + timeLength
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
