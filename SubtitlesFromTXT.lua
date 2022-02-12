function Main()
  local subtitleTextFilePath = "W:\\Projects\\Reaper\\ZadaniaRok3\\Dokument\\Audio\\Subtitles.txt"

  local FXText = [[// Text overlay
  #text=""; // set to string to override
  font="tiresias";
  
  //@param1:size 'text height' 0.05 0.01 0.2 0.1 0.001
  //@param2:ypos 'y position' 0.95 0 1 0.5 0.01
  //@param3:xpos 'x position' 0 0 1 0.5 0.01
  //@param4:border 'border' 0 0 1 0.5 0.01
  //@param5:fgc 'text bright' 1.0 0 1 0.5 0.01
  //@param6:fga 'text alpha' 1.0 0 1 0.5 0.01
  //@param7:bgc 'bg bright' 0.75 0 1 0.5 0.01
  //@param8:bga 'bg alpha' 0.5 0 1 0.5 0.01
  //@param10:ignoreinput 'ignore input' 0 0 1 0.5 1
  
  input = ignoreinput ? -2:0;
  project_wh_valid===0 ? input_info(input,project_w,project_h);
  gfx_a2=0;
  gfx_blit(input,1);
  gfx_setfont(size*project_h,font);
  strcmp(#text,"")==0 ? input_get_name(-1,#text);
  gfx_str_measure(#text,txtw,txth);
  yt = (project_h- txth*(1+border*2))*ypos;
  gfx_set(bgc,bgc,bgc,bga);
  gfx_fillrect(0, yt, project_w, txth*(1+border*2));
  gfx_set(fgc,fgc,fgc,fga);
  gfx_str_draw(#text,xpos * (project_w-txtw),yt+txth*border);]]
  
  local itemLength = 4
  local track = reaper.GetSelectedTrack(0, 0)
  local i = 0
  for line in io.lines(subtitleTextFilePath) do
    if (string.len(line) > 0) then
      local item = InsertEmptyAudioItem(track, i * itemLength, line, itemLength)
      
    end
    i = i + 1
  end
end

function InsertEmptyAudioItem(track, position, name, length)
  local item = reaper.AddMediaItemToTrack(track)
  local take = reaper.AddTakeToMediaItem(item)
  --reaper.GetMediaItemTake(item, 0)

  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)

  reaper.SetMediaItemPosition(item, position, false)

  reaper.SetMediaItemLength(item, length, false)

  local FXIndex = reaper.TakeFX_AddByName(take, "Video processor", -1000)

  if (FXIndex == -1) then
    reaper.ShowConsoleMsg("FX not loaded\n")
    
  local presetSuccess = reaper.TakeFX_SetPresetByIndex(take,0,2)
  
  if(presetSuccess~=true) then
    reaper.ShowConsoleMsg("Preset not loaded\n")
  end
  
  end
  
  return item
end

Main()
