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

local function PhraseQueueSetTracks(phraseQueue)
	for index, value in ipairs(phraseQueue) do
		value.SetTracks(TrackKick, TrackSideKick, TrackSnare, TrackBass)
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
	local phraseRngContainer = RngContainer(1000)

	local bassNoteSequence1 = CreateBassNoteSequence(32)
	bassNoteSequence1.RecalculatePitch()

	local bassNoteSequence2 = bassNoteSequence1.Copy()
	--bassNoteSequence2.pitchRangeSemitones = bassNoteSequence2.pitchRangeSemitones * 2
	bassNoteSequence2.pitchDistributionModifierFormula.steepness =
		bassNoteSequence2.pitchDistributionModifierFormula.steepness * 8
	bassNoteSequence2.RecalculatePitch()

	local bassNoteSequence3 = bassNoteSequence2.Copy()
	--bassNoteSequence2.pitchRangeSemitones = bassNoteSequence2.pitchRangeSemitones * 2
	bassNoteSequence3.pitchDistributionModifierFormula.steepness =
		bassNoteSequence3.pitchDistributionModifierFormula.steepness / 8
	bassNoteSequence3.RecalculatePitch()

	local phrase1 = Phrase(phraseRngContainer.Copy(), phraseLength, bassNoteSequence1, PathFileKick, PathFileSnare, nil)
	local phrase2 = Phrase(phraseRngContainer.Copy(), phraseLength, bassNoteSequence2, PathFileKick, PathFileSnare, nil)
	local phrase3 = Phrase(phraseRngContainer.Copy(), phraseLength, bassNoteSequence3, PathFileKick, PathFileSnare, nil)

	local phraseQueue = {phrase1, phrase2, phrase3}
	PhraseQueueSetTracks(phraseQueue)
	PhraseQueueInsert(phraseQueue)
	SortEnvelopePoints()
end
