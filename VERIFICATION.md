# Native attachment evidence — 0.8.1

Source: the exact installed W:/Games/Octowow/WoW.exe (fingerprint in README).
- 0x4BB190 is the stdcall reverse raid GUID lookup, returning index 0..7 or 8.
- 0x6C6E90 native per-unit world text/raid-marker rendering resolves the unit GUID.
- 0x6C6F00 calls 0x608640 to obtain the unit model's overhead attachment.
- 0x608640 requests attachment 18 or 29 through 0x712CB0/0x712D50, with model-height fallback.
- 0x6C70A2 calls 0x4BB190, return 0x6C70A7. Native drawing uses the returned skull cell.
- 0x7CB82F and 0x608AA7 call the same lookup for the native nameplate path.
- Other lookup callers, including API callers, retain their original values.
- The engine's GUID table at 0xB71368 is never written by this addon.

The tests verify dispatch/isolation/expiry logic and ABI with a mock trampoline.
Disassembly supports the selected native path; it does not establish live success.
No game input was sent and no game process was terminated for this repair.

Cache defect evidence:
- 0x6C70B2 reads CGUnit+0xE60; a non-null native nameplate skips world icon drawing.
- 0x7CB82F queries the raid icon when binding a unit to a plate, not per local request.
- 0x608A90 re-queries the index and calls 0x7CBE20 to show/hide the plate's raid texture.
- pfUI's installed nameplates module reuses/reparents this native raidicon region.
- 0.8.1 invokes 0x608A90 for active requests, removal, expiry and clear.
The prior document incorrectly described this as a chat-bubble variant; that label
is corrected here. Native marker visibility and cache logic have separate tests.
