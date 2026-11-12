# Traditional Preservation (Fish & Meat): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPFM.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPFM.weather()` | The drying weather now: temperature, the 10-day season average, the basement's, the loft's, a room's and a roof's temperatures and their drying and tub rates, humidity, wetness (open and cold frames), wind, the drying speed open, under a roof and cold, whether unsalted and salted fish are spoiling, and the running totals (with hours of hard frost and of cold fish lying wet). |
| `TPFM.here()` | Which place you're standing in, as a station there would read it: Open, Covered (a roof, no room), Sheltered (a room), Loft or Basement. |
| `TPFM.wind()` | Starts a log of the live wind (0-1) every 10 game minutes; run it again to print the mean, min and max on dry and on rainy or snowy spells, beside the forecast's mean wind for the same days, and stop. For setting the cold-drying wind curve. |
| `TPFM.age(hours)` | Gives every hanging stack this many hours of perfect drying weather. `TPFM.age(288)` finishes a salt stack, `TPFM.age(768)` a cold one, `TPFM.age(120)` a charque one, `TPFM.age(520)` a Country Cured cut in the Smokehouse (1010 with a leg). Corned meat hanging in a Smokehouse spoils with it as a 12 C shed would, so `TPFM.age(520)` rots it. |
| `TPFM.spoil(hours)` | Adds spoiling weather, to test rotting. A fresh cold stack rots after 48; a part-dried one takes longer. |
| `TPFM.frost(hours)` | Adds hours of hard frost. A cold stack under 30% dried loses a tenth of its keeping per 72 hours, at most a quarter in all with wet. |
| `TPFM.heat(hours)` | Adds hours of hot sun (above 25 C). An open salt stack under half dried loses 5% of its keeping per 24 hours, times how wet it still is, at most a quarter. |
| `TPFM.warmCure(hours)` | Adds hours of a warm cure at 25 C (1.5 x hours to `warmCure` and `warmCureRoom`). A batch in a tub above ground or in a room loses about 0.8% of its keeping per hour; a tub in a basement goes by its own totals (0.4.24) and takes none. |
| `TPFM.longCure(hours)` | Adds hours of a 15 C season (default 168) to a running Country Cure, which wants 10 C or less: a leg's cure rots after 504. |
| `TPFM.dry()` | Clears the wetness, so open and cold frames start drying again at once after rain. |
| `TPFM.mature(days)` | Ages the stockfish and the dry cured meat you carry by this many days. Stockfish is Matured after 60; a dry cured cut is Aged after 30, a Country Ham after 90. |
| `TPFM.food()` | Each cured fish or meat item you carry, with the numbers the game's tooltip rounds or hides: hunger, unhappiness, boredom, thirst, weight, age against its fresh / rotten days, and how far it has aged. |
| `TPFM.pallet()` | Reports the Stockfish Pallet within 3 tiles: its place, how much faster it ripens, its stack (1-3 or none), its stockfish and the ripest one. |
| `TPFM.fish(name, n, weight, stage)` | Spawns `n` fish, at that weight if given (food scaled to match), e.g. `TPFM.fish("Walleye", 2, 4)`. A stage gives it further along: `"cured"` (Salt Cured, ready to hang), `"dried"` (Salt Dried), `"hotSmoked"`, `"coldSmoked"` (each as its station gives a cured fish, nothing spoiled) or `"stockfish"` (young, fresh off the frame), and may take the weight's place: `TPFM.fish("Walleye", 3, "cured")`. `TPFM.fish()` lists the names; `"all"` gives one of each |
| `TPFM.meat(name, n, stage)` | Spawns `n` of a cut, e.g. `TPFM.meat("Steak", 2)`; `"all"` gives each of Beef, Steak, Mutton Chop, Venison, Pork, Pork Chop and Leg of Pork. A stage gives it further along: `"corned"` (*Steak (Corned)*; no leg), `"country"` (Country Cured), `"charque"` (a Corned cut dried on a frame; no pork), `"hotSmoked"` (a Corned cut from a stoked Smokehouse; pork comes out as the game's Ham, no leg) or `"dryCured"` (dry cured, smoked and young, to age and slice). `TPFM.meat()` lists the names |
| `TPFM.rain(hours)` | Adds this many hours of rain (default 6) and wets the open frames: an open charque stack loses a tenth of its progress per 6 hours. `TPFM.dry()` dries the frames off again. |
| `TPFM.give(name, n, option)` | Spawns `n` of: `"head"` (Fish Head), `"stock"` (Pot of Fish Head Stock), `"salt"` (vanilla shaker), `"fat"` (one each of Pork Fat, Beef Suet and Mutton Fat), `"fatPot"` (a Pot of Pork Fat, cooked; option `"burnt"` or `"raw"`), `"crock"` (a full Crock of Potted Meat: four Steaks in Lard in a Glazed Clay Jar). Default food values. `TPFM.give()` lists them |
| `TPFM.kit("potted")` | Spawns what Potted Meat takes: a Pot, Lard, Salt, a Steak, Beef, Pork Chop and Pork, and a Clay Jar, Glazed Clay Jar and Clay Pot. |
| `TPFM.crocks()` | Each Crock of Potted Meat on you or in containers within 4 tiles on your floor: its place (Fridge, Freezer, Basement, Sheltered, Open), keeping rate (x1 = a basement's 60 days), age, days until stale and rotten there, and whether it has been opened. |
| `TPFM.keep(days)` | Ages those crocks by this many days at their place's rate now (default 10). |
| `TPFM.kit("flue")` | Spawns both flue kits (2 Clay Pipe Segments, 3 Flat Stones, 3 Clay) with a Mason's Trowel and a Shovel. |
| `TPFM.smokehouse()` | Each Smokehouse chamber tile within 3 tiles on your floor: facing, back or door tile, the entry overlay it shows, and each Firebox beside it with its flue and why it can't join (or `may join`, `joined here`). |
| `TPFM.smoke()` | Each Smokehouse within 3 tiles: its joined Firebox's fire record (mode, stoked and banked hours, the session now running and its hours) and each stack's hot hours against its need, smoke hours against its need (`F.smokeHours`), dried hours, whether its cook is done, and for meat its dry-curing need, whether it has a leg and how far under-salting has spoiled it. |
| `TPFM.addSmoke(hours)` | Adds hours of smoke (default 60) straight to every stack in the Smokehouses within 3 tiles, whatever the weather or the fire. `TPFM.bank` only gives smoke on a day of 15 C or less, and says so when it is warmer. |
| `TPFM.underSalt(hours)` | Adds hours of a 10 C shed (default 168) for Corned meat hanging in a Smokehouse, a room or under a roof; it rots after 672. |
| `TPFM.stoke(hours)` | Adds stoked hours (default 1) to the running session of those joined Fireboxes; the stacks pick them up on the World's next look. Stoke the Firebox first: with no session running it says so. |
| `TPFM.bank(hours)` | Adds banked hours (default 6) to the record of those joined Fireboxes, as if they had smouldered that long: smoke for Cold Smoked (counted only if today is 20 C or less). |
| `TPFM.fatRows()` | Says whether the sandbox has butchering fat on, and prints the fat row of each vanilla pig, cow and sheep's butchering table (base numbers: about x2.8 on a Butchering Hook, x0.6 on the ground). |

The Salting Tub runs on the game clock, not the weather, so `TPFM.age` doesn't speed up curing. Use the game's own time controls for that.

**Typical check of the whole salt route:** `TPFM.fish("Walleye", 3, 4)` and `TPFM.give("salt", 10)` (each 4 weight walleye takes 28 salt, and a shaker holds 10), pack and cure, then hang the fish and `TPFM.age(288)`.

**Typical check of rendering:** `TPFM.give("fat", 2)`, a Pot, Put Pork Fat in a Pot, cook it on any stove or fire (60 minutes), Pour Off Lard: the pot holds 0.5 L Lard (Melted); Strain Lard (with a Rag or other cloth, or a Strainer): one Lard, one Cracklings, the pot kept.

**Typical check of Potted Meat:** `TPFM.kit("potted")`, Put Meat in Lard or Tallow (the Steak), Add Meat to the Pot three times (a fifth is refused), cook it on any stove or fire (120 minutes), Pack Potted Meat into the Glazed Clay Jar: "Crock of Potted Meat (4 portions)", glazed look, the pot back. Eat a quarter: 3 portions, lighter. Eat the rest: the Glazed Clay Jar comes back.

**Typical check of keeping by place (4c):** three crocks, one in a powered fridge, one in a basement, one in a room upstairs; stand by each and `TPFM.crocks()`: Fridge x0.50 (120 days), Basement by its damped temperature (x0.55 at 5 C in January, x0.94 at 14 C in July), the room by the season mean (22 C while the grid is on) (x0.5 at 4 C and below, x1 at 15 C, x4.29 at 25 C and up). `TPFM.keep(30)` by each: about 15, 30 and up to 128 days old. Eat a quarter of one: it loses a third of its days to stale once (`opened`); a second bite costs nothing.

**Typical check of the copper:** `TPFM.give("fat", 6)`, a lit Hearth, Put Fat in the Copper (Pork Fat), wait for it to steam and an hour more, Fill from Copper into a pot, Strain Lard three times.

**Typical check of hot smoking:** a Smokehouse with a Firebox joined (`TPC.kit("firebox")`, `TPFM.kit("flue")`), `TPFM.meat("all", 2, "corned")` and `TPFM.fish("Walleye", 3, "cured")`, hang one stack of each, light the Firebox, `TPFM.smoke()` (a session, hot 0 of 6-8 and 4), `TPFM.stoke(8)`: within a second both come out Hot Smoked and a ham hangs by the door. For a broken run: stoke 2 h, bank it and wait over an hour: hot back to 0, Smoke 2.0 h.

**Typical check of heads:** `TPFM.fish("Walleye", 1, 4)` and `TPFM.fish("Bluegill", 1, 0.9)`, then Gut Fish on both. Only the walleye gives a head.
