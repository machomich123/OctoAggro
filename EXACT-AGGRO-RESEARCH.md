# Exact selected-NPC aggro range — investigation, 2026-10-13

## Finding

No authoritative OctoWoW per-NPC/player aggro-range feed was found in the
inspected client APIs, public NPC page or public source search. The current
level-based circle is still an estimate. The user confirmed that native drawing
in 0.3.0 behaved acceptably, but the displayed radius differed from actual aggro.
That is live feedback about this build's estimate, not proof of a specific new
server formula or radius.

Inspected primary sources:

- [ClassicAPI API/source](https://github.com/brues-code/ClassicAPI): unit positions,
  GUIDs, nameplates, line of sight and combat APIs. Its inspected API.md and source
  do not expose an authoritative NPC detection range or assistance graph.
- [OctoWoW Vile Familiar, NPC 3101](https://octowow.st/db/?npc=3101): public page
  shows level 3–4, faction 14, health and related NPC fields. It does not supply
  aggro radius, detection modifiers, help range or a per-player calculation.
- [OctoWoW public source listings](https://octowow.st/git/explore/repos): no
  confirmed current realm core/configuration containing these values was obtained.
- [VMaNGOS Creature.cpp](https://github.com/vmangos/core/blob/development/src/game/Objects/Creature.cpp):
  GetAttackDistance, CallAssistance, CanBeTargetedByCallForHelp and
  CanRespondToCallForHelpAgainst. This is reference server code, NOT confirmed
  OctoWoW core/configuration.
- [VMaNGOS WorldObject distance code](https://github.com/vmangos/core/blob/development/src/game/Objects/Object.cpp):
  distance semantics can include object size. A numerical attack distance is not
  automatically the same as a centre-to-centre ring radius.

## Why level alone cannot be exact

The reference server calculation starts with the creature's detection range,
applies level difference, includes detection/detected-range aura modifiers and
uses a server aggro multiplier. Minimum distance and special AI/script behaviour
also matter. Accurate visual conversion additionally needs the actual server's
distance convention: 2D versus 3D and whether object size is included. Native ring
texture geometry must be checked against known world distances too. Enlarging
the ring is a rendering change; it cannot infer missing server inputs.

The current implementation retains the documented base 20 yards and level
adjustment. It does not silently switch to 18 yards, add bounding sizes or invent
per-species values based on comments in another server's code.

## Circle inclusion is not social aggro

VMaNGOS handles assistance separately. Its decisions can depend on assistance
radius/configuration, faction compatibility, assistance flags, existing combat,
crowd control, NPC react state and AI scripts. Therefore a red NPC inside another
NPC's proximity-aggro circle is not sufficient proof that attacking the first
will pull it. The requested new button implements geometric inclusion and labels
it as such. It does not fabricate a confirmed pull graph.

## Route to an authoritative result

The dependable route is cooperation from OctoWoW's server maintainers:

1. Confirm the actual realm's current core/configuration and how it converts
   aggro distance into a player-position boundary.
2. Have the server compute that boundary for a specific live NPC GUID and the
   requesting player's current level, auras, state and map.
3. Return a server-approved addon response containing NPC/player identity,
   radius/distance convention, computation time and state/version information.
   Include assistance candidates separately if exact extra pulls are wanted.
4. Invalidate/recompute after relevant NPC/player state changes. Hide an
   authoritative label when the response is unavailable or stale.
5. Validate rendered ring geometry against known positions, then validate the
   server boundary on a non-Hardcore test character in controlled conditions.

No message was sent to maintainers and no server changes were attempted. The
current build has no active request/feed because no such approved interface was
identified. A server dump could support a better documented prediction, but
static values alone would not resolve live auras or scripted behaviour.

Passive observation of aggro can provide an interval, not millimetre accuracy:
NPC/player movement, update intervals and latency separate the server's decision
from the client's observation. Do not deliberately approach/pull mobs on the
user's Hardcore character to calibrate the addon.
