# Kino Challenge Configurator (Plutonium T5)

Host-side GSC mod for Black Ops / Plutonium T5 Zombies. It runs only on Kino der Toten (`zombie_theater`) and opens a host-controlled challenge menu before round 1 starts spawning zombies.

**Validation:** the user reported the diagnostic working. Controller support in the full menu still needs an in-game test.

## Optional compile diagnostic

With the match closed, temporarily copy `diagnostics/kino_challenges.gsc` over the installed `kino_challenges.gsc` at the path below. Keep that exact filename so the diagnostic uses the same script path. The full source remains in `scripts/sp/zom/kino_challenges.gsc` in this project; do not install both versions together.

Start a fresh Kino match. The diagnostic should print `[KINO PROBE] init entered` in the console, then `direct local call passed` and `local callback passed` in the console and on screen after spawning. It uses the supplied working script's connection/spawn sequence without modifying rounds or killing zombies.

If it fails, capture the first error and the preceding script-loading lines. If it succeeds, that establishes that local calls and callbacks work in this installed module; investigate the full mod's dependencies next. Restore the full source after the diagnostic. Passing the diagnostic does not validate the challenge menu or enforcement.

## Included rules

- No Jug
- No Perks
- No Power
- No Pack-a-Punch
- No Mystery Box
- No Thunder Gun
- Starting Room Only
- Wall Weapons Only
- Random N Rules (choose 1–8 random restrictions, or 0 to use manual choices)

`Wall Weapons Only` disables the Mystery Box and leaves stock `weapon_upgrade` wall-buy triggers untouched. `Random N Rules` deliberately replaces manual selections with exactly N randomly selected rules when the host starts the match.

## Install

1. Close a running Zombies match.
2. Copy [kino_challenges.gsc](scripts/sp/zom/kino_challenges.gsc) to:

   `%LOCALAPPDATA%\Plutonium\storage\t5\scripts\sp\zom\kino_challenges.gsc`

3. Start or restart a private/dedicated Kino der Toten game. The host/server needs the file; clients do not need to install it. The rules HUD is a server HUD and is shown to all connected players.
4. In the pre-round menu, the host uses:

   - **D-pad up/down** — previous/next entry, wrapping at either end.
   - **D-pad left/right** — turn a rule off/on, or decrease/increase Random N (wrapping through 0–8).
   - **A** — toggle a rule, increase Random N, or select **START GAME**. Press A again to confirm starting.
   - **B** — cancel start confirmation and return to editing. At the root menu it does nothing, preserving the pre-game pause and selections.

   Keyboard/mouse still supports Attack for next, Aim Down Sights for previous, and Use for select/confirm. Melee or Stance cancels confirmation. Other players receive the live rule display but have no menu input listener. After confirming **START GAME**, the configuration is locked for that match.

The D-pad and A bindings were checked against this installation's `players/config.cfg`: `+actionslot 1/2/3/4` and `+gostand`. B currently maps to `+melee`; the menu also accepts `+stance` for the Default layout. These are command listeners, so the corresponding keyboard keys and stick button can also trigger them. Custom remaps must use the same commands. No controller bindings are changed, and no input polling thread is added. The listener returns when starting the game.

Use `map_restart` from the game console after updating the script, or end and recreate the match. Remove the installed file to return to normal Kino.

## Design notes

The script delays the stock `maps\_zombiemode::round_start()` through its documented `level.round_prestart_func` callback. It applies selected rules before stock code sets `begin_spawning`, then locks the choice.

Rules are registered in `kinoRegisterRules()`. To add one, add a `kinoAddRule("key", "Label")` line there and a corresponding action in `kinoApplyRule()`; the menu, Random N picker, locked HUD, and application pass automatically include it.

The script uses `init()` like the supplied working Zombies extension, and `::kinoChallengePrestart` is a direct local callback. Entry-point selection does not by itself explain a compile-time unresolved function. `maps\_zombiemode_utility` supplies `disable_trigger`; `maps\_hud_util` supplies the font, positioning, and HUD cleanup helpers. Ordinary local calls are retained; changing function capitalization is not a demonstrated fix.

Restrictions are one-time changes to stock interaction/state rather than continuous player polling:

| Rule | Stock target/state used |
| --- | --- |
| No Jug / No Perks | `zombie_vending` triggers; Jug is `specialty_armorvest` |
| No Power | `use_elec_switch` trigger |
| No Pack-a-Punch | `zombie_vending_upgrade` triggers |
| No Mystery Box | `treasure_chest_use` triggers |
| No Thunder Gun | `level.zombie_weapons["thundergun_zm"].is_in_box` |
| Starting Room Only | `zombie_door` and `zombie_debris` triggers |

Those names and the round prestart callback were verified against the public [Plutonium T5 scripts](https://github.com/plutoniummod/t5-scripts), specifically Kino's `maps/zombie_theater.gsc` and the shared Zombies scripts.

## Verification checklist

- Launch `zombie_theater`; confirm the configuration HUD appears before zombies spawn.
- Connect a second player; confirm they see the HUD but cannot move its cursor or change values.
- Select each restriction separately and verify the corresponding stock use prompt is unavailable.
- Select Random N and confirm the final rules HUD lists exactly N active restrictions.
- Start the game and confirm neither host nor clients can reopen or modify the menu.
- On controller, verify all four D-pad directions, A toggling, B cancelling start confirmation without losing selections, and A confirming start. Verify a client's controller cannot edit the host's menu.
