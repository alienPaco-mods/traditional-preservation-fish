# Traditional Preservation (Fish & Meat): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPFM.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPFM.weather()` | The drying weather now: temperature, the 10-day season average, humidity, wetness (open and cold frames), wind, the drying speed open, under a roof and cold, whether unsalted and salted fish are spoiling, and the running totals (with hours of hard frost and of cold fish lying wet). |
| `TPFM.wind()` | Starts a log of the live wind (0-1) every 10 game minutes; run it again to print the mean, min and max on dry and on rainy or snowy spells, beside the forecast's mean wind for the same days, and stop. For setting the cold-drying wind curve. |
| `TPFM.age(hours)` | Gives every hanging stack this many hours of perfect drying weather. `TPFM.age(288)` finishes a salt stack, `TPFM.age(768)` a cold one. |
| `TPFM.spoil(hours)` | Adds spoiling weather, to test rotting. A fresh cold stack rots after 48; a part-dried one takes longer. |
| `TPFM.frost(hours)` | Adds hours of hard frost. A cold stack under 30% dried loses a tenth of its keeping per 72 hours, at most a quarter in all with wet. |
| `TPFM.heat(hours)` | Adds hours of hot sun (above 25 C). An open salt stack under half dried loses 5% of its keeping per 24 hours, times how wet it still is, at most a quarter. |
| `TPFM.warmCure(hours)` | Adds hours of a warm cure at 25 C (1.5 x hours to `warmCure`). A batch in the tub loses about 0.8% of its keeping per hour. |
| `TPFM.dry()` | Clears the wetness, so open and cold frames start drying again at once after rain. |
| `TPFM.mature(days)` | Ages the Cold Dried fish you carry by this many days. Ripe after 60. |
| `TPFM.stockfish(n)` | Spawns n unripe Cold Dried fish, as if fresh off the frame, for the pallet. |
| `TPFM.pallet()` | Reports the Stockfish Pallet within 3 tiles: its place, how much faster it ripens, its stack (1-3 or none), its stockfish and the ripest one. |
| `TPFM.fish(name, weight, n)` | Spawns `n` whole fish at that weight, with food scaled to match, e.g. `TPFM.fish("Walleye", 4, 2)`. `TPFM.fish()` lists the names. |
| `TPFM.heads(n)` | Spawns Fish Heads (default food values). |
| `TPFM.stock()` | Spawns a Pot of Fish Head Stock (default values, no head listed). |
| `TPFM.salt(n)` | Spawns vanilla Salt shakers. |
| `TPFM.fat(n)` | Spawns `n` each of Pork Fat, Beef Suet and Mutton Fat (default food values). |
| `TPFM.meat(n)` | Spawns `n` each of the cuts Pack Meat in Salt takes: Beef, Steak, Mutton Chop, Venison. |
| `TPFM.fatPot(state)` | Spawns a Pot of Pork Fat: `"cooked"` (the default, ready to pour off), `"burnt"` (only Scrape Out Burnt Fat takes it) or `"raw"`. |
| `TPFM.fatRows()` | Says whether the sandbox has butchering fat on, and prints the fat row of each vanilla pig, cow and sheep's butchering table (base numbers: about x2.8 on a Butchering Hook, x0.6 on the ground). |

The Salting Tub runs on the game clock, not the weather, so `TPFM.age` doesn't speed up pressing. Use the game's own time controls for that.

**Typical check of the whole salt route:** `TPFM.fish("Walleye", 4, 3)` and `TPFM.salt(5)` (each 4 weight walleye takes 16 salt, and a shaker holds 10), pack and press, then hang the fish and `TPFM.age(288)`.

**Typical check of rendering:** `TPFM.fat(2)`, a Pot, Put Pork Fat in a Pot, cook it on any stove or fire (60 minutes), Pour Off Lard: the pot holds 0.5 L Melted Lard; Strain Lard (with a Rag or other cloth, or a Strainer): one Lard, one Cracklings, the pot kept.

**Typical check of the copper:** `TPFM.fat(6)`, a lit Hearth, Put Fat in the Copper (Pork Fat), wait for it to steam and an hour more, Fill from Copper into a pot, Strain Lard three times.

**Typical check of heads:** `TPFM.fish("Walleye", 4)` and `TPFM.fish("Bluegill", 0.9)`, then Gut Fish on both. Only the walleye gives a head.
