# Verification — 2026-10-13

## Confirmed offline

- Built OctoAggroNative.dll as x86 with MSVC 2022, static runtime.
- Inspected the exact installed WoW.exe fingerprint and disassembled the native
  highlight set/clear path from the engine's mouseover implementation.
- The compiled DLL loaded in a separate x86 host and `Load()` returned 1 for
  unsupported executable identity. That host was placed at image base 0x400000
  so the test also exercises executable-fingerprint rejection.
- Fourteen Lua test groups passed in the actual Lua 5.0.3 interpreter, executing
  the shipped World.lua and Settings.lua with mocked engine functions.
- Test cases cover world-coordinate circle radius, body-highlight requests,
  removal on lost hover/despawn, disabled state, independent switches, neutral
  and unknown-level NPCs, missing rendering bridge, missing ground intersections,
  occluded projection results, terrain caching, world transitions and ring cap.
- The PE binary is x86 (`0x14c`), exports `Load`, and imports only bcrypt.dll and
  KERNEL32.dll. The MSVC runtime is linked statically.
- Installation and full restore were exercised on a disposable directory with
  the actual client executable. Restored dlls.txt matched its original hash.
- The local client installation received six hash-verified files and exactly one
  new loader entry. Existing loader entries were retained. Backup:
  `W:\Games\Octowow\AddonBackups\OctoAggro-world-20261013-122857-051`.
  No game session was launched or controlled.

## Not established by these checks

The native world engine functions were not exercised inside a running WoW world.
The simulated projector does not prove the native camera ABI. The unsupported-host
test does not exercise supported-client hooks. Live hook coexistence, exact body
glow appearance, ground alignment, occlusion and frame-time cost remain unverified.
No guaranteed server aggro boundary or assistance graph is available. No
millimetre-accuracy claim is made.

This is a staged world-rendering test build. It is not a confirmed complete addon.
