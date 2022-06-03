if DataStructures then
	return
end
DataStructures = {}

function Phrase(_lengthInBeats, _kickFile, _snareFile, _ornamentFile, _bassNoteSequenceBlueprint)
	local self = {
		lengthInBeats = _lengthInBeats,
		kickFile = _kickFile,
		snareFile = _snareFile,
		ornamentFile = _ornamentFile,
		bassNoteSequenceBlueprint = _bassNoteSequenceBlueprint
	}

	function self.Insert(_startPosition, _weights, _kickTrack, _sideKickTrack, _snareTrack, _bassTrack)
		local offset = _startPosition
		local lengthTime = ReaperUtils.BeatsToTime(self.lengthInBeats)
		local endPosition = _startPosition + lengthTime

		local bassMelodyNotes = self.bassNoteSequenceBlueprint.GetNotes(_weights)
		local bassItemCount = 4
		local bassItemLength = self.lengthInBeats / bassItemCount

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
				ReaperUtils.InsertMIDIItemFromPitchValues(
					bassMelodyNotes,
					_bassTrack,
					ReaperUtils.BeatsToTime(i) + offset,
					ReaperUtils.BeatsToTime(bassItemLength)
				)
			end
		end

		--Insert envelope points
		local pointsPerBeat = 8
		local increment = 1 / pointsPerBeat
		for i = 0, self.lengthInBeats, increment do
			ReaperUtils.InsertEnvelopePointSimple(SBIntensityEnv, i, offset, UMath.SawUp01(i, self.lengthInBeats, 0.5))
			ReaperUtils.InsertEnvelopePointSimple(SBTimbre1Env, i, offset, UMath.Sin01(i, self.lengthInBeats / 2, 1))
			ReaperUtils.InsertEnvelopePointSimple(SBTimbre2Env, i, offset, UMath.Triangle01(i, self.lengthInBeats / 2, 1))
			ReaperUtils.InsertEnvelopePointSimple(SBWidthEnv, i, offset, 0.3)
		end

		return endPosition
	end

	return self
end

function NoteSequenceBlueprint(basePitch, semitoneRange, progressMult, progressCurve, weightsCurve)
	local self = {
		basePitch = basePitch,
		semitoneRange = semitoneRange,
		progressMult = progressMult,
		progressCurve = progressCurve,
		weightsCurve = weightsCurve
	}

	function self.GetNotes(weights)
		local notes = {}
		local noteCount = #weights
		for i = 0, noteCount, 1 do
			local currProgress = 1 * (1 - self.progressMult) + ((i / noteCount) ^ self.progressCurve) * self.progressMult
			local remapWeight = (weights[i] * 2) - 1
			local pitchDelta = currProgress * UMath.Sign(remapWeight) * math.abs(remapWeight) ^ self.weightsCurve
			pitchDelta = pitchDelta * self.semitoneRange
			notes[i] = UMath.Round(self.basePitch + pitchDelta)
		end

		return notes
	end

	return self
end
