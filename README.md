# PvPCallouts Clean

PvPCallouts Clean is a small World of Warcraft addon rebuilt from the original
PvPCallouts spell database.

The goal of this rebuild is to avoid the taint problems seen in the original
PvPCallouts addon by keeping the addon simple:

- no Ace options stack
- no direct Blizzard chat-frame hooks
- no protected UI frame hooks
- aura scanning wrapped with `pcall`
- arena-focused PvP callouts

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

5. Restart World of Warcraft and enable `PvP Callouts Clean`.

The final path should be:

```text
Interface/AddOns/PvPCallouts/PvPCallouts.toc
```

## Commands

Use `/pvpcallouts` or `/pvpco` in game.

## Notes

This is a clean rebuild intended to reduce taint risk. It is not the full
original PvPCallouts feature set.

Original PvPCallouts is MIT licensed. See `LICENSE.txt`.
