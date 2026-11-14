-- Checks the fat rows in vanilla's butchering tables, the rendering recipes and the fat items outside the game.
-- Run from the mod folder: luajit tests/test_fat.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installEvents()
H.installGetText()

-- Vanilla's tables as AnimalPartsDefinitions.lua builds them: breeds of a kind share one parts table.
local pigParts = { { item = "Base.PorkChop", minNb = 8, maxNb = 13 }, { item = "Base.Pork", minNb = 8, maxNb = 13 } }
local pigletParts = { { item = "Base.PorkChop", minNb = 3, maxNb = 7 } }
local cowParts = { { item = "Base.Steak", minNb = 10, maxNb = 18 } }
local sheepParts = { { item = "Base.MuttonChop", minNb = 9, maxNb = 15 } }
local deerParts = { { item = "Base.Venison", minNb = 10, maxNb = 19 } }
AnimalPartsDefinitions = { animals = {
    sowlandrace = { parts = pigParts }, boarlandrace = { parts = pigParts },
    sowlargeblack = { parts = pigParts }, boarlargeblack = { parts = pigParts },
    pigletlandrace = { parts = pigletParts },
    cowangus = { parts = cowParts }, bullangus = { parts = cowParts }, cowsimmental = { parts = cowParts },
    bullsimmental = { parts = cowParts }, cowholstein = { parts = cowParts },
    ewesuffolk = { parts = sheepParts }, ramsuffolk = { parts = sheepParts },
    doewhitetailed = { parts = deerParts },
} }
package.loaded["Definitions/animal/AnimalPartsDefinitions"] = true

dofile("42/media/lua/shared/TraditionalPreservationFishMeatFat.lua")
local F = TraditionalPreservationFishMeat

local function rows(parts, item)
    local found = {}
    for _, part in ipairs(parts) do
        if part.item == item then table.insert(found, part) end
    end
    return found
end
local PORK, SUET, MUTTON = "TraditionalPreservationFishMeat.PorkFat", "TraditionalPreservationFishMeat.BeefSuet", "TraditionalPreservationFishMeat.MuttonFat"

-- The rows
check("nothing is added before the game starts a world", #pigParts == 2)
H.fire("OnInitGlobalModData")
check("a world gives pigs one Pork Fat row, though four breeds share the table", #rows(pigParts, PORK) == 1 and #pigParts == 3)
check("cattle get Beef Suet and sheep Mutton Fat", #rows(cowParts, SUET) == 1 and #rows(sheepParts, MUTTON) == 1)
check("piglets and deer get none", #pigletParts == 1 and #deerParts == 1)
check("a missing vanilla animal (bullholstein here) is skipped", AnimalPartsDefinitions.animals.bullholstein == nil)
F.applyFatRows(true)
check("applying again adds nothing", #pigParts == 3 and #cowParts == 2 and #sheepParts == 2)
F.applyFatRows(false)
check("turned off, the tables are vanilla's again", #pigParts == 2 and #cowParts == 1 and #sheepParts == 1)
F.applyFatRows(true)

check("butchering fat is on with no sandbox", F.fatEnabled())
SandboxVars = { TraditionalPreservationFishMeat = { ButcheringFat = false } }
check("and off when the sandbox says so", not F.fatEnabled())
SandboxVars.TraditionalPreservationFishMeat.ButcheringFat = true
check("and on when it says so", F.fatEnabled())

-- The cap: on the Butchering Hook a pig's fat renders to 2 or 3 Lard, on the ground to none without a second pig.
-- Vanilla's sums (ButcheringUtil.addAnimalPart): the base numbers x2.8 on the Hook, x0.6 on the ground, a whole
-- number from the minimum up to but not including the maximum, and never less than one.
local function pieces(row, scale)
    local low, high = math.floor(row.minNb * scale), math.floor(row.maxNb * scale) - 1
    return math.max(1, low), math.max(1, high)
end
local pork = rows(pigParts, PORK)[1]
local low, high = pieces(pork, 2.8)
check("a pig on the Hook gives 5 to 7 Pork Fat: 2 or 3 Lard", low == 5 and high == 7)
low, high = pieces(pork, 0.6)
check("a pig on the ground gives one", low == 1 and high == 1)
low, high = pieces(rows(cowParts, SUET)[1], 2.8)
check("a cow on the Hook gives 8 to 10 Beef Suet: 4 or 5 Tallow", low == 8 and high == 10)
low, high = pieces(rows(sheepParts, MUTTON)[1], 2.8)
check("a sheep on the Hook gives 2 to 4 Mutton Fat: 1 or 2 Tallow", low == 2 and high == 4)

-- The recipes' tests
local function pot(fullType, burnt)
    return { getFullType = function() return fullType end, isBurnt = function() return burnt end }
end
check("a cooked pot pours off", F.canPourOff(pot("TraditionalPreservationFishMeat.PotOfPorkFat", false)))
check("a burnt pot doesn't", not F.canPourOff(pot("TraditionalPreservationFishMeat.PotForgedSuet", true)))
check("a burnt pot scrapes out", F.canScrape(pot("TraditionalPreservationFishMeat.PotOfSuet", true)))
check("a good pot doesn't", not F.canScrape(pot("TraditionalPreservationFishMeat.PotForgedPorkFat", false)))

-- The scripts
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
local function block(kind, name)
    return script:match("\n    " .. kind .. " " .. name .. "\n    (%b{})")
end
local function number(item, field)
    return tonumber(block("item", item):match(field .. " = ([%-%d%.]+)"))
end
for _, row in ipairs(F.FAT_ROWS) do
    local name = row.item:match("%.(%w+)$")
    check(name .. " is an item with a name", block("item", name) ~= nil and H.texts[row.item] ~= nil)
end
for name in pairs(F.FAT_POTS) do
    local item = block("item", name:match("%.(%w+)$"))
    check(name .. " has a name, cooks and can't be eaten", item ~= nil and H.texts[name] ~= nil
        and item:find("IsCookable = true", 1, true) and item:find("CantEat = true", 1, true) ~= nil)
end
local lard = 4095
check("Tallow is worth vanilla's Lard and bakes like it", number("Tallow", "Calories") == lard
    and block("item", "Tallow"):find("Tags = base:bakingfat", 1, true) ~= nil)
for _, fat in ipairs({ "PorkFat", "BeefSuet", "MuttonFat" }) do
    check("two " .. fat .. " are worth a block and its cracklings",
        math.abs(2 * number(fat, "Calories") - lard - number("Cracklings", "Calories")) < 10)
    check(fat .. " keeps like raw meat", number(fat, "DaysFresh") == 2 and number(fat, "DaysTotallyRotten") == 4)
end
check("Put Pork Fat in a Pot takes an empty pot and two raw pieces",
    block("craftRecipe", "PutPorkFatInPot"):find("item 2 [TraditionalPreservationFishMeat.PorkFat] flags[InheritFoodAge;IsUncookedFoodItem;ItemCount]", 1, true) ~= nil
    and block("craftRecipe", "PutPorkFatInPot"):find("flags[InheritCondition;IsEmpty]", 1, true) ~= nil)
check("suet and mutton fat share a pot", block("craftRecipe", "PutSuetInPot"):find("[TraditionalPreservationFishMeat.BeefSuet;TraditionalPreservationFishMeat.MuttonFat]", 1, true) ~= nil)
for recipe, fat in pairs({ PourOffLard = "Base.Lard", PourOffTallow = "TraditionalPreservationFishMeat.Tallow" }) do
    local text = block("craftRecipe", recipe)
    local kind = recipe:match("PourOff(%w+)")
    check(recipe .. " takes a cooked pot and gives the pot back, filled by its OnCreate; the block and cracklings come from straining",
        text:find("IsCookedFoodItem", 1, true) and text:find("OnTest = TraditionalPreservationFishMeat.canPourOff", 1, true)
        and text:find("OnCreate = TraditionalPreservationFishMeat.onPourOff" .. kind .. ",", 1, true)
        and text:find("item 1 mapper:potType", 1, true) and not text:find(fat, 1, true)
        and not text:find("Cracklings", 1, true) and not text:find("xpAward", 1, true))
end
check("Scrape Out Burnt Fat gives only the pot", block("craftRecipe", "ScrapeOutBurntFat"):find("OnTest = TraditionalPreservationFishMeat.canScrape", 1, true) ~= nil
    and not block("craftRecipe", "ScrapeOutBurntFat"):find("Cracklings", 1, true))
for recipe in script:gmatch("craftRecipe (%w+)") do
    check(recipe .. " has a name", H.texts[recipe] ~= nil and H.texts["TraditionalPreservationFishMeat." .. recipe] ~= nil)
end
for tooltip in script:gmatch("Tooltip = (Tooltip_[%w_]+)") do
    check(tooltip .. " is translated", getText(tooltip) ~= tooltip)
end
-- Fat in the Hearth's cauldron
local Hearth = require "TraditionalPreservationCore/Hearth"
local fluids = io.open("42/media/scripts/TraditionalPreservationFishMeat_fluids.txt"):read("*a")
for _, fat in ipairs(F.CAULDRON_FATS) do
    for _, name in ipairs({ fat.raw, fat.melted }) do
        check(name .. " is a fluid with a name", fluids:find("\n    fluid " .. name .. "\n", 1, true) ~= nil
            and H.texts["Fluid_Name_" .. name] ~= nil)
    end
    check(fat.raw .. " has its row's text", H.texts["ContextMenu_TraditionalPreservationFishMeat_FatPieces_" .. fat.name] ~= nil)
    for item in pairs(fat.items) do
        check(item .. " is a raw fat item", block("item", item:match("%.(%w+)$")) ~= nil)
    end
end
check("Fat (Rancid) is a fluid with a name", fluids:find("\n    fluid RancidFat\n", 1, true) ~= nil and H.texts.Fluid_Name_RancidFat ~= nil)
local cauldron = {}
check("an empty cauldron has room for 240 pieces", F.cauldronFatRoom(cauldron, "RawPorkFat") == 240)
check("six pieces of pork fat go in as a litre and a half", F.putFatInCauldron(cauldron, "RawPorkFat", { 96, 30, 96, 96, 96, 96 }, 10) == 6
    and cauldron.ml == 1500 and cauldron.fluid == "RawPorkFat" and cauldron.tempC == Hearth.ROOM_C)
check("the oldest piece sets when it goes rancid", cauldron.offAt == 40)
check("raw fat can't be ladled out", not Hearth.poursOut(cauldron))
check("suet doesn't go in with pork fat", F.cauldronFatRoom(cauldron, "RawSuet") == 0 and F.putFatInCauldron(cauldron, "RawSuet", { 96 }, 10) == 0)
check("more pork fat does, and a rotten piece makes it rancid at once", F.putFatInCauldron(cauldron, "RawPorkFat", { -5 }, 12) == 1
    and cauldron.ml == 1750 and cauldron.offAt == 12)
cauldron.offAt, cauldron.last = 40, 12
cauldron.fireUntil = 100
Hearth.advance(cauldron, 12 + Hearth.hoursToHot(cauldron, cauldron.banked) + 0.9, 20, cauldron)
check("not yet melted short of the hour", cauldron.fluid == "RawPorkFat")
Hearth.advance(cauldron, 15, 20, cauldron)
check("an hour steaming melts it to Lard (Melted), which ladles out and keeps", cauldron.fluid == "MeltedLard" and Hearth.poursOut(cauldron)
    and cauldron.offAt == nil)
check("seven pieces are three blocks and a half", cauldron.ml / 500 == 3.5)
check("melted fat takes no raw", F.cauldronFatRoom(cauldron, "RawPorkFat") == 0)
local suet = {}
F.putFatInCauldron(suet, "RawSuet", { 50, 50 }, 0)
Hearth.advance(suet, 51, 20, suet)
check("suet left cold goes rancid, and stays in the cauldron", suet.fluid == "RancidFat" and not Hearth.poursOut(suet))
local tight = { ml = Hearth.CAULDRON_ML - 600, fluid = "RawSuet", tempC = 20, last = 0 }
check("a nearly full cauldron takes only the pieces that fit", F.putFatInCauldron(tight, "RawSuet", { 9, 9, 9, 9 }, 0) == 2)
check("a piece's hours left come from its age", F.fatHoursLeft({ getOffAgeMax = function() return 4 end, getAge = function() return 1.5 end }) == 60)
for recipe, fat in pairs({ StrainLard = { "MeltedLard", "Base.Lard" }, StrainTallow = { "MeltedTallow", "TraditionalPreservationFishMeat.Tallow" } }) do
    local text = block("craftRecipe", recipe)
    check(recipe .. " takes half a litre from any container and gives a block and its cracklings",
        text:find("item 1 [*],\n            -fluid 0.5 [" .. fat[1] .. "],", 1, true) and text:find("item 1 " .. fat[2] .. ",", 1, true)
        and text:find("item 1 [Base.CheeseCloth;Base.DishCloth;Base.RippedSheets;Base.Sheet;Base.Strainer] mode:keep,\n            item 1 [*],", 1, true)
        and text:find("item 1 TraditionalPreservationFishMeat.Cracklings,", 1, true) ~= nil)
end
local function poured(onCreate)
    local pot = { fluids = {} }
    pot.getFluidContainer = function() return { addFluid = function(_, name, litres) pot.fluids[name] = litres end } end
    pot.setItemHeat = function(_, heat) pot.heat = heat end
    onCreate({ getAllCreatedItems = function() return H.list({ pot }) end })
    return pot
end
local potOfLard, potOfTallow = poured(F.onPourOffLard), poured(F.onPourOffTallow)
check("a pot poured off holds half a litre of Lard (Melted), hot: one block's worth, as two pieces are in the cauldron",
    potOfLard.fluids.MeltedLard == 0.5 and potOfLard.heat > 1.4 and F.POT_FAT_ML == 2 * F.FAT_PIECE_ML)
check("a pot of suet pours off as Tallow (Melted)", potOfTallow.fluids.MeltedTallow == 0.5 and potOfTallow.fluids.MeltedLard == nil)
check("a litre of melted fat is worth two blocks", tonumber(fluids:match("fluid MeltedLard.-Calories = ([%d%.]+)")) == 2 * lard
    and tonumber(fluids:match("fluid MeltedTallow.-Calories = ([%d%.]+)")) == 2 * lard)
for _, key in ipairs({ "FatHelp", "NoFat", "FatNoRoom", "FatRendering", "FatMelted", "FatRancid" }) do
    check(key .. " is translated", H.texts["IGUI_TraditionalPreservationFishMeat_" .. key] ~= nil)
end

check("Tallow and Cracklings have names", H.texts["TraditionalPreservationFishMeat.Tallow"] ~= nil and H.texts["TraditionalPreservationFishMeat.Cracklings"] ~= nil)
check("the sandbox has the option", io.open("42/media/sandbox-options.txt"):read("*a"):find("option TraditionalPreservationFishMeat.ButcheringFat", 1, true) ~= nil)

H.done()
