local A=OctoAggroWorld
local function label(parent,s,y)
  local l=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  l:SetPoint("TOPLEFT",parent,"TOPLEFT",18,y);l:SetWidth(360);l:SetJustifyH("LEFT");l:SetText(s);return l
end
local function button(p,s,x,y,callback)
  local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
  b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);b:SetWidth(70);b:SetHeight(24);b:SetText(s);b:SetScript("OnClick",callback);return b
end
function A.BuildOptions()
  local p=CreateFrame("Frame","OctoAggroSettings",UIParent)
  p:SetWidth(400);p:SetHeight(410);p:SetPoint("CENTER",UIParent,"CENTER",0,0)
  p:SetFrameStrata("DIALOG");p:EnableMouse(true);p:SetMovable(true);p:SetClampedToScreen(true);p:RegisterForDrag("LeftButton")
  p:SetScript("OnDragStart",function() p:StartMoving() end);p:SetScript("OnDragStop",function() p:StopMovingOrSizing() end)
  p:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
  p:SetBackdropColor(0.05,0.05,0.06,0.96)
  label(p,"OctoAggro - world rings and body glow",-20)
  label(p,"Experimental: radii and extra mobs are estimates.\nNo server-confirmed pull links or millimetre accuracy.",-55)
  A.checks={}
  local rows={{"enabled","Enable OctoAggro"},{"rings","Show ground rings"},{"glow","Body glow on hover and possible extras"}}
  for i,row in ipairs(rows) do
    local key=row[1];local y=-110-(i-1)*35
    local c=CreateFrame("CheckButton","OctoAggroWorldOption"..key,p,"UICheckButtonTemplate")
    c:SetPoint("TOPLEFT",p,"TOPLEFT",15,y);c:SetWidth(26);c:SetHeight(26)
    local t=label(p,row[2],y-7);t:ClearAllPoints();t:SetPoint("TOPLEFT",p,"TOPLEFT",46,y-7);t:SetWidth(330)
    c:SetScript("OnClick",function() A.Set(key,not A.db[key]) end);A.checks[key]=c
  end
  A.values={}
  local numbers={{"base","Base aggro estimate",20},{"assist","Possible-assist distance",10}}
  for i,row in ipairs(numbers) do
    local key=row[1];local y=-228-(i-1)*35
    label(p,row[2],y-5);A.values[key]=label(p,"",y-5);A.values[key]:ClearAllPoints();A.values[key]:SetPoint("TOPLEFT",p,"TOPLEFT",278,y-5);A.values[key]:SetWidth(60)
    button(p,"-",205,y,function() A.Set(key,A.db[key]-5) end)
    button(p,"+",320,y,function() A.Set(key,A.db[key]+5) end)
  end
  label(p,"Up to 12 observed NPC rings within 60 yards.\nGround clipping and glow need live-game verification.\nNo radar, HUD or nameplate decorations.",-318)
  button(p,"Status",18,-371,function() A.Command("status") end)
  button(p,"Close",310,-371,function() p:Hide() end)
  A.options=p;table.insert(UISpecialFrames,"OctoAggroSettings");p:Hide();A.RefreshOptions()
  if type(InterfaceOptions_AddCategory)=="function" then p.name="OctoAggro";InterfaceOptions_AddCategory(p) end
end
function A.RefreshOptions()
  for key,c in pairs(A.checks) do c:SetChecked(A.db[key]) end
  for key,l in pairs(A.values) do l:SetText(string.format("%g yd",A.db[key])) end
end
