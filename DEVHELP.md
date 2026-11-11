# Traditional Preservation (Fish): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPF.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPF.weather()` | The drying weather now: temperature, the 10-day season average, humidity, wetness, the drying speed open, under a roof and cold, whether unsalted and salted fish are spoiling, and the running totals. |
| `TPF.wind()` | Starts a log of the live wind (0-1) every 10 game minutes; run it again to print the mean, min and max on dry and on rainy or snowy spells, beside the forecast's mean wind for the same days, and stop. For setting the cold-drying wind curve. |
| `TPF.age(hours)` | Gives every hanging stack this many hours of perfect drying weather. `TPF.age(288)` finishes a salt stack, `TPF.age(480)` a cold one. |
| `TPF.spoil(hours)` | Adds spoiling weather, to test rotting. A cold stack rots after 48. |
| `TPF.dry()` | Clears the wetness, so open frames start drying again at once after rain. |
| `TPF.fish(name, weight, n)` | Spawns `n` whole fish at that weight, with food scaled to match, e.g. `TPF.fish("Walleye", 4, 2)`. `TPF.fish()` lists the names. |
| `TPF.heads(n)` | Spawns Fish Heads (default food values). |
| `TPF.stock()` | Spawns a Pot of Fish Head Stock (default values, no head listed). |
| `TPF.salt(n)` | Spawns vanilla Salt shakers. |

The Salting Tub runs on the game clock, not the weather, so `TPF.age` doesn't speed up pressing. Use the game's own time controls for that.

**Typical check of the whole salt route:** `TPF.fish("Walleye", 4, 3)` and `TPF.salt(5)` (each 4 weight walleye takes 16 salt, and a shaker holds 10), pack and press, then hang the fish and `TPF.age(288)`.

**Typical check of heads:** `TPF.fish("Walleye", 4)` and `TPF.fish("Bluegill", 0.9)`, then Gut Fish on both. Only the walleye gives a head.
