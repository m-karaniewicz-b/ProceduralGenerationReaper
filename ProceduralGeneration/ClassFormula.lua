function Formula(formulaFunction, steepness, frequency)
	local self = {
		formulaFunction = formulaFunction,
		steepness = steepness or 1,
		frequency = frequency or 1
	}

	function self.GetValue(time01)
		if (self.formulaFunction == nil) then
			return 0
		end
		return self.formulaFunction(time01, 1 / self.frequency, self.steepness)
	end

	function self.CheckRandom(time01, rngContainer)
		return self.GetValue(time01) > rngContainer.GetNext()
	end

	--0 is self, 1 is target, 0.5 is midpoint
	function self.GetInterpolatedValue(phase01, targetFormula, interpolationValue01)
		local selfValue = self.GetValue(phase01)
		local targetValue = targetFormula.GetValue(phase01)
		return selfValue + (targetValue - selfValue) * interpolationValue01
	end

	return self
end
