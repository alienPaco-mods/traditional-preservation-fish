# Traditional Preservation (Fish) — Build 42 prototype (v0.2.8)

**Status: experimental.** The stations build, open and hang fish in the game, but a full year hasn't been played. Back up your save before enabling.

## History

The mod's two routes are the two great preserved fish of the North Atlantic. Stockfish is unsalted cod hung on open racks through the cold northern Norwegian spring, and it has been traded across Europe since the Viking age. Salt cod (Norwegian *klippfisk*, Portuguese *bacalhau*) is salted, pressed and dried in mild air, and from the 1500s it fed sailors and Catholic fast days on both sides of the Atlantic. On the lower Volga around Astrakhan, large salted fish such as pike are hung from hooks to dry. Both keep for months or years, and both are soaked before cooking.

## Install

Copy this folder to `~/Zomboid/mods/TraditionalPreservationFish`, as a real copy rather than a symlink. It needs the **TP Core** mod (`TraditionalPreservationCore`, the series' shared mod) installed and enabled the same way, and no other mods.

## How it works

The salt route can be done in any season. The cold route needs no salt, keeps about three times as long and only works in a cold season. Both use the same drying stations.

**Salt route**

1. **Pack Fish in Salt**: a raw fish or fillet, salt by its size and a sharp knife or meat cleaver (kept). Any fish works, fresh or stale and even part-eaten, but not rotten, frozen or cooked. It takes 4 salt for each started half weight of the packed fish, about 15% of its weight (Volga salters use 10 to 15%): a bluegill takes 4, a 4 weight walleye 32, a 4.5 weight walleye 36 (packed weight is after the guts come out). A whole or gutted fish over 4.5 weight (about 2 kg) is too thick to salt whole, as on the Volga: gut it, split it and pack the halves (a 10 weight catfish gives two halves of 4.0, 32 salt each). Salt in a container in reach covers the first 2; the rest must be in your inventory (bags count). Any salt works: a vanilla shaker holds 10, an Evaporated Salt from Traditional Preservation (Salt) 5 and a Bag of Salt 50, and part-used salt goes first. Gives one Salt Packed fish, which keeps for days, not weeks, and Fish Guts if the fish has any (see below). The same limits apply when loading the tub and the frame. A Gutted Fish or Fish Half can be packed too, and goes through the salt route the same way, so you can gut a fish and still salt it.
2. **Build a Salting Tub** (Carpentry 2, Fishing 2): 4 planks, 6 nails, 2 twine, a hammer and a saw (both kept).
3. **Press**: load up to 50 weight of packed fish, 35 items at most, into the tub and press **Craft**. The board and stones go on until the salt has gone through the thickest fish, so the heaviest fish sets the time: 1 in-game day if every fish is up to 1.1 weight (about 0.5 kg), 2 days with any fish of 2.2 weight (about 1 kg) or more, and in between by weight. Big fish are split before salting (over 4.5 weight), so 2 days is the longest. The tub is closed from then until the last pressed fish is taken out, so nothing can be added. The clock keeps running while you are away.
   *Optional rinse*: before hanging, **Rinse Off Salt** (a recipe in the fish's submenu, 0.15 L of clean carried water a fish, batches in the Craft window, works in the dark) or **Rinse at Sink** in the same submenu (a sink, bathtub, barrel or well of clean water within 3 tiles) soaks the excess salt off, as on the Volga. The fish is marked Rinsed: two thirds of the thirst, a tenth less keeping, and its Salt Dried fish has thirst 20 instead of 30 and no unhappiness. Tainted water is refused. Skipping it changes nothing.
4. **Build a Fish Drying Frame** (Carpentry 2, Fishing 2): 6 long sticks, 3 nails, 4 twine and a hammer (kept).
5. **Hang**: pick Hang Salt Pressed Fish to Dry in the frame's recipe list, load pressed fish and press **Craft**. Each press hangs one stack, which dries on its own timer. A stack holds 2.5 weight, so a full frame holds 20, and a fish heavier than 2.5 has to be sliced first (Slice Fish, two fillets of half its weight each) or hung on a bigger station. You can keep adding stacks while others dry, up to the 8 fixed spots, and finished stacks hold their spot until collected. Each sprite changes colour and thins down in five steps as its stack dries. Each stack picks its look at random when it starts, whatever is in it, so a frame doesn't look all alike. A salt stack is usually a whole fish and sometimes a headless or split one, and a cold stack is usually headless and sometimes split.
6. **Eat, cook or rehydrate**: Salt Dried fish keeps for about 4 to 6 months. It is very salty, but can go straight into soup, stew, rice or pasta. **Rehydrate Fish** uses 1 L of water and gives a mild, perishable fish that cooks like a fresh one and is safe without cooking, though it stays darker than fresh fish, as real soaked fish does. Packed and pressed fish aren't safe yet: only drying makes salt fish safe to eat uncooked.

**Bigger fish**: two outdoor stations hang fish the same way as the frame, with the same recipes, rates and spoilage, but take far bigger stacks and show them larger on their hooks. They can be built in the open or under a roof with no room round it (a porch, an open shed), not in a room, and one picked up can't be put down in a room either.

- **Fish Hanging Beam** (Carpentry 4, Fishing 2): 6 planks, 6 nails, 1 large hook and a hammer (kept). 4 stacks of up to 15 weight each.
- **Fish Gantry** (Carpentry 6, Fishing 2): 2 logs, 2 planks, 8 nails, 2 large hooks and a hammer (kept). 2 stacks of up to 50 weight each.

**Cold route**

1. **Gut Fish**: a raw whole fish and a sharp knife or meat cleaver (kept). Gives a Gutted Fish, which keeps like a fresh fish, must be cooked before eating like one, and Fish Guts and a Fish Head if it has them. Fillets can't be gutted, so they stay on the salt route.
2. **Split Fish**: a Gutted Fish over 2.5 weight, too heavy for a frame stack, can be cut into two Fish Halves with a knife. Each keeps half the weight and food, and the fish's name, such as Medium Walleye Half. Fish that are too heavy for the frame can also hang whole on a Fish Hanging Beam or Fish Gantry.
3. **Hang**: pick Hang Gutted Fish to Cold Dry in the frame's recipe list, load gutted fish or halves and press **Craft**. Frozen fish is fine. The hanging fish fade to grey as they dry. A stack can't mix gutted and salted fish, but a frame can hold both kinds of stack.
4. **Mature**: stockfish ripens in storage, as it did for two or three months in the warehouses after the racks. It takes 60 days on the fish's own food clock: any container works, a fridge slows it and a freezer stops it. The name says *Unripe* or *Ripe*, and the tooltip shows how far along it is (Maturing: 40 percent). Fish made before version 0.3.3 count as ripe. A **Stockfish Pallet** (build menu: Carpentry 2, 3 planks, 6 nails, hammer and saw kept; a 20 weight container) speeds it up where the warehouses kept stockfish: a loft (a room upstairs) ×2, 30 days, a ground-floor room ×1.5, 40 days; covered, outdoors or in a basement no faster than a shelf. Right-click it to see its speed there. It shows a stack of stockfish, a third, two thirds or full by the weight on it, while it holds nothing but stockfish. A **Stockfish Bale** carries and stores it: right-click selected stockfish, *Tie a Bale*, with one use of Twine or a Rope. It holds 10 weight of stockfish and nothing else (weight reduction 30), the fish keep ripening inside, on a pallet too, and *Untie Bale* gives the fish and the cord back.
5. **Rehydrate**: Cold Dried fish keeps for about 1 to 2 years and weighs very little. It can't go into recipes until **Rehydrate Fish** has soaked it, which uses 1 L of water. The soaked fish keeps how ripe it was: unripe it's dull (unhappiness +10), halfway it's plain, ripe it cheers you up (-10), and a soup or stew takes on its share.

**Fish Guts**: Gut Fish and Pack Fish in Salt both give one Fish Guts from a whole fish over 0.6 weight, the same size limit vanilla uses for filleting. The guts weigh 10% of the fish, and the fish loses that weight. Smaller fish, fillets and salmon give none and lose nothing. Filleting a fish later gives no more.

**Fish Head**: Gut Fish takes the head off, as stockfish makers did, and a whole fish over 1.0 weight gives a Fish Head named for its fish, such as Medium Walleye Head. It weighs 10% of the fish and takes 6% of its food, which the gutted fish loses. The limit is above the guts' 0.6 so small fish can't be farmed for heads. A head spoils like fresh fish (3 days fresh, 6 before rotting), makes you sick if eaten raw, and is a little unpleasant to eat even cooked. It goes into vanilla soups and stews or chum, and can't be dried. Pack Fish in Salt leaves the head on, as salted fish on the Volga were dried, so it gives no head.

**Fish Head Stock**: **Create Fish Head Stock** (Cooking, in hand, from the right-click Craft menu of the head or the pot) takes a Cooking Pot or Forged Pot holding 1.5 L of water and a Fish Head, and gives a Pot of Fish Head Stock. Unlike a vanilla stew, which only becomes a stew when its first ingredient goes in and that ingredient takes one of its 6 slots, the stock is a stew from the start and the head takes no slot. It takes the same ingredients as vanilla stew from the right-click menu under **Fish Head Stock**: **6 ingredients**, plus seasonings, which as in vanilla don't take a slot and go in once each. The head is listed among the ingredients in the tooltip. The pot is named for what went in, as a vanilla stew is but with the stock first: *Fish Head Stock with Fish and Carrots*. As in vanilla, two different foods of one type are named by the type (*with Vegetables*), seasonings are named only while there's room, and past 3 kinds it's just *Fish Head Stock*. The head itself isn't named. It starts with the same mood boost as a vanilla stew (unhappiness -20), and ingredients and seasonings change it from there as they do in a stew. It carries the head's food, must be cooked like a stew, keeps 3 days fresh and 5 before rotting, and gives the pot back when finished. **Divide Food into 4 Bowls** and **Divide Food into 2 Bowls** share it into bowls or clay bowls as vanilla does with a stew, and like vanilla's they need a table or counter nearby, giving Stew Bowls and the empty pot back.

**Slice Fish**: a whole fish over 0.6 weight can still be filleted with a sharp knife after it's been salted, dried or rehydrated, as a fresh one can. It gives 2 fillets at the same stage, each with half the fish's food and half its weight. (Vanilla's raw fillet is 5% of its fish: a cured fish has no guts left to lose.) Fillets and smaller fish can't be cut.

Fish keep their size and species through every stage, with the stage in brackets after the name and vanilla's freshness after that: *Gutted Small Largemouth Bass (Salt Pressed) (Fresh)*, then *(Salt Dried)*, or on the cold route *(Cold Dried, Unripe)*, then *(Cold Dried, Ripe)* and *(Rehydrated, Cold Dried, Ripe)*. Gutted and Half are part of the fish's name: "Gutted" stays on every stage of a fish that went through Gut Fish (it's the headless one). A fish packed whole keeps its head and isn't called gutted, though packing takes the guts of one over 0.6 weight. Names follow the days: they update every in-game hour for what you carry and when an inventory window shows a container. They also keep the original fish's icon, pale with salt once Salt Pressed, browned once Salt Dried, grey once Cold Dried and a darker brown or grey once rehydrated. A Gutted Fish is drawn without its head, as stockfish were, and stays headless through every later stage, and a Fish Half is that same fish split open, with red flesh and a backbone down the body and its fins and tail in the species' colours, and stays split through every later stage. Salted fish keep their heads, as small salted fish often do. Each fish also keeps its own weight and food, so a batch of mixed sizes comes out mixed too.

| Stage | Weight | Calories and nutrients | Hunger | Fresh / rotten days |
|---|---|---|---|---|
| Salt Packed | 90% | 100% | 100% | 3 / 6 |
| Salt Pressed | 79–84% | 100% | 100% | 7 / 14 |
| Salt Dried | about 37% | 90% | 70% | 120 / 180 |
| Rehydrated (salt) | about 66% | 90% | 100% | 2 / 4 |
| Gutted | 80% | 94% | 94% | 3 / 6 |
| Cold Dried | about 18% | 89% | 66% | 365 / 730 |
| Rehydrated (cold) | about 53% | 89% | 94% | 2 / 4 |

Percentages are of the whole fresh fish. They assume the fish was big enough to give guts (over 0.6 weight) and, on the cold route, a head (over 1.0). A fish too small for guts keeps that tenth of its weight at every stage. A cold-route fish of 1.0 weight or less keeps its head, so it's 90% when gutted, with all of its food. Pressing takes a random 7 to 12% of each fish's weight. Freshness carries over as a share of each stage's fresh days, so a fish half way to stale is still half way to stale when gutted or packed. The press starts the clock afresh, less what a warm cure took (see Seasons). Rehydrating carries the dried fish's share over, so an old dried fish gives a stale rehydrated one. A fillet vanilla cut counts as the food it holds once salted: it pays half its gutted fish's salt and comes out of the salt that heavy (9 times its raw weight).

## Seasons

You don't need to watch the forecast. Drying usually takes 12 to 55 days, and the time of year decides how a batch goes.

- **Salt drying** takes 12 days at full speed, which is 20 C or above in dry air. Cold slows it (at 10 C it runs at a quarter speed) and so does air above 50% humidity, but it never drops below about 44% speed, so frost slows it without stopping it.
- **Cold drying** takes 32 days at full speed: 0 to 5 C in a good breeze. Frost slows it (80% at -5 C, 60% below: ice leaves as vapour), so does warmth toward 10 C (67%), and it stops above 10 C. Wind sets the rest: 50% in still air, up to 120% at a wind intensity of 0.25 (`WIND_GOOD`). Live wind in a dry spell averages about 0.11, so a batch hung November to January takes about 50 to 55 days (a gameplay compromise: real stockfish hangs about three months).
- **Fresh fish is fragile**: until a cold stack is 30% dried (`FRESH_UNTIL`), hard frost below -5 C (a tenth of its keeping per 72 hours) and lying wet above 0 C (0.05 per 48 hours) add to its spoilage, scaled by how wet it still is, together never past a quarter (`DAMAGE_CAP`). Rot from a warm season is scaled the same way, so a nearly dry stack caught by an April warm spell loses little and a fresh one rots.
- **Rain**: open stations stop until it ends and the wet has dried off. Progress is paused, not lost. Snow counts as rain for salt fish but doesn't bother cold drying. Rain wets cold fish too, and it waits to dry off (its own wetness, `coldWetness`).
- **Three places.** Core's `Weather.placeOf(station, true)` reads the station's square:
  - **Open**: no roof overhead.
  - **Covered**: a roof overhead but not a room (a porch, an open shed, a floor above with no walls round it). Rain can't reach it. Salt fish dries at the open-air rate in the shade, and the sun can't scorch it. Cold drying runs at 75% (`COVERED_COLD_RATE`): the roof breaks some of the wind, but rain never pauses it and wet never harms it.
  - **Indoors**: a room, either a map building's or a space you built with walls all round and every square roofed (the engine's `isInARoom`). Salt fish runs at 65%, as when fish was dried indoors with the windows open, about 21 to 27 days. Cold drying needs moving air, so it stops indoors.

Spoilage goes by the season, not the day: it follows the average temperature of the last 10 days or so, so a warm afternoon in January does nothing.

- **Gutted fish** spoils once that average is above 10 C. It rots on the frame after 2 days at 10 C, sooner the warmer it gets, and the stack comes out rotten straight away.
- **Salt fish** only suffers when the average is above 22 C and the humidity above 40%. Each day of that takes a twentieth of the finished fish's keeping time. In practice that's a few days in a hot July.
- **Hot sun** (above 25 C, `HEAT_ABOVE`) on an open salt stack under half dried (`SALT_FRESH_UNTIL`) hardens the skin over wet flesh and rusts the fat: each 24 hours of it takes 5% (`HEAT_DAMAGE`) off the keeping, scaled by how wet it still is, within the same quarter (`DAMAGE_CAP`). A covered or indoor frame is in the shade. On the forecasts that costs an open stack 2 to 6% from May to August.
- **A warm cure**: while the season averages above 20 C (`WARM_CURE_ABOVE`), fish in the tub sours by the spine before the salt reaches it. It picks up spoilage at a quarter of raw fish's rate (`WARM_CURE_SHARE`), plus as much again for each 10 degrees over: a day at 21 C costs about 14% of its keeping, two days at 25 C about 38%. The pressed fish carries that share onto the frame (by weight, for a stack of mixed fish), and the tub's popup shows it while pressing. A 2-day press lost 17% in July and 5% in August here.

Weather is recorded every 10 in-game minutes for the whole world, so frames keep drying while you are away.

This is how a batch hung in each month went, on the game's own forecasts for default weather. Rain timing is estimated, so treat the days as approximate. `tools/season_report.lua` prints this table.

| Month | Mean C | Mean humidity | Salt, open | Salt, covered | Salt, indoors | Salt keeping lost (open / covered) | Cold, open | Cold, covered | Cold batches rotted | Cold keeping lost | 2-day press lost |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Jan | -4 | 0.24 | 28–33 d | 27 d | 27 d | 0% / 0% | 51–55 d | 60–65 d | 0% | 20% | 0% |
| Feb | -1 | 0.22 | 29–33 d | 27 d | 27 d | 0% / 0% | 52–93 d | 63–101 d | 3% | 16% | 0% |
| Mar | 3 | 0.25 | 29–33 d | 26–27 d | 27 d | 0% / 0% | 74 d | — | 97% | 18% | 0% |
| Apr | 8 | 0.30 | 22–30 d | 20–26 d | 24–27 d | 0% / 0% | — | — | 100% | — | 0% |
| May | 15 | 0.34 | 16–25 d | 15–20 d | 22–25 d | 2% / 0% | — | — | 100% | — | 0% |
| Jun | 19 | 0.35 | 16–20 d | 14–17 d | 21–23 d | 4% / 0% | — | — | 100% | — | 0% |
| Jul | 21 | 0.45 | 15–18 d | 14–17 d | 21–23 d | 6% / 1% | — | — | 100% | — | 17% |
| Aug | 18 | 0.35 | 17–24 d | 14–20 d | 22–25 d | 2% / 0% | — | — | 100% | — | 5% |
| Sep | 15 | 0.33 | 17–34 d | 16–26 d | 23–27 d | 1% / 0% | — | — | 100% | — | 0% |
| Oct | 8 | 0.27 | 30–34 d | 26–27 d | 27 d | 0% / 0% | 52–57 d | 65–69 d | 30% | 15% | 0% |
| Nov | 0 | 0.24 | 29–30 d | 27 d | 27 d | 0% / 0% | 50–52 d | — | 0% | 10% | 0% |
| Dec | -4 | 0.19 | — | 27 d | 27 d | 0% / 0% | — | — | — | — | 0% |

Humidity stays low in the game all year, mostly 20 to 45%, so it barely changes drying. That is why it only matters for salt fish in high summer. Salt fish under a roof lost about 1% of its keeping time at worst here; in the open, the summer sun takes a few percent more. Blanks mean no batch hung that month finished inside the forecast data.

## Sandbox options

Under Traditional Preservation (Fish) in the sandbox options: **Salt drying time** (12 days), **Slowest salt drying** (27 days), **Stockfish drying time** (32 days), **Stockfish maturing time** (60 days), **Salt press time** (2 days for a batch with a big fish; small fish half) and **Spoilage strictness** (Off, Forgiving, Normal, Harsh). The defaults are set from the season report: stockfish hung from late October to January dries outdoors in about 50-55 days, salt fish in 15-34. Before 0.3.7 stockfish drying followed salt drying at 8/3; it is its own option now.

## Tuning

Times, capacity, stage values, weather rates and spoilage limits are at the top of `42/media/lua/shared/TraditionalPreservationFish.lua`. `PRESS_HOURS` (the longest press; `PRESS_MIN_HOURS` and the two `PRESS_..._WEIGHT` values set the rest), `DRY_HOURS` and `COLD_DRY_HOURS` set the recipe times when the game starts, so they are the only times to edit. Restart the game after changing them. Slot counts are set in the entity scripts and recipes. A station keeps the counts it was built with, even when picked up and placed again.

`tools/build_tileset.py` repaints the stations, hanging fish, icons, the mod list icon and model textures, tints the vanilla fish icons, and writes `42/media/scripts/TraditionalPreservationFish_models.txt` (needs Pillow and the game files). `tools/build_model.py` writes the Stockfish Bale's ground model (`42/media/Models_X/StockfishBale.glb`), its texture and icon (needs Pillow, numpy and the game files). It also writes the generated `42/media/lua/shared/TraditionalPreservationFish/Tiles.lua`, the tile numbers the Lua reads (don't edit it by hand), and `luajit tests/test_tiles.lua` checks the entity scripts against it. `luajit tests/test_curing.lua` checks the curing rules, `luajit tests/test_ui.lua` the station slots and popup, `luajit tests/test_world.lua` the station sprites and the weather record, `luajit tests/test_pallet.lua` the Stockfish Pallet and Bale, and `luajit tests/test_console.lua` the debug commands. The season table above is for the default settings. `luajit tools/season_report.lua` runs the rules against `tools/climate_year.csv`, about a year and a half of forecasts read from the game, so run it after changing any rates. `tools/climate_wind.csv` adds a year of the game's forecast wind (one world per start month), for the coming wind curve.

The shared Traditional Preservation core (season averages, station tracking, popups) is the required TP Core mod (`~/MODS/TraditionalPreservationCore`), loaded as `require "TraditionalPreservationCore/Weather"`. Edit it there. The drying and spoilage rates, wetness and the frame's stacks stay in this mod's own files.

## Debug commands

In debug mode, `TPF.help()` in the Lua console lists commands for testing this mod. They are described in `DEVHELP.md`.

## Known prototype caveats

- **Not fully tested in play.** Building, the station windows and sprites have been seen in-game. Seasons, spoilage and the sandbox options haven't been played through.
- A pressing batch's hover popup is the mod's own too: the tub's recipe time is the longest press, so vanilla's
  would count a small batch down from 2 days.
- A hanging stack's hover popup is the mod's own, built from the same weather rules as drying. Its Time Remaining assumes the weather holds. The window's Time Required line above the slots stays at the recipe's base time, and the popup's layout is copied from vanilla, so compare the two after a game update.
- A covered or indoor frame uses the outdoor temperature, so heating the room doesn't speed it up.
- A stack that rots shows its finished sprite until collected.
- Vanilla's cutting can also give a roe sac in season. Gutting and packing only give guts, and gutting a head.
- Vanilla's Divide Food into Bowls only knows vanilla's pots, so the stock has its own two copies of it. Compare them with vanilla's after a game update.
- In a dish's "Contains" list, a fish stage shows one icon for that stage, not its species. Each stage picks its species model when it is made, and the tooltip makes a fresh one every frame, so the list records a stand-in item (`...Ingredient`) instead. Dish names are unaffected.
- Every Fish Head shares one icon, a largemouth bass's head, and lies on the ground as that icon at half size (`ScaleWorldIcon = 0.5`, as the icon art is doubled), as there is no head mesh.
- The season figures come from the game's forecasts for default weather, not from a played year. Sandbox temperature settings will shift them.
- A fish over 4.5 weight has to be gutted and split before it's packed in salt; a fish over 50 weight won't fit on a Fish Gantry, so split it to cold dry.
- The tub holds 35 items at most and a frame stack 25, so fillets under 0.1 weight fill a stack by count before weight.
- A stack's hanging look is picked at random, so it may not match the fish in it. The beams only hang walleye and sauger shapes, as wide fish look wrong at that size.
- On the ground most stages are the vanilla model of that species with a repainted texture, using `WorldStaticModelsByIndex`. Both sides of a fish share one texture, so a gutted fish keeps its head, flecked red, with a pink belly. A half uses the fillet mesh instead, redder, with that species' skin around its edge. Cooked and rotten fish keep their uncooked ground model. Fillets, salmon and fish from other mods use a tinted fillet.
- The tub's and frames' add limits go through the core's `UI.slotRules`, whose add loop is copied from vanilla's `ISCraftLogicPanel.ItemSlotAddItems`, so compare the two after a game update.
- The tiledef number 5129 must be unique among your active mods. A tileset holds 512 tiles at most, and going over drops the whole tile file and every placed station, so the beams are in a second tileset.
- Multiplayer is not supported. This mod is singleplayer only for now.

## Test plan

Already passed: the curing rules (offline), a simulated year on the game's forecasts, scripts, recipes, tiles and sandbox options on a headless server, and building and hanging fish in the game. Still to check in the real game:

1. The tub and frame appear in the build menu at the right Carpentry level and consume the listed materials. Both facings work.
2. Pack Fish in Salt accepts a whole fish and a fillet, fresh or stale, keeps the knife, accepts a part-eaten fish and keeps it part-eaten, and refuses cooked, rotten and frozen fish. The tub refuses rotten and frozen packed fish, and the frame refuses rotten, frozen and cooked pressed fish. Every stage shows the original fish's icon, salted when Salt Pressed, browned when Salt Dried and grey when Cold Dried, including after a save and reload.
3. The tub shows fish in the salt when loaded, and a board sunk into the salt with stones on it when started, which hides them, on both facings. The board stays until the last fish is out.
4. A full 35-item tub presses and finishes correctly. A slot only shows a green border for fish it will really take, and a refused drop says why. The tub takes only Salt Packed fish, and the drying stations only Salt Pressed fish, Gutted Fish and halves. Adding past 50 weight stops at the limit with a message. Adding while pressing, or before the output is emptied, is refused with a message.
5. Pressing takes 1 day for a batch of small fish and 2 days with a fish of 2.2 weight or more, at your Day Length, and finishes while you are away. Save and reload mid-press keeps the progress.
6. A mixed batch comes out with each fish's own name, weight and calories, including after a save and reload mid-press. Cancelling returns the same fish.
7. Each press of Craft hangs one stack with one sprite, which steps through all five looks as its progress rises. A finished stack keeps its sprite until its last fish is taken. Going over 2.5 in a stack or 8 stacks stops with a message, and a stack added later dries on its own clock. Check that a full 25-item stack and several stacks at once run and finish correctly.
8. Rain pauses an open frame and not a covered or indoor one, snow doesn't pause cold drying, and the Wetness readout appears. Drying continues after leaving the area and coming back.
9. Slice Fish appears for a fish that could be cut and not for a too-small fish or a fillet, at every stage, and gives 2 fillets that keep their age. Salt Dried fish goes into a soup. Rehydrate Fish uses 1 L of water and keeps the container.
10. Hovering a stack in progress shows its method, progress, time left, temperature, wetness and real drying rate, and a spoilage warning in a bad season, and the popup fits. Vanilla racks keep their usual popup. The frame's recipe list shows both hanging recipes, and each starts only with the right fish. A salted and a gutted stack can run on one frame at once, each on its own clock, and a mixed drop says why it was refused.
11. Gut Fish and Pack Fish in Salt each give one Fish Guts for a whole fish over 0.6 weight, at 10% of its weight, and none for a small fish, a fillet or salmon. The guts work in chum.
12. Gut Fish on a whole fish over 1.0 weight also gives a Fish Head, named for the fish (Medium Walleye Head), about 10% of the fish's weight. A fish of 1.0 or less gives none, and Pack Fish in Salt never does. The head cooks, goes into a soup or stew, and works in chum.
13. Create Fish Head Stock takes a pot with 1.5 L of water and a head, in a cooking pot and a forged pot. The tooltip lists Fish Head as an ingredient. The Fish Head Stock submenu offers stew ingredients and seasonings, allows 6 ingredients on top of the head, and seasonings as vanilla does, and the unhappiness starts at a vanilla stew's -20. It cooks, and eating it all gives the pot back. Divide Food into 4 Bowls and into 2 Bowls both appear for a cooked pot, give Stew Bowls named after the stock with its ingredients, and give the pot back.
14. Gutted Fish keeps its name and icon and can be cooked. A half shows its fish's own Half icon, including after a save and reload. Dropped on the ground, every stage shows that species' model with the right paint: tinted when salted, dried or rehydrated, pink belly and red-flecked head when gutted, a red fillet edged with that species' skin when halved. Split Fish appears only for one over 2.5 weight, and gives 2 halves. A Gutted Fish and a half can both be packed in salt, with no more guts.
15. Cold drying finishes a winter stack as Cold Dried fish. Cold stacks hang headless or split, fading to grey, and salt stacks whole, headless or split, fading to brown, on both facings. A stack keeps its look through running, finishing and a save and reload. A stack hung in a warm season comes out rotten in a few days. Frozen gutted fish hangs, and the frame takes no raw fish or fillets. Rehydrate Fish uses 1 L of water.
16. The Fish Hanging Beam and Fish Gantry appear in the build menu at the right Carpentry level, consume the listed materials and work on both facings. Neither can be placed in a room (a map building, or a space built with walls all round and a full roof); both can go under a porch or open-shed roof; the frame can go anywhere. Each takes its stack limit and number of stacks and stops with a message past that. Fish hang from the hooks, which go about a third of the way into each fish, clear of the beam, larger on the Gantry than the Beam, and both recipes work on both.
17. `console.txt` shows no repeating Lua errors after an hour of play.
