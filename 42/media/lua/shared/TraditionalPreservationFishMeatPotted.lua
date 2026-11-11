-- Traditional Preservation (Fish & Meat): Potted Meat (ROADMAP §7, phase 4). Kavurma, meso u masti and confit in
-- English: cuts cooked slowly in Lard or Tallow with salt, packed into a clay jar or pot and sealed under the fat.
-- A pot takes a cut, a block of fat (or a pot of melted fat, 0.5 L, the same block) and salt, and up to three more
-- cuts (Add Meat to the Pot: hand crafts can't take a varying count); cooked on any stove or fire it can burn, and packed it gives a Crock of Potted Meat of a portion a cut, which is eaten from as
-- Dairy's Jar of Yoghurt is: vanilla's Eat, Eat Half and Eat Quarter take portions, and the last bite gives the
-- jar or pot back.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- Pork joins the Salting Tub's cuts here: kept under fat and out of the sun, its own fat doesn't go rancid.
F.POTTED_CUTS = {
    ["Base.Beef"] = true, ["Base.Steak"] = true, ["Base.MuttonChop"] = true, ["Base.Venison"] = true,
    ["Base.Pork"] = true, ["Base.PorkChop"] = true,
}
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

-- Sets a food item's values to portions of one portion's food p; full is the portions it was made with.
local function setPortions(food, portions, full, p)
    food:setHungChange(p.hunger * portions)
    food:setBaseHunger(p.hunger * full)
    food:setCalories(p.calories * portions)
    food:setCarbohydrates(p.carbohydrates * portions)
    food:setLipids(p.lipids * portions)
    food:setProteins(p.proteins * portions)
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
    setPortions(pot, batch.portions, batch.portions, (F.pottedPortion(batch)))
end

local function consumed(craftRecipeData, set)
    local used, found = craftRecipeData:getAllConsumedItems(), {}
    for i = 0, used:size() - 1 do
        if set[used:get(i):getFullType()] then table.insert(found, used:get(i)) end
    end
    return found
end

local function createdPots(craftRecipeData)
    local created, pots = craftRecipeData:getAllCreatedItems(), {}
    for i = 0, created:size() - 1 do
        if F.MEAT_FAT_POTS[created:get(i):getFullType()] then table.insert(pots, created:get(i)) end
    end
    return pots
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

-- "Crock of Potted Meat (3 portions)", and the weight of the vessel and what is left in it.
function F.labelCrock(crock)
    local data = crock:getModData()
    local left = F.crockPortions(crock)
    local text = string.format("%.1f", left):gsub("%.0$", "")
    local base = getItemNameFromFullType(F.CROCK)
    crock:setName(getText(text == "1" and "IGUI_TraditionalPreservationFishMeat_CrockOnePortion"
        or "IGUI_TraditionalPreservationFishMeat_CrockPortions", base, text))
    crock:setCustomName(true)
    local empty = ScriptManager.instance:getItem(data.tpfmVessel or "Base.ClayJar")
    crock:setActualWeight((empty and empty:getActualWeight() or 0) + left * (data.tpfmPortionWeight or 0))
    -- The engine saves only a custom weight; without this a reloaded crock weighs a full one again.
    crock:setCustomWeight(true)
end

-- A new crock: the pot's batch in the vessel (a full type).
function F.fillCrock(crock, batch, vessel)
    local data = crock:getModData()
    data.tpfmVessel = vessel
    data.tpfmPortion, data.tpfmPortionWeight = F.pottedPortion(batch)
    crock:setModelIndex(F.POTTED_VESSELS[vessel] or 0)
    setPortions(crock, batch.portions, batch.portions, data.tpfmPortion)
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

-- After any eat: an emptied crock goes back to its container as its jar or pot; one with meat left is relabelled.
-- Returns the empty vessel, if any.
function F.afterCrockUse(crock, container)
    if container and container:contains(crock) and F.crockPortions(crock) >= F.POTTED_EMPTY then
        F.labelCrock(crock)
        return nil
    end
    if container and container:contains(crock) then container:DoRemoveItem(crock) end
    local target = container or crock:getContainer()
    return target and target:AddItem(crock:getModData().tpfmVessel or "Base.ClayJar")
end

local function wrapEat(name)
    local original = ISEatFoodAction[name]
    ISEatFoodAction[name] = function(self, ...)
        local crock = self.item and self.item:getFullType() == F.CROCK and self.item
        local container = crock and crock:getContainer()
        local result = original(self, ...)
        if crock then F.afterCrockUse(crock, container) end
        return result
    end
end

-- complete eats what was asked; serverStop eats the part done when the action is cut short. Outside the game
-- (tests) there is no eat action unless one is stubbed.
if ISEatFoodAction then
    wrapEat("complete")
    wrapEat("serverStop")
end
