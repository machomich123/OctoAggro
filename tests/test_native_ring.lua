dofile("tests/mock.lua")
glows={};radii={};circlesCalled=0;texturesMade=0
local methods=getmetatable(UIParent).__index
local oldTexture=methods.CreateTexture
function methods:CreateTexture(name) texturesMade=texturesMade+1;return oldTexture(self,name) end
function OctoAggroNativeVersion() return 2 end
function OctoAggroNativeClear() glows={};radii={};return 1 end
function OctoAggroNativeGlow(id,on) glows[id]=on or nil;return 1 end
function OctoAggroNativeCircleRadius(id,radius) circlesCalled=circlesCalled+1;radii[id]=radius>0 and radius or nil;return 1 end
function OctoAggroNativeProject() error("Rejected projection path called") end
function OctoAggroNativeSurface() error("Rejected tracing path called") end
dofile("World.lua");dofile("Settings.lua")
local A=OctoAggroWorld
local count=0
local function check(name,f)f();count=count+1;print("PASS "..name)end
local function fire(ev,name)event=ev;arg1=name;A.events:GetScript("OnEvent")();event=nil;arg1=nil end
world.player={id="player",x=0,y=0,z=0,map=1,level=10}
local a=mob("0x0000000000000001",20,0)
local b=mob("0x0000000000000002",25,0)
local far=mob("0x0000000000000003",50,0)
aliases.mouseover=a.id;aliases.target=a.id
check("actual Lua 5.0 startup with protocol 2",function()
 fire("ADDON_LOADED","OctoAggro");fire("PLAYER_ENTERING_WORLD")
 assert(A.ready and A.BridgeReady());assert(table.getn(A.units)==3)
end)
check("no custom ring textures, projection or terrain tracing",function()
 assert(texturesMade==0);assert(A.layer==nil and A.Render==nil);assert(frames.OctoAggroRadar==nil)
end)
check("native radius request is a world radius",function() assert(radii[a.id]==20 and radii[b.id]==20) end)
check("body glow requests still cover hover and nearby candidate",function()
 assert(glows[a.id] and glows[b.id]);assert(not glows[far.id])
end)
check("radius and glow switches are independent",function()
 A.Set("rings",false);assert(next(radii)==nil and glows[a.id])
 A.Set("rings",true);A.Set("glow",false);assert(next(glows)==nil and radii[a.id]==20);A.Set("glow",true)
end)
check("unknown level and neutral units lose radius requests",function()
 a.level=-1;A.Scan();assert(radii[a.id]==nil);a.level=10
 a.reaction=4;A.Scan();assert(radii[a.id]==nil);a.reaction=2;A.Scan()
end)
check("hover loss and despawn clear stale requests",function()
 aliases.mouseover=nil;A.Scan();assert(next(glows)==nil)
 aliases.mouseover=a.id;A.Scan();world[b.id]=nil;A.Scan();assert(radii[b.id]==nil and glows[b.id]==nil);world[b.id]=b
end)
check("disable clears native requests and stops scanning",function()
 A.Command("off");assert(next(radii)==nil and next(glows)==nil)
 local n=apiCalls;A.events:GetScript("OnUpdate")(nil,1);assert(apiCalls==n);A.Command("on")
end)
check("scan only runs four times per second",function()
 local n=circlesCalled
 A.events:GetScript("OnUpdate")(nil,0.1);assert(circlesCalled==n)
 A.events:GetScript("OnUpdate")(nil,0.1);assert(circlesCalled==n)
 A.events:GetScript("OnUpdate")(nil,0.1);assert(circlesCalled>n)
end)
check("old protocol fails closed",function()
 local old=OctoAggroNativeVersion;OctoAggroNativeVersion=function()return 1 end;A.Scan()
 assert(next(radii)==nil and next(glows)==nil);OctoAggroNativeVersion=old;A.Scan()
end)
check("world exit clears both request sets",function()
 fire("PLAYER_LEAVING_WORLD");assert(next(radii)==nil and next(glows)==nil)
 fire("PLAYER_ENTERING_WORLD");assert(radii[a.id]==20)
end)
print("PASS "..count.." native-ring Lua groups; live_world_tested=false")
