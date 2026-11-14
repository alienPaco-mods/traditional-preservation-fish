-- Traditional Preservation (Fish & Meat): fat. Vanilla butchering gives no fat and Lard is loot only, so pigs,
-- cattle and sheep get a fat row in vanilla's butchering parts tables, and the recipes in
-- TraditionalPreservationFishMeat_Meat.txt render it. Raw fat is an item; over heat it becomes a fluid, Lard (Melted)
-- or Tallow (Melted), and that is strained to a block and its Cracklings. Two pieces cook in a pot (which can burn)
-- and are poured off as a pot of melted fat; TP Core's Hearth melts many pieces at once in its cauldron.
require "Definitions/animal/AnimalPartsDefinitions"
local Hearth = require "TraditionalPreservationCore/Hearth"

TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- The row each kind of animal gets, and the vanilla animals (type and breed, the keys of
-- AnimalPartsDefinitions.animals) that are of that kind. Young animals and deer are too lean for one.
-- minNb and maxNb are base numbers as vanilla's are: ButcheringUtil.addAnimalPart multiplies them by the animal's
-- size and meat ratio, by 2.8 on a Butchering Hook or 0.6 on the ground, raises the maximum with Butchering
-- skill, halves roadkill and cuts an old carcass, and never gives less than one. Two pieces render to one block,
-- so a pig on the Hook gives 5 to 7 Pork Fat, 2 or 3 Lard, about what its meat is worth; on the ground one piece.
F.FAT_ROWS = {
    {
        item = "TraditionalPreservationFishMeat.PorkFat", minNb = 2, maxNb = 3,
        animals = { "sowlandrace", "boarlandrace", "sowlargeblack", "boarlargeblack" },
    },
    {
        item = "TraditionalPreservationFishMeat.BeefSuet", minNb = 3, maxNb = 4,
        animals = { "cowangus", "bullangus", "cowsimmental", "bullsimmental", "cowholstein", "bullholstein" },
    },
    {
        item = "TraditionalPreservationFishMeat.MuttonFat", minNb = 1, maxNb = 2,
        animals = { "ewesuffolk", "ramsuffolk", "ewerambouillet", "ramrambouillet", "ewefriesian", "ramfriesian" },
    },
}

-- The pots of raw or rendered fat.
F.FAT_POTS = {
    ["TraditionalPreservationFishMeat.PotOfPorkFat"] = true,
    ["TraditionalPreservationFishMeat.PotForgedPorkFat"] = true,
    ["TraditionalPreservationFishMeat.PotOfSuet"] = true,
    ["TraditionalPreservationFishMeat.PotForgedSuet"] = true,
}

-- Fat in the Hearth's cauldron. The cauldron holds fluids, so a piece of raw fat goes in as FAT_PIECE_ML of its raw
-- fluid (never rename a fluid once the mod is out: saves hold the names). Kept steaming for FAT_RENDER_HOURS it
-- melts (Hearth.turnsHot), and 0.5 L of the melted fat strains to a block and its Cracklings (Strain Lard, Strain
-- Tallow), so two pieces make a block here as they do in a pot. Raw fat stays in the cauldron (Hearth.staysIn) and
-- goes rancid there when its oldest piece would have rotted (Hearth.goesOff); melted fat keeps, as Lard does.
F.FAT_PIECE_ML = 250
F.FAT_RENDER_HOURS = 1
F.RANCID_FAT = "RancidFat"
F.CAULDRON_FATS = {
    {
        raw = "RawPorkFat", melted = "MeltedLard", name = "PorkFat",
        items = { ["TraditionalPreservationFishMeat.PorkFat"] = true },
    },
    {
        raw = "RawSuet", melted = "MeltedTallow", name = "Suet",
        items = { ["TraditionalPreservationFishMeat.BeefSuet"] = true, ["TraditionalPreservationFishMeat.MuttonFat"] = true },
    },
}
for _, fat in ipairs(F.CAULDRON_FATS) do
    Hearth.turnsHot(fat.raw, fat.melted, F.FAT_RENDER_HOURS)
    Hearth.goesOff(fat.raw, F.RANCID_FAT)
    Hearth.staysIn(fat.raw)
end
Hearth.staysIn(F.RANCID_FAT)

-- How many pieces of a raw fat the cauldron has room for now: none if it holds anything else.
function F.cauldronFatRoom(cauldron, raw)
    return math.floor(Hearth.cauldronRoom(cauldron, raw, Hearth.CAULDRON_ML) / F.FAT_PIECE_ML)
end

-- Puts pieces of raw fat in the cauldron, as many as fit. hoursLeft has, for each piece, the hours until it would
-- have rotted. Returns how many went in.
function F.putFatInCauldron(cauldron, raw, hoursLeft, now)
    local count = math.min(#hoursLeft, F.cauldronFatRoom(cauldron, raw))
    if count <= 0 then return 0 end
    Hearth.pourInto(cauldron, raw, count * F.FAT_PIECE_ML, Hearth.ROOM_C, now)
    for index = 1, count do Hearth.offBy(cauldron, now + math.max(hoursLeft[index], 0)) end
    return count
end

-- Hours until a piece of raw fat is rotten.
function F.fatHoursLeft(item)
    return (item:getOffAgeMax() - item:getAge()) * 24
end

local function withoutRow(parts, item)
    for index = #parts, 1, -1 do
        if parts[index].item == item then table.remove(parts, index) end
    end
end

-- Puts the fat rows into vanilla's parts tables, or takes them out again when the sandbox turns butchering fat
-- off. Vanilla's breeds share one parts table per kind of animal, so a table is only ever given its row once,
-- however often this runs. An animal vanilla no longer has is skipped.
function F.applyFatRows(enabled)
    local animals = AnimalPartsDefinitions and AnimalPartsDefinitions.animals
    if not animals then return end
    for _, row in ipairs(F.FAT_ROWS) do
        for _, name in ipairs(row.animals) do
            local parts = animals[name] and animals[name].parts
            if parts then
                withoutRow(parts, row.item)
                if enabled then table.insert(parts, { item = row.item, minNb = row.minNb, maxNb = row.maxNb }) end
            end
        end
    end
end

-- Whether the sandbox lets butchering give fat. On unless the option says otherwise.
function F.fatEnabled()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    return not options or options.ButcheringFat ~= false
end

-- OnTest of Pour Off Lard and Pour Off Tallow: the recipe's cooked-food flag lets burnt food through, and burnt
-- fat gives nothing.
function F.canPourOff(item)
    if not F.FAT_POTS[item:getFullType()] then return true end
    return not item:isBurnt()
end

-- OnCreate of Pour Off Lard and Pour Off Tallow: the pot comes back holding the two pieces' melted fat, hot.
F.POT_FAT_ML = 2 * F.FAT_PIECE_ML

local function fillWith(craftRecipeData, fluid)
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local container = created:get(i):getFluidContainer()
        if container then
            container:addFluid(fluid, F.POT_FAT_ML / 1000)
            created:get(i):setItemHeat(Hearth.itemHeat(Hearth.HOT_C))
        end
    end
end

function F.onPourOffLard(craftRecipeData)
    fillWith(craftRecipeData, F.CAULDRON_FATS[1].melted)
end

function F.onPourOffTallow(craftRecipeData)
    fillWith(craftRecipeData, F.CAULDRON_FATS[2].melted)
end

-- OnTest of Scrape Out Burnt Fat: only a burnt pot, of fat or of Potted Meat's meat in fat.
function F.canScrape(item)
    local fullType = item:getFullType()
    if not F.FAT_POTS[fullType] and not (F.MEAT_FAT_POTS and F.MEAT_FAT_POTS[fullType]) then return true end
    return item:isBurnt()
end

Events.OnInitGlobalModData.Add(function() F.applyFatRows(F.fatEnabled()) end)
