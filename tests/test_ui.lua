-- Checks the station slots outside the game. Run from the mod folder: luajit tests/test_ui.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
ModData = { getOrCreate = function() return {} end }
Events = { OnInitGlobalModData = { Add = function() end } }
-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationFish/") or name:find("^TraditionalPreservationCore/") then return realRequire(name) end
end
dofile("42/media/lua/shared/TraditionalPreservationFish.lua")

local halos, vanillaVerdict, vanillaUps, addCalls = {}, true, 0, 0
ResourceIO = { Input = "input", Output = "output" }
ComponentType = { CraftLogic = "plain", DryingCraftLogic = "drying" }
ISMouseDrag = {}
ISInventoryPane = { getActualItems = function(dragging) return dragging end }
HaloTextHelper = { addBadText = function(_, text) table.insert(halos, text) end }
function getPlayer() return "player" end
function getText(key) return key end
ISCraftLogicPanel = { ItemSlotAddItems = function() addCalls = addCalls + 1 end }
ISItemSlot = {}
instanceof = function() return true end
local progressSlots = {}
ISWidgetCraftLogicOutputProgress = { updateProgressItems = function() end }
function ISItemSlot:defaultVerifyItem() return vanillaVerdict end
function ISItemSlot:onMouseUp() vanillaUps = vanillaUps + 1 end

local busyStacks = 0
TraditionalPreservationFishWorld = {
    busyStacks = function() return busyStacks end,
    track = function() end,
    refresh = function() end,
}
ISMoveableSpriteProps = {}
function ISMoveableSpriteProps:canPlaceMoveable() return true end
dofile("42/media/lua/client/TraditionalPreservationFishUI.lua")


local check = H.check

local list = H.list

local function fish(fullType, weight)
    return {
        getFullType = function() return fullType end,
        getActualWeight = function() return weight end,
    }
end

local function station(sprite, stored, running)
    local logic = {
        isRunning = function() return running or false end,
        -- A tub built before a slot change keeps its old count, so nothing should depend on this.
        getFreeOutputSlotCount = function() return 25 end,
    }
    local entity = {
        getSprite = function() return { getName = function() return sprite end } end,
        getComponent = function() return logic end,
    }
    local resource = {
        getIO = function() return ResourceIO.Input end,
        getGameEntity = function() return entity end,
        getStoredItems = function() return list(stored or {}) end,
    }
    return { resource = resource }
end

local PACKED, PRESSED = "TraditionalPreservationFish.SaltPackedFish", "TraditionalPreservationFish.SaltPressedFish"
local GUTTED, HALF = "TraditionalPreservationFish.GuttedFish", "TraditionalPreservationFish.FishHalf"
local TUB, FRAME = "traditionalpreservationfish_01_0", "traditionalpreservationfish_01_7"
local function green(slot, item) return ISItemSlot.defaultVerifyItem({}, slot, item) end

check("a frame is green for pressed fish", green(station(FRAME), fish(PRESSED, 0.5)))
check("not for packed fish", not green(station(FRAME), fish(PACKED, 0.5)))
check("not when the stack is full", not green(station(FRAME, { fish(PRESSED, 2.1) }), fish(PRESSED, 0.5)))
check("not for a fish over the stack limit", not green(station(FRAME), fish(PRESSED, 3)))
check("green while the stack has room", green(station(FRAME, { fish(PRESSED, 0.5) }), fish(PRESSED, 0.5)))
check("a frame is green for gutted fish", green(station(FRAME), fish(GUTTED, 0.5)))
check("and for halves", green(station(FRAME), fish(HALF, 0.5)))
check("not for raw fish", not green(station(FRAME), fish("Base.Walleye", 0.5)))
check("not for a fillet", not green(station(FRAME), fish("Base.FishFillet", 0.5)))
check("not for gutted fish on a salted stack", not green(station(FRAME, { fish(PRESSED, 0.5) }), fish(GUTTED, 0.5)))
check("not for salted fish on a gutted stack", not green(station(FRAME, { fish(GUTTED, 0.5) }), fish(PRESSED, 0.5)))
check("gutted fish and halves share a stack", green(station(FRAME, { fish(GUTTED, 0.5) }), fish(HALF, 0.5)))
check("a half over the limit is refused", not green(station(FRAME), fish(HALF, 3)))
local MEDIUM, LARGE = "traditionalpreservationfish_02_0", "traditionalpreservationfish_02_3"
check("a medium beam takes a fish too heavy for a frame", green(station(MEDIUM), fish(PRESSED, 12)))
check("but not over its limit", not green(station(MEDIUM), fish(PRESSED, 16)))
check("a large beam takes the biggest", green(station(LARGE), fish(GUTTED, 48)))
check("but not over its limit", not green(station(LARGE), fish(GUTTED, 51)))
busyStacks = 3
check("a medium beam has 4 hooks", green(station(MEDIUM), fish(PRESSED, 1)))
busyStacks = 4
check("and no more", not green(station(MEDIUM), fish(PRESSED, 1)))
busyStacks = 2
check("a large beam has 2", not green(station(LARGE), fish(PRESSED, 1)))
busyStacks = 0
check("a tub is green for packed fish", green(station(TUB), fish(PACKED, 2)))
check("not for raw fish", not green(station(TUB), fish("Base.Walleye", 2)))
check("not while pressing", not green(station(TUB, nil, true), fish(PACKED, 2)))
busyStacks = 1
check("not before the pressed fish is out", not green(station(TUB), fish(PACKED, 2)))
busyStacks = 0
check("an empty tub with old slot counts is open", green(station(TUB), fish(PACKED, 2)))
local thirtyFour, thirtyFive = {}, {}
for i = 1, 35 do
    if i < 35 then thirtyFour[i] = fish(PACKED, 0.01) end
    thirtyFive[i] = fish(PACKED, 0.01)
end
check("a tub takes a 35th fish", green(station(TUB, thirtyFour), fish(PACKED, 0.01)))
check("but not a 36th, however light", not green(station(TUB, thirtyFive), fish(PACKED, 0.01)))
check("not past its capacity", not green(station(TUB, { fish(PACKED, TraditionalPreservationFish.TUB_CAPACITY - 0.5) }), fish(PACKED, 1)))

vanillaVerdict = false
check("vanilla can still say no", not green(station(FRAME), fish(PRESSED, 0.5)))
vanillaVerdict = true

local other = station("carpentry_02_122")
check("other mods' slots are left alone", green(other, fish("Base.Plank", 1)))
local output = station(FRAME)
output.resource.getIO = function() return ResourceIO.Output end
check("output slots are left alone", green(output, fish(PACKED, 1)))
check("a slot with no resource is safe", green({}, fish(PACKED, 1)))
local spriteless = station(FRAME)
spriteless.resource.getGameEntity = function() return nil end
check("a slot with no entity is safe", green(spriteless, fish(PACKED, 1)))

local frame = station(FRAME)
ISMouseDrag.dragging = { fish(PACKED, 1) }
ISItemSlot.onMouseUp(frame, 0, 0)
check("a refused drop says why", halos[1] == "IGUI_TraditionalPreservationFish_NeedsPressed" and vanillaUps == 1)

halos = {}
ISMouseDrag.dragging = { fish(PACKED, 1), fish(PRESSED, 0.5) }
ISItemSlot.onMouseUp(frame, 0, 0)
check("a mixed drag that can partly go in says nothing", #halos == 0 and vanillaUps == 2)

ISMouseDrag.dragging = nil
ISItemSlot.onMouseUp(frame, 0, 0)
check("a plain click says nothing", #halos == 0 and vanillaUps == 3)

ISMouseDrag.dragging = { fish(PACKED, 1) }
ISMouseDrag.draggingFocus = frame
ISItemSlot.onMouseUp(frame, 0, 0)
check("dragging from the slot itself says nothing", #halos == 0)
ISMouseDrag.draggingFocus = nil

local entityList = {}
ISEntityUI = { WalkToEntity = function() return true end }
ISItemSlotAddAction = { new = function(_, _, _, item) table.insert(entityList, item); return {} end }
ISTimedActionQueue = { add = function() end }
local function refusedWith(slot)
    halos = {}
    ISCraftLogicPanel.ItemSlotAddItems("player", slot.resource:getGameEntity(), slot, { fish(PACKED, 1) }, slot.resource:getGameEntity():getComponent())
    return halos[1]
end
check("a running tub says it's in use", refusedWith(station(TUB, nil, true)) == "IGUI_TraditionalPreservationFish_TubInUse")
busyStacks = 1
check("a finished one says to empty it", refusedWith(station(TUB)) == "IGUI_TraditionalPreservationFish_TubNotEmpty")
busyStacks = 0
local tubSlot = station(TUB)
halos = {}
ISCraftLogicPanel.ItemSlotAddItems("player", tubSlot.resource:getGameEntity(), tubSlot, { fish(PRESSED, 1) }, tubSlot.resource:getGameEntity():getComponent())
check("adding the wrong fish is refused", #entityList == 0 and halos[1] == "IGUI_TraditionalPreservationFish_NeedsPacked")
ISCraftLogicPanel.ItemSlotAddItems("player", tubSlot.resource:getGameEntity(), tubSlot, { fish(PACKED, 1), fish(PACKED, 1) }, tubSlot.resource:getGameEntity():getComponent())
check("the right fish goes in", #entityList == 2)

-- A hanging stack's popup
local function stackLines(recipeName, modData, ledger)
    TraditionalPreservationFish.getLedger = function() return ledger end
    local slot = {
        craftRecipeData = {
            getRecipe = function() return { getName = function() return recipeName end } end,
            getModData = function() return modData end,
        },
        drawTooltip = "vanilla",
    }
    ISWidgetCraftLogicOutputProgress.updateProgressItems({ progressItems = { getItemSlots = function() return { slot } end } })
    if slot.drawTooltip == "vanilla" then return nil end

    local lines, layout = {}, {}
    function layout:addItem()
        local item = {}
        function item:setLabel(text) self.label = text end
        function item:setValue(text) lines[self.label] = text end
        return item
    end
    function layout:render() return 90 end
    local tip = { width = 50 }
    function tip:getFont() return "font" end
    function tip:getLineSpacing() return 20 end
    function tip:adjustWidth() end
    function tip:DrawText() end
    function tip:beginLayout() return layout end
    function tip:endLayout() end
    function tip:getWidth() return self.width end
    function tip:setWidth(value) self.width = value end
    function tip:setHeight(value) self.height = value end
    slot:drawTooltip(tip)
    check("the popup sizes itself", tip.height == 95 and tip.width == 150)
    return lines
end

local winter = { wetness = 0, temperature = 0, coldRate = 1, openRate = 0.44, shelteredRate = 0.44 }
local coldLines = stackLines("TraditionalPreservationFish.HangFishToColdDry", { dried = 384 }, winter)
check("a cold stack says so", coldLines["IGUI_TraditionalPreservationFish_Method:"] == "IGUI_TraditionalPreservationFish_MethodCold")
check("and shows its real rate and progress", coldLines["IGUI_TraditionalPreservationFish_Rate:"] == "100%" and coldLines["IGUI_TraditionalPreservationFish_Progress:"] == "50%")
check("with no warning in a cold season", coldLines["IGUI_TraditionalPreservationFish_Spoilage:"] == nil)
local saltLines = stackLines("HangFishToDry", { dried = 144 }, winter)
check("a salt stack shows its own rate", saltLines["IGUI_TraditionalPreservationFish_Method:"] == "IGUI_TraditionalPreservationFish_MethodSalt" and saltLines["IGUI_TraditionalPreservationFish_Rate:"] == "44%")
local warm = { wetness = 0, temperature = 18, coldRate = 0, openRate = 0.8, shelteredRate = 0.52, rawSpoiling = true }
local warmLines = stackLines("HangFishToColdDry", { dried = 10, spoiled = 0.4 }, warm)
check("a warm season stops cold drying", warmLines["IGUI_TraditionalPreservationFish_Rate:"] == "IGUI_TraditionalPreservationFish_StoppedTooWarm")
check("and warns of spoilage", warmLines["IGUI_TraditionalPreservationFish_Spoilage:"] == "IGUI_TraditionalPreservationFish_SpoilingWarm")
check("and has no time left to give", warmLines["IGUI_TraditionalPreservationFish_TimeLeft:"] == "IGUI_TraditionalPreservationFish_Paused")
check("other recipes are left alone", stackLines("DryCorn", {}, winter) == nil)

-- The game can't format a bare %, so a line's own percent sign belongs in the value it is given.
local translations = io.open("42/media/lua/shared/Translate/EN/IG_UI.json"):read("*a")
check("translations have no bare percent signs", not translations:find("%%%D"))

-- Picked-up beams can't be put down indoors
local function placing(spriteName, outside)
    return ISMoveableSpriteProps.canPlaceMoveable({ spriteName = spriteName }, nil, { isOutside = function() return outside end }, nil)
end
check("a beam can't be put down indoors", not placing("traditionalpreservationfish_02_0", false) and not placing("traditionalpreservationfish_02_3", false))
check("but can outdoors", placing("traditionalpreservationfish_02_2", true))
check("and the frame can go anywhere", placing("traditionalpreservationfish_01_0", false))

H.done()
