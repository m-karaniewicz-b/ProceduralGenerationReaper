if NormalizedFunctionsUtils then
	return
end
NormalizedFunctionsUtils = {}

local randomPeriodic = {
	MathUtils.Sin01,
	MathUtils.Triangle01,
	MathUtils.SawUp01,
	MathUtils.SawDown01
}

local function GetRandomSteepness(rngContainer, maxSteepnessPositive, maxSteepnessNegative, chanceForPositive01)
	maxSteepnessNegative = maxSteepnessNegative or maxSteepnessPositive
	chanceForPositive01 = chanceForPositive01 or 0.5
	if (rngContainer.GetNext() < chanceForPositive01) then
		return 1 + rngContainer.GetNext() * (maxSteepnessPositive - 1)
	else
		return 1 / (1 + (rngContainer.GetNext() * (maxSteepnessNegative - 1)))
	end
end

function NormalizedFunctionsUtils.GetRandomIncreasing(rngContainer)
	return Formula(MathUtils.SawUp01, GetRandomSteepness(rngContainer, 1, 4, 0))
end

function NormalizedFunctionsUtils.GetRandomDecreasing(rngContainer)
	return Formula(MathUtils.SawDown01, GetRandomSteepness(rngContainer, 2))
end

function NormalizedFunctionsUtils.GetRandomPeriodic(rngContainer)
	return Formula(
		randomPeriodic[rngContainer.RandomRangeInt(1, #randomPeriodic)],
		GetRandomSteepness(rngContainer, 2),
		rngContainer.RandomRangeInt(1, 4)
	)
end

return NormalizedFunctionsUtils
