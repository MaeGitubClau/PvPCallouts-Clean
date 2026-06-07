# PvPCallouts

Original PvPCallouts 2.5.2 base with focused Retail taint fixes.

This build keeps the original addon structure, bundled Ace options menu,
profile import/export, spell toggles, TTS settings, and slash commands. The
taint-related changes are intentionally narrow:

- use a single Retail TOC interface number so WoW recognizes the addon
- keep `Options.lua`, `ProfileManager.lua`, AceConfig, and AceGUI loaded
- open the original options with `/pvpc`, `/pvpc options`, or the addon compartment button
- avoid classified aura filters that can expose protected/secret aura values
- guard aura field reads and spell ID lookups with `pcall`
- avoid runtime `RegisterUnitEvent`, `UnregisterEvent`, and `UnregisterAllEvents` calls

## Install

1. Download the release zip.
2. Fully close World of Warcraft.
3. Delete any old copy of:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/PvPCallouts
   ```

4. Extract the zip into:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

5. Restart World of Warcraft and enable `PvPCallouts`.

The final path should be:

```text
Interface/AddOns/PvPCallouts/PvPCallouts.toc
```

## Commands

Use `/pvpc`, `/pvpcallouts`, or the addon compartment menu.

Useful checks:

- `/pvpc` opens the original-style options menu.
- `/pvpc options` opens the original-style options menu.
- `/pvpc test` sends a test callout.
- `/pvpc volume 0-300` sets TTS volume.
- `/pvpc arena on/off` toggles arena-only mode.

Original PvPCallouts is MIT licensed. See `LICENSE.txt`.
