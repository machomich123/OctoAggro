dofile("tests/mock.lua")
clock=0
local methods=getmetatable(UIParent).__index
function GetTime() return clock end
function methods:GetWidth() return self.width or 1280 end
function methods:GetHeight() return self.height or 720 end
function methods:SetRotation(angle) self.rotation=angle end
glows={};clears=0;groundCalls=0
function OctoAggroNativeVersion() return 1 end
function OctoAggroNativeClear() glows={};clears=clears+1;return 1 end
function OctoAggroNativeGlow(id,on) glows[id]=on or nil;return 1 end
function OctoAggroNativeSurface(x,y,z) groundCalls=groundCalls+1;return z+0.08 end
function OctoAggroNativeProject(x,y,z,check) return 0.5+x/200,0.5+y/200 end
dofile("World.lua");dofile("Settings.lua")
local A=OctoAggroWorld
local count=0
local function check(name,f) f();count=count+1;print("PASS "..name) end
local function fire(ev,name) event=ev;arg1=name;A.events:GetScript("OnEvent")();event=nil;arg1=nil end
world.player={id="player",x=0,y=0,z=0,map=1,level=10}
local u=mob("0x0000000000000001",20,0)
local other=mob("0x0000000000000002",25,0)
local far=mob("0x0000000000000003",50,0)
aliases.mouseover=u.id;aliases.target=u.id
check("saved radar settings are discarded",function()
 local s=A.Settings({radar=true,enabled=true});assert(s.radar==nil)
 assert(A.Settings(false).base==20);assert(A.Settings({base=0/0}).base==20)
end)
check("actual Lua 5.0 startup and settings panel",function()
 fire("ADDON_LOADED","OctoAggro");fire("PLAYER_ENTERING_WORLD")
 assert(A.ready and A.BridgeReady());assert(not A.options:IsShown())
 assert(frames.OctoAggroRadar==nil);assert(table.getn(A.units)==3)
end)
check("native body glow covers hover and nearby candidate only",function()
 assert(glows[u.id] and glows[other.id]);assert(not glows[far.id])
end)
check("rings originate from NPC coordinates at aggro radius",function()
 assert(A.activeRings==3);local p=A.rings[1].points[1]
 local d=math.sqrt((p.x-u.x)^2+(p.y-u.y)^2)
 assert(math.abs(d-20)<0.000001);assert(p.z==0.08)
 assert(A.rings[1].lines[1]:IsShown());assert(A.rings[1].lines[1].rotation~=nil)
end)
check("ground cache and fresh projection are separate",function()
 local n=groundCalls;A.Scan();A.Render(true);assert(groundCalls==n)
 clock=1;A.Scan();assert(groundCalls>n)
end)
check("camera-obscured segments are not drawn",function()
 local old=OctoAggroNativeProject;OctoAggroNativeProject=function() return nil end
 A.Render(true);for _,r in ipairs(A.rings) do for _,l in ipairs(r.lines) do assert(not l:IsShown()) end end
 OctoAggroNativeProject=old;A.Render(true)
end)
check("no terrain hit does not create floating rings",function()
 local old=OctoAggroNativeSurface;OctoAggroNativeSurface=function() return nil end
 clock=2;A.Scan();A.Render(true)
 for _,r in ipairs(A.rings) do for _,l in ipairs(r.lines) do assert(not l:IsShown()) end end
 OctoAggroNativeSurface=old;clock=3;A.Scan();A.Render(true)
end)
check("ring and body switches are independent",function()
 A.Set("rings",false);assert(A.activeRings==0);assert(glows[u.id])
 A.Set("rings",true);A.Set("glow",false);assert(next(glows)==nil);assert(A.activeRings==3)
 A.Set("glow",true)
end)
check("neutral and unknown-level NPCs have no invented radius",function()
 u.reaction=4;A.Scan();assert(A.units[1].radius==nil)
 u.reaction=2;u.level=-1;A.Scan();assert(A.units[1].radius==nil);u.level=10
end)
check("lost mouseover and despawn release native glow",function()
 aliases.mouseover=nil;A.Scan();assert(next(glows)==nil)
 aliases.mouseover=u.id;A.Scan();world[other.id]=nil;A.Scan();assert(not glows[other.id]);world[other.id]=other
end)
check("disabled addon clears all geometry and glow",function()
 A.Command("off");assert(next(glows)==nil)
 for _,r in ipairs(A.rings) do for _,l in ipairs(r.lines) do assert(not l:IsShown()) end end
 local calls=apiCalls;A.events:GetScript("OnUpdate")(nil,1);assert(apiCalls==calls)
 A.Command("on")
end)
check("missing bridge fails without displaying a substitute UI",function()
 local old=OctoAggroNativeVersion;OctoAggroNativeVersion=nil;A.Scan()
 A.Render(true);assert(A.activeRings==0)
 assert(next(glows)==nil and table.getn(A.units)==0);assert(frames.OctoAggroRadar==nil)
 OctoAggroNativeVersion=old;A.Scan()
end)
check("world transitions clear state",function()
 fire("PLAYER_LEAVING_WORLD");assert(next(glows)==nil)
 fire("PLAYER_ENTERING_WORLD");assert(glows[u.id])
end)
check("rendering load is bounded",function()
 for i=1,30 do mob(string.format("0x%016x",i+50),25,i/3) end
 A.Scan();A.Render(true);assert(A.activeRings==12);assert(table.getn(A.rings)==12)
end)
print("PASS "..count.." world-addon groups; live_world_tested=false")
