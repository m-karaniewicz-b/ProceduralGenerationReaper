
function main()
  selCount = reaper.CountSelectedTracks(0)
  
  if selCount == 1 then
    selTrack = reaper.GetSelectedTrack(0)
    _, trackName = reaper.GetSetMediaTrackInfo_String(selTrack, "P_NAME", '', false)
    
  end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Add parent track",-1)


