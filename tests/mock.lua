-- Minimal frame API used only in offline tests. Unknown methods must fail.
UISpecialFrames={}; SlashCmdList={}; messages={}; frames={}
local methods={}
function methods:SetWidth(n) self.width=n end
function methods:SetHeight(n) self.height=n end
function methods:SetPoint(a,b,c,d,e) self.anchor={a,b,c,d,e} end
function methods:ClearAllPoints() self.anchor=nil end
function methods:SetAllPoints(frame) self.allpoints=frame end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown~=false and (not self.parent or self.parent:IsShown()) end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(n) self.level=n end
function methods:GetCenter() return 500,400 end
function methods:AddMessage(m) table.insert(messages,m) end
function methods:SetOwner(owner) self.owner=owner end
function methods:IsOwned(owner) return self.owner==owner end
function methods:ClearLines() self.lines={} end
function methods:AddLine(line) self.lines=self.lines or {}; table.insert(self.lines,line) end
function methods:SetVertexColor(r,g,b,a) self.colour={r,g,b,a} end
function methods:SetBackdropBorderColor(r,g,b,a) self.border={r,g,b,a} end
local noops={"SetBackdrop","SetBackdropColor","SetFont","SetJustifyH","SetFrameStrata",
  "EnableMouse","SetMovable","SetClampedToScreen","RegisterForDrag","StartMoving",
  "StopMovingOrSizing","SetTexture","SetTextColor"}
for _,key in ipairs(noops) do methods[key]=function() end end
local function frame(name,parent)
  local f=setmetatable({name=name,parent=parent,shown=true,scripts={},events={}}, {__index=methods})
  if name then frames[name]=f; _G[name]=f end
  return f
end
function CreateFrame(kind,name,parent,template) return frame(name,parent) end
function methods:CreateTexture(name) return frame(name,self) end
function methods:CreateFontString(name) return frame(name,self) end
UIParent=frame("UIParent")
GameTooltip=frame("GameTooltip"); GameTooltip:Hide()
DEFAULT_CHAT_FRAME=frame("DEFAULT_CHAT_FRAME")
function getglobal(key) return _G[key] end

world={}; aliases={}; apiCalls=0
local function find(token) return world[aliases[token] or token] end
function UnitExists(token) apiCalls=apiCalls+1; return find(token)~=nil end
function UnitCanAttack(player,token) local u=find(token); return u and u.attackable end
function UnitIsPlayer(token) local u=find(token); return u and u.player end
function UnitIsDeadOrGhost(token) local u=find(token); return u and u.dead end
function UnitIsDead(token) return UnitIsDeadOrGhost(token) end
function UnitGUID(token) local u=find(token); return u and u.id end
function UnitName(token) local u=find(token); return u and u.name end
function UnitLevel(token) local u=find(token); return u and u.level end
function UnitReaction(player,token) local u=find(token); return u and u.reaction end
function UnitPosition(token)
  local u=find(token)
  if u and not u.noPosition then return u.y,u.x,u.z,u.map end
end
function UnitInLineOfSight(token) local u=find(token); return u and u.los end
C_NamePlate={}
function C_NamePlate.GetNamePlateGUIDs()
  local result={}; for id,u in pairs(world) do if u.plate then table.insert(result,id) end end
  return result
end
function C_NamePlate.GetNamePlateForUnit(token) local u=find(token); return u and u.plate end
function mob(id,x,y,level,reaction)
  local u={id=id,name=id,x=x,y=y,z=0,map=1,level=level or 10,reaction=reaction or 2,attackable=true,los=true}
  u.plate=CreateFrame("Frame",nil,UIParent); world[id]=u
  return u
end
function fire(ev,name)
  -- Exercise vanilla globals, not just modern callback arguments.
  event=ev; arg1=name; OctoAggro.events:GetScript("OnEvent")()
  event=nil; arg1=nil
end
