# OctoAggro 0.5.0 — automatic per-NPC aggro model

New: automatic lookup of 12,751 named NPC templates from the pinned Tortoise/Turtle
reference database, replacing the blanket base of 20 yards. Live levels and
visible simple detection-range aura effects are folded into the server formula.
Unknown IDs/name mismatches use fallback 18; unknown live levels give no radius.
Existing saved generic bases migrate automatically. Base +/- now changes only
the unknown-NPC fallback, not the automatically selected template.

`/oa target` explains source, NPC base, aura adjustment and missing inputs.
See DATA-SOURCES.md. OctoWoW's deployed template/configuration parity is not
confirmed. Native drawing code is unchanged from 0.4.0.

This build enlarges the **existing game selection ring**. The rejected 0.2.0
custom world-line renderer has been removed, including its textures, camera
projection, terrain queries and per-frame Lua drawing. The addon has no radar,
HUD or nameplate decorations. `/oa` opens settings.

## What changed

The native bridge intercepts the client's existing selection-ring draw function
at `0x608e00`. During that function only, the circle-size input at `CGUnit+0xcf0`
is replaced with `requestedRadius / objectScale`. The original draw routine
handles its texture, position, camera and ground geometry. The original input
is restored byte-for-byte on return. No model-scale, bounding-radius descriptor,
combat-reach descriptor or targeting changes are made by this hook.

**Always-visible circles** is a separate in-game checkbox. When enabled, the
bridge calls the same native circle drawer for up to 12 observed red NPCs during
the engine visual-update stage, without selecting them. Selected NPCs are not
drawn twice. When disabled, only the normal game selection ring is enlarged.
The normal ring texture and colour are retained. Moving and rotating do not
require Lua to recreate ring segments. Request updates run four times a second;
the native renderer follows the unit at its own rendering rate. Requests expire
after 750 ms without refresh.

Mouseover body glow and nearby possible-assist glow are retained from the prior
build. These use a separately owned native highlight reason and are independently
switchable. Actual native colour and appearance still need live verification.

## Accuracy and live-test boundary

The aggro radius remains a source-derived prediction: per-NPC reference base,
live level difference and visible simple aura modifiers. Possible assists remain a geometric
heuristic with default radius 10 yards. Actual OctoWoW server detection, auras,
linked packs and scripts are not available. No complete pull graph or millimetre
accuracy is claimed. Unknown hostile levels and neutral mobs are not assigned
an invented proximity radius.

The user reported that 0.3.0 native-ring drawing worked acceptably, while the
aggro estimate did not exactly match real aggro. This is evidence for the prior
live drawing path, not verification of the new always-visible mode.

The 0.2.0 renderer was rejected after the user reported extreme lag and supplied
images showing broken/incorrect ground placement. The current build retains removal of that drawing path.
This proves removal in code, **not** a measured FPS improvement or perfect terrain
behaviour. A large native ring can still interact differently with steep slopes,
caves and overhangs. The actual game's draw function, hooking coexistence and
new always-visible appearance have not been tested live for this build.

## Install and test

Requires the exact inspected 32-bit OctoWoW 1.12.1.5875 executable, ClassicAPI and
VanillaFixes. Supported WoW.exe SHA-256:
`5014ca1cfedf860f10e93fe7d955c56c28eb11a2bb503030dbb9b1c777f00470`.
The bridge rejects other fingerprints before installing hooks.

Close WoW and run from this repository folder:

```powershell
.\tools\Install.ps1 -GamePath 'W:\Games\Octowow'
```

The installer backs up the current addon and dlls.txt, copies eight hash-verified
files and ensures exactly one loader entry:

```text
Interface/AddOns/OctoAggro/native/OctoAggroNative.dll
```

It does not replace WoW.exe, ClassicAPI, UnitXP or graphics DLLs. Restart via the
normal launcher and enable OctoAggro in the AddOns list. Enable enemy nameplates
for observing nearby possible assists. Commands: `/oa`, `/oa on`, `/oa off`,
`/oa toggle`, `/oa status`.

For the first live test, select an already visible hostile NPC at a safe distance
and compare the native ring with rings enabled/disabled in `/oa`. Move/rotate only
in a known safe area; inspect smooth following, terrain and responsiveness. Do
not pull NPCs to validate estimates on a Hardcore character. `/oa off` clears
addon-owned radius/glow requests. A full restart is mandatory for DLL updates;
`/reload` alone continues using the previously loaded native binary.

With WoW closed, `tools/Restore.ps1 -GamePath ... -BackupPath ...` restores the
installer snapshot. It refuses to overwrite files changed since installation.

## Repository URL installation

Publish this folder's **contents at the repository root**, preferably in a
repository named `OctoAggro`. Lua, prebuilt x86 DLL, native source, MinHook source
and license, installer, restore tool and tests are included. No upload or remote
is configured. A compatible repository installer can clone the addon; native
activation still requires the one-time installer step:

```powershell
git clone https://github.com/YOUR_ACCOUNT/OctoAggro.git 'W:\Games\Octowow\Interface\AddOns\OctoAggro'
& 'W:\Games\Octowow\Interface\AddOns\OctoAggro\tools\Install.ps1' -GamePath 'W:\Games\Octowow'
```

The URL is a placeholder. After activation, the DLL is inside the checkout and
can be updated with the repository. Close WoW before updating. Actual GitHub URL
installation is not verified before publication.

## Build and tests

`tools/Build.ps1` rebuilds the x86 DLL with Visual Studio C++ tools and a static
runtime. `lua tests/test_native_ring.lua` runs the shipped Lua against a narrow
mock. `tests/test_circle.cpp` executes the actual production circle hook with a
fake native draw callback and verifies the temporary size and restored bytes.
`tests/test_host.cpp` verifies rejection in an unsupported host.

## Evidence

The exact installed executable's `CGUnit` vtable points slot `+0x30` at `0x608e00`.
Its disassembly computes the ring bounds from `CGUnit+0xcf0` multiplied by the
descriptor scale at `+0x10`, then invokes the native textured ground drawing path.
Only that draw function receives a scoped size override. No use is made of the
generic model transform at `0x614cd0`, which would risk enlarging the NPC model.
Client-call conventions were checked against the inspected executable and
[ClassicAPI](https://github.com/brues-code/ClassicAPI). The aggro formula remains
a reference from [VMaNGOS](https://github.com/vmangos/core/blob/development/src/game/Objects/Creature.cpp),
not proof of OctoWoW server rules. See VERIFICATION.md.
