-- Traditional Preservation (Fish): a dish's ingredient list stores item types, and its tooltip makes a
-- fresh item of each type every frame to draw the icon. A fish stage picks a random species model when
-- made, so its icon would change every frame. After a fish stage goes into a dish, the list records a
-- single-icon stand-in for that stage instead, which names the dish the same way.
require "TimedActions/ISAddItemInRecipe"

TraditionalPreservationFish = TraditionalPreservationFish or {}
local F = TraditionalPreservationFish

F.INGREDIENT_STANDINS = {
    ["TraditionalPreservationFish.SaltDriedFish"] = "TraditionalPreservationFish.SaltDriedFishIngredient",
    ["TraditionalPreservationFish.SoakedSaltFish"] = "TraditionalPreservationFish.SoakedSaltFishIngredient",
    ["TraditionalPreservationFish.GuttedFish"] = "TraditionalPreservationFish.GuttedFishIngredient",
    ["TraditionalPreservationFish.FishHalf"] = "TraditionalPreservationFish.FishHalfIngredient",
    ["TraditionalPreservationFish.SoakedColdFish"] = "TraditionalPreservationFish.SoakedColdFishIngredient",
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

local vanillaComplete = ISAddItemInRecipe.complete

function ISAddItemInRecipe:complete()
    local result = vanillaComplete(self)
    F.useStandins(self.baseItem)
    return result
end

-- Fish Head Stock is named "Fish Head Stock with Fish and Carrots" rather than vanilla's "Fish Fish
-- Head Stock". The rules are vanilla's: each food type is named by its first ingredient, or by the type
-- once two different ones share it; more than MAX_NAMED kinds of food give just "Fish Head Stock", and
-- seasonings are named only while the total stays within it. The head the stock started with isn't named.
F.STOCK_POTS = {
    ["TraditionalPreservationFish.PotOfFishHeadStock"] = true,
    ["TraditionalPreservationFish.PotForgedFishHeadStock"] = true,
}
local MAX_NAMED = 3
local HEAD = "TraditionalPreservationFish.FishHead"

local function namedKinds(list, skipHead, withMinor)
    local names, byType, order, plain = {}, {}, {}, nil
    for i = 0, list:size() - 1 do
        local food = list:get(i)
        if skipHead and food == HEAD then
            skipHead = false
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
    return getText("IGUI_TraditionalPreservationFish_StockWith", dish, joined(names))
end

local vanillaCheckName = ISAddItemInRecipe.checkName

ISAddItemInRecipe.checkName = function(baseItem, recipe)
    if not (baseItem and F.STOCK_POTS[baseItem:getFullType()]) or baseItem:isCustomName() then
        return vanillaCheckName(baseItem, recipe)
    end
    local name = F.stockName(baseItem, recipe)
    if name then baseItem:setName(name) end
    if not isServer() then ISInventoryPage.dirtyUI() end
end
