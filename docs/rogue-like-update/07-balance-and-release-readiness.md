# Phase 7: Balance and Release Readiness

## Goal

Stabilize the mode before widening its content. Pick the final name only after its pacing, co-op behavior, and HUD language are understood.

## Work

1. Move the 100-kill interval, boon values, curse values, and round milestones into a small, named configuration section. Preserve the Phase 4/5 defaults.
2. Run a focused test matrix: solo and four-player games; disconnect during a pending draft; death, revive, and rejoin; power and perk milestones; rounds 5, 10, and 20; each Escalation tier; and the pre-existing modes with progression off.
3. Remove diagnostics, make HUD cleanup idempotent, and verify no duplicate thread, notification, or detour is installed across a whole match.
4. Choose the player-facing mode name and replace only provisional display labels, retaining tested internal keys.
5. Add new content one item at a time in future small releases, each with its owning stock hook and a focused test.

## Candidate Backlog

These are ideas, not approved implementations. Research their owning T5 path before scheduling them.

| Player boons | Zombie/shared curses |
| --- | --- |
| Round-start ammo reserve | Faster zombie movement ramp |
| Headshot score bonus | Larger active horde |
| Revive-speed bonus | Faster spawn cadence |
| Extra powerup duration | Reduced or altered powerup deck |
| One-time emergency self-revive | Increased standard-zombie health |
| Melee damage bonus | Special-enemy frequency, if target-build support exists |
| Discounted first perk | Perk-purchase milestone pressure |
| Box discount or reroll protection | Power-restoration milestone pressure |

## Verification

1. Produce a short balance record for each test match: player count, selected draft ranks, curse history, final round, deaths, and obvious pacing failures.
2. Confirm `progression` off exercises the existing static selections with no new HUD, hooks, or score/health/movement changes.
3. Confirm the final terminology fits all owner-only and shared HUD strings without clipping at the supported resolutions.
4. Re-run the complete live-match checklist in [README.md](../../README.md) after the final package install.

## Release Gate

Do not add the candidate backlog merely to make the mode feel larger. Ship the small loop only when the matrix shows deterministic credit, one-time event accounting, correct modifier composition, and readable co-op UI.