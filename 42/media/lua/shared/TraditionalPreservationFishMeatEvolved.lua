-- Traditional Preservation (Fish & Meat): a dish's ingredient list stores item types, and its tooltip makes a
-- fresh item of each type every frame to draw the icon. A fish stage picks a random species model when
-- made, so its icon would change every frame. After a fish stage goes into a dish, the list records a
-- single-icon stand-in for that stage instead, which names the dish the same way.
require "TimedActions/ISAddItemInRecipe"

TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

F.INGREDIENT_STANDINS = {
    ["TraditionalPreservationFishMeat.SaltDriedFish"] = "TraditionalPreservationFishMeat.SaltDriedFishIngredient",
    ["TraditionalPreservationFishMeat.SoakedSaltFish"] = "TraditionalPreservationFishMeat.SoakedSaltFishIngredient",
    ["TraditionalPreservationFishMeat.GuttedFish"] = "TraditionalPreservationFishMeat.GuttedFishIngredient",
    ["TraditionalPreservationFishMeat.FishHalf"] = "TraditionalPreservationFishMeat.FishHalfIngredient",
    ["TraditionalPreservationFishMeat.SoakedColdFish"] = "TraditionalPreservationFishMeat.SoakedColdFishIngredient",
    ["TraditionalPreservationFishMeat.SoakedCharque"] = "TraditionalPreservationFishMeat.SoakedCharqueIngredient",
    ["TraditionalPreservationFishMeat.HotSmokedFish"] = "TraditionalPreservationFishMeat.HotSmokedFishIngredient",
    ["TraditionalPreservationFishMeat.HotSmokedMeat"] = "TraditionalPreservationFishMeat.HotSmokedMeatIngredient",
    ["TraditionalPreservationFishMeat.ColdSmokedFish"] = "TraditionalPreservationFishMeat.ColdSmokedFishIngredient",
    ["TraditionalPreservationFishMeat.DryCuredMeat"] = "TraditionalPreservationFishMeat.DryCuredMeatIngredient",
}

-- Swaps every fish stage in a dish's list for its stand-in.
function F.useStandins(dish)
    local extras = dish and dish:getExtraItems()
    if not extras then return end
    for i = 0, extras:size() - 1 do
        local standin = F.INGREDIENT_STANDINS[extras:get(i)]
        if standin then extras:set(i, standin) end
    end
end

-- Meat stages are one item for every animal, so vanilla would name every dish with them after the script's "Beef".
-- Once a piece goes in, its entry becomes the stand-in of its stage and animal (tools/build_standins.py), which has
-- vanilla's food type and name for that animal, and the dish is named again: "Venison Stew" (realism pass, user
-- 2026-11-13). The animal is the piece's MEAT_CUTS index (a slice's is its modData.cut). Pairs the game can't make,
-- and a piece with no cut, keep the stage's own stand-in. Dry cured meat that had its smoke (not airDried) takes a
-- Cold Smoked stand-in, so the dish lists it as its name says: "Beef (Cold Smoked)".
F.ANIMAL_STAGES = { HotSmokedMeat = true, DryCuredMeat = true, SoakedCharque = true, HotSmokedMeatSlice = true,
    DryCuredMeatSlice = true }
local COLD_SMOKED = { DryCuredMeat = "ColdSmokedMeat", DryCuredMeatSlice = "ColdSmokedMeatSlice" }

-- The stand-in for this piece's stage and animal, or nil. airDried: a dry cured piece's modData.airDried.
function F.standinFor(fullType, index, airDried)
    local animal = index and F.MEAT_ANIMALS[index + 1]
    local stage = fullType and fullType:match("^TraditionalPreservationFishMeat%.(.+)$")
    if not animal or not stage or not F.ANIMAL_STAGES[stage] then return nil end
    if not airDried and COLD_SMOKED[stage] then stage = COLD_SMOKED[stage] end
    local standin = "TraditionalPreservationFishMeat." .. stage .. "Ingredient_" .. animal
    if getScriptManager and not getScriptManager():FindItem(standin) then return nil end
    return standin
end

-- The piece's cut: its model index or, for a slice, the piece it was cut from.
local function cutOf(item)
    if not item then return nil end
    local stage = F.STAGES and F.STAGES[item:getFullType()]
    if stage and stage.slice then return item:getModData().cut end
    local index = item:getModelIndex()
    return index >= 0 and index or nil
end

-- Swaps the newest entry of fullType in the dish's list for standin; true if one was found.
function F.useAnimalStandin(dish, fullType, standin)
    local extras = dish and dish:getExtraItems()
    if not extras or not standin then return false end
    for i = extras:size() - 1, 0, -1 do
        if extras:get(i) == fullType then
            extras:set(i, standin)
            return true
        end
    end
    return false
end

-- Once vanilla has added an ingredient, its list entry is swapped for the stand-in (see the top).
local vanillaComplete = ISAddItemInRecipe.complete

function ISAddItemInRecipe:complete()
    local stock = self.baseItem
    local used = self.usedItem
    local usedType = used and used:getFullType()
    local animalStandin = F.standinFor(usedType, cutOf(used), used and used:getModData().airDried)
    local result = vanillaComplete(self)
    F.carryStock(stock, self.baseItem, self.recipe)
    local renamed = F.useAnimalStandin(self.baseItem, usedType, animalStandin)
    F.useStandins(self.baseItem)
    if renamed and not self.baseItem:isCustomName() then ISAddItemInRecipe.checkName(self.baseItem, self.recipe) end
    return result
end

-- A stock's soup or stew is named "Fish Head Soup with Fish and Carrots" rather than vanilla's "Fish Fish
-- Head Soup". The rules are vanilla's: each food type is named by its first ingredient, or by the type once
-- two different ones share it; more than MAX_NAMED kinds of food give just the dish, and seasonings are named
-- only while the total stays within it. What the stock started with isn't named: the first Fish Head, and
-- every part in F.STOCK_PARTS. F.STOCK_POTS gives each stock's plain name, F.STOCK_DISHES each dish's.
F.STOCK_POTS = {
    ["TraditionalPreservationFishMeat.PotOfFishHeadStock"] = "FishHeadStock",
    ["TraditionalPreservationFishMeat.PotForgedFishHeadStock"] = "FishHeadStock",
    ["TraditionalPreservationFishMeat.PotOfBoneBroth"] = "BoneBroth",
    ["TraditionalPreservationFishMeat.PotForgedBoneBroth"] = "BoneBroth",
    ["TraditionalPreservationFishMeat.PotOfChickenStock"] = "ChickenStock",
    ["TraditionalPreservationFishMeat.PotForgedChickenStock"] = "ChickenStock",
}
F.STOCK_DISHES = {}
for _, kind in ipairs({ "FishHead", "BoneBroth", "Chicken" }) do
    for _, dish in ipairs({ "Soup", "Stew" }) do
        for _, pot in ipairs({ "PotOf", "PotForged" }) do
            F.STOCK_DISHES["TraditionalPreservationFishMeat." .. pot .. kind .. dish] = kind .. dish
        end
    end
end

-- Vanilla's addItem makes a stock's first soup or stew a fresh pot: the stock's food comes with it, but its
-- unhappiness and boredom are zeroed and its listed parts dropped. They go back on here, the parts first so
-- the naming skips them, and the dish is named again with them in place.
function F.carryStock(stock, dish, recipe)
    if not (stock and dish) or stock == dish or not F.STOCK_POTS[stock:getFullType()] then return end
    dish:setUnhappyChange(dish:getUnhappyChangeUnmodified() + stock:getUnhappyChangeUnmodified())
    dish:setBoredomChange(dish:getBoredomChangeUnmodified() + stock:getBoredomChangeUnmodified())
    local parts = stock:getExtraItems()
    if parts and parts:size() > 0 then
        local added = {}
        local extras = dish:getExtraItems()
        if extras then
            for i = 0, extras:size() - 1 do table.insert(added, extras:get(i)) end
            extras:clear()
        end
        for i = 0, parts:size() - 1 do dish:addExtraItem(parts:get(i)) end
        for _, fullType in ipairs(added) do dish:addExtraItem(fullType) end
    end
    if not dish:isCustomName() then ISAddItemInRecipe.checkName(dish, recipe) end
end

local MAX_NAMED = 3
local HEAD = "TraditionalPreservationFishMeat.FishHead"

local function namedKinds(list, skipHead, withMinor)
    local names, byType, order, plain = {}, {}, {}, nil
    local skipParts = skipHead
    for i = 0, list:size() - 1 do
        local food = list:get(i)
        if skipHead and food == HEAD then
            skipHead = false
        elseif skipParts and F.STOCK_PARTS and F.STOCK_PARTS[food] then
            -- a starting part of a Chicken Stock
        elseif isItemFood(food) and (withMinor or not hasItemTag(food, ItemTag.MINOR_INGREDIENT)) then
            local foodType = getItemFoodType(food)
            if not foodType or foodType == "NoExplicit" then
                if #order == 0 and not plain then plain = getItemDisplayName(food) end
            else
                local typeName = getText("ContextMenu_FoodType_" .. foodType)
                local name = getItemEvolvedRecipeName(food) or getItemDisplayName(food)
                if not byType[typeName] then
                    byType[typeName] = name
                    table.insert(order, typeName)
                elseif byType[typeName] ~= getItemDisplayName(food) then
                    byType[typeName] = typeName
                end
            end
        end
    end
    for _, typeName in ipairs(order) do table.insert(names, byType[typeName]) end
    if #names == 0 and plain then names[1] = plain end
    return names
end

local function joined(names)
    local text = ""
    for index, name in ipairs(names) do
        if index == 1 then
            text = name
        elseif index == #names then
            text = text .. " " .. getText("ContextMenu_EvolvedRecipe_and") .. " " .. name
        else
            text = text .. getText("ContextMenu_EvolvedRecipe_comma") .. " " .. name
        end
    end
    return text
end

-- "Fish Head Stock with carrot and onion": the dish plus what went in, spices only if there's room.
-- Nil to keep vanilla's name. Too many kinds to name gives the plain dish.
function F.stockName(stock, recipe)
    local dish = getText("ContextMenu_EvolvedRecipe_" .. recipe:getUntranslatedName())
    local names = stock:getExtraItems() and namedKinds(stock:getExtraItems(), true, true) or {}
    if #names > MAX_NAMED then return dish end
    if stock:getSpices() then
        local spices = namedKinds(stock:getSpices(), false, false)
        if #names + #spices <= MAX_NAMED then
            for _, name in ipairs(spices) do table.insert(names, name) end
        end
    end
    if #names == 0 then return nil end
    return getText("IGUI_TraditionalPreservationFishMeat_StockWith", dish, joined(names))
end

-- A stock's soup or stew is named by stockName instead of vanilla's rule; other dishes pass through.
-- Wraps ISAddItemInRecipe.checkName: compare with vanilla after a game update.
local vanillaCheckName = ISAddItemInRecipe.checkName

ISAddItemInRecipe.checkName = function(baseItem, recipe)
    if not (baseItem and (F.STOCK_POTS[baseItem:getFullType()] or F.STOCK_DISHES[baseItem:getFullType()])) or baseItem:isCustomName() then
        return vanillaCheckName(baseItem, recipe)
    end
    local name = F.stockName(baseItem, recipe)
    if name then baseItem:setName(name) end
    if not isServer() then ISInventoryPage.dirtyUI() end
end

-- Vanilla's inheritFoodNameBowl names a bowl after the pot, so a stock with nothing added gave "Bowl of Pot of
-- Bone Broth". The bowls are named after the dish instead: "Bowl of Bone Broth", "Bowl of Bone Broth Soup with
-- Carrots".
function F.onCreateStockBowls(craftRecipeData)
    local pot
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    for i = 0, inputs:size() - 1 do
        local fullType = inputs:get(i):getFullType()
        if F.STOCK_POTS[fullType] or F.STOCK_DISHES[fullType] then pot = inputs:get(i) end
    end
    if not pot then return end
    local dish = pot:getDisplayName()
    if dish == getItemNameFromFullType(pot:getFullType()) then
        dish = getText("ContextMenu_EvolvedRecipe_" .. (F.STOCK_POTS[pot:getFullType()] or F.STOCK_DISHES[pot:getFullType()]))
    end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local bowl = created:get(i)
        if bowl:getFullType() ~= "Base.Pot" and bowl:getFullType() ~= "Base.PotForged" then
            bowl:setName(getText("Tooltip_food_Bowl", dish))
            bowl:setCustomName(true)
        end
    end
end
