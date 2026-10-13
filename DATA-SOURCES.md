# Automatic aggro model provenance — 2026-10-13

NPCData.lua is an extracted adaptation of 12,751 creature-template rows from
[tortoise-wow/tortoise-wow](https://github.com/tortoise-wow/tortoise-wow), commit
`10393426efe4bbe1de3a31fd071ca36fae358bb6`,
[creature-template SQL](https://github.com/tortoise-wow/tortoise-wow/blob/10393426efe4bbe1de3a31fd071ca36fae358bb6/sql/base/tw_world_creature_template.sql).
Source SHA-256: `a091deb2ed09ffd651d8ae11eac8b40ee11f7505bbcffeae24582fb30f1ed12b`.
The pinned URL was fetched independently and its hash matched the parsed file.

Retained fields: entry, enUS name, detection_range, and a derived no-proximity-aggro
flag from civilian / flags_extra NO_AGGRO. Names guard against custom-server ID
reuse. A name mismatch or unknown ID uses the documented fallback (18 yards).

Tortoise-WoW describes itself as an unofficial community restoration of Turtle
WoW 1.18.1. It is not OctoWoW's confirmed deployed core or database, and it is not
Blizzard's original server source. **These rows are reference data, not verified
live OctoWoW values.** The model identifies that source in `/oa target`.

The distributed package is under upstream's AGPL-3.0 license (LICENSE).
The earlier original addon-code MIT notice is retained under licenses; MinHook
keeps its own BSD license at native/vendor/minhook/LICENSE.txt. No upstream server
source code is copied into the model; the mathematical calculation is independently
implemented. The extracted template dataset is distributed with its provenance.

## Implemented reference formula

For a hostile NPC and the local player:

`max(min(base, 5), base - max(-25, playerLevel - npcLevel) + NPC_detect_modifier + player_detected_modifier) * aggroRate`

Base detection below 1 or aggro rate 0 gives 0. Unknown live level gives no radius.
Reference sources:

- [Tortoise Creature::GetAttackDistance and canStartAttack](https://github.com/tortoise-wow/tortoise-wow/blob/10393426efe4bbe1de3a31fd071ca36fae358bb6/src/game/Objects/Creature.cpp).
  The attack gate uses `IsWithinDistInMap(..., true, SizeFactor::None)`: 3D,
  centre distance. No bounding-radius or combat-reach expansion was added.
- [VMaNGOS Creature.cpp](https://github.com/vmangos/core/blob/development/src/game/Objects/Creature.cpp):
  same overall structure, creature-specific detection range and aura modifiers.
- [CMaNGOS Unit.cpp](https://github.com/cmangos/mangos-classic/blob/master/src/game/Entities/Unit.cpp):
  closely related calculation, with a 5-yard floor and an additional pet-target
  multiplier. The addon computes player proximity, not pet proximity.
- [Tortoise configuration defaults](https://github.com/tortoise-wow/tortoise-wow/blob/10393426efe4bbe1de3a31fd071ca36fae358bb6/src/mangosd/mangosd.conf.dist.in):
  aggro rate 1 and family assistance distance 10. OctoWoW's deployed values are
  unknown; the model uses reference rate 1, clearly reported by target inspection.

## Concrete previous-model defect

The old model used base 20 for every NPC. This dataset gives Vile Familiar (3101)
and Felstalker (3102) base 12. Most rows use 18; 3,544 use 20, and others differ.
At player level 5 against a level-4 Vile Familiar, the reference result is 11
yards, whereas the old result was 19. That is a reference-model correction,
not proof that the deployed OctoWoW boundary is exactly 11.

## Live aura inputs

ClassicAPI GetUnitAuras supplies observed spell IDs and stacks. GetSpellEffectInfo
supplies the installed client's Spell.dbc effect fields. Aura type 91 modifies
the NPC's detection range; type 152 modifies the player's detected range. Fixed
magnitudes use basePoints + baseDice, multiplied by observed applications.

For NPC detection auras the reference server checks MaxTargetLevel. ClassicAPI
does not expose that field directly; the model extracts a level cap from the
client's English spell description. Missing caps, random magnitudes and level-
scaled magnitudes are flagged incomplete and not invented. Missing aura APIs are
also reported. Source: [ClassicAPI API.md](https://github.com/brues-code/ClassicAPI/blob/master/docs/API.md).
Presence of these API names was verified in the installed DLL; live registration
and observed-aura operation remain untested for this build.

Stealth, invisibility and feign-death states suppress the ordinary circular
prediction. They are separate detection problems. Line of sight, AI scripts,
world state and server changes can still alter actual attacks. Help from other
NPCs remains separate from geometric circle inclusion.
