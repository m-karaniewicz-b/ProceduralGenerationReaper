local function ClearProject()
	ReaperUtils.ReaperClearProjectItems()
	ReaperUtils.EnvelopeTableDeleteAllPoints(BassEnvelopesTable)
end

local function Initialize()
	math.randomseed(CurrentCompositionSeed)
end

local function SelectFiles()
	PathFileKick = PathDirBankKick .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankKick))
	PathFileSnare =
		PathDirBankSnare .. "\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankSnare))
	PathFilePresetBass =
		PathDirBankVitalVST3Bass ..
		"\\" .. MathUtils.GetRandomArrayValue(FileUtils.GetFilesInDirectory(PathDirBankVitalVST3Bass))
end

local function CreateBassNoteSequence(phraseLength)
	local bassNotesRng = RngContainer(1000)

	local bassItemsPerPhrase = 4
	local bassItemLength = phraseLength / bassItemsPerPhrase
	local bassMaxNotesPerBeat = 8
	local bassNotesPitchBase = 32
	local bassNotesPitchRange = 16
	local bassNotesTimeWeightTable = {0, 0, 0, 1, 0, 8}
	local bassProgressFormula =
		Formula(
		function(x)
			return x ^ 4
		end
	)
	local bassPitchFormula =
		Formula(
		function(x)
			return x ^ 0.5
		end
	)

	local bassNoteSequence =
		NoteSequence(
		bassProgressFormula,
		bassPitchFormula,
		bassNotesPitchBase,
		bassNotesPitchRange,
		bassItemLength,
		bassMaxNotesPerBeat,
		bassNotesTimeWeightTable
	)

	--TODO: implement RngContainer into NoteSequence
	bassNoteSequence.Recalculate(MathUtils.GenerateRandomValuesArray(1000))

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
	Initialize()
	SelectFiles()
	reaper.TrackFX_SetPreset(TrackBass, 0, PathFilePresetBass)
	ReaperUtils.RandomizeBPM(90, 110)

	local phraseLength = 32
	local bassNoteSequence = CreateBassNoteSequence(32)
	local phraseRng = RngContainer(1000)

	local phrase = Phrase(phraseLength, phraseRng.Copy(), bassNoteSequence, PathFileKick, PathFileSnare, nil)
	local phrase2 = Phrase(phraseLength, phraseRng.Copy(), bassNoteSequence, PathFileKick, PathFileSnare, nil)
	local phrase3 = Phrase(phraseLength, phraseRng.Copy(), bassNoteSequence, PathFileKick, PathFileSnare, nil)

	local phraseQueue = {phrase, phrase2, phrase3}
	PhraseQueueSetTracks(phraseQueue)
	PhraseQueueInsert(phraseQueue)
	ReaperUtils.EnvelopeTableSortPoints(BassEnvelopesTable)
end
