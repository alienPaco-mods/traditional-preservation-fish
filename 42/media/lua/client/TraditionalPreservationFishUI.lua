-- Traditional Preservation (Fish): starts showing a station's contents as soon as something goes in,
-- because one built this session hasn't been through the map loader. Also replaces vanilla's
-- free slot limit: a tub takes one batch at a time by weight, and a frame goes by stacks. The
-- same rules decide the slot's green border, so it never promises what adding then refuses.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Controls/ISItemSlot"
local UI = require "TraditionalPreservationFish/Core/UI"
local Tiles = require "TraditionalPreservationFish/Tiles"

local FIRST_FRAME_SPRITE = Tiles.FRAME


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

-- queued lists the fish on their way in that the slot doesn't hold yet. slot.extra says it's a tub.
local function refusal(slot, item, queued)
    local entity, component, resource, isTub = slot.entity, slot.component, slot.resource, slot.extra
    local wrongFish = TraditionalPreservationFish.fishRefusal(isTub, item:getFullType())
    if wrongFish then return wrongFish end

    local weight = item:getActualWeight()
    local waiting = waitingWeight(resource)
    for _, fish in ipairs(queued) do waiting = waiting + fish:getActualWeight() end
    if isTub then
        if component:isRunning() then return "IGUI_TraditionalPreservationFish_TubInUse" end
        -- This asks what is in the tub, because a tub keeps the slot counts it was built with.
        if TraditionalPreservationFishWorld.busyStacks(entity) > 0 then return "IGUI_TraditionalPreservationFish_TubNotEmpty" end
        if resource:getStoredItems():size() + #queued >= TraditionalPreservationFish.TUB_MAX_ITEMS
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
