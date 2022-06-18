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
