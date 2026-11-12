# Changelog: Traditional Preservation (Fish & Meat)

## 0.4.21
- **Rotted stacks look rotten** (2026-11-12, from the external review): a grey-green, mottled, mouldy look for each
  kind (salt fish, cold dried fish, meat) on the Drying Frame, Hanging Beam and Gantry, 84 tiles on a new third tile
  sheet (the first two keep their numbers, so saves keep their sprites). A running stack shows it when it is lost
  as a whole; a mixed Corned and Country Cured stack dries on and keeps its look. A finished stack shows it when
  any piece in it rotted. The Smokehouse shows nothing hanging, as before.
- Fixed: a rotted piece lost its stack, so a finished mixed stack counted as two on the station and could block
  its last spot.

## 0.4.20
- **Fewer pieces a stack on the Hanging Beam and the Gantry** (2026-11-12, from the external review): a Beam stack
  takes 12 pieces and a Gantry stack 6, fish or meat alike; the weight caps (15, 50) stay. They are meant for bigger
  fish, not more fish. The Drying Frame and the Smokehouse keep 25. A full stack says "This stack is full: press
  Craft to hang it".

## 0.4.19
- **Station info in the station's own window** (2026-11-12, from the external review): the Salting Tub, the Drying
  Frame, the Hanging Beam, the Gantry and the Smokehouse show, under In Progress, Done and Take All: the place, the
  stacks in use and what each may weigh (the tub: weight and pieces against its limits), the air now and over the
  season, wind and wetness where they reach it, the joined Firebox's fire, then a bar for every running batch with
  its share and time left or why it stands still, and under them what is spoiling a batch, a hot cook under way,
  the smoke so far, pieces loaded but not started and finished ones waiting. The tub's one bar is named for its
  cure (Fish cure, Corning, Country cure) and has no number. It reads the popups' own status
  (`F.stackStatus`, `F.charqueStatus`, `F.pressStatus`; `Info.rows` in `client/TraditionalPreservationFishMeatInfo.lua`,
  the World's `inspect`), so nothing is simulated twice. TP Core's new `StationInfo`. (A first build had it as a
  separate window on the right-click; the user asked for it in the window.)
- **The Fish Drying Frame, Fish Hanging Beam and Fish Gantry are the Drying Frame, the Hanging Beam and the Gantry**
  (user: they hang meat too). Display names only; entities, sprites and saves are untouched.
- Wording brought in line with the code (user: "for Corned, not Salt Cured, meat"): Hang Salted Meat to Dry's
  tooltip (Corned meat for charque, Country Cured meat in the shade), the tub's, frame's, Beam's, Gantry's and
  Smokehouse's build tooltips (fish or meat; the long cure), the cured fish, gutted fish, cured meat, rinse, Corn
  and Country Cure tooltips, a Country Ham's (it need not dry in the Smokehouse), the refusals "Take the cured
  batch out first", "It can't take that much" and "No spots left", the sandbox's Salt cure time tooltip, the
  sandbox switch **Charque** renamed **Salting meat** (it turns all meat salting off; the option's key is
  unchanged), and the mod's description in the mod list.
- Fixed: **the long cure never finished on time** (since 0.4.14). The tub's bar ran at the short press's speed
  against the long cure's 21-day recipe, so 10 days of cuts took about 105 and a leg's 21 about 220, spoiling all
  the while. `F.onPressUpdate` now goes by the recipe's own time. A batch already in the tub finishes when its
  hours are up (at once, if they are).
- Fixed: a **Country Cure** batch in the tub had vanilla's popup, not the mod's (time left by its own hours, the warm
  season's spoilage).
- Internal: the popup's Spoilage line picks its text in `F.spoilWarning`.

## 0.4.18
- **Salt by the quarter weight** (2026-11-12, the fish and meat against salt check): packing takes 2 salt for
  each quarter weight of the packed piece, to the nearest quarter and never under 2, where it took 4 for each
  started half weight. Still about 15%. A Steak, Mutton Chop or Pork Chop takes 2 (was 4, a Beef's salt), a panfish
  under about 0.4 weight 2 (was 4), a 4 weight walleye 28 (was 32), a 4.5 weight one 32 (was 36); a Beef, Venison,
  Pork, a half-weight fish and a Leg of Pork (10) pay what they did (`F.SALT_STEP` 0.25, `F.SALT_PER_STEP` 2,
  `F.LEG_SALT_PER_STEP` 1, `F.saltFor` rounds).
- A crock moved between places is looked at through TP Core's `Transfer.before` (2026-11-12) instead of Fish & Meat's
  own wrap of `transferItem`. No change in play.
- Guide chapter 14, **At the Table** (2026-11-12): what each fish and meat stage is eaten as, its cook and burn
  times, the dishes it goes into and the recipe that moves it on. README title says 0.4.17.

## 0.4.17
- **The Salting Tub shows what is in it**: uncovered and waiting, a tub of meat no longer draws fish. Red cuts for
  beef, mutton and venison, pale pink for pork, and one Leg of Pork filling the tub, each lying in the salt
  (`Tiles.TUB_MEAT`, tiles 870-875, `W.tubKind`). Mixed cuts show the last put in, the top layer;
  a leg always shows, as it fills the tub. The board and stones still cover any
  tub that is pressing or done. Tests in `tests/test_world.lua`.

## 0.4.16
- **Ageing (6c)**: Dry-Cured meat and the Country Ham age after they have dried, on the item's own food clock: a cut
  **30 days**, a ham **90** (`F.AGE_CUT_DAYS`, `F.AGE_HAM_DAYS`, `F.agedness`; `modData.agedFrom`, older pieces
  count all their days). The name gains **"(Aged)"** and the tooltip counts the tenths. Aged, a cut's mood goes from
  -3 to **-8**, a Country Ham's from -10 (was -3) to **-40 with Boredom -20** (`F.applyAged`, by the share left).
- **Left hanging it ages in three quarters of the time** (`F.HANG_AGE_SHARE`, `F.ageHanging`): a finished stack still
  on the station where it dried. A piece taken down can't be hung again; a hanging one holds its stack.
- **Slices**: **Slice Dry-Cured Meat** and **Slice Hot-Smoked Meat** (slices of about hunger 14, as many as the cut
  holds: `F.sliceCount`, 2 to 6), **Carve Country Ham** (5 slices, the ham kept and lighter) and **Carve the Last of
  the Country Ham**: 15 slices from a leg in three carvings (`...Slices.lua`). Slices are named by the piece
  ("Suho Meso Slice", "Country Ham Slice (Aged)"), take its share of food and mood, keep half its days (60 / 90,
  90 / 180, 3 / 7), and go into vanilla's Ham Slice dishes. Vanilla's Ham Slices icon and model.
- **Hot smoking shows on the stack**: while a stoked run is cooking a stack its bar follows the cook when that is
  ahead of the drying (`F.cookShare`, `F.stackProgress`), and a small Hot Smoked icon sits in the slot's bottom
  left corner, where salt stacks show their salt. A run broken for over an hour drops both.
- Sandbox: **Dry-cured meat ageing time** (30) and **Country Ham ageing time** (90).
- Dev: `TPFM.mature(days)` ages carried dry-cured meat too; `TPFM.dryCured(n)`; `TPFM.food()` prints each carried
  piece's hunger, unhappiness, boredom, thirst, age and ageing. Tests: `tests/test_aged.lua`.

## 0.4.15
- **Dry curing without the Smokehouse**: Country Cured meat, pork too, hangs on a **Frame, Beam or Gantry under a
  roof, or a Frame or Beam in a room or a basement** (`F.meatRefusal`; not in the open) and dry cures there to air dried
  meat: Bresaola, Dry-Cured Mutton / Venison / Pork, Country Ham. Under a roof or indoors as the shed with the fire
  out; in a basement at a steady two thirds all year (`F.DRY_CURE_BASEMENT_RATE`: about 32 days a cut, 63 a leg); a
  stack that loses its roof waits. Smoke, hot smoking and the fire's warmth stay the Smokehouse's. Corned pork still
  hangs in the Smokehouse only.
- **The Hanging Beam can be built in a room or a basement** (`F.doorFree`; the Gantry and the Smokehouse stay
  outdoors: `Tiles.OUTDOOR`, with `Tiles.DOOR_KEPT` for the door rule).
- **No charque indoors**: in a room or a basement every meat stack dry cures; Corned meat there is under-salted, as
  in the Smokehouse. Charque is the open air's and the open roof's.
- **Spoilage strictness** now reaches 0.4.14's two rules: under-salted Corned meat (`F.UNDER_CURE_HOURS`) and the long
  cure's cold rule (`F.LONG_CURE_ROT_HOURS`) are scaled as the older ones (off: never; forgiving x2; harsh x0.5).
- Air dried meat's tooltip no longer speaks of smoke at all.
- **Guide pass**: chapter 3 is every road on one page (when to start, the cure, where, how long, yield, keeping, and what it costs in salt and fuel); dry curing has its own chapter 11; the Almanac has the year month by month, when each larder runs out and what the base game's garden and fishing do; new chapter 16, Three Larders: a house with one freezer, a farm, a river camp. Charque's indoor column is gone (no charque indoors).
- **The ham by the Smokehouse door** hangs on the door's other side, a third larger, a little past the shed's corner,
  with a slice taken off its round end (`paint_chamber_ham`; same tile numbers). Painted as vanilla's Ham icon is: a
  few tones in small patches, lit from one side, a pale mottled cut with a lighter middle, a dark line round it.

## 0.4.14
- **Dry curing in the Smokehouse** (phase 6b): meat hung in the shed never comes out Charque. It dries on its own
  need by the heaviest piece (`F.dryCureHours`: 3 weeks at full rate for a Beef, 6 for a Leg of Pork) in cool air
  (`F.dryCureRate`: full from 12 C, a quarter in frost, damp air as salt fish, no wind), with the fire's warmth as
  before (ledger totals `dryCure`, `dryCureBanked`, `dryCureStoked`). With its smoke it is
  **Suho Meso, Mutton Ham, Jerked Venison, Smoked Dry-Cured Pork**; with less, air dried: **Bresaola, Dry-Cured
  Mutton / Venison / Pork** (`modData.airDried`). Charque comes from the frames only. A stack hung before this
  keeps its share of progress on the new need.
- **Country Ham**: a Leg of Pork dries to a new item, `CountryHam` (**Smoked Country Ham** or **Country Ham**),
  keeping 180 / 365 days. A stack with a leg takes no hot cook: its stoked hours are smoke.
- **Hot smoked pork is vanilla's Ham** (`F.carryHam`), with the cut's own food and weight, so Slice Ham and ham
  dishes take it. Never a leg.
- **Under-salted**: Corned meat (the short cure) left to dry in the shed spoils by the shed's temperature
  (`F.underCureRate`: rotten in 4 weeks at 10 C, five times faster per 10 C more, the fire's lift counted) until a
  hot cook is done; Country Cured pieces in the same stack don't. Popup line "Under-salted".
- Popup in the shed: Method "Dry curing", the shed's temperature word, no Hot Smoke line for a stack with a leg.
- **A rotted stack comes down as what was hung** (`F.rottenStage`, `F.rottenOutputs`, `F.stackStations`): Corned Beef
  (Rotten), a pressed or gutted fish, not Bresaola, Salt Dried or Stockfish. In a mixed stack only the Corned pieces
  rot and the stack dries on (`modData.allUnder`). Air dried meat has its own tooltip, which doesn't speak of smoke at all.
- **Smoke by fixed hours** (`F.smokeHours`, `modData.smokeNeed`), for fish and meat alike: by the heaviest piece, fish
  24 hours (up to 1.1 weight) to 48 (2.2), meat 60 (a cut) to 120 (a leg). It was a third of the hours hung, which
  the slow dry cure turned into weeks of fire. Popup: *x of y h of smoke*.
- **"(Soaked)"** on rehydrated fish too (*Walleye Stockfish (Soaked)*, *Medium Walleye (Soaked, Salt Dried)*), as
  charque. Stockfish tooltips: "Keeps for about a year", "Matured stockfish".
- **The long cure wants the cold**: above a season mean of 10 C (`F.LONG_CURE_ABOVE`) a Country Cure batch spoils in
  step with the warmth, rotten after a leg's 21 days at 15 C (ledger `longCureSpoil`). Without it, the cool-air rule
  made summer the quickest season for ham. The short cure and fish keep the 20 C rule. `TPFM.longCure(hours)`.
- **Stockfish keeps 365 / 540 days** (was 730), so a winter's fish reaches the next winter but two don't stack.

## 0.4.13
- **Pork in the salt** (phase 6a): Pack Meat in Salt takes **Pork, Pork Chop and the new Leg of Pork**. Salt Cured
  pork hangs in the **Smokehouse only** (`F.porkRefusal`): a frame, Beam or Gantry refuses it, as pork fat goes rancid
  in sun and wind; so does **Country Cured** meat, whose long cure is for dry-cured meat, not charque. Icons and ground models for the three in every meat stage (`F.MEAT_CUTS` now seven).
- **Leg of Pork** (`TraditionalPreservationFishMeatPork.lua`): an adult pig gives some of its Pork as whole legs, 2.5
  weight. A wrapper on `ButcheringUtil.addAnimalPart` lets vanilla give the Pork, then makes 5 of those pieces into one
  leg with their food (`F.fillLeg`), at most half the Pork and 3 legs (`F.legsFrom`). No table row and no trim, so a
  pig's meat stays vanilla's at any size, meat ratio, skill or roadkill (a fixed row was simulated first and lost
  meat on a typical pig). About 1-2 on the Hook, usually none from the ground. Sandbox **Butchering gives legs of
  pork** (on). Icon and model: vanilla's Ham pulled to raw pink. A leg takes half fish's salt, 10 for 2.5 (~8%).
- **Two meat cures.** **Corn Salted Meat** (was Cure Salted Meat), the short one for charque and hot smoking, gives
  **Corned** meat. A leg gets the red border while Corn is selected, and Craft refuses if one is in the tub (`F.recipeRefusal` through Core's new `recipeRefusal` slot rule: in game, OnTest alone let vanilla start and leave the leg in its slot). **Country Cure Salted Meat** (new, `CountryCureMeat`), the long
  one for the Smokehouse's dry-cured meat and country ham: **10 days** for cuts, **21** with a leg
  (`F.LONG_CUT_HOURS`, `F.LONG_LEG_HOURS`), marks `longCure` (6b reads it). The warm-cure rule applies unchanged, so
  the long cure is a cold-season job.
- **Names** (display only; keys and indices kept, old items rename on load): the name says what it is now, a bracket
  only for a changing state. Meat: *Steak (Salt Packed)*, *Corned Steak*, *Country Cured Leg of Pork*, *Beef Charque*,
  *Beef Charque (Soaked)*, *Hot-Smoked Mutton*; cold smoked *Suho Meso* (beef), *Mutton Ham*, *Jerked Venison*,
  *Smoked Dry-Cured Pork*, *Smoked Country Ham* (air-dried names ready for 6b: Bresaola, Dry-Cured X, Country Ham).
  Vanilla's *(Prime Cut)* no longer follows a cut into the salt. Stockfish: *Walleye Stockfish*, *(Matured)*,
  *(Rehydrated)*, without size or Gutted; other fish names unchanged. Hang Salt Cured Meat to Dry is now *Hang
  Salted Meat to Dry*.
- **Wording:** fish and meat never sour. The tub popup reads *Spoiling (Warm cure)*; guide, README and Workshop say
  the flesh "starts to spoil by the spine (bone taint)"; a rinsed Salt Dried fish loses its "sharp tang".
- `TPFM.meat` gives the pork cuts and a leg; `TPFM.cured(n, long)`; tests `test_pork`, pork, leg, long-cure and name
  checks; `test_curing` reads the real EN texts. README's stoked lift corrected to 20 C.
- **Not released alone:** 6b (the Smokehouse routes: no charque from the shed, Ham, Country Ham) ships with it.

## 0.4.12
- **Cold smoke counts on days of 15 C or less** (was 20 C; `F.COLD_SMOKE_MAX`). With the banked smoulder now lifting
  the shed 15 C (0.4.11), a 20 C day read 35 C, past the 30 C where smoke cooks rather than cures (side-agent flag,
  user's pick). Popup's "Too warm to count" says why; guide, README, Workshop and Balance follow.

## 0.4.11
- **The smoulder's warmth** (ROADMAP §7): with the Firebox burning, a Smokehouse stack dries as if the shed were
  **15 C warmer banked, 20 C warmer stoked** than outdoors, and the warmed air drier (its humidity halved per 10 C);
  charque keeps the outdoor wind. Before, a fire dried at the Covered rate, which gave nothing under about 13 C, so
  cold smoke's season barely gained. Salt fish at 2.3 C outdoors: 27 days Sheltered, about 16 banked, 12 stoked (if the
  fire burned every hour); banked helps from about -2 C, stoked from about -7 C (banked was +10 first, which gave
  nothing under about 3 C: step 80, user picked +15). Cold smoke's "cool day" test still reads the outdoor temperature.
- Ledger totals `smokeBanked`, `smokeStoked`, `charqueBanked`, `charqueStoked` (`F.liftedRates`, `F.BANKED_LIFT`,
  `F.STOKED_LIFT`); a save without them gets them at load. A stack's `burning` holds the fire's mode (Core's
  `Hearth.STOKED` / `BANKED`), and its popup rate follows it; a stack saved before starts its warm totals at its
  next look. `TPFM.weather()` and `TPFM.age()` show and feed the new totals.

## 0.4.10
- **Cold smoke** (ROADMAP §7, phase 5d): a salt stack in a Smokehouse joined to a Firebox comes out **Cold Smoked**
  when it has dried, if its smoke counter reached **a third of its clock hours** in the shed (smoked-dried fish,
  balyk, suho meso: a few hours of smoke a day over the drying). Smoke = banked hours plus stoked sessions that broke
  off before a hot cook. **Fire hours count only on days of 20 C or less** (the smoulder lifts the meat 10-15 C; over
  30 C it cooks rather than cures), stoked or banked: the ledger keeps all hours (`clock`) and the cool ones
  (`smokeCool`), and a stack reads the share since its last look; a stack's hot hours keep their cool part
  (`hotCool`) for when the session breaks off. Short of the third it ends as Salt Dried / Charque, as before.
- **Fire dries faster:** every hour of fire, stoked or banked, dries the stack at the Covered rate instead of
  Sheltered's: up to 1.5x for salt fish, only over about 13 C (below, both sit at the 27-day floor); charque gains
  only with wind.
- **Cold Smoked Fish** (keeps 120 / 180 days like Salt Dried, edible as it is, thirst 25, mood +3) and
  **Dry-Cured Meat** (no longer charque once smoked: "Dry-Cured Beef / Mutton / Venison (Cold Smoked)", named by the
  cut's animal, keeps 120 / 180 like Charque, edible, thirst 25, mood +3; phase 6 adds ripening). In soups, stews,
  rice, pasta, sandwiches and salads, with dish stand-ins. Icons: Salt Dried fish pulled to smoky bronze, cuts to
  burgundy (`build_meat_icons.py`).
- A finished stack in a Smokehouse waits at the end until the World has seen its shed since the load
  (`F.smokeStations`, not saved), so OnCreate can swap in the Cold Smoked outputs (`F.smokedOutputs`, which
  `F.hotSmokeOutputs` became).
- Stack popup: "Smoke: x h, y h needed so far (a third of the hours hung)", or "Too warm to count" over 20 C. Firebox Info's flue line
  says what burning and cold smoke do. Dev: `TPFM.bank(hours)`; `TPFM.smoke()` shows the smoke need and each
  stack's heaviest piece (`heaviest`).
- Drying Rate in a Smokehouse shows the Covered rate while the Firebox burns (`burning`, set by `F.smokeStep`).
- A new stack clears the shed and smoke fields (recipe data is pooled with its ModData), so a frame stack after a
  shed stack can't wait at the end or read an old baseline.

## 0.4.9
- **Hot smoking** (ROADMAP §7, phase 5c): a salt stack in the Smokehouse (Salt Cured fish, or charque from Salt Cured
  meat) joined to a Firebox counts the fire on two counters. **Hot** = the Firebox's stoked session now running
  (TP Core's `Hearth.logFire`: unbroken stoking, up to 1 h without it allowed). Reaching the stack's need finishes it at
  once as **Hot Smoked Fish / Hot Smoked Meat**: fish 4 h (to 1.1 weight) to 6 h (2.2 and up), meat 6 h (a 0.3 cut) to
  8 h (0.5), by the heaviest piece, 4 to 12 h. **Cold** (smoke) = banked hours plus stoked sessions that broke off; it is
  kept for Cold Smoked (5d) and changes nothing yet. Short of a cook, a stack dries on as Sheltered, as before.
  Hours come from Core's record, so a fire that burns out while you're away counts only to when its wood ran out.
- Hot Smoked Fish and Meat: cooked and ready to eat, 7 / 14 days, 0.78 of the cured weight (about 70% of raw), food
  carried from each piece (`F.carry`), a little salt (thirst 15), mood +5; in soups, stews, rice, pasta, sandwiches and
  salads, with dish stand-ins. Icons: Salt Dried fish pulled to gold, meat cuts to mahogany (`build_meat_icons.py`).
  The engine puts a drying station's outputs in its slots before OnCreate (`CraftLogicSystem.stop`), so OnCreate swaps
  them there (`F.hotSmokeOutputs`); a done cook is noted by the World each look (`F.hotStations`, not saved) and its
  OnUpdate ends the stack.
- **A ham hangs by the Smokehouse door** while finished stacks wait inside (user's idea): tiles 868-869, on the door's
  tile (`F.hamSprite`).
- Stack popup: "Hot Smoke: x of y h stoked in a row" in a joined shed, "Smoke: x h" once there is any.
- Firebox Info's flue line now says what a joined Firebox does (stoked 4 to 8 hours in a row it hot smokes the
  stacks; banked or out they dry as Sheltered) instead of "Smoking comes in a later version".
- Docs: the player guide, README and Workshop text rewritten as one Fish & Meat manual, by process (cleaning table,
  Salting Tub, drying stations, Salt Dried fish, Charque, Stockfish, Smokehouse and hot smoking, fat, Potted Meat),
  checked against the code; history follows the Volga, Lofoten, the charqueadas, kavurma and the Kentucky smokehouse
  (no salt cod or biltong). README splits player notes from a code map for modders.
- Dev: `TPFM.smoke()` (the joined Firebox's record and each stack's counters), `TPFM.stoke(hours)` (adds stoked hours
  to the running session), `TPFM.curedFish(name, n)` (Salt Cured fish, default Walleye).

## 0.4.8
- **Connect the Firebox** (ROADMAP §7, phase 5b-2b): TP Core's Firebox joins the Smokehouse chamber beside it, with a
  **clay pipe** (2 Clay Pipe Segments + 1 Clay, Mason's Trowel kept) or a **stone trench** (3 Flat Stones + 2 Clay,
  a shovel or spade kept: `DIG_GRAVE`). No skill, a little Masonry XP. On the Firebox's menu (Core's
  `HearthUI.addFireboxMenu`) and the chamber's right-click. The Firebox may stand by either long side or the back gable,
  never at the door's end, and never with its own door towards the shed (`Hearth.flueSideTo`); one Firebox a shed, and
  not while its fire burns (lit or banked). **Disconnect** gives the pipe segments or flat stones back, the clay is lost.
  Neither the Firebox nor the shed picks up while joined. The link lives on the Firebox alone (Core's `flue`,
  `flueSide`). Firebox Info says where its flue goes. Smoke does nothing yet (5c, 5d): the shed still dries as Sheltered.
- Where the flue enters, on the long side the camera sees: a pipe stub in a collar of clay, or the trench's mouth under
  the sill (hidden by the Firebox itself). Tiles 860-867 (sheet 2 grows to 58 rows), `Tiles.CHAMBER_ENTRY`; the
  World draws them on either chamber tile. Rules in `TraditionalPreservationFishMeatSmokehouse.lua`, per chamber tile,
  so a bigger shed can reuse them. Dev: `TPFM.flueKit()`, `TPFM.smokehouse()`. Tests: `test_smokehouse.lua`.
- The Smokehouse's door needs its front tile free, and nothing of TP's (Firebox, Hearth, beams, another shed) goes up
  or is put down in front of it (Core's `Doors`: the door tiles registered in `...FishMeatSmokehouse.lua`;
  `F.notInRoom` asks `Doors.fits`; `UI.keepDoorsFree(Tiles.OUTDOOR)`). User, after step 75: a Firebox could be built
  at the shed's door end, and with its own door against the shed.

## 0.4.7
- **Smokehouse chamber** (ROADMAP §7, phase 5b-2a): a plank shed two tiles long under one roof slope, its door on the
  high end with a smoke slot under the eave (a two-tile entity like vanilla's Drying Rack: `SpriteGridPos`,
  `ForceSingleItem`). Carpentry 3, 14 Planks, 20 Nails, hammer kept. Holds 6 stacks of up to 15 weight of salt fish,
  Cold Dried fish or Salt Cured meat (charque), on the frame's recipes. Open air or under an open roof, not in a
  room. With no fire it is always **Sheltered** inside, wherever it stands (still air, no rain; cold fish doesn't
  dry), and nothing hangs in sight. Tiles 856-859 (sheet 2, 448-451), `Tiles.HANGERS.chamber` (`bases` for its two
  facings, `closed`). Connecting the Core Firebox comes in 5b-2b. Tests.
- The Smokehouse offers only Hang Salt Cured Fish and Hang Salt Cured Meat (recipe tag `Smokehouse`, added beside
  `DryingFrame`); cold drying needs moving air. A shed keeps its recipe tag in the save, so one built before gets
  the new tag when first seen.
- **Gutted fish is refused indoors**: the slot of any frame, beam or Smokehouse in a room, a basement or the
  Smokehouse turns away fish for cold drying, with the reason (`F.coldRefusal`). Stacks already hanging indoors
  stay, stopped as before.
- A stack's popup no longer shows Wetness indoors (a room or the Smokehouse): it is the rain on open frames.
- Charque's method reads **Salt drying (charque)**, in the popup and the recipe tooltip (was Sun drying).

## 0.4.6
- **Potted Meat keeps by place** (ROADMAP §7, phase 4c): a crock carries its own clock on a new weather ledger
  (global ModData `TraditionalPreservationFishMeatPotted`, kind `potted`) and catches up when next seen, at the place
  it was seen in last (Core's FluidAgeing record and place rules). A cellar's 15 C keeps the script's 60 / 90 days;
  a powered fridge or 4 C and colder 120 / 180; 14 / 21 at 25 C and up; a room goes by the season's mean (not the drying stations' season + 10, which made every pantry 25 C from spring to autumn); a powered freezer stops it.
  Vanilla's Food Spoilage setting scales it. **The first portion taken** costs a third of the days it has left,
  once (`tpfmOpened`). Looked at every hour on the player, when a loot window shows it and as it is moved. Sandbox
  **Potted Meat keeps by place** (on); off, a crock is plain food again. `TPFM.crocks()`, `TPFM.keep(days)`; tests.

## 0.4.5
- **Potted Meat** (ROADMAP §7, phase 4b): **Put Meat in Lard or Tallow** (an empty Pot, a block of Lard or Tallow,
  a cut, Salt) or **Put Meat in the Melted Fat** (a pot of 0.5 L Melted Lard or Tallow, as Pour Off leaves it) gives
  a **Pot of Meat in Fat**; **Add Meat to the Pot** puts in up to four cuts (a block covers four). Beef, Steak,
  Mutton Chop, Venison, and pork (Pork, Pork Chop): under fat and out of the sun, pork keeps. It cooks in two hours
  on any stove or fire and can burn (Scrape Out Burnt Fat). **Pack Potted Meat** into a vanilla Clay Jar, Glazed
  Clay Jar or Clay Pot: a **Crock of Potted Meat**, a portion a cut with a quarter block of fat each; vanilla's Eat
  takes portions, the name counts them, and the jar or pot comes back with the last bite. Keeps 60 / 90 days for
  now; keeping by place and the first opening's loss come in 4c. `TPFM.potted()`, `tests/test_potted.lua`, icons
  from `tools/build_meat_icons.py`.

## 0.4.4
- **"Salt Pressed" is now "Salt Cured"** for fish as for meat, and the tub recipes are **Cure Salted Fish** and
  **Cure Salted Meat** (were Press Salted ...); **Hang Salt Cured Fish to Dry**; sandbox "Salt cure time". Display
  names only: item and recipe IDs (`SaltPressedFish`, `PressSaltedFish`, `PressSaltedMeat`) and the `PressDays`
  option keep their names, so saves are unchanged.
- **Charque** (ROADMAP §7, phase 3c, the second half). **Hang Salt Cured Meat to Dry** on the Fish Drying Frame,
  the Fish Hanging Beam or the Fish Gantry: the summer sun dries it in 5 days at full rate. Full speed from 25 C up,
  nothing at 0 C or below, slowed by damp air; still air 0.65, a good breeze 1.2; under an open roof as in the open
  without the rain, indoors 0.65 with no wind. On an open frame it waits while wet, and each 6 hours of rain take
  back a tenth of what it had. No heat damage; only salt fish's hot and muggy season spoils it. Kentucky: about
  7-11 days in summer under a roof, weeks in spring and autumn, nearly nothing in winter (tools/charque_report.lua).
- **Charque** ("Steak (Charque)") keeps 120 / 180 days at about half the raw weight with 90% of the food, and
  **can't be eaten until soaked**: **Rehydrate Charque** (1 L of water) gives **Rehydrated Charque**, cookable, a
  little salty (thirst 10), spoils as fresh meat and goes into dishes.
- **Cold Dried fish can't be eaten until soaked either**, as Lofoten stockfish always is. Salt Dried fish stays
  edible as it is.
- **Salt Cured meat can be rinsed** (Rinse Off Salt, Rinse at Sink), as the charqueadas washed it before the sun:
  it keeps a tenth less long, and the rehydrated charque is less salty (thirst about 7).
- A stack is one kind: salted fish, gutted fish or meat ("A stack is one kind: ..."); one frame can hold all three.
- Sandbox: **Charque** (on/off: off, meat isn't packed in salt nor hung) and **Charque drying time** (5 days).
- Hanging charque: 140 new tiles at the end of the second sheet (vanilla's loin, steak and venison icons, cured red
  to deep brown); no station tile moved. Icons for Charque and Rehydrated Charque from build_meat_icons.py.
- Dev: `TPFM.cured(n)` (Salt Cured cuts), `TPFM.rain(hours)`; `TPFM.age` and `TPFM.weather` cover charque.

## 0.4.3
- **Meat in the Salting Tub** (ROADMAP §7, phase 3b, the first half of Charque). **Pack Meat in Salt** (in hand, no
  knife) takes a Beef, Steak, Mutton Chop or Venison as vanilla gives it, with fish's salt rule: 4 for each started
  half weight, about 15%, as charque. It gives **Salt Packed Meat**, named and drawn after its cut. Pork is left out
  on purpose: its fat goes rancid in the sun, so it waits for Country Ham.
- **Press Salted Meat** in the Salting Tub: 2 days for a 0.5 cut, less by weight (a Steak about 29 hours), never
  under a day; the heaviest cut sets the batch. A warm season costs keeping as it does for fish. It gives **Salt
  Cured Meat** ("Steak (Salt Cured)"), which keeps 7 / 14 days and cooks; the Drying Frame takes it in phase 3c.
- A tub salts fish or meat, never both at once ("A tub salts fish or meat, not both at once").
- Icons from `tools/build_meat_icons.py` (vanilla's cut icons, salted and cured). Dev: `TPFM.meat(n)`.

## 0.4.2
- **Fat renders in the Hearth's copper** (ROADMAP §7, 2d), many pieces at once. **Put Fat in the Copper** on the
  Hearth's menu puts in every carried piece of one kind (Pork Fat, or Beef Suet and Mutton Fat together), 0.25 L a
  piece, up to 240. Over a lit fire, an hour of steaming (85 C or more) melts it to **Melted Lard** or **Melted
  Tallow**, a fluid that Fill from Copper puts in any pot, bucket or jar. **Strain Lard** / **Strain Tallow** take
  half a litre for a block and a Cracklings: two pieces a block, as in a pot. The copper never burns fat.
- Raw fat stays in the copper, and goes to **Rancid Fat** there when its oldest piece would have rotted; only Empty
  the Copper takes that. Melted fat keeps.
- **Pots follow the same rule: raw fat is an item, over heat it becomes the fluid.** Pour Off Lard / Pour Off
  Tallow on a cooked pot now give the pot back holding 0.5 L of Melted Lard or Melted Tallow (hot), not the block;
  Strain gives the block and Cracklings, and its Cooking XP. A pot still burns if left on the heat (150 minutes).
- Straining needs a cloth or a Strainer, kept: a Cheese Cloth, Dish Towel, clean Rag, Sheet or Strainer.
- Hearth Info says how long the fat has to go and when it would go rancid. New fluids `RawPorkFat`, `RawSuet`,
  `MeltedLard`, `MeltedTallow`, `RancidFat`; `tests/test_fat_ui.lua`. Needs TP Core with `Hearth.turnsHot`.

## 0.4.1
- **Fat from butchering** (ROADMAP §7, phase 2). Pigs give **Pork Fat**, cattle **Beef Suet** and sheep **Mutton
  Fat**: one row each in vanilla's butchering parts tables, added when a world starts, so vanilla's own rules scale
  it (size, meat ratio, x2.8 on a Butchering Hook, x0.6 on the ground, skill, roadkill, an old carcass). A pig on
  the Hook gives 5 to 7 pieces, a cow 8 to 10, a sheep 2 to 4; on the ground 1 or 2. Young animals and deer give none.
- **Rendering** on any stove or fire, no station: Put Pork Fat in a Pot / Put Suet in a Pot (an empty Pot or Forged
  Pot, 2 raw pieces), cook 60 minutes, then Pour Off Lard (vanilla's Lard) or Pour Off Tallow, each with
  **Cracklings** and the pot back. Burnt fat gives nothing: Scrape Out Burnt Fat returns the pot.
- New items: Pork Fat, Beef Suet, Mutton Fat (raw, 2 / 4 days), **Tallow** (vanilla Lard's values and baking tag),
  Cracklings, and the four pots of fat. Icons from `tools/build_meat_icons.py`.
- Sandbox: **Butchering gives fat** (on).
- Console: `TPFM.fat(n)`, `TPFM.fatPot(state)`, `TPFM.fatRows()`.
- Internal: meat has its own files (`TraditionalPreservationFishMeatFat.lua`, `..._Meat.txt`, `tests/test_fat.lua`);
  fish code and goldens untouched. Butchering gives a little more Butchering XP, as each piece of fat counts as a part.

## 0.4.0
- **Renamed to Traditional Preservation (Fish & Meat)**, ahead of the meat routes (ROADMAP §7, phase 1). Mod ID
  `TraditionalPreservationFishMeat` (was `TraditionalPreservationFish`), debug console `TPFM` (was `TPF`), timed
  actions `TPFM...` (were `TPFish...`). The script module, so every item's and recipe's full type, the Lua table
  and files, translation keys, sandbox options (`SandboxVars.TraditionalPreservationFishMeat`), ledger and modData
  keys, the texture pack, tileset and sprite names all follow. Tiledef number 5129 stays. No change in play: tests
  and the season and storage goldens are the same, and the pack and tiles differ from 0.3.7 only by the name.
- **Not save compatible with 0.3.7** (nothing is released): a save made with the old ID loses its stations and
  cured fish. Enable the new mod in place of the old one.
- Entries below keep the names of their day (`TPF`, `TPFish...`, `TraditionalPreservationFish`).
- Internal: the guide is `1_FishMeat_Guide.md`; a stray tracked `tools/__pycache__` file is out of git.

## 0.3.7
- **Defaults and sandbox options** (ROADMAP §6, decisions 14 and 15). The season report confirms the defaults as
  they are: stockfish hung from late October to January dries outdoors in 50-55 days (32 at rate 1), February is
  a gamble (52-93), March rots; salt fish 15-34 days; maturing 60; press 1-2 days. No value changed.
- New sandbox options, defaults equal to the old fixed values: **Stockfish drying time** (`ColdDryDays`, 32),
  **Stockfish maturing time** (`MatureDays`, 60), **Salt press time** (`PressDays`, 2: a big fish's time; small
  fish keep half of it, `PRESS_MIN_HOURS`). Stockfish drying no longer follows Salt drying time at 8/3: a save
  that had changed DryDays gets 32 days for cold drying unless it sets the new option.

## 0.3.6
- **Stockfish Bale** (ROADMAP §6, pallet pitch C; user picks 2026-11-11: capacity 10, weight reduction 30, new icon
  and new world model, tie and untie from the right-click menu). A container item (`StockfishBale`, the pallet's
  `F.BALE_TYPE`) that takes only stockfish (`AcceptItemFunction = TraditionalPreservationFish.acceptBale`, any
  Cold Dried fish, gutted or half). Fish in it keep their own clocks and ripen on a pallet as loose ones do.
- **Tie a Bale** in the fish's submenu on selected stockfish: up to 10 weight of them (`F.baleLoad`, the rest stay
  out) with one use of Twine, or a Rope if there's no Twine (`F.findCord`); greyed out with "Needs Twine or a Rope"
  otherwise. **Untie Bale** on a bale: its fish and the cord come back (a Twine of one use, or the Rope). The bale
  records the cord (`cord` in its modData; a bale without one gives back Twine) and weighs it (0.1 or 0.8, saved
  as a custom weight). Timed actions `TPFishTieBale` (120 ticks) and `TPFishUntieBale` (60).
- Art: `tools/build_model.py` (new) writes the bale's ground model `Models_X/StockfishBale.glb` (seven stockfish in
  three layers, heads and tails alternating, two twine bands; FuelBarrel's glb writer), its texture and its icon
  (three Cold Dried fish icons stacked under a band). In-game size: `scale` of `StockfishBaleGround`.
- Tests: bale rules and cords in `test_pallet.lua`, the menus in `test_ui.lua` (its event stand-in now chains
  handlers as the game does).

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
