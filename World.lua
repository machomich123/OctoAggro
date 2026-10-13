OctoAggroWorld={version="0.4.0-test",units={},glowing={},radii={},maxAlways=12}
local A=OctoAggroWorld
function A.Call(fn,a,b,c,d)
  if type(fn)~="function" then return nil end
  local ok,x,y,z,w=pcall(fn,a,b,c,d)
  if ok then return x,y,z,w end
end
function A.Finite(n) return type(n)=="number" and n==n and math.abs(n)<50000 end
function A.Settings(saved)
  if type(saved)~="table" then saved={} end
  local out={enabled=true,rings=true,glow=true,always=false,inside=false,base=20,assist=10}
  for key,value in pairs(out) do
    if type(saved[key])==type(value) and (type(value)=="boolean" or A.Finite(saved[key])) then out[key]=saved[key] end
  end
  out.base=math.max(0,math.min(60,out.base));out.assist=math.max(0,math.min(40,out.assist))
  return out
end
function A.Position(token)
  local west,north,z,map=A.Call(UnitPosition,token)
  if A.Finite(west) and A.Finite(north) and A.Finite(z) and A.Finite(map) then return {x=north,y=west,z=z,map=map} end
end
function A.Distance(a,b)
  if a.map~=b.map then return nil end
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
function A.Radius(playerLevel,level,base)
  if not A.Finite(playerLevel) or not A.Finite(level) or playerLevel<1 or level<1 then return nil end
  if base==0 then return 0 end
  return math.max(math.min(5,base),base-math.max(-25,playerLevel-level))
end
function A.Message(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff8844OctoAggro:|r "..s) end end
function A.BridgeReady()
  return A.Call(OctoAggroNativeVersion)==3 and type(OctoAggroNativeCircleRadius)=="function"
    and type(OctoAggroNativeAlwaysCircles)=="function"
    and type(OctoAggroNativeGlow)=="function" and type(OctoAggroNativeClear)=="function"
    and type(UnitPosition)=="function" and type(UnitGUID)=="function"
end
function A.Clear()
  A.Call(OctoAggroNativeClear);A.glowing={};A.units={};A.hover=nil;A.radii={}
end
function A.Scan()
  if not A.db.enabled or not A.BridgeReady() then A.Clear();return end
  local player=A.Position("player")
  if not player then A.Clear();return end
  local units,seen={},{}
  local function add(token)
    if not A.Call(UnitExists,token) or not A.Call(UnitCanAttack,"player",token)
      or A.Call(UnitIsPlayer,token) or A.Call(UnitIsDeadOrGhost,token) or A.Call(UnitIsDead,token) then return end
    local id=A.Call(UnitGUID,token)
    if type(id)~="string" or seen[id] then return end
    local pos=A.Position(token)
    if not pos then return end
    local distance=A.Distance(player,pos)
    if not distance or distance>60 then return end
    seen[id]=true;pos.id=id;pos.distance=distance;pos.token=token
    local reaction=A.Call(UnitReaction,"player",token)
    pos.hostile=type(reaction)=="number" and reaction<=3
    if pos.hostile then
      pos.radius=A.Radius(A.Call(UnitLevel,"player"),A.Call(UnitLevel,token),A.db.base)
    end
    table.insert(units,pos)
  end
  add("mouseover");add("target")
  if C_NamePlate and type(C_NamePlate.GetNamePlateGUIDs)=="function" then
    local ids=A.Call(C_NamePlate.GetNamePlateGUIDs)
    if type(ids)=="table" then for _,id in ipairs(ids) do add(id) end end
  else for i=1,80 do add("nameplate"..i) end end
  local hoverId=A.Call(UnitGUID,"mouseover")
  local targetId=A.Call(UnitGUID,"target")
  local hover=nil
  local target=nil
  for _,u in ipairs(units) do if u.id==hoverId then hover=u end end
  for _,u in ipairs(units) do if u.id==targetId then target=u end end
  local anchor=(hover and hover.hostile and hover) or (target and target.hostile and target)
  table.sort(units,function(a,b)
    if a.id==hoverId and b.id~=hoverId then return true end
    if b.id==hoverId and a.id~=hoverId then return false end
    if a.id==targetId and b.id~=targetId then return true end
    if b.id==targetId and a.id~=targetId then return false end
    return a.distance<b.distance
  end)
  local sources={}
  if A.db.always then
    for _,u in ipairs(units) do
      if u.hostile and u.radius and u.radius>0 and table.getn(sources)<A.maxAlways then table.insert(sources,u) end
    end
  elseif anchor and anchor.radius then table.insert(sources,anchor) end
  local glow={}
  if A.db.glow and anchor then
    glow[anchor.id]=true
    for _,u in ipairs(units) do
      local d=A.Distance(anchor,u)
      if u.hostile and A.db.assist>0 and d and d<=A.db.assist and math.abs(anchor.z-u.z)<=8 then glow[u.id]=true end
    end
  end
  -- Requested geometric inclusion. This is NOT a server-confirmed pull link.
  if A.db.inside then
    for _,source in ipairs(sources) do
      if source.hostile and source.radius and source.radius>0 then
        for _,u in ipairs(units) do
          if u.id~=source.id and u.hostile and math.abs(source.z-u.z)<=8
            and (source.x-u.x)^2+(source.y-u.y)^2<=source.radius^2 then glow[u.id]=true end
        end
      end
    end
  end
  for id in pairs(A.glowing) do if not glow[id] then A.Call(OctoAggroNativeGlow,id,false) end end
  for id in pairs(glow) do A.Call(OctoAggroNativeGlow,id,true) end
  A.glowing=glow;A.units=units;A.hover=hover
  local radii={}
  local drawn=0
  if A.db.rings then
    for _,u in ipairs(units) do
      if u.radius and u.radius>0 and (not A.db.always or drawn<A.maxAlways) then
        drawn=drawn+1
        radii[u.id]=u.radius;A.Call(OctoAggroNativeCircleRadius,u.id,u.radius)
      end
    end
  end
  for id in pairs(A.radii) do if not radii[id] then A.Call(OctoAggroNativeCircleRadius,id,0) end end
  A.radii=radii
  A.Call(OctoAggroNativeAlwaysCircles,A.db.rings and A.db.always)
end
function A.Set(key,value)
  A.db[key]=value;A.db=A.Settings(A.db);OctoAggroDB=A.db;A.Clear()
  if A.db.enabled then A.Scan() end
  if A.RefreshOptions then A.RefreshOptions() end
end
function A.Command(s)
  s=string.lower(s or "")
  if s=="off" then A.Set("enabled",false)
  elseif s=="on" then A.Set("enabled",true)
  elseif s=="toggle" then A.Set("enabled",not A.db.enabled)
  elseif s=="status" then
    A.Message("Rendering bridge: "..(A.BridgeReady() and "available" or "missing / unsupported client"))
    A.Message("Observed NPCs: "..table.getn(A.units)..". Aggro and extra mobs are estimates.")
  elseif s=="target" then
    if not A.Call(UnitExists,"target") then A.Message("Select an NPC first.");return end
    local reaction=A.Call(UnitReaction,"player","target")
    if type(reaction)~="number" or reaction>3 or A.Call(UnitIsPlayer,"target") then A.Message("Selected unit is not a red hostile NPC.");return end
    local radius=A.Radius(A.Call(UnitLevel,"player"),A.Call(UnitLevel,"target"),A.db.base)
    local name=A.Call(UnitName,"target") or "Unknown"
    local id=A.Call(UnitCreatureID,"target")
    A.Message(name..(id and (" (NPC "..id..")") or "")..": "..(radius and string.format("estimated %.1f yards",radius) or "radius unknown"))
    A.Message("Basis: base "..A.db.base.." + level adjustment. Server detection distance, aura modifiers and assistance rules are unavailable.")
  else A.options:Show();A.RefreshOptions() end
end
local eventFrame=CreateFrame("Frame","OctoAggroWorldEvents")
eventFrame:RegisterEvent("ADDON_LOADED");eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:SetScript("OnEvent",function(self,ev,name)
  ev=ev or event;name=name or arg1
  if ev=="ADDON_LOADED" and name=="OctoAggro" then
    A.db=A.Settings(OctoAggroDB);OctoAggroDB=A.db;A.Clear();A.BuildOptions();A.ready=true
    SLASH_OCTOAGGRO1="/oa";SLASH_OCTOAGGRO2="/octoaggro";SlashCmdList.OCTOAGGRO=A.Command
    A.Message("Native-ring test 0.4.0. /oa settings. Radius is estimated; circle overlap is not a confirmed pull.")
    if not A.BridgeReady() then A.Message("Rendering bridge missing. Run the supplied installer with WoW closed, then restart. No substitute radar is shown.") end
  elseif ev=="PLAYER_LEAVING_WORLD" then A.inWorld=false;A.Clear()
  elseif ev=="PLAYER_ENTERING_WORLD" then A.inWorld=true;if A.ready then A.Scan() end end
end)
local scan=0
eventFrame:SetScript("OnUpdate",function(self,dt)
  if not A.ready or not A.inWorld or not A.db.enabled then return end
  scan=scan+(dt or arg1 or 0)
  if scan>=0.25 then scan=0;A.Scan() end
end)
A.events=eventFrame
