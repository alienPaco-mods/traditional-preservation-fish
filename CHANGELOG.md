# Changelog: Traditional Preservation (Fish)

## 0.3.5
- **Stockfish Pallet** (ROADMAP §6, user 2026-11-11, from a photo of stockfish maturing stacked on pallets): built from
  the build menu (hammer and saw kept, 3 planks, 6 nails, Carpentry 2). A 20 weight container from its tile
  (`container = stockfishpallet`, vanilla's Empty Pallet art copied, tile `_02_304`). Cold Dried fish on it, and in
  bales on it, ripens faster by place: a loft (a room on floor 1 or up) ×2 (`PALLET_LOFT`, 30 days), a ground-floor
  room ×1.5 (`PALLET_GROUND`, 40 days); covered, outdoors or a basement ×1, never worse than a shelf. Done once an
  in-game hour by moving each fish's `matureAge` back (`F.ripenOnPallet`), counting time the area was unloaded; the
  hour last counted is on the pallet (`palletHour`), so a moved pallet starts afresh. No new item key.
- The pallet shows a stack of stockfish (necks out, layers crossed) at a third, two thirds or full by the weight on
  it (`F.palletLevel`, tiles `_02_305`-`_307`), only while it holds nothing but stockfish (or bales of it).
- No window (like vanilla's crates): right-clicking it says what it does where it stands, *Stockfish Pallet: ripens
  stockfish x2 (loft)*, *x1.5 (ground-floor room)* or *no faster than a shelf here*, with the places on hover.
- Debug: `TPF.stockfish(n)` spawns unripe Cold Dried fish; `TPF.pallet()` reports the pallet near you.

## 0.3.4
- Optional rinse (ROADMAP §6, user 2026-11-11, from an Astrakhan vobla account: the excess salt is soaked off after
  pressing). **Rinse Off Salt** is a craft recipe (`RinseSaltedFish`) on Salt Pressed fish: 0.15 L of clean
  carried water each (`RINSE_LITRES`), so it sits in the fish's recipe submenu and the Craft window can do many at
  once, and works in the dark (`CanBeDoneInDark`). It gives back the same fish (`onCreateRinsed`: food, weight, age and mod data carried) marked `rinsed`.
  Near a sink, bathtub, barrel or well of clean water (3 tiles, same floor, `F.findWaterSource`), **Rinse at Sink**
  joins the same submenu (a lone vanilla recipe option is turned into that submenu in place) and rinses every
  selected fish there (`TPFishRinse`, `RINSE_TICKS`), walking over first. Tainted water is refused both ways, as
  the soaking recipes already refuse it.
- A rinsed fish has two thirds of the thirst and keeps a tenth less long (`RINSED_THIRST`, `RINSED_KEEPING`: less
  salt, less protection); the Salt Dried fish made from it gets the same from its own script (thirst 30 to 20) and
  loses its sour note (unhappiness 3 to 0). Slices keep it; soaking doesn't apply it again. Names show it:
  *Medium Walleye (Salt Dried, Rinsed)*. Skipping the rinse changes nothing.

## 0.3.3
- Stockfish matures (ROADMAP §6, decisions 5 and 6, user 2026-11-11): Cold Dried fish ripens over 60 days
  (`MATURE_DAYS`) on its own food clock, so a fridge slows it and a freezer stops it; no station, any container.
  `onCreateDried` stamps `matureAge` (item modData); a fish with no stamp (made before 0.3.3) counts as ripe.
- Rehydrate Fish on stockfish now runs `onCreateSoaked`: the soaked fish keeps `ripeness` and its unhappiness
  goes from +10 unripe through 0 halfway to -10 ripe (`MATURE_UNHAPPY`); a dish takes on its share, as vanilla does.
- Names: the stage goes in brackets after the fish, and vanilla's (Fresh) / (Stale) follows: *Gutted Medium Walleye
  (Salt Pressed)*, *Fish Half (Cold Dried, Unripe)*, *Medium Walleye (Rehydrated, Cold Dried, Ripe)*. Gutted and
  Half stay part of the fish's name; "Gutted" shows on every later stage of a fish that went through Gut Fish (user:
  packing takes the guts but leaves the fish whole), read from its headless icon (`F.wasGutted`), so old saves too. `F.stageName`, `F.rename`; slices carry the ripeness.
- Names and the stockfish's tooltip ("Maturing: 40 percent", one Tooltip key per tenth, `..._ColdDried_40`, as the game neither saves a per-item tooltip nor formats one) update
  every in-game hour for the player's own things and whenever the inventory windows show a container. Fish from
  older saves take the new names the same way.
- Debug: `TPF.mature(days)` ages the Cold Dried fish you carry.

## 0.3.2
- Realism (ROADMAP §6, decision 16, user 2026-11-11): salt per fish doubled to 4 uses per started half weight
  (`SALT_PER_STEP`), about 15% of the fish's weight, the Volga figure (was about 7%).
- A warm cure: while the season averages above 20 C (`WARM_CURE_ABOVE`), a tub batch picks up spoilage at a quarter
  of raw fish's rate (`WARM_CURE_SHARE`), plus as much again per 10 degrees over (a day at 21 C ~14%, two at 25 C
  ~38%). The press's OnCreate is now `onCreatePressed`: each pressed fish carries `cureSpoiled` and is aged by it, and
  a frame stack starts from its fish's share by weight. The tub's popup shows it. Presses from before count from now.
- Hot sun: above 25 C (`HEAT_ABOVE`, live temperature), an open salt stack under half dried (`SALT_FRESH_UNTIL`)
  takes 0.05 per 24 h (`HEAT_DAMAGE`, `HEAT_DAMAGE_HOURS`, scaled by the Spoilage option) times how wet it still is,
  within `DAMAGE_CAP`. Salt stacks now go through `F.saltStep`. Popup: "Too hot in the sun" and "Spoiling (Hot sun)".
- Covered (user 2026-11-11): a roof with no room round it (porch, open shed; Core `Weather.placeOf(station, true)`)
  is its own place. Salt fish dries at the open rate there, never rained on, in the shade; cold fish at 75%
  (`COVERED_COLD_RATE`), never rained on, no wet damage. A room (map or player-built: walled all round and fully
  roofed, the engine's `isInARoom`) is indoors as before: salt 65%, cold stops. New stack key `covered`; new ledger
  totals `covered`, `coldCovered`, `warmCure`, `heat` (older saves gain them at 0). Popup shows the Place.
- The Fish Hanging Beam and Gantry may stand under an open roof; only a room refuses them (`F.notInRoom`, Core
  `UI.notInRooms`; was outdoors only).
- Season report runs salt stacks through `saltStep` in all three places and adds covered cold drying and a 2-day
  press column; golden updated. README, guide, Workshop text and tooltips updated.

## 0.3.1
- Realism (ROADMAP §6, decision 9): the press follows the batch's heaviest fish, as the salt has to reach through the
  thickest one. 1 day if every fish is up to 1.1 weight (about 0.5 kg, `PRESS_SMALL_WEIGHT`), 2 days with any fish of
  2.2 weight (about 1 kg, `PRESS_BIG_WEIGHT`) or more, in between by weight (was 12 hours for any batch; Volga
  practice, user: about 2 days at most). The recipe's time is the longest press (`PRESS_HOURS` 48); a lighter batch's
  bar runs faster (new `pressHours` on the recipe data). A press already running from an older version keeps its
  12 hours. Tooltip, guide, README and Workshop text updated.
- The tub gets the mod's own hover popup on a running batch (Progress, Time Remaining from its own hours), as
  vanilla's counts down from the recipe's 2 days (step 58: a small batch read 1d 23h at the start).

## 0.3.0
- Realism (ROADMAP §6, cold-frame model): cold drying follows frost and wind. Full speed 0 to 5 C; 80% at -5 C
  and 60% below (`HARD_FROST`); wind from `ClimateManager:getWindIntensity()` gives 50% in still air up to 120% at
  0.25 (`WIND_GOOD`). Base cold drying is 32 days (`COLD_DRY_HOURS` 768, was 480), so a stack hung November to
  January takes 50 to 55 days (user: a 55-day gameplay compromise). Rain wets cold frames with their own wetness (`coldWetness`, snow doesn't), and drying waits
  until it is gone. Until a stack is 30% dried, hard frost (0.1 per 72 h) and lying wet above 0 C (0.05 per 48 h)
  add a little to its spoilage (at most a quarter, `DAMAGE_CAP`): about 10% of the keeping for a November hang,
  20% for January; rot from a warm season is scaled by how wet the stack still is. New ledger
  totals `hardFrost`, `coldWet`, `coldWetness`, `wind`; older ledgers and running stacks carry on.
- Popup: a Wind line on cold stacks (calm, light breeze, good drying wind), "Frost" and "Hard frost" for cold
  stacks, and the cold frame's own wetness. Debug: `TPF.frost(hours)`; `TPF.weather()` shows wind, cold
  wetness and the new totals; `TPF.dry()` clears both wetnesses.
- Season report: reads `tools/climate_wind.csv` (forecast wind x0.65 on dry days, x1.3 in rain), runs each cold
  stack through `F.coldStep`, and adds the keeping lost. 

## 0.2.9
- Realism (ROADMAP §6, Volga salting): Pack Fish in Salt refuses a whole or gutted fish over 4.5 weight (about 2 kg,
  `SALT_WHOLE_MAX`): gut and split it, then pack the halves. Smaller fish still go in whole with their heads, and
  gutting is unchanged. The tooltip, guide and README say so.
- Debug: `TPF.wind()` logs the live wind every 10 minutes, then prints it on dry and wet spells beside the
  forecast's wind, for setting the cold-drying wind curve. `tools/climate_wind.csv` holds a year of the game's
  forecast wind (one headless world per start month) for the season report.

## 0.2.8
- Docs (2026-11-11 pass against the code): the season tables in the README and guide match `tools/season_report.lua`
  again (a day's difference in seven months; April's 3% of cold batches finish in 33 days); Fish Head Stock's
  tooltip and the Workshop text say it starts as tasty as a plain stew (they said tastier, from before -20);
  fillets no longer "stack deep" (a salted fillet weighs as the food it holds); the Workshop's "one batch packs
  about 12 fish" and the DEVHELP salt check (`TPF.salt(5)`) follow salt by size. Tooltip text only: no change in play.
- Balance (series pass, F3): Pack Fish in Salt takes salt by the fish's size, 2 for each started half weight of the
  packed fish (at least 2; past the first 2 it must be carried), part-used salt first; the Salt mod's empties come
  back for what it uses up. A fillet vanilla cut counts as the food it holds (half its gutted fish) for salt and
  for its salted weight; fillets sliced from a cured fish weigh half of it, not 5%. Rehydrating carries the dried
  fish's freshness over as a share instead of starting fresh. The recipe's tooltip gives the rule.
- Balance (series pass, F1): Salting Tub takes 4 planks (was 2) and a saw, kept; Drying Frame takes 4 twine
  (was 2). Packing fish in salt gives Cooking 3 (was 10), gutting Butchering 10 (was 15), vanilla's figures.
  Fish Head Stock starts at vanilla stew's -20 unhappiness (was -30). Rehydrated fish fill as the fresh fish did
  (soaking gives back the 30% of hunger drying took); calories unchanged.
- Internal: new `tests/test_console.lua` loads the debug console (TPF) and calls every command, so one can't
  break unseen.
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
