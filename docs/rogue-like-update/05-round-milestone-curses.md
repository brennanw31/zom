# Phase 5: Round Milestone Curses

## Goal

Add the first shared zombie pressure that accumulates every few rounds, using the post-stock round hook verified in Phase 1.

## Work

1. Store active progression curses and their ranks on `level`; all players see the same curse state.
2. Trigger one curse at the start of round 5 and each fifth round thereafter. The event must execute after stock computes the new round values and before the affected wave begins.
3. Add exactly two random, repeatable curses:
   - `overrun`: increase the active-AI limit by 2 per rank with `SetAILimit()`.
   - `pressure`: reduce the stock-computed zombie spawn delay by 10% per rank, never below the verified stock-safe minimum.
4. Capture the current round's stock values first, then calculate curse output from those values. Do not carry a mutated value forward as the next round's base.
5. Show active curse ranks in the shared locked-rules HUD or a dedicated shared status line.
6. For this first pass, block progression-mode activation with non-Normal Escalation and state the reason in the menu. Both features mutate round pacing and must not race until Phase 6 defines their order.

## Verification

1. Run to round 4: no curse is active. At round 5, exactly one curse appears and applies once.
2. At rounds 10 and 15, confirm one additional rank is selected per milestone, including repeat selections.
3. Compare base values immediately before application and confirm `pressure` uses the new stock round value rather than the prior cursed value.
4. Confirm `overrun` calls `SetAILimit()` with the expected rank-adjusted limit.
5. Try to enable non-Normal Escalation and progression together; the menu must reject or clearly disable the unsupported combination.

## Exit Criteria

Round-driven curses are shared, bounded, visible, and reliably applied once per milestone. No power or perk advancement trigger is added yet.