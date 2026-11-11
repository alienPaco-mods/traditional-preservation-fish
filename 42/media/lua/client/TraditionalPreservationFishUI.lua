-- Traditional Preservation (Fish): starts showing a station's contents as soon as something goes in,
-- because one built this session hasn't been through the map loader. Also replaces vanilla's
-- free slot limit: a tub takes one batch at a time by weight, and a frame goes by stacks. The
-- same rules decide the slot's green border, so it never promises what adding then refuses.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Controls/ISItemSlot"
local UI = require "TraditionalPreservationCore/UI"
local Tiles = require "TraditionalPreservationFish/Tiles"
local F = TraditionalPreservationFish

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
        if component:isRunning() then return "IGUI_TraditionalPreservationFish_TubInUse" end
        -- This asks what is in the tub, because a tub keeps the slot counts it was built with.
        if TraditionalPreservationFishWorld.busyStacks(entity) > 0 then return "IGUI_TraditionalPreservationFish_TubNotEmpty" end
        if resource:getStoredItems():size() + #queued >= F.TUB_MAX_ITEMS
                or not F.hasRoom(F.TUB_CAPACITY, waiting, weight) then
            return "IGUI_TraditionalPreservationFish_Full"
        end
        return nil
    end
    local stored = resource:getStoredItems()
    local isCold = F.COLD_FISH[item:getFullType()]
    if stored:size() > 0 and F.COLD_FISH[stored:get(0):getFullType()] ~= isCold then
        return "IGUI_TraditionalPreservationFish_MixedStack"
    end
    local hanger = F.hangerFor(spriteIndex(entity))
    return F.frameRefusal(hanger, TraditionalPreservationFishWorld.busyStacks(entity), waiting, weight)
end

-- A tub or a drying station, with whether it's a tub. Asking about one starts tracking it.
local function station(entity)
    local index = spriteIndex(entity)
    if not index or not TraditionalPreservationFishWorld then return nil end

    local isTub = index < FIRST_FRAME_SPRITE
    local component = entity:getComponent(isTub and ComponentType.CraftLogic or ComponentType.DryingCraftLogic)
    if not component then return nil end
    TraditionalPreservationFishWorld.track(entity)
    return component, isTub
end

UI.slotRules{
    station = station,
    refusal = refusal,
    -- What hangs there now, so the count of busy stacks is current.
    added = function(entity) TraditionalPreservationFishWorld.refresh(entity) end,
}

local function timeText(hours)
    if not hours then return getText("IGUI_TraditionalPreservationFish_Paused") end
    return UI.timeText(hours, "IGUI_TraditionalPreservationFish_Time")
end

-- Vanilla's popup goes by its own temperature curve and the recipe's time, so hanging stacks get
-- this instead.
local function drawStackTooltip(slot, tooltip, isCold)
    local ledger = F.getLedger()
    local status = F.stackStatus(isCold, slot.craftRecipeData:getModData(), ledger)
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Method", getText(isCold and "IGUI_TraditionalPreservationFish_MethodCold" or "IGUI_TraditionalPreservationFish_MethodSalt"))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_TimeLeft", timeText(status.hoursLeft))
        local modData = slot.craftRecipeData:getModData()
        local place = modData.sheltered and "Indoors" or modData.covered and "Covered" or "Open"
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Place", getText("IGUI_TraditionalPreservationFish_Place" .. place))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Temperature", getText(F.temperatureWord(isCold, ledger.temperature or 0, place == "Open")))
        if isCold then UI.addLine(layout, "IGUI_TraditionalPreservationFish_Wind", getText(F.windWord(ledger.wind))) end
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Wetness", UI.percent(isCold and ledger.coldWetness or ledger.wetness))
        if status.reason then
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Rate", getText("IGUI_TraditionalPreservationFish_Stopped" .. status.reason), UI.SLOW_COLOUR)
        else
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Rate", UI.percent(status.rate))
        end
        if status.spoiling or status.scorching or status.spoiled > 0 then
            local warning = "IGUI_TraditionalPreservationFish_Spoiled"
            if status.scorching then warning = "IGUI_TraditionalPreservationFish_SpoilingSun" end
            if status.spoiling then warning = isCold and "IGUI_TraditionalPreservationFish_SpoilingWarm" or "IGUI_TraditionalPreservationFish_SpoilingMuggy" end
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
    end)
end

-- The tub's recipe time is the longest press, so a lighter batch says its own time left, and what a warm
-- season is taking from it.
local function drawPressTooltip(slot, tooltip)
    local status = F.pressStatus(slot.craftRecipeData:getModData(), getGameTime():getWorldAgeHours(), F.getLedger())
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_TimeLeft", timeText(status.hoursLeft))
        if status.spoiling or status.spoiled > 0 then
            local warning = status.spoiling and "IGUI_TraditionalPreservationFish_SpoilingWarmCure" or "IGUI_TraditionalPreservationFish_Spoiled"
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
    end)
end

UI.progressTooltips({
    PressSaltedFish = drawPressTooltip,
    HangFishToDry = function(slot, tooltip) drawStackTooltip(slot, tooltip, false) end,
    HangFishToColdDry = function(slot, tooltip) drawStackTooltip(slot, tooltip, true) end,
})

-- A little salt in the bottom left corner tells salt stacks from cold ones at a glance.
local saltIcon
local function renderWithSaltBadge(slot)
    ISItemSlot.render(slot)
    saltIcon = saltIcon or ScriptManager.instance:getItem("Base.Salt"):getNormalTexture()
    slot:drawTextureScaled(saltIcon, SALT_BADGE_MARGIN, slot:getHeight() - SALT_BADGE_SIZE - SALT_BADGE_MARGIN,
        SALT_BADGE_SIZE, SALT_BADGE_SIZE, 1, 1, 1, 1)
end

-- Slots are reused for other batches, so the badge comes off again.
UI.onProgressSlot(function(slot, name)
    if name == "HangFishToDry" then
        slot.render = renderWithSaltBadge
    elseif slot.render == renderWithSaltBadge then
        slot.render = nil
    end
end)

-- The Fish Hanging Beam and Gantry each stands in the open or under an open roof, not in a room.
UI.notInRooms(Tiles.OUTDOOR)

-- Fish names and the stockfish's ripeness follow the days: the player's own things every hour, and any
-- container as soon as the inventory windows show it. Names from before the bracket names update the same way.
local function renameIn(container)
    if not container then return end
    for fullType in pairs(F.STAGES) do
        local items = container:getAllTypeRecurse(fullType)
        for i = 0, items:size() - 1 do F.rename(items:get(i)) end
    end
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

-- Rinse at Sink: the Rinse recipe takes carried water, and this takes it from the nearest sink, bathtub, barrel or
-- well of clean water, walking there. It goes in the fish's own submenu, beside the recipe, for every selected fish.
local function selectedFish(items)
    local fish = {}
    for _, entry in ipairs(items) do
        if instanceof(entry, "InventoryItem") then
            if F.canRinse(entry) then table.insert(fish, entry) end
        else
            -- A collapsed stack lists its first item twice.
            for i = 2, #entry.items do
                if F.canRinse(entry.items[i]) then table.insert(fish, entry.items[i]) end
            end
        end
    end
    return fish
end

local function onRinse(playerObj, fish, source)
    for _, item in ipairs(fish) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    if not luautils.walkAdj(playerObj, source:getSquare(), true) then return end
    for _, item in ipairs(fish) do ISTimedActionQueue.add(TPFishRinse:new(playerObj, item, source)) end
end

local OPTION_FIELDS = { "target", "onSelect", "param1", "param2", "param3", "param4", "param5", "param6", "param7",
    "param8", "param9", "param10", "iconTexture", "color", "toolTip", "notAvailable" }

-- The submenu named after the fish that holds its recipes (Gut Fish, Pack Fish in Salt ...). Vanilla makes one only
-- for two recipes or more; a lone recipe option is turned into it where it stands, and with no recipe it is added.
local function fishSubMenu(context, fish)
    local name = fish:getDisplayName()
    local lone
    for _, option in ipairs(context.options) do
        if option.name == name and option.subOption then return context:getSubMenu(option.subOption) end
        if not lone and option.onSelect and option.onSelect == ISInventoryPaneContextMenu.OnNewCraft then lone = option end
    end
    local subMenu = context:getNew(context)
    local parent = lone
    if lone then
        local recipe = subMenu:addOption(lone.name)
        for _, field in ipairs(OPTION_FIELDS) do
            recipe[field] = lone[field]
            lone[field] = nil
        end
        lone.name = name
    else
        parent = context:addOption(name)
    end
    parent.iconTexture = fish:getTexture()
    context:addSubMenu(parent, subMenu)
    return subMenu
end

local function onFillRinseMenu(playerNum, context, items)
    local fish = selectedFish(items)
    if #fish == 0 then return end
    local playerObj = getSpecificPlayer(playerNum)
    local source = F.findWaterSource(playerObj, F.RINSE_LITRES)
    if not source then return end
    local option = fishSubMenu(context, fish[1]):addOption(getText("ContextMenu_TraditionalPreservationFish_RinseAtSink"), playerObj, onRinse, fish, source)
    option.iconTexture = fish[1]:getTexture()
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = getText("Tooltip_TraditionalPreservationFish_RinseAtSink", tostring(#fish), string.format("%.2f", F.RINSE_LITRES * #fish))
    option.toolTip = tooltip
end

Events.OnFillInventoryObjectContextMenu.Add(onFillRinseMenu)
