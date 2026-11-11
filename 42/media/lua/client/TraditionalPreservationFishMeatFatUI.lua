-- Traditional Preservation (Fish & Meat): fat in the copper of TP Core's Hearth. Put Fat in the Copper on the
-- Hearth's menu has a row for each kind of raw fat carried, and Hearth Info says how the fat in the copper is doing.
require "TraditionalPreservationFishMeatFat"
require "TimedActions/TPFMFatCopper"
local UI = require "TraditionalPreservationCore/UI"
local Hearth = require "TraditionalPreservationCore/Hearth"
local HearthUI = require "TraditionalPreservationCore/HearthUI"
local F = TraditionalPreservationFishMeat

local function onFatInCopper(playerObj, hearth, raw, pieces)
    if not luautils.walkAdj(playerObj, hearth:getSquare(), true) then return end
    for _, item in ipairs(pieces) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    ISTimedActionQueue.add(TPFMFatCopper:new(playerObj, hearth, raw, pieces))
end

HearthUI.addMenu(function(menu, playerObj, hearth, copper)
    local carried = {}
    for _, fat in ipairs(F.COPPER_FATS) do
        local pieces = UI.findItems(playerObj, function(item) return fat.items[item:getFullType()] and not item:isRotten() end)
        if #pieces > 0 then table.insert(carried, { fat = fat, pieces = pieces }) end
    end
    -- Only someone carrying raw fat sees the row.
    if #carried == 0 then return end
    local option = menu:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_FatInCopper"))
    option.iconTexture = getTexture("Item_PorkFat")
    local sub = menu:getNew(menu)
    menu:addSubMenu(option, sub)
    for _, entry in ipairs(carried) do
        local row = sub:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_" .. entry.fat.name, tostring(#entry.pieces)),
            playerObj, onFatInCopper, hearth, entry.fat.raw, entry.pieces)
        row.itemForTexture = entry.pieces[1]
        if F.copperFatRoom(copper, entry.fat.raw) > 0 then
            UI.tooltip(row, getText("IGUI_TraditionalPreservationFishMeat_FatHelp"))
        else
            row.notAvailable = true
            UI.tooltip(row, getText("IGUI_TraditionalPreservationFishMeat_FatNoRoom"))
        end
    end
end)

HearthUI.addNotes(function(info, notes)
    local copper = info.copper
    if (copper.ml or 0) <= 0 then return end
    if copper.fluid == F.RANCID_FAT then
        table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatRancid"))
        return
    end
    for _, fat in ipairs(F.COPPER_FATS) do
        if copper.fluid == fat.melted then
            table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatMelted"))
        elseif copper.fluid == fat.raw then
            local now = getGameTime():getWorldAgeHours()
            table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatRendering",
                UI.hoursText(Hearth.hoursToTurn(copper) or 0), UI.hoursText(math.max((copper.offAt or now) - now, 0))))
        end
    end
end)
