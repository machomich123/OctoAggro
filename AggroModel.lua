-- Formula implemented independently from the cited server mathematics.
OctoAggroModel={effectCache={}}
local M=OctoAggroModel
local function call(fn,a,b)
  if type(fn)~="function" then return nil end
  local ok,x=pcall(fn,a,b);if ok then return x end
end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<50000 end
function M.Calculate(base,playerLevel,mobLevel,mobModifier,playerModifier,rate)
  if not finite(base) or not finite(playerLevel) or not finite(mobLevel) or playerLevel<1 or mobLevel<1 then return nil end
  if base<1 or rate==0 then return 0 end
  return math.max(math.min(base,5),base-math.max(-25,playerLevel-mobLevel)+(mobModifier or 0)+(playerModifier or 0))*(rate or 1)
end
function M.Auras(unit,wanted,level)
  local result={amount=0,available=false,uncertain=false,hidden=false}
  if not C_UnitAuras or not C_Spell then return result end
  local auras=call(C_UnitAuras.GetUnitAuras,unit)
  if type(auras)~="table" or type(C_Spell.GetSpellEffectInfo)~="function" then return result end
  result.available=true
  for _,aura in ipairs(auras) do
    local id=aura.spellId
    local fx=id and M.effectCache[id]
    if not fx and type(id)=="number" and id>0 and id<2147483648 then fx=call(C_Spell.GetSpellEffectInfo,id);if type(fx)=="table" then M.effectCache[id]=fx end end
    if type(fx)~="table" then result.uncertain=true
    else
      for _,effect in ipairs(fx) do
        if effect.auraName==16 or effect.auraName==18 then result.hidden=true end
        if effect.auraName==wanted then
          local valid=true
          if wanted==91 then
            -- The server checks MaxTargetLevel. Read its displayed cap rather
            -- than pretending to know an unexposed custom Spell.dbc field.
            local description=call(C_Spell.GetSpellDescription,id)
            local cap=nil
            if type(description)=="string" then
              local _,_,n=string.find(description,"[Ll]evel%s+(%d+)");cap=tonumber(n)
            end
            if not cap then result.uncertain=true;valid=false
            elseif not finite(level) or level>cap then valid=false end
          end
          if valid then
            if not finite(effect.basePoints) or not finite(effect.baseDice)
              or (effect.dieSides or 0)>1 or (effect.pointsPerLevel or 0)~=0 or (effect.dicePerLevel or 0)~=0 then result.uncertain=true
            else
              local stacks=finite(aura.applications) and math.max(1,math.min(255,aura.applications)) or 1
              result.amount=result.amount+(effect.basePoints+effect.baseDice)*stacks
            end
          end
        end
      end
    end
  end
  return result
end
function M.Player()
  local result=M.Auras("player",152,call(UnitLevel,"player"))
  if call(IsStealthed) or call(UnitIsFeignDeath,"player") then result.hidden=true end
  return result
end
function M.ForUnit(unit,player,saved)
  local id=call(UnitCreatureID,unit)
  local name=call(UnitName,unit)
  local row=OctoAggroNPCData and OctoAggroNPCData[id]
  -- Custom servers can reuse IDs. Do not apply another named NPC's template.
  if row and name~=row[2] then row=nil end
  local base=row and row[1] or saved.base
  local result={npcId=id,base=base,source=row and "Tortoise template (OctoWoW not verified)" or "fallback base",rate=saved.rate or 1,mobModifier=0,playerModifier=0}
  if player.hidden then result.reason="stealth / invisibility / feign death";return nil,result end
  if row and row[3] then result.reason="reference NPC cannot proximity-aggro";return 0,result end
  local level=call(UnitLevel,unit)
  local mods=M.Auras(unit,91,level)
  result.mobModifier=mods.amount;result.playerModifier=player.amount
  result.auraUnknown=not mods.available or not player.available or mods.uncertain or player.uncertain
  result.radius=M.Calculate(base,call(UnitLevel,"player"),level,mods.amount,player.amount,result.rate)
  if not result.radius then result.reason="unknown live level" end
  return result.radius,result
end
