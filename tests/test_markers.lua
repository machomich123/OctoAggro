dofile("tests/mock.lua")
local version=6;local requested={};local writes=0
function OctoAggroNativeVersion()return version end
function OctoAggroNativeClear()requested={};return 1 end
function OctoAggroNativeCircleRadius()return 1 end
function OctoAggroNativeAlwaysCircles()return 1 end
function OctoAggroNativeGlow()error("Unexpected body glow")end
function OctoAggroNativeMarker(id,on)writes=writes+1;requested[id]=on or nil;return 1 end
function OctoAggroNativeCreatures()local t={};for id in pairs(world)do if id~="player"then table.insert(t,id)end end;return t end
function OctoAggroNativeProject()error("Screen projection must never run")end
function SetRaidTarget()error("Real raid markers must never change")end
dofile("NPCData.lua");dofile("AggroModel.lua");dofile("World.lua");dofile("Markers.lua");dofile("Settings.lua")
local A=OctoAggroWorld
local function fire(e)event=e;arg1="OctoAggro";A.events:GetScript("OnEvent")();event=nil;arg1=nil end
local n=0;local function check(name,f)f();n=n+1;print("PASS "..name)end
world.player={id="player",x=0,y=0,z=0,map=1,level=10}
local a=mob("0xF130000000000001",20,0);local b=mob("0xF130000000000002",25,0);local far=mob("0xF130000000000003",40,0)
a.plate=false;b.plate=false;far.plate=false
OctoAggroDB={glow=true,inside=true,always=true};fire("ADDON_LOADED");fire("PLAYER_ENTERING_WORLD")
check("migration disables glow and always circles",function()assert(A.db.skulls and not A.db.glow and not A.db.inside and not A.db.always)end)
check("no target no native markers",function()assert(next(requested)==nil)end)
check("multiple native skull requests without nameplates",function()aliases.target=a.id;A.Scan();assert(requested[a.id] and requested[b.id] and not requested[far.id]);assert(A.radii[a.id] and not A.radii[b.id])end)
check("no custom frame renderer",function()assert(A.markerFrames==nil and A.markerTimer==nil and A.DrawMarkers==nil)end)
check("refresh requests before expiry",function()local old=writes;A.Scan();assert(writes>old and requested[a.id])end)
check("dead neutral and height-separated neighbours excluded",function()b.dead=true;A.Scan();assert(not requested[b.id]);b.dead=false;b.reaction=4;A.Scan();assert(not requested[b.id]);b.reaction=2;b.z=20;A.Scan();assert(not requested[b.id]);b.z=0 end)
check("target-change clears prior ownership",function()aliases.target=far.id;fire("PLAYER_TARGET_CHANGED");assert(requested[far.id] and not requested[a.id] and not requested[b.id]);aliases.target=nil;fire("PLAYER_TARGET_CHANGED");assert(next(requested)==nil)end)
check("old DLL fails closed and reports restart",function()aliases.target=a.id;A.Scan();version=5;A.Scan();assert(next(requested)==nil);A.Command("status");assert(string.find(messages[table.getn(messages)-1],"restart required",1,true));version=6 end)
check("toggle disable and world exit clear native requests",function()A.Set("skulls",false);assert(next(requested)==nil);A.Set("skulls",true);assert(requested[a.id]);A.Command("off");assert(next(requested)==nil);A.Command("on");fire("PLAYER_LEAVING_WORLD");assert(next(requested)==nil)end)
check("request count capped at 32",function()A.inWorld=true;for i=1,50 do mob(string.format("0xF130%012x",i+100),20,i/100)end;A.Scan();local c=0;for _ in pairs(requested)do c=c+1 end;assert(c==32)end)
print("PASS "..n.." native skull Lua groups; live native display unverified")
