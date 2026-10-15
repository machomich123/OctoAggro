-- Let Vanilla attach and draw the skull on the creature model.
-- No screen projection, fixed head offsets or UI overlay frames.
local A=OctoAggroWorld
A.markerCandidates={};A.markerOwned={};A.markerLimit=32
function A.ClearMarkers()
  for id in pairs(A.markerOwned) do A.Call(OctoAggroNativeMarker,id,false) end
  A.markerCandidates={};A.markerOwned={}
end
function A.UpdateMarkerCandidates(units,target)
  local candidates,requested={},{}
  local ready=A.Call(OctoAggroNativeVersion)==6 and type(OctoAggroNativeMarker)=="function"
  if ready and A.db.skulls and target and target.hostile then
    table.insert(candidates,target)
    for _,u in ipairs(units) do
      local d=A.Distance(target,u)
      if u.id~=target.id and u.hostile and A.db.assist>0 and d and d<=A.db.assist
        and math.abs(target.z-u.z)<=8 and table.getn(candidates)<A.markerLimit then
        table.insert(candidates,u)
      end
    end
    for _,u in ipairs(candidates) do
      if A.Call(OctoAggroNativeMarker,u.id,true)==1 then requested[u.id]=true end
    end
  end
  for id in pairs(A.markerOwned) do if not requested[id] then A.Call(OctoAggroNativeMarker,id,false) end end
  A.markerCandidates=candidates;A.markerOwned=requested
end
function A.BuildMarkers() end
