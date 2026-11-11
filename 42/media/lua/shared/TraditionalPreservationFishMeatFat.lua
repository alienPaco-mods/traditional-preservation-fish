-- Traditional Preservation (Fish & Meat): fat. Vanilla butchering gives no fat and Lard is loot only, so pigs,
-- cattle and sheep get a fat row in vanilla's butchering parts tables, and the recipes in
-- TraditionalPreservationFishMeat_Meat.txt render it in a pot to Lard or Tallow.
require "Definitions/animal/AnimalPartsDefinitions"

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

-- OnTest of Scrape Out Burnt Fat: only a burnt pot.
function F.canScrape(item)
    if not F.FAT_POTS[item:getFullType()] then return true end
    return item:isBurnt()
end

Events.OnInitGlobalModData.Add(function() F.applyFatRows(F.fatEnabled()) end)
