local function RequireFiles()
	MathUtils = require("MathUtils")
	ReaperUtils = require("ReaperUtils")
	FileUtils = require("FileUtils")
	LogUtils = require("LogUtils")
	NormalizedFunctionsUtils = require("NormalizedFunctionsUtils")
	require("ClassPhrase")
	require("ClassFormula")
	require("ClassNoteSequence")
	require("ClassNoteData")
	require("ClassRngContainer")
	require("Composition")
	require("Generation")
	require("Config")
end

local function DefineGlobalsSeparator()
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		Separator = "\\"
	else
		Separator = "/"
	end
end

local function DefineGlobalsEnvelopes(synthbassParamNames)
	BassEnvelopesTable =
		ReaperUtils.GetParameterEnvelopesFromTrackFXByNames(
		TrackBass,
		synthbassParamNames,
		reaper.TrackFX_GetInstrument(TrackBass)
	)

	BassEnvelopeIntensity = BassEnvelopesTable[1]
	BassEnvelopeTimbre1 = BassEnvelopesTable[2]
	BassEnvelopeTimbre2 = BassEnvelopesTable[3]
	BassEnvelopeWidth = BassEnvelopesTable[4]
end

local function Init()
	RequireFiles()
	DefineGlobalsSeparator()
	Config.DefineGlobalsPaths()
	Config.DefineGlobalsTracks()
	DefineGlobalsEnvelopes(Config.GetSynthbassParamNames())

	local compCount, saveToFile, renderToFile = Config.GetGenerationOptions()
	StartGeneration(compCount, saveToFile, renderToFile)
end

Init()
