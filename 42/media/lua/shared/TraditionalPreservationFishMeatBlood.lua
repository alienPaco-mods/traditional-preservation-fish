-- Traditional Preservation (Fish & Meat): blood. Vanilla lets a carcass be bled into a container (Animal Blood) and
-- nothing uses it, and the fluid never goes off. Here the amount follows the animal's weight as at a real sticking,
-- the blood goes off through TP Core's FluidAgeing (kind blood: fresh, spoiled, and three treated states), salt or
-- vinegar stirred in keeps it longer, and it goes into Black Pudding (baked in a pan) and Blood Sausage (stuffed
-- into salted casings from butchering and boiled). The recipes are in TraditionalPreservationFishMeat_Blood.txt.
require "Definitions/animal/CowDefinitions"
require "Definitions/animal/PigDefinitions"
require "Definitions/animal/SheepDefinitions"
require "Definitions/animal/DeerDefinitions"
require "Definitions/animal/AnimalPartsDefinitions"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Weather = require "TraditionalPreservationCore/Weather"
local OnHeat = require "TraditionalPreservationCore/OnHeat"
local Charge = require "TraditionalPreservationCore/Charge"

TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- How much blood a carcass holds (user, 2026-11-13). Vanilla gives each animal minBlood to maxBlood centilitres by
-- its weight in its minWeight to maxWeight (IsoAnimal.getBloodQuantity), 8 to 25 L for a pig or a sheep, four to
-- six times a real sticking's. An animal has 6-8% of its weight in blood and about half drains, so here it is 3.5
-- cl a kg: 3.5 L from a 100 kg pig, 20 L from a 600 kg cow. The game reads the Lua table on first use, when the
-- world loads (AnimalDefinitions.loadAnimalDefinitions), so this runs as the file loads.
F.BLOOD_CL_PER_KG = 3.5

function F.realBlood(animals)
    for _, def in pairs(animals or {}) do
        if def.minBlood and def.minWeight and def.maxWeight then
            def.minBlood = math.floor(def.minWeight * F.BLOOD_CL_PER_KG + 0.5)
            def.maxBlood = math.floor(def.maxWeight * F.BLOOD_CL_PER_KG + 0.5)
        end
    end
end

F.realBlood(AnimalDefinitions and AnimalDefinitions.animals)

-- Going off (user, 2026-11-13). Fresh blood keeps a day at 20 C and three in a fridge; cured with salt or vinegar
-- (one state, Cured, whichever was stirred in; user 2026-11-13) three days at 20 C and seven in a fridge. The rate
-- is 1 at 20 C, 2 at 30 C, stopped once frozen; cured blood has its own cold curve (its own ledger kind), so the
-- fridge (4 C) is a third for fresh blood, 3/7 for cured. Blood has no soured stage: it goes straight to Spoiled
-- Blood. Fluid names and ledger kinds are saved: never rename them once the mod is out.
F.BLOOD_KIND = "blood"
F.BLOOD_KEEPING = { { -1, 0 }, { 4, 1 / 3 }, { 20, 1 }, { 30, 2 } }
F.CURED_BLOOD_KEEPING = { { -1, 0 }, { 4, 3 / 7 }, { 20, 1 }, { 30, 2 } }
F.BLOOD_SPOIL_HOURS = 24
F.BLOOD_FLUID = "AnimalBlood"
F.SPOILED_BLOOD = "SpoiledBlood"
F.BLOOD_LEDGER_KEY = "TraditionalPreservationFishMeatBlood"

local function bloodRate(celsius)
    return Weather.curve(F.BLOOD_KEEPING, celsius)
end
local function curedRate(celsius)
    return Weather.curve(F.CURED_BLOOD_KEEPING, celsius)
end
local BLOOD_KINDS = { blood = bloodRate, bloodCured = curedRate }

-- Salt and vinegar are one treatment, Cured: cured blood mixed with cured blood stays cured, and curing it again
-- does nothing.
F.BLOOD_STATES = {
    Cured = { fluids = { AnimalBlood = "CuredBlood" }, spoilHours = 72, kind = "bloodCured", rate = curedRate },
}

function F.newBloodLedger(now)
    return Weather.newLedger(now, BLOOD_KINDS)
end

function F.bloodLedger()
    return Weather.fillLedger(Weather.getLedger(F.BLOOD_LEDGER_KEY, F.newBloodLedger), BLOOD_KINDS)
end

-- Adds a stretch of weather to the blood ledger (every ten minutes, from the World).
function F.recordBlood(now, temperature)
    Weather.advance(F.bloodLedger(), now, temperature, BLOOD_KINDS)
end

F.BLOOD_SPEC = FluidAgeing.register({
    kind = F.BLOOD_KIND,
    rate = bloodRate,
    turnHours = math.huge,
    spoilHours = F.BLOOD_SPOIL_HOURS,
    fresh = { AnimalBlood = F.BLOOD_FLUID },
    spoiled = { AnimalBlood = F.SPOILED_BLOOD },
    states = F.BLOOD_STATES,
    getLedger = function() return F.bloodLedger() end,
    -- Vanilla's Food Spoilage setting, as Potted Meat's.
    speed = function() return F.POTTED_KEEP and F.POTTED_KEEP.speed() or 1 end,
})

-- Every blood a recipe can use: fresh or treated, never spoiled.
F.USABLE_BLOOD = { AnimalBlood = true, CuredBlood = true }

-- Curing (user 2026-11-13): TP Core's treat menu on a container of blood (Cure Blood, -n Salt / -n Vinegar), one use
-- for each BLOOD_LITRES_PER_USE litres, about 1% salt or 5% vinegar, taken from what the player carries.
F.BLOOD_LITRES_PER_USE = 2
F.BLOOD_TREATMENTS = {
    { name = "Cured", tag = function() return ItemTag.SALT end, icon = "Item_Salt",
        label = "ContextMenu_TraditionalPreservationFishMeat_CureSalt" },
    { name = "Cured", tag = function() return ItemTag.VINEGAR end, icon = "Item_Vinegar",
        label = "ContextMenu_TraditionalPreservationFishMeat_CureVinegar" },
}
F.BLOOD_SPEC.treatments = F.BLOOD_TREATMENTS
F.BLOOD_SPEC.litresPerUse = F.BLOOD_LITRES_PER_USE
F.BLOOD_SPEC.treatMenu = "ContextMenu_TraditionalPreservationFishMeat_CureBlood"
F.BLOOD_SPEC.treatTooltip = "Tooltip_TraditionalPreservationFishMeat_TreatBlood"

-- The litres of fresh or treated blood in a container item, and of spoiled blood.
function F.bloodIn(item)
    local container = item and item.getFluidContainer and item:getFluidContainer()
    if not container then return 0, 0 end
    return FluidAgeing.litresIn(container, F.BLOOD_SPEC)
end

-- The filler of black pudding and blood sausage (user, 2026-11-13: any of them, one recipe): a quarter of a bag of oats
-- or rice by the use, or 12 grains (0.24 kg) of barley, rye or wheat, the renewable ones. The recipe line keeps the
-- one it takes; TP Core's Charge takes the amount.
F.FILLER = Charge.line({
    ["Base.OatsRaw"] = { uses = 12 }, ["Base.Rice"] = { uses = 12 },
    ["Base.BarleySeed"] = { count = 12 }, ["Base.RyeSeed"] = { count = 12 }, ["Base.WheatSeed"] = { count = 12 },
})
F.canTakeFiller = F.FILLER.onTest
F.onCreateTakeFiller = F.FILLER.take

-- Casings (user, 2026-11-13): vanilla butchering gives no guts, so pigs, cattle, sheep and deer get a Raw Casings
-- row in vanilla's parts tables, as the fat rows are added. One Raw Casings fills one batch of six sausages. They are
-- base numbers, scaled as the fat rows' are (on a Butchering Hook about x2.8, never less than one): a pig on the Hook
-- gives about 3, cattle about 4, a sheep or a deer about 2, a young animal 1. Raw casings go off in a day;
-- cleaned and packed in salt they keep a year.
F.CASING_ITEM = "TraditionalPreservationFishMeat.RawCasings"
F.CASING_ROWS = {
    { minNb = 1, maxNb = 1, animals = { "sowlandrace", "boarlandrace", "sowlargeblack", "boarlargeblack" } },
    { minNb = 1, maxNb = 2, animals = { "cowangus", "bullangus", "cowsimmental", "bullsimmental", "cowholstein", "bullholstein" } },
    { minNb = 1, maxNb = 1, animals = { "ewesuffolk", "ramsuffolk", "ewerambouillet", "ramrambouillet", "ewefriesian", "ramfriesian" } },
    { minNb = 1, maxNb = 1, animals = { "doewhitetailed", "buckwhitetailed" } },
    -- Young animals: about one.
    { minNb = 0.5, maxNb = 0.5, animals = { "cowcalfangus", "cowcalfsimmental", "cowcalfholstein", "pigletlandrace",
        "pigletlargeblack", "lambsuffolk", "lambrambouillet", "lambfriesian", "fawnwhitetailed" } },
}

-- Puts the casing rows into vanilla's parts tables, once each however often it runs (shared tables, as for fat).
function F.applyCasingRows()
    local animals = AnimalPartsDefinitions and AnimalPartsDefinitions.animals
    if not animals then return end
    for _, row in ipairs(F.CASING_ROWS) do
        for _, name in ipairs(row.animals) do
            local parts = animals[name] and animals[name].parts
            if parts then
                for index = #parts, 1, -1 do
                    if parts[index].item == F.CASING_ITEM then table.remove(parts, index) end
                end
                table.insert(parts, { item = F.CASING_ITEM, minNb = row.minNb, maxNb = row.maxNb })
            end
        end
    end
end

Events.OnInitGlobalModData.Add(F.applyCasingRows)

-- Telling the links apart (user, 2026-11-13): poached they are Blood Sausage (Boiled); a raw link fried as it is
-- names itself Blood Sausage (Fried) as it cooks (OnCooked); a boiled one fried afterwards, BLOOD_SAUSAGE_FRY_MINUTES
-- at frying heat (TP Core's OnHeat), Blood Sausage (Boiled, Fried). Only the name changes.
F.BLOOD_SAUSAGE_FRY_MINUTES = 5

local function rename(item, key)
    item:setName(getText(key))
    item:setCustomName(true)
end

function F.onCookedBloodSausage(item)
    rename(item, "IGUI_TraditionalPreservationFishMeat_BloodSausageFried")
end

OnHeat.watch("TraditionalPreservationFishMeat.BloodSausage", F.BLOOD_SAUSAGE_FRY_MINUTES, function(item)
    rename(item, "IGUI_TraditionalPreservationFishMeat_BloodSausageBoiledFried")
end)
