if NoteClasses then
	return
end
NoteClasses = {}

function NoteSequence(
	pitchProgressModifierFormula,
	pitchDistributionModifierFormula,
	basePitch,
	semitoneRange,
	lengthInBeats,
	noteFractionsPerBeat,
	notesLengthWeights)
	local self = {
		pitchProgressModifierFormula = pitchProgressModifierFormula,
		pitchDistributionModifierFormula = pitchDistributionModifierFormula,
		basePitch = basePitch,
		semitoneRange = semitoneRange,
		lengthInBeats = lengthInBeats
	}

	notesLengthWeights = notesLengthWeights or {0, 1, 1, 1, 0}

	local maximumNoteFractionCount = lengthInBeats * noteFractionsPerBeat

	local noteDataTable = {}
	local notePitchTable = {}
	local noteStartTimeTable = {}
	local noteLengthTable = {}

	local randomValueIndex = 0
	local randomValueCache = {}

	local function GetNextRandomValue()
		local value = randomValueCache[randomValueIndex]
		randomValueIndex = randomValueIndex + 1
		return value
	end

	local function RecalculateNoteTiming()
		noteDataTable = {}
		local noteLengthWeightsSum = MathUtils.GetNumericTableSum(notesLengthWeights)

		local noteCounter = 0
		local noteFractionCounter = 0
		while noteFractionCounter < maximumNoteFractionCount do
			local currentNoteLength = MathUtils.GetWeightedIndex(notesLengthWeights, GetNextRandomValue() * noteLengthWeightsSum)

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

	local function RecalculateNotePitches()
		local noteCount = #noteDataTable
		for i = 0, noteCount, 1 do
			local currentTime = noteDataTable[i].startTimeInFractions / maximumNoteFractionCount
			local progressModifier = self.pitchProgressModifierFormula.GetValue(currentTime)
			local randomValue = (GetNextRandomValue() * 2) - 1
			local randomValueModifiedDistribution = self.pitchDistributionModifierFormula.GetValue(math.abs(randomValue))
			local finalValue = randomValueModifiedDistribution * progressModifier * MathUtils.Sign(randomValue)
			noteDataTable[i].SetPitch(MathUtils.Round(self.basePitch + finalValue * self.semitoneRange))
		end
	end

	function self.SetRandomValuesCache(cache)
		randomValueIndex = 1
		randomValueCache = cache
	end

	function self.Recalculate(newRandomValueCache)
		newRandomValueCache = newRandomValueCache or randomValueCache
		self.SetRandomValuesCache(newRandomValueCache)

		if (randomValueCache == nil) then
			self.SetRandomValuesCache(MathUtils.GenerateRandomValuesArray(1000))
			LogUtils.Print("Recalculating note sequence without setting random values cache")
		end

		RecalculateNoteTiming()
		RecalculateNotePitches()

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

	return self
end

function NoteData()
	local self = {}

	function self.SetTiming(startTimeInNoteFractions, lengthInNoteFractions)
		self.startTimeInFractions = startTimeInNoteFractions
		self.lengthInFractions = lengthInNoteFractions
	end

	function self.SetPitch(pitch)
		self.pitch = pitch
	end

	return self
end

return NoteClasses
