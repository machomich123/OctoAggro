# OctoAggro 0.5.0 verification — 2026-10-13

Current model verification:

- Parsed 12,751 upstream template rows. Independently fetched the pinned source
  and checked its SHA-256 against the parsed source. UTF-8 deterministic rebuild
  was run twice with identical generated output.
- Eight automatic-model groups passed in actual Lua 5.0.3, including loading the
  entire generated dataset, Vile Familiar 12-yard base, level changes, range floors,
  level-difference cap, multiplier, Soothe, player modifiers, stacks, ID/name reuse,
  missing aura APIs, random magnitudes and stealth.
- Sixteen retained native-ring Lua groups passed with the new model loaded.
- Installed ClassicAPI binary contains the names of GetUnitAuras,
  GetSpellEffectInfo, GetSpellDescription and UnitCreatureID. String presence is
  not live-registration or observed-aura proof.
- Native DLL code and protocol are unchanged from 0.4.0. No additional native
  drawing hook or terrain tracing was added for the automatic calculation.
- Source-derived calculations do not verify OctoWoW template/config parity.
  Actual range and live aura behavior still need a controlled game test.

Earlier drawing verification and history:

The previous 0.2.0 build failed the user's live visual/performance test: reported
extreme lag, broken rings and ground clipping. That is the concrete reason for
replacing its rendering path.

The user subsequently confirmed 0.3.0's native ring behaved acceptably in-game,
but reported a mismatch with actual aggro range. This does not verify 0.4.0's
new always-visible draw dispatch or establish an exact radius.

Confirmed for the current build:

- Disassembled the actual client selection-circle draw at 0x608e00 and its
  CGUnit vtable entry. Its radius input is CF0 multiplied by descriptor scale.
- Removed the rejected Lua texture renderer and native surface/project APIs.
  No ring terrain rays, per-point projection or ring line textures remain.
- Sixteen Lua test groups passed in actual Lua 5.0.3. Tests cover startup, the new
  protocol, zero custom ring textures, requests, switches, stale state, disabled
  scans and a four-per-second scan limit. Calling the rejected APIs raises test
  errors; no calls occurred.
- New checks exercise both settings buttons, no-selection operation, independent
  geometric highlighting, neutral exclusion, circle boundary and vertical-floor
  filtering, twelve-circle cap, target inspection and protocol migration.
- Compiled and executed tests/test_circle.cpp against the actual production hook.
  Three object scales produced the requested radius during the fake draw.
  All object and descriptor bytes matched their originals after the callback.
  Expired/missing requests and invalid scales passed through unchanged.
- The production extra-circle dispatch was exercised with a fake native draw:
  unselected requested NPCs drew, selected duplicates did not, and disabled or
  expired mode/request state did not draw. The 0x614a90 ABI was inspected in the
  actual client. Its live hook and draw staging remain unverified.
- Built x86 DLL with static runtime. The unsupported x86 host rejected it before
  installing hooks (Load returned 1).

Not verified for 0.4.0: always-visible drawing in a running game, new-hook
coexistence or its frame-time cost. The mock draw is not a native game rendering
test. Aggro boundaries and possible assists remain estimates. Exact-range
research is in EXACT-AGGRO-RESEARCH.md.

Installed six hash-verified files. Snapshot: W:\Games\Octowow\AddonBackups\OctoAggro-world-20261013-130229-169. Existing loader entries retained; one bridge entry. No game session launched.

0.4.0 installed: six hash-verified runtime files; snapshot W:\Games\Octowow\AddonBackups\OctoAggro-world-20261013-154046-694. Existing loader retained. No game controlled or launched.

0.5.0 deployment: 8 hash-verified runtime files. Install/restore exercised on a disposable client copy. Backup: W:\Games\Octowow\AddonBackups\OctoAggro-world-20261013-161604-360. No game launched or controlled.
