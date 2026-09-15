# T5 Zombies Architecture and Modding Hooks

Practical base-game reference for Call of Duty: Black Ops / Plutonium T5 Zombies. It focuses on systems a Kino der Toten (`zombie_theater`) mod can observe or alter from host-side GSC.

The exact installed Plutonium build remains authoritative for implementation details. Use the stock-script workflow in [t5-sources.md](t5-sources.md) before relying on a value for a new feature. Project-specific behavior and known map entity targets are in [t5-gsc-reference.md](t5-gsc-reference.md); console DVAR boundaries are in [dvars.md](dvars.md).

## Script Architecture

The main Zombies scripts divide responsibility by game system:

| Stock script | Main responsibility | Useful modding surfaces |
| --- | --- | --- |
| `maps/_zombiemode.gsc` | Game initialization, round loop, round transitions, active-AI limit | `level.zombie_vars`, `level.zombie_ai_limit`, `SetAILimit()`, round callbacks |
| `maps/_zombiemode_spawner.gsc` | Zombie spawn setup, health, AI spawning | Spawn callbacks, actor state, health and AI setup |
| `maps/_zombiemode_powerups.gsc` | Natural drops, powerup deck, pickup effects | `level.zombie_powerup_array`, `specific_powerup_drop()` |
| `maps/_zombiemode_perks.gsc` | Perk machines, purchases, downing hooks | `give_perk()`, perk identifiers, vending triggers |
| `maps/_zombiemode_weapons.gsc` | Weapon tables and Pack-a-Punch behavior | `level.zombie_weapons`, box eligibility, upgrade behavior |
| `maps/_zombiemode_utility.gsc` | Shared Zombies interactions | Points of interest, trigger and barricade helpers |
| `maps/_zombiemode_score.gsc` | Player score mutation | `add_to_player_score()` |

Use the stock function which owns a behavior rather than adding a polling thread around a symptom. For example, a powerup change belongs in the powerup path, and a pre-round interaction restriction belongs in the round-prestart callback.

## Core Runtime State

`level.zombie_vars` is a server-side GSC table initialized by stock Zombies code. It is not a collection of console DVARs.

| Runtime value | Base value | Role |
| --- | ---: | --- |
| `level.zombie_vars["zombie_health"]` | `150` | Round 1 standard-zombie health baseline |
| `level.zombie_vars["zombie_spawn_delay"]` | `2.0` | Initial delay between zombie spawns |
| `level.zombie_vars["zombie_move_speed_multiplier"]` | `8` | Stock round speed-ramp increment |
| `level.zombie_vars["zombie_point_scalar"]` | `1.0` | Global score multiplier; Double Points uses `2.0` |
| `level.zombie_vars["zombie_drop_item"]` | `1` | Enables normal powerup drops |
| `level.zombie_vars["zombie_between_round_time"]` | `10` | Stock inter-round timing |
| `level.zombie_vars["zombie_perk_juggernaut_health"]` | Stock-owned | Juggernog health target |
| `level.zombie_vars["zombie_perk_juggernaut_health_upgrade"]` | Stock-owned | Upgraded Juggernog health target |

Related state is stored directly on `level`, not in `zombie_vars`:

- `level.round_number`: current round.
- `level.first_round`: stock first-round state.
- `level.zombie_move_speed`: active round speed value.
- `level.zombie_ai_limit`: requested active-AI limit. Stock initializes it to `24` and applies it with `SetAILimit()`.
- `level.zombie_powerup_array` and `level.zombie_powerup_index`: current natural-powerup deck and position.
- `level._zombie_custom_spawn_logic`: optional callback or callback array applied to spawned zombies.

## Rounds and Standard Zombies

### Health progression

Standard zombie health is $150$ on round 1, rises by $100$ per round through round 9, then increases by $10\%$ per round.

$$
H(R) =
\begin{cases}
150 & R = 1 \\
150 + 100(R - 1) & 2 \le R \le 9 \\
\lfloor 950 \cdot 1.1^{R-9} \rfloor & R \ge 10
\end{cases}
$$

| Round | Standard zombie health |
| ---: | ---: |
| 1 | 150 |
| 5 | 550 |
| 9 | 950 |
| 10 | 1,045 |
| 20 | 2,710 |
| 50 | 47,295 |
| 100 | 5,552,108 |

For a health overhaul, identify the target-build spawner function that calculates or assigns health. Do not assume a generic `set_zombie_health()` example is an exported function in every T5 build.

### Round population

For rounds 5 and later, standard-round population uses a player-count multiplier $M$:

| Player count | $M$ |
| ---: | ---: |
| 1 | 0.09 |
| 2 | 0.18 |
| 3 | 0.36 |
| 4 | 0.54 |

$$N(R, P) = \lfloor M \cdot R^2 + 24 \rfloor$$

Solo rounds 1-4 use fixed counts: 6, 8, 13, and 18. The round population is not the same as the active map population: stock standard play requests an active-AI limit of 24 and spawns reserves as existing zombies die.

`SetAILimit()` is the mod hook for a custom active horde size. The Kino Escalation presets intentionally request 26, 28, and 30, so `24` should be treated as the stock default rather than an immutable engine ceiling. Validate above-default values in a live match.

### Spawn delay and movement

The stock spawn delay starts at 2.0 seconds and decays by 5% per round down to a 0.08-second floor:

$$D(R) = \max(0.08, 2.0 \cdot 0.95^{R-1})$$

Round 1 uses slow walking/stumbling behavior. Rounds 2-4 mix faster walking and slow running. Standard zombies can fully sprint from round 5 onward.

When changing pacing, update the variable the stock round loop consumes. A custom curve should account for `level.zombie_vars["zombie_spawn_delay"]`, `level.zombie_vars["zombie_move_speed_multiplier"]`, and `level.zombie_move_speed` together.

### Targeting, barriers, and crawlers

- Zombies normally path to a valid player over the navigation graph.
- `maps/_zombiemode_utility::create_zombie_point_of_interest()` can redirect zombie interest to a registered point of interest, such as a Monkey Bomb target.
- A standard window has six boards. Rebuilding a board awards 10 points.
- Barrier-repair earnings are capped at $50R$ points per round, up to 500 points from round 10 onward; legacy stock behavior may yield 490 at the cap.
- Explosive damage over roughly 10% of current zombie health enters the gibbing path. Destroyed leg bones create a crawler state with reduced speed and a lower profile.

Barricade-free modes need to address both physical boards and Carpenter. The current Kino implementation destroys and hides barrier chunks, disconnects related clips, prevents repair validation, removes Carpenter from the natural deck, and suppresses explicit Carpenter drops. See [kino_gameplay.gsc](../mod_package/scripts/sp/zom/kino_gameplay.gsc).

## Powerups

### Natural-drop flow

Natural drops are driven by team-point progression and a per-kill random roll:

1. Team points accumulate toward the first 2,000-point threshold.
2. Each later threshold in the round is multiplied by $1.14$.
3. A zombie kill also has a 2% random-drop chance.
4. Natural drops are capped at four per round.
5. The next eligible item is drawn from the powerup cycle/deck.

The base deck contains Max Ammo, Insta-Kill, Double Points, and Nuke. Conditional entries include:

| Powerup | Availability condition | Effect |
| --- | --- | --- |
| Carpenter | At least five window boards destroyed | Repairs barriers and awards 200 points to every player |
| Fire Sale | Mystery Box has moved from its starting location | All box locations activate and cost 10 points for 30 seconds |
| Death Machine | Round 60+ or map-specific Easter egg condition | Picking player receives a 30-second minigun |

Max Ammo refills held-weapon reserves and equipment, Insta-Kill lasts 30 seconds, Double Points lasts 30 seconds, and Nuke clears active standard zombies while awarding 400 points to each player.

The modding surface is `level.zombie_powerup_array` for eligibility and ordering, plus `maps/_zombiemode_powerups::specific_powerup_drop()` for named drops. Preserve the original function's entity context and arguments when detouring it. In this project, `disableDetourOnce()` is required before calling a captured original to prevent recursion.

### Map-specific teleporter behavior

Der Riese teleporters have separate powerup rules. From round 15, the chance of no powerup rises by 5 percentage points per round. From round 10, a Max Ammo result has an increasing chance to re-roll. These rules do not apply to Kino unless a feature explicitly recreates them.

## Players, Points, and Perks

### Player and score model

- Base player health is 100. A standard zombie hit deals 50 damage.
- Juggernog raises health to 250.
- Bleedout lasts 45 seconds.
- Base revive time is 3.0 seconds; co-op Quick Revive reduces it to 1.5 seconds.
- A down removes 5% of the downed player's points. A bleedout removes 25% from that player and 10% from surviving teammates.

| Action | Points |
| --- | ---: |
| Non-lethal bullet hit | 10 |
| Torso or limb kill | 50 |
| Neckshot kill | 70 |
| Headshot kill | 100 |
| Melee kill | 130 |

`maps/_zombiemode_score::add_to_player_score()` is the correct hook for an income modifier. Scale and round once, then invoke the captured original exactly once. The current income boon follows this pattern.

### Perks

Standard perk behavior relevant to a challenge mod:

| Perk | Cost | Core effect |
| --- | ---: | --- |
| Juggernog | 2,500 | 250 player health |
| Speed Cola | 3,000 | 50% faster reload and faster board repairs |
| Quick Revive | 500 solo / 1,500 co-op | Solo self-revive; co-op 1.5-second revive |
| Double Tap | 2,000 | 33% fire-rate increase |
| Stamin-Up | 2,000 | 7% speed increase and longer sprint |
| PhD Flopper | 2,000 | Self-explosive and fall-damage protection; dive explosion |
| Deadshot Daiquiri | 1,500 | Head targeting and reduced recoil/spread |
| Mule Kick | 4,000 | Third primary weapon slot |

Perk machines use `zombie_vending` as their targetname and identify their perk through `script_noteworthy`. Relevant identifiers in the Kino mod include `specialty_armorvest`, `specialty_quickrevive`, `specialty_fastreload`, `specialty_rof`, `specialty_longersprint`, `specialty_flakjacket`, `specialty_deadshot`, and `specialty_additionalprimaryweapon`.

For a perk restriction, discover the machines present on the map and disable their triggers before round spawning. For a health modifier, wrap `maps/_zombiemode_perks::give_perk()` so Juggernog purchases retain the custom health adjustment.

## Mystery Box and Weapons

- Mystery Box spins normally cost 950 points and cost 10 during Fire Sale.
- Players hold two weapons by default and three with Mule Kick.
- A Teddy Bear outcome relocates the Mystery Box. It is separate from the Fire Sale powerup; a Teddy result does not itself place a Fire Sale pickup.
- No Mystery Box can be enforced by disabling `treasure_chest_use` triggers.
- No Thunder Gun can be enforced before box use by clearing `level.zombie_weapons["thundergun_zm"].is_in_box` and the matching `level.zombie_include_weapons` entry when present.

Notable wonder-weapon properties:

| Weapon | Upgraded name | Gameplay property |
| --- | --- | --- |
| Thunder Gun | Zeus Cannon | Wind-cylinder blast; affects up to 24 zombies per shot |
| Wunderwaffe DG-2 | Wunderwaffe DG-2 | Infinite-damage chain lightning to up to 10 zombies |
| Scavenger | Hyena Infra-Red | Upgraded explosive bolts deal 10,000 fixed splash damage |
| V-R11 | V-R11 Lazarus | Converts zombies into human distractions; teammates gain brief protection effects |
| Zap Gun / Wave Gun | Porter's X-2 Ray Gun | Single-target electrocution or microwave expansion/pop effect |

Weapon availability, damage, and Pack-a-Punch rules may differ by map. Query weapon tables rather than assuming every entry belongs in Kino's Mystery Box.

## Special Enemies and Rounds

| Enemy or round | Behavior relevant to scripting |
| --- | --- |
| Hellhounds | Dog rounds begin after round 5, recur every 4-5 rounds, allow up to four active dogs, and award a round-clear Max Ammo. Health ranges from 100 to 400. |
| Nova Crawlers | Low-profile enemies that can use special traversal; their death gas harms and distorts nearby players except for certain kill types. |
| Pentagon Thief | Five-only weapon thief targeting the player with the highest-tier weapon. Killing it before escape awards Max Ammo and Bonfire Sale. |
| Space Monkeys | Ascension-only perk-machine attackers. Protecting all machines awards Max Ammo. |
| George A. Romero | Call of the Dead boss with player-count and round-scaling health. Water can calm its enraged state. |
| Astronaut Zombie | Moon-only recurring special zombie that steals a perk and teleports a struck player. |

Do not generalize map-exclusive entities to Kino. They are useful reference points only when a feature targets their map or recreates their behavior.

## Kino Hook Patterns

The current mod provides working examples of the expected GSC patterns:

| Goal | Local pattern |
| --- | --- |
| Run restrictions before stock spawning | Set `level.round_prestart_func` in [kino.gsc](../mod_package/scripts/sp/zom/kino.gsc). |
| Disable a stock interaction | Find triggers with `GetEntArray(targetname, "targetname")`, then call `disable_trigger()`. |
| Alter horde size | Assign `level.zombie_ai_limit`, then call `SetAILimit()`. |
| Change player-to-zombie damage | Add a spawn callback, capture each actor's `actor_damage_func`, then install a wrapper. |
| Change player score | Detour `add_to_player_score()` and bypass the detour for direct stock-equivalent grants. |
| Disable Carpenter | Update the deck and inclusion state, then detour named Carpenter drops. |
| Preserve a boon after perk purchase | Detour `give_perk()`, invoke the original, then reapply custom health. |

Use one-time pre-round state changes where possible. Continuous player polling is appropriate only for a genuinely continuous effect, such as the current infinite-ammo playtest option.

## Corrections and Caveats

- The health table is consistent when the exponential calculation is rounded at presentation/assignment: use $\lfloor 950 \cdot 1.1^{R-9} \rfloor$ for the post-round-9 model. Do not recursively floor every intermediate round unless the target stock code explicitly does so.
- The stock active-AI default is 24, but the Kino mod deliberately raises the requested limit through `SetAILimit()`. Treat higher values as a runtime-tested customization, not an impossible setting.
- `level.zombie_vars` entries are GSC state, not console DVARs. Do not search a DVAR dump to validate them.
- Map, game mode, player count, special-round type, and exact build can alter a system. Check the owning target-build stock script before adding an enforcement or balance rule.

## Change Checklist

1. Identify the owning stock script and runtime state.
2. Keep new logic in a pre-round callback, existing stock function, or established detour path.
3. Preserve original function arguments and `self` context when wrapping a stock function.
4. Apply a multiplier or score adjustment exactly once.
5. Test a fresh `zombie_theater` match through the state transition being changed.
6. Add durable project-specific findings to [t5-gsc-reference.md](t5-gsc-reference.md).