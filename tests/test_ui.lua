-- Checks the station slots outside the game. Run from the mod folder: luajit tests/test_ui.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
ModData = { getOrCreate = function() return {} end }
local handlers = {}
-- Each event calls its handlers in the order they were added, as the game does.
Events = setmetatable({}, { __index = function(_, name) return { Add = function(handler)
    local before = handlers[name]
    handlers[name] = before and function(...) before(...) return handler(...) end or handler
end } end })
-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationFishMeat/") or name:find("^TraditionalPreservationCore/") then return realRequire(name) end
end
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")

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
TraditionalPreservationFishMeatWorld = {
    busyStacks = function() return busyStacks end,
    track = function() end,
    refresh = function() end,
}
ISMoveableSpriteProps = {}
function ISMoveableSpriteProps:canPlaceMoveable() return true end
dofile("42/media/lua/client/TraditionalPreservationFishMeatUI.lua")


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

local PACKED, PRESSED = "TraditionalPreservationFishMeat.SaltPackedFish", "TraditionalPreservationFishMeat.SaltPressedFish"
local GUTTED, HALF = "TraditionalPreservationFishMeat.GuttedFish", "TraditionalPreservationFishMeat.FishHalf"
local TUB, FRAME = "traditionalpreservationfishmeat_01_0", "traditionalpreservationfishmeat_01_7"
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
local CURED = "TraditionalPreservationFishMeat.SaltCuredMeat"
check("a frame is green for Salt Cured meat", green(station(FRAME), fish(CURED, 0.3)))
check("not for meat on a fish stack, nor fish on a meat one", not green(station(FRAME, { fish(PRESSED, 0.5) }), fish(CURED, 0.3))
    and not green(station(FRAME, { fish(CURED, 0.3) }), fish(GUTTED, 0.5)))
check("meat stacks with meat", green(station(FRAME, { fish(CURED, 0.3) }), fish(CURED, 0.5)))
check("a half over the limit is refused", not green(station(FRAME), fish(HALF, 3)))
local MEDIUM, LARGE = "traditionalpreservationfishmeat_02_0", "traditionalpreservationfishmeat_02_3"
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
check("not past its capacity", not green(station(TUB, { fish(PACKED, TraditionalPreservationFishMeat.TUB_CAPACITY - 0.5) }), fish(PACKED, 1)))
local MEAT = "TraditionalPreservationFishMeat.SaltPackedMeat"
check("an empty tub is green for packed meat", green(station(TUB), fish(MEAT, 0.5)))
check("meat goes in with meat", green(station(TUB, { fish(MEAT, 0.3) }), fish(MEAT, 0.5)))
check("not with fish", not green(station(TUB, { fish(PACKED, 1) }), fish(MEAT, 0.5)))
check("nor fish with meat", not green(station(TUB, { fish(MEAT, 0.5) }), fish(PACKED, 1)))

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
check("a refused drop says why", halos[1] == "IGUI_TraditionalPreservationFishMeat_NeedsPressed" and vanillaUps == 1)

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
check("a running tub says it's in use", refusedWith(station(TUB, nil, true)) == "IGUI_TraditionalPreservationFishMeat_TubInUse")
busyStacks = 1
check("a finished one says to empty it", refusedWith(station(TUB)) == "IGUI_TraditionalPreservationFishMeat_TubNotEmpty")
busyStacks = 0
local tubSlot = station(TUB)
halos = {}
ISCraftLogicPanel.ItemSlotAddItems("player", tubSlot.resource:getGameEntity(), tubSlot, { fish(PRESSED, 1) }, tubSlot.resource:getGameEntity():getComponent())
check("adding the wrong fish is refused", #entityList == 0 and halos[1] == "IGUI_TraditionalPreservationFishMeat_NeedsPacked")
ISCraftLogicPanel.ItemSlotAddItems("player", tubSlot.resource:getGameEntity(), tubSlot, { fish(PACKED, 1), fish(PACKED, 1) }, tubSlot.resource:getGameEntity():getComponent())
check("the right fish goes in", #entityList == 2)
entityList, halos = {}, {}
ISCraftLogicPanel.ItemSlotAddItems("player", tubSlot.resource:getGameEntity(), tubSlot, { fish(MEAT, 0.5), fish(PACKED, 1) }, tubSlot.resource:getGameEntity():getComponent())
check("meat and fish dragged in together are refused at the fish", #entityList == 1 and halos[1] == "IGUI_TraditionalPreservationFishMeat_MixedTub")

-- A hanging stack's popup
local function stackLines(recipeName, modData, ledger)
    TraditionalPreservationFishMeat.getLedger = function() return ledger end
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
local coldLines = stackLines("TraditionalPreservationFishMeat.HangFishToColdDry", { dried = 384 }, winter)
check("a cold stack says so", coldLines["IGUI_TraditionalPreservationFishMeat_Method:"] == "IGUI_TraditionalPreservationFishMeat_MethodCold")
check("and shows its real rate and progress", coldLines["IGUI_TraditionalPreservationFishMeat_Rate:"] == "100%" and coldLines["IGUI_TraditionalPreservationFishMeat_Progress:"] == "50%")
check("with no warning in a cold season", coldLines["IGUI_TraditionalPreservationFishMeat_Spoilage:"] == nil)
local saltLines = stackLines("HangFishToDry", { dried = 144 }, winter)
check("a salt stack shows its own rate", saltLines["IGUI_TraditionalPreservationFishMeat_Method:"] == "IGUI_TraditionalPreservationFishMeat_MethodSalt" and saltLines["IGUI_TraditionalPreservationFishMeat_Rate:"] == "44%")
local warm = { wetness = 0, temperature = 18, coldRate = 0, openRate = 0.8, shelteredRate = 0.52, rawSpoiling = true }
local warmLines = stackLines("HangFishToColdDry", { dried = 10, spoiled = 0.4 }, warm)
check("a warm season stops cold drying", warmLines["IGUI_TraditionalPreservationFishMeat_Rate:"] == "IGUI_TraditionalPreservationFishMeat_StoppedTooWarm")
check("and warns of spoilage", warmLines["IGUI_TraditionalPreservationFishMeat_Spoilage:"] == "IGUI_TraditionalPreservationFishMeat_SpoilingWarm")
check("and has no time left to give", warmLines["IGUI_TraditionalPreservationFishMeat_TimeLeft:"] == "IGUI_TraditionalPreservationFishMeat_Paused")
check("other recipes are left alone", stackLines("DryCorn", {}, winter) == nil)

-- The game can't format a bare %, so a line's own percent sign belongs in the value it is given.
local translations = io.open("42/media/lua/shared/Translate/EN/IG_UI.json"):read("*a")
check("translations have no bare percent signs", not translations:find("%%%D"))

-- Picked-up beams can't be put down in a room
local function placing(spriteName, inRoom)
    return ISMoveableSpriteProps.canPlaceMoveable({ spriteName = spriteName }, nil, { isInARoom = function() return inRoom end }, nil)
end
check("a beam can't be put down in a room", not placing("traditionalpreservationfishmeat_02_0", true) and not placing("traditionalpreservationfishmeat_02_3", true))
check("but can outdoors or under an open roof", placing("traditionalpreservationfishmeat_02_2", false))
check("and the frame can go anywhere", placing("traditionalpreservationfishmeat_01_0", true))

-- Names follow the days in any container the inventory shows
local renamed = {}
local fakeFish = { fullType = "TraditionalPreservationFishMeat.ColdDriedFish" }
local container = {}
function container:getAllTypeRecurse(fullType)
    return H.list(fullType == fakeFish.fullType and { fakeFish } or {})
end
local F = TraditionalPreservationFishMeat
local realRename = F.rename
F.rename = function(item) table.insert(renamed, item) end
handlers.OnRefreshInventoryWindowContainers({ backpacks = { { inventory = container } } }, "begin")
check("names wait for the window to finish refreshing", #renamed == 0)
handlers.OnRefreshInventoryWindowContainers({ backpacks = { { inventory = container } } }, "end")
check("then every fish stage in each shown container is renamed", #renamed == 1 and renamed[1] == fakeFish)
check("and the player's things every hour", handlers.EveryHours ~= nil)
F.rename = realRename

-- Rinse at Sink
local ui = H.installMenus()
dofile("42/media/lua/shared/TimedActions/TPFMRinse.lua")
local function rinsable(fullType, name)
    local modData = {}
    return { class = "InventoryItem", getFullType = function() return fullType end, getModData = function() return modData end,
        getDisplayName = function() return name or "Walleye (Salt Cured)" end, getTexture = function() return "fish icon" end }
end
local sink
local person = {
    getX = function() return 10 end, getY = function() return 10 end, getZ = function() return 0 end,
    isTimedActionInstant = function() return false end,
}
function getSpecificPlayer() return person end
function getCell()
    return { getGridSquare = function(_, x, y)
        if x ~= 12 or y ~= 10 or not sink then return nil end
        return { getObjects = function() return H.list({ sink }) end }
    end }
end
local function rinseMenu(items, context)
    context = context or H.menu()
    ui.queued = {}
    handlers.OnFillInventoryObjectContextMenu(0, context, items)
    return context
end
local function rinseOption(menu)
    return menu:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_RinseAtSink")
end
local pressedOne, pressedTwo = rinsable("TraditionalPreservationFishMeat.SaltPressedFish"), rinsable("TraditionalPreservationFishMeat.SaltPressedFish")
local stack = { items = { pressedOne, pressedOne, pressedTwo } }
check("no sink, no option: the Rinse recipe covers carried water", #rinseMenu({ stack }).options == 0)
sink = {
    hasWater = function() return true end, isTaintedWater = function() return false end,
    getFluidAmount = function() return 10 end, getSquare = function() return "sink square" end,
}
check("no option on a fish that isn't Salt Cured", #rinseMenu({ rinsable("TraditionalPreservationFishMeat.SaltDriedFish") }).options == 0)

-- Vanilla's recipe submenu for the fish already there: the option joins it.
local withSub = H.menu()
local vanillaSub = withSub:getNew()
withSub:addSubMenu(withSub:addOption("Walleye (Salt Cured)"), vanillaSub)
vanillaSub:addOption("Slice")
rinseMenu({ stack }, withSub)
local atSink = rinseOption(vanillaSub)
check("near a sink it goes in the fish's submenu", #withSub.options == 1 and atSink ~= nil)
atSink.onSelect(atSink.target, unpack(atSink.args))
check("and rinses each fish of a stack once, after walking to the sink", #ui.queued == 2 and ui.queued[1].fish == pressedOne
    and ui.queued[2].fish == pressedTwo and ui.queued[1].source == sink and ui.walks == 1)

-- A lone recipe option: turned into the fish's submenu where it stands.
function ISInventoryPaneContextMenu.OnNewCraft() end
local lone = H.menu()
lone:addOption("Eat")
local slice = lone:addOption("Slice", pressedOne, ISInventoryPaneContextMenu.OnNewCraft)
slice.iconTexture = "slice icon"
rinseMenu({ stack }, lone)
local parent = lone.options[2]
check("a lone recipe becomes the fish's submenu in its place", #lone.options == 2 and parent.name == "Walleye (Salt Cured)" and parent.onSelect == nil)
local moved = parent.subOption.options[1]
check("holding the recipe as it was, then Rinse at Sink", moved.name == "Slice" and moved.target == pressedOne
    and moved.onSelect == ISInventoryPaneContextMenu.OnNewCraft and moved.iconTexture == "slice icon" and rinseOption(parent.subOption) ~= nil)

sink.isTaintedWater = function() return true end
check("a sink of tainted water doesn't count", #rinseMenu({ stack }).options == 0)

-- Tie a Bale and Untie Bale
dofile("42/media/lua/shared/TimedActions/TPFMTieBale.lua")
dofile("42/media/lua/shared/TimedActions/TPFMUntieBale.lua")
function getItemNameFromFullType(fullType) return fullType == "Base.Rope" and "Rope" or "Twine" end
local cordItem
local carried = { getFirstEvalRecurse = function(_, fn) return cordItem and fn(cordItem) and cordItem or nil end }
person.getInventory = function() return carried end
local function stockfishItem(weight)
    return { class = "InventoryItem", getFullType = function() return "TraditionalPreservationFishMeat.ColdDriedFish" end,
        getActualWeight = function() return weight end, getDisplayName = function() return "Gutted Walleye (Cold Dried)" end,
        getTexture = function() return "fish icon" end, getModData = function() return {} end }
end
local function tieOption(context)
    local sub = context.options[1] and context.options[1].subOption
    return sub and sub:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_TieBale")
end
local dried = {}
for i = 1, 60 do dried[i] = stockfishItem(0.2) end
local noCord = rinseMenu({ { items = { dried[1], unpack(dried) } } })
check("no cord, the Tie option says what it needs", tieOption(noCord) ~= nil and tieOption(noCord).notAvailable == true)
cordItem = { getFullType = function() return "Base.Twine" end, getCurrentUses = function() return 3 end,
    getDisplayName = function() return "Twine" end }
local withCord = rinseMenu({ { items = { dried[1], unpack(dried) } } })
local tie = tieOption(withCord)
check("with twine it goes in the fish's submenu", tie ~= nil and not tie.notAvailable)
tie.onSelect(tie.target, unpack(tie.args))
check("and ties the first 10 weight with the twine", #ui.queued == 1 and #ui.queued[1].fish == 50
    and ui.queued[1].cordItem == cordItem and ui.queued[1].cord.key == "twine")
check("no Tie option on salt fish", tieOption(rinseMenu({ rinsable("TraditionalPreservationFishMeat.SaltDriedFish") })) == nil)
local baleData = { cord = "rope" }
local bale = { class = "InventoryItem", getFullType = function() return F.BALE_TYPE end, getModData = function() return baleData end }
local untieMenu = rinseMenu({ bale })
local untie = untieMenu:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_UntieBale")
check("a bale has Untie Bale", untie ~= nil and untie.toolTip ~= nil)
untie.onSelect(untie.target, unpack(untie.args))
check("which unties it", #ui.queued == 1 and ui.queued[1].bale == bale)

-- The pallet's right-click line
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local function palletAt(z, place)
    package.loaded["TraditionalPreservationCore/Weather"].placeOf = function() return place end
    return { getSprite = function() return { getName = function() return Tiles.PALLET end } end,
        getSquare = function() return { getZ = function() return z end } end }
end
local realPlaceOf = package.loaded["TraditionalPreservationCore/Weather"].placeOf
local function palletLine(z, place)
    local context = H.menu()
    handlers.OnFillWorldObjectContextMenu(0, context, { palletAt(z, place) })
    return context.options[1]
end
check("a loft pallet says x2", palletLine(1, "Sheltered").name == "ContextMenu_TraditionalPreservationFishMeat_PalletSpeed")
check("a covered one says it's no faster", palletLine(0, "Covered").name == "ContextMenu_TraditionalPreservationFishMeat_PalletNoSpeed")
check("the line explains the places on hover", palletLine(0, "Sheltered").toolTip.description == "Tooltip_craft_stockfishPalletDesc")
local none = H.menu()
handlers.OnFillWorldObjectContextMenu(0, none, { { getSprite = function() return nil end } })
check("nothing for other objects", #none.options == 0)
package.loaded["TraditionalPreservationCore/Weather"].placeOf = realPlaceOf

H.done()
