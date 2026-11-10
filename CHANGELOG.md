# Changelog: Traditional Preservation (Fish)

## 0.2.8
- Changed: the season's mean temperature and humidity (raw and salt spoilage) are the series' own, kept once by TP
  Core, so Fish added to a running save agrees with the other mods from its first day. Save keys unchanged.
- Internal: a station is told by a table lookup on its sprite's name (`F.stationIndex`), not a pattern match.
- Docs: README and Workshop text say the mod needs TP Core (they said "no other mods"); the comment on raw
  spoilage says what the code does (twice as fast at +10 C, three times at +20, not doubling each time).
- Internal: `test_ui.lua` stubs `instanceof`, which the core's slot rules now call.
- Now requires the **TP Core** mod (`TraditionalPreservationCore`), which loads first. The mod's own copy of the
  shared core (`TraditionalPreservationFish/Core/`: Weather, Station, UI) is gone; the code loads
  `TraditionalPreservationCore/...` instead. Same rules, same timers, same save keys, items and entities: existing
  saves carry on unchanged.
- Internal: the synced core copies name the core's new source path (TP Core is now a mod). Comment line only.
- Internal: the shared core's folder is now `TraditionalPreservationCore` (was `_tpcore`): comments and test
  paths only. No change in play.

## 0.2.7
- Internal: comments on the public functions that lacked one and on the evolved-recipe wraps, and an updated copy
  of the shared core (comments only). No change in play.

## 0.2.6
- Fixed: a Spoilage sandbox value outside the four choices stopped the mod's settings loading; it now counts as Normal.
- Internal: the fish-to-item food copying (cured stages, head, halves, fillets) is one local `copyFood`; the code uses
  a `local F` alias for `TraditionalPreservationFish`. Public names unchanged, no change in play.

## 0.2.5
- Internal: the tub's and frames' slot rules (adding, green border, refused-drop message) run on the shared core's
  `UI.slotRules`. Same rules, same messages.

## 0.2.4
- Internal: recipe times are set through the shared core (`Weather.setRecipeHours`). No change in play.

## 0.2.3
- Internal: tile numbers come from a `Tiles.lua` the art builder writes, instead of hand-kept numbers. Same art.

## 0.2.2
- Internal: the press timer uses the shared core's clock (`Weather.startClock/showClock`). Same timing.

## 0.2.1
- Fixed: a drying frame, beam or tub in a chunk that had just unloaded could still be updated, so its changes were
  lost or went to a stale chunk. Stations are now checked against the live cell.
- Changed: Time Remaining in the popup rounds up instead of down, as in the other TP mods.
- Fixed: the popup's Spoilage line could show the wrong text (a percentage was passed to the translator).
- Internal: runs on the shared Traditional Preservation core (weather, station tracking, popups).
