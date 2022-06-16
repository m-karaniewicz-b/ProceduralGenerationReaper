function NoteSequence(
	_rngContainer,
	_lengthInBeats,
	_noteFractionsPerBeat,
	_notesLengthWeights,
	_pitchBaseSemitones,
	_pitchRangeSemitones,
	_pitchProgressModifierFormula,
	_pitchDistributionModifierFormula)
	local self = {
		pitchProgressModifierFormula = _pitchProgressModifierFormula,
		pitchDistributionModifierFormula = _pitchDistributionModifierFormula,
		pitchBaseSemitones = _pitchBaseSemitones,
		pitchRangeSemitones = _pitchRangeSemitones
	}

	_notesLengthWeights = _notesLengthWeights or {0, 1, 1, 1, 0}
	local maximumNoteFractionCount = _lengthInBeats * _noteFractionsPerBeat
	local rngContainer = _rngContainer

	local noteDataTable = {}
	local notePitchTable = {}
	local noteStartTimeTable = {}
	local noteLengthTable = {}

	local function CalculateNoteTiming()
		noteDataTable = {}
		local noteLengthWeightsSum = MathUtils.GetNumericTableSum(_notesLengthWeights)

		local noteCounter = 0
		local noteFractionCounter = 0
		while noteFractionCounter < maximumNoteFractionCount do
			local currentNoteLength =
				MathUtils.GetWeightedIndex(_notesLengthWeights, rngContainer.GetNext() * noteLengthWeightsSum)

			--TODO: Last note should not ignore the weights
			while noteFractionCounter + currentNoteLength > maximumNoteFractionCount do
				currentNoteLength = currentNoteLength - 1
			end

			noteDataTable[noteCounter] = NoteData()
			noteDataTable[noteCounter].SetTiming(noteFractionCounter, currentNoteLength)

			noteFractionCounter = noteFractionCounter + currentNoteLength
			noteCounter = noteCounter + 1
		end
	end

	local function CalculateNotePitches()
		local noteCount = #noteDataTable
		for i = 0, noteCount, 1 do
			local currentTime = noteDataTable[i].startTimeInFractions / maximumNoteFractionCount
			local progressModifier = self.pitchProgressModifierFormula.GetValue(currentTime)
			local randomValue = (rngContainer.GetNext() * 2) - 1
			local randomValueModifiedDistribution = self.pitchDistributionModifierFormula.GetValue(math.abs(randomValue))
			local finalValue = randomValueModifiedDistribution * progressModifier * MathUtils.Sign(randomValue)
			noteDataTable[i].SetPitch(MathUtils.Round(self.pitchBaseSemitones + finalValue * self.pitchRangeSemitones))
		end
	end

	local function CacheNoteValues()
		local noteCount = #noteDataTable
		notePitchTable = {}
		noteStartTimeTable = {}
		noteLengthTable = {}

		for i = 0, noteCount, 1 do
			notePitchTable[i] = noteDataTable[i].pitch
			noteStartTimeTable[i] = noteDataTable[i].startTimeInFractions
			noteLengthTable[i] = noteDataTable[i].lengthInFractions
		end
	end

	function self.RecalculatePitch()
		rngContainer.CheckpointLoad(1)
		CalculateNotePitches()
		CacheNoteValues()
	end

	function self.GetNoteDataTable()
		return noteDataTable
	end

	function self.GetNotePitchTable()
		return notePitchTable
	end

	function self.GetNoteStartTimeTableNoteFractions()
		return noteStartTimeTable
	end

	function self.GetNoteLengthTable()
		return noteLengthTable
	end

	function self.GetLength()
		return _lengthInBeats
	end

	function self.GetNoteStartTimeAndLengthTablesProjectTime(itemStartTime, itemLength)
		local noteFractionLengthProjectTime = itemLength / maximumNoteFractionCount
		local noteStartTimeTableProjectTime = {}
		local noteLengthTableProjectTime = {}

		for i = 0, #noteLengthTable do
			noteStartTimeTableProjectTime[i] = noteStartTimeTable[i] * noteFractionLengthProjectTime + itemStartTime
			noteLengthTableProjectTime[i] = noteLengthTable[i] * noteFractionLengthProjectTime
		end

		return noteStartTimeTableProjectTime, noteLengthTableProjectTime
	end

	function self.Copy()
		local newNS =
			NoteSequence(
			_rngContainer.Copy(),
			_lengthInBeats,
			_noteFractionsPerBeat,
			_notesLengthWeights,
			self.pitchBaseSemitones,
			self.pitchRangeSemitones,
			self.pitchProgressModifierFormula,
			self.pitchDistributionModifierFormula
		)
		return newNS
	end

	rngContainer.ResetIndex()
	CalculateNoteTiming()
	rngContainer.CheckpointCreate(1)
	self.RecalculatePitch()

	return self
end
