# OctoAggro 0.3.0 verification — 2026-10-13

The previous 0.2.0 build failed the user's live visual/performance test: reported
extreme lag, broken rings and ground clipping. That is the concrete reason for
replacing its rendering path.

Confirmed for 0.3.0:

- Disassembled the actual client selection-circle draw at 0x608e00 and its
  CGUnit vtable entry. Its radius input is CF0 multiplied by descriptor scale.
- Removed the rejected Lua texture renderer and native surface/project APIs.
  No ring terrain rays, per-point projection or ring line textures remain.
- Eleven Lua test groups passed in actual Lua 5.0.3. Tests cover startup, the new
  protocol, zero custom ring textures, requests, switches, stale state, disabled
  scans and a four-per-second scan limit. Calling the rejected APIs raises test
  errors; no calls occurred.
- Compiled and executed tests/test_circle.cpp against the actual production hook.
  Three object scales produced the requested radius during the fake draw.
  All object and descriptor bytes matched their originals after the callback.
  Expired/missing requests and invalid scales passed through unchanged.
- Built x86 DLL with static runtime. The unsupported x86 host rejected it before
  installing hooks (Load returned 1).

Not verified: actual native drawing, live hook coexistence, ring appearance on
slopes, or frame-time improvement in a running game. The mock draw is not a native
game rendering test. Aggro boundaries and possible assists remain estimates.

Installed six hash-verified files. Snapshot: W:\Games\Octowow\AddonBackups\OctoAggro-world-20261013-130229-169. Existing loader entries retained; one bridge entry. No game session launched.
