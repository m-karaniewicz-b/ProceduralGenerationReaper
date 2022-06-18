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

local function SelectFiles(rngContainer)
	--TODO: implement RngContainer
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

local function SetBPM(rngContainer)
	ReaperUtils.SetBPM(rngContainer.RandomRangeInt(90, 110))
end

local function CreateBassNoteSequence(phraseLength, rngContainer)
	local bassItemsPerPhrase = 4
	local bassItemLength = phraseLength / bassItemsPerPhrase
	local bassMaxNotesPerBeat = 8
	local bassNotesTimeWeightTable = {0, 0, 0, 1, 0, 8}
	local bassNotesPitchBase = rngContainer.RandomRangeInt(26, 38)
	local bassNotesPitchRange = 16
	local bassProgressFormula = Formula(MathUtils.SawUp01, 0.3, 1)
	local bassPitchFormula = Formula(MathUtils.SawUp01, 2, 1)

	local bassNoteSequence =
		NoteSequence(
		RngContainer(),
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

local function ApplyRandomModifierToNoteSequence(noteSequence, rngContainer)
	local modifiers = {
		function(ns)
			ns.pitchDistributionModifierFormula.steepness =
				ns.pitchDistributionModifierFormula.steepness * (rngContainer.RandomRangeFloat(8, 12))
		end,
		function(ns)
			ns.pitchBaseSemitones = ns.pitchBaseSemitones + rngContainer.RandomRangeInt(-1, 1) * 12
		end,
		function(ns)
			ns.pitchRangeSemitones = ns.pitchRangeSemitones * (rngContainer.RandomRangeFloat(1.5, 2.5))
		end
	}
	modifiers[rngContainer.RandomRangeInt(1, #modifiers)](noteSequence)
end

local function CreateBassNoteSequenceVariations(originalSequence, variationCount, rngContainer)
	local sequenceVariations = {}
	sequenceVariations[#sequenceVariations + 1] = originalSequence
	local newSequence
	for i = 1, variationCount, 1 do
		newSequence = originalSequence.Copy()
		ApplyRandomModifierToNoteSequence(newSequence, rngContainer)
		newSequence.RecalculatePitch()
		sequenceVariations[#sequenceVariations + 1] = newSequence
	end
	return sequenceVariations
end

local function CreatePhrase(phraseLength, compositionProgress, bassNoteSequenceVariations, compositionRngContainer)
	local compositionValueIntroOutro = MathUtils.Clamp((1 - MathUtils.Triangle01(compositionProgress, 1, 1)) * 2, 0, 1)
	local variationStart = 0.3
	local compositionValueVariation = MathUtils.StepValue(compositionProgress, variationStart) / (1 - variationStart)

	local kickMainActive = compositionValueIntroOutro > compositionRngContainer.GetNext()
	local phaseVerticalDataMain =
		PhraseVerticalData(
		kickMainActive,
		compositionValueIntroOutro ^ 0.5 > compositionRngContainer.GetNext(),
		kickMainActive,
		true,
		compositionValueIntroOutro,
		0,
		1
	)

	local phaseVerticalDataEnd =
		PhraseVerticalData(
		false,
		compositionValueIntroOutro > compositionRngContainer.GetNext(),
		0.5 < compositionRngContainer.GetNext() and kickMainActive,
		true,
		compositionValueIntroOutro,
		0,
		1
	)

	local variationIndex =
		MathUtils.Round(MathUtils.Remap(compositionValueVariation, 1, #bassNoteSequenceVariations, 0, 1))
	local bassNoteSequence = bassNoteSequenceVariations[variationIndex]

	local phraseEndingPositions = {1, 0.875, 0.75}
	local phraseEndingPositionWeights = {1, 4, 3}
	local phraseEndingPositionSelectedIndex =
		MathUtils.GetWeightedIndex(
		phraseEndingPositionWeights,
		compositionRngContainer.GetNext() * MathUtils.GetNumericTableSum(phraseEndingPositionWeights)
	)
	local phraseEndingNormalizedPosition = phraseEndingPositions[phraseEndingPositionSelectedIndex]

	local phrase =
		Phrase(
		RngContainer(),
		bassNoteSequence,
		phraseLength,
		phraseEndingNormalizedPosition,
		phaseVerticalDataMain,
		phaseVerticalDataEnd
	)
	return phrase
end

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

function CreateComposition(phraseCountMin, phraseCountMax, phraseLength)
	phraseCountMin = phraseCountMin or 7
	phraseCountMax = phraseCountMax or 9
	phraseLength = phraseLength or 32

	InitializeRng()
	local compositionRngContainer = RngContainer()
	SetBPM(compositionRngContainer)
	SelectFiles(compositionRngContainer)
	SetPresets()

	local phraseCount = math.random(phraseCountMin, phraseCountMax)
	local bassNoteSequenceVariations =
		CreateBassNoteSequenceVariations(
		CreateBassNoteSequence(phraseLength, compositionRngContainer),
		4,
		compositionRngContainer
	)
	local phraseQueue = {}
	for i = 1, phraseCount do
		phraseQueue[#phraseQueue + 1] =
			CreatePhrase(phraseLength, (i - 1) / (phraseCount - 1), bassNoteSequenceVariations, compositionRngContainer)
	end

	PhraseQueueSetFiles(phraseQueue)
	PhraseQueueSetTracks(phraseQueue)

	ClearProject()
	PhraseQueueInsert(phraseQueue)
	SortEnvelopePoints()
end
