-- Traditional Preservation (Fish & Meat): Potted Meat (ROADMAP §7, phase 4). Kavurma, meso u masti and confit in
-- English: cuts cooked slowly in Lard or Tallow with salt, packed into a clay jar or pot and sealed under the fat.
-- A pot takes a cut, a block of fat (or a pot of melted fat, 0.5 L, the same block) and salt, and up to three more
-- cuts (Add Meat to the Pot: hand crafts can't take a varying count); cooked on any stove or fire it can burn, and packed it gives a Crock of Potted Meat of a portion a cut, which is eaten from as
-- Dairy's Jar of Yogurt is: vanilla's Eat, Eat Half and Eat Quarter take portions, and the last bite gives the
-- jar or pot back.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Portions = require "TraditionalPreservationCore/Portions"
local Recipes = require "TraditionalPreservationCore/Recipes"

-- Pork joins the Salting Tub's cuts here: kept under fat and out of the sun, its own fat doesn't go rancid.
-- Chicken, turkey and rabbit too (user, 2026-11-13): kept alive and eaten fresh, they were rarely salted or dried,
-- but potted under fat (potted rabbit and chicken, rillettes de lapin, Gascon confit). A whole bird is cut first
-- (vanilla's Cut Chicken and Cut Turkey). Their food is vanilla's, rabbit's 969 calories too; mixed pots are fine.
F.POTTED_GAME = { "Base.Chicken", "Base.ChickenWings", "Base.ChickenFillet", "Base.TurkeyLegs", "Base.TurkeyWings",
    "Base.TurkeyFillet", "Base.Rabbitmeat" }
F.POTTED_CUTS = {
    ["Base.Beef"] = true, ["Base.Steak"] = true, ["Base.MuttonChop"] = true, ["Base.Venison"] = true,
    ["Base.Pork"] = true, ["Base.PorkChop"] = true,
}
for _, cut in ipairs(F.POTTED_GAME) do F.POTTED_CUTS[cut] = true end
F.POTTED_FATS = { ["Base.Lard"] = true, ["TraditionalPreservationFishMeat.Tallow"] = true }
F.MEAT_FAT_POTS = {
    ["TraditionalPreservationFishMeat.PotOfMeatInFat"] = true,
    ["TraditionalPreservationFishMeat.PotForgedMeatInFat"] = true,
}
F.CROCK = "TraditionalPreservationFishMeat.CrockOfPottedMeat"
-- A block of fat covers POTTED_MAX cuts, about 1 fat to 3 or 4 meat by weight with what the meat gives itself.
-- A clay jar (2.5 L) holds about that much. A smaller batch leaves the rest of the block in the pot's fat.
F.POTTED_MAX = 4
-- A full block's food, for the melted fat, which has none of its own (vanilla Lard's and our Tallow's; hunger as
-- the engine keeps it, -24 in the script).
F.FAT_BLOCK = { hunger = -0.24, calories = 4095, carbohydrates = 0, lipids = 454, proteins = 0 }
F.FAT_BLOCK_WEIGHT = 0.3
-- Meat loses about a third of its weight in the pot; its food stays.
F.POTTED_WEIGHT = 0.67
-- The vessels, with the icon and model index each gives the crock (IconsForTexture, WorldStaticModelsByIndex).
-- A Clay Pot shares vanilla's unglazed jar icon, so it looks like one.
F.POTTED_VESSELS = { ["Base.ClayJar"] = 0, ["Base.ClayJarGlazed"] = 1, ["Base.ClayPot"] = 0 }
F.POTTED_XP = 3                 -- Cooking, per cut packed
-- Under this many portions a crock counts as eaten out (the engine keeps hunger as a 32-bit float).
F.POTTED_EMPTY = 0.05

-- A food's values, or a share of them.
local function foodOf(item, share)
    share = share or 1
    return {
        hunger = item:getHungChange() * share, calories = item:getCalories() * share,
        carbohydrates = item:getCarbohydrates() * share, lipids = item:getLipids() * share,
        proteins = item:getProteins() * share,
    }
end

local function addFood(total, food)
    for key, value in pairs(food) do total[key] = (total[key] or 0) + value end
end


-- A pot of meat in fat keeps its batch in modData tpfmPotted: { portions = cuts in, food = all of it, weight = all of
-- it, fat = a full block's food, blocks = blocks of fat still free }. Each cut takes its own food and a quarter
-- block of the fat's (what a part-used block has left, if less); a smaller batch leaves the rest in the pot's fat.

-- A new batch from the fat: a block (a food item, maybe part-used) or nil for a pot of melted fat, a whole block.
function F.newPottedBatch(fat)
    local batch = { portions = 0, food = {}, weight = 0, fat = F.FAT_BLOCK, blocks = 1 }
    if fat then
        local left = fat:getHungChange() / F.FAT_BLOCK.hunger
        batch.blocks = math.max(0, math.min(left, 1))
        if left > 0 then batch.fat = foodOf(fat, 1 / left) end
    end
    return batch
end

-- Adds a cut (a food item) to a batch.
function F.addPottedCut(batch, cut)
    local blocks = math.min(1 / F.POTTED_MAX, batch.blocks)
    batch.blocks = batch.blocks - blocks
    addFood(batch.food, foodOf(cut))
    for key, value in pairs(batch.fat) do batch.food[key] = (batch.food[key] or 0) + value * blocks end
    batch.weight = batch.weight + cut:getActualWeight() * F.POTTED_WEIGHT + F.FAT_BLOCK_WEIGHT * blocks
    batch.portions = batch.portions + 1
end

-- One portion's food and weight in a batch.
function F.pottedPortion(batch)
    local portion = {}
    for key, value in pairs(batch.food) do portion[key] = value / batch.portions end
    return portion, batch.weight / batch.portions
end

-- The pot takes the batch's food (it can't be eaten, but its food shows what the crock will hold).
local function setPot(pot, batch)
    pot:getModData().tpfmPotted = batch
    Portions.set(pot, (F.pottedPortion(batch)), batch.portions, batch.portions)
end

local consumed = Recipes.consumed

local function createdPots(craftRecipeData)
    return Recipes.created(craftRecipeData, F.MEAT_FAT_POTS)
end

-- OnCreate of Put Meat in Lard, Put Meat in Tallow and Put Meat in the Melted Fat: a new batch of one cut.
function F.onPutMeatInFat(craftRecipeData)
    local batch = F.newPottedBatch(consumed(craftRecipeData, F.POTTED_FATS)[1])
    for _, cut in ipairs(consumed(craftRecipeData, F.POTTED_CUTS)) do F.addPottedCut(batch, cut) end
    for _, pot in ipairs(createdPots(craftRecipeData)) do setPot(pot, batch) end
end

-- OnTest of Add Meat to the Pot: an uncooked pot with room for another cut.
function F.canAddPottedCut(item)
    if not F.MEAT_FAT_POTS[item:getFullType()] then return true end
    local batch = item:getModData().tpfmPotted
    return batch ~= nil and batch.portions < F.POTTED_MAX and not item:isCooked() and not item:isBurnt()
end

-- OnCreate of Add Meat to the Pot: the pot comes back as itself (sameItem) with the cut added.
function F.onAddPottedCut(craftRecipeData)
    local pot = consumed(craftRecipeData, F.MEAT_FAT_POTS)[1]
    local batch = pot and pot:getModData().tpfmPotted
    if not batch then return end
    for _, cut in ipairs(consumed(craftRecipeData, F.POTTED_CUTS)) do F.addPottedCut(batch, cut) end
    for _, made in ipairs(createdPots(craftRecipeData)) do
        made:setAge(pot:getAge())
        made:setCondition(pot:getCondition())
        setPot(made, batch)
    end
end

-- OnTest of Pack Potted Meat: the recipe's cooked-food flag lets burnt food through, and burnt meat packs nothing.
function F.canPackPotted(item)
    if not F.MEAT_FAT_POTS[item:getFullType()] then return true end
    return not item:isBurnt() and item:getModData().tpfmPotted ~= nil
end

-- The portions left in a Crock of Potted Meat.
function F.crockPortions(crock)
    local portion = crock:getModData().tpfmPortion
    if not portion or portion.hunger == 0 then return 0 end
    return crock:getHungChange() / portion.hunger
end

-- The crock's plain name (user, 2026-11-13: it eats like any food, so no portion count; a crock from an older
-- build loses its "(3 portions)"), and the weight of the vessel and what is left in it.
function F.labelCrock(crock)
    local data = crock:getModData()
    crock:setName(getItemNameFromFullType(F.CROCK))
    crock:setCustomName(false)
    Portions.weigh(crock, F.crockPortions(crock), data.tpfmVessel or "Base.ClayJar", data.tpfmPortionWeight or 0)
end

-- A new crock: the pot's batch in the vessel (a full type).
function F.fillCrock(crock, batch, vessel)
    local data = crock:getModData()
    data.tpfmVessel = vessel
    data.tpfmPortion, data.tpfmPortionWeight = F.pottedPortion(batch)
    crock:setModelIndex(F.POTTED_VESSELS[vessel] or 0)
    Portions.set(crock, data.tpfmPortion, batch.portions, batch.portions)
    crock:setAge(0)
    F.labelCrock(crock)
end

-- OnCreate of Pack Potted Meat: the crock from the cooked pot's batch and the vessel that went in.
function F.onPackPotted(craftRecipeData, character)
    character = character or craftRecipeData:getCharacter()
    local used = craftRecipeData:getAllConsumedItems()
    local batch, vessel
    for i = 0, used:size() - 1 do
        local item = used:get(i)
        local fullType = item:getFullType()
        if F.MEAT_FAT_POTS[fullType] then batch = item:getModData().tpfmPotted end
        if F.POTTED_VESSELS[fullType] then vessel = fullType end
    end
    if not batch then return end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local crock = created:get(i)
        if crock:getFullType() == F.CROCK then F.fillCrock(crock, batch, vessel or "Base.ClayJar") end
    end
    if character and addXp then addXp(character, Perks.Cooking, F.POTTED_XP * batch.portions) end
end

-- A crock with no batch of its own (the debug Item List, loot, another mod) holds what its script gives: one
-- portion, in a plain Clay Jar. That is written down the first time it is eaten, so it eats and labels as a packed
-- one; without it the portions left read 0 and the first bite threw the rest away.
function F.adoptCrock(crock)
    local data = crock:getModData()
    if data.tpfmPortion then return end
    data.tpfmVessel = data.tpfmVessel or "Base.ClayJar"
    data.tpfmPortion = { hunger = crock:getHungChange(), calories = crock:getCalories(),
        carbohydrates = crock:getCarbohydrates(), lipids = crock:getLipids(), proteins = crock:getProteins() }
    local empty = ScriptManager.instance:getItem(data.tpfmVessel)
    data.tpfmPortionWeight = math.max(crock:getActualWeight() - (empty and empty:getActualWeight() or 0), 0)
end

-- After any eat: an emptied crock goes back to its container as its jar or pot; one with meat left is weighed again.
-- Returns the empty vessel, if any.
function F.afterCrockUse(crock, container)
    return Portions.used(crock, container, function() return F.crockPortions(crock) >= F.POTTED_EMPTY end,
        crock:getModData().tpfmVessel or "Base.ClayJar", F.labelCrock)
end

-- Keeping by place (4c). The crock's script days (60 fresh, 90 to rotten) are a cellar's, so a day at the cellar's
-- 15 C counts as a day of age; a fridge (4 C) or a cold month counts half (120 / 180), a warm room up to 60/14
-- (14 / 21 at 25 C and up); a room goes by the season's mean (F.pottedTemperature). Modern advice is under 4 C and about three months; the cold figure follows cellar
-- practice. A crock carries its own clock in modData tpfmKeep = { base = its age when the clock started, record = a
-- FluidAgeing record (kind potted) on the mod's potted ledger }, so one left in a basement for a month catches up
-- when it is next seen: its age is base plus the record's hours. A powered freezer stops it. Vanilla ages it between
-- looks at its own rate; each look puts that right.
-- Frozen (realism pass, user 2026-11-13) it keeps as in a freezer: from 0.5 at 4 C down to nothing at -2 C.
F.POTTED_KEEPING = { { -2, 0 }, { 4, 0.5 }, { 15, 1 }, { 25, 60 / 14 } }
-- The first portion taken lets air under the fat: a third of the keeping left goes, once.
F.POTTED_OPENED_LOSS = 1 / 3
F.POTTED_LEDGER_KEY = "TraditionalPreservationFishMeatPotted"
-- Vanilla's Food Spoilage sandbox steps (Food.getFoodRotSpeed: very fast to very slow).
local ROT_SPEEDS = { 1.7, 1.4, 1, 0.7, 0.4 }

local function keepRate(celsius)
    return Weather.curve(F.POTTED_KEEPING, celsius)
end
local POTTED_KINDS = { potted = keepRate }
F.POTTED_KEEP = {
    kind = "potted", rate = keepRate,
    speed = function() return ROT_SPEEDS[SandboxVars and SandboxVars.FoodRotSpeed] or 1 end,
}

-- The sandbox's "Potted Meat keeps by place"; off, a crock keeps its script days anywhere, as plain food.
function F.pottedByPlace()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    return not options or options.PottedByPlace ~= false
end

function F.newPottedLedger(now)
    return Weather.newLedger(now, POTTED_KINDS)
end

function F.pottedLedger()
    return Weather.getLedger(F.POTTED_LEDGER_KEY, F.newPottedLedger)
end

-- A crock's temperature at a Weather place: Weather's own (a room or an open roof is the season's mean).
function F.pottedTemperature(ledger, place)
    return Weather.placeTemperature(ledger, place)
end

-- Adds a stretch of weather to the potted ledger (every ten minutes), as Weather.advance does but with
-- F.pottedTemperature.
function F.recordPotted(now, temperature)
    local ledger = F.pottedLedger()
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now
    Weather.season(ledger, "seasonTemperature", temperature, hours)
    ledger.temperature = temperature
    for _, place in ipairs(Weather.PLACES) do
        local rate = keepRate(F.pottedTemperature(ledger, place))
        ledger["potted" .. place .. "Rate"] = rate
        ledger["potted" .. place] = (ledger["potted" .. place] or 0) + rate * hours
    end
end

-- How fast a crock keeps at a place now: FluidAgeing's place names (Fridge, Freezer, or a Weather place).
function F.pottedRate(place, ledger)
    if place == FluidAgeing.FREEZER then return 0 end
    if place == FluidAgeing.FRIDGE then return keepRate(FluidAgeing.FRIDGE_C) end
    return keepRate(F.pottedTemperature(ledger or F.pottedLedger(), place or "Sheltered"))
end

-- Brings a crock's age up to now at the place it was seen in last, and counts from where it is now (place, or
-- where the crock is). The first look starts its clock. Returns its tpfmKeep, or nil with keeping by place off.
function F.keepCrock(crock, now, place, ledger)
    if not F.pottedByPlace() then return nil end
    now = now or getGameTime():getWorldAgeHours()
    ledger = ledger or F.pottedLedger()
    local data = crock:getModData()
    local keep = data.tpfmKeep
    place = place or FluidAgeing.placeOfItem(crock) or (keep and keep.record.place) or "Sheltered"
    if not keep then
        keep = { base = crock:getAge(), record = FluidAgeing.newRecord(F.POTTED_KEEP, ledger, now, place) }
        data.tpfmKeep = keep
        return keep
    end
    FluidAgeing.advance(keep.record, F.POTTED_KEEP, ledger, now, place)
    crock:setAge(keep.base + keep.record.age / 24)
    return keep
end

-- Every crock in an item container (and the bags in it).
function F.keepCrocksIn(container, now)
    local crocks = container and container:getAllTypeRecurse(F.CROCK)
    for i = 0, crocks and crocks:size() - 1 or -1 do F.keepCrock(crocks:get(i), now) end
end

-- The first portion taken: a third of what the crock has left until stale (or, stale already, until rotten) goes.
function F.openCrock(crock)
    local data = crock:getModData()
    if data.tpfmOpened then return end
    data.tpfmOpened = true
    local keep = F.keepCrock(crock)
    if not keep then return end
    local age = crock:getAge()
    local limit = age < crock:getOffAge() and crock:getOffAge() or crock:getOffAgeMax()
    keep.record.age = keep.record.age + math.max(limit - age, 0) * F.POTTED_OPENED_LOSS * 24
    crock:setAge(keep.base + keep.record.age / 24)
end

-- Eaten through vanilla's eat action (TP Core's Portions, the one wrap of it, which Dairy's jar uses too): the crock's
-- keeping is brought up to now first; a first portion taken opens it; then it is weighed again or gives its vessel back.
Portions.onEat(F.CROCK, function(crock)
    F.adoptCrock(crock)
    local before = F.crockPortions(crock)
    F.keepCrock(crock)
    return before
end, function(crock, container, before)
    if F.crockPortions(crock) < before then F.openCrock(crock) end
    F.afterCrockUse(crock, container)
end)
