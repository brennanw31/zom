# Phase 6: Advancement Curses and Compatibility

## Goal

Turn meaningful match advancements into controlled curse triggers and define how dynamic progression composes with existing Kino options.

## Work

1. On the verified one-time power-restoration event, add one random shared curse to the Phase 5 pool.
   - Guard it with level state so repeated interactions, reconnects, or hook reentry cannot add another.
2. Count verified, non-upgrade perk purchases at team scope. At three purchases, add one random shared curse and reset only the three-purchase counter.
   - Explicitly decide from Phase 1 evidence how rebuy, refund, and perk upgrades are treated; do not infer from labels.
3. Queue any event-triggered pace change for the next authoritative round application point. The curse can display immediately, but no mid-wave mutation should create a partial round state.
4. Use one shared `give_perk()` wrapper when either static health or progression purchase tracking is enabled.
   - Invoke original behavior once, then apply the existing health preservation and progression accounting in a documented order.
5. Remove the Phase 5 escalation exclusion only after defining and testing this round calculation order:
   - stock round values
   - Escalation adjustments
   - progression curse ranks
6. Define current player-boon composition in helpers, not scattered assignments:
   - health: stock perk target + static health bonus + `vitality`
   - movement: stock scale x static movement scale x `swiftness` scale
   - score: stock award x static income scale x `bounty` scale, rounded once

## Verification

1. Activate power once and confirm exactly one curse is queued and applied next round.
2. Buy three qualifying perks across one or more players; confirm exactly one curse. Repeat another three purchases and confirm one more.
3. Confirm upgrades and any excluded purchase paths follow the documented policy.
4. Test Juggernog with progression active and static health active; verify original perk behavior and both bonuses remain intact.
5. Exercise each Escalation tier with progression mode and compare the measured round values against the declared order.

## Exit Criteria

Power, perks, static boons, and Escalation have explicit, tested composition rules. No separate detour may own the same stock function.