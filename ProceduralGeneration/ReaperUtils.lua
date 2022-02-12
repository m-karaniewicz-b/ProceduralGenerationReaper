if ReaperUtils then
	return
end
ReaperUtils = {}

dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")

function ReaperUtils.InsertMIDIItemFromPitchValues(pitchValues, track, position, length)
	local item = reaper.CreateNewMIDIItemInProj(track, position, position + length)
	local take = reaper.GetActiveTake(item)

	local itemPosPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, position)
	local itemLengthPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, position + length) - itemPosPPQ

	local noteCount = #pitchValues

	local noteLengthPPQ = itemLengthPPQ / noteCount

	for i = 0, noteCount, 1 do
		reaper.MIDI_InsertNote(take, false, false, noteLengthPPQ * i, noteLengthPPQ * (i + 1), 0, pitchValues[i], 90, false)
	end

	reaper.MIDI_Sort(take)
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
