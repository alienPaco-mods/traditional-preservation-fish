-- Traditional Preservation (Fish & Meat): the curing rules shared by the recipes and the world.
-- Weather is the same everywhere, so one running total in global ModData tells every frame
-- how much drying it has had, including while its chunk was unloaded.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local Doors = require "TraditionalPreservationCore/Doors"
local Hearth = require "TraditionalPreservationCore/Hearth"

F.MOD_DATA_KEY = "TraditionalPreservationFishMeat"

-- Hours in the tub at most, and hours on the frame at a drying rate of 1. These set the recipes' times.
F.PRESS_HOURS = 48
F.DRY_HOURS = 288
F.COLD_DRY_HOURS = 768

-- A batch is pressed when the salt has gone through its thickest fish, so the heaviest fish sets the time:
-- PRESS_MIN_HOURS if every fish is up to PRESS_SMALL_WEIGHT (about 0.5 kg), PRESS_HOURS if any is
-- PRESS_BIG_WEIGHT (about 1 kg) or more, and in between by weight.
F.PRESS_MIN_HOURS = 24
F.PRESS_SMALL_WEIGHT = 1.1
F.PRESS_BIG_WEIGHT = 2.2
-- A press started before the heaviest fish set the time took this long.
local OLD_PRESS_HOURS = 12

-- The most weight of fish a tub takes, with room for a few bigger fish.
F.TUB_CAPACITY = 50
-- Fish too, so a tub can't be filled with fillets. A tub built with more slots still stops here.
F.TUB_MAX_ITEMS = 35
-- Each press of Craft hangs one stack, with one sprite and one timer, and every stack is limited
-- by weight alone. A full frame holds 20. MAX_STACKS is the frame's spots, from the Tiles.lua that
-- tools/build_tileset.py writes.
F.STACK_WEIGHT = 2.5
F.MAX_STACKS = Tiles.HANGERS.frame.stacks
-- Every station that hangs fish, by its first sprite: the first hanging fish sprite and its stacks
-- (from Tiles.lua), and the weight of each stack.
-- The Smokehouse chamber is closed (nothing hangs in sight) and its facings are two tiles apart, so it lists both.
local STACK_WEIGHTS = { frame = F.STACK_WEIGHT, medium = 15, large = 50, chamber = 15 }
-- And the most pieces in each stack, fish or meat alike (0.4.20): the Beam and the Gantry are for bigger fish, not
-- more of them. 25 is the slot every station is built with.
local STACK_PIECES = { frame = 25, medium = 12, large = 6, chamber = 25 }
F.HANGERS = {}
for name, hanger in pairs(Tiles.HANGERS) do
    local entry = { fishSprite = hanger.fishSprite, meatSprite = hanger.meatSprite, stacks = hanger.stacks, stackWeight = STACK_WEIGHTS[name],
        stackPieces = STACK_PIECES[name], closed = hanger.closed }
    for _, base in ipairs(hanger.bases or { hanger.base }) do F.HANGERS[base] = entry end
end

-- Vanilla's rules for cutting a fish: over this weight, into two fillets of this share of its
-- weight (more in spawning season, when part goes to roe), each with half its food.
F.MIN_SLICE_WEIGHT = 0.6
F.FILLET_WEIGHT = 0.05
-- These are already cut, so vanilla doesn't slice them.
F.UNSLICEABLE = { ["Base.FishFillet"] = true, ["Base.Salmon"] = true }
-- Vanilla's guts: only a fish it could cut has them, and they are this share of its weight.
F.GUTS_WEIGHT = 0.1
-- A fillet vanilla cut weighs a twentieth of its fish and holds half its food. Salted, it counts as what it
-- holds, half the gutted fish: it pays that much salt and comes out of the salt that heavy.
F.FILLET_FOOD_WEIGHT = (1 - F.GUTS_WEIGHT) * 0.5 / F.FILLET_WEIGHT
-- Packing takes SALT_PER_STEP salt for each SALT_STEP of the packed fish's weight, to the nearest step, and never
-- less than the SALT_MIN the recipe itself asks for. Quarter steps since 0.4.18: a started half weight made a
-- Steak pay a Beef's salt and a small panfish a big one's.
F.SALT_STEP = 0.25
F.SALT_PER_STEP = 2
F.SALT_MIN = 2
-- A fish over this weight is too thick to salt whole, as on the Volga: gut and split it first. Halves always pack.
F.SALT_WHOLE_MAX = 4.5
-- Gut Fish takes the head off too, as stockfish did, and a fish over HEAD_MIN_WEIGHT gives a Fish
-- Head for the pot: this share of its weight and of its food. The limit is above the guts' so small
-- fish can't be farmed for heads. Salted fish keep their heads.
F.HEAD_MIN_WEIGHT = 1.0
F.HEAD_WEIGHT = 0.1
F.HEAD_FOOD = 0.06
-- Butchering XP for gutting a whole fish while packing it.
F.PACK_GUTTING_XP = 5
-- Charque (phase 3b): the meat cuts that go in the salt as vanilla gives them, in the order of the meat stages'
-- IconsForTexture. Pork, Pork Chop and the Leg of Pork came with 6a, for the Smokehouse only: pork fat goes rancid
-- in sun and wind (meatRefusal).
F.MEAT_CUTS = { "Base.Beef", "Base.Steak", "Base.MuttonChop", "Base.Venison", "Base.Pork", "Base.PorkChop",
    "TraditionalPreservationFishMeat.LegOfPork" }
-- The pork cuts' and the leg's model indices.
F.PORK_INDICES = { [4] = true, [5] = true, [6] = true }
F.LEG_INDEX = 6
F.LEG_OF_PORK = "TraditionalPreservationFishMeat.LegOfPork"
-- The meat stages, which take their icon from MEAT_CUTS' index.
F.MEAT_STAGES = {
    ["TraditionalPreservationFishMeat.SaltPackedMeat"] = true, ["TraditionalPreservationFishMeat.SaltCuredMeat"] = true,
    ["TraditionalPreservationFishMeat.Charque"] = true, ["TraditionalPreservationFishMeat.SoakedCharque"] = true,
    ["TraditionalPreservationFishMeat.HotSmokedMeat"] = true, ["TraditionalPreservationFishMeat.DryCuredMeat"] = true,
    ["TraditionalPreservationFishMeat.CountryHam"] = true,
    ["TraditionalPreservationFishMeat.HotSmokedMeatSlice"] = true, ["TraditionalPreservationFishMeat.DryCuredMeatSlice"] = true,
    ["TraditionalPreservationFishMeat.CountryHamSlice"] = true,
}

function F.isMeatStage(fullType)
    return F.MEAT_STAGES[fullType] == true
end
F.PACKED_FISH = "TraditionalPreservationFishMeat.SaltPackedFish"
F.PACKED_MEAT = "TraditionalPreservationFishMeat.SaltPackedMeat"
-- A cut is pressed when the salt has reached its middle: PRESS_HOURS for a MEAT_PRESS_WEIGHT cut (a Beef or a
-- Venison), less by weight (a Steak about 29 hours), never under PRESS_MIN_HOURS. The heaviest cut sets the batch.
F.MEAT_PRESS_WEIGHT = 0.5
-- The long cure (6a), Country Cure Salted Meat: the salt goes all through, for meat that dries for weeks in the
-- Smokehouse. LONG_CUT_HOURS for cuts, LONG_LEG_HOURS for a batch with a leg in it. A leg takes only this one.
F.LONG_CUT_HOURS = 240
F.LONG_LEG_HOURS = 504
F.LONG_CURE_RECIPE = "CountryCureMeat"
-- A leg takes half fish's salt, as a country ham's dry cure (about 8%): LEG_SALT_PER_STEP for each SALT_STEP.
F.LEG_SALT_PER_STEP = 1
F.CURED_MEAT = "TraditionalPreservationFishMeat.SaltCuredMeat"
-- What a frame cold dries.
F.COLD_FISH = { ["TraditionalPreservationFishMeat.GuttedFish"] = true, ["TraditionalPreservationFishMeat.FishHalf"] = true }

-- How many looks a hanging fish has, from fresh to done, and its styles. A stack picks a style at
-- random when it starts, whatever is in it, so a frame doesn't look all alike. Both come from Tiles.lua.
F.DRYING_STAGES = Tiles.DRYING_STAGES
F.STYLE_SALT = Tiles.STYLES.SALT
F.STYLE_GUTTED = Tiles.STYLES.GUTTED
F.STYLE_HALF = Tiles.STYLES.HALF
F.STYLE_SALT_GUTTED = Tiles.STYLES.SALT_GUTTED
F.STYLE_SALT_HALF = Tiles.STYLES.SALT_HALF
F.SALT_STYLES = { 0, 0, 3, 4 }
F.COLD_STYLES = { 1, 1, 2 }
F.STYLE_MEAT = Tiles.STYLES.MEAT

-- Air above DRY_AIR_HUMIDITY slows drying, down to DAMP_AIR_RATE in saturated air.
F.DRY_AIR_HUMIDITY = 0.5
F.DAMP_AIR_RATE = 0.4
-- Weather can slow a frame this far and no further, so a batch takes MAX_DRY_DAYS at most, plus rain.
F.MAX_DRY_DAYS = 27
F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
-- Indoors the fish stays dry and the air moves less. People dried fish indoors with the
-- windows open, so it's slower but a fair choice. Under a roof with no room round it (a porch, an
-- open shed) salt fish dries as in the open air, in the shade and out of the rain.
F.SHELTERED_RATE = 0.65

-- Cold drying runs at full rate from 0 C to COLD_BEST, slows to COLD_MIN_RATE at COLD_LIMIT and stops
-- above that. Below freezing the water has to leave as vapour from ice, which is slower: down to
-- FROST_RATE at HARD_FROST, and HARD_FROST_RATE below it.
F.COLD_BEST = 5
F.COLD_LIMIT = 10
F.COLD_MIN_RATE = 0.67
F.HARD_FROST = -5
F.FROST_RATE = 0.8
F.HARD_FROST_RATE = 0.6
-- Stockfish dries in the wind: half speed in still air, up to WINDY_RATE in a breeze of WIND_GOOD
-- (ClimateManager's wind intensity, 0 to 1). Live wind averages about 0.11 on dry days.
F.WIND_GOOD = 0.25
F.CALM_RATE = 0.5
F.WINDY_RATE = 1.2
-- An open shed's roof breaks some of the wind, so cold drying there runs at this share, rain or not.
F.COVERED_COLD_RATE = 0.75
-- Fresh fish suffers most. Until it is FRESH_UNTIL dried and has formed a dry skin, hard frost breaks
-- the flesh and lying wet above freezing starts it going off. Each adds a little to its spoilage,
-- scaled by how wet the fish still is: FREEZE_DAMAGE_HOURS of hard frost on a fresh stack add
-- FREEZE_DAMAGE, WET_DAMAGE_HOURS wet add WET_DAMAGE. Together they never take it past DAMAGE_CAP.
F.FRESH_UNTIL = 0.3
F.FREEZE_DAMAGE_HOURS = 72
F.FREEZE_DAMAGE = 0.1
F.WET_DAMAGE_HOURS = 48
F.WET_DAMAGE = 0.05
F.DAMAGE_CAP = 0.25

-- Spoilage follows the season, not the day: it reads a running average of the weather over the
-- core's Weather.SEASON_HOURS, so a warm afternoon in January does nothing.
-- Unsalted fish spoils once the season is above RAW_SPOIL_ABOVE, and rots on the frame after
-- RAW_SPOIL_HOURS of that. Each 10 degrees more adds as much again
-- (twice as fast at +10, three times at +20).
F.RAW_SPOIL_ABOVE = 10
F.RAW_SPOIL_HOURS = 48
-- Salt fish only suffers in a hot, muggy season. SALT_SPOIL_HOURS of that is a rotten stack, and
-- less takes the same share off how long it keeps.
F.SALT_SPOIL_ABOVE = 22
F.SALT_SPOIL_HUMIDITY = 0.4
F.SALT_SPOIL_HOURS = 480
-- A tub in a warm season: the flesh by the spine spoils (bone taint) before the salt reaches it. Above WARM_CURE_ABOVE
-- (the season's mean) the batch picks up spoilage at WARM_CURE_SHARE of RAW_SPOIL_HOURS' rate, and each
-- 10 degrees more adds as much again. The pressed fish carries it onto the frame.
F.WARM_CURE_ABOVE = 20
F.WARM_CURE_SHARE = 0.25
-- The long cure wants the cold (0.4.14): its salt takes weeks to reach the middle, so the meat sours at the bone
-- unless the season stays cool, which is why hog killing waited for frost. Above LONG_CURE_ABOVE (the season's mean)
-- a Country Cure batch spoils in step with the warmth, and is rotten after LONG_CURE_ROT_HOURS (a leg's cure) at
-- LONG_CURE_ROT_AT. At 12 C a leg loses two fifths of its keeping and cuts a fifth. On top of the warm cure above.
F.LONG_CURE_ABOVE = 10
F.LONG_CURE_ROT_AT = 15
F.LONG_CURE_ROT_HOURS = 504
-- Salt fish hangs in the shade. In open sun above HEAT_ABOVE (the temperature now), until it is
-- SALT_FRESH_UNTIL dried, the skin hardens over wet flesh and the fat rusts: HEAT_DAMAGE_HOURS of that on
-- a fresh stack add HEAT_DAMAGE to its spoilage, scaled by how wet it still is, within DAMAGE_CAP.
F.HEAT_ABOVE = 25
F.SALT_FRESH_UNTIL = 0.5
F.HEAT_DAMAGE_HOURS = 24
F.HEAT_DAMAGE = 0.05
-- Stockfish matures in storage, as it did in the warehouses after the racks: MATURE_DAYS on its own food clock
-- (a fridge slows it, a freezer stops it). Rehydrated, a ripe fish lifts the mood by MATURE_UNHAPPY and a
-- fresh-off-the-frame one lowers it as much; halfway is neither. A dish takes on the share it gets.
F.MATURE_DAYS = 60
F.MATURE_UNHAPPY = 10
-- Dry-cured meat ages after it has dried (6c), on its own food clock as stockfish matures: a cut AGE_CUT_DAYS, a
-- Country Ham AGE_HAM_DAYS. Left hanging where it dried it takes HANG_AGE_SHARE of that; once down it can't go
-- back up. It is good to eat before; Aged, a whole cut lifts the mood by AGED_CUT_UNHAPPY and a whole ham by
-- AGED_HAM_UNHAPPY, and the ham takes AGED_HAM_BOREDOM off the boredom: the ham's reward, with its slices.
F.AGE_CUT_DAYS = 30
F.AGE_HAM_DAYS = 90
F.HANG_AGE_SHARE = 0.75
F.AGED_CUT_UNHAPPY = -8
F.AGED_HAM_UNHAPPY = -40
F.AGED_HAM_BOREDOM = -20
-- Rinsing Salt Cured fish, as on the Volga: the excess salt soaked off before it hangs. Optional. It takes
-- RINSE_LITRES of water a fish, leaves RINSED_THIRST of the thirst, and the fish keeps RINSED_KEEPING as long
-- (less salt, less protection). A Salt Dried fish from it loses its sharp tang too (unhappiness 3 to 0).
F.RINSE_LITRES = 0.15
F.RINSED_THIRST = 2 / 3
F.RINSED_KEEPING = 0.9
F.RINSE_REACH = 3
F.RINSE_TICKS = 60

-- The Stockfish Pallet: stockfish on it ripens faster where the warehouses kept it, dry and airy. A loft (a room
-- upstairs) PALLET_LOFT times the food clock, a ground-floor room PALLET_GROUND; covered, outdoors or a basement
-- ("too damp") no faster than a shelf. Its stack shows a third, two thirds or full by the weight on it.
F.PALLET_LOFT = 2
F.PALLET_GROUND = 1.5
F.PALLET_CAPACITY = 20
F.PALLET_LEVELS = 3
-- A Stockfish Bale: stockfish tied up for carrying and storing, as it was shipped from the Lofoten. It holds
-- BALE_CAPACITY weight of stockfish (the script's Capacity) and nothing else; the fish keep their own clocks.
-- It is tied with one use of Twine or a Rope, and untying gives the cord back; the bale weighs what tied it.
F.BALE_TYPE = "TraditionalPreservationFishMeat.StockfishBale"
F.BALE_CAPACITY = 10
F.BALE_CORDS = {
    { type = "Base.Twine", key = "twine", uses = 1, weight = 0.1 },
    { type = "Base.Rope", key = "rope", weight = 0.8 },
}
F.BALE_TIE_TICKS = 120
F.BALE_UNTIE_TICKS = 60

-- Cold smoke (5d, TraditionalPreservationFishMeatSmokehouse.lua): fire hours count only on a day at or under
-- COLD_SMOKE_MAX (a banked smoulder lifts the shed BANKED_LIFT, 15 C; over 30 C at the meat it cooks rather than
-- smokes; 20 C until 0.4.12, when the lift grew from 10 to 15). Stacks in
-- a Smokehouse, by stackId, as the World last saw them (not saved); a finished one waits at SHED_WAIT until seen.
F.COLD_SMOKE_MAX = 15
-- The smoulder's warmth: while the Firebox burns, a Smokehouse stack dries as if the shed were this much warmer than
-- outdoors, banked or stoked, and the warmed air holds the same water, so its humidity halves every 10 C (F.liftedRates).
-- A stack's modData.burning holds the fire's mode, Core's Hearth.STOKED or BANKED.
F.BANKED_LIFT = 15
F.STOKED_LIFT = 20
F.smokeStations = {}
-- Every hanging stack's station, by stackId, as the World last saw it (not saved): a stack that rots comes down as
-- what was hung, not as the finished thing (F.rottenOutputs).
F.stackStations = {}
F.SHED_WAIT = 0.999

-- Charque (phase 3c): Salt Cured meat dried in the summer sun, as in Brazil's charqueadas. CHARQUE_HOURS at a rate of
-- 1, which takes CHARQUE_FULL_HEAT and up (heat helps, and does no harm), nothing at 0 C or below, in between by
-- the temperature; damp air slows it as salt fish (airRate). Still air dries at CHARQUE_CALM_RATE, a breeze of
-- WIND_GOOD at CHARQUE_WINDY_RATE. Under an open roof it dries as in the open without the rain; indoors at
-- CHARQUE_INDOORS_RATE with no wind. On an open frame, CHARQUE_RAIN_HOURS of rain take back CHARQUE_REWET of the
-- progress. Spoilage is salt fish's hot and muggy rule only. Numbers from tools/charque_report.lua.
F.CHARQUE_HOURS = 120
F.CHARQUE_FULL_HEAT = 25
F.CHARQUE_CALM_RATE = 0.65
F.CHARQUE_WINDY_RATE = 1.2
F.CHARQUE_INDOORS_RATE = 0.65
F.CHARQUE_REWET = 0.1
F.CHARQUE_RAIN_HOURS = 6
-- The sandbox's Charque switch: off, meat can't be packed in salt nor hung.
F.CHARQUE_ON = true

-- Dry curing (6b): meat hung in the Smokehouse never comes out Charque. It dries slowly in cool air, as a ham or a
-- side of suho meso does: its need is by the heaviest piece (DRY_CURE_HOURS: three weeks at a rate of 1 for a Beef,
-- six for a Leg of Pork, a Steak about 19 days), and its rate is full from DRY_CURE_FULL_HEAT (a cellar's
-- 12 C) and never under DRY_CURE_FROST_RATE (frost only slows it), times the air's (airRate). The fire's warmth
-- lifts the shed as it does for fish (F.liftedRates).
F.DRY_CURE_HOURS = { { 0.45, 504 }, { 2.25, 1008 } }
F.DRY_CURE_FULL_HEAT = 12
F.DRY_CURE_FROST_RATE = 0.25
-- Country Cured meat also dry cures on a Frame, Beam or Gantry in the shade (0.4.15): under a roof or indoors as in the shed
-- with the fire out, and in a basement, the curing cellar, at a steady DRY_CURE_BASEMENT_RATE all year (its 15 C is
-- full heat; the still air takes a third). Always air dried: smoke is the Smokehouse's.
F.DRY_CURE_BASEMENT_RATE = 2 / 3
-- Under-salted (6b): Corned meat has salt for a few days, not for weeks in the shed. Until a hot cook is done it
-- picks up spoilage by the shed's temperature: rotten in UNDER_CURE_HOURS at UNDER_CURE_AT, UNDER_CURE_TENFOLD times
-- faster for every 10 C more (and slower for less), no faster than at UNDER_CURE_MAX. Near freezing it ends about
-- half spoiled; in a shed at 10 C and up, or by a banked fire, it rots before it has dried.
F.UNDER_CURE_HOURS = 672
F.UNDER_CURE_AT = 10
F.UNDER_CURE_TENFOLD = 5
F.UNDER_CURE_MAX = 30

-- From DryingCraftLogic, so the frame's wetness readout tells the truth.
local RAIN_WETTING = 0.001  -- per game second, at full intensity
local SNOW_WETTING = 0.5
local WET_DRYING_OFF = 0.0002  -- per game second, at a temperature rate of 1
local SECONDS_PER_HOUR = 3600

-- The fish each IconsForTexture entry in the item scripts belongs to, in the same order.
F.FISH_ICONS = {
    "Base.FishFillet", "Base.Salmon", "Base.LargemouthBass", "Base.SmallmouthBass", "Base.SpottedBass",
    "Base.StripedBass", "Base.Walleye", "Base.Sauger", "Base.BlackCrappie", "Base.WhiteCrappie",
    "Base.Bluegill", "Base.RedearSunfish", "Base.GreenSunfish", "Base.BlueCatfish", "Base.ChannelCatfish",
    "Base.FlatheadCatfish", "Base.Muskellunge", "Base.WhiteBass", "Base.YellowPerch", "Base.FreshwaterDrum",
    "Base.AligatorGar", "Base.Paddlefish",
}

-- What each stage keeps of the item it was made from. With a maxWeight, each fish keeps a
-- random share between weight and maxWeight. Soaking gives back the bulk drying took (hunger 0.7).
-- A prep stage names the fish itself (Gutted Walleye, Walleye Half); the others go in brackets after it.
F.STAGES = {
    ["TraditionalPreservationFishMeat.SaltPackedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_Packed", weight = 1, nutrition = 1, hunger = 1, gutted = true },
    ["TraditionalPreservationFishMeat.SaltPressedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_Pressed", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1, salty = true },
    ["TraditionalPreservationFishMeat.SaltDriedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_Dried", weight = 0.45, nutrition = 0.9, hunger = 0.7, salty = true, rinsedUnhappy = 0 },
    ["TraditionalPreservationFishMeat.SoakedSaltFish"] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedSalt", weight = 1.8, nutrition = 1, hunger = 1 / 0.7 },
    ["TraditionalPreservationFishMeat.GuttedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_Gutted", weight = 1, nutrition = 1, hunger = 1, gutted = true, headless = true, prep = true },
    ["TraditionalPreservationFishMeat.FishHalf"] = { weight = 1, nutrition = 1, hunger = 1, prep = true },
    ["TraditionalPreservationFishMeat.ColdDriedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_ColdDried", weight = 0.22, nutrition = 0.95, hunger = 0.7, matures = true },
    ["TraditionalPreservationFishMeat.SoakedColdFish"] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedCold", weight = 3, nutrition = 1, hunger = 1 / 0.7, ripened = true },
    ["TraditionalPreservationFishMeat.SaltPackedMeat"] = { name = "IGUI_TraditionalPreservationFishMeat_Packed", weight = 1, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFishMeat.SaltCuredMeat"] = { name = "IGUI_TraditionalPreservationFishMeat_Cured", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1, salty = true },
    -- About half the raw cut's weight (0.55 of the cured), as salt fish keeps its food. Soaked, it gets back about as much.
    ["TraditionalPreservationFishMeat.Charque"] = { name = "IGUI_TraditionalPreservationFishMeat_Charque", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true },
    -- Hot smoked (the Smokehouse, 5c): cooked, still moist, about 70% of the raw weight (0.78 of the cured).
    ["TraditionalPreservationFishMeat.HotSmokedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_HotSmoked", weight = 0.78, nutrition = 1, hunger = 1, salty = true },
    ["TraditionalPreservationFishMeat.HotSmokedMeat"] = { name = "IGUI_TraditionalPreservationFishMeat_HotSmoked", weight = 0.78, nutrition = 1, hunger = 1, salty = true },
    ["TraditionalPreservationFishMeat.SoakedCharque"] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedCharque", weight = 1.6, nutrition = 1, hunger = 1 / 0.7, salty = true },
    -- Cold smoked (the Smokehouse, 5d): dried in smoky air, as dry as Salt Dried fish or charque. Meat smoked so is no
    -- longer charque but the start of the Dry-Cured line, named by the animal ("Dry-Cured Beef (Cold Smoked)").
    ["TraditionalPreservationFishMeat.ColdSmokedFish"] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.45, nutrition = 0.9, hunger = 0.7, salty = true },
    ["TraditionalPreservationFishMeat.DryCuredMeat"] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true, dryCured = true, ages = true },
    -- A Leg of Pork dried in the Smokehouse (6b): Dry-Cured meat's shares, an item of its own for its longer keeping.
    ["TraditionalPreservationFishMeat.CountryHam"] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true, dryCured = true, ages = true, ham = true },
    -- Slices (6c, TraditionalPreservationFishMeatSlices.lua): named by the piece they were cut from (modData.cut).
    ["TraditionalPreservationFishMeat.HotSmokedMeatSlice"] = { slice = true, hot = true },
    ["TraditionalPreservationFishMeat.DryCuredMeatSlice"] = { slice = true },
    ["TraditionalPreservationFishMeat.CountryHamSlice"] = { slice = true },
}

-- The animal each of MEAT_CUTS comes from, by model index, for the finished meat's names.
F.MEAT_ANIMALS = { "Beef", "Beef", "Mutton", "Venison", "Pork", "Pork", "Pork" }

-- The low end of DryingCraftLogic's curve: nothing at freezing, 1 at 20 C. It stops there, so
-- heat can't finish a batch in under DRY_HOURS.
function F.temperatureRate(celsius)
    local rate = math.max(0, math.min(celsius, 20)) / 20
    return rate * rate
end

-- Cold drying (unsalted fish in frost and wind) by temperature: full speed from 0 C to COLD_BEST,
-- slowing to COLD_MIN_RATE at COLD_LIMIT, nothing above it. Frost slows it to FROST_RATE at HARD_FROST,
-- and harder frost to HARD_FROST_RATE.
function F.coldRate(celsius)
    if celsius > F.COLD_LIMIT then return 0 end
    if celsius < F.HARD_FROST then return F.HARD_FROST_RATE end
    if celsius < 0 then return 1 - celsius / F.HARD_FROST * (1 - F.FROST_RATE) end
    if celsius <= F.COLD_BEST then return 1 end
    local warmth = (celsius - F.COLD_BEST) / (F.COLD_LIMIT - F.COLD_BEST)
    return 1 - warmth * (1 - F.COLD_MIN_RATE)
end

-- What the wind does to cold drying: CALM_RATE in still air, rising to WINDY_RATE at WIND_GOOD.
-- A reading without wind leaves the rate as it is.
function F.windRate(wind)
    if not wind then return 1 end
    local breeze = math.min(math.max(wind, 0) / F.WIND_GOOD, 1)
    return F.CALM_RATE + breeze * (F.WINDY_RATE - F.CALM_RATE)
end

-- Damp air slows open drying: full speed up to DRY_AIR_HUMIDITY, down to DAMP_AIR_RATE in saturated air.
function F.airRate(humidity)
    local dryAir = F.DRY_AIR_HUMIDITY
    if humidity <= dryAir then return 1 end
    local dampness = math.min((humidity - dryAir) / (1 - dryAir), 1)
    return 1 - dampness * (1 - F.DAMP_AIR_RATE)
end

-- Charque's rate by temperature: nothing at 0 C or below, full from CHARQUE_FULL_HEAT.
function F.charqueWarmRate(celsius)
    return math.max(0, math.min(celsius / F.CHARQUE_FULL_HEAT, 1))
end

-- Dry curing's rate by temperature: DRY_CURE_FROST_RATE at its lowest, full from DRY_CURE_FULL_HEAT.
function F.dryCureRate(celsius)
    return math.max(F.DRY_CURE_FROST_RATE, math.min(celsius / F.DRY_CURE_FULL_HEAT, 1))
end

-- The hours at a rate of 1 a stack of meat needs in the Smokehouse, by its heaviest piece: straight between the two
-- points and on below them, no more than the leg's.
function F.dryCureHours(heaviest)
    local low, high = F.DRY_CURE_HOURS[1], F.DRY_CURE_HOURS[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.min(hours, high[2])
end

-- The share of itself under-salted meat loses an hour at this temperature in the shed.
function F.underCureRate(celsius)
    local warmth = (math.min(celsius, F.UNDER_CURE_MAX) - F.UNDER_CURE_AT) / 10
    return F.UNDER_CURE_TENFOLD ^ warmth / F.UNDER_CURE_HOURS
end

-- What the wind does to charque: CHARQUE_CALM_RATE in still air, rising to CHARQUE_WINDY_RATE at WIND_GOOD.
-- Salt fish's and charque's drying rates in air warmed by lift C (the Smokehouse with the fire burning): the
-- temperature lifted, the humidity halved for every 10 C of it, the wind as outdoors. Then dry curing's rate and
-- under-salted meat's spoiling in the same air (no wind in the shed).
function F.liftedRates(weather, lift)
    local humidity = weather.humidity * 0.5 ^ (lift / 10)
    local air = F.airRate(humidity)
    local celsius = weather.temperature + lift
    return math.max(F.temperatureRate(celsius) * air, F.MIN_DRY_RATE),
        F.charqueWarmRate(celsius) * air * F.charqueWindRate(weather.wind),
        F.dryCureRate(celsius) * air, F.underCureRate(celsius)
end

function F.charqueWindRate(wind)
    if not wind then return 1 end
    local breeze = math.min(math.max(wind, 0) / F.WIND_GOOD, 1)
    return F.CHARQUE_CALM_RATE + breeze * (F.CHARQUE_WINDY_RATE - F.CHARQUE_CALM_RATE)
end

-- The weather totals: hours of drying done open, sheltered (indoors), covered (a roof, no room), cold and cold
-- covered, charque open, covered and sheltered, hours of spoiling raw and salted,
-- hours of hard frost and of cold fish lying wet above freezing, of a warm cure, of heat and of rain, the
-- wetness rain left on open frames and on cold ones, for cold smoke (5d) all hours and the cool ones, and salt fish's
-- and charque's drying in a Smokehouse warmed by a banked or a stoked fire, and dry curing's drying and under-salted
-- meat's spoiling there with the fire out, banked and stoked.
function F.newLedger(now)
    return { lastHour = now, wetness = 0, coldWetness = 0, open = 0, sheltered = 0, covered = 0, cold = 0, coldCovered = 0, rawSpoil = 0, saltSpoil = 0,
        hardFrost = 0, coldWet = 0, warmCure = 0, heat = 0, charque = 0, charqueCovered = 0, charqueSheltered = 0, charqueRain = 0,
        clock = 0, smokeCool = 0, smokeBanked = 0, smokeStoked = 0, charqueBanked = 0, charqueStoked = 0,
        dryCure = 0, dryCureBanked = 0, dryCureStoked = 0, underCure = 0, underCureBanked = 0, underCureStoked = 0,
        longCureSpoil = 0, dryCureBasement = 0, underCureBasement = 0 }
end

-- Adds one stretch of weather to the totals. Open frames dry nothing until the rain has gone
-- and the wetness it left has dried off. Cold drying only minds rain, as snow doesn't wet frozen fish.
function F.advance(ledger, now, weather)
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now

    local minRate = F.MIN_DRY_RATE
    local temperatureRate = F.temperatureRate(weather.temperature)
    local seconds = hours * SECONDS_PER_HOUR
    local dryingOff = WET_DRYING_OFF * math.max(temperatureRate, minRate) * seconds
    if weather.precipitation > 0 then
        local wetting = RAIN_WETTING * weather.precipitation * (weather.isSnow and SNOW_WETTING or 1)
        ledger.wetness = math.min(ledger.wetness + wetting * seconds, 1)
    else
        ledger.wetness = math.max(ledger.wetness - dryingOff, 0)
    end
    local raining = weather.precipitation > 0 and not weather.isSnow
    if raining then
        ledger.coldWetness = math.min(ledger.coldWetness + RAIN_WETTING * weather.precipitation * seconds, 1)
    else
        ledger.coldWetness = math.max(ledger.coldWetness - dryingOff, 0)
    end

    local rate = temperatureRate * F.airRate(weather.humidity)
    ledger.openRate = ledger.wetness <= 0 and math.max(rate, minRate) or 0
    ledger.shelteredRate = math.max(rate * F.SHELTERED_RATE, minRate)
    ledger.coveredRate = math.max(rate, minRate)
    local coldRate = F.coldRate(weather.temperature) * F.windRate(weather.wind)
    ledger.coldRate = ledger.coldWetness <= 0 and coldRate or 0
    ledger.coldCoveredRate = coldRate * F.COVERED_COLD_RATE
    local charqueRate = F.charqueWarmRate(weather.temperature) * F.airRate(weather.humidity)
    ledger.charqueCoveredRate = charqueRate * F.charqueWindRate(weather.wind)
    ledger.charqueRate = ledger.wetness <= 0 and ledger.charqueCoveredRate or 0
    ledger.charqueShelteredRate = charqueRate * F.CHARQUE_INDOORS_RATE
    ledger.charque = ledger.charque + ledger.charqueRate * hours
    ledger.charqueCovered = ledger.charqueCovered + ledger.charqueCoveredRate * hours
    ledger.charqueSheltered = ledger.charqueSheltered + ledger.charqueShelteredRate * hours
    if raining then ledger.charqueRain = ledger.charqueRain + hours end
    ledger.clock = ledger.clock + hours
    if weather.temperature <= F.COLD_SMOKE_MAX then ledger.smokeCool = ledger.smokeCool + hours end
    local underBanked, underStoked
    ledger.bankedRate, ledger.charqueBankedRate, ledger.dryCureBankedRate, underBanked = F.liftedRates(weather, F.BANKED_LIFT)
    ledger.stokedRate, ledger.charqueStokedRate, ledger.dryCureStokedRate, underStoked = F.liftedRates(weather, F.STOKED_LIFT)
    ledger.dryCureRate = F.dryCureRate(weather.temperature) * F.airRate(weather.humidity)
    ledger.dryCure = ledger.dryCure + ledger.dryCureRate * hours
    ledger.dryCureBanked = ledger.dryCureBanked + ledger.dryCureBankedRate * hours
    ledger.dryCureStoked = ledger.dryCureStoked + ledger.dryCureStokedRate * hours
    ledger.dryCureBasement = ledger.dryCureBasement + F.DRY_CURE_BASEMENT_RATE * hours
    ledger.underCureBasement = ledger.underCureBasement + F.underCureRate(Weather.BASEMENT_TEMPERATURE) * hours
    ledger.underCure = ledger.underCure + F.underCureRate(weather.temperature) * hours
    ledger.underCureBanked = ledger.underCureBanked + underBanked * hours
    ledger.underCureStoked = ledger.underCureStoked + underStoked * hours
    ledger.smokeBanked = ledger.smokeBanked + ledger.bankedRate * hours
    ledger.smokeStoked = ledger.smokeStoked + ledger.stokedRate * hours
    ledger.charqueBanked = ledger.charqueBanked + ledger.charqueBankedRate * hours
    ledger.charqueStoked = ledger.charqueStoked + ledger.charqueStokedRate * hours
    ledger.temperature = weather.temperature
    ledger.wind = weather.wind
    ledger.open = ledger.open + ledger.openRate * hours
    ledger.sheltered = ledger.sheltered + ledger.shelteredRate * hours
    ledger.covered = ledger.covered + ledger.coveredRate * hours
    ledger.cold = ledger.cold + ledger.coldRate * hours
    ledger.coldCovered = ledger.coldCovered + ledger.coldCoveredRate * hours
    if weather.temperature < F.HARD_FROST then ledger.hardFrost = ledger.hardFrost + hours end
    if ledger.coldWetness > 0 and weather.temperature > 0 then ledger.coldWet = ledger.coldWet + hours end
    if weather.temperature > F.HEAT_ABOVE then ledger.heat = ledger.heat + hours end

    Weather.season(ledger, "seasonTemperature", weather.temperature, hours)
    Weather.season(ledger, "seasonHumidity", weather.humidity, hours)
    local warmth = ledger.seasonTemperature - F.RAW_SPOIL_ABOVE
    ledger.rawSpoiling = warmth > 0
    if ledger.rawSpoiling then
        ledger.rawSpoil = ledger.rawSpoil + (1 + warmth / 10) * hours
    end
    local cureWarmth = ledger.seasonTemperature - F.WARM_CURE_ABOVE
    ledger.warmCuring = cureWarmth > 0
    if ledger.warmCuring then
        ledger.warmCure = ledger.warmCure + (1 + cureWarmth / 10) * hours
    end
    local longWarmth = ledger.seasonTemperature - F.LONG_CURE_ABOVE
    ledger.longCuring = longWarmth > 0
    if ledger.longCuring then
        ledger.longCureSpoil = ledger.longCureSpoil + longWarmth / (F.LONG_CURE_ROT_AT - F.LONG_CURE_ABOVE) / F.LONG_CURE_ROT_HOURS * hours
    end
    ledger.saltSpoiling = ledger.seasonTemperature > F.SALT_SPOIL_ABOVE and ledger.seasonHumidity > F.SALT_SPOIL_HUMIDITY
    if ledger.saltSpoiling then
        ledger.saltSpoil = ledger.saltSpoil + hours
    end
end

-- Whether a fresh salt stack is in open sun in a heat wave.
function F.scorching(modData, temperature)
    return not modData.sheltered and not modData.covered and temperature > F.HEAT_ABOVE
        and (modData.dried or 0) < F.SALT_FRESH_UNTIL * F.DRY_HOURS
end

-- How a hanging stack is doing right now, for its popup. reason says why it isn't drying, and
-- hoursLeft assumes the weather stays as it is.
function F.stackStatus(isCold, modData, ledger)
    local hours = isCold and F.COLD_DRY_HOURS or F.DRY_HOURS
    local temperature = ledger.temperature or 0
    local rate, reason
    if isCold and modData.sheltered then
        rate, reason = 0, "Roof"
    elseif isCold and temperature > F.COLD_LIMIT then
        rate, reason = 0, "TooWarm"
    elseif isCold and modData.covered then
        rate = ledger.coldCoveredRate or 0
    elseif isCold then
        rate = ledger.coldRate or 0
        if rate <= 0 then reason = "Rain" end
    elseif modData.sheltered then
        -- A burning Firebox warms a Smokehouse stack's air (F.smokeStep).
        rate = ledger.shelteredRate or 0
        if modData.burning then
            rate = math.max(rate, (modData.burning == Hearth.STOKED and ledger.stokedRate or ledger.bankedRate) or 0)
        end
    elseif modData.covered then
        rate = ledger.coveredRate or 0
    else
        rate = ledger.openRate or 0
        if rate <= 0 then reason = "Rain" end
    end
    local dried = modData.dried or 0
    return {
        progress = math.min(dried / hours, 1),
        rate = rate,
        reason = reason,
        hoursLeft = rate > 0 and math.max(hours - dried, 0) / rate or nil,
        spoiled = math.min(modData.spoiled or 0, 1),
        spoiling = (isCold and ledger.rawSpoiling or not isCold and ledger.saltSpoiling) == true,
        scorching = not isCold and F.scorching(modData, temperature),
    }
end

-- The popup's Spoilage line for a hanging stack's status, a translation key taking the share spoiled, or nil with
-- nothing to say: what is spoiling it now (the season, or hot sun), else just how much has gone.
function F.spoilWarning(status, isCold)
    if status.spoiling then
        return isCold and "IGUI_TraditionalPreservationFishMeat_SpoilingWarm" or "IGUI_TraditionalPreservationFishMeat_SpoilingMuggy"
    end
    if status.scorching then return "IGUI_TraditionalPreservationFishMeat_SpoilingSun" end
    if status.spoiled > 0 then return "IGUI_TraditionalPreservationFishMeat_Spoiled" end
    return nil
end

-- The popup's word for the temperature, a translation key: good, cool, mild, too warm, frost or hard frost,
-- or for salt fish in the sun, too hot (exposed: no roof over it).
function F.temperatureWord(isCold, celsius, exposed)
    if isCold then
        if celsius > F.COLD_LIMIT then return "IGUI_TraditionalPreservationFishMeat_TempTooWarm" end
        if celsius > F.COLD_BEST then return "IGUI_TraditionalPreservationFishMeat_TempMild" end
        if celsius >= 0 then return "IGUI_TraditionalPreservationFishMeat_TempGoodCold" end
        if celsius >= F.HARD_FROST then return "IGUI_TraditionalPreservationFishMeat_TempFrost" end
        return "IGUI_TraditionalPreservationFishMeat_TempHardFrost"
    end
    if exposed and celsius > F.HEAT_ABOVE then return "IGUI_TraditionalPreservationFishMeat_TempHot" end
    if celsius >= 20 then return "IGUI_TraditionalPreservationFishMeat_TempGoodWarm" end
    if celsius > 0 then return "IGUI_TraditionalPreservationFishMeat_TempCool" end
    return "IGUI_TraditionalPreservationFishMeat_TempFrost"
end

-- How a hanging charque stack is doing right now, for its popup, as stackStatus.
function F.charqueStatus(modData, ledger)
    local rate, reason
    local curing = F.dryCuring(modData)
    local lift = 0
    local curePlace = curing and F.curePlace(modData)
    if curePlace == "Basement" then
        rate = F.DRY_CURE_BASEMENT_RATE
    elseif curePlace == "Open" then
        rate, reason = 0, "NeedsRoof"
    elseif curing then
        rate = ledger.dryCureRate or 0
        if modData.burning then
            local stoked = modData.burning == Hearth.STOKED
            rate = math.max(rate, (stoked and ledger.dryCureStokedRate or ledger.dryCureBankedRate) or 0)
            lift = stoked and F.STOKED_LIFT or F.BANKED_LIFT
        end
    elseif modData.sheltered then
        rate = ledger.charqueShelteredRate or 0
        if modData.burning then
            rate = math.max(rate, (modData.burning == Hearth.STOKED and ledger.charqueStokedRate or ledger.charqueBankedRate) or 0)
        end
    elseif modData.covered then
        rate = ledger.charqueCoveredRate or 0
    else
        rate = ledger.charqueRate or 0
        if rate <= 0 and (ledger.wetness or 0) > 0 then reason = "Rain" end
    end
    if rate <= 0 and not reason then reason = "TooCold" end
    local dried, hours = modData.dried or 0, F.meatHours(modData)
    return {
        progress = math.min(dried / hours, 1),
        rate = rate,
        reason = reason,
        hoursLeft = rate > 0 and math.max(hours - dried, 0) / rate or nil,
        spoiled = math.min((modData.spoiled or 0) + (modData.underSpoiled or 0), 1),
        spoiling = ledger.saltSpoiling == true,
        scorching = false,
        dryCuring = curing,
        -- Corned meat in the shed, and the shed's temperature it spoils by.
        underSalted = curing and modData.underCured == true,
        shedTemperature = curePlace == "Basement" and Weather.BASEMENT_TEMPERATURE or (ledger.temperature or 0) + lift,
    }
end

-- The popup's word for the temperature on a charque stack: hot sun is good, then warm, cool and too cold.
function F.charqueTemperatureWord(celsius)
    if celsius >= F.CHARQUE_FULL_HEAT then return "IGUI_TraditionalPreservationFishMeat_TempHotGood" end
    if celsius >= 15 then return "IGUI_TraditionalPreservationFishMeat_TempGoodWarm" end
    if celsius > 0 then return "IGUI_TraditionalPreservationFishMeat_TempCool" end
    return "IGUI_TraditionalPreservationFishMeat_TempTooCold"
end

-- The popup's word for the temperature on meat in the Smokehouse: cool air is right, frost only slows it.
function F.dryCureTemperatureWord(celsius)
    if celsius >= F.DRY_CURE_FULL_HEAT then return "IGUI_TraditionalPreservationFishMeat_TempGoodCure" end
    if celsius > 0 then return "IGUI_TraditionalPreservationFishMeat_TempCool" end
    return "IGUI_TraditionalPreservationFishMeat_TempFrostSlow"
end

-- The popup's word for the wind on a cold frame: calm, a light breeze or a good drying wind.
function F.windWord(wind)
    wind = wind or 0
    if wind >= F.WIND_GOOD then return "IGUI_TraditionalPreservationFishMeat_WindGood" end
    if wind >= F.WIND_GOOD / 3 then return "IGUI_TraditionalPreservationFishMeat_WindLight" end
    return "IGUI_TraditionalPreservationFishMeat_WindCalm"
end

-- The ledger is the mod's global ModData table itself, so its keys are the ones in every save.
function F.getLedger()
    local data = ModData.getOrCreate(F.MOD_DATA_KEY)
    -- cold, hardFrost, covered, warmCure, heat, the charque, the smoke, the smoulder's, dry curing's and the long
    -- cure's totals came after the first release, so a save can have the rest without them.
    if not data.underCureBasement then
        local ledger = F.newLedger(getGameTime():getWorldAgeHours())
        for key, value in pairs(ledger) do
            if data[key] == nil then data[key] = value end
        end
    end
    return data
end

-- Hours in the tub for a batch whose heaviest fish weighs this much.
function F.pressHours(heaviest)
    local share = (heaviest - F.PRESS_SMALL_WEIGHT) / (F.PRESS_BIG_WEIGHT - F.PRESS_SMALL_WEIGHT)
    share = math.min(math.max(share, 0), 1)
    return F.PRESS_MIN_HOURS + share * (F.PRESS_HOURS - F.PRESS_MIN_HOURS)
end

-- Hours in the tub for a batch of meat whose heaviest cut weighs this much.
function F.meatPressHours(heaviest)
    return math.min(math.max(F.PRESS_HOURS * heaviest / F.MEAT_PRESS_WEIGHT, F.PRESS_MIN_HOURS), F.PRESS_HOURS)
end

-- The press runs on the plain game clock (no weather), timed from here. The inputs are already
-- taken in, so the batch's heaviest fish or cut sets its hours.
function F.onPressStart(craftRecipeData)
    Weather.startClock(craftRecipeData, "pressStartHour", getGameTime():getWorldAgeHours())
    craftRecipeData:getModData().lastWarmCure = F.getLedger().warmCure
    craftRecipeData:getModData().lastLongCure = nil
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local heaviest, meat, leg = 0, false, false
    for i = 0, fish:size() - 1 do
        heaviest = math.max(heaviest, fish:get(i):getActualWeight())
        meat = meat or fish:get(i):getFullType() == F.PACKED_MEAT
        leg = leg or F.isLeg(fish:get(i))
    end
    local hours = meat and F.meatPressHours(heaviest) or F.pressHours(heaviest)
    -- The engine gives the recipe's full name, module and all.
    local recipeName = string.gsub(craftRecipeData:getRecipe():getName(), "^.*%.", "")
    if recipeName == F.LONG_CURE_RECIPE then
        hours = F.longCureHours(leg)
        craftRecipeData:getModData().lastLongCure = F.getLedger().longCureSpoil
    end
    craftRecipeData:getModData().pressHours = hours
end

-- Hours of the long cure: a leg's if the batch has one.
function F.longCureHours(leg)
    return leg and F.LONG_LEG_HOURS or F.LONG_CUT_HOURS
end

-- A Leg of Pork, raw or at any stage.
function F.isLeg(item)
    if item:getFullType() == F.LEG_OF_PORK then return true end
    return F.isMeatStage(item:getFullType()) and item:getModelIndex() == F.LEG_INDEX
end

-- Pork or a leg at any meat stage, by its model index.
function F.isPork(item)
    return F.isMeatStage(item:getFullType()) and F.PORK_INDICES[item:getModelIndex()] == true
end

-- OnTest of the short cure: a leg is too thick for it, and takes the long cure only.
function F.canCorn(item)
    return not F.isLeg(item)
end

-- The long cure's OnCreate: as the short one's, and each piece is marked Country Cured.
function F.onCreateLongCured(craftRecipeData)
    F.onCreatePressed(craftRecipeData)
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        created:get(i):getModData().longCure = true
        F.rename(created:get(i))
    end
end

-- The share of its keeping a batch has lost to a warm cure so far. A press started before this counts from now.
function F.cureSpoiled(modData, ledger)
    local warm = ledger.warmCure - (modData.lastWarmCure or ledger.warmCure)
    -- A long cure (lastLongCure is set at its start) also minds a season over LONG_CURE_ABOVE.
    local long = modData.lastLongCure and (ledger.longCureSpoil or 0) - modData.lastLongCure or 0
    return math.min(warm * F.WARM_CURE_SHARE / F.RAW_SPOIL_HOURS + long, 1)
end

-- How far a batch in the tub is, for its popup.
function F.pressStatus(modData, now, ledger)
    local hours = modData.pressHours or OLD_PRESS_HOURS
    local done = math.max(now - (modData.pressStartHour or now), 0)
    return { progress = math.min(done / hours, 1), hoursLeft = math.max(hours - done, 0),
        spoiled = F.cureSpoiled(modData, ledger),
        spoiling = ledger.warmCuring == true or modData.lastLongCure ~= nil and ledger.longCuring == true }
end

-- Craft timers tick at a fixed speed whatever Day Length says and stop when the area unloads,
-- so this replaces their count with the game clock. The recipe's time is the longest press (the long cure's: a
-- leg's 21 days), so a lighter batch's bar runs faster to end on its own hours.
function F.onPressUpdate(craftRecipeData)
    local hours = craftRecipeData:getModData().pressHours or OLD_PRESS_HOURS
    local recipeHours = craftRecipeData:getRecipe():getTime() / SECONDS_PER_HOUR
    Weather.showClock(craftRecipeData, "pressStartHour", getGameTime():getWorldAgeHours(), recipeHours / hours)
end

-- A tub salts fish or meat, one batch at a time: what is waiting in it already sets the kind.
function F.mixedTub(waitingType, fullType)
    if waitingType and waitingType ~= fullType then return "IGUI_TraditionalPreservationFishMeat_MixedTub" end
    return nil
end

function F.hasRoom(capacity, storedWeight, weight)
    return storedWeight + weight <= capacity
end

-- Vanilla slots take any item and leave Craft greyed out, so each station names its fish.
function F.fishRefusal(isTub, fullType)
    if isTub and fullType ~= F.PACKED_FISH and fullType ~= F.PACKED_MEAT then return "IGUI_TraditionalPreservationFishMeat_NeedsPacked" end
    if not isTub and fullType ~= "TraditionalPreservationFishMeat.SaltPressedFish" and not F.COLD_FISH[fullType] and fullType ~= F.CURED_MEAT then
        return "IGUI_TraditionalPreservationFishMeat_NeedsPressed"
    end
    if fullType == F.PACKED_MEAT or fullType == F.CURED_MEAT then
        if not F.CHARQUE_ON then return "IGUI_TraditionalPreservationFishMeat_CharqueOff" end
    end
    return nil
end

-- Meat a drying station refuses, by where it stands (Weather.placeOf with Covered). The Smokehouse (closed) takes
-- all. Country Cured meat, pork too, dry cures in the shade: a Frame, Beam or Gantry under a roof, a Frame or Beam
-- indoors or in a basement, never in the open (sun and rain are charque's). Corned pork has only its hot cook: in
-- sun and wind its fat goes rancid, and it has too little salt to hang.
function F.meatRefusal(hanger, place, item)
    if hanger.closed then return nil end
    if item:getFullType() == F.CURED_MEAT and item:getModData().longCure then
        if place == "Open" then return "IGUI_TraditionalPreservationFishMeat_CountryCuredSmokehouse" end
        return nil
    end
    if F.isPork(item) then return "IGUI_TraditionalPreservationFishMeat_PorkSmokehouse" end
    return nil
end

-- Why an item can't go in a tub set to this recipe (Core's recipeRefusal): a Leg of Pork is too thick to corn.
function F.recipeRefusal(recipeName, item)
    if recipeName == "PressSaltedMeat" and F.isLeg(item) then return "IGUI_TraditionalPreservationFishMeat_LegNeedsLongCure" end
    return nil
end

-- What hangs in a stack: "salt" fish, "cold" fish or "meat". One stack is one kind.
function F.hangKind(fullType)
    if F.COLD_FISH[fullType] then return "cold" end
    if fullType == F.CURED_MEAT then return "meat" end
    return "salt"
end

-- A tileset can't hold more than 512 tiles, so everything from FIRST_SHEET_SIZE on is in a second
-- one. Sprites are numbered straight through both.
F.FIRST_SHEET_SIZE = Tiles.FIRST_SHEET_SIZE

function F.spriteName(index)
    if index < F.FIRST_SHEET_SIZE then return Tiles.SHEETS[1].prefix .. index end
    return Tiles.SHEETS[2].prefix .. (index - F.FIRST_SHEET_SIZE)
end

-- The number of one of this mod's sprites, or nil for any other.
function F.spriteIndex(name)
    local sheet, index = string.match(name or "", "^traditionalpreservationfishmeat_0([12])_(%d+)$")
    if not sheet then return nil end
    return tonumber(index) + (sheet == "2" and F.FIRST_SHEET_SIZE or 0)
end

-- The number of a station's own sprite, or nil for anything that isn't one of this mod's stations. A table
-- lookup: the slot rules ask this of every crafting station's slot.
local STATION_INDEX = {}
for _, name in ipairs(Tiles.STATIONS) do STATION_INDEX[name] = F.spriteIndex(name) end

function F.stationIndex(object)
    local sprite = object and object:getSprite()
    local name = sprite and sprite:getName()
    return name and STATION_INDEX[name]
end

-- The Gantry and the Smokehouse stand in the open or under an open roof, not in a room, unlike the frame and (since
-- 0.4.15) the Hanging Beam; and not in front of a door (TP Core's Doors: the Hearth's mouth, the Firebox's door, the
-- Smokehouse's), with the Smokehouse's own door's front free. The Hanging Beam only minds the doors (F.doorFree).
function F.doorFree(params)
    local name = params.tileInfo and params.tileInfo:getSpriteName()
    return Doors.fits(params.square, name)
end

function F.notInRoom(params)
    local name = params.tileInfo and params.tileInfo:getSpriteName()
    return not params.square:isInARoom() and Doors.fits(params.square, name)
end

-- The hanger a station's sprite belongs to, whichever way it faces (and either tile of the chamber), or nil for a tub.
function F.hangerFor(spriteIndex)
    return F.HANGERS[spriteIndex - spriteIndex % 2]
end

-- Why a fish can't join the stack waiting on a frame, as a translation key, or nil if it can.
-- busyStacks is what is already hanging: running stacks and finished ones not yet taken. waitingPieces is how many
-- pieces already wait in the stack (nil counts as none).
function F.frameRefusal(hanger, busyStacks, waitingWeight, weight, waitingPieces)
    if busyStacks >= hanger.stacks then return "IGUI_TraditionalPreservationFishMeat_FrameFull" end
    if weight > hanger.stackWeight then return "IGUI_TraditionalPreservationFishMeat_TooHeavy" end
    if (waitingPieces or 0) >= hanger.stackPieces
            or not F.hasRoom(hanger.stackWeight, waitingWeight, weight) then
        return "IGUI_TraditionalPreservationFishMeat_StackFull"
    end
    return nil
end

-- Cold drying needs moving air: a room, a basement or the Smokehouse (place is Weather.placeOf's, with Covered)
-- refuses gutted fish. The Smokehouse doesn't list the recipe either.
function F.coldRefusal(place)
    if place ~= "Open" and place ~= "Covered" then return "IGUI_TraditionalPreservationFishMeat_NoColdIndoors" end
    return nil
end

-- The recipe tag the Smokehouse lists: its own, without cold drying. A shed keeps the tag it was built with in the
-- save, so one from before the tag gets it when it is first seen.
F.SMOKEHOUSE_RECIPES = "Smokehouse"

-- A random hanging look for a new stack, kept in its modData so it doesn't change.
function F.pickStyle(styles)
    return styles[ZombRand(#styles) + 1]
end

-- The style to show for an item: its stack's, or for fish still waiting, what it is.
function F.fishStyle(item)
    local style = item:getModData().style
    if style then return style end
    local fullType = item:getFullType()
    if fullType == "TraditionalPreservationFishMeat.FishHalf" then return F.STYLE_HALF end
    if fullType == "TraditionalPreservationFishMeat.GuttedFish" or fullType == "TraditionalPreservationFishMeat.ColdDriedFish" then return F.STYLE_GUTTED end
    if fullType == F.CURED_MEAT or fullType == "TraditionalPreservationFishMeat.Charque" then return F.STYLE_MEAT end
    return F.STYLE_SALT
end

-- The look for a fish still drying. The last stage is kept for fish that have finished.
function F.dryingStage(progress)
    local running = F.DRYING_STAGES - 1
    return math.min(math.floor(progress * running), running - 1)
end

-- What a warm cure took from a stack's fish, by weight.
function F.stackCureSpoiled(fish)
    local weight, spoiled = 0, 0
    for i = 0, fish:size() - 1 do
        local item = fish:get(i)
        weight = weight + item:getActualWeight()
        spoiled = spoiled + item:getActualWeight() * (item:getModData().cureSpoiled or 0)
    end
    return weight > 0 and spoiled / weight or 0
end

local function startStack(craftRecipeData)
    local ledger = F.getLedger()
    local modData = craftRecipeData:getModData()
    modData.dried = 0
    modData.spoiled = F.stackCureSpoiled(craftRecipeData:getAllInputItemsWithFlag("ItemCount"))
    modData.stackId = getGameTime():getWorldAgeHours()
    modData.lastOpen = ledger.open
    modData.lastSheltered = ledger.sheltered
    modData.lastCovered = ledger.covered
    modData.lastCold = ledger.cold
    modData.lastColdCovered = ledger.coldCovered
    modData.lastRawSpoil = ledger.rawSpoil
    modData.lastSaltSpoil = ledger.saltSpoil
    modData.lastHardFrost = ledger.hardFrost
    modData.lastColdWet = ledger.coldWet
    modData.lastHeat = ledger.heat
    modData.lastCharque = ledger.charque
    modData.lastCharqueCovered = ledger.charqueCovered
    modData.lastCharqueSheltered = ledger.charqueSheltered
    modData.lastCharqueRain = ledger.charqueRain
    modData.lastDryCure, modData.lastUnderCure = ledger.dryCure, ledger.underCure
    modData.lastCureBasement, modData.lastUnderBasement = ledger.dryCureBasement, ledger.underCureBasement
    modData.basement, modData.longStack = nil, nil
    modData.sheltered = nil
    modData.covered = nil
    -- Recipe data is pooled with its ModData (ENGINE_NOTES): a stack mustn't inherit an old one's shed or smoke.
    modData.inShed, modData.burning, modData.hotNeed, modData.heaviest = nil, nil, nil, nil
    modData.lastClock, modData.lastSmokeCool, modData.lastDraughtCovered, modData.lastDraughtSheltered = nil, nil, nil, nil
    modData.lastDraughtBanked, modData.lastDraughtStoked = nil, nil
    modData.cureNeed, modData.noHot, modData.underCured, modData.underSpoiled, modData.allUnder = nil, nil, nil, nil, nil
    modData.smokeNeed = nil
    modData.lastUnderBase, modData.lastUnderBanked, modData.lastUnderStoked = nil, nil, nil
end

-- Shows a stack's progress, and ends it early if it has rotted or its hot smoking is done (the Smokehouse). A stack
-- in a Smokehouse waits at the end until the World has seen its shed since the load, so OnCreate can swap in Cold
-- Smoked outputs (F.smokeStations).
-- How far a stack's hot cook has come in the stoked run now counting, 0 to 1; nil with no run counting (not in a
-- joined Smokehouse, the fire banked or out over an hour, or a leg in the stack). A broken run takes it back to nil.
function F.cookShare(modData)
    if not modData.hotNeed or modData.noHot or (modData.hot or 0) <= 0 then return nil end
    return math.min(modData.hot / modData.hotNeed, 1)
end

-- The stack's bar: how far it has dried, or its hot cook while that is further along (a run that breaks off drops
-- it back to the drying). The cook itself ends the stack only through the World (F.hotStations).
function F.stackProgress(modData, hours)
    local progress = math.min(modData.dried / hours, 1)
    local cook = F.cookShare(modData)
    if cook and cook > progress then progress = math.min(cook, F.SHED_WAIT) end
    return progress
end

local function showProgress(craftRecipeData, modData, hours)
    local time = craftRecipeData:getRecipe():getTime()
    -- Under-salting ends a stack only when every piece in it is Corned: Country Cured pieces dry on.
    local rotten = modData.spoiled + (modData.allUnder and modData.underSpoiled or 0) >= 1
    local progress = (rotten or F.hotStations[modData.stackId]) and 1 or F.stackProgress(modData, hours)
    if progress >= 1 and modData.inShed and not F.smokeStations[modData.stackId] then progress = F.SHED_WAIT end
    -- A dry-curing stack on a frame waits for the World too, which swaps its Charque for dry-cured meat.
    if progress >= 1 and not modData.inShed and F.dryCuring(modData) and not F.stackStations[modData.stackId] then progress = F.SHED_WAIT end
    craftRecipeData:setElapsedTime(progress * time)
end

-- OnStart for salted fish on a frame: marks the ledger and picks a look.
function F.onDryStart(craftRecipeData)
    startStack(craftRecipeData)
    F.startSmoke(craftRecipeData:getModData(), craftRecipeData:getAllInputItemsWithFlag("ItemCount"), false)
    craftRecipeData:getModData().style = F.pickStyle(F.SALT_STYLES)
end

-- Adds what the weather has done to a salt stack since it was last looked at. It goes by the frame's
-- place now, so a roof built over a running frame counts from then on. Heat in open sun harms a stack
-- under SALT_FRESH_UNTIL dried, weighed by how wet it still is, as cold frames weigh frost.
function F.saltStep(modData, ledger)
    -- Stacks from before spoilage, the covered total and heat have no starting point, so they count from now.
    local heat = ledger.heat - (modData.lastHeat or ledger.heat)
    local exposed = not modData.sheltered and not modData.covered
    local vulnerability = 1 - math.min(modData.dried / F.DRY_HOURS, 1)
    local damage = 0
    if exposed and vulnerability > 1 - F.SALT_FRESH_UNTIL then
        damage = heat / F.HEAT_DAMAGE_HOURS * F.HEAT_DAMAGE * vulnerability
    end
    if modData.sheltered then
        modData.dried = modData.dried + ledger.sheltered - modData.lastSheltered
    elseif modData.covered then
        modData.dried = modData.dried + ledger.covered - (modData.lastCovered or ledger.covered)
    else
        modData.dried = modData.dried + ledger.open - modData.lastOpen
    end
    local spoiled = (modData.spoiled or 0) + (ledger.saltSpoil - (modData.lastSaltSpoil or ledger.saltSpoil)) / F.SALT_SPOIL_HOURS
    if damage > 0 and spoiled < F.DAMAGE_CAP then spoiled = math.min(spoiled + damage, F.DAMAGE_CAP) end
    modData.spoiled = spoiled
    modData.lastOpen = ledger.open
    modData.lastSheltered = ledger.sheltered
    modData.lastCovered = ledger.covered
    modData.lastSaltSpoil = ledger.saltSpoil
    modData.lastHeat = ledger.heat
end

function F.onDryUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.saltStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.DRY_HOURS)
end

-- OnStart for unsalted fish on a cold frame.
function F.onColdDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = F.pickStyle(F.COLD_STYLES)
end

-- Adds what the weather has done to a cold stack since it was last looked at. Indoors the air is
-- still, so unsalted fish doesn't dry there; it can still spoil. An open shed's roof keeps the rain
-- off and some of the wind. Rot, early hard frost and wet weigh
-- by how wet the fish still is, taken at this update (a stack catching up after its chunk was
-- unloaded uses its progress from then).
function F.coldStep(modData, ledger)
    local vulnerability = 1 - math.min(modData.dried / F.COLD_DRY_HOURS, 1)
    -- A stack from before the frost and wet totals has no starting point, so it counts from now.
    local frost = ledger.hardFrost - (modData.lastHardFrost or ledger.hardFrost)
    local wet = ledger.coldWet - (modData.lastColdWet or ledger.coldWet)
    local damage = 0
    if vulnerability > 1 - F.FRESH_UNTIL then
        damage = frost / F.FREEZE_DAMAGE_HOURS * F.FREEZE_DAMAGE
        if not modData.sheltered and not modData.covered then damage = damage + wet / F.WET_DAMAGE_HOURS * F.WET_DAMAGE end
    end
    if modData.covered then
        modData.dried = modData.dried + ledger.coldCovered - (modData.lastColdCovered or ledger.coldCovered)
    elseif not modData.sheltered then
        modData.dried = modData.dried + ledger.cold - modData.lastCold
    end
    local spoiled = modData.spoiled + (ledger.rawSpoil - modData.lastRawSpoil) / F.RAW_SPOIL_HOURS * vulnerability
    if spoiled < F.DAMAGE_CAP then spoiled = math.min(spoiled + damage * vulnerability, F.DAMAGE_CAP) end
    modData.spoiled = spoiled
    modData.lastCold = ledger.cold
    modData.lastColdCovered = ledger.coldCovered
    modData.lastRawSpoil = ledger.rawSpoil
    modData.lastHardFrost = ledger.hardFrost
    modData.lastColdWet = ledger.coldWet
end

function F.onColdDryUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.coldStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.COLD_DRY_HOURS)
end

-- Whether a stack of meat dry cures: any in a Smokehouse (the World marks it) or in a room or a basement (sheltered:
-- charque is the sun's, so Corned meat indoors is under-salted meat drying, as in the shed), and under an open roof
-- one with Country Cured meat in it (longStack, from F.startSmoke). Then the hours at a rate of 1 a stack of meat
-- needs.
function F.dryCuring(modData)
    return (modData.inShed == true or modData.longStack == true or modData.sheltered == true) and modData.cureNeed ~= nil
end

function F.meatHours(modData)
    return F.dryCuring(modData) and modData.cureNeed or F.CHARQUE_HOURS
end

-- OnStart for Salt Cured meat on a frame (charque) or in the Smokehouse (dry curing).
function F.onCharqueStart(craftRecipeData)
    startStack(craftRecipeData)
    F.startSmoke(craftRecipeData:getModData(), craftRecipeData:getAllInputItemsWithFlag("ItemCount"), true)
    craftRecipeData:getModData().style = F.STYLE_MEAT
end

-- Where a dry-curing stack hangs: "Shed", "Basement", "Shade" (a Frame or Beam under a roof or indoors) or "Open"
-- (its roof is gone: it waits).
function F.curePlace(modData)
    if modData.inShed then return "Shed" end
    if modData.basement then return "Basement" end
    return (modData.sheltered or modData.covered) and "Shade" or "Open"
end

-- Meat in the Smokehouse dry cures (6b): the shed's cool-air drying with the fire out (F.smokeStep adds the fire's
-- hours), and for Corned meat the spoiling of the under-salted. The same under a roof; a basement has its own steady
-- totals; in the open nothing dries.
local function dryCureStep(modData, ledger)
    local place = F.curePlace(modData)
    local dried = ledger.dryCure - (modData.lastDryCure or ledger.dryCure)
    local under = ledger.underCure - (modData.lastUnderCure or ledger.underCure)
    if place == "Basement" then
        dried = (ledger.dryCureBasement or 0) - (modData.lastCureBasement or ledger.dryCureBasement or 0)
        under = (ledger.underCureBasement or 0) - (modData.lastUnderBasement or ledger.underCureBasement or 0)
    elseif place == "Open" then
        dried = 0
    end
    modData.dried = modData.dried + dried
    if modData.underCured then modData.underSpoiled = (modData.underSpoiled or 0) + under end
    modData.lastDryCure, modData.lastUnderCure = ledger.dryCure, ledger.underCure
    modData.lastCureBasement, modData.lastUnderBasement = ledger.dryCureBasement, ledger.underCureBasement
end

-- Adds what the weather has done to a charque stack since it was last looked at, by the frame's place now. Rain on
-- an open frame takes back a share of what it had first; it doesn't dry while wet anyway.
function F.charqueStep(modData, ledger)
    local rain = ledger.charqueRain - (modData.lastCharqueRain or ledger.charqueRain)
    if F.dryCuring(modData) then
        dryCureStep(modData, ledger)
    elseif modData.sheltered then
        modData.dried = modData.dried + ledger.charqueSheltered - modData.lastCharqueSheltered
    elseif modData.covered then
        modData.dried = modData.dried + ledger.charqueCovered - modData.lastCharqueCovered
    else
        if rain > 0 then modData.dried = modData.dried * (1 - F.CHARQUE_REWET) ^ (rain / F.CHARQUE_RAIN_HOURS) end
        modData.dried = modData.dried + ledger.charque - modData.lastCharque
    end
    modData.spoiled = (modData.spoiled or 0) + (ledger.saltSpoil - modData.lastSaltSpoil) / F.SALT_SPOIL_HOURS
    modData.lastCharque = ledger.charque
    modData.lastCharqueCovered = ledger.charqueCovered
    modData.lastCharqueSheltered = ledger.charqueSheltered
    modData.lastCharqueRain = ledger.charqueRain
    modData.lastSaltSpoil = ledger.saltSpoil
end

function F.onCharqueUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.charqueStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.meatHours(modData))
end

-- A fish from another mod isn't in the list, and keeps the stage's own icon.
function F.iconIndex(source)
    local fullType = source:getFullType()
    -- Stages after these list their icons three times over: whole, gutted, then half.
    if fullType == "TraditionalPreservationFishMeat.GuttedFish" then return source:getModelIndex() + #F.FISH_ICONS end
    if fullType == "TraditionalPreservationFishMeat.FishHalf" then return source:getModelIndex() + #F.FISH_ICONS * 2 end
    if source:getModelIndex() >= 0 then return source:getModelIndex() end
    for index, fishType in ipairs(F.FISH_ICONS) do
        if fishType == fullType then return index - 1 end
    end
    for index, cutType in ipairs(F.MEAT_CUTS) do
        if cutType == fullType then return index - 1 end
    end
    return -1
end

-- Whether vanilla could cut this fish, which is what gives guts.
function F.hasGuts(fish)
    return fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
        and fish:getActualWeight() > F.MIN_SLICE_WEIGHT
end

-- Whether gutting this fish gives a Fish Head.
function F.hasHead(fish)
    return F.hasGuts(fish) and fish:getActualWeight() > F.HEAD_MIN_WEIGHT
end

-- A fillet vanilla cut counts as the food it holds; anything else, a loot fillet included, as what it weighs.
function F.foodWeight(fish)
    if fish:getFullType() == "Base.FishFillet" and fish:isCustomWeight() then
        return fish:getActualWeight() * F.FILLET_FOOD_WEIGHT
    end
    return fish:getActualWeight()
end

-- What a fish weighs once packed: gutted if it has guts, and a fillet by its food.
function F.packedWeight(fish)
    if F.hasGuts(fish) then return fish:getActualWeight() * (1 - F.GUTS_WEIGHT) end
    return F.foodWeight(fish)
end

-- The salt packing this fish takes in all, the recipe's own SALT_MIN included.
function F.saltFor(fish)
    local steps = math.floor(F.packedWeight(fish) / F.SALT_STEP + 0.5 + 1e-6)
    local perStep = fish:getFullType() == F.LEG_OF_PORK and F.LEG_SALT_PER_STEP or F.SALT_PER_STEP
    return math.max(F.SALT_MIN, perStep * steps)
end

-- A whole or gutted fish over SALT_WHOLE_MAX, which has to be split before it goes in the salt.
function F.tooBigToSaltWhole(fish)
    local whole = fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
    local gutted = fish:getFullType() == "TraditionalPreservationFishMeat.GuttedFish"
    return (whole or gutted) and fish:getActualWeight() > F.SALT_WHOLE_MAX
end

-- The salt the character carries, bags included, with uses left.
local function saltCarried(character)
    local found = character:getInventory():getAllTagRecurse(ItemTag.SALT, ArrayList.new())
    local salt = {}
    for i = 0, found:size() - 1 do
        local item = found:get(i)
        if item:getCurrentUses() > 0 then table.insert(salt, item) end
    end
    return salt
end

function F.saltCarried(character)
    local uses = 0
    for _, item in ipairs(saltCarried(character)) do uses = uses + item:getCurrentUses() end
    return uses
end

function F.isMeatCut(fullType)
    for _, cut in ipairs(F.MEAT_CUTS) do
        if cut == fullType then return true end
    end
    return false
end

-- OnTest sees every input, so the knife and the salt pass here too. The recipe finds its first SALT_MIN
-- anywhere in reach; the rest must be on you.
function F.canPack(item, character)
    if item:hasTag(ItemTag.SALT) or not instanceof(item, "Food") then return true end
    if F.tooBigToSaltWhole(item) then return false end
    if not F.CHARQUE_ON and F.isMeatCut(item:getFullType()) then return false end
    if not character then return true end
    return F.saltCarried(character) >= F.saltFor(item)
end

-- Uses up the salt this fish takes past the recipe's own, part-used salt first. The Salt mod gives an empty
-- shaker or paper bag for what this empties, as it does for what the recipe empties.
function F.chargeSalt(fish, character)
    local owed = F.saltFor(fish) - F.SALT_MIN
    if owed <= 0 or not character then return end
    local salt = saltCarried(character)
    table.sort(salt, function(a, b) return a:getCurrentUses() < b:getCurrentUses() end)
    local emptied = ArrayList.new()
    for _, item in ipairs(salt) do
        if owed <= 0 then break end
        local uses = item:getCurrentUses()
        local taken = math.min(uses, owed)
        owed = owed - taken
        item:setCurrentUses(uses - taken)
        if taken == uses then
            item:getContainer():DoRemoveItem(item)
            emptied:add(item)
        end
    end
    local Salt = TraditionalPreservationSalt
    if Salt and Salt.returnEmpties and emptied:size() > 0 then Salt.returnEmpties(character, emptied) end
end

-- Hands a share of a fish's food to another item; hungerShare defaults to share.
-- Eating lowers HungChange and leaves BaseHunger, so a part-eaten fish stays part-eaten.
local function copyFood(from, to, share, hungerShare)
    hungerShare = hungerShare or share
    to:setCalories(from:getCalories() * share)
    to:setProteins(from:getProteins() * share)
    to:setLipids(from:getLipids() * share)
    to:setCarbohydrates(from:getCarbohydrates() * share)
    to:setBaseHunger(from:getBaseHunger() * hungerShare)
    to:setHungChange(from:getHungChange() * hungerShare)
end

F.copyFood = copyFood

-- Gives the next stage of a fish its share of the last stage's food, less the head if this stage takes it off.
function F.carry(source, target)
    local stage = F.STAGES[target:getFullType()]
    local headless = stage.headless and F.hasHead(source)
    -- The head takes its share of the food with it.
    local kept = headless and 1 - F.HEAD_FOOD or 1
    copyFood(source, target, stage.nutrition * kept, stage.hunger * kept)
    local keptWeight = stage.maxWeight and ZombRandFloat(stage.weight, stage.maxWeight) or stage.weight
    local cut = 0
    if stage.gutted and F.hasGuts(source) then cut = F.GUTS_WEIGHT end
    if headless then cut = cut + F.HEAD_WEIGHT end
    keptWeight = keptWeight * (1 - cut)
    target:setActualWeight(F.foodWeight(source) * keptWeight)
    target:setCustomWeight(true)

    -- The display name has the fish's size, as in Small Black Crappie, and a trailing space from vanilla.
    -- A stage item that never had a species (one spawned in) keeps its plain name, so a Salt Dried
    -- Fish doesn't become a Rehydrated Salt Dried Salt Dried Fish.
    local sourceData, targetData = source:getModData(), target:getModData()
    local fishName = sourceData.fishName
    if not fishName and not F.STAGES[source:getFullType()] then
        fishName = string.gsub(source:getDisplayName(), "%s+$", "")
    end
    if fishName then targetData.fishName = fishName end

    if sourceData.fishName then
        targetData.sliceable = sourceData.sliceable
    else
        targetData.sliceable = not F.UNSLICEABLE[source:getFullType()] and source:getActualWeight() > F.MIN_SLICE_WEIGHT
    end

    if sourceData.rinsed then
        targetData.rinsed = true
        F.applyRinse(target)
    end

    -- After the icon, which tells whether the fish was gutted.
    target:setModelIndex(F.iconIndex(source))
    F.rename(target)
end

-- Salt Cured fish, and Salt Cured meat as the charqueadas washed it before the sun.
F.RINSE_TYPES = { ["TraditionalPreservationFishMeat.SaltPressedFish"] = true, [F.CURED_MEAT] = true }

-- Only Salt Cured fish or meat not rinsed yet: a dried one has lost the water that lets the salt out.
function F.canRinse(item)
    return F.RINSE_TYPES[item:getFullType()] == true and not item:getModData().rinsed
end

-- What rinsing does to a salty stage, from its script values: less thirst, a little less keeping. A stage
-- made from a rinsed fish gets it again, as its values come fresh from its own script.
function F.applyRinse(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage or not stage.salty then return end
    item:setThirstChange(item:getThirstChange() * F.RINSED_THIRST)
    if stage.rinsedUnhappy then item:setUnhappyChange(stage.rinsedUnhappy) end
    item:setOffAge(math.floor(item:getOffAge() * F.RINSED_KEEPING + 0.5))
    item:setOffAgeMax(math.floor(item:getOffAgeMax() * F.RINSED_KEEPING + 0.5))
end

function F.rinse(item)
    if not F.canRinse(item) then return false end
    item:getModData().rinsed = true
    F.applyRinse(item)
    F.rename(item)
    return true
end

-- The Rinse recipe's OnTest, which runs for every input: only the fish is checked.
function F.canRinseInput(item)
    if not F.RINSE_TYPES[item:getFullType()] then return true end
    return F.canRinse(item)
end

-- The Rinse recipe gives back the same fish, so each one hands over everything it is, then is rinsed.
function F.onCreateRinsed(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        local source, target = fish:get(i), created:get(i)
        copyFood(source, target, 1)
        target:setActualWeight(source:getActualWeight())
        target:setCustomWeight(true)
        local targetData = target:getModData()
        for key, value in pairs(source:getModData()) do targetData[key] = value end
        target:setModelIndex(source:getModelIndex())
        F.rinse(target)
        target:setAge(source:getAge())
    end
end

-- How much faster a pallet ripens stockfish than a shelf: place is Weather.placeOf's (with Covered), z the floor.
function F.palletSpeed(place, z)
    if place ~= "Sheltered" then return 1 end
    if z >= 1 then return F.PALLET_LOFT end
    return F.PALLET_GROUND
end

function F.isStockfish(item)
    local stage = F.STAGES[item:getFullType()]
    return stage ~= nil and stage.matures == true
end

-- Calls fn on each stockfish in the container, and in the bales in it.
function F.eachStockfish(container, fn)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if F.isStockfish(item) then
            fn(item)
        elseif item:getFullType() == F.BALE_TYPE and item:getInventory() then
            F.eachStockfish(item:getInventory(), fn)
        end
    end
end

-- The stack to show, 1 to PALLET_LEVELS by the share of the pallet filled, or nil when it is empty or holds
-- anything but stockfish and bales of it.
function F.palletLevel(container)
    local items = container:getItems()
    if items:size() == 0 then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if not F.isStockfish(item) then
            if item:getFullType() ~= F.BALE_TYPE then return nil end
            local inside = item:getInventory():getItems()
            for j = 0, inside:size() - 1 do
                if not F.isStockfish(inside:get(j)) then return nil end
            end
        end
    end
    local share = container:getContentsWeight() / F.PALLET_CAPACITY
    return math.max(1, math.min(F.PALLET_LEVELS, math.ceil(share * F.PALLET_LEVELS - 0.0001)))
end

-- Ripens the stockfish on a pallet by extra days of its food clock, by moving its stamp back. A ripe fish stays ripe.
function F.ripenOnPallet(container, extraDays)
    if extraDays <= 0 then return end
    F.eachStockfish(container, function(fish)
        local modData = fish:getModData()
        if modData.matureAge and F.ripeness(fish) < 1 then
            modData.matureAge = modData.matureAge - extraDays
            F.rename(fish)
        end
    end)
end

-- The bale's AcceptItemFunction: only stockfish goes in.
function F.acceptBale(container, item)
    return F.isStockfish(item)
end

-- The cord a bale is tied with: Twine with a use left first, as it is the lighter, then a Rope.
-- Returns the item and its BALE_CORDS entry, or nil.
function F.findCord(inventory)
    for _, cord in ipairs(F.BALE_CORDS) do
        local found = inventory:getFirstEvalRecurse(function(item)
            return item:getFullType() == cord.type and (not cord.uses or item:getCurrentUses() >= cord.uses)
        end)
        if found then return found, cord end
    end
    return nil
end

function F.cordByKey(key)
    for _, cord in ipairs(F.BALE_CORDS) do
        if cord.key == key then return cord end
    end
    return nil
end

-- The stockfish that fit in one bale, in the order given, up to BALE_CAPACITY weight; the rest stay out.
function F.baleLoad(fish)
    local load, weight = {}, 0
    for _, item in ipairs(fish) do
        if F.isStockfish(item) and weight + item:getActualWeight() <= F.BALE_CAPACITY + 0.0001 then
            table.insert(load, item)
            weight = weight + item:getActualWeight()
        end
    end
    return load
end

-- Ties the fish (all in the inventory) into a new bale with the cord, which is used up. Returns the bale.
function F.tieBale(inventory, fish, cordItem, cord)
    local bale = inventory:AddItem(F.BALE_TYPE)
    bale:getModData().cord = cord.key
    bale:setCustomWeight(true)
    bale:setActualWeight(cord.weight)
    local inside = bale:getInventory()
    for _, item in ipairs(fish) do
        inventory:Remove(item)
        inside:AddItem(item)
    end
    if cord.uses then
        for _ = 1, cord.uses do cordItem:UseAndSync() end
    else
        cordItem:getContainer():Remove(cordItem)
    end
    return bale
end

-- Unties a bale in the inventory: its fish and the cord that tied it go into the inventory, the bale is gone.
-- A bale from before the cord was recorded gives back Twine.
function F.untieBale(inventory, bale)
    local items = bale:getInventory():getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        bale:getInventory():Remove(item)
        inventory:AddItem(item)
    end
    local cord = F.cordByKey(bale:getModData().cord) or F.BALE_CORDS[1]
    local given = inventory:AddItem(cord.type)
    if cord.uses then given:setCurrentUses(cord.uses) end
    bale:getContainer():Remove(bale)
end

-- The nearest sink, bathtub, barrel or well of clean water within RINSE_REACH on the character's floor with at least litres.
function F.findWaterSource(character, litres)
    local cell, px, py, z = getCell(), math.floor(character:getX()), math.floor(character:getY()), math.floor(character:getZ())
    local best, bestDistance
    for x = px - F.RINSE_REACH, px + F.RINSE_REACH do
        for y = py - F.RINSE_REACH, py + F.RINSE_REACH do
            local square = cell:getGridSquare(x, y, z)
            local objects = square and square:getObjects()
            for i = 0, objects and objects:size() - 1 or -1 do
                local object = objects:get(i)
                if object:hasWater() and not object:isTaintedWater() and object:getFluidAmount() >= litres then
                    local distance = (x - px) ^ 2 + (y - py) ^ 2
                    if not best or distance < bestDistance then best, bestDistance = object, distance end
                end
            end
        end
    end
    return best
end

-- How far a stockfish has matured, 0 to 1, by the days on its own food clock since it came off the frame.
-- One made before maturing existed (no stamp) counts as ripe; a rehydrated one keeps what it had.
function F.ripeness(item)
    local modData = item:getModData()
    if F.STAGES[item:getFullType()].ripened then return modData.ripeness end
    if not modData.matureAge then return 1 end
    return math.max(0, math.min((item:getAge() - modData.matureAge) / F.MATURE_DAYS, 1))
end

-- The days a piece of dry-cured meat takes to age, nil for anything that doesn't.
function F.ageDays(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage or not stage.ages then return nil end
    return stage.ham and F.AGE_HAM_DAYS or F.AGE_CUT_DAYS
end

-- How far a piece of dry-cured meat has aged, 0 to 1, by the days on its food clock since it dried (agedFrom; one
-- from before 6c counts all its days). Once Aged it stays so.
function F.agedness(item)
    local days = F.ageDays(item)
    if not days then return 0 end
    local modData = item:getModData()
    if modData.aged then return 1 end
    return math.max(0, math.min((item:getAge() - (modData.agedFrom or 0)) / days, 1))
end

-- The share of a food item not yet eaten or carved off: both lower HungChange and leave BaseHunger.
function F.shareLeft(item)
    local base = item:getBaseHunger()
    if not base or base == 0 then return 1 end
    return math.max(0, math.min(item:getHungChange() / base, 1))
end

-- Marks a piece Aged the first time it is seen so, and gives what is left of it the aged meat's mood.
function F.applyAged(item)
    local modData = item:getModData()
    if modData.aged or F.agedness(item) < 1 then return end
    modData.aged = true
    local left = F.shareLeft(item)
    if F.STAGES[item:getFullType()].ham then
        item:setUnhappyChange(F.AGED_HAM_UNHAPPY * left)
        item:setBoredomChange(F.AGED_HAM_BOREDOM * left)
    else
        item:setUnhappyChange(F.AGED_CUT_UNHAPPY * left)
    end
end

-- A piece left hanging where it dried (a finished stack in its station's slots) ages faster: once an hour it
-- gets the extra days since the last look, by moving its stamp back. Taken down, it ages at the shelf's pace.
function F.ageHanging(item, now)
    if not F.ageDays(item) then return end
    local modData = item:getModData()
    local last = modData.hungHour
    if last and now - last < 1 then return end
    modData.hungHour = now
    if not last or modData.aged then return end
    modData.agedFrom = (modData.agedFrom or 0) - (now - last) / 24 * (1 / F.HANG_AGE_SHARE - 1)
    F.rename(item)
end

-- Whether a later stage came from a Gutted Fish (headless). Packing a whole fish takes its guts but leaves it
-- whole, head on, so it isn't. The icon already says which: stages list theirs whole, gutted, then half.
function F.wasGutted(item)
    local index, count = item:getModelIndex(), #F.FISH_ICONS
    return index >= count and index < count * 2
end

-- Names (6a): the name says what it is now, a permanent fact in front ("Corned Beef", "Suho Meso"); a bracket only
-- holds a state that changes or wants acting on, one at most, before vanilla's freshness.
-- The finished meat of each animal, by how it dried: smoked (the default) or air dried (modData.airDried, 6b).
-- The leg has its own, Country Ham.
local function meatKind(index)
    if index == F.LEG_INDEX then return "Leg" end
    return F.MEAT_ANIMALS[index + 1]
end

-- A meat stage's name, from the cut it was made of (its model index; a slice's is in modData.cut): nil for one
-- spawned without a cut. Vanilla's grade ("Beef (Prime Cut)") stays behind: the food values carry it.
local function meatStageName(item)
    local fullType, modData = item:getFullType(), item:getModData()
    local stage = F.STAGES[fullType]
    local index = item:getModelIndex()
    if stage.slice then index = modData.cut end
    local cut = index and F.MEAT_CUTS[index + 1]
    if not cut then return nil end
    local animal = getText("IGUI_TraditionalPreservationFishMeat_Animal" .. F.MEAT_ANIMALS[index + 1])
    if fullType == "TraditionalPreservationFishMeat.SaltPackedMeat" then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", getItemNameFromFullType(cut), getText("IGUI_TraditionalPreservationFishMeat_Packed"))
    elseif fullType == F.CURED_MEAT then
        return getText(modData.longCure and "IGUI_TraditionalPreservationFishMeat_CountryCured" or "IGUI_TraditionalPreservationFishMeat_Corned",
            getItemNameFromFullType(cut))
    elseif fullType == "TraditionalPreservationFishMeat.Charque" then
        return getText("IGUI_TraditionalPreservationFishMeat_CharqueOf", animal)
    elseif fullType == "TraditionalPreservationFishMeat.SoakedCharque" then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", getText("IGUI_TraditionalPreservationFishMeat_CharqueOf", animal),
            getText("IGUI_TraditionalPreservationFishMeat_Soaked"))
    elseif fullType == "TraditionalPreservationFishMeat.HotSmokedMeat" then
        return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", animal)
    elseif stage.hot then
        return getText("IGUI_TraditionalPreservationFishMeat_SliceOf", getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", animal))
    end
    local name = getText((modData.airDried and "IGUI_TraditionalPreservationFishMeat_AirDried_" or "IGUI_TraditionalPreservationFishMeat_Smoked_") .. meatKind(index))
    local aged = F.agedness(item) >= 1
    if stage.slice then
        name = getText("IGUI_TraditionalPreservationFishMeat_SliceOf", name)
        aged = modData.aged == true
    end
    if aged then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Aged"))
    end
    return name
end

-- Stockfish is named by its species alone ("Walleye Stockfish"): no size, nor Gutted, which nearly all of it is.
-- One from another mod's fish (no icon of ours) keeps the name it came with. Matured once ripe; Soaked, rehydrated.
local function stockfishName(item, fishName)
    local index = item:getModelIndex()
    if index >= 0 then fishName = getItemNameFromFullType(F.FISH_ICONS[index % #F.FISH_ICONS + 1]) end
    local name = getText("IGUI_TraditionalPreservationFishMeat_Stockfish", fishName)
    local stage = F.STAGES[item:getFullType()]
    if stage.ripened then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Rehydrated"))
    end
    if F.ripeness(item) >= 1 then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Ripe"))
    end
    return name
end

-- A fish stage's name: the fish (Gutted if it went through Gut Fish), then its stage in brackets, as in
-- "Gutted Medium Walleye (Salt Dried, Rinsed)"; stockfish and meat have their own. Vanilla adds (Fresh) or
-- (Stale) after it. Nil for a stage item that never had a species or a cut.
function F.stageName(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage then return nil end
    if F.isMeatStage(item:getFullType()) then return meatStageName(item) end
    local modData = item:getModData()
    local fishName = modData.fishName
    if not fishName then return nil end
    if stage.matures or stage.ripened then return stockfishName(item, fishName) end
    if stage.prep then return stage.name and getText(stage.name, fishName) or fishName end
    if F.wasGutted(item) then fishName = getText("IGUI_TraditionalPreservationFishMeat_Gutted", fishName) end
    local state = getText(stage.name)
    if stage.salty and modData.rinsed then
        state = getText("IGUI_TraditionalPreservationFishMeat_And", state, getText("IGUI_TraditionalPreservationFishMeat_Rinsed"))
    end
    return getText("IGUI_TraditionalPreservationFishMeat_Named", fishName, state)
end

-- Brings a fish stage's name up to date (ripening, or a name from before the bracket names), and a maturing
-- stockfish's tooltip, which the game doesn't save. The tooltip has a key for each tenth (..._ColdDried_40):
-- the game looks the text up without formatting it, so a made-up text would log a missing translation.
function F.rename(item)
    local ages = F.ageDays(item) ~= nil
    if ages then F.applyAged(item) end
    local name = F.stageName(item)
    if name and item:getDisplayName() ~= name then
        item:setName(name)
        item:setCustomName(true)
    end
    -- Dry-cured meat's tooltip says how far it has aged, a key per tenth as stockfish; air dried meat's has no
    -- smoke in it.
    if ages then
        local agedness = F.agedness(item)
        local tooltip = "Tooltip_TraditionalPreservationFishMeat_" .. (F.STAGES[item:getFullType()].ham and "CountryHam" or item:getModData().airDried and "AirDried" or "DryCured")
        item:setTooltip(tooltip .. "_" .. (agedness >= 1 and "Aged" or math.floor(agedness * 10) * 10))
    end
    if not F.STAGES[item:getFullType()].matures then return end
    local ripeness = F.ripeness(item)
    local tooltip = "Tooltip_TraditionalPreservationFishMeat_ColdDried"
    if ripeness < 1 then tooltip = tooltip .. "_" .. math.floor(ripeness * 10) * 10 end
    item:setTooltip(tooltip)
end

-- InheritFood would copy the first fish onto all of them, and a batch can mix sizes, so each
-- fish hands its own values to one output.
-- A hung piece that rotted before it was done: the same stage again, as it went up, rotten ("Corned Beef", not
-- "Bresaola"; a Gutted Walleye, not a Stockfish).
function F.rottenStage(source)
    local rotten = instanceItem(source:getFullType())
    copyFood(source, rotten, 1)
    rotten:setActualWeight(source:getActualWeight())
    rotten:setCustomWeight(true)
    local sourceData, rottenData = source:getModData(), rotten:getModData()
    for _, key in ipairs({ "fishName", "sliceable", "longCure", "rinsed", "cureSpoiled" }) do rottenData[key] = sourceData[key] end
    if sourceData.rinsed then F.applyRinse(rotten) end
    rotten:setModelIndex(source:getModelIndex())
    F.rename(rotten)
    rotten:setAge(rotten:getOffAgeMax())
    return rotten
end

-- Hot smoked pork is vanilla's Ham (6b), with the cut's own food and Hot Smoked's share of its weight, so Slice Ham
-- and every ham dish take it. Vanilla names and keeps it.
function F.carryHam(source, ham)
    local stage = F.STAGES[F.HOT_MEAT]
    copyFood(source, ham, stage.nutrition, stage.hunger)
    ham:setActualWeight(F.foodWeight(source) * stage.weight)
    ham:setCustomWeight(true)
end

function F.onCreateCured(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        F.carry(fish:get(i), created:get(i))
    end
end

-- Soaking a stockfish fixes how ripe it was, and with it how the fish lifts or lowers the mood.
function F.onCreateSoaked(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        local soaked = created:get(i)
        local ripeness = F.ripeness(fish:get(i))
        soaked:getModData().ripeness = ripeness
        soaked:setUnhappyChange(F.MATURE_UNHAPPY * (1 - 2 * ripeness))
        F.carry(fish:get(i), soaked)
    end
end

-- The press's OnCreate: a warm cure has taken its share off each fish's keeping, and the fish carries
-- that share onto the frame.
function F.onCreatePressed(craftRecipeData)
    F.onCreateCured(craftRecipeData)
    local spoiled = F.cureSpoiled(craftRecipeData:getModData(), F.getLedger())
    if spoiled <= 0 then return end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local fish = created:get(i)
        fish:getModData().cureSpoiled = spoiled
        fish:setAge(spoiled >= 1 and fish:getOffAgeMax() or fish:getOffAge() * spoiled)
    end
end

-- A part cut from a fish, scaled to it as vanilla's guts are.
local function cutFrom(fish, fullType, weightShare, foodShare)
    local part = instanceItem(fullType)
    part:setActualWeight(fish:getActualWeight() * weightShare)
    part:setWeight(part:getActualWeight())
    part:setCustomWeight(true)
    part:setBaseHunger(fish:getBaseHunger() * foodShare)
    part:setHungChange(fish:getHungChange() * foodShare)
    return part
end

-- The head keeps the fish's name and age.
function F.fishHead(fish)
    local share = F.HEAD_FOOD
    local head = cutFrom(fish, "TraditionalPreservationFishMeat.FishHead", F.HEAD_WEIGHT, share)
    copyFood(fish, head, share)
    head:setAge(fish:getAge())
    local fishName = fish:getModData().fishName or string.gsub(fish:getDisplayName(), "%s+$", "")
    head:setName(getText("IGUI_TraditionalPreservationFishMeat_Head", fishName))
    head:setCustomName(true)
    return head
end

-- The stock carries the head's food on top of its own broth, and lists the head among its
-- ingredients, as a vanilla stew lists what went in.
function F.onCreateHeadStock(craftRecipeData)
    local head
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    for i = 0, inputs:size() - 1 do
        if inputs:get(i):getFullType() == "TraditionalPreservationFishMeat.FishHead" then head = inputs:get(i) end
    end
    local stock = craftRecipeData:getAllCreatedItems():get(0)
    if not head or not stock then return end
    stock:setCalories(head:getCalories())
    stock:setProteins(head:getProteins())
    stock:setLipids(head:getLipids())
    stock:setCarbohydrates(head:getCarbohydrates())
    stock:setBaseHunger(stock:getBaseHunger() + head:getBaseHunger())
    stock:setHungChange(stock:getHungChange() + head:getHungChange())
    stock:addExtraItem(head:getFullType())
end

-- For recipes that clean a fish. A recipe can't leave an output out, so the guts and head go
-- straight in the inventory.
function F.onCreateGutted(craftRecipeData, character)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local stage = F.STAGES[craftRecipeData:getAllCreatedItems():get(0):getFullType()]
    F.onCreateCured(craftRecipeData)
    if not F.hasGuts(fish) then return end

    local share = F.GUTS_WEIGHT
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    inventory:AddItem(cutFrom(fish, "Base.FishGuts", share, share))
    if stage.headless and F.hasHead(fish) then
        inventory:AddItem(F.fishHead(fish))
    end
end

-- Packing a whole fish guts it, but a fillet only takes the salt. One recipe packs both, so its
-- xpAward can't tell them apart. Both pack recipes end here, and take the rest of the fish's salt.
function F.onCreatePacked(craftRecipeData, character)
    character = character or craftRecipeData:getCharacter()
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local gutting = F.hasGuts(fish)
    F.onCreateGutted(craftRecipeData, character)
    F.chargeSalt(fish, character)
    if gutting then addXp(character, Perks.Butchering, F.PACK_GUTTING_XP) end
end

-- OnTest sees every input, so the knife passes here too.
function F.canSplit(item, character)
    if item:getFullType() ~= "TraditionalPreservationFishMeat.GuttedFish" then return true end
    return item:getActualWeight() > F.STACK_WEIGHT
end

-- Each half keeps half the weight, not a fillet's share, so halves can't stack deep on a frame.
function F.onCreateSplit(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local halfName = getText("IGUI_TraditionalPreservationFishMeat_Half", fish:getModData().fishName)
    for i = 0, created:size() - 1 do
        local half = created:get(i)
        copyFood(fish, half, 0.5)
        half:setActualWeight(fish:getActualWeight() / 2)
        half:setCustomWeight(true)

        local modData = half:getModData()
        modData.fishName = halfName
        modData.sliceable = false
        half:setName(halfName)
        half:setCustomName(true)
        half:setModelIndex(fish:getModelIndex())
    end
end

-- OnTest sees every input, so the knife passes here too.
function F.canSlice(item, character)
    if not F.STAGES[item:getFullType()] then return true end
    return item:getModData().sliceable == true
end

-- Slicing keeps the stage, so a Salt Packed fish gives Salt Packed fillets. A cured fish has no guts left
-- to lose, so each fillet keeps half its weight with half its food, not vanilla's raw share.
function F.onCreateSliced(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local filletName = getItemNameFromFullType("Base.FishFillet")
    for i = 0, created:size() - 1 do
        local fillet = created:get(i)
        copyFood(fish, fillet, 0.5)
        fillet:setActualWeight(fish:getActualWeight() / 2)
        fillet:setCustomWeight(true)

        local modData = fillet:getModData()
        modData.fishName = filletName
        modData.sliceable = false
        modData.matureAge = fish:getModData().matureAge
        modData.ripeness = fish:getModData().ripeness
        if fish:getModData().rinsed then
            modData.rinsed = true
            F.applyRinse(fillet)
        end
        fillet:setModelIndex(0)
        F.rename(fillet)
    end
end

-- Marks the fish of a stack, so a frame can tell its finished stacks apart, and ages it by what
-- the season took out of it. A stack hot smoked in the Smokehouse comes out Hot Smoked instead, and one that had
-- its hours of smoke there (F.smokeHours) Cold Smoked. Meat dried in the shed is Dry-Cured either way, never Charque.
function F.onCreateDried(craftRecipeData)
    local modData = craftRecipeData:getModData()
    local hung = modData.stackId and F.stackStations[modData.stackId]
    if hung then F.stackStations[modData.stackId] = nil end
    if hung and (modData.spoiled or 0) >= 1 and F.rottenOutputs(craftRecipeData, hung) then
        F.hotStations[modData.stackId], F.smokeStations[modData.stackId] = nil, nil
        return
    end
    local station = F.hotStations[modData.stackId]
    if station then
        F.hotStations[modData.stackId] = nil
        if F.smokedOutputs(craftRecipeData, station, F.HOT_FISH, F.HOT_MEAT) then return end
    end
    -- Meat dry cured on a Frame or Beam in the shade: air dried, as from the shed with no smoke.
    if hung and modData.smokeMeat and not modData.inShed and F.dryCuring(modData) and F.smokedOutputs(craftRecipeData, hung, F.COLD_FISH_OUT, F.DRY_CURED, true) then return end
    station = modData.stackId and F.smokeStations[modData.stackId]
    if station then F.smokeStations[modData.stackId] = nil end
    if station then
        local smoked = F.coldDone(modData)
        -- Meat from the shed is always Dry-Cured, smoked or air dried (6b); fish only with its share of smoke.
        if (smoked or modData.smokeMeat) and F.smokedOutputs(craftRecipeData, station, F.COLD_FISH_OUT, F.DRY_CURED, not smoked) then return end
    end
    F.onCreateCured(craftRecipeData)
    local spoiled = modData.spoiled or 0
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local fish = created:get(i)
        fish:getModData().stackId = modData.stackId
        fish:getModData().style = modData.style
        fish:setAge(spoiled >= 1 and fish:getOffAgeMax() or fish:getOffAge() * spoiled)
        if F.STAGES[fish:getFullType()].matures then
            fish:getModData().matureAge = fish:getAge()
            F.rename(fish)
        end
    end
end

-- What the sandbox's spoilage setting does to the limits: off, forgiving, normal and harsh.
local SPOILAGE_SCALES = { math.huge, 2, 1, 0.5 }
local RAW_SPOIL_HOURS, SALT_SPOIL_HOURS = F.RAW_SPOIL_HOURS, F.SALT_SPOIL_HOURS
local FREEZE_DAMAGE_HOURS, WET_DAMAGE_HOURS, HEAT_DAMAGE_HOURS = F.FREEZE_DAMAGE_HOURS, F.WET_DAMAGE_HOURS, F.HEAT_DAMAGE_HOURS
local UNDER_CURE_HOURS, LONG_CURE_ROT_HOURS = F.UNDER_CURE_HOURS, F.LONG_CURE_ROT_HOURS
-- Small fish press for the same share of the biggest fish's time, whatever the sandbox sets it to.
local PRESS_MIN_SHARE = F.PRESS_MIN_HOURS / F.PRESS_HOURS

-- Reads the sandbox options into the drying, pressing and maturing times and the spoilage limits. Each time is
-- its own option (up to 0.3.6 cold drying followed DryDays at 8/3); their defaults are the times in this file.
function F.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    if not options then return end
    if options.DryDays then F.DRY_HOURS = options.DryDays * 24 end
    if options.ColdDryDays then F.COLD_DRY_HOURS = options.ColdDryDays * 24 end
    if options.MatureDays then F.MATURE_DAYS = options.MatureDays end
    if options.AgeCutDays then F.AGE_CUT_DAYS = options.AgeCutDays end
    if options.AgeHamDays then F.AGE_HAM_DAYS = options.AgeHamDays end
    if options.PressDays then
        F.PRESS_HOURS = options.PressDays * 24
        F.PRESS_MIN_HOURS = F.PRESS_HOURS * PRESS_MIN_SHARE
    end
    if options.CharqueDays then F.CHARQUE_HOURS = options.CharqueDays * 24 end
    if options.Charque ~= nil then F.CHARQUE_ON = options.Charque end
    if options.MaxDryDays then F.MAX_DRY_DAYS = math.max(options.MaxDryDays, F.DRY_HOURS / 24) end
    F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
    local scale = SPOILAGE_SCALES[options.Spoilage] or 1
    F.RAW_SPOIL_HOURS = RAW_SPOIL_HOURS * scale
    F.SALT_SPOIL_HOURS = SALT_SPOIL_HOURS * scale
    F.FREEZE_DAMAGE_HOURS = FREEZE_DAMAGE_HOURS * scale
    F.WET_DAMAGE_HOURS = WET_DAMAGE_HOURS * scale
    F.HEAT_DAMAGE_HOURS = HEAT_DAMAGE_HOURS * scale
    -- Under-salted Corned meat and the long cure's cold rule (0.4.14) go by the setting too: off, they never spoil.
    F.UNDER_CURE_HOURS = UNDER_CURE_HOURS * scale
    F.LONG_CURE_ROT_HOURS = LONG_CURE_ROT_HOURS * scale
end

local function applyRecipeTime(name, hours)
    Weather.setRecipeHours(name, hours, "TraditionalPreservationFishMeat")
end

-- Sets each slow recipe's script time to the sandbox's, so the crafting window shows the right length.
function F.applyRecipeTimes()
    F.applySandbox()
    applyRecipeTime("TraditionalPreservationFishMeat.PressSaltedFish", F.PRESS_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.PressSaltedMeat", F.PRESS_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.CountryCureMeat", F.LONG_LEG_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.HangFishToDry", F.DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.HangFishToColdDry", F.COLD_DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.HangMeatToDry", F.CHARQUE_HOURS)
end

Events.OnInitGlobalModData.Add(F.applyRecipeTimes)
