if PhraseClasses then
	return
end
PhraseClasses = {}

function Phrase(_lengthInBeats, _kickFile, _snareFile, _ornamentFile)
	local self = {
		lengthInBeats = _lengthInBeats,
		kickFile = _kickFile,
		snareFile = _snareFile,
		ornamentFile = _ornamentFile
	}

	local function InsertAutomationPoints(offset)
		--Insert envelope points
		local pointsPerBeat = AutomationPointsPerBeat
		local increment = 1 / pointsPerBeat
		for i = 0, self.lengthInBeats, increment do
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeIntensity, i, offset, UMath.SawUp01(i, self.lengthInBeats, 0.5))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre1, i, offset, UMath.Sin01(i, self.lengthInBeats / 2, 1))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre2, i, offset, UMath.Triangle01(i, self.lengthInBeats / 2, 1))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeWidth, i, offset, 0.3)
		end
	end

	function self.Insert(_startPosition, _weights, _kickTrack, _sideKickTrack, _snareTrack, _bassTrack)
		local offset = _startPosition
		local lengthTime = ReaperUtils.BeatsToTime(self.lengthInBeats)
		local endPosition = _startPosition + lengthTime

		local maxNotesPerBeat = 4
		local bassItemCount = 4
		local bassItemLength = self.lengthInBeats / bassItemCount

		local bassProgressFormula =
			Formula(
			function(x)
				return 0
			end
		)

		local bassPitchFormula =
			Formula(
			function(x)
				return x
			end
		)

		local bassNoteSequence = NoteSequence(bassProgressFormula, bassPitchFormula, 32, 16, bassItemLength, maxNotesPerBeat)
		bassNoteSequence.Recalculate()

		for i = 0, self.lengthInBeats - 1, 1 do
			ReaperUtils.InsertAudioItemPercussive(self.kickFile, _kickTrack, ReaperUtils.BeatsToTime(i) + offset, 0.25, 0.225)
			ReaperUtils.InsertAudioItemPercussive(
				self.kickFile,
				_sideKickTrack,
				ReaperUtils.BeatsToTime(i) + offset,
				0.25,
				0.225
			)

			if i % 2 == 1 then
				ReaperUtils.InsertAudioItemPercussive(self.snareFile, _snareTrack, ReaperUtils.BeatsToTime(i) + offset, 0.4, 0.225)
			end

			if i % bassItemLength == 0 then
				local itemStartTime = ReaperUtils.BeatsToTime(i) + offset
				local itemLength = ReaperUtils.BeatsToTime(bassItemLength)
				local noteStartTimes, noteLengths =
					bassNoteSequence.GetNoteStartTimeAndLengthTablesProjectTime(itemStartTime, itemLength)

				ReaperUtils.InsertMIDIItem(
					_bassTrack,
					itemStartTime,
					itemLength,
					bassNoteSequence.GetNotePitchTable(),
					noteStartTimes,
					noteLengths
				)
			end
		end

		InsertAutomationPoints(offset)

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
