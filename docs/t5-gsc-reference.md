# T5 GSC Reference

This is a compact, project-specific reference for the Kino Challenge Configurator. It is not a replacement for the target T5 stock scripts. Facts below are either verified in this repository or must cite their external source.

## Target

- Game/runtime: Call of Duty: Black Ops / Plutonium T5 Zombies.
- Map: Kino der Toten (`zombie_theater`).
- Primary mod: `scripts/sp/zom/kino.gsc`.
- Diagnostic-only script: `diagnostics/kino.gsc`.

## Verified in This Repository

### Script lifecycle

- The mod uses `init()` as its entry point.
- Guard map-specific behavior with `level.script == "zombie_theater"`.
- Use `level.round_prestart_func = ::kinoChallengePrestart;` to run selected restrictions before stock spawning begins.
- The callback is a direct local function reference. Local calls and callbacks compile in the installed module when the diagnostic succeeds.

### Script modules

- The public Plutonium T5 Kino script includes companion map scripts, then invokes their functions with qualified names such as `maps\zombie_theater_magic_box::magic_box_init()`.
- The Kino challenge scripts follow that stock pattern: the entry script includes sibling `scripts\sp\zom\kino_*` modules, and cross-module calls use the same qualified form.
- Source: [Plutonium T5 scripts](https://github.com/plutoniummod/t5-scripts/blob/main/ZM/Maps/Kino%20der%20Toten/maps/zombie_theater.gsc), `ZM/Maps/Kino der Toten/maps/zombie_theater.gsc`, Kino der Toten / public T5 scripts `main` branch.

### Included libraries

```gsc
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;
```

- `maps\_zombiemode_utility` provides `disable_trigger`.
- `maps\_hud_util` provides the font, positioning, and HUD cleanup helpers used by this mod.

### Entities and state used by the current rules

| Feature | Entity or state |
| --- | --- |
| Perks | `zombie_vending` targetname; perk identity in `script_noteworthy` |
| Juggernog | `specialty_armorvest` |
| Power | `use_elec_switch` targetname |
| Pack-a-Punch | `zombie_vending_upgrade` targetname |
| Mystery Box | `treasure_chest_use` targetname |
| Doors and debris | `zombie_door` and `zombie_debris` targetnames |
| Thunder Gun box availability | `level.zombie_weapons["thundergun_zm"].is_in_box` |

### Established local patterns

```gsc
triggers = GetEntArray( "zombie_vending", "targetname" );
triggers[index] disable_trigger();

rule = SpawnStruct();
rule.key = key;
rule.enabled = false;
level.kino_challenge_rules[level.kino_challenge_rules.size] = rule;
```

- Restrictions are applied once before round spawning, rather than through continuous player polling.
- Host input is handled by command listeners; clients only receive the server HUD.
- Rule overlap is maintained as data in `kino_config.gsc`. The menu and active HUD suppress a selected rule only when another selected rule transitively implies it; the underlying selection remains intact.

## Adding Verified Knowledge

Add reusable facts here only after checking the target build's stock scripts or a source listed in `t5-sources.md`. Label the source, target map/build, and relevant script path. Record uncertainty rather than guessing.
