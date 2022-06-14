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

local function GetRandomSteepness(maxSteepness)
	if (math.random() < 0.5) then
		return 1 + math.random() * maxSteepness
	else
		return 1 - math.random() / maxSteepness
	end
end

function NormalizedFunctionsUtils.GetRandomIncreasing()
	return Formula(MathUtils.SawUp01, GetRandomSteepness(2))
end

function NormalizedFunctionsUtils.GetRandomDecreasing()
	return Formula(MathUtils.SawDown01, GetRandomSteepness(2))
end

function NormalizedFunctionsUtils.GetRandomPeriodic()
	return Formula(randomPeriodic[math.random(1, #randomPeriodic)], GetRandomSteepness(2), math.random(1, 4))
end

return NormalizedFunctionsUtils
