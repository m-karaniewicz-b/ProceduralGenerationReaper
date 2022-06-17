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

local function ApplyRandomModifierToNoteSequence(noteSequence)
	noteSequence.pitchDistributionModifierFormula.steepness = noteSequence.pitchDistributionModifierFormula.steepness * 8
end

local function CreateBassNoteSequenceVariations(originalSequence, variationCount)
	local sequenceVariations = {}
	sequenceVariations[#sequenceVariations + 1] = originalSequence
	local newSequence
	for i = 1, variationCount, 1 do
		newSequence = originalSequence.Copy()
		ApplyRandomModifierToNoteSequence(newSequence)
		newSequence.RecalculatePitch()
		sequenceVariations[#sequenceVariations + 1] = newSequence
	end
	return sequenceVariations
end

local function CreatePhrase(phraseLength, compositionProgress, bassNoteSequenceVariations, compositionRngContainer)
	local introOutroValue = (1 - MathUtils.Triangle01(compositionProgress, 1, 1)) * 1.5
	local kickMainActive = introOutroValue > compositionRngContainer.GetNext()
	local sidechainMainActive = introOutroValue > compositionRngContainer.GetNext()
	local phaseVerticalDataMain =
		PhraseVerticalData(
		kickMainActive and sidechainMainActive,
		introOutroValue ^ 0.5 > compositionRngContainer.GetNext(),
		sidechainMainActive,
		true,
		0,
		1
	)

	local phaseVerticalDataEnd =
		PhraseVerticalData(
		false,
		introOutroValue > compositionRngContainer.GetNext(),
		0.5 < compositionRngContainer.GetNext(),
		true,
		0,
		1
	)

	local bassNoteSequence = bassNoteSequenceVariations[1]

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
	InitializeRng()
	local compositionRngContainer = RngContainer()
	SetBPM(compositionRngContainer)
	SelectFiles(compositionRngContainer)
	SetPresets()

	local phraseCount = math.random(phraseCountMin, phraseCountMax)
	local bassNoteSequenceVariations = CreateBassNoteSequenceVariations(CreateBassNoteSequence(phraseLength), 2)
	local phraseQueue = {}
	for i = 1, phraseCount do
		phraseQueue[#phraseQueue + 1] =
			CreatePhrase(phraseLength, (i - 1) / phraseCount, bassNoteSequenceVariations, compositionRngContainer)
	end

	-- local verticalIntroMain = PhraseVerticalData(false, false, false, true, 0, 1)
	-- local verticalIntroEnd = PhraseVerticalData(false, true, false, true, 0, 1)
	-- local introPhraseRngContainer = RngContainer()
	-- local phraseIntro =
	-- 	Phrase(introPhraseRngContainer, bassNoteSequenceVariations[1], phraseLength, 0.5, verticalIntroMain, verticalIntroEnd)

	-- local verticalPartAMain = PhraseVerticalData(true, true, true, true, 0, 1)
	-- local verticalPartAEnd = PhraseVerticalData(false, true, false, true, 0, 1)
	-- local phrasePartA =
	-- 	Phrase(RngContainer(), bassNoteSequenceVariations[2], phraseLength, 0.875, verticalPartAMain, verticalPartAEnd)

	-- local verticalPartBMain = PhraseVerticalData(true, true, true, true, 0, 1)
	-- local verticalPartBEnd = PhraseVerticalData(false, true, true, true, 0, 1)
	-- local phrasePartB =
	-- 	Phrase(RngContainer(), bassNoteSequenceVariations[2], phraseLength, 0.875, verticalPartBMain, verticalPartBEnd)

	-- local verticalOutroMain = PhraseVerticalData(true, false, true, true, 0, 1)
	-- local verticalOutroEnd = PhraseVerticalData(false, false, true, true, 0, 1)
	-- local phraseOutro =
	-- 	Phrase(RngContainer(), bassNoteSequenceVariations[1], phraseLength, 0.875, verticalOutroMain, verticalOutroEnd)

	-- phraseQueue = {phraseIntro, phrasePartA, phrasePartB, phraseOutro}

	PhraseQueueSetFiles(phraseQueue)
	PhraseQueueSetTracks(phraseQueue)

	ClearProject()
	PhraseQueueInsert(phraseQueue)
	SortEnvelopePoints()
end
