# Traditional Preservation (Fish & Meat) — Build 42 prototype (v0.4.15)

**Status: experimental.** The stations build, open and hang fish and meat in the game, but a full year hasn't been played. Back up your save before enabling.

Preserves fish and meat the old way, with no power: salt, wood, fat, smoke and the weather. One workshop serves both: the same Salting Tub cures fish and meat, the same drying stations hang both, the Smokehouse smokes both, and butchering gives the fat that seals meat in a clay jar. The player guide is `1_FishMeat_Guide.md` in this folder.

| Road | Fish | Meat | Season | Keeps |
|---|---|---|---|---|
| Salt and dry | Salt Dried fish | Charque (beef, mutton, venison) | Any for fish; summer for charque | 120 / 180 days |
| Freeze-dry in the wind | Stockfish | - | Winter | 365 / 540 days |
| Hot smoke | Hot Smoked fish | Hot-Smoked meat | Any | 7 / 14 days, ready to eat |
| Cold smoke | Cold Smoked fish | Suho Meso (beef), Mutton Ham, Jerked Venison, Smoked Dry-Cured Pork, Smoked Country Ham | Days of 15 C or less | 120 / 180 days, ready to eat (a ham 180 / 365) |
| Dry cure in cool air | - | Bresaola (beef), Dry-Cured Mutton / Venison / Pork, Country Ham | Cool months, no fire needed | The same |
| Under fat | - | Potted Meat (any red meat, pork too) | Any | By place: 14 to 120 days fresh |

## History

The salt route is the lower Volga's: around Astrakhan, fish is salted in vats under a weighted lid, soaked, and dried in the shade, small fish such as vobla whole with their heads on and large ones such as pike split or hung from hooks. Stockfish is unsalted fish hung on open racks through the cold northern Norwegian spring, matured in airy warehouses and traded across Europe since the Viking age. Charque comes from the *charqueadas* of southern Brazil: beef salted in piles, washed and dried in the summer sun, always soaked before it is cooked. Potted Meat is Turkish *kavurma*, French *confit* and the Balkan *meso u masti*: meat cooked in fat and sealed in clay for the winter. The Smokehouse is the Kentucky farm smokehouse and the Bosnian *pušnica*, fed from a low firebox outside the wall; hot smoking follows the Volga's hot-smoked fish.

## Install

Copy this folder to `~/Zomboid/mods/TraditionalPreservationFishMeat`, as a real copy rather than a symlink. It needs the **TP Core** mod (`TraditionalPreservationCore`, the series' shared mod) installed and enabled the same way, and no other mods.

## How it works

### Preparing fish and meat

- **Gut Fish** (a raw whole fish, a sharp knife or meat cleaver kept): a Gutted Fish, which keeps like fresh fish and must be cooked like one, plus Fish Guts and a Fish Head if it has them. Fillets can't be gutted.
- **Split Fish**: a Gutted Fish over 2.5 weight, too heavy for a frame stack, becomes two Fish Halves, each half the weight and food, named for the fish (*Medium Walleye Half*).
- **Slice Fish**: a whole fish over 0.6 weight can still be filleted after it's been salted, dried or rehydrated: 2 fillets at the same stage, each with half the fish's food and weight (a cured fish has no guts left to lose). Fillets and smaller fish can't be cut.
- **Fish Guts**: Gut Fish and Pack Fish in Salt both give one from a whole fish over 0.6 weight, vanilla's filleting limit. They weigh 10% of the fish, which loses that weight. Smaller fish, fillets and salmon give none. Filleting later gives no more.
- **Fish Head**: Gut Fish takes the head off a whole fish over 1.0 weight (above the guts' 0.6, so small fish can't be farmed for heads): *Medium Walleye Head*, 10% of the weight and 6% of the food. It spoils like fresh fish (3 / 6 days), makes you sick raw, is a little unpleasant even cooked, goes into soups, stews or chum, and can't be dried. Pack Fish in Salt leaves the head on, as salted fish on the Volga were dried.
- **Fish Head Stock**: **Create Fish Head Stock** (Cooking, in hand) takes a Cooking Pot or Forged Pot holding 1.5 L of water and a Fish Head. Unlike a vanilla stew, it's a stew from the start and the head takes no slot: **6 ingredients** plus seasonings, under **Fish Head Stock** in the right-click menu. It's named for what went in (*Fish Head Stock with Fish and Carrots*; two foods of one type by the type; past 3 kinds just *Fish Head Stock*), starts at a vanilla stew's unhappiness -20, carries the head's food, keeps 3 / 5 days and gives the pot back. **Divide Food into 4 Bowls** / **2 Bowls** share it as vanilla does a stew, at a table or counter.
- **Meat** goes to the salt or the pot as vanilla's butchering cuts it, no knife work: Beef and Venison 0.5 weight, Steak and Mutton Chop 0.3, Pork 0.5, Pork Chop 0.3.
- **Leg of Pork** (for country ham): an adult pig gives some of its Pork as whole legs, 2.5 weight each. Five of the Pork it just gave make one leg, which takes their food, so the pig's meat stays vanilla's; at most half its Pork goes, and three legs. On a Butchering Hook about one or two (two or three from a big pig), from the ground usually none. Piglets give none. Sandbox *Butchering gives legs of pork*.
- **Fat from butchering**: pigs give Pork Fat, cattle Beef Suet, sheep Mutton Fat (on a Butchering Hook about 5-7, 8-10 and 2-4 for an average animal; 1 or 2 on the ground). Young animals and deer give none. See *Fat* below.

### The Salting Tub

**Build** (Carpentry 2, Fishing 2): 4 planks, 6 nails, 2 twine; hammer and saw kept. It holds 50 weight or 35 items, fish **or** meat.

1. **Pack in salt.** **Pack Fish in Salt**: a raw fish, fillet, Gutted Fish or Fish Half and a sharp knife or meat cleaver (kept). Fresh, stale or part-eaten, not rotten, frozen or cooked. **Pack Meat in Salt**: a Beef, Steak, Mutton Chop, Venison, Pork, Pork Chop or Leg of Pork, no knife. Salt goes by the packed weight: 4 for each started half weight, about 15% (Volga salters use 10 to 15%): a bluegill 4, a 4 weight walleye 32, a 4.5 weight walleye 36, any meat cut 4; a Leg of Pork half that, 2 a started half weight (about 8%, a country ham's dry cure), 10 for a 2.5 leg. A whole or gutted fish over 4.5 weight (about 2 kg) is too thick to salt whole: gut it, split it and pack the halves. Salt in a container in reach covers the first 2; the rest must be on you (bags count). Any salt works (a vanilla shaker holds 10, the Salt mod's Evaporated Salt 5 and a Bag of Salt 50), part-used salt first. Salt Packed fish and meat keep 3 / 6 days.
2. **Cure.** Pick the recipe, load the tub, press Craft. The board and stones go on until the salt has gone through the thickest piece, so the heaviest sets the time. **Cure Salted Fish**: 1 day if all are up to 1.1 weight, 2 days with one of 2.2 or more, in between by weight; out comes **Salt Cured** fish. Meat has two cures. **Corn Salted Meat**, the short one, for charque and hot smoking: 2 days for a 0.5 cut, by weight for lighter ones (about 29 hours for Steaks and Chops), never under a day; out comes **Corned** meat (*Corned Steak*). A Leg of Pork is too thick for it: with Corn selected the slot's border goes red for a leg and refuses it, and if a leg is already in, Craft says so and doesn't start. **Country Cure Salted Meat**, the long one, for the Smokehouse's dry-cured meat and country ham: **10 days** for cuts, **21** if a Leg of Pork is in the batch; out comes **Country Cured** meat (*Country Cured Leg of Pork*). The clock runs while you're away, and the tub stays closed until the last piece is out. Salt Cured fish, Corned and Country Cured meat keep 7 / 14 days and must be cooked to eat.
3. **Rinse, if you like.** **Rinse Off Salt** (a recipe in the piece's submenu, 0.15 L of clean carried water each, batches in the Craft window, works in the dark) or **Rinse at Sink** (a sink, bathtub, barrel or well of clean water within 3 tiles). Tainted water is refused. Rinsed, every later stage is less salty (two thirds of the thirst; Salt Dried fish also loses its unhappiness) and keeps a tenth less long. Skipping it changes nothing.

**A warm cure**: while the season averages above 20 C, the flesh by the spine starts to spoil (bone taint) before the salt reaches it. The batch picks up spoilage that shortens the finished food's keeping: a day at 21 C about 14%, two days at 25 C about 38%. The tub's popup shows it while curing (*Spoiling (Warm cure)*). The long cure is a cold-season job, as country hams were salted from the first hard frost: 10 days in a warm season costs a cut most of its keeping, and 21 rots a leg. **The long cure wants the cold** (0.4.14, `F.LONG_CURE_ABOVE` 10, `F.LONG_CURE_ROT_AT` 15, ledger total `longCureSpoil`, the batch's `lastLongCure`): above a season mean of **10 C** a Country Cure batch spoils in step with the warmth, rotten after a leg's 21 days at 15 C; at 12 C a leg loses 40% and cuts 19%, at 15 C cuts lose 48%. So dry-cured meat and ham are an October-to-April craft, with no season lock.

### The drying stations

Each press of Craft hangs one stack, which dries on its own timer and keeps its spot until collected; you can keep adding stacks while others dry. A stack is one kind (salt fish, gutted fish or meat), but a station runs all kinds side by side. Each stack picks its hanging look at random when it starts (a salt stack usually whole, a cold one usually headless), and the sprite changes colour and thins in five steps as it dries.

| Station | Build (hammer kept) | Holds | Where |
|---|---|---|---|
| **Fish Drying Frame** | Carpentry 2, Fishing 2: 6 long sticks, 3 nails, 4 twine | 8 stacks of 2.5 weight | Anywhere |
| **Fish Hanging Beam** | Carpentry 4, Fishing 2: 6 planks, 6 nails, 1 large hook | 4 stacks of 15 | Open air or under an open roof |
| **Fish Gantry** | Carpentry 6, Fishing 2: 2 logs, 2 planks, 8 nails, 2 large hooks | 2 stacks of 50 | Open air or under an open roof |
| **Smokehouse** | Carpentry 3: 14 planks, 20 nails | 6 stacks of 15 | Open air or under an open roof; two tiles |

The frame, Beam and Gantry take **Hang Salt Cured Fish to Dry**, **Hang Salted Meat to Dry** and **Hang Gutted Fish to Cold Dry**; the Smokehouse takes the first two. **Country Cured meat, pork too, hangs in the shade** (0.4.15, `F.meatRefusal`): in the Smokehouse, or on a **Frame, Beam or Gantry under a roof**, or a **Frame or Beam in a room or a basement**, where it dry cures to air dried meat (below); never in the open (sun and rain are charque's). **Corned pork hangs in the Smokehouse only**, for its hot cook. A frame, Beam or Gantry takes Corned beef, mutton and venison anywhere, for charque. Beam and Gantry fish hang larger on their hooks. A fish heavier than a stack's limit has to be sliced or split, or hung on a bigger station. Hover a stack for its method, progress, time left, place, temperature, wind, wetness, drying rate, smoke and any spoilage.

### Salt Dried fish

**Hang Salt Cured Fish to Dry**: 12 days at full speed (20 C or warmer in dry air). Salt Dried fish keeps 120 / 180 days (rinsed 108 / 162), is very salty but safe as it is, and goes straight into soup, stew, rice or pasta. **Rehydrate Fish** (1 L of water) gives a mild fish that cooks like fresh and keeps 2 / 4 days, a darker brown than fresh fish as real soaked fish is. Packed and cured fish aren't safe yet: only drying makes salt fish safe uncooked.

### Charque

**Hang Salted Meat to Dry**: 5 days at full speed, in hot sun (25 C and up) and a breeze. It slows in cooler weather (two fifths at 10 C) and stops at freezing; still air dries at two thirds, a good breeze adds a fifth; rain on an open station takes back a tenth of the progress every 6 hours. About a week in a Kentucky summer under a roof. **Charque** (*Beef Charque*, *Mutton Charque*, *Venison Charque*) weighs about half the raw cut, keeps 90% of the food, keeps 120 / 180 days, and can't be eaten until **Rehydrate Charque** (1 L of water) soaks it: *Beef Charque (Soaked)* is a little salty, cooks like a steak, goes into stews and pies, and keeps 2 / 4 days.

### Stockfish (the cold route)

1. **Gut Fish** (and **Split Fish** if needed).
2. **Hang Gutted Fish to Cold Dry** on a frame, Beam or Gantry in the open or under an open roof (never in a room or the Smokehouse: it needs moving air). Frozen fish is fine. A stack can't mix gutted and salted fish. The hanging fish fade to grey.
3. 32 days at full speed: 0 to 5 C in a good breeze; about 50 to 55 days hung November to January.
4. **Mature**: stockfish matures in storage over 60 days on the fish's own food clock: any container works, a fridge slows it and a freezer stops it. Young it's plain *Walleye Stockfish*, matured *Walleye Stockfish (Matured)*, and the tooltip shows how far along it is. Fish made before 0.3.3 count as ripe. A **Stockfish Pallet** (build menu: Carpentry 2, 3 planks, 6 nails, hammer and saw kept; a 20 weight container) speeds it where the warehouses kept stockfish: a loft (a room upstairs) ×2, 30 days, a ground-floor room ×1.5, 40 days; covered, outdoors or in a basement no faster than a shelf. Right-click it to see its speed. It shows a stack of stockfish, a third, two thirds or full by weight, while it holds nothing else. A **Stockfish Bale**: right-click selected stockfish, *Tie a Bale*, with one use of Twine or a Rope. It holds 10 weight of stockfish and nothing else (weight reduction 30), the fish keep ripening inside, on a pallet too, and *Untie Bale* gives the fish and the cord back.
5. **Rehydrate Fish** (1 L of water) before eating (*Walleye Stockfish (Soaked)*): stockfish is as hard as wood and keeps 365 / 540 days, enough to reach next winter's fish. The soaked fish keeps how ripe it was: unripe it's dull (unhappiness +10), halfway plain, ripe it cheers you up (-10), and a soup or stew takes its share.

### The Smokehouse, hot and cold smoking

A plank shed two tiles long under one roof slope, the door on the high end. Inside it's always **Indoors**: no rain, no wind, salt fish at about two thirds of the open speed, meat dry curing, no stockfish. The tile in front of its door stays clear, and nothing can be built there.

**Connect the Firebox**: TP Core's **Firebox** (Masonry 2: 8 Clay Bricks, 2 Clay, trowel kept) on a tile beside the shed joins it with a **clay pipe** (2 Clay Pipe Segments + 1 Clay, Mason's Trowel kept) or a **stone trench** (3 Flat Stones + 2 Clay, a shovel or spade kept). No skill, about half an hour, a little Masonry XP. On the Firebox's menu and the shed's right-click. It may stand by either long side or the back, not at the door end and not with its own door towards the shed; one Firebox a shed; the fire must be out. **Disconnect** gives the pipe or stones back (the clay is lost). Joined, neither picks up. Firebox Info says where its flue goes and what it does.

**Hot smoking**: every salt stack (Salt Cured fish, or salted meat) in a joined shed counts the Firebox's **stoked hours in a row**. A lit Firebox is stoked; Core's *Bank the Fire* rakes it down, *Stoke the Fire* brings it back. When a stack has enough, it finishes at once as **Hot Smoked Fish** or **Hot-Smoked** meat (*Hot-Smoked Beef*); **pork comes out as vanilla's Ham** with the cut's own weight and food, so Slice Ham and ham dishes take it; a stack with a **Leg of Pork never takes a cook** (its stoked hours are smoke): by the heaviest piece, fish 4 hours (all up to 1.1 weight) to 6 (2.2 and up), meat 6 hours (a 0.3 cut) to 8 (0.5). Adding wood or banking it up to an hour keeps the run (the gap doesn't count); longer, the run is over, its hours become **smoke** (below) and the next stoking starts from nothing. A fire that burns out while you're away counts only until its wood ran out. Short of a cook, fish dries on as Sheltered and comes out Salt Dried; meat dry cures (below). The popup shows *Hot Smoke: x of y h stoked in a row*. While finished stacks wait inside, a **smoked ham hangs by the door**.

**Hot Smoked** fish and meat are cooked and ready to eat: 7 / 14 days, about 63% of the fresh fish's weight or 70% of the raw cut, all of its food, a little salt (thirst 15, rinsed 10), a small mood lift (unhappiness -5). Fish go into soups, stews, rice, pasta, sandwiches and salads; meat also into pies, tacos and burritos.

**Cold smoking**: **smoke** = banked hours plus stoked runs that broke off before a cook, counted only on days of **15 C or less** (stoked or banked; a smoulder lifts the meat about 15 C, and over 30 C it cooks rather than cures). When a stack has dried, if it has had its **hours of smoke** (by the heaviest piece: fish 24 hours up to 1.1 weight, 48 from 2.2; meat 60 for a cut, 120 with a Leg of Pork; they needn't come in a row), it comes out **Cold Smoked Fish** or smoked dry-cured meat, named by its animal: **Suho Meso** (beef and steak, the Bosnian smoked beef), **Mutton Ham** (the Scottish and Welsh smoked mutton), **Jerked Venison** (the frontier's), **Smoked Dry-Cured Pork**, and from a Leg of Pork **Smoked Country Ham**. Short of that, fish is Salt Dried and meat is air dried (below). **Any hour of fire** dries the shed as if it were **15 C warmer banked, 20 C stoked** (`F.BANKED_LIFT`, `F.STOKED_LIFT`), with the humidity halved per 10 C of lift and the outdoor wind, and the popup's Drying Rate shows it. Salt fish leaves the 27-day floor (`MIN_DRY_RATE`) from about -2 C outdoors banked, -7 C stoked, and reaches full speed (12 days) from about 5 C banked, 0 C stoked; meat gains in the same way. The popup's *Smoke* line reads *x of y h of smoke*, or *Too warm to count* over 15 C. Both keep 120 / 180 days (rinsed 108 / 162), as Salt Dried and Charque, and are eaten as they are: thirst 25, a small mood lift (unhappiness -3); the same dishes as Hot Smoked.

### Fat: Lard, Tallow and Cracklings

**Put Pork Fat in a Pot** / **Put Suet in a Pot**: an empty Pot or Forged Pot and 2 raw pieces (suet and mutton fat mix). It cooks on any stove or fire in 60 minutes and burns at 150. **Pour Off Lard** / **Pour Off Tallow** leaves the pot holding 0.5 L of Melted Lard or Melted Tallow. **Strain Lard** / **Strain Tallow** takes 0.5 L from any container through a Cheese Cloth, Dish Towel, Rag, Sheet or Strainer (kept): vanilla's Lard or the new **Tallow** (Lard's values, bakes wherever Lard does) and one **Cracklings** (7 / 14 days; salads, soups, stews, sandwiches). A burnt pot only takes **Scrape Out Burnt Fat**, which returns the pot. Raw fat keeps 2 / 4 days and is dangerous uncooked; Lard, Tallow and melted fat don't spoil. Two pieces make one block, so a pig's Lard (2 or 3 blocks on the Hook) is worth about its meat.

**In the Hearth's copper**: **Put Fat in the Copper** (on the Hearth's menu) puts every piece of a kind you carry in, 0.25 L a piece, up to 240. Kept steaming (85 C or more) for an hour it becomes Melted Lard or Tallow, which **Fill from Copper** puts in any container; strain it as above. The copper never burns fat. Raw fat left in a cold copper goes rancid when its oldest piece would have rotted (Empty the Copper takes it).

### Potted Meat

1. **Put Meat in Lard or Tallow** (an empty Pot or Forged Pot, a block of Lard or Tallow, one cut, 1 Salt) or **Put Meat in the Melted Fat** (a pot holding 0.5 L of Melted Lard or Tallow, one block's worth): a **Pot of Meat in Fat**.
2. **Add Meat to the Pot**: up to four cuts in all (Beef, Steak, Mutton Chop, Venison, Pork, Pork Chop), uncooked only.
3. Cook it on any stove or fire: 120 minutes, burns at 240.
4. **Pack Potted Meat** into an empty Clay Jar, Glazed Clay Jar or Clay Pot: the pot back and a **Crock of Potted Meat**, one portion a cut (its food plus a quarter block of fat, about 1,000 calories), eaten by the portion ("(3 portions)"), the vessel back with the last bite. Cooking XP 3 a cut.

The crock **keeps by place**: about 120 / 180 days in a powered fridge or at 4 C and colder, 60 / 90 in a basement (15 C), in a room by the season's mean temperature (a July pantry about 14 / 21), stopped in a powered freezer. The first portion taken costs a third of the days it had left, once. A part-used Lard gives only what is left of it.

### Names, icons and stages

Names say what a piece is now; a permanent fact goes in front, and a bracket holds only a state that changes or wants acting on, before vanilla's freshness. Fish keep their size and species: *Gutted Small Largemouth Bass (Salt Cured) (Fresh)*, then *(Salt Dried)*, *(Hot Smoked)*, *(Cold Smoked)*; "Gutted" stays on every stage of a fish that went through Gut Fish (a fish packed whole keeps its head). Stockfish goes by its species alone: *Walleye Stockfish*, *Walleye Stockfish (Matured)*, *Walleye Stockfish (Rehydrated)*. Meat goes by its cut in the tub (*Steak (Salt Packed)*, *Corned Steak*, *Country Cured Leg of Pork*) and by its animal after (*Beef Charque*, *Beef Charque (Soaked)*, *Hot-Smoked Mutton*, *Suho Meso*, *Smoked Country Ham*); vanilla's grade (*Prime Cut*) stays behind once a cut goes in the salt, as its food carries it (`F.MEAT_CUTS` and `F.MEAT_ANIMALS` by model index). A rinse is not in the name. Names update every in-game hour for what you carry and when a container is shown. Icons follow the stage: pale with salt once cured, browned once salt dried, grey once cold dried, gold once hot smoked, smoky bronze once cold smoked, darker once rehydrated; a gutted fish is drawn headless and a half split open with its backbone. Meat goes red-brown when cured, nearly black as charque, mahogany when hot smoked, burgundy when Dry-Cured. Each piece keeps its own weight and food, so a mixed batch comes out mixed.

**Fish**, as shares of the whole fresh fish (one big enough for guts, and on the cold route a head):

| Stage | Weight | Calories and nutrients | Hunger | Fresh / rotten days |
|---|---|---|---|---|
| Salt Packed | 90% | 100% | 100% | 3 / 6 |
| Salt Cured | 79–84% | 100% | 100% | 7 / 14 |
| Salt Dried | about 37% | 90% | 70% | 120 / 180 |
| Soaked (salt) | about 66% | 90% | 100% | 2 / 4 |
| Hot Smoked | about 63% | 100% | 100% | 7 / 14 |
| Cold Smoked | about 37% | 90% | 70% | 120 / 180 |
| Gutted | 80% | 94% | 94% | 3 / 6 |
| Stockfish | about 18% | 89% | 66% | 365 / 540 |
| Stockfish (Soaked) | about 53% | 89% | 94% | 2 / 4 |

A fish too small for guts keeps that tenth of its weight at every stage, and a cold-route fish of 1.0 weight or less keeps its head (90% gutted, all of its food). Curing takes a random 7 to 12% of each piece's weight. Freshness carries over as a share of each stage's fresh days; the cure starts the clock afresh, less what a warm cure took; rehydrating carries the dried fish's share over. A fillet vanilla cut counts as the food it holds once salted: it pays half its gutted fish's salt and comes out of the salt that heavy (9 times its raw weight).

**Meat**, as shares of the raw cut:

| Stage | Weight | Calories and nutrients | Hunger | Fresh / rotten days |
|---|---|---|---|---|
| Salt Packed Meat | 100% | 100% | 100% | 3 / 6 |
| Corned / Country Cured | 88–93% | 100% | 100% | 7 / 14 |
| Charque | about 50% | 90% | 70% | 120 / 180 |
| Charque (Soaked) | about 80% | 90% | 100% | 2 / 4 |
| Hot-Smoked | about 70% | 100% | 100% | 7 / 14 |
| Dry-cured, smoked or air dried (Suho Meso, Bresaola, ...) | about 50% | 90% | 70% | 120 / 180 |
| Country Ham, Smoked Country Ham | about 50% of the leg | 90% | 70% | 180 / 365 |
| Ham (hot smoked pork, vanilla's item) | about 70% | 100% | 100% | 5 / 10 |
| Slices (0.4.16): Dry-Cured / Country Ham / Hot-Smoked | the cut shared by its 2 to 6 slices; a ham's fifteenth | its share | about 14 each | 60 / 90, 90 / 180, 3 / 7 |

## Seasons

Drying usually takes 12 to 55 days, and the time of year decides how a batch goes. Weather is recorded every 10 in-game minutes for the whole world, so stations keep drying while you are away.

- **Salt drying** takes 12 days at full speed, 20 C or above in dry air. Cold slows it (a quarter speed at 10 C) and so does air above 50% humidity, but it never drops below about 44% speed, so frost slows it without stopping it.
- **Charque** takes 5 days at full speed, from 25 C, scaled down to nothing at 0 C, times the same damp-air factor and a wind factor (0.65 still, 1.2 in a good breeze). No minimum rate and no heat damage.
- **Cold drying** takes 32 days at full speed: 0 to 5 C in a good breeze. Frost slows it (80% at -5 C, 60% below), so does warmth toward 10 C (67%), and it stops above 10 C. Wind sets the rest: 50% in still air, up to 120% at a wind intensity of 0.25. Live wind in a dry spell averages about 0.11, so a batch hung November to January takes about 50 to 55 days (a gameplay compromise: real stockfish hangs about three months).
- **Fresh fish is fragile**: until a cold stack is 30% dried, hard frost below -5 C (a tenth of its keeping per 72 hours) and lying wet above 0 C (5% per 48 hours) add to its spoilage, scaled by how wet it still is, together never past a quarter. Rot from a warm season is scaled the same way.
- **Rain**: open stations stop until it ends and the wet has dried off; progress is paused, not lost, except charque's tenth per 6 hours. Snow counts as rain for salt fish but doesn't bother cold drying. Cold fish waits to dry off after rain too.
- **Three places**, read from the station's square (Core's `Weather.placeOf(station, true)`):
  - **Open**: no roof overhead.
  - **Covered**: a roof overhead but not a room (a porch, an open shed, a floor above with no walls round it). Rain can't reach it. Salt fish and charque dry at the open rate in the shade; cold drying at 75%.
  - **Indoors**: a room, either a map building's or one you built with walls all round and every square roofed, and always the Smokehouse. Salt fish at 65%, no wind; meat there dry cures and is never charque (0.4.15). Cold drying needs moving air, so gutted fish is refused (a stack hung before 0.4.7 stays, stopped).

Spoilage goes by the season, not the day: it follows the average temperature of the last 10 days or so.

- **Gutted fish** spoils once that average is above 10 C: it rots on the frame after about 2 days at 10 C, sooner the warmer it gets.
- **Salt fish and charque** only suffer when the average is above 22 C and the humidity above 40%: each day of that takes a twentieth of the finished food's keeping. In practice a few days in a hot July.
- **Hot sun** (above 25 C) on an open salt fish stack under half dried hardens the skin over wet flesh: each 24 hours takes 5% off the keeping, scaled by how wet it still is, within the same quarter. A covered or indoor station is in the shade. On the forecasts that costs an open stack 2 to 6% from May to August. Charque takes no harm from the sun.
- **A warm cure**: see the Salting Tub. A 2-day cure lost 17% in July and 5% in August here.

How a batch hung in each month went, on the game's own forecasts for default weather (rain timing is estimated, so treat the days as approximate). `tools/season_report.lua` prints this table, `tools/charque_report.lua` the charque one.

| Month | Mean C | Mean humidity | Salt, open | Salt, covered | Salt, indoors | Salt keeping lost (open / covered) | Cold, open | Cold, covered | Cold batches rotted | Cold keeping lost | 2-day cure lost |
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

| Charque | Jan | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct |
|---|---|---|---|---|---|---|---|---|---|
| Open | 88–119 d | 31–59 d | 13–34 d | 9–25 d | 8–19 d | 7–15 d | 9–20 d | 8–17 d | — |
| Covered | 51–86 d | 20–36 d | 11–24 d | 7–12 d | 7–9 d | 7–10 d | 7–11 d | 7–17 d | 17–65 d |
| Indoors | 65–94 d | 25–44 d | 14–27 d | 10–16 d | 9–12 d | 9–12 d | 10–13 d | 10–26 d | 25–70 d |

Humidity stays low in the game all year, mostly 20 to 45%, so it barely changes drying. Blanks mean no batch hung that month finished inside the forecast data.

## Sandbox options

Under Traditional Preservation (Fish & Meat): **Salt drying time** (12 days), **Slowest salt drying** (27), **Stockfish drying time** (32), **Stockfish maturing time** (60), **Dry-cured meat ageing time** (30) and **Country Ham ageing time** (90; left hanging, three quarters of either), **Salt cure time** (2 days for a batch with a big fish or a 0.5 cut; small fish half), **Spoilage strictness** (Off, Forgiving, Normal, Harsh: it scales every rule that spoils a curing or drying batch, the under-salted and the long cure's cold rule included; `F.applySandbox`), **Butchering gives fat** (on; off: no fat rows, Lard is loot only), **Butchering gives legs of pork** (on; off: all Pork, as vanilla), **Charque** (on; off: meat can't be packed in salt or hung), **Charque drying time** (5 days), **Potted Meat keeps by place** (on; off: 60 / 90 days anywhere and opening costs nothing). Options are read when the world loads. Hot smoking has no option yet.

## For modders

### Code map

| System | Files | Notes |
|---|---|---|
| Stages, salt, tub, drying, weather ledger | `shared/TraditionalPreservationFishMeat.lua` | Constants at the top; `F.STAGES` (what each stage keeps), `F.carry` (food, weight, name, icon onto the next stage), `F.saltFor`, `F.pressHours` / `F.meatPressHours`, `F.advance` (the weather totals), `F.saltStep` / `F.coldStep` / `F.charqueStep`, `F.applySandbox` |
| Station sprites, places, the weather record | `server/TraditionalPreservationFishMeatWorld.lua` | Core's `Station.tracker`; sets each stack's `sheltered` / `covered`, runs the Smokehouse's `F.smokeStep`, draws stacks, the flue entry and the ham |
| Slots, popups, menus | `client/TraditionalPreservationFishMeatUI.lua` | Core's `UI.slotRules`; the stack and tub popups |
| Leg of Pork | `shared/TraditionalPreservationFishMeatPork.lua` | Wraps `ButcheringUtil.addAnimalPart`: for an adult pig's `Base.Pork` row it lets vanilla give the Pork, then turns `F.legsFrom(count)` sets of `F.LEG_PORK` (5) of them into legs (`F.fillLeg` sums their food, the oldest age); `F.LEG_SHARE` 0.5, `F.LEG_MAX` 3, `F.LEG_ANIMALS`. No table row, so the pig's meat stays vanilla's at any size, meat ratio, skill or roadkill |
| Fat | `shared/TraditionalPreservationFishMeatFat.lua`, `client/...FatUI.lua`, action `TPFMFatCopper` | `F.FAT_ROWS` rows added to vanilla's `AnimalPartsDefinitions` at world start (vanilla scales them: size, meat ratio, x2.8 Hook / x0.6 ground, skill, roadkill); `Pour Off` fills the pot with `MeltedLard` / `MeltedTallow`; the copper via Core's `Hearth.turnsHot` / `goesOff` / `staysIn` (fluids `RawPorkFat`, `RawSuet`, `MeltedLard`, `MeltedTallow`, `RancidFat`, names fixed for saves) |
| Charque, pork, the two meat cures | the main file, `..._Meat.txt` | `F.MEAT_CUTS` (seven, the pork three since 6a: `F.PORK_INDICES`, `F.LEG_INDEX`), `F.isPork` / `F.isLeg`, `F.porkRefusal` (frames refuse pork and `longCure` meat; the closed Smokehouse takes both), `F.canCorn` (OnTest of the short cure `PressSaltedMeat`: it only skips a leg) and `F.recipeRefusal` (Core's `UI.slotRules` `recipeRefusal`: the tub's border goes red for a leg while Corn is selected, and Craft refuses if the recipe changed after loading), `F.longCureHours` and `F.onCreateLongCured` (recipe `CountryCureMeat`, marks `longCure`), `F.LEG_SALT_PER_STEP`; names in `F.stageName`; own ledger totals `charque`, `charqueCovered`, `charqueSheltered`, `charqueRain`; `F.mixedTub` refuses fish and meat together; `F.hangKind` keeps a stack one kind |
| Potted Meat | `shared/TraditionalPreservationFishMeatPotted.lua` | The batch in the pot's modData `tpfmPotted`; `F.fillCrock`; eaten as Dairy's yoghurt jar (`ISEatFoodAction` wrapped, `F.afterCrockUse`); keeping by place on its own ledger `TraditionalPreservationFishMeatPotted` (`F.POTTED_KEEPING`, `F.pottedTemperature`: a room reads the season mean, not Core's station rule), `F.openCrock` |
| Ageing, slices, carving (6c) | the main file (`F.ageDays`, `F.agedness`, `F.applyAged`, `F.ageHanging`), `shared/TraditionalPreservationFishMeatSlices.lua` | See "Ageing and slices"; tests in `tests/test_aged.lua` |
| Smokehouse, flue, hot and cold smoking | `shared/TraditionalPreservationFishMeatSmokehouse.lua`, `client/...SmokehouseUI.lua`, action `TPFMFlue` | Chamber tiles (`F.chamberTile`, `F.chamberOther`), `F.connectRefusal`, `F.joinedFirebox`; hot smoking: `F.hotHours`, `F.startSmoke`, `F.smokeStep`, `F.hotDone`, `F.hotStations`, `F.hamSprite`; cold smoking: `F.smokeHours`, `F.coldNeed`, `F.coldDone`, `F.smokeStations`; dry curing: `F.dryCureRate`, `F.dryCureHours`, `F.underCureRate`, `F.dryCuring`; all: `F.smokedItem`, `F.smokedOutputs`, `F.rottenOutputs` |
| Pallet and bale | `server/...Pallet.lua`, actions `TPFMTieBale` / `TPFMUntieBale` | `F.PALLET_*`, `F.BALE_*` |
| Dish stand-ins, stock names | `shared/TraditionalPreservationFishMeatEvolved.lua` | `F.INGREDIENT_STANDINS` |

**Hot smoking in detail.** Core's `Hearth.logFire` keeps each Firebox's record in its Hearth state: `stokedHours`, `bankedHours`, and the stoked session running (`session`, `sessionBase`, `stokedLast`; 1 h grace, `Hearth.SESSION_GRACE`), counted only up to `fireEnds` because vanilla burns a lit fire's away time in one go on load. A stack (`HangFishToDry` or `HangMeatToDry`) gets `hotNeed` at start from its heaviest piece (`F.HOT_FISH_HOURS` 1.1 → 4, 2.2 → 6; `F.HOT_MEAT_HOURS` 0.3 → 6, 0.5 → 8; clamp 4-12) and keeps `hot`, `cold`, `smokeFrom` (the Firebox's `fireId`), `smokeSession`, `lastStoked`, `lastBanked`. The World steps it against the joined Firebox each look; stoked hours in a session that has ended (or that started and ended between looks) go to `cold`, as do banked hours. A done cook goes into `F.hotStations[stackId]` (not saved; set again after a load), the stack's OnUpdate then shows full progress, and OnCreate (`F.onCreateDried`) swaps the outputs: the engine has already put Salt Dried fish or Charque in the chamber's slots (`CraftLogicSystem.stop`: createOutputs before OnCreate), so `F.smokedOutputs` removes each and offers a `HotSmokedFish` / `HotSmokedMeat` carried from its input.

**Dry curing** (0.4.14): meat hung in the Smokehouse **never comes out Charque**; charque is the frames'. It dries on its own need by the heaviest piece, **3 weeks at full rate for a Beef, 6 for a Leg of Pork**, in cool air: full rate from **12 C**, down to **a quarter** in frost, slowed by damp air as salt fish, no wind; the fire's warmth as above. A cut hung in December with a fire a few hours a day takes about 7 weeks and a leg about 3 months; with no fire, 12 weeks and more in frost. With its smoke it is Suho Meso and the others above; without, **air dried**: **Bresaola** (beef), **Dry-Cured Mutton / Venison / Pork**, and from a leg **Country Ham**. A Country Ham (smoked or not) is its own item and keeps **180 / 365 days**. **Corned meat is under-salted** for the long hang: until a hot cook is done it spoils by the shed's temperature, the fire's lift included (rotten in 4 weeks at 10 C, five times slower at 0 C, five times faster at 20 C; popup line *Under-salted*); Country Cured pieces in the same stack don't. **A stack that rots on any station comes down as what was hung**, rotten (*Corned Beef (Rotten)*, a pressed or gutted fish), not as the finished thing.

**Dry curing outside the shed** (0.4.15): a stack with Country Cured meat in it (`modData.longStack`) on a Frame, Beam or Gantry dry cures by where it hangs (`F.curePlace`): under a roof or indoors as the shed with the fire out (the `dryCure` total: about 82 days for a cut hung in January, 3 weeks from 12 C up); in a **basement**, the curing cellar, at a steady two thirds all year (`F.DRY_CURE_BASEMENT_RATE`, totals `dryCureBasement` / `underCureBasement`: about **32 days a cut, 63 a leg**); if its roof goes, it waits (*Stopped (Needs a roof)*). **In a room or a basement every meat stack dry cures** (`F.dryCuring` reads `sheltered`): Corned meat there is under-salted as in the shed, and never Charque; under an open roof or in the open an all-Corned stack is still Charque. The **Hanging Beam may be built in a room or a basement** since 0.4.15 (`F.doorFree`; `Tiles.OUTDOOR` is now the Gantry and the Smokehouse, `Tiles.DOOR_KEPT` all three); the Gantry stays outdoors. The Salting Tub still goes by the season wherever it stands. Always air dried: Bresaola, Dry-Cured Mutton / Venison / Pork, Country Ham. Smoke, the hot cook and the fire's warmth stay the Smokehouse's. The World swaps the outputs through `F.stackStations`, and the stack waits at `F.SHED_WAIT` until it has been seen.

**Ageing and slices** (0.4.16, 6c). Dry-Cured meat and the Country Ham **age** after they have dried, on the item's own food clock from the age it came down with (`modData.agedFrom`, set in `F.smokedItem`; one from before 0.4.16 counts all its days): a cut `F.AGE_CUT_DAYS` (30), a ham `F.AGE_HAM_DAYS` (90). `F.agedness` gives 0 to 1; `F.rename` turns it "(Aged)" once (`modData.aged`, kept), sets the tooltip by the tenth, and `F.applyAged` gives what is left of the piece (`F.shareLeft`) the aged mood: a cut Unhappiness -3 to **-8**, a ham -10 to **-40** with **Boredom -20**. That, with its slices, is the ham's reward; its calories are the Pork's. **Left hanging** where it dried (a finished stack in the station's output slots; the World calls `F.ageHanging` on its hourly look) a piece ages in `F.HANG_AGE_SHARE` (three quarters) of the time, by moving `agedFrom` back; `modData.hungHour` is the last hour counted. A piece taken down can't be hung again (output slots take nothing), so the faster ageing ends there, and a hanging piece holds its stack. Edible young; Hot-Smoked meat, vanilla Ham and Charque never age.
**Slices** (`shared/TraditionalPreservationFishMeatSlices.lua`), on a surface with a knife as vanilla's Slice Ham: **Slice Dry-Cured Meat** and **Slice Hot-Smoked Meat** give a cut's worth of slices of about hunger 14 (`F.SLICE_HUNGER`, `F.sliceCount`: a Hot-Smoked Beef 6, a Steak 3, a dry-cured Beef 4, never under 2; the script makes two and OnCreate hands the character the rest; vanilla's Ham Slice is hunger 10); **Carve Country Ham** takes 5 slices (hunger 70 in all, `F.CARVE_HUNGER`) off a ham that is **kept** (`mode:keep`; `F.carveOff` lowers its food, mood and weight and leaves BaseHunger, as eating does); with 105 or less left on it (`F.CARVE_LAST`) only **Carve the Last of the Country Ham** shows, which takes it all. A 2.5 leg's ham (hunger 210): three carvings, 15 slices. `F.fillSlices` gives each slice its share of the piece's food, thirst and mood, the cut it came from (`modData.cut`, for "Suho Meso Slice", "Smoked Country Ham Slice (Aged)"), `aged` and `airDried`, and an age as far through its days as the piece was (`F.sliceAge`). Slices keep half the piece's days (their scripts: 60 / 90, 90 / 180, 3 / 7), use vanilla's Ham Slices icon and model, and go into the same dishes (`EvolvedRecipeName.json` names them there). Hot smoked pork is vanilla's Ham, which vanilla slices.

**The cook on the stack** (0.4.16): while a stoked run counts (`F.cookShare`: `hot / hotNeed`, nil with no run or a leg in the stack) the stack's bar shows the cook when it is ahead of the drying (`F.stackProgress`, capped at `F.SHED_WAIT`: only the World ends a cooked stack), and the slot's bottom-left badge (`renderWithBadge` in the UI file, where salt stacks show a salt shaker) shows the Hot Smoked item's icon. A broken run zeroes `hot`, so both fall back.

**Dry curing in detail.** `F.startSmoke` gives a meat stack `cureNeed` (`F.dryCureHours`), `smokeNeed` (`F.smokeHours`), `noHot` (a leg in it), `underCured` (a piece without `longCure`) and `allUnder` (every piece). In the shed (`F.dryCuring`: `inShed` and `cureNeed`) `F.charqueStep` adds the ledger's `dryCure` total and, under-cured, `underCure` to `underSpoiled`; `F.smokeStep` adds the fire's gains from `dryCureBanked` / `dryCureStoked` and `underCureBanked` / `underCureStoked`, as it does for fish. `F.smokedItem` makes each piece: vanilla Ham (`F.carryHam`), `CountryHam` for a leg, `modData.airDried` for the name and tooltip, and `F.rottenStage` for a piece that rotted. `F.stackStations` (the World, every hanger) lets `F.rottenOutputs` swap a rotted stack's outputs. A stack hung before 0.4.14 gets its need at its next look and keeps its share of progress.

**Cold smoking in detail.** The ledger keeps `clock` (all hours) and `smokeCool` (hours at or under `F.COLD_SMOKE_MAX`, 15 C). Each look, a stack (`F.smokeStep(modData, fire, ledger)`) takes the cool share of the hours since its last look (`lastClock`, `lastSmokeCool`) and counts only that share of new banked hours and of stoked hours into smoke; `hotCool` is the cool part of `hot`, which is what moves to `cold` when a session breaks. The same look adds the fire's warmth: banked hours times the ledger's (banked − Sheltered) drying per hour over the interval, stoked hours times (stoked − Sheltered) (totals `smokeBanked`/`smokeStoked` or `dryCureBanked`/`dryCureStoked` by `smokeMeat`, from `F.liftedRates`; `lastDraughtSheltered`, `lastDraughtBanked`, `lastDraughtStoked`) to `dried`, and sets `burning` to the fire's mode (Core's `Hearth.STOKED` / `BANKED`) for the popup's Drying Rate. A stack from before 0.4.11 starts its warm totals at its next look. The World sets `inShed` and `F.smokeStations[stackId]` (not saved); a finished shed stack waits at `F.SHED_WAIT` until the World has seen it after a load, then OnCreate checks `F.coldDone` (`cold` ≥ the stack's `smokeNeed`) and swaps in `ColdSmokedFish` / `DryCuredMeat`. `startStack` clears every shed and smoke field, because the engine pools recipe data with its ModData.

**The Smokehouse in detail.** `entity_Smokehouse_Chamber.txt`: a two-tile entity like vanilla's Drying Rack (`SpriteGridPos`, `ForceSingleItem`; slots on the master tile), recipe tag `Smokehouse` (a shed built before the tag gets it when the World first sees it: `recipeTagQuery` is saved per object), always Sheltered (`entry.place`), closed (no hanging sprites). The flue link lives on the Firebox alone (Core's `flue` and `flueSide`); the shed finds it by its tiles' neighbours. Connect: 400 ticks, Masonry XP 5; Disconnect 200. Refusals in `F.connectRefusal`: the Firebox joined already, the shed joined already, the door end (`F.chamberSideAllowed`), the Firebox's own door towards the shed (Core `Hearth.flueSideTo`), the fire lit or banked. Neither picks up while joined (`UI.keepInPlace`). The shed's door tiles are registered with Core's `Doors`. Tiles: chamber 856-859, flue entries 860-867 (`Tiles.CHAMBER_ENTRY`), the ham 868-869 (`Tiles.CHAMBER_HAM`), then the Salting Tub filled with meat, pork or a leg 870-875 (`Tiles.TUB_MEAT`: the last cut put in, or a leg whenever one is in).

### Tuning

Times, capacity, stage values, weather rates and spoilage limits are at the top of `42/media/lua/shared/TraditionalPreservationFishMeat.lua`. `PRESS_HOURS` (the longest press; `PRESS_MIN_HOURS` and the two `PRESS_..._WEIGHT` values set the rest), `DRY_HOURS`, `COLD_DRY_HOURS` and `CHARQUE_HOURS` set the recipe times when the game starts, so they are the only times to edit. Restart the game after changing them. Hot smoking's hours and cold smoking's share are at the end of `...Smokehouse.lua`; `COLD_SMOKE_MAX` is in the main file. Slot counts are set in the entity scripts and recipes. A station keeps the counts it was built with, even when picked up and placed again.

### Tools and tests

- `tools/build_tileset.py` repaints the stations, hanging fish and meat, the Smokehouse and its overlays, the fish icons, the mod list icon and model textures, writes `..._models.txt` and the generated `42/media/lua/shared/TraditionalPreservationFishMeat/Tiles.lua` (don't edit it by hand). It also rewrites the frame, beam and mod icons slightly differently from the committed ones: restore those with git. Needs Pillow and the game files.
- `tools/build_meat_icons.py` paints the fat, salted meat, charque, Potted Meat, Hot Smoked, Cold Smoked and Dry-Cured icons (meat from vanilla's cuts, the Leg of Pork from vanilla's Ham, fish from this mod's Salt Dried icons), and the raw Leg of Pork's icon and ground-model texture (vanilla's Ham pulled to raw pink). Apart from `build_tileset.py`, so the fish art doesn't rebuild with it.
- `tools/build_model.py` writes the Stockfish Bale's ground model, texture and icon (needs Pillow, numpy and the game files).
- `tools/season_report.lua` and `tools/charque_report.lua` run the rules on `tools/climate_year.csv` (about a year and a half of the game's forecasts); `tools/climate_wind.csv` is a year of forecast wind, which `WIND_GOOD` was scaled from. Run them after changing any rate. `tools/storage_model.lua` is the keeping model checked against its golden output.
- `tp test FishMeat` (from `~/MODS/TraditionalPreservationCore`) runs every test in `tests/`: `test_curing` (curing rules, stages, scripts, icons), `test_ui` (slots and popups), `test_world` (sprites, places, the weather record, the ham), `test_tiles` (entity scripts against `Tiles.lua`), `test_pallet`, `test_fat`, `test_fat_ui`, `test_pork` (legs from butchering), `test_potted`, `test_smokehouse` (flue rules, hot and cold smoking counters, the draught, smoked meat names), `test_console` (debug commands), then the golden checks.

The shared core (season averages, station tracking, popups, the Hearth and Firebox) is the required TP Core mod (`~/MODS/TraditionalPreservationCore`), loaded with `require "TraditionalPreservationCore/..."`. Edit it there.

## Debug commands

In debug mode, `TPFM.help()` in the Lua console lists commands for testing this mod. They are described in `DEVHELP.md`.

## Known prototype caveats

- **Not fully tested in play.** Building, the station windows and sprites, charque, Potted Meat, the Smokehouse, hot and cold smoking have been seen in game. Seasons, spoilage and the sandbox options haven't been played through.
- A curing batch's and a hanging stack's hover popups are the mod's own, built from the same rules. Time Remaining assumes the weather holds; the window's Time Required line stays at the recipe's base time. The popup's layout is copied from vanilla, so compare the two after a game update.
- A covered or indoor station uses the outdoor temperature, so heating the room doesn't speed it up.
- A stack that rots shows its finished sprite until collected.
- Vanilla's cutting can also give a roe sac in season. Gutting and packing only give guts, and gutting a head.
- Vanilla's Divide Food into Bowls only knows vanilla's pots, so the stock has its own two copies of it. Compare them with vanilla's after a game update.
- In a dish's "Contains" list, a fish or meat stage shows one icon for that stage, not its species or cut: the list records a stand-in item (`...Ingredient`). Dish names are unaffected.
- Every Fish Head shares one icon, a largemouth bass's head, and lies on the ground as that icon at half size.
- The season figures come from the game's forecasts for default weather, not from a played year. Sandbox temperature settings will shift them.
- A fish over 4.5 weight has to be gutted and split before it's packed in salt; a fish over 50 weight won't fit on a Fish Gantry, so split it to cold dry.
- The tub holds 35 items at most and a stack 25, so fillets under 0.1 weight fill a stack by count before weight.
- A stack's hanging look is picked at random, so it may not match the fish in it. The beams only hang walleye and sauger shapes.
- On the ground most fish stages are the vanilla model of that species with a repainted texture (`WorldStaticModelsByIndex`); Hot and Cold Smoked fish use Salt Dried fish's models. Charque, salted, smoked, Dry-Cured and rehydrated meat lie on the ground as the vanilla model of their cut, untinted.
- The tub's and stations' add limits go through the core's `UI.slotRules`, whose add loop is copied from vanilla's `ISCraftLogicPanel.ItemSlotAddItems`, so compare the two after a game update.
- The tiledef number 5129 must be unique among your active mods. A tileset holds 512 tiles at most, and going over drops the whole tile file and every placed station, so the beams and the Smokehouse are in a second tileset.
- Multiplayer is not supported. This mod is singleplayer only for now.

## Test plan

Already passed: the curing rules (offline), a simulated year on the game's forecasts, scripts, recipes, tiles and sandbox options on a headless server, and in-game steps for every system (the series' `INGAME_PASS.md`). Still to check in a played year:

1. A whole salt-fish batch, a stockfish batch, a charque batch and a hot-smoked batch from catch or kill to the plate, with real time and weather, and save/reloads in between.
2. Stockfish hung in a warm spell rots; one caught by early frost keeps less; a ripe one cheers up a stew.
3. A warm cure in July; hot sun on an open salt stack; a muggy July's charque.
4. A pig on the Hook rendered in the copper, its meat potted, crocks kept in a basement, a pantry and a fridge for a season.
5. A Smokehouse with a Firebox through a week away: the fire burns out, the stacks dry on, nothing is lost.
6. `console.txt` shows no repeating Lua errors after an hour of play.
