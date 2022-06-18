function Phrase(
	_rngContainer,
	_bassNoteSequence,
	_lengthInBeats,
	_endingNormalizedPosition,
	_verticalDataMain,
	_verticalDataEnding)
	local self = {
		rngContainer = _rngContainer,
		bassNoteSequence = _bassNoteSequence,
		lengthInBeats = _lengthInBeats,
		endingNormalizedPosition = _endingNormalizedPosition,
		verticalDataMain = _verticalDataMain,
		verticalDataEnding = _verticalDataEnding
	}

	local kickTrack
	local sideKickTrack
	local snareTrack
	local bassTrack
	local insertionRules

	local phraseTimbreValue = self.rngContainer.GetNext()

	local function GetCurrentVerticalData(normalizedPosition)
		local verticalData = self.verticalDataMain
		if (normalizedPosition > self.endingNormalizedPosition) then
			verticalData = self.verticalDataEnding
		end
		return verticalData
	end

	local function InsertKicks(time)
		ReaperUtils.InsertAudioItemPercussive(self.kickFile, kickTrack, time, 0.25, 0.225)
	end

	local function InsertSnares(time)
		ReaperUtils.InsertAudioItemPercussive(self.snareFile, snareTrack, time, 0.4, 0.225)
	end

	local function InsertBassSidechain(time)
		ReaperUtils.InsertAudioItemPercussive(self.kickFile, sideKickTrack, time, 0.25, 0.225)
	end

	local function InsertBassItems(time)
		local bassLength = self.bassNoteSequence.GetLength()
		local itemStartTime = time
		local itemLength = ReaperUtils.BeatsToTime(bassLength)
		local noteStartTimes, noteLengths =
			self.bassNoteSequence.GetNoteStartTimeAndLengthTablesProjectTime(itemStartTime, itemLength)
		local notePitches = self.bassNoteSequence.GetNotePitchTable()
		ReaperUtils.InsertMIDIItem(bassTrack, itemStartTime, itemLength, notePitches, noteStartTimes, noteLengths)
	end

	local function AddInsertionRule(insertFunction, insertRule)
		insertionRules[#insertionRules + 1] = {insertFunction, insertRule}
	end

	local function DefineInsertionRules()
		insertionRules = {}
		AddInsertionRule(
			InsertKicks,
			function(beat, verticalData)
				return verticalData.kick == true
			end
		)
		AddInsertionRule(
			InsertBassSidechain,
			function(beat, verticalData)
				return verticalData.sidechain == true
			end
		)
		AddInsertionRule(
			InsertSnares,
			function(beat, verticalData)
				return verticalData.snare == true and beat % 2 == 1
			end
		)
		AddInsertionRule(
			InsertBassItems,
			function(beat, verticalData)
				return verticalData.bass == true and beat % self.bassNoteSequence.GetLength() == 0
			end
		)
	end

	local function InsertItemsWithRules(timeOffset)
		for currentBeat = 0, self.lengthInBeats - 1, 1 do
			local beatsTimeOffset = ReaperUtils.BeatsToTime(currentBeat) + timeOffset
			local verticalData = GetCurrentVerticalData(currentBeat / (self.lengthInBeats - 1))
			for _, rule in ipairs(insertionRules) do
				if rule[2](currentBeat, verticalData) then
					rule[1](beatsTimeOffset)
				end
			end
		end
	end

	local function InsertAutomation(timeOffset)
		local intensityFormula = NormalizedFunctionsUtils.GetRandomIncreasing(self.rngContainer)
		local timbre1Formula = NormalizedFunctionsUtils.GetRandomPeriodic(self.rngContainer)
		local timbre2Formula =
			Formula(
			function()
				return phraseTimbreValue
			end
		)
		local widthFormula = Formula()

		local pointsPerBeat = AutomationPointsPerBeat
		local tickLength = 1 / pointsPerBeat
		for currentTick = 0, self.lengthInBeats, tickLength do
			local pointTimeOffset = ReaperUtils.BeatsToTime(currentTick) + timeOffset
			local progress = currentTick / self.lengthInBeats
			local verticalData = GetCurrentVerticalData(currentTick / (self.lengthInBeats - 1))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeIntensity, pointTimeOffset, intensityFormula.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre1, pointTimeOffset, timbre1Formula.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre2, pointTimeOffset, timbre2Formula.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeWidth, pointTimeOffset, widthFormula.GetValue(verticalData.width))
		end
	end

	function self.SetTracks(_kickTrack, _sideKickTrack, _snareTrack, _bassTrack)
		kickTrack = _kickTrack
		sideKickTrack = _sideKickTrack
		snareTrack = _snareTrack
		bassTrack = _bassTrack
	end

	function self.SetFiles(_kickFile, _snareFile, _ornamentFile)
		self.kickFile = _kickFile
		self.snareFile = _snareFile
		self.ornamentFile = _ornamentFile
	end

	function self.Insert(_startPosition)
		local lengthTime = ReaperUtils.BeatsToTime(self.lengthInBeats)
		local endPosition = _startPosition + lengthTime
		InsertItemsWithRules(_startPosition)
		InsertAutomation(_startPosition)
		return endPosition
	end

	DefineInsertionRules()

	return self
end

function PhraseVerticalData(_kick, _snare, _sidechain, _bass, _width, _intensityMin, _intensityMax)
	local self = {
		kick = _kick,
		snare = _snare,
		sidechain = _sidechain,
		bass = _bass,
		width = _width,
		intensityMin = _intensityMin,
		intensityMax = _intensityMax
	}

	return self
end
