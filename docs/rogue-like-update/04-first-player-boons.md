# Phase 4: First Player Boons

## Goal

Make selected draft choices matter using three stackable, new player boons. Keep their implementation explicit and compatible with the current static boon paths.

## First Set

| Stable key | Provisional label | Per-rank effect |
| --- | --- | --- |
| `vitality` | Vitality | +25 maximum health |
| `swiftness` | Swiftness | +5% movement-speed scale |
| `bounty` | Bounty | +10% player score awards |

Labels and numbers are provisional; the keys are the contract used by draft state and tests.

## Work

1. Add a small per-player rank lookup over selected progression keys. It returns zero when progression mode is off.
2. Extend the existing health application path so maximum health is computed from the stock/Juggernog target, the static health boon, and `vitality` ranks. Apply it both on selection and after a relevant perk grant.
3. Compute movement from the existing static movement scale and `swiftness` ranks, then reapply it immediately to the choosing player.
4. Consolidate score scaling in one detour so static income and `bounty` multiply together, rounding once before the captured `add_to_player_score()` call.
   - Install the detour when either feature needs it.
   - Never stack wrappers around the same stock function or call the original more than once.
5. Add rank/effect text to the personal progression status area.

## Verification

1. Draft each first-set boon separately and confirm its effect begins immediately.
2. Select duplicate copies and verify each rank stacks exactly once.
3. Buy Juggernog after `vitality` and confirm the bonus persists.
4. Enable static income and draft `bounty`; compare a fixed point award to the documented combined multiplier, with one rounding operation.
5. Confirm a player with no progression selections still receives precisely the current static boon behavior.

## Exit Criteria

Each boon has a localized owning path, coexists with the matching current feature, and survives the gameplay transition it owns. Do not introduce additional effect categories in this phase.