# OctoAggro 0.8.1 — Vanilla overhead skulls

Select a hostile NPC. The client uses its own overhead raid-marker drawing path
to draw a local skull on the selected enemy and up to 31 possible nearby assists.
The estimate uses Possible-assist distance (default 10 yards), not server pull links.
No nameplates are required. No targeting, spells, movement or raid assignments change.
Existing real raid markers take priority over the local skull.

The 0.7 screen-overlay renderer was removed: no fixed-height world projection,
custom icon frames or screen placement timer remains. The active skull now uses
Vanilla's built-in atlas and model attachment point. The earlier imagegen artwork
is retained under Textures for reference and rollback; it is not the active marker.

First-use migration from old glow builds disables body glow and always circles.
/oa opens settings. /oa markers toggles local skulls. /oa status checks bridge readiness.

## Install
Close WoW completely and run tools/Install.ps1 -GamePath W:\Games\Octowow.
Full restart is required. /reload cannot load the new protocol-6 native DLL.
Installer snapshots the old addon and loader and checks backup and installed hashes.
Restore.ps1 restores its snapshot if installed files have not changed.
The parent output directory contains a one-time wait-for-close installer and status.

## Verification
10 native-marker Lua groups, 18 ring groups and 8 aggro-model groups pass in Lua 5.0.
The x86 DLL builds. Tests execute the production marker decision function and
stdcall hook with a fake original lookup, checking simultaneous skulls, preservation
of all real marker types, caller isolation, GUID separation, expiry and tick wrap.
The production circle regression and unsupported-host rejection also pass.

The exact client's native renderer obtains the attachment via CGUnit::608640:
model attachment 18/29 when available, otherwise model-height/scale fallback.
Native marker selection is intercepted only at identified rendering call sites.
The server's eight GUID slots and gameplay/API marker lookup results are untouched.
Requests refresh every 250 ms and expire after 750 ms if Lua stops refreshing.

Actual in-game appearance, depth/occlusion, compatibility and frame-time impact
remain UNVERIFIED for this build until a full restart and live observation.
Supported executable SHA256:
5014ca1cfedf860f10e93fe7d955c56c28eb11a2bb503030dbb9b1c777f00470

## 0.8.1 near-range cache repair

0.8.0 did not refresh the native nameplate's cached raid icon when a local request
was enabled, renewed or removed. The world marker renderer deliberately skips
units which have a native nameplate, so those units could have neither visible path.
The new build calls CGUnit's native raid-icon updater 0x608A90 after map updates.
Removal, expiration and global clear erase the request before refreshing, restoring
any real marker. Renewals also handle nameplates created since the previous scan.
The production cache regression reproduces the stale-plate discrepancy and verifies
enable, renewal, removal, late plate creation and preservation of real raid marks.
Native build 801 is shown in /oa status. Live consistency remains unverified.
