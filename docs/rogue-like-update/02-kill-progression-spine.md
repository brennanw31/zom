# Phase 2: Kill Progression Spine

## Goal

Add an opt-in progression flag and personal, observable kill-threshold state. Do not grant boons or alter zombies yet.

## Work

1. Add one provisional pre-match `progression` mode toggle, defaulting to off. It must be selected before `kinoLockRules()` and leave current matches unchanged when off.
2. At match lock, initialize only this state for each participating player:
   - `total_kills = 0`
   - `next_boon_kills = 100`
   - `draft_pending = false`
3. Use the Phase 1 death hook to increment `total_kills` only for a living, credited player killing a standard zombie.
   - Call the captured stock behavior exactly once.
   - Do not count score events, assists, non-player kills, dogs, crawlers, or special enemies unless the verified hook classifies them as standard zombies.
4. When `total_kills >= next_boon_kills`, set `draft_pending` once. Keep counting kills while it is pending; Phase 3 will advance the threshold after a choice.
5. Provide a temporary owner-only diagnostic line showing total kills and pending state. Remove or replace it in Phase 3.

## Non-Goals

- No reward, offer randomization, selection input, curse, or new persistence format.
- No changes to `level.kino_challenge_boons`; those remain initial configuration.

## Verification

1. With progression off, confirm an ordinary match behaves identically to the current build.
2. With progression on, verify that kills 1 through 99 do not set pending and kill 100 sets it once.
3. In co-op, verify each player has an independent count and only the credited killer advances.
4. Verify environment and excluded-enemy deaths do not change a player's count.
5. Continue killing after threshold 100 and confirm the count rises without repeatedly setting or announcing pending.

## Exit Criteria

The temporary HUD and a short test log agree on all five checks. A mismatch means the Phase 1 attribution assumption was wrong; fix the kill hook before creating any draft UI.