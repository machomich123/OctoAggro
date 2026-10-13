OctoAggroWorld={version="0.2.0-test",units={},glowing={},rings={},samples=64,maxRings=12}
local A=OctoAggroWorld
local white="Interface\\Buttons\\WHITE8X8"
function A.Call(fn,a,b,c,d)
  if type(fn)~="function" then return nil end
  local ok,x,y,z,w=pcall(fn,a,b,c,d)
  if ok then return x,y,z,w end
end
function A.Finite(n) return type(n)=="number" and n==n and math.abs(n)<50000 end
function A.Settings(saved)
  if type(saved)~="table" then saved={} end
  local out={enabled=true,rings=true,glow=true,base=20,assist=10}
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
  return A.Call(OctoAggroNativeVersion)==1 and type(OctoAggroNativeSurface)=="function"
    and type(OctoAggroNativeProject)=="function" and type(OctoAggroNativeGlow)=="function"
    and type(OctoAggroNativeClear)=="function" and type(UnitPosition)=="function" and type(UnitGUID)=="function"
end
function A.Clear()
  A.Call(OctoAggroNativeClear); A.glowing={}; A.units={}; A.hover=nil; A.activeRings=0
  for _,ring in ipairs(A.rings) do
    for _,line in ipairs(ring.lines) do line:Hide() end
    ring.id=nil;ring.points=nil
  end
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
    if A.Call(UnitReaction,"player",token) and A.Call(UnitReaction,"player",token)<=3 then
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
  local hover=nil
  for _,u in ipairs(units) do if u.id==hoverId then hover=u end end
  local glow={}
  if A.db.glow and hover then
    glow[hover.id]=true
    for _,u in ipairs(units) do
      local d=A.Distance(hover,u)
      if A.db.assist>0 and d and d<=A.db.assist and math.abs(hover.z-u.z)<=8 then glow[u.id]=true end
    end
  end
  for id in pairs(A.glowing) do if not glow[id] then A.Call(OctoAggroNativeGlow,id,false) end end
  for id in pairs(glow) do A.Call(OctoAggroNativeGlow,id,true) end
  A.glowing=glow;A.units=units;A.hover=hover
  table.sort(units,function(a,b)
    if a.id==hoverId and b.id~=hoverId then return true end
    if b.id==hoverId and a.id~=hoverId then return false end
    return a.distance<b.distance
  end)
  local index=0
  if A.db.rings then
    for _,u in ipairs(units) do
      if u.radius and u.radius>0 and index<A.maxRings then
        index=index+1
        local ring=A.rings[index]
        if not ring then
          ring={lines={}};A.rings[index]=ring
          for j=1,A.samples do
            local line=A.layer:CreateTexture(nil,"ARTWORK")
            line:SetTexture(white);line:SetHeight(2);line:SetVertexColor(1,0.12,0.02,0.85);line:Hide()
            ring.lines[j]=line
          end
        end
        if ring.id~=u.id or not ring.points or ring.radius~=u.radius or math.abs(ring.x-u.x)+math.abs(ring.y-u.y)>0.3 or GetTime()-ring.groundAt>0.5 then
          ring.points={};ring.id=u.id;ring.x=u.x;ring.y=u.y;ring.radius=u.radius;ring.groundAt=GetTime()
          for j=1,A.samples do
            local angle=j*math.pi*2/A.samples
            local x,y=u.x+math.cos(angle)*u.radius,u.y+math.sin(angle)*u.radius
            local z=A.Call(OctoAggroNativeSurface,x,y,u.z)
            if A.Finite(z) and math.abs(z-u.z)<=12 then ring.points[j]={x=x,y=y,z=z,visible=false} end
          end
        end
      end
    end
  end
  A.activeRings=index
  for i=index+1,table.getn(A.rings) do for _,line in ipairs(A.rings[i].lines) do line:Hide() end end
end
function A.Render(checkVisibility)
  if not A.db.enabled or not A.db.rings then return end
  local width,height=UIParent:GetWidth(),UIParent:GetHeight()
  for i=1,A.activeRings or 0 do
    local ring=A.rings[i]
    local projected={}
    for j=1,A.samples do
      local p=ring.points[j]
      if p then
        local x,y=A.Call(OctoAggroNativeProject,p.x,p.y,p.z,checkVisibility)
        if checkVisibility then p.visible=x~=nil and y~=nil end
        if p.visible and A.Finite(x) and A.Finite(y) then projected[j]={x=x*width,y=y*height} end
      end
    end
    for j=1,A.samples do
      local line=ring.lines[j];local a=projected[j];local b=projected[j==A.samples and 1 or j+1]
      line:Hide()
      if a and b then
        local dx,dy=b.x-a.x,b.y-a.y
        local len=math.sqrt(dx*dx+dy*dy)
        if len>0.1 and len<300 and type(line.SetRotation)=="function" then
          line:SetWidth(len+0.5);line:ClearAllPoints()
          line:SetPoint("CENTER",UIParent,"BOTTOMLEFT",(a.x+b.x)/2,(a.y+b.y)/2)
          line:SetRotation(math.atan2(dy,dx));line:Show()
        end
      end
    end
  end
end
function A.Set(key,value)
  A.db[key]=value;A.db=A.Settings(A.db);OctoAggroDB=A.db;A.Clear()
  if A.db.enabled then A.Scan();A.Render(true) end
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
  else A.options:Show();A.RefreshOptions() end
end
A.layer=CreateFrame("Frame",nil,UIParent)
A.layer:SetAllPoints(UIParent);A.layer:SetFrameStrata("BACKGROUND");A.layer:EnableMouse(false)
local eventFrame=CreateFrame("Frame","OctoAggroWorldEvents")
eventFrame:RegisterEvent("ADDON_LOADED");eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:SetScript("OnEvent",function(self,ev,name)
  ev=ev or event;name=name or arg1
  if ev=="ADDON_LOADED" and name=="OctoAggro" then
    A.db=A.Settings(OctoAggroDB);OctoAggroDB=A.db;A.Clear();A.BuildOptions();A.ready=true
    SLASH_OCTOAGGRO1="/oa";SLASH_OCTOAGGRO2="/octoaggro";SlashCmdList.OCTOAGGRO=A.Command
    A.Message("World test 0.2.0. /oa settings. Rings and extra mobs are estimates.")
    if not A.BridgeReady() then A.Message("Rendering bridge missing. Run the supplied installer with WoW closed, then restart. No substitute radar is shown.") end
  elseif ev=="PLAYER_LEAVING_WORLD" then A.inWorld=false;A.Clear()
  elseif ev=="PLAYER_ENTERING_WORLD" then A.inWorld=true;if A.ready then A.Scan();A.Render(true) end end
end)
local scan,render,visibility=0,0,0
eventFrame:SetScript("OnUpdate",function(self,dt)
  dt=dt or arg1 or 0
  if not A.ready or not A.inWorld or not A.db.enabled then return end
  scan=scan+dt;render=render+dt;visibility=visibility+dt
  if scan>=0.15 then scan=0;A.Scan() end
  if render>=0.05 then render=0;local check=visibility>=0.15;A.Render(check);if check then visibility=0 end end
end)
A.events=eventFrame
