# T5 DVAR Reference

This guide categorizes the `dvarlist` capture provided on 2026-09-15 for Call of Duty: Black Ops / Plutonium T5. It is a practical reference for the Kino Challenge Configurator, not a recommendation to modify the listed values.

The capture identifies itself as the multiplayer executable (`version` contains `COD_T5_S MP`), with `spmode`, `zombiemode`, and `mapname` all inactive. A DVAR's presence in this list does not establish that it is meaningful, writable, or honored during a Zombies match.

## DVARs Are Not `zombie_vars`

Console DVARs and `level.zombie_vars` are different data stores:

- **DVAR:** engine/configuration setting, queried or written through `GetDvar*` and `SetDvar*`.
- **`level.zombie_vars`:** a server-side GSC array populated by the stock `maps\_zombiemode` scripts with map/difficulty values. It is accessed with normal array indexing, not console commands.

The supplied dump has no `zombie_*` console DVARs. That absence is expected and does **not** invalidate the similarly named runtime entries below.

| Mod state | Store | Evidence and expected behavior |
| --- | --- | --- |
| `zombie_spawn_delay` | `level.zombie_vars` | Stock Zombies GSC value. Default is `2.0`; the stock round loop reduces it by `0.95` per round down to `0.08`. Escalation replaces that curve. |
| `zombie_move_speed_multiplier` | `level.zombie_vars` | Stock Zombies GSC value. Default is `8`; stock calculates the next round's base from round number times this multiplier. Escalation changes it to `10` or `12`. |
| `zombie_between_round_time` | `level.zombie_vars` | Stock Zombies GSC value. Default is `10`; the mod reads it to calculate the shortened round-display delay. |
| `zombie_perk_juggernaut_health` | `level.zombie_vars` | Stock perk-health value read by the Health boon. It is not a console DVAR. |
| `zombie_perk_juggernaut_health_upgrade` | `level.zombie_vars` | Stock upgraded-Juggernog health value read by the Health boon. It is not a console DVAR. |
| `zombie_ai_limit` | `level` field plus `SetAILimit()` | Not a DVAR and not a `zombie_vars` member. Stock initializes it to `24`; Escalation sets `26`, `28`, or `30`. |

The first three defaults and their stock update behavior are defined in the public T5 `maps\_zombiemode.gsc` source described in [t5-sources.md](t5-sources.md). The two Juggernog values remain stock-owned runtime values; verify them against the exact installed build before treating their numeric values as a stable contract.

## Mod-Relevant Console DVARs

Only these DVARs from the capture are directly written by this mod. They are used by the Sprint boon, not Escalation.

| DVAR | Captured default | Purpose | Mod usage |
| --- | --- | --- | --- |
| `player_sprintUnlimited` | `0` | Enables unlimited sprint. | Set to `1` for a player when Sprint is `Unlimited`. |
| `player_sprintTime` | `4` | Normal player sprint duration. | Set to `999999` with unlimited sprint. |

The related `player_sprintCameraBob`, `player_sprintForwardMinimum`, `player_sprintMinTime`, `player_sprintRechargePause`, `player_sprintSpeedScale`, `player_sprintStrafeSpeedScale`, and `player_sprintThreshhold` affect the player movement system. They are not used by this mod and are poor substitutes for zombie pacing.

## Complete Prefix Map

Every item in the supplied dump is covered by one of these families. A wildcard denotes every captured DVAR beginning with that prefix; singleton names are listed exactly. This is more useful than a flat alphabetical dump because it makes the runtime owner and mod relevance explicit.

| Family in capture | Owner / category | Kino relevance |
| --- | --- | --- |
| `ai_*`, `acousticSpike*`, `g_connectpaths` | Generic engine AI, acoustic sensing, and debugging. | No known safe use for Zombie pacing. |
| `bg_*`, `dtp_*`, `jump_*`, `mantle_*`, `prone_*`, `friction`, `stopspeed` | Shared movement, animation, physics, and traversal tuning. | Not used. Altering these changes player or global movement rather than Zombies rules. |
| `player_*`, `perk_*`, `revive_time_taken`, `defaultDamage*`, `defaultHitDamage` | Player, perk, damage, and revive mechanics. | Only the two sprint DVARs above are used. The rest are outside this mod's rules. |
| `dog_*`, `scr_dog_*` | Multiplayer killstreak dog behavior. | Useless for Zombies dog rounds; those are controlled by stock Zombies GSC. |
| `cg_*`, `hud_*`, `hudElemPausedBrightness`, `lowAmmo*`, `waypoint*`, `compass*`, `actionSlotsHide`, `ammoCounterHide`, `team_indicator` | Client HUD, camera, reticle, display, and accessibility presentation. | Cosmetic/client-only. Do not use for server-side rules. |
| `r_*`, `sm_*`, `fx_*`, `flare*`, `flame*`, `wind_*`, `tree_*`, `water*`, `facepaintLodDist`, `hiDef`, `wideScreen`, `vid_*` | Renderer, lighting, effects, materials, weather, and video settings. | Visual-only or engine diagnostics; useless for gameplay rules. |
| `snd_*`, `voice_*`, `winvoice_*`, `footstep_*` | Audio mixer, voice, sound debugging, and footsteps. | Not used. |
| `cl_*`, `sv_*`, `net_*`, `band_*`, `rate`, `reliable*`, `packet*`, `showpackets`, `showdrop`, `snaps`, `protocol` | Client/server networking, bandwidth, timing, and packet diagnostics. | Useless for a local Zombies rules mod; changing them can destabilize networking. |
| `fs_*`, `useFastFile`, `g_loadScripts`, `sv_referenced*`, `sv_iwd*` | Filesystem, asset loading, FastFile, and server content bookkeeping. | Installation/debug infrastructure only. Do not change from gameplay code. |
| `con_*`, `log*`, `developer`, `developer_script`, `debug*`, `draw*`, `dump*`, `msg_*`, `profile_*`, `script_debugger_smoke_test` | Console behavior, logging, developer tools, and diagnostics. | Useful for investigation only. They do not configure Zombie rules. |
| `ui_*`, `uiscript_debug`, `uiViewer_*`, `uiviewer_*`, `com_desiredMenu`, `activeAction`, `category*`, `selected*` | Front-end/menu state and UI viewer configuration. | Unrelated to the mod's custom server HUD. |
| `m_*`, `in_mouse`, `input_*`, `sensitivity`, `gpad_*` | Mouse, keyboard, and controller input. | The mod listens for bound commands; it does not need these DVARs. |
| `demo_*`, `nextdemo`, `cl_demo*` | Theater/demo recording and playback. | Useless for challenge behavior. |
| `phys_*`, `ragdoll_*`, `dynEnt_*`, `dynEntPieces_*`, `vehicle_*`, `veh*`, `turret_*` | Physics, ragdolls, dynamic entities, vehicles, and turrets. | Not a reliable way to alter standard Zombie AI. |
| `xblive_*`, `dw_*`, `steamid`, `live_*`, `friends*`, `invite*`, `clan*`, `lb_*`, `stats_*`, `counter*` | Online services, identity, friends, leaderboards, and stats. | Useless for local challenge rules. Never document or expose account values from a capture. |
| `zombiemode`, `zombiefive_*`, `zombieStopSplitScreen`, `zombietron*`, `spmode`, `blackopsmode`, `arcademode`, `legacy_zombiemode`, `monkeytoy` | Mode-selection, legacy mode, or feature-presence flags. | They are not tuning controls and do not replace Zombies script state. |
| `g_*`, `scr_*`, `koth_*`, `twar_*`, `bot_*`, `party_*`, `playlist*`, `wager*`, `custom_class_*`, `custom_killstreak_*`, `customGameMode`, `customclass*`, `prestigeclass*`, `barebones_*`, `attachmentFilter` | Multiplayer match, game-type, bot, party, progression, Create-a-Class, and wager configuration. | Multiplayer-only and useless for this Zombies-only mod. |
| `scr_dm_*`, `scr_tdm_*`, `scr_ctf_*`, `scr_dem_*`, `scr_dom_*`, `scr_koth_*`, `scr_oic_*`, `scr_sab_*`, `scr_sd_*`, `scr_shrp_*`, `scr_hlnd_*` | Individual multiplayer game-mode rules. | Multiplayer-only and useless. |
| `dedicated`, `onlinegame`, `session_*`, `sv_dedicatedmaxclients`, `sv_private*`, `password`, `rcon_password`, `server*`, `quickmatch_*`, `matchmaking_*` | Hosting, session, private-server, and matchmaking settings. | Useless for challenge mechanics. Treat password fields as sensitive even when empty. |
| `sys_*`, `systemUiActive`, `com_*`, `fixedtime`, `timescale`, `long_blocking_call`, `waitForStreamer`, `version`, `shortversion` | Engine, platform, build, timing, and startup state. | Diagnostics only. `timescale` is a test aid, not a gameplay setting. |
| `allEmblems*`, `allItems*`, `emblem_*`, `collectors`, `dec20_Enabled`, `eventMessageLastFetchTime`, `codMessageLastFetchTime`, `notice_*`, `statusinfo_*` | Legacy UI, unlock, event, and storefront metadata. | Useless. |
| `bodyTypeFromGun`, `bulletrange`, `bullet_*`, `penetrationCount*`, `primaryWeaponOffset`, `weapon*`, `attachmentFilter` | Generic weapon and bullet presentation/tuning. | Not used by the challenge rules. |
| `dive_*`, `nightVision*`, `overrideNVGModelWithKnife`, `nightVisionDisableEffects`, `showVisionSetDebugInfo` | Specialized movement and vision features. | Unrelated to Kino Zombies progression. |
| `mapname`, `ui_mapname`, `ui_currentMap`, `nextmap`, `sv_mapRotation*`, `compassCoords` | Map selection, rotation, and map presentation. | The mod independently guards `level.script == "zombie_theater"`. |
| `name`, `motd`, `scr_motd`, `sv_hostname`, `sv_noname` | Displayed player/server text. | Not gameplay controls. The captured player name should not be copied into documentation. |

## Multiplayer-Only DVARs

The following groups are intentionally documented only to rule them out. This project does not target multiplayer, so they are **useless for this mod**:

- All `scr_<mode>_*` entries controlling Deathmatch, Team Deathmatch, Capture the Flag, Demolition, Domination, Headquarters, One in the Chamber, Sabotage, Search and Destroy, Sharpshooter, and Team Warfare.
- `g_*` multiplayer match controls, `bot_*`, `party_*`, `playlist*`, `matchmaking_*`, and `quickmatch_*`.
- `custom_class_*`, `custom_killstreak_*`, `custom_perks_*`, `customGameMode`, `customclass*`, `prestigeclass*`, and `perk_*` multiplayer loadout systems.
- `koth_*`, `twar_*`, `wager*`, `xblive_*`, `dw_*`, and multiplayer leaderboard/session settings.
- `scr_hardcore`, `scr_oldschool`, `scr_team_*`, `scr_player_*`, and related respawn/score-limit controls.

Some names are shared engine plumbing and may exist in a Zombies process, but the stock Zombies scripts do not use them as the source of challenge difficulty. Do not infer applicability from a DVAR name alone.

## Safe Investigation Workflow

1. Check whether a value is read through `level.zombie_vars`, `level.<field>`, or a `GetDvar*` call before changing it.
2. For a suspected Zombies variable, inspect the matching target-build stock script named in [t5-sources.md](t5-sources.md), not just `dvarlist`.
3. Keep challenge mechanics in the pre-round GSC path. Use console DVARs only when the target script demonstrably reads them.
4. Validate gameplay changes in a fresh Kino match. A DVAR dump cannot prove GSC behavior or a value's mutability.

## Current Conclusion

The `zombie_vars` used by the Kino mod are not hallucinated console DVARs. They are stock GSC runtime values. The dump confirms that searching the console-DVAR namespace is the wrong way to validate them. It does, however, confirm the two `player_sprint*` DVARs used by the Sprint boon and rules out a hidden console DVAR for the mod's zombie spawn, speed, horde-limit, barricade, or round-cooldown behavior.