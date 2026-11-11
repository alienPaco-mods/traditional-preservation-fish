-- Traditional Preservation (Fish & Meat): Connect the Firebox and Disconnect the Firebox, in the Firebox's own menu
-- (TP Core's HearthUI.addFireboxMenu) and on the Smokehouse chamber's right-click. Neither picks up while joined, and
-- Firebox Info says where its flue goes.
require "TimedActions/TPFMFlue"
local UI = require "TraditionalPreservationCore/UI"
local HearthUI = require "TraditionalPreservationCore/HearthUI"
local Hearth = require "TraditionalPreservationCore/Hearth"
local F = TraditionalPreservationFishMeat

local FIREBOX_ICON = "media/textures/Item_TPFirebox.png"
local TOOL_NAMES = { MASONS_TROWEL = "IGUI_TraditionalPreservationFishMeat_ToolTrowel", DIG_GRAVE = "IGUI_TraditionalPreservationFishMeat_ToolShovel" }
local KIND_NAMES = { Pipe = "IGUI_TraditionalPreservationFishMeat_FluePipe", Stones = "IGUI_TraditionalPreservationFishMeat_FlueStones" }

local function countsOf(playerObj, kind)
    local counts = {}
    for _, need in ipairs(F.FLUE_KITS[kind].items) do
        counts[need[1]] = #UI.findItems(playerObj, function(item) return item:getFullType() == need[1] end)
    end
    return counts
end

local function toolOf(playerObj, kind)
    local tag = ItemTag[F.FLUE_KITS[kind].tool]
    return UI.findItems(playerObj, function(item) return item:hasTag(tag) and not item:isBroken() end)[1]
end

local function itemList(items)
    local names = {}
    for _, need in ipairs(items) do table.insert(names, need[2] .. " " .. getItemNameFromFullType(need[1])) end
    return table.concat(names, ", ")
end

local function walkTo(playerObj, found)
    return luautils.walkAdj(playerObj, found.firebox:getSquare(), true)
end

local function onConnect(playerObj, found, kind)
    local kit = F.FLUE_KITS[kind]
    for _, need in ipairs(kit.items) do
        local items = UI.findItems(playerObj, function(item) return item:getFullType() == need[1] end)
        for i = 1, need[2] do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, items[i]) end
    end
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, toolOf(playerObj, kind))
    if not walkTo(playerObj, found) then return end
    ISTimedActionQueue.add(TPFMFlue:new(playerObj, found.firebox, found.tile, kind, kit.tool))
end

local function onDisconnect(playerObj, found, kind)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, toolOf(playerObj, kind))
    if not walkTo(playerObj, found) then return end
    ISTimedActionQueue.add(TPFMFlue:new(playerObj, found.firebox, found.tile, nil, F.FLUE_KITS[kind].tool))
end

local function addConnect(menu, playerObj, found)
    local option = menu:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_ConnectFirebox"))
    option.iconTexture = getTexture(FIREBOX_ICON)
    local refusal = F.connectRefusalFor(found)
    if refusal then return UI.disable(option, getText(refusal)) end
    local sub = menu:getNew(menu)
    menu:addSubMenu(option, sub)
    for _, kind in ipairs(F.FLUE_KINDS) do
        local kit = F.FLUE_KITS[kind]
        local choice = sub:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_Connect" .. kind), playerObj, onConnect, found, kind)
        local missing, noTool = F.flueKitMissing(kind, countsOf(playerObj, kind), toolOf(playerObj, kind) ~= nil)
        local lines = { getText("IGUI_TraditionalPreservationFishMeat_Flue" .. kind .. "Help"),
            UI.say("IGUI_TraditionalPreservationFishMeat_FlueNeeds", itemList(kit.items)),
            UI.say("IGUI_TraditionalPreservationFishMeat_FlueTool", getText(TOOL_NAMES[kit.tool])) }
        if #missing > 0 or noTool then
            local short = itemList(missing)
            if noTool then short = short ~= "" and (short .. ", " .. getText(TOOL_NAMES[kit.tool])) or getText(TOOL_NAMES[kit.tool]) end
            table.insert(lines, UI.say("IGUI_TraditionalPreservationFishMeat_FlueMissing", short))
            UI.disable(choice, table.concat(lines, " <LINE> "))
        else
            UI.tooltip(choice, table.concat(lines, " <LINE> "))
        end
    end
end

local function addDisconnect(menu, playerObj, found)
    local kind = F.flueOf(found.firebox)
    local kit = F.FLUE_KITS[kind]
    local option = menu:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_DisconnectFirebox"), playerObj, onDisconnect, found, kind)
    option.iconTexture = getTexture(FIREBOX_ICON)
    local back
    for _, need in ipairs(kit.items) do
        if need[1] == kit.back then back = need[2] .. " " .. getItemNameFromFullType(need[1]) end
    end
    local help = UI.say("IGUI_TraditionalPreservationFishMeat_DisconnectHelp", back, getText(TOOL_NAMES[kit.tool]))
    if Hearth.isBurning(found.firebox) then
        UI.disable(option, getText("IGUI_TraditionalPreservationFishMeat_FlueBurning"))
    elseif not toolOf(playerObj, kind) then
        UI.disable(option, help .. " <LINE> " .. UI.say("IGUI_TraditionalPreservationFishMeat_FlueMissing", getText(TOOL_NAMES[kit.tool])))
    else
        UI.tooltip(option, help)
    end
end

-- The Firebox's menu: Disconnect if its flue is laid, else Connect when a chamber tile is on its back or a flank.
HearthUI.addFireboxMenu(function(menu, playerObj, firebox)
    if F.flueOf(firebox) then
        local tile = F.joinedChamber(firebox)
        return addDisconnect(menu, playerObj, { firebox = firebox, tile = tile or firebox })
    end
    local found = F.chamberBy(firebox)
    if found then addConnect(menu, playerObj, found) end
end)

-- The chamber's right-click: the joined Firebox's Disconnect, or Connect for the first Firebox beside it.
local function onFillChamberMenu(playerNum, context, worldobjects, test)
    for _, object in ipairs(worldobjects) do
        if F.chamberTile(F.stationIndex(object)) then
            if test then return end
            local playerObj = getSpecificPlayer(playerNum)
            local firebox, joined = F.joinedFirebox(object)
            if firebox then return addDisconnect(context, playerObj, joined) end
            local candidates = F.fireboxesBy(object)
            -- One that may join first, so a refusal shows only when none fits.
            table.sort(candidates, function(a, b) return (F.connectRefusalFor(a) == nil) and (F.connectRefusalFor(b) ~= nil) end)
            if candidates[1] then addConnect(context, playerObj, candidates[1]) end
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillChamberMenu)

-- Neither the Firebox nor the shed picks up while the flue joins them.
UI.keepInPlace(function(object)
    if F.chamberTile(F.stationIndex(object)) then return F.joinedFirebox(object) ~= nil end
    return Hearth.isFirebox(object) and F.flueOf(object) ~= nil
end)

HearthUI.addFireboxNotes(function(info, notes)
    local flue = info.copper and info.copper.flue
    if not flue then return end
    table.insert(notes, UI.say("IGUI_TraditionalPreservationFishMeat_FlueJoined", getText(KIND_NAMES[flue])))
    table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FlueSmokes"))
end)
