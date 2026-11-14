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
local Hearth = require "TraditionalPreservationCore/Hearth"
local Season = require "TraditionalPreservationCore/Season"

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
    speed = FluidAgeing.foodRotSpeed,
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

-- Smoked Blood Sausage (user, 2026-11-13): boiled links, never fried, hung alone in the Smokehouse
-- (Hang Sausage to Smoke, one recipe with Smoked Sausage's since 0.4.38) take SMOKED_SAUSAGE_HOURS of cold smoke, whatever the stack: the Smokehouse's cold
-- counter (F.smokeStep), so fire hours count only on cool days and a stoked run is smoke at once (never a cook), as
-- Thuringian Rotwurst or smoked kaszanka are smoked after the kettle. Each link keeps its Boiled clock while it
-- hangs (vanilla's day a day, by the Food Spoilage setting). One smoked before it went stale comes down Smoked Blood
-- Sausage (21 / 40), its age the same share of the new keeping; one gone stale first comes down the Boiled link it
-- was. The stack ends once smoked, or once every link has gone stale.
F.SMOKED_SAUSAGE_HOURS = 24
F.BLOOD_SAUSAGE = "TraditionalPreservationFishMeat.BloodSausage"
F.SMOKED_BLOOD_SAUSAGE = "TraditionalPreservationFishMeat.SmokedBloodSausage"

-- Whether a boiled link was fried afterwards (TP Core's OnHeat ran its rename).
function F.wasFried(item)
    local heat = item:getModData()[OnHeat.KEY]
    return heat ~= nil and heat.done == true
end

-- OnTest for HangSausageToSmoke: blood sausage boiled and never fried after; Fresh Sausage raw.
function F.canSmokeSausage(item)
    if item:getFullType() == F.BLOOD_SAUSAGE then return item:isCooked() and not F.wasFried(item) end
    if item:getFullType() == F.FRESH_SAUSAGE then return not item:isCooked() end
    return true
end

-- Sets a new stack's counters from its links (an ArrayList): the Smokehouse's, and the hour its freshest link goes
-- stale. Blood sausage takes no cook and a fixed smoke; Smoked Sausage ("pork", TraditionalPreservationFishMeatSausage.lua)
-- a fixed hot run. modData.sausage is true for blood (as stacks hung since 0.4.37 have it) or "pork".
function F.startSausageSmoke(modData, links, now, speed, kind)
    -- Recipe data is pooled with its ModData (ENGINE_NOTES): a stack mustn't inherit an old one's counters.
    local keys = {}
    for key in pairs(modData) do table.insert(keys, key) end
    for _, key in ipairs(keys) do modData[key] = nil end
    F.startSmoke(modData, links, false)
    if kind == "pork" then
        modData.sausage, modData.hotNeed = "pork", F.SAUSAGE_HOT_HOURS
    else
        modData.sausage, modData.noHot = true, true
    end
    modData.smokeNeed = F.SMOKED_SAUSAGE_HOURS
    modData.stackId = now
    local daysLeft = 0
    for i = 0, links:size() - 1 do
        local link = links:get(i)
        daysLeft = math.max(daysLeft, link:getOffAge() - link:getAge())
    end
    modData.staleAt = now + daysLeft * 24 / speed
end

-- The crafting window's time is the longer of the two: blood sausage's smoke, as if the fire burnt on a cool day
-- throughout (Smoked Sausage's hot run is a quarter of it).
Events.OnInitGlobalModData.Add(function()
    Weather.setRecipeHours("TraditionalPreservationFishMeat.HangSausageToSmoke", F.SMOKED_SAUSAGE_HOURS,
        "TraditionalPreservationFishMeat")
end)

-- The stack's kind is its links' (one kind to a stack, F.hangKind): Fresh Sausage takes the hot run.
function F.sausageKind(links)
    return links:size() > 0 and links:get(0):getFullType() == F.FRESH_SAUSAGE and "pork" or nil
end

function F.onSausageSmokeStart(craftRecipeData)
    local links = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    F.startSausageSmoke(craftRecipeData:getModData(), links, getGameTime():getWorldAgeHours(), FluidAgeing.foodRotSpeed(),
        F.sausageKind(links))
end

-- A sausage stack's smoke so far and its need: the cold counter for blood sausage, the hot run for Smoked Sausage
-- (a broken run starts it again, F.smokeStep).
function F.sausageSmoke(modData)
    if modData.sausage == "pork" then return modData.hot or 0, modData.hotNeed or F.SAUSAGE_HOT_HOURS end
    return modData.cold or 0, F.coldNeed(modData)
end

-- Notes the hour the smoke was done. A catch-up after time away adds many hours at once, so the hour is placed
-- within the stretch since the last look by the share of the smoke still needed then.
function F.sausageSmokeStep(modData, now)
    local smoke, need = F.sausageSmoke(modData)
    if not modData.smokedAt and smoke >= need then
        local before, at = modData.seenCold or 0, modData.seenAt or modData.stackId or now
        -- A hot run that broke off since started again from nothing.
        if before > smoke then before = 0 end
        local share = smoke > before and (need - before) / (smoke - before) or 1
        modData.smokedAt = at + (now - at) * math.max(0, math.min(share, 1))
    end
    modData.seenCold, modData.seenAt = smoke, now
end

-- The stack's bar, 0 to 1: its smoke so far, full once smoked or once every link went stale. It waits just short of
-- the end until the World has seen its shed since the load, so OnCreate can swap the outputs.
function F.sausageProgress(modData, now)
    local smoke, need = F.sausageSmoke(modData)
    local progress = modData.smokedAt and 1 or math.min(smoke / need, 1)
    if modData.staleAt and now >= modData.staleAt then progress = 1 end
    if progress >= 1 and not F.smokeStations[modData.stackId] then progress = F.SHED_WAIT end
    return progress
end

function F.onSausageSmokeUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.sausage then return end
    local now = getGameTime():getWorldAgeHours()
    F.sausageSmokeStep(modData, now)
    craftRecipeData:setElapsedTime(F.sausageProgress(modData, now) * craftRecipeData:getRecipe():getTime())
end

-- Hands a part-eaten link's share on to what it became.
local function keepShare(from, to)
    local share = F.shareLeft(from)
    if share >= 1 then return end
    to:setHungChange(to:getBaseHunger() * share)
    to:setCalories(to:getCalories() * share)
    to:setProteins(to:getProteins() * share)
    to:setLipids(to:getLipids() * share)
    to:setCarbohydrates(to:getCarbohydrates() * share)
    to:setActualWeight(to:getActualWeight() * share)
    to:setCustomWeight(true)
end

-- What one hung link comes down as, now: smoked if the smoke was done before it went stale, its age that share of
-- the smoked keeping plus the days since; otherwise the link it was (Boiled, or a raw Fresh Sausage), aged by the
-- days it hung. Either keeps its seasoning (TP Core's Season).
function F.smokedLink(link, modData, now, speed)
    local hung, smokedAt = modData.stackId or now, modData.smokedAt
    local pork = modData.sausage == "pork"
    local ageThen = link:getAge() + ((smokedAt or now) - hung) / 24 * speed
    local out
    local smoked = smokedAt and ageThen < link:getOffAge()
    if smoked then
        out = instanceItem(pork and F.SMOKED_SAUSAGE or F.SMOKED_BLOOD_SAUSAGE)
        out:setAge(ageThen / link:getOffAge() * out:getOffAge() + (now - smokedAt) / 24 * speed)
    else
        out = instanceItem(link:getFullType())
        out:setAge(link:getAge() + (now - hung) / 24 * speed)
    end
    -- A raw link that went off first comes down raw.
    out:setCooked(smoked or not pork)
    keepShare(link, out)
    Season.carry(link, out)
    return out
end

function F.onCreateSmokedSausage(craftRecipeData)
    local modData = craftRecipeData:getModData()
    local station = modData.stackId and F.smokeStations[modData.stackId]
    if modData.stackId then
        F.smokeStations[modData.stackId], F.stackStations[modData.stackId] = nil, nil
        F.hotStations[modData.stackId] = nil
    end
    if not station then
        -- Never seen by the World (it waits for that): at least the script's links are cooked.
        local created = craftRecipeData:getAllCreatedItems()
        for i = 0, created:size() - 1 do created:get(i):setCooked(true) end
        return
    end
    local now, speed = getGameTime():getWorldAgeHours(), FluidAgeing.foodRotSpeed()
    F.swapOutputs(craftRecipeData, station, function(link) return F.smokedLink(link, modData, now, speed) end)
end

-- What a sausage stack's popup and the station's info say: its bar, the smoke against the need, what the fire is
-- doing for it (a key: Smoking, TooWarm or NoFire for blood; Cooking, Banked or NoFire for Smoked Sausage, whose
-- hot run ignores the weather), and the days its freshest link has left before it goes stale (nil once smoked).
function F.sausageStatus(modData, ledger, now)
    local state = "NoFire"
    local smoke, need = F.sausageSmoke(modData)
    if modData.sausage == "pork" then
        if modData.burning == Hearth.STOKED then
            state = "Cooking"
        elseif modData.burning then
            state = "Banked"
        end
    elseif modData.burning and (ledger.temperature or 0) > F.COLD_SMOKE_MAX then
        state = "TooWarm"
    elseif modData.burning then
        state = "Smoking"
    end
    local staleDays = not modData.smokedAt and modData.staleAt and math.max(0, (modData.staleAt - now) / 24) or nil
    return { progress = F.sausageProgress(modData, now), cold = smoke, need = need, hot = modData.sausage == "pork",
        state = state, staleDays = staleDays }
end
