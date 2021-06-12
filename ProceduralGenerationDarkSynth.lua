
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
--ultraschall.ApiTest()

-- local libPath = reaper.GetExtState("Scythe v3", "libPath")
-- if not libPath or libPath == "" then
--     reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
--     return
-- end

-- loadfile(libPath .. "scythe.lua")()


function Main()
  reaper.Undo_BeginBlock()

  PerformRender = true
  GenerationCount = 4

  RenderDir = "W:\\Samples\\Procedural\\Generated"

  KickDir = "W:\\Samples\\Procedural\\Banks\\Kicks"
  SnareDir = "W:\\Samples\\Procedural\\Banks\\Snares"

  --Load file template
  --reaper.Main_openProject(templateFileName)
  ParentTrack = reaper.GetTrack(0,0)
  KickTrack = reaper.GetTrack(0,1)
  SideKickTrack = reaper.GetTrack(0,2)
  SnareTrack = reaper.GetTrack(0,3)
  ReverbSendTrack = reaper.GetTrack(0,4)
  SynthbassTrack = reaper.GetTrack(0,5)


  --Build any missing peaks
  reaper.Main_OnCommand(40047,0)
  reaper.UpdateArrange()

  --reaper.ShowConsoleMsg(os.date("Gen-%Y-%m-%d-%H-%M-%S\n"), 0)


  reaper.Undo_EndBlock("Generate", 1)
end

function StartGeneration()

  --Generation
  for i=0,GenerationCount-1,1
  do
    kickFileName = KickDir.."\\"..SelectRandomElementFromArray(GetFilesFromDirectory(KickDir))
    snareFileName = SnareDir.."\\"..SelectRandomElementFromArray(GetFilesFromDirectory(SnareDir))
    --snareFileName = "W:\\Samples\\Procedural\\Banks\\Snares\\pendulum_snare.wav"

    templateFileName = "W:\\Samples\\Procedural\\Banks\\TrackTemplates\\Generation2.RTrackTemplate"
    --local templatePath = reaper.GetResourcePath() .. '/TrackTemplates/' .. templateName

    --Deselect all tracks
    reaper.Main_OnCommand(40297, 0)
    reaper.SelectAllMediaItems(0,true)
    --Delete selected media items
    reaper.Main_OnCommand(40697,0)

    GenerationCurrentPos = 0

    RandomizeBPM(90,120)
    GenerateSegment(8, 4, 8)

    local genName = "gen"..os.date("%Y_%m_%d_%H_%M_%S")
    if(PerformRender) then RenderProjectToPath(RenderDir.."\\"..genName..".wav") end

  end
end

function GenerateSegment(length, division, noteDensity)

  local timeLength = reaper.TimeMap2_beatsToTime(0, length)
  local offset = GenerationCurrentPos

  local segmentRandomNoteValues = GenerateRandomValuesArray(noteDensity)

  local synthbassMel = GenerateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 1, 3, 2);
  --local synthbassMel = GenerateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 24, 1, 2, 5); --jump at end
  --local synthbassMel = GenerateBasicMelodyFromWeights(segmentRandomNoteValues, 32, 12, 0, 1, 0); --octave

  for i = 0,length-1,1
  do
    InsertAudioItemPercussive(kickFileName,KickTrack,reaper.TimeMap2_beatsToTime(0,i) + offset,0.25,0.225)
    InsertAudioItemPercussive(kickFileName,SideKickTrack,reaper.TimeMap2_beatsToTime(0,i) + offset,0.25,0.225)
    if i%2==1 then
      InsertAudioItemPercussive(snareFileName,SnareTrack,reaper.TimeMap2_beatsToTime(0,i) + offset,0.4,0.225)
    end
    if i%(length/division)==0 then
      CreateMIDIItemFromMelody(synthbassMel, SynthbassTrack, reaper.TimeMap2_beatsToTime(0,i) + offset,
      reaper.TimeMap2_beatsToTime(0,(length/division)));
    end
  end

  GenerationCurrentPos = GenerationCurrentPos + timeLength

end


function GenerateBasicMelodyFromWeights(weights, basePitch, semitoneRange, progressMult, progressCurve ,weightsCurve)

  basePitch = basePitch or 36
  semitoneRange = semitoneRange or 18
  progressMult = progressMult or 1
  progressCurve = progressCurve or 3
  weightsCurve = weightsCurve or 1.5

  local ret = {}
  local bias = 0
  local noteCount = #weights
  for i=0, noteCount,1
  do

    local currProgress = 1 * (1-progressMult) + ((i / noteCount) ^ progressCurve) * progressMult

    local remapWeight = (weights[i] * 2) - 1

    local pitchDelta =  currProgress * Sign(remapWeight) * math.abs(remapWeight) ^ weightsCurve
    --reaper.ShowConsoleMsg(pitchDelta.."\n")

    pitchDelta = pitchDelta * semitoneRange

    ret[i] = Round(basePitch + pitchDelta)

  end

  return ret

end



function CreateMIDIItemFromMelody(pitchValues, track, position, length)
  local item = reaper.CreateNewMIDIItemInProj(track, position, position+length)
  local take = reaper.GetActiveTake(item)

  local itemPosPPQ = reaper.MIDI_GetPPQPosFromProjTime(take,position)
  local itemLengthPPQ = reaper.MIDI_GetPPQPosFromProjTime(take,position+length) - itemPosPPQ

  local noteCount = #pitchValues

  local noteLengthPPQ = itemLengthPPQ / noteCount

  for i=0,noteCount,1
  do
    reaper.MIDI_InsertNote(take,false,false,
    noteLengthPPQ * i, noteLengthPPQ * (i+1), 0,
    pitchValues[i] , 90, false)
  end

  reaper.MIDI_Sort(take)

end



function InsertAudioItem(filename, track, position)

  local item = reaper.AddMediaItemToTrack(track)
  local take = reaper.AddTakeToMediaItem(item)--reaper.GetMediaItemTake(item, 0)

  reaper.SetMediaItemPosition(item, position, false)

  --Set source from file
  local ok = reaper.BR_SetTakeSourceFromFile(take, filename, false)
  if(ok==false) then reaper.ShowConsoleMsg("Setting source from file failed. ("..filename..")\n") end

  --Set item length to source length
  local length = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take));
  reaper.SetMediaItemLength(item,length,false)

  return item
end

function InsertAudioItemPercussive(filename, track, position, length, fadeOutLength)
  local item = InsertAudioItem(filename, track, position)
  reaper.SetMediaItemLength(item,length,false)
  reaper.SetMediaItemInfo_Value(item,"D_FADEOUTLEN",fadeOutLength)
  reaper.SetMediaItemInfo_Value(item,"D_FADEOUTDIR", 0)
  reaper.SetMediaItemInfo_Value(item,"C_FADEOUTSHAPE", 1)
  reaper.SetMediaItemInfo_Value(item,"B_LOOPSRC", 0)
end


function GetFilesFromDirectory(directoryName)
  local files = {}
  local i = 0

  repeat
    local ret = reaper.EnumerateFiles(directoryName,i)
    table.insert(files,ret)
    i = i + 1
  until not ret

  return files
end


function SelectRandomElementFromArray(array)
  if(array==nil) then return nil end
  return array[math.random(0,#array)]
end


function RandomizeBPM(lower,upper)
  local bpm = math.random(lower,upper)
  reaper.SetCurrentBPM(0,bpm,1)
end



function RenderProjectToPath(renderPath)

  render_cfg_string = ultraschall.CreateRenderCFG_WAV(1,0,0,0,true)

  retval, render_files_count, rendered_files_MediaItemStateChunk, rendered_files_array
  = ultraschall.RenderProject(nil, renderPath, 0,-1,false,true,true,render_cfg_string,nil)

end


--Math helpers

function Round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end



function Sign(n)
   return n > 0 and 1
      or  n < 0 and -1
      or  0
end



function GenerateRandomValuesArray(size)
  local ret = {n=10}
  for i=0,size,1
  do
  ret[i] = math.random()
  end
  return ret
end

Main()
