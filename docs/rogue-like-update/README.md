# Dynamic Progression Update Plan

This folder plans an opt-in, in-match progression mode. Its player-facing name is intentionally undecided; use the internal term `progression` until a name is chosen.

## Outcome

- Each player earns a personal boon draft after every 100 credited standard-zombie kills.
- A draft contains a small random set of new boon definitions; players choose one without pausing other players.
- Global curses accumulate at clear round milestones and at selected match advancements, such as restoring power or buying perks.
- Existing pre-match boons, rules, playtest options, and escalation retain their current behavior when progression mode is off.

## Boundaries

- Keep runtime progression state separate from `level.kino_challenge_boons`, whose `selected` values are intentionally pre-match configuration.
- Keep player state on the player and shared curse state on `level`.
- Count kills from an authoritative stock kill/death path, never from score changes or a polling loop.
- Do not add a generic effect framework. Start with small definition structs and explicit application paths; extract only repeated, proven behavior.
- Each phase has a playable verification gate. Stop at a failed gate rather than building dependent features on an unverified hook.

## Delivery Order

1. [Phase 1: Verify Runtime Hooks](01-verify-runtime-hooks.md)
2. [Phase 2: Kill Progression Spine](02-kill-progression-spine.md)
3. [Phase 3: Personal Draft Interaction](03-personal-draft-interaction.md)
4. [Phase 4: First Player Boons](04-first-player-boons.md)
5. [Phase 5: Round Milestone Curses](05-round-milestone-curses.md)
6. [Phase 6: Advancement Curses and Compatibility](06-advancement-curses-and-compatibility.md)
7. [Phase 7: Balance and Release Readiness](07-balance-and-release-readiness.md)

The plan deliberately leaves boon and curse names, values, and final mode branding adjustable. Stable internal keys should not be renamed casually once live saves, HUD output, or tests depend on them.