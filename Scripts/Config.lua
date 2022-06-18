if Config then
	return
end
Config = {}

function Config.DefineGlobalsPaths()
	PathDirMainRenders = "W:\\Samples\\Procedural\\Generated"
	PathDirSubgenerationRenders = "W:\\Samples\\Procedural\\SubGenerations"
	PathDirGeneratedProjectFiles = "W:\\Samples\\Procedural\\Generated\\ProjectFiles"

	PathDirBankVitalVST3Bass = "C:\\Repositories\\ProceduralGenerationReaper\\VitalVST3Presets\\Bass"
	PathDirBankKick = "W:\\Samples\\Procedural\\Banks\\Kicks"
	PathDirBankSnare = "W:\\Samples\\Procedural\\Banks\\Snares"
	PathDirBankOrnamentSource = "W:\\Samples\\Procedural\\Banks\\Random"

	PathDirLogs = "W:\\Samples\\Procedural\\Logs"
	PathFileProjectTemplate = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"
end

function Config.DefineGlobalsTracks()
	ParentTrack = reaper.GetTrack(0, 0)
	TrackKick = reaper.GetTrack(0, 1)
	TrackSideKick = reaper.GetTrack(0, 2)
	TrackSnare = reaper.GetTrack(0, 3)
	ReverbSendTrack = reaper.GetTrack(0, 4)
	TrackBass = reaper.GetTrack(0, 5)
end

function Config.GetSynthbassParamNames()
	--Macro 1 => Intensity
	--Macro 2 => Timbre 1
	--Macro 3 => Timbre 2
	--Macro 4 => Width
	return {"Macro 1", "Macro 2", "Macro 3", "Macro 4"}
end

function Config.GetGenerationOptions()
	local compositionCount = 1
	local saveProjectToFile = false
	local renderProjectToFile = false
	return compositionCount, saveProjectToFile, renderProjectToFile
end

return Config
