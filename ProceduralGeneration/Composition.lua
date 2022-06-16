local function ClearProject()
	ReaperUtils.ReaperClearProjectItems()
	ReaperUtils.EnvelopeTableDeleteAllPoints(BassEnvelopesTable)
end

local function InitializeRng()
	math.randomseed(CurrentCompositionSeed)
end

local function SortEnvelopePoints()
	ReaperUtils.EnvelopeTableSortPoints(BassEnvelopesTable)
end

local function SelectFiles()
	PathFileKick = PathDirBankKick .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankKick))
	PathFileSnare =
		PathDirBankSnare .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankSnare))
	PathFilePresetBass =
		PathDirBankVitalVST3Bass ..
		"\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankVitalVST3Bass))
end

local function SetPresets()
	reaper.TrackFX_SetPreset(TrackBass, 0, PathFilePresetBass)
end

local function SetBPM()
	ReaperUtils.RandomizeBPM(90, 110)
end

local function CreateBassNoteSequence(phraseLength)
	local bassNoteSequenceRngContainer = RngContainer(1000)
	local bassItemsPerPhrase = 4
	local bassItemLength = phraseLength / bassItemsPerPhrase
	local bassMaxNotesPerBeat = 8
	local bassNotesTimeWeightTable = {0, 0, 0, 1, 0, 8}

	local bassNotesPitchBase = 32
	local bassNotesPitchRange = 16
	local bassProgressFormula = Formula(MathUtils.SawUp01, 0.3, 1)
	local bassPitchFormula = Formula(MathUtils.SawUp01, 2, 1)

	local bassNoteSequence =
		NoteSequence(
		bassNoteSequenceRngContainer,
		bassItemLength,
		bassMaxNotesPerBeat,
		bassNotesTimeWeightTable,
		bassNotesPitchBase,
		bassNotesPitchRange,
		bassProgressFormula,
		bassPitchFormula
	)

	return bassNoteSequence
end

-- local function CreatePhrase(phraseLength, compositionProgress)
-- 		local verticalIntroMain = PhraseVerticalData(false, false, false, true, 0, 1)
-- 	local verticalIntroEnd = PhraseVerticalData(false, true, false, true, 0, 1)
-- 	local introPhraseRngContainer = RngContainer(rngMaxCountDefault)
-- 	local phraseIntro =
-- 		Phrase(introPhraseRngContainer, bassNoteSequenceA, phraseLength, 0.5, verticalIntroMain, verticalIntroEnd)
-- end

local function PhraseQueueSetTracks(phraseQueue)
	for index, value in ipairs(phraseQueue) do
		value.SetTracks(TrackKick, TrackSideKick, TrackSnare, TrackBass)
	end
end

local function PhraseQueueSetFiles(phraseQueue)
	for index, value in ipairs(phraseQueue) do
		value.SetFiles(PathFileKick, PathFileSnare, nil)
	end
end

local function PhraseQueueInsert(phraseQueue)
	local currentTimePosition = 0
	for index, value in ipairs(phraseQueue) do
		currentTimePosition = value.Insert(currentTimePosition)
	end
end

function CreateComposition()
	ClearProject()
	InitializeRng()
	SelectFiles()
	SetPresets()
	SetBPM()

	local phraseLength = 32
	local rngMaxCountDefault = 1000

	local bassNoteSequenceA = CreateBassNoteSequence(32)
	local bassNoteSequenceB = bassNoteSequenceA.Copy()
	bassNoteSequenceB.pitchDistributionModifierFormula.steepness =
		bassNoteSequenceB.pitchDistributionModifierFormula.steepness * 8
	bassNoteSequenceB.RecalculatePitch()

	local verticalIntroMain = PhraseVerticalData(false, false, false, true, 0, 1)
	local verticalIntroEnd = PhraseVerticalData(false, true, false, true, 0, 1)
	local introPhraseRngContainer = RngContainer(rngMaxCountDefault)
	local phraseIntro =
		Phrase(introPhraseRngContainer, bassNoteSequenceA, phraseLength, 0.5, verticalIntroMain, verticalIntroEnd)

	local verticalPartAMain = PhraseVerticalData(true, true, true, true, 0, 1)
	local verticalPartAEnd = PhraseVerticalData(false, true, false, true, 0, 1)
	local phrasePartA =
		Phrase(RngContainer(rngMaxCountDefault), bassNoteSequenceB, phraseLength, 0.875, verticalPartAMain, verticalPartAEnd)

	local verticalPartBMain = PhraseVerticalData(true, true, true, true, 0, 1)
	local verticalPartBEnd = PhraseVerticalData(false, true, true, true, 0, 1)
	local phrasePartB =
		Phrase(RngContainer(rngMaxCountDefault), bassNoteSequenceB, phraseLength, 0.875, verticalPartBMain, verticalPartBEnd)

	local verticalOutroMain = PhraseVerticalData(true, false, true, true, 0, 1)
	local verticalOutroEnd = PhraseVerticalData(false, false, true, true, 0, 1)
	local phraseOutro =
		Phrase(RngContainer(rngMaxCountDefault), bassNoteSequenceA, phraseLength, 0.875, verticalOutroMain, verticalOutroEnd)

	local phraseQueue = {phraseIntro, phrasePartA, phrasePartB, phraseOutro}
	PhraseQueueSetFiles(phraseQueue)
	PhraseQueueSetTracks(phraseQueue)
	PhraseQueueInsert(phraseQueue)
	SortEnvelopePoints()
end
