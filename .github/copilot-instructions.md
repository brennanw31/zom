# Copilot Instructions

## T5 / GSC Work

For changes to `scripts/**/*.gsc` or `diagnostics/**/*.gsc`:

1. Read `docs/t5-gsc-reference.md` and the nearby script implementation first.
2. Treat facts labeled **Verified in this repository** as the current mod contract.
3. Consult `docs/t5-sources.md` only when the local reference and nearby code do not establish the required engine behavior, API signature, or target-specific entity name.
4. Prefer the target T5 build's stock script behavior and the existing mod's usage over generic Call of Duty GSC examples.
5. When external research establishes a reusable fact, add a brief, sourced entry to `docs/t5-gsc-reference.md` in the same change. Include the source URL, relevant stock-script path, and the target map/build when applicable.
6. Do not copy external documentation wholesale or present an unverified API as established fact.

Keep GSC changes small and preserve the host-only, Kino-only behavior unless a task explicitly changes it.

## Installer Safety

Do not execute the generated `install.bat` installer, whether from the workspace or `BO1_Mod_Installer.zip`. Running `package.py` to build the archive is permitted.
