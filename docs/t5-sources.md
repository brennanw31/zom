# T5 Research Sources

Use these sources only when `t5-gsc-reference.md` and nearby mod code do not establish the behavior needed for a change.

## Canonical Implementation Reference

- [Plutonium T5 scripts](https://github.com/plutoniummod/t5-scripts)
  - Known relevant paths: `maps/zombie_theater.gsc`, shared Zombies scripts, and the implementation of any function invoked by this mod.
  - Use the branch/revision that matches the installed Plutonium T5 build when that distinction matters.

## Local Evidence

- [README.md](../README.md) records the currently verified lifecycle, include dependencies, stock target names, installation procedure, and in-game validation checklist.
- [scripts/sp/zom/kino.gsc](../scripts/sp/zom/kino.gsc) is the current implementation and strongest evidence for project-specific behavior.
- [diagnostics/kino.gsc](../diagnostics/kino.gsc) validates the module's basic entry-point and local-call behavior without gameplay changes.

## Research Workflow

1. Identify the exact entity, function, callback, or state required by the feature.
2. Find its implementation or usage in the matching stock T5 scripts.
3. Confirm map-specific behavior in `maps/zombie_theater.gsc` where relevant.
4. Record a concise result in `t5-gsc-reference.md` when it is likely to help later changes.

Do not treat generic GSC examples, another Call of Duty title, or an unsourced forum post as authoritative for this T5 target.
