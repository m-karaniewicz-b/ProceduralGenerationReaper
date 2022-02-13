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
	return array[math.random(0, #array)]
end

function MathUtils.GetFirstIndexMatchingString(stringTable, stringMatch)
	for index, string in ipairs(stringTable) do
		if (string == stringMatch) then
			return index - 1
		end
	end
	return nil
end

return MathUtils
