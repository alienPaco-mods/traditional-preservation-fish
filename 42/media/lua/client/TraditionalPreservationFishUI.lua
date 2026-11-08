-- Traditional Preservation (Fish): starts showing a station's contents as soon as something goes in,
-- because one built this session hasn't been through the map loader. Also replaces vanilla's
-- free slot limit: a tub takes one batch at a time by weight, and a frame goes by stacks. The
-- same rules decide the slot's green border, so it never promises what adding then refuses.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Controls/ISItemSlot"
require "Entity/ISUI/Components/Crafting/ISWidgetCraftLogicOutputProgress"
require "Moveables/ISMoveableSpriteProps"

local FIRST_FRAME_SPRITE = 6  -- keep in step with tools/build_tileset.py

local vanillaItemSlotAddItems = ISCraftLogicPanel.ItemSlotAddItems
local vanillaVerifyItem = ISItemSlot.defaultVerifyItem
local vanillaMouseUp = ISItemSlot.onMouseUp
local vanillaProgressItems = ISWidgetCraftLogicOutputProgress.updateProgressItems

local HANG_RECIPES = { HangFishToDry = "salt", HangFishToColdDry = "cold" }
local TOOLTIP_PADDING = 5
local TOOLTIP_MIN_WIDTH = 150
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

local function addLine(layout, label, value, r, g, b)
    local item = layout:addItem()
    item:setLabel(getText(label) .. ":", 1, 1, 0.8, 1)
    item:setValue(value, r or 1, g or 1, b or 1, 1)
end

local function timeText(hours)
    if not hours then return getText("IGUI_TraditionalPreservationFish_Paused") end
    return getText("IGUI_TraditionalPreservationFish_Time", string.format("%.0f", math.floor(hours / 24)), string.format("%.0f", math.floor(hours % 24)))
end

-- Vanilla's popup goes by its own temperature curve and the recipe's time, so hanging stacks get
-- this instead. It runs twice, once to measure and once to draw.
local function drawStackTooltip(slot, tooltip, isCold)
    local ledger = TraditionalPreservationFish.getLedger()
    local status = TraditionalPreservationFish.stackStatus(isCold, slot.craftRecipeData:getModData(), ledger)
    local title = getText("EC_CraftLogic_Progress")
    tooltip:DrawText(tooltip:getFont(), title, TOOLTIP_PADDING, TOOLTIP_PADDING, 1, 1, 0.8, 1)
    tooltip:adjustWidth(TOOLTIP_PADDING, title)

    local layout = tooltip:beginLayout()
    addLine(layout, "IGUI_TraditionalPreservationFish_Method", getText(isCold and "IGUI_TraditionalPreservationFish_MethodCold" or "IGUI_TraditionalPreservationFish_MethodSalt"))
    addLine(layout, "IGUI_TraditionalPreservationFish_Progress", string.format("%.0f%%", status.progress * 100))
    addLine(layout, "IGUI_TraditionalPreservationFish_TimeLeft", timeText(status.hoursLeft))
    addLine(layout, "IGUI_TraditionalPreservationFish_Temperature", getText(TraditionalPreservationFish.temperatureWord(isCold, ledger.temperature or 0)))
    addLine(layout, "IGUI_TraditionalPreservationFish_Wetness", string.format("%.0f%%", ledger.wetness * 100))
    if status.reason then
        addLine(layout, "IGUI_TraditionalPreservationFish_Rate", getText("IGUI_TraditionalPreservationFish_Stopped" .. status.reason), 1, 0.7, 0.4)
    else
        addLine(layout, "IGUI_TraditionalPreservationFish_Rate", string.format("%.0f%%", status.rate * 100))
    end
    if status.spoiling or status.spoiled > 0 then
        local warning = status.spoiling and (isCold and "IGUI_TraditionalPreservationFish_SpoilingWarm" or "IGUI_TraditionalPreservationFish_SpoilingMuggy") or "IGUI_TraditionalPreservationFish_Spoiled"
        addLine(layout, "IGUI_TraditionalPreservationFish_Spoilage", getText(warning, string.format("%.0f%%", status.spoiled * 100)), 1, 0.35, 0.3)
    end
    local bottom = layout:render(TOOLTIP_PADDING, TOOLTIP_PADDING + tooltip:getLineSpacing(), tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(bottom + TOOLTIP_PADDING)
    tooltip:setWidth(math.max(tooltip:getWidth(), TOOLTIP_MIN_WIDTH))
end

-- A little salt in the bottom left corner tells salt stacks from cold ones at a glance.
local saltIcon
local function renderWithSaltBadge(slot)
    ISItemSlot.render(slot)
    saltIcon = saltIcon or ScriptManager.instance:getItem("Base.Salt"):getNormalTexture()
    slot:drawTextureScaled(saltIcon, SALT_BADGE_MARGIN, slot:getHeight() - SALT_BADGE_SIZE - SALT_BADGE_MARGIN,
        SALT_BADGE_SIZE, SALT_BADGE_SIZE, 1, 1, 1, 1)
end

function ISWidgetCraftLogicOutputProgress:updateProgressItems()
    vanillaProgressItems(self)
    for _, slot in ipairs(self.progressItems:getItemSlots()) do
        -- This runs for every station's slots, and a batch that has just finished hands its data back to
        -- the engine's pool with no recipe, so both can be missing.
        local recipe = slot.craftRecipeData and slot.craftRecipeData:getRecipe()
        local method = recipe and HANG_RECIPES[string.gsub(recipe:getName(), "^.*%.", "")]
        if method then
            slot.drawTooltip = function(itemSlot, tooltip) drawStackTooltip(itemSlot, tooltip, method == "cold") end
        end
        -- Slots are reused for other batches, so the badge comes off again.
        if method == "salt" then
            slot.render = renderWithSaltBadge
        elseif slot.render == renderWithSaltBadge then
            slot.render = nil
        end
    end
end

-- The Fish Hanging Beam and Gantry each stands in the open. Its build recipe refuses an indoor square, and this stops one being picked
-- up and carried in, as placing a moveable doesn't run that check.
local OUTDOOR_SPRITES = { ["traditionalpreservationfish_02_0"] = true, ["traditionalpreservationfish_02_1"] = true, ["traditionalpreservationfish_02_2"] = true, ["traditionalpreservationfish_02_3"] = true }
local vanillaCanPlace = ISMoveableSpriteProps.canPlaceMoveable

function ISMoveableSpriteProps:canPlaceMoveable(character, square, item)
    if OUTDOOR_SPRITES[self.spriteName] and square and not square:isOutside() then return false end
    return vanillaCanPlace(self, character, square, item)
end
