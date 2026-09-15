# Phase 1: Verify Runtime Hooks

## Goal

Establish the target Plutonium T5 hooks that can safely drive kill credit, round milestones, power state, and perk-purchase progression. This phase changes no match behavior.

## Work

1. Obtain the stock scripts that match the installed Plutonium build, following [t5-sources.md](../t5-sources.md).
2. Identify one standard-zombie death path that exposes the credited player and runs exactly once per death.
   - Record the stock file, function/callback, argument order, `self` type, and how non-player, environmental, and special-enemy deaths appear.
3. Identify one post-stock round transition point.
   - It must run once per completed round after stock code has assigned the next round's speed and spawn values.
   - Do not assume `between_round_over` establishes listener ordering; the existing escalation plan identifies that race.
4. Identify the completed power-restoration path and confirm whether Kino power is a one-time level state.
5. Verify `maps/_zombiemode_perks::give_perk()` for normal purchases, upgrades, repeats, and self context.
6. Add only verified, reusable facts to [t5-gsc-reference.md](../t5-gsc-reference.md), including the stock build/revision examined.

## Exit Criteria

- The four sources above are known precisely enough to wrap or subscribe without guessing.
- The death hook can distinguish a standard zombie kill credited to a specific player.
- The round hook has defined post-stock ordering.
- The perk and power paths have explicit duplicate-event rules.

## Verification

Use a disposable diagnostic script or temporary logging only. In a fresh `zombie_theater` match, confirm that one ordinary player kill, one non-player/environmental death if reproducible, a round change, power activation, and a perk purchase produce the documented observations exactly once. Remove the diagnostic before continuing.

## Stop Condition

If a hook cannot prove its timing or attribution, do not substitute score changes, periodic polling, or an unrelated notification. Continue research in the owning stock script until a suitable path is found.