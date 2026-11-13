-- Checks Put Fat in the Copper on the Hearth's menu with stand-ins for the engine. Run from the mod folder:
-- luajit tests/test_fat_ui.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
package.path = (os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/42/media/lua/shared/?.lua;" .. package.path
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's and the core's own modules and actions load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") or name:find("^TimedActions/TP") then return realRequire(name) end
end

local ui = H.installMenus()
AnimalPartsDefinitions = { animals = {} }

local Hearth = require "TraditionalPreservationCore/Hearth"
require "TraditionalPreservationFishMeatFatUI"
require "TraditionalPreservationCore/CopperUI"
local F = TraditionalPreservationFishMeat
local onFillMenu = H.handlers.OnFillWorldObjectContextMenu[1]

local function hearth(copper)
    local modData = { [Hearth.KEY] = { [Hearth.COPPER] = copper or {} } }
    local square = { getX = function() return 5 end, getY = function() return 5 end, getZ = function() return 0 end }
    return {
        class = "IsoFireplace",
        getSprite = function() return { getName = function() return Hearth.sprite("Empty", 0) end } end,
        getModData = function() return modData end,
        getSquare = function() return square end,
        getTileName = function() return "Stone Oven" end,
        isLit = function() return false end,
        getFuelAmount = function() return 120 end,
    }
end

local function fat(fullType, rotten)
    return {
        getFullType = function() return fullType end,
        isRotten = function() return rotten or false end,
        getFluidContainer = function() return nil end,
        isFavorite = function() return false end,
        hasTag = function() return false end,
        getAge = function() return 1 end,
        getOffAgeMax = function() return 4 end,
    }
end

local function open(aHearth)
    local context = H.menu()
    onFillMenu(0, context, { aHearth }, false)
    local sub = context:getOptionFromName(getText("IGUI_CraftingWindow_TPHearth")).subOption
    return sub:getOptionFromName(getText("ContextMenu_TraditionalPreservationFishMeat_FatInCopper"))
end

check("with no raw fat carried the Hearth's menu has no fat row", open(hearth()) == nil)
local pork, pork2, suet, mutton = fat("TraditionalPreservationFishMeat.PorkFat"), fat("TraditionalPreservationFishMeat.PorkFat"),
    fat("TraditionalPreservationFishMeat.BeefSuet"), fat("TraditionalPreservationFishMeat.MuttonFat")
ui.carried = { pork, suet, pork2, mutton, fat("TraditionalPreservationFishMeat.PorkFat", true), fat("Base.Lard") }
local empty = hearth()
local rows = open(empty).subOption.options
check("carrying both kinds gives a row each, counting the pieces and leaving rotten ones out", #rows == 2
    and rows[1].name == getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_PorkFat", "2")
    and rows[2].name == getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_Suet", "2"))
check("an empty copper takes either", not rows[1].notAvailable and not rows[2].notAvailable)
local character = { isTimedActionInstant = function() return false end }
rows[2].onSelect(character, unpack(rows[2].args))
local queued = ui.queued[#ui.queued]
check("choosing a row walks over, takes the pieces in hand and queues the job", ui.walks == 1 and #ui.moved == 2
    and queued.Type == "TPFMFatCopper" and queued.raw == "RawSuet" and queued.pieces[1] == suet and queued.pieces[2] == mutton
    and queued.hearth == empty)
rows = open(hearth({ ml = 500, fluid = "RawPorkFat", tempC = 20 })).subOption.options
check("a copper of pork fat takes more pork fat and refuses suet with the reason", not rows[1].notAvailable and rows[2].notAvailable == true
    and rows[2].toolTip.description == getText("IGUI_TraditionalPreservationFishMeat_FatNoRoom"))
rows = open(hearth({ ml = 500, fluid = "MeltedLard", tempC = 90 })).subOption.options
check("melted fat takes no raw", rows[1].notAvailable == true and rows[2].notAvailable == true)
rows = open(hearth({ ml = 500, fluid = "Water", tempC = 20 })).subOption.options
check("nor does water", rows[1].notAvailable == true)

check("no text would make the game's formatter warn" .. (H.textWarnings[1] and " (" .. table.concat(H.textWarnings, "; ") .. ")" or ""),
    #H.textWarnings == 0)

H.done()
