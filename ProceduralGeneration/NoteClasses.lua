if NoteClasses then
	return
end
NoteClasses = {}

function NoteSequence(progressFormula, pitchFormula, basePitch, semitoneRange, lengthInBeats, noteFractionsPerBeat)
	local self = {
		progressFormula = progressFormula,
		pitchFormula = pitchFormula,
		basePitch = basePitch,
		semitoneRange = semitoneRange,
		lengthInBeats = lengthInBeats
	}

	local notesLengthWeights = {0, 1, 1, 1, 1}

	local maximumNoteFractionCount = lengthInBeats * noteFractionsPerBeat

	local noteDataTable = {}
	local notePitchTable = {}
	local noteStartTimeTable = {}
	local noteLengthTable = {}

	local function RecalculateNoteTiming()
		noteDataTable = {}
		local noteLengthWeightsSum = UMath.GetNumericTableSum(notesLengthWeights)

		local noteCounter = 0
		local noteFractionCounter = 0
		while noteFractionCounter < maximumNoteFractionCount do
			local currentNoteLength = UMath.GetWeightedIndex(notesLengthWeights, math.random() * noteLengthWeightsSum)

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
			local currentProgress = self.progressFormula.GetValue(currentTime)
			--(1 - self.progressMult) + (timeProgress ^ self.progressCurve) * self.progressMult

			--local remapWeight = (weights[i] * 2) - 1

			--local pitchDelta = self.pitchFormula.GetValue()
			--currentProgress * UMath.Sign(remapWeight) * math.abs(remapWeight) ^ self.weightsCurve

			noteDataTable[i].SetPitch(UMath.Round(self.basePitch + currentProgress * self.semitoneRange))
		end
	end

	function self.Recalculate()
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
