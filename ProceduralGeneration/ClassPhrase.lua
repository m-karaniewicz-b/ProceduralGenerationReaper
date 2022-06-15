function Phrase(_lengthInBeats, _rngContainer, _bassNoteSequence, _kickFile, _snareFile, _ornamentFile)
	local self = {
		lengthInBeats = _lengthInBeats,
		kickFile = _kickFile,
		snareFile = _snareFile,
		ornamentFile = _ornamentFile,
		bassNoteSequence = _bassNoteSequence,
		rngContainer = _rngContainer
	}

	local kickTrack
	local sideKickTrack
	local snareTrack
	local bassTrack

	local function InsertEnvelopePoints(offset)
		local intensityFormula = NormalizedFunctionsUtils.GetRandomIncreasing(self.rngContainer)
		local timbre1Formula = NormalizedFunctionsUtils.GetRandomPeriodic(self.rngContainer)
		local timbre2Value = self.rngContainer.GetNext()
		local widthFormula = NormalizedFunctionsUtils.GetRandomPeriodic(self.rngContainer)
		local pointsPerBeat = AutomationPointsPerBeat
		local increment = 1 / pointsPerBeat
		for i = 0, self.lengthInBeats, increment do
			local progress = i / self.lengthInBeats
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeIntensity, i, offset, intensityFormula.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre1, i, offset, timbre1Formula.GetValue(progress))
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeTimbre2, i, offset, timbre2Value)
			ReaperUtils.InsertEnvelopePointSimple(BassEnvelopeWidth, i, offset, widthFormula.GetValue(progress))
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

		local bassLength = self.bassNoteSequence.GetLength()

		for i = 0, self.lengthInBeats - 1, 1 do
			ReaperUtils.InsertAudioItemPercussive(self.kickFile, kickTrack, ReaperUtils.BeatsToTime(i) + offset, 0.25, 0.225)
			ReaperUtils.InsertAudioItemPercussive(self.kickFile, sideKickTrack, ReaperUtils.BeatsToTime(i) + offset, 0.25, 0.225)

			if i % 2 == 1 then
				ReaperUtils.InsertAudioItemPercussive(self.snareFile, snareTrack, ReaperUtils.BeatsToTime(i) + offset, 0.4, 0.225)
			end

			if i % bassLength == 0 then
				local itemStartTime = ReaperUtils.BeatsToTime(i) + offset
				local itemLength = ReaperUtils.BeatsToTime(bassLength)
				local noteStartTimes, noteLengths =
					self.bassNoteSequence.GetNoteStartTimeAndLengthTablesProjectTime(itemStartTime, itemLength)
				local notePitches = self.bassNoteSequence.GetNotePitchTable()
				ReaperUtils.InsertMIDIItem(bassTrack, itemStartTime, itemLength, notePitches, noteStartTimes, noteLengths)
			end
		end

		InsertEnvelopePoints(offset)

		return endPosition
	end

	return self
end
