# OctoAggro 0.2.0 — world-rendering test

This replaces the rejected radar design. There is **no radar, HUD, NPC list or
nameplate decoration**. Only `/oa` opens a settings panel.

## Implemented design

- A red circular outline surrounds observed hostile NPCs **in the game view**.
  Its points are computed in world yards around the NPC, traced onto nearby
  world geometry and projected through the real game camera. It is not a fixed
  screen-size circle or an enlarged icon.
- Hovering an NPC applies the client's own model highlight to it and to observed
  nearby potential assists. No target switching is involved. The native engine
  determines the highlight colour; live appearance is not yet verified against
  the supplied screenshots.
- Native highlight ownership uses its own bit (reason 30), leaving the game's
  target/mouseover reasons intact. A 750 ms expiry clears it if Lua stops refreshing
  it. Loss of hover, disable, despawn, Lua reinitialisation and world transitions
  clear addon-owned highlights.
- Settings separately control all visuals, rings and body glow. The base aggro
  estimate and possible-assist distance can be adjusted.

## Exactness and remaining uncertainty

**This is an experimental client-extension build, not a verified live-game result.**
The visible radius is an estimate. The default base is 20 game yards, adjusted by
level difference using a VMaNGOS reference formula. OctoWoW's actual server rules,
detection auras, multipliers and NPC scripts are not known. The 10-yard default
assist distance is a geometric heuristic. Being inside it does not prove that an
NPC will assist; being outside it does not prove that it will not. There is no
millimetre accuracy or complete prediction of which NPCs an attack pulls.

Only target, mouseover and accessible nameplate NPCs are observed. Up to twelve
nearest observed hostile NPCs within 60 yards get rings, with mouseover prioritised.
Their rings have 64 segments. Terrain sampling occurs about twice a second,
projection about 20 times a second, and camera obstruction checks about 7 times
a second. This is not pixel-perfect depth-buffer rendering: partially obscured
segments, near-screen edges, slopes, caves, overhangs and multiple floors require
live visual testing. Missing hits and off-screen endpoints are not fabricated.

## Requirements

- The **exact** inspected 32-bit OctoWoW client at build 1.12.1.5875. Supported
  WoW.exe SHA-256:
  `5014ca1cfedf860f10e93fe7d955c56c28eb11a2bb503030dbb9b1c777f00470`.
  The DLL refuses other executable fingerprints before installing hooks.
- VanillaFixes with `dlls.txt` and the installed ClassicAPI texture transformations,
  UnitPosition and UnitGUID functions. This is not an addon for official WoW.
- Enemy nameplates enabled for observation of nearby NPCs.

## Local installation

Close WoW, then run from this repository folder:

```powershell
.\tools\Install.ps1 -GamePath 'W:\Games\Octowow'
```

The installer checks the exact client hash and that the client is closed,
backs up `dlls.txt` and an existing addon, installs six files with hash checks,
and adds **one** loader entry:

```text
Interface/AddOns/OctoAggro/native/OctoAggroNative.dll
```

It does not replace ClassicAPI, UnitXP, graphics DLLs or WoW.exe. Existing loader
entries are retained. The bridge is stored inside the addon folder so future
repository updates can update its binary too. Restart via your usual launcher.
Enable OctoAggro in the character-screen AddOns list.

Commands: `/oa` for settings, `/oa on`, `/oa off`, `/oa toggle`, `/oa status`.

## First live test

Stand in a familiar open area at a safe distance. Do not pull NPCs to validate
an estimate on a Hardcore character. Check whether circles lie on the ground
around NPCs, remain centred as you turn the camera, and scale with perspective.
Hover a visible NPC and check body highlighting; leave it and check cleanup.
Try `/oa off`, then each independent switch. Check camera/frame responsiveness.
If anything looks wrong, disable with `/oa off` and retain the exact error text.

The offline tests cannot establish that native calls, hook coexistence,
camera projection or highlight appearance work in the actual running client.
**A restart and controlled visual test are still required.**

To disable the native bridge completely, close WoW and remove the one loader
entry above. The remaining Lua addon fails without a substitute radar. A backed-up
`dlls.txt` is available in the installer-reported backup directory; restore it
only if no other loader changes have been made since installation.

## GitHub and installation by repository URL

Publish the **contents of this folder at the root** of a repository named
`OctoAggro`. The root .toc, Lua sources, prebuilt native DLL, native source,
MinHook sources/license, build script and tests are included. No upload has been
performed and no remote is configured.

For a repository installer or a direct git clone:

```powershell
git clone https://github.com/YOUR_ACCOUNT/OctoAggro.git 'W:\Games\Octowow\Interface\AddOns\OctoAggro'
& 'W:\Games\Octowow\Interface\AddOns\OctoAggro\tools\Install.ps1' -GamePath 'W:\Games\Octowow'
```

That URL is a placeholder. A pure Lua repository installer cannot independently
activate a native DLL: **the one-time loader setup above is necessary**.
After that, the binary lives in the git checkout and is updated with it. Close
WoW before updating. An actual GitHub URL installation is not verified until
the repository is published.

## Build and verification

Rebuild with Visual Studio 2022 C++ tools using `tools/Build.ps1` (x86). The
prebuilt DLL uses the static Microsoft runtime and needs no separate runtime
installer. MinHook is vendored with its BSD license.

Run the Lua tests from the repository root with `lua tests/test.lua` using Lua
5.0/5.1. They run actual World.lua and Settings.lua with simulated engine APIs.
See VERIFICATION.md for the exact boundary of the verification.

Sources used to establish client interfaces:

- [ClassicAPI](https://github.com/brues-code/ClassicAPI): object GUID resolver,
  registry guard, native Lua registration and texture corner rotations.
- [UnitXP SP3 mirror](https://github.com/brues-code/UnitXP_SP3), commit
  `cedbf4b59776567db954ce38f681af1cbb9f0e1c`: camera projection and collision ABI.
- The installed WoW.exe: disassembly of `0x492890` (mouseover setter),
  `0x4945e0` (highlight wrapper), `0x614550`/`0x6144f0` (set/clear highlight)
  and `0x66fd50` (world-tick ABI). Disassembly establishes the call structure,
  not live rendering success.
- [VMaNGOS reference aggro logic](https://github.com/vmangos/core/blob/development/src/game/Objects/Creature.cpp):
  heuristic formula only; not confirmed OctoWoW server behaviour.
