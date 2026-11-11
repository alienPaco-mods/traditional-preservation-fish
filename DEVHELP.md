# Traditional Preservation (Fish): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPF.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPF.weather()` | The drying weather now: temperature, the 10-day season average, humidity, wetness (open and cold frames), wind, the drying speed open, under a roof and cold, whether unsalted and salted fish are spoiling, and the running totals (with hours of hard frost and of cold fish lying wet). |
| `TPF.wind()` | Starts a log of the live wind (0-1) every 10 game minutes; run it again to print the mean, min and max on dry and on rainy or snowy spells, beside the forecast's mean wind for the same days, and stop. For setting the cold-drying wind curve. |
| `TPF.age(hours)` | Gives every hanging stack this many hours of perfect drying weather. `TPF.age(288)` finishes a salt stack, `TPF.age(768)` a cold one. |
| `TPF.spoil(hours)` | Adds spoiling weather, to test rotting. A fresh cold stack rots after 48; a part-dried one takes longer. |
| `TPF.frost(hours)` | Adds hours of hard frost. A cold stack under 30% dried loses a tenth of its keeping per 72 hours, at most a quarter in all with wet. |
| `TPF.heat(hours)` | Adds hours of hot sun (above 25 C). An open salt stack under half dried loses 5% of its keeping per 24 hours, times how wet it still is, at most a quarter. |
| `TPF.warmCure(hours)` | Adds hours of a warm cure at 25 C (1.5 x hours to `warmCure`). A batch in the tub loses about 0.8% of its keeping per hour. |
| `TPF.dry()` | Clears the wetness, so open and cold frames start drying again at once after rain. |
| `TPF.mature(days)` | Ages the Cold Dried fish you carry by this many days. Ripe after 60. |
| `TPF.stockfish(n)` | Spawns n unripe Cold Dried fish, as if fresh off the frame, for the pallet. |
| `TPF.pallet()` | Reports the Stockfish Pallet within 3 tiles: its place, how much faster it ripens, its stack (1-3 or none), its stockfish and the ripest one. |
| `TPF.fish(name, weight, n)` | Spawns `n` whole fish at that weight, with food scaled to match, e.g. `TPF.fish("Walleye", 4, 2)`. `TPF.fish()` lists the names. |
| `TPF.heads(n)` | Spawns Fish Heads (default food values). |
| `TPF.stock()` | Spawns a Pot of Fish Head Stock (default values, no head listed). |
| `TPF.salt(n)` | Spawns vanilla Salt shakers. |

The Salting Tub runs on the game clock, not the weather, so `TPF.age` doesn't speed up pressing. Use the game's own time controls for that.

**Typical check of the whole salt route:** `TPF.fish("Walleye", 4, 3)` and `TPF.salt(5)` (each 4 weight walleye takes 16 salt, and a shaker holds 10), pack and press, then hang the fish and `TPF.age(288)`.

**Typical check of heads:** `TPF.fish("Walleye", 4)` and `TPF.fish("Bluegill", 0.9)`, then Gut Fish on both. Only the walleye gives a head.
