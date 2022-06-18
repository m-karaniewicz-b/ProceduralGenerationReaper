if MathUtils then
	return
end
MathUtils = {}

function MathUtils.Round(x)
	return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

function MathUtils.Sign(n)
	return n > 0 and 1 or n < 0 and -1 or 0
end

function MathUtils.Remap(value, outMin, outMax, inMin, inMax)
	inMin = inMin or 0
	inMax = inMax or 1
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function MathUtils.Clamp(value, min, max)
	return value < min and min or value > max and max or value
end

function MathUtils.Step(value, step)
	return value < step and 0 or 1
end

function MathUtils.StepValue(value, step)
	return value < step and 0 or value - step
end

function MathUtils.Sin01(phase, periodLength, steepness)
	steepness = steepness or 1
	periodLength = periodLength or 1
	local sin = MathUtils.Steepness(math.sin(phase * math.pi / periodLength * 2), steepness)
	return MathUtils.Remap(sin, 0, 1, -1, 1)
end

function MathUtils.Triangle01(phase, periodLength, steepness)
	steepness = steepness or 1
	periodLength = periodLength or 1
	local triangle = math.abs((phase + 1) % periodLength - periodLength * 0.5) / periodLength * 2
	return MathUtils.Steepness(triangle, steepness)
end

function MathUtils.SawUp01(phase, periodLength, steepness)
	steepness = steepness or 1
	periodLength = periodLength or 1
	return MathUtils.Steepness(phase % periodLength / periodLength, steepness)
end

function MathUtils.SawDown01(phase, periodLength, steepness)
	steepness = steepness or 1
	periodLength = periodLength or 1
	return 1 - MathUtils.Steepness(phase % periodLength / periodLength, 1 / steepness)
end

function MathUtils.Steepness(value, steepness)
	return math.abs(value) ^ (1 / steepness) * MathUtils.Sign(value)
end

function MathUtils.GenerateRandomValuesArray(size)
	local ret = {n = 10}
	for i = 0, size, 1 do
		ret[i] = math.random()
	end
	return ret
end

function MathUtils.GetRandomArrayValue(array)
	if (array == nil) then
		return nil
	end
	return array[math.random(1, #array)]
end

function MathUtils.GetFirstIndexMatchingString(stringTable, stringMatch)
	for index, string in ipairs(stringTable) do
		if (string == stringMatch) then
			return index - 1
		end
	end
	return nil
end

function MathUtils.Random01()
	return math.random()
end

function MathUtils.GetNumericTableSum(numericTable)
	local sum = 0
	for index, value in ipairs(numericTable) do
		sum = sum + value
	end
	return sum
end

function MathUtils.GetWeightedIndex(weightsTable, valueSmallerThanSum)
	local counter = 0
	for index, value in ipairs(weightsTable) do
		counter = counter + value
		if valueSmallerThanSum < counter then
			return index
		end
	end
end

return MathUtils
