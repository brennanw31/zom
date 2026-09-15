# Phase 3: Personal Draft Interaction

## Goal

Let the eligible player choose one item from three stable, personal offers. Choices are recorded only; effects arrive in Phase 4.

## Work

1. Add a compact progression-boon definition list with stable keys, provisional labels, and an eligibility predicate. Start with exactly three draftable definitions.
2. When a player's `draft_pending` becomes true, choose three distinct eligible definitions using the same bounded random-pool pattern already used by `kinoChooseRandomRules()`.
   - Persist the chosen keys in that player's pending draft so opening, closing, or redrawing HUD cannot reroll it.
   - If fewer than three choices are eligible, offer every eligible choice. If none are eligible, clearly record the exhausted-pool condition and defer policy changes to Phase 7.
3. Render an owner-only HUD overlay and reuse the existing `kino_*` command-listener pattern for previous, next, and select input.
   - Do not pause the match or block other players' inputs.
   - Config-menu input remains locked after match start; only a pending draft accepts these commands.
4. On selection, append the selected key to the player's progression state, clear the pending draft, and increase `next_boon_kills` by 100.
   - Reevaluate the total after the overlay closes so kills earned while choosing are not lost.
   - Destroy owner HUD on disconnect and do not transfer personal choices to another player.
5. Show the selected keys in a small owner-only status area. The temporary counter from Phase 2 may be removed.

## Verification

1. At 100 kills, exactly one player sees three distinct offers and can select only one.
2. Other co-op players can continue playing and do not control or see that draft.
3. Reopening/redrawing the overlay presents the same offers; selection advances the next threshold to 200.
4. Kill to 200 while a draft is open, select one, and confirm a new draft is queued without a lost or duplicate threshold.
5. Disconnect during a draft and verify the HUD cleans up and other players' progression remains intact.

## Exit Criteria

The draft lifecycle is deterministic after the random roll, personal in co-op, and adds no gameplay benefit yet. Do not add more candidates until the selection state is reliable.