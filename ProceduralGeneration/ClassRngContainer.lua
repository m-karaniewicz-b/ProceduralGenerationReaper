RngContainerMaxValueCountDefault = 1000

function RngContainer(_valueCount)
	local self = {}
	local valuesCache
	local valueIndex
	local indexCheckpoints = {}
	_valueCount = _valueCount or RngContainerMaxValueCountDefault

	function self.ResetIndex()
		valueIndex = 1
	end

	function self.CheckpointCreate(checkpointId)
		indexCheckpoints[checkpointId] = valueIndex
	end

	function self.CheckpointLoad(checkpointId)
		valueIndex = indexCheckpoints[checkpointId]
	end

	function self.SetValues(newValuesCache)
		valuesCache = {}
		for index, value in ipairs(newValuesCache) do
			valuesCache[index] = value
		end
	end

	function self.Populate(valueCount)
		valuesCache = {}
		self.ResetIndex()
		for i = 1, valueCount, 1 do
			valuesCache[i] = math.random()
		end
	end

	function self.GetNext()
		local value = valuesCache[valueIndex]
		valueIndex = valueIndex + 1
		if valueIndex > #valuesCache then
			self.ResetIndex()
			LogUtils.Log("RngContainer | Resetting index [Values count: " .. #valuesCache .. "]")
		end
		return value
	end

	function self.RandomRangeFloat(lowerBound, upperBound)
		return lowerBound + (upperBound - lowerBound) * self.GetNext()
	end

	function self.RandomRangeInt(lowerBound, upperBound)
		return math.floor(self.RandomRangeFloat(lowerBound, upperBound + 1))
	end

	function self.Copy(resetIndexCopy)
		resetIndexCopy = resetIndexCopy or true
		local copy = RngContainer()
		copy.SetValues(valuesCache)
		if resetIndexCopy then
			copy.ResetIndex()
		end
		return copy
	end

	if _valueCount then
		self.Populate(_valueCount)
	end

	return self
end
