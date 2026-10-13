dofile("NPCData.lua");dofile("AggroModel.lua")
local M=OctoAggroModel
local count=0
local function check(name,f)f();count=count+1;print("PASS "..name)end
local level=4;local playerLevel=4;local npcId=3101;local npcName="Vile Familiar"
function UnitLevel(unit) return unit=="player" and playerLevel or level end
function UnitCreatureID()return npcId end
function UnitName()return npcName end
local auras={player={},target={}}
C_UnitAuras={GetUnitAuras=function(unit)return auras[unit] or {} end}
local effects={
 [2908]={{auraName=91,basePoints=-11,baseDice=1,dieSides=1,pointsPerLevel=0,dicePerLevel=0}},
 [100001]={{auraName=152,basePoints=-6,baseDice=1,dieSides=1}},
 [100002]={{auraName=16}},
 [100003]={{auraName=152,basePoints=-4,baseDice=1,dieSides=3}}
}
C_Spell={GetSpellEffectInfo=function(id)return effects[id] or {} end,
 GetSpellDescription=function(id)if id==2908 then return "Soothes beasts up to level 40, reducing attack range." end end}
local settings={base=18,rate=1}
check("Vile Familiar uses actual reference template 12, not blanket 20",function()
 local r,s=M.ForUnit("target",M.Player(),settings);assert(r==12 and s.base==12)
 playerLevel=5;assert(M.ForUnit("target",M.Player(),settings)==11);playerLevel=4
end)
check("all 12751 parsed reference templates load in Lua 5.0",function()
 local n=0;for _ in pairs(OctoAggroNPCData)do n=n+1 end;assert(n==12751)
 assert(OctoAggroNPCData[3102][1]==12 and OctoAggroNPCData[2951][1]==18)
end)
check("level cap, minimum floor, disabled detection and rate match mathematics",function()
 assert(M.Calculate(18,1,60,0,0,1)==43)
 assert(M.Calculate(18,60,1,0,0,1)==5)
 assert(M.Calculate(0,1,60,0,0,1)==0)
 assert(M.Calculate(1,60,1,0,0,1)==1)
 assert(M.Calculate(12,4,4,0,0,0)==0)
 assert(M.Calculate(12,4,4,0,0,1.5)==18)
 assert(M.Calculate(12,4,-1,0,0,1)==nil)
end)
check("visible Soothe shrinks range and removal restores it",function()
 auras.target={{spellId=2908,applications=1}};assert(M.ForUnit("target",M.Player(),settings)==5)
 level=41;playerLevel=41;assert(M.ForUnit("target",M.Player(),settings)==12)
 auras.target={};level=4;playerLevel=4;assert(M.ForUnit("target",M.Player(),settings)==12)
end)
check("player detected-range modifiers and stacks are folded",function()
 auras.player={{spellId=100001,applications=2}};assert(M.ForUnit("target",M.Player(),settings)==5);auras.player={}
end)
check("ID/name reuse falls back rather than applying wrong template",function()
 npcName="Different custom NPC";local r,s=M.ForUnit("target",M.Player(),settings);assert(r==18 and s.source=="fallback base");npcName="Vile Familiar"
end)
check("stealth has no invented ordinary circular boundary",function()
 auras.player={{spellId=100002,applications=1}};local r,s=M.ForUnit("target",M.Player(),settings);assert(r==nil and s.reason);auras.player={}
end)
check("random magnitude and missing APIs are flagged as incomplete",function()
 auras.player={{spellId=100003}};local _,s=M.ForUnit("target",M.Player(),settings);assert(s.auraUnknown)
 auras.player={};local old=C_UnitAuras;C_UnitAuras=nil;_,s=M.ForUnit("target",M.Player(),settings);assert(s.auraUnknown);C_UnitAuras=old
end)
print("PASS "..count.." automatic model groups; OctoWoW parity unverified")
