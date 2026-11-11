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
    check(recipe .. " takes a cooked pot and gives the fat, cracklings and the pot",
        text:find("IsCookedFoodItem", 1, true) and text:find("OnTest = TraditionalPreservationFishMeat.canPourOff", 1, true)
        and text:find("item 1 " .. fat .. ",", 1, true) and text:find("item 1 TraditionalPreservationFishMeat.Cracklings,", 1, true)
        and text:find("item 1 mapper:potType", 1, true) ~= nil)
end
check("Scrape Out Burnt Fat gives only the pot", block("craftRecipe", "ScrapeOutBurntFat"):find("OnTest = TraditionalPreservationFishMeat.canScrape", 1, true) ~= nil
    and not block("craftRecipe", "ScrapeOutBurntFat"):find("Cracklings", 1, true))
for recipe in script:gmatch("craftRecipe (%w+)") do
    check(recipe .. " has a name", H.texts[recipe] ~= nil and H.texts["TraditionalPreservationFishMeat." .. recipe] ~= nil)
end
for tooltip in script:gmatch("Tooltip = (Tooltip_[%w_]+)") do
    check(tooltip .. " is translated", getText(tooltip) ~= tooltip)
end
check("Tallow and Cracklings have names", H.texts["TraditionalPreservationFishMeat.Tallow"] ~= nil and H.texts["TraditionalPreservationFishMeat.Cracklings"] ~= nil)
check("the sandbox has the option", io.open("42/media/sandbox-options.txt"):read("*a"):find("option TraditionalPreservationFishMeat.ButcheringFat", 1, true) ~= nil)

H.done()
