-- Traditional Preservation (Fish & Meat): starts showing a station's contents as soon as something goes in,
-- because one built this session hasn't been through the map loader. Also replaces vanilla's
-- free slot limit: a tub takes one batch at a time by weight, and a frame goes by stacks. The
-- same rules decide the slot's green border, so it never promises what adding then refuses.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Controls/ISItemSlot"
local UI = require "TraditionalPreservationCore/UI"
local Transfer = require "TraditionalPreservationCore/Transfer"
local Weather = require "TraditionalPreservationCore/Weather"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local F = TraditionalPreservationFishMeat

local FIRST_FRAME_SPRITE = Tiles.FRAME


local SALT_BADGE_SIZE = 14
local SALT_BADGE_MARGIN = 3

local spriteIndex = F.stationIndex

local function waitingWeight(resource)
    local weight = 0
    local stored = resource:getStoredItems()
    for i = 0, stored:size() - 1 do
        weight = weight + stored:get(i):getActualWeight()
    end
    return weight
end

-- queued lists the fish on their way in that the slot doesn't hold yet. slot.extra says it's a tub.
local function refusal(slot, item, queued)
    local entity, component, resource, isTub = slot.entity, slot.component, slot.resource, slot.extra
    local wrongFish = F.fishRefusal(isTub, item:getFullType())
    if wrongFish then return wrongFish end

    local weight = item:getActualWeight()
    local waiting = waitingWeight(resource)
    for _, fish in ipairs(queued) do waiting = waiting + fish:getActualWeight() end
    if isTub then
        if component:isRunning() then return "IGUI_TraditionalPreservationFishMeat_TubInUse" end
        -- This asks what is in the tub, because a tub keeps the slot counts it was built with.
        if TraditionalPreservationFishMeatWorld.busyStacks(entity) > 0 then return "IGUI_TraditionalPreservationFishMeat_TubNotEmpty" end
        local first = resource:getStoredItems():size() > 0 and resource:getStoredItems():get(0) or queued[1]
        local mixed = F.mixedTub(first and first:getFullType(), item:getFullType())
        if mixed then return mixed end
        if resource:getStoredItems():size() + #queued >= F.TUB_MAX_ITEMS
                or not F.hasRoom(F.TUB_CAPACITY, waiting, weight) then
            return "IGUI_TraditionalPreservationFishMeat_Full"
        end
        return nil
    end
    local stored = resource:getStoredItems()
    if stored:size() > 0 and F.hangKind(stored:get(0):getFullType()) ~= F.hangKind(item:getFullType()) then
        return "IGUI_TraditionalPreservationFishMeat_MixedStack"
    end
    local mixedMeat = stored:size() > 0 and F.mixedMeat(stored:get(0), item)
    if mixedMeat then return mixedMeat end
    local hanger = F.hangerOf(entity)
    local sausageRefused = F.sausageRefusal(hanger, item)
    if sausageRefused then return sausageRefused end
    local porkRefused = F.meatRefusal(hanger, hanger.closed and "Enclosed" or Weather.placeOf(entity), item)
    if porkRefused then return porkRefused end
    if F.hangKind(item:getFullType()) == "cold" then
        local coldRefused = F.coldRefusal(hanger.closed and "Enclosed" or Weather.placeOf(entity))
        if coldRefused then return coldRefused end
    end
    return F.frameRefusal(hanger, TraditionalPreservationFishMeatWorld.busyStacks(entity), waiting, weight,
        stored:size() + #queued)
end

-- A tub or a drying station, with whether it's a tub. Asking about one starts tracking it.
local function station(entity)
    if not F.isStation(entity) or not TraditionalPreservationFishMeatWorld then return nil end

    local index = spriteIndex(entity)
    local isTub = index ~= nil and index < FIRST_FRAME_SPRITE
    local component = entity:getComponent(isTub and ComponentType.CraftLogic or ComponentType.DryingCraftLogic)
    if not component then return nil end
    TraditionalPreservationFishMeatWorld.track(entity)
    return component, isTub
end

UI.slotRules{
    station = station,
    refusal = refusal,
    -- The short cure refuses a Leg of Pork, on the drop and again at Craft if the recipe changed after loading.
    recipeRefusal = function(slot, item) return F.recipeRefusal(slot.recipe, item) end,
    -- In TP Core's Smokehouse, only this mod's own items (another mod's cheese is its own to judge).
    owns = function(entity, item) return not Smokehouse.isChamber(entity) or F.ownsItem(item) end,
    -- What hangs there now, so the count of busy stacks is current.
    added = function(entity) TraditionalPreservationFishMeatWorld.refresh(entity) end,
}

local function timeText(hours)
    if not hours then return getText("IGUI_TraditionalPreservationFishMeat_Paused") end
    return UI.timeText(hours, "IGUI_TraditionalPreservationFishMeat_Time")
end

local METHODS = { salt = "IGUI_TraditionalPreservationFishMeat_MethodSalt", cold = "IGUI_TraditionalPreservationFishMeat_MethodCold",
    meat = "IGUI_TraditionalPreservationFishMeat_MethodCharque" }

-- Vanilla's popup goes by its own temperature curve and the recipe's time, so hanging stacks get
-- this instead. kind is F.hangKind's.
local function drawStackTooltip(slot, tooltip, kind)
    local ledger = F.getLedger()
    local isCold, isMeat = kind == "cold", kind == "meat"
    local status = isMeat and F.charqueStatus(slot.craftRecipeData:getModData(), ledger)
        or F.stackStatus(isCold, slot.craftRecipeData:getModData(), ledger)
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Method", getText(status.hotOnly and "IGUI_TraditionalPreservationFishMeat_MethodHotOnly"
            or status.dryCuring and "IGUI_TraditionalPreservationFishMeat_MethodDryCure" or METHODS[kind]))
        -- The recipe's output says Charque or Salt Dried whatever the stack is; this says what it is turning into.
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_ComesOutAs", F.stackOutcome(slot.craftRecipeData:getModData(),
            slot.craftRecipeData:getAllInputItemsWithFlag("ItemCount"), kind))
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_TimeLeft", timeText(status.hoursLeft))
        local modData = slot.craftRecipeData:getModData()
        local place = modData.inShed and "Enclosed" or modData.basement and "Basement" or modData.loft and "Loft"
            or modData.sheltered and "Sheltered" or modData.covered and "Covered" or "Open"
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Place", UI.placeName(place))
        -- A basement, loft, room or roofed stack dries by that place's temperature (Core's); the Smokehouse and the
        -- open air go by the day's.
        local own = place == "Basement" or place == "Loft" or place == "Sheltered" or place == "Covered"
        local celsius = own and F.ownTemperature(ledger, place) or ledger.temperature or 0
        local word = F.temperatureWord(isCold, celsius, place == "Open")
        if status.dryCuring or status.hotOnly then
            word = F.dryCureTemperatureWord(status.shedTemperature)
        elseif isMeat then
            word = F.charqueTemperatureWord(celsius)
        end
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Temperature", getText(word))
        if isCold or isMeat and not modData.sheltered and not status.dryCuring then UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Wind", getText(F.windWord(ledger.wind))) end
        -- Wetness is rain left on open frames: indoors (a room, the Smokehouse) none reaches the stack.
        if not modData.sheltered then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Wetness", UI.percent(isCold and ledger.coldWetness or ledger.wetness))
        end
        if status.reason then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Rate", getText("IGUI_TraditionalPreservationFishMeat_Stopped" .. status.reason), UI.SLOW_COLOUR)
        else
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Rate", UI.percent(status.rate))
        end
        -- In a Smokehouse joined to a Firebox: the stoked session's hours against the cook, and the smoke so far.
        if modData.smokeFrom and modData.hotNeed and not modData.noHot then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_HotSmoke", getText("IGUI_TraditionalPreservationFishMeat_HotSmokeHours",
                string.format("%.1f", modData.hot or 0), string.format("%.0f", modData.hotNeed)))
        end
        -- Smoke so far against the stack's need (F.smokeHours, by its heaviest piece), or why banked
        -- hours don't count today.
        if modData.hotOnly then
            -- Poultry and rabbit take no cold smoke.
        elseif modData.smokeFrom and (ledger.temperature or 0) > F.COLD_SMOKE_MAX then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_ColdSmoke", getText("IGUI_TraditionalPreservationFishMeat_ColdSmokeTooWarm"), UI.SLOW_COLOUR)
        elseif modData.smokeFrom or (modData.cold or 0) > 0 then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_ColdSmoke", getText("IGUI_TraditionalPreservationFishMeat_ColdSmokeNeed",
                string.format("%.1f", modData.cold or 0), string.format("%.0f", F.coldNeed(modData))))
        end
        local warning = F.spoilWarning(status, isCold)
        if warning then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
        -- Corned meat left to dry in the shed: what the shed's warmth is taking from it.
        if status.underSalted then
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_UnderSalted", UI.say(status.hotOnly and "IGUI_TraditionalPreservationFishMeat_UnderSaltedHotOnly" or "IGUI_TraditionalPreservationFishMeat_UnderSaltedShed",
                string.format("%.0f", status.shedTemperature)), UI.WARNING_COLOUR)
        end
    end)
end

-- A stack of blood sausage or Fresh Sausage: the smoke (a hot run for Fresh Sausage) against its need, what the fire is
-- doing for it, and how long its links keep before they come down stale (F.sausageStatus).
local function drawSausageTooltip(slot, tooltip)
    local modData = slot.craftRecipeData:getModData()
    local status = F.sausageStatus(modData, F.getLedger(), getGameTime():getWorldAgeHours())
    local key = "IGUI_TraditionalPreservationFishMeat_"
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, key .. "Method", getText(key .. (status.hot and "MethodSmokedSausage" or "MethodSausage")))
        UI.addLine(layout, key .. "Progress", UI.percent(status.progress))
        if status.hot then
            UI.addLine(layout, key .. "HotSmoke", getText(key .. "HotSmokeHours", string.format("%.1f", status.cold),
                string.format("%.0f", status.need)))
        else
            UI.addLine(layout, key .. "ColdSmoke", getText(key .. "ColdSmokeNeed", string.format("%.1f", status.cold),
                string.format("%.0f", status.need)))
        end
        UI.addLine(layout, key .. "Fire", getText(key .. "Sausage" .. status.state),
            status.state ~= (status.hot and "Cooking" or "Smoking") and UI.SLOW_COLOUR or nil)
        if status.staleDays then
            UI.addLine(layout, key .. "Spoilage", UI.say(key .. (status.hot and "FreshSausageStaleIn" or "SausageStaleIn"), string.format("%.1f", status.staleDays)),
                status.staleDays < 1 and UI.WARNING_COLOUR or nil)
        end
    end)
end

-- The tub's recipe time is the longest press, so a lighter batch says its own time left, and what a warm
-- season is taking from it.
local function drawPressTooltip(slot, tooltip)
    local status = F.pressStatus(slot.craftRecipeData:getModData(), getGameTime():getWorldAgeHours(), F.getLedger())
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_TimeLeft", timeText(status.hoursLeft))
        if status.spoiling or status.spoiled > 0 then
            local warning = status.spoiling and "IGUI_TraditionalPreservationFishMeat_SpoilingWarmCure" or "IGUI_TraditionalPreservationFishMeat_Spoiled"
            UI.addLine(layout, "IGUI_TraditionalPreservationFishMeat_Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
    end)
end

UI.progressTooltips({
    PressSaltedFish = drawPressTooltip,
    PressSaltedMeat = drawPressTooltip,
    CountryCureMeat = drawPressTooltip,
    HangFishToDry = function(slot, tooltip) drawStackTooltip(slot, tooltip, "salt") end,
    HangFishToColdDry = function(slot, tooltip) drawStackTooltip(slot, tooltip, "cold") end,
    HangMeatToDry = function(slot, tooltip) drawStackTooltip(slot, tooltip, "meat") end,
    HangSausageToSmoke = drawSausageTooltip,
})

-- The window's Output slot shows the script's one output whatever the stack will be: its popup lists every end
-- instead (the stack's own popup says which, F.stackOutcome).
local OUTCOMES = {
    HangMeatToDry = { "Charque", "DryCured", "CountryHam", "HotSmokedMeat", "SmokedDryCured" },
    HangFishToDry = { "SaltDried", "HotSmokedFish", "ColdSmokedFish" },
    HangSausageToSmoke = { "SmokedSausage", "SmokedBloodSausage" },
}
local function drawOutcomes(tooltip, name)
    local lines = {}
    for _, key in ipairs(OUTCOMES[name]) do table.insert(lines, getText("IGUI_TraditionalPreservationFishMeat_Ends_" .. key)) end
    UI.drawListTooltip(tooltip, getText("IGUI_TraditionalPreservationFishMeat_ComesOutAs"), lines)
end
UI.outputTooltips({ HangMeatToDry = drawOutcomes, HangFishToDry = drawOutcomes, HangSausageToSmoke = drawOutcomes })

-- A badge in the bottom left corner, as the inventory marks frozen food: a little salt tells salt stacks from cold
-- ones at a glance, and while a stoked run is cooking a stack (F.cookShare) it shows what the stack is turning
-- into, Hot Smoked fish or meat, with the bar following the cook.
local BADGE_ITEMS = { salt = "Base.Salt", hotFish = "TraditionalPreservationFishMeat.HotSmokedFish", hotMeat = "TraditionalPreservationFishMeat.HotSmokedMeat" }
local badgeIcons = {}
local function badgeOf(slot)
    local data = slot.craftRecipeData
    local modData = data and data:getRecipe() and data:getModData()
    if modData and F.cookShare(modData) then return slot.tpMeat and "hotMeat" or "hotFish" end
    return not slot.tpMeat and "salt" or nil
end

local function renderWithBadge(slot)
    ISItemSlot.render(slot)
    local badge = badgeOf(slot)
    if not badge then return end
    badgeIcons[badge] = badgeIcons[badge] or ScriptManager.instance:getItem(BADGE_ITEMS[badge]):getNormalTexture()
    slot:drawTextureScaled(badgeIcons[badge], SALT_BADGE_MARGIN, slot:getHeight() - SALT_BADGE_SIZE - SALT_BADGE_MARGIN,
        SALT_BADGE_SIZE, SALT_BADGE_SIZE, 1, 1, 1, 1)
end

-- Slots are reused for other batches, so the badge comes off again.
UI.onProgressSlot(function(slot, name)
    if name == "HangFishToDry" or name == "HangMeatToDry" then
        slot.render = renderWithBadge
        slot.tpMeat = name == "HangMeatToDry"
    elseif slot.render == renderWithBadge then
        slot.render = nil
    end
end)

-- The Gantry stands in the open or under an open roof, not in a room (TP Core's Smokehouse keeps its own rules); it
-- and the Hanging Beam keep out of a door's front.
UI.notInRooms(Tiles.OUTDOOR)
UI.keepDoorsFree(Tiles.DOOR_KEPT)

-- Fish names and the stockfish's ripeness follow the days: the player's own things every hour, and any
-- container as soon as the inventory windows show it. Names from before the bracket names update the same way.
-- Crocks of Potted Meat catch up on their keeping the same way (F.keepCrock).
local function renameIn(container)
    if not container then return end
    for fullType in pairs(F.STAGES) do
        local items = container:getAllTypeRecurse(fullType)
        for i = 0, items:size() - 1 do F.rename(items:get(i)) end
    end
    F.keepCrocksIn(container)
end

Events.EveryHours.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then renameIn(player:getInventory()) end
    end
end)

Events.OnRefreshInventoryWindowContainers.Add(function(page, reason)
    if reason ~= "end" then return end
    for _, button in ipairs(page.backpacks or {}) do renameIn(button.inventory) end
end)

-- A crock is looked at as it is moved, while it is still where it was, so its time there counts at that place.
Transfer.before(function(_, item)
    if item:getFullType() == F.CROCK then F.keepCrock(item) end
end)

-- Rinse at Sink: the Rinse recipe takes carried water, and this takes it from the nearest sink, bathtub, barrel or
-- well of clean water, walking there. It goes in the fish's own submenu, beside the recipe, for every selected fish.
local function selectedFish(items, wanted)
    local fish = {}
    for _, entry in ipairs(items) do
        if instanceof(entry, "InventoryItem") then
            if wanted(entry) then table.insert(fish, entry) end
        else
            -- A collapsed stack lists its first item twice.
            for i = 2, #entry.items do
                if wanted(entry.items[i]) then table.insert(fish, entry.items[i]) end
            end
        end
    end
    return fish
end

local function onRinse(playerObj, fish, source)
    for _, item in ipairs(fish) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    if not luautils.walkAdj(playerObj, source:getSquare(), true) then return end
    for _, item in ipairs(fish) do ISTimedActionQueue.add(TPFMRinse:new(playerObj, item, source)) end
end

-- The submenu named after the fish that holds its recipes (TP Core's UI.itemSubMenu).
local fishSubMenu = UI.itemSubMenu

local function onFillRinseMenu(playerNum, context, items)
    local fish = selectedFish(items, F.canRinse)
    if #fish == 0 then return end
    local playerObj = getSpecificPlayer(playerNum)
    local source = F.findWaterSource(playerObj, F.RINSE_LITRES)
    if not source then return end
    local option = fishSubMenu(context, fish[1]):addOption(getText("ContextMenu_TraditionalPreservationFishMeat_RinseAtSink"), playerObj, onRinse, fish, source)
    option.iconTexture = fish[1]:getTexture()
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = getText("Tooltip_TraditionalPreservationFishMeat_RinseAtSink", tostring(#fish), string.format("%.2f", F.RINSE_LITRES * #fish))
    option.toolTip = tooltip
end

Events.OnFillInventoryObjectContextMenu.Add(onFillRinseMenu)

-- Tie a Bale on selected stockfish, in the fish's submenu, and Untie Bale on a bale. The fish, the cord and the
-- bale come into the main inventory first.
local function onTieBale(playerObj, fish, cordItem, cord)
    for _, item in ipairs(fish) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, cordItem)
    ISTimedActionQueue.add(TPFMTieBale:new(playerObj, fish, cordItem, cord))
end

local function onUntieBale(playerObj, bales)
    for _, bale in ipairs(bales) do
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bale)
        ISTimedActionQueue.add(TPFMUntieBale:new(playerObj, bale))
    end
end

local function isBale(item)
    return item:getFullType() == F.BALE_TYPE
end

local function onFillBaleMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local fish = F.baleLoad(selectedFish(items, F.isStockfish))
    if #fish > 0 then
        local cordItem, cord = F.findCord(playerObj:getInventory())
        local option = fishSubMenu(context, fish[1]):addOption(getText("ContextMenu_TraditionalPreservationFishMeat_TieBale"), playerObj, onTieBale, fish, cordItem, cord)
        option.iconTexture = getTexture("Item_StockfishBale")
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        if cord then
            local weight = 0
            for _, item in ipairs(fish) do weight = weight + item:getActualWeight() end
            tooltip.description = getText("Tooltip_TraditionalPreservationFishMeat_TieBale", tostring(#fish), string.format("%.1f", weight), cordItem:getDisplayName())
        else
            tooltip.description = getText("Tooltip_TraditionalPreservationFishMeat_TieBaleNoCord")
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end
    local bales = selectedFish(items, isBale)
    if #bales > 0 then
        local option = context:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_UntieBale"), playerObj, onUntieBale, bales)
        option.iconTexture = getTexture("Item_StockfishBale")
        local cord = F.cordByKey(bales[1]:getModData().cord) or F.BALE_CORDS[1]
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("Tooltip_TraditionalPreservationFishMeat_UntieBale", getItemNameFromFullType(cord.type))
        option.toolTip = tooltip
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillBaleMenu)

-- The Stockfish Pallet has no window: its right-click menu says what it does where it stands.
local PALLET_PLACES = { [F.PALLET_LOFT] = "IGUI_TraditionalPreservationFishMeat_PalletLoft", [F.PALLET_GROUND] = "IGUI_TraditionalPreservationFishMeat_PalletGround" }

local function onFillPalletMenu(playerNum, context, worldobjects, test)
    for _, object in ipairs(worldobjects) do
        local sprite = object:getSprite()
        if sprite and sprite:getName() == Tiles.PALLET then
            if test then return end
            local speed = F.palletSpeed(Weather.placeOf(object))
            local text = PALLET_PLACES[speed]
                and getText("ContextMenu_TraditionalPreservationFishMeat_PalletSpeed", tostring(speed), getText(PALLET_PLACES[speed]))
                or getText("ContextMenu_TraditionalPreservationFishMeat_PalletNoSpeed")
            local option = context:addOption(text)
            option.iconTexture = getTexture("Item_StockfishPallet")
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip.description = getText("Tooltip_craft_stockfishPalletDesc")
            option.toolTip = tooltip
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillPalletMenu)
