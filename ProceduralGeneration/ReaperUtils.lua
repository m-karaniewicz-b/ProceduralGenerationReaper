if ReaperUtils then
	return
end
ReaperUtils = {}

dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")

function ReaperUtils.InsertMIDIItemFromPitchValuesSimple(pitchValues, track, timePosition, length)
	local item = reaper.CreateNewMIDIItemInProj(track, timePosition, timePosition + length)
	local take = reaper.GetActiveTake(item)

	local itemPosPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timePosition)
	local itemLengthPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timePosition + length) - itemPosPPQ

	local noteCount = #pitchValues

	local noteLengthPPQ = itemLengthPPQ / noteCount

	for i = 0, noteCount, 1 do
		reaper.MIDI_InsertNote(take, false, false, noteLengthPPQ * i, noteLengthPPQ * (i + 1), 0, pitchValues[i], 90, false)
	end

	reaper.MIDI_Sort(take)
end

function ReaperUtils.InsertMIDIItem(
	track,
	itemStartTime,
	itemLength,
	notePitchTable,
	noteStartTimeTable,
	noteLengthTable)
	local item = reaper.CreateNewMIDIItemInProj(track, itemStartTime, itemStartTime + itemLength)
	local take = reaper.GetActiveTake(item)

	local noteCount = #notePitchTable
	for i = 0, noteCount, 1 do
		ReaperUtils.InsertNoteSimpleProjectTime(take, noteStartTimeTable[i], noteLengthTable[i], notePitchTable[i], 90)
	end

	reaper.MIDI_Sort(take)
end

function ReaperUtils.InsertNoteSimpleProjectTime(take, startTimeProjectTime, lengthProjectTime, pitch, velocity)
	ReaperUtils.InsertNote(
		take,
		reaper.MIDI_GetPPQPosFromProjTime(take, startTimeProjectTime),
		reaper.MIDI_GetPPQPosFromProjTime(take, startTimeProjectTime + lengthProjectTime),
		pitch,
		velocity
	)
end

function ReaperUtils.InsertNote(take, startTimePPQ, endPPQ, pitch, velocity)
	reaper.MIDI_InsertNote(take, false, false, startTimePPQ, endPPQ, 0, pitch, velocity, false)
end

function ReaperUtils.InsertAudioItem(filename, track, position)
	if (filename == nil) then
		reaper.ShowConsoleMsg("Missing file.\n")
		return nil
	end

	local item = reaper.AddMediaItemToTrack(track)
	local take = reaper.AddTakeToMediaItem(item)
	--reaper.GetMediaItemTake(item, 0)

	reaper.SetMediaItemPosition(item, position, false)

	--Set source from file
	local ok = reaper.BR_SetTakeSourceFromFile(take, filename, false)
	if (ok == false) then
		reaper.ShowConsoleMsg("Setting source from file failed. (" .. filename .. ")\n")
	end

	--Set item length to source length
	local length = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
	reaper.SetMediaItemLength(item, length, false)

	return item
end

function ReaperUtils.InsertAudioItemPercussive(filename, track, position, length, fadeOutLength)
	local item = ReaperUtils.InsertAudioItem(filename, track, position)
	if (item == nil) then
		reaper.ShowConsoleMsg("Invalid item.\n")
		return nil
	end
	reaper.SetMediaItemLength(item, length, false)
	reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeOutLength)
	reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", 0)
	reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", 1)
	reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
end

function ReaperUtils.RenderProjectToPath(renderPath)
	local render_cfg_string = ultraschall.CreateRenderCFG_WAV(1, 0, 0, 0, true)

	local retval, render_files_count, rendered_files_MediaItemStateChunk, rendered_files_array =
		ultraschall.RenderProject(nil, renderPath, 0, -1, false, true, true, render_cfg_string, nil)
end

function ReaperUtils.ReaperClearProjectItems()
	--Deselect all tracks
	reaper.Main_OnCommand(40297, 0)

	reaper.SelectAllMediaItems(0, true)

	--Delete selected media items
	reaper.Main_OnCommand(40697, 0)
end

function ReaperUtils.ReaperUpdateView()
	--Build any missing peaks
	reaper.Main_OnCommand(40047, 0)
	reaper.UpdateArrange()
end

function ReaperUtils.RandomizeBPM(lower, upper)
	local bpm = math.random(lower, upper)
	reaper.SetCurrentBPM(0, bpm, 1)
	return bpm
end

function ReaperUtils.GetTrackFXParameterNames(track, fxIndex)
	track = track or 0
	fxIndex = fxIndex or 0

	local paramFound = true
	local paramNames = {}
	local currentName
	local i = 0
	while paramFound do
		paramFound, currentName = reaper.TrackFX_GetParamName(track, fxIndex, i)

		if (paramFound == false) then
			break
		end

		table.insert(paramNames, currentName)
		i = i + 1
	end

	return paramNames
end

function ReaperUtils.GetParameterEnvelopesFromTrackFXByNames(track, parameterNames, fxIndex)
	fxIndex = fxIndex or 0
	local allFXParameterNames = ReaperUtils.GetTrackFXParameterNames(track, fxIndex)

	local envelopes = {}

	--TODO: optimize string search by checking all parameterNames simultaneously
	local paramIndex
	for index, value in ipairs(parameterNames) do
		paramIndex = UMath.GetFirstIndexMatchingString(allFXParameterNames, value)
		envelopes[index] = reaper.GetFXEnvelope(track, fxIndex, paramIndex, true)
	end

	return envelopes
end

function ReaperUtils.InsertEnvelopePointSimple(envelope, beatOffset, timeOffset, value)
	reaper.InsertEnvelopePoint(envelope, reaper.TimeMap2_beatsToTime(0, beatOffset) + timeOffset, value, 0, 1, false, true)
end

function ReaperUtils.BeatsToTime(beats)
	return reaper.TimeMap2_beatsToTime(0, beats)
end

function ReaperUtils.BeginProjectModification()
	reaper.PreventUIRefresh(777)
	reaper.Undo_BeginBlock()
end

function ReaperUtils.EndProjectModification(undoName)
	ReaperUtils.ReaperUpdateView()
	reaper.PreventUIRefresh(-777)
	reaper.Undo_EndBlock(undoName, 0)
end

function ReaperUtils.SaveProjectAndCopyToPath(path)
	reaper.Main_SaveProject(0, false)

	local _, projFile = reaper.EnumProjects(-1, "")

	local ok, _
	UFile.CopyFileToPath(projFile, path)

	if ok == false then
		ULog.Print("Copying failed: " .. path)
	end
end

return ReaperUtils
