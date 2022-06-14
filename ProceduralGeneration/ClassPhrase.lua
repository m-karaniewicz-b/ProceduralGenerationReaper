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
		local formulaMacro1 = NormalizedFunctionsUtils.GetRandomIncreasing()
		local formulaMacro2 = NormalizedFunctionsUtils.GetRandomPeriodic()
		local formulaMacro3 = NormalizedFunctionsUtils.GetRandomPeriodic()
		local formulaMacro4 = NormalizedFunctionsUtils.GetRandomPeriodic()
		local pointsPerBeat = AutomationPointsPerBeat
		local increment = 1 / pointsPerBeat
		for i = 0, self.lengthInBeats, increment do
			local progress = i / self.lengthInBeats
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeIntensity, i, offset, formulaMacro1.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre1, i, offset, formulaMacro2.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre2, i, offset, formulaMacro3.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeWidth, i, offset, formulaMacro4.GetValue(progress))
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

		local bassItemCount = 4
		local bassItemLength = self.lengthInBeats / bassItemCount
		local bassMaxNotesPerBeat = 8
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
				return x
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
