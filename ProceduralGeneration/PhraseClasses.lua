if PhraseClasses then
	return
end
PhraseClasses = {}

function Phrase(_lengthInBeats, randomValuesCache, _kickFile, _snareFile, _ornamentFile)
	local self = {
		lengthInBeats = _lengthInBeats,
		kickFile = _kickFile,
		snareFile = _snareFile,
		ornamentFile = _ornamentFile
	}

	local kickTrack
	local sideKickTrack
	local snareTrack
	local bassTrack

	local function InsertEnvelopePoints(offset)
		local pointsPerBeat = AutomationPointsPerBeat
		local increment = 1 / pointsPerBeat
		for i = 0, self.lengthInBeats, increment do
			ReaperUtils.InsertEnvelopePointSimple(
				BassEnvelopeIntensity,
				i,
				offset,
				MathUtils.SawUp01(i, self.lengthInBeats, 0.5)
			)
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre1, i, offset, MathUtils.Sin01(i, self.lengthInBeats / 2, 1))
			ReaperUtils.InsertEnvelopePointSimple(
				BassEnvelopeTimbre2,
				i,
				offset,
				MathUtils.Triangle01(i, self.lengthInBeats / 2, 1)
			)
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeWidth, i, offset, 0.3)
		end
	end

	function self.SetTracks(_kickTrack, _sideKickTrack, _snareTrack, _bassTrack)
		kickTrack = _kickTrack
		sideKickTrack = _sideKickTrack
		snareTrack = _snareTrack
		bassTrack = _bassTrack
	end

	function self.Insert(_startPosition)
		local offset = _startPosition
		local lengthTime = ReaperUtils.BeatsToTime(self.lengthInBeats)
		local endPosition = _startPosition + lengthTime

		local bassMaxNotesPerBeat = 8
		local bassItemCount = 4
		local bassItemLength = self.lengthInBeats / bassItemCount
		local bassNotesPitchBase = 32
		local bassNotesPitchRange = 16
		local bassNotesTimeWeightTable = {0, 0, 0, 1, 0, 8}

		local bassProgressFormula =
			Formula(
			function(x)
				return x ^ 3
			end
		)

		local bassPitchFormula =
			Formula(
			function(x)
				return x ^ 0.25
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
		bassNoteSequence.Recalculate(randomValuesCache)

		for i = 0, self.lengthInBeats - 1, 1 do
			ReaperUtils.InsertAudioItemPercussive(self.kickFile, kickTrack, ReaperUtils.BeatsToTime(i) + offset, 0.25, 0.225)
			ReaperUtils.InsertAudioItemPercussive(self.kickFile, sideKickTrack, ReaperUtils.BeatsToTime(i) + offset, 0.25, 0.225)

			if i % 2 == 1 then
				ReaperUtils.InsertAudioItemPercussive(self.snareFile, snareTrack, ReaperUtils.BeatsToTime(i) + offset, 0.4, 0.225)
			end

			if i % bassItemLength == 0 then
				local itemStartTime = ReaperUtils.BeatsToTime(i) + offset
				local itemLength = ReaperUtils.BeatsToTime(bassItemLength)
				local noteStartTimes, noteLengths =
					bassNoteSequence.GetNoteStartTimeAndLengthTablesProjectTime(itemStartTime, itemLength)
				local notePitches = bassNoteSequence.GetNotePitchTable()
				ReaperUtils.InsertMIDIItem(bassTrack, itemStartTime, itemLength, notePitches, noteStartTimes, noteLengths)
			end
		end

		InsertEnvelopePoints(offset)

		return endPosition
	end

	return self
end

function Formula(formulaFunction, periodLength, steepness)
	local self = {
		formulaFunction = formulaFunction,
		periodLength = periodLength or 1,
		steepness = steepness or 1
	}

	function self.GetValue(time01)
		return self.formulaFunction(time01, periodLength, steepness)
	end

	--0 is self, 1 is target, 0.5 is midpoint
	function self.GetInterpolatedValue(phase01, targetFormula, interpolationValue01)
		local selfValue = self.GetValue(phase01)
		local targetValue = targetFormula.GetValue(phase01)
		return selfValue + (targetValue - selfValue) * interpolationValue01
	end

	return self
end

return PhraseClasses
