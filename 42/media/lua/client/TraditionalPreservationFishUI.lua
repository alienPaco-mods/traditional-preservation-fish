-- Traditional Preservation (Fish): starts showing a station's contents as soon as something goes in,
-- because one built this session hasn't been through the map loader. Also replaces vanilla's
-- free slot limit: a tub takes one batch at a time by weight, and a frame goes by stacks. The
-- same rules decide the slot's green border, so it never promises what adding then refuses.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Controls/ISItemSlot"
local UI = require "TraditionalPreservationFish/Core/UI"
local Tiles = require "TraditionalPreservationFish/Tiles"

local FIRST_FRAME_SPRITE = Tiles.FRAME

local vanillaItemSlotAddItems = ISCraftLogicPanel.ItemSlotAddItems
local vanillaVerifyItem = ISItemSlot.defaultVerifyItem
local vanillaMouseUp = ISItemSlot.onMouseUp

local SALT_BADGE_SIZE = 14
local SALT_BADGE_MARGIN = 3

local function spriteIndex(entity)
    local sprite = entity and entity:getSprite()
    return sprite and TraditionalPreservationFish.spriteIndex(sprite:getName())
end

local function waitingWeight(resource)
    local weight = 0
    local stored = resource:getStoredItems()
    for i = 0, stored:size() - 1 do
        weight = weight + stored:get(i):getActualWeight()
    end
    return weight
end

-- queuedWeight and queuedCount are fish on their way in that the slot doesn't hold yet.
local function refusal(entity, component, resource, isTub, item, queuedWeight, queuedCount)
    local wrongFish = TraditionalPreservationFish.fishRefusal(isTub, item:getFullType())
    if wrongFish then return wrongFish end

    local weight = item:getActualWeight()
    local waiting = waitingWeight(resource) + queuedWeight
    if isTub then
        if component:isRunning() then return "IGUI_TraditionalPreservationFish_TubInUse" end
        -- This asks what is in the tub, because a tub keeps the slot counts it was built with.
        if TraditionalPreservationFishWorld.busyStacks(entity) > 0 then return "IGUI_TraditionalPreservationFish_TubNotEmpty" end
        if resource:getStoredItems():size() + queuedCount >= TraditionalPreservationFish.TUB_MAX_ITEMS
                or not TraditionalPreservationFish.hasRoom(TraditionalPreservationFish.TUB_CAPACITY, waiting, weight) then
            return "IGUI_TraditionalPreservationFish_Full"
        end
        return nil
    end
    local stored = resource:getStoredItems()
    local isCold = TraditionalPreservationFish.COLD_FISH[item:getFullType()]
    if stored:size() > 0 and TraditionalPreservationFish.COLD_FISH[stored:get(0):getFullType()] ~= isCold then
        return "IGUI_TraditionalPreservationFish_MixedStack"
    end
    local hanger = TraditionalPreservationFish.hangerFor(spriteIndex(entity))
    return TraditionalPreservationFish.frameRefusal(hanger, TraditionalPreservationFishWorld.busyStacks(entity), waiting, weight)
end

local function canAdd(action)
    return not refusal(action.entity, action.component, action.resource, action.isTub, action.item, 0, 0)
end

-- Vanilla's ItemSlotAddItems with canAdd in place of its limit, because each queued action
-- has to re-check it when it runs. Compare this with vanilla after a game update.
local function addFish(player, entity, itemSlot, itemList, component, isTub)
    if #itemList == 0 then return end
    TraditionalPreservationFishWorld.refresh(entity)

    local queuedWeight = 0
    for index, item in ipairs(itemList) do
        local reason = refusal(entity, component, itemSlot.resource, isTub, item, queuedWeight, index - 1)
        if reason then
            HaloTextHelper.addBadText(player, getText(reason))
            return
        end
        if index == 1 and not ISEntityUI.WalkToEntity(player, entity) then return end

        local action = ISItemSlotAddAction:new(player, entity, item, itemSlot.resource, itemSlot)
        action.component = component
        action.isTub = isTub
        action.canAddItem = canAdd
        ISTimedActionQueue.add(action)
        queuedWeight = queuedWeight + item:getActualWeight()
    end
end

function ISCraftLogicPanel.ItemSlotAddItems(player, entity, itemSlot, itemList, component)
    local index = spriteIndex(entity)
    if not index or not TraditionalPreservationFishWorld then
        return vanillaItemSlotAddItems(player, entity, itemSlot, itemList, component)
    end

    TraditionalPreservationFishWorld.track(entity)
    addFish(player, entity, itemSlot, itemList, component, index < FIRST_FRAME_SPRITE)
end

-- The station an input slot belongs to, or nil for any other slot.
local function slotStation(itemSlot)
    local resource = itemSlot and itemSlot.resource
    if not TraditionalPreservationFishWorld or not resource or resource:getIO() ~= ResourceIO.Input then return nil end

    local entity = resource:getGameEntity()
    local index = spriteIndex(entity)
    if not index then return nil end

    local isTub = index < FIRST_FRAME_SPRITE
    local component = entity:getComponent(isTub and ComponentType.CraftLogic or ComponentType.DryingCraftLogic)
    if not component then return nil end
    TraditionalPreservationFishWorld.track(entity)
    return entity, component, isTub
end

function ISItemSlot:defaultVerifyItem(itemSlot, item)
    if not vanillaVerifyItem(self, itemSlot, item) then return false end

    local entity, component, isTub = slotStation(itemSlot)
    if not entity then return true end
    return not refusal(entity, component, itemSlot.resource, isTub, item, 0, 0)
end

-- The reason to show when nothing being dragged can go in this slot.
local function dropRefusal(itemSlot)
    if not ISMouseDrag.dragging or ISMouseDrag.draggingFocus == itemSlot then return nil end
    local entity, component, isTub = slotStation(itemSlot)
    if not entity then return nil end

    local reason
    for _, item in ipairs(ISInventoryPane.getActualItems(ISMouseDrag.dragging)) do
        local itemReason = refusal(entity, component, itemSlot.resource, isTub, item, 0, 0)
        if not itemReason then return nil end
        reason = reason or itemReason
    end
    return reason
end

-- A refused drop does nothing in vanilla, so this says why.
function ISItemSlot:onMouseUp(x, y)
    local reason = dropRefusal(self)
    if reason then HaloTextHelper.addBadText(getPlayer(), getText(reason)) end
    return vanillaMouseUp(self, x, y)
end

local function timeText(hours)
    if not hours then return getText("IGUI_TraditionalPreservationFish_Paused") end
    return UI.timeText(hours, "IGUI_TraditionalPreservationFish_Time")
end

-- Vanilla's popup goes by its own temperature curve and the recipe's time, so hanging stacks get
-- this instead.
local function drawStackTooltip(slot, tooltip, isCold)
    local ledger = TraditionalPreservationFish.getLedger()
    local status = TraditionalPreservationFish.stackStatus(isCold, slot.craftRecipeData:getModData(), ledger)
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Method", getText(isCold and "IGUI_TraditionalPreservationFish_MethodCold" or "IGUI_TraditionalPreservationFish_MethodSalt"))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_TimeLeft", timeText(status.hoursLeft))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Temperature", getText(TraditionalPreservationFish.temperatureWord(isCold, ledger.temperature or 0)))
        UI.addLine(layout, "IGUI_TraditionalPreservationFish_Wetness", UI.percent(ledger.wetness))
        if status.reason then
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Rate", getText("IGUI_TraditionalPreservationFish_Stopped" .. status.reason), UI.SLOW_COLOUR)
        else
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Rate", UI.percent(status.rate))
        end
        if status.spoiling or status.spoiled > 0 then
            local warning = status.spoiling and (isCold and "IGUI_TraditionalPreservationFish_SpoilingWarm" or "IGUI_TraditionalPreservationFish_SpoilingMuggy") or "IGUI_TraditionalPreservationFish_Spoiled"
            UI.addLine(layout, "IGUI_TraditionalPreservationFish_Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
    end)
end

UI.progressTooltips({
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

-- The Fish Hanging Beam and Gantry each stands in the open.
UI.outdoorOnly(Tiles.OUTDOOR)
