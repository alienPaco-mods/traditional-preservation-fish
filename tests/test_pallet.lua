-- Checks the Stockfish Pallet outside the game. Run from the mod folder: luajit tests/test_pallet.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()
dofile("42/media/lua/shared/TraditionalPreservationFish.lua")
local F = TraditionalPreservationFish
local Tiles = require "TraditionalPreservationFish/Tiles"

local function stockfish(age, weight)
    local modData = { fishName = "Walleye", matureAge = age }
    local fish = { fullType = "TraditionalPreservationFish.ColdDriedFish", weight = weight or 0.2 }
    function fish:getFullType() return self.fullType end
    function fish:getModData() return modData end
    function fish:getAge() return age end
    function fish:getActualWeight() return self.weight end
    function fish:getModelIndex() return 0 end
    function fish:getDisplayName() return self.name or "" end
    function fish:setName(name) self.name = name end
    function fish:setCustomName() end
    function fish:setTooltip() end
    return fish
end
local function other(fullType, weight)
    return { getFullType = function() return fullType end, getActualWeight = function() return weight or 1 end }
end
local function container(items)
    local box = {}
    function box:getItems() return H.list(items) end
    function box:getContentsWeight()
        local weight = 0
        for _, item in ipairs(items) do weight = weight + item:getActualWeight() end
        return weight
    end
    return box
end
local function bale(items)
    local inside = container(items)
    local item = other(F.BALE_TYPE)
    item.getInventory = function() return inside end
    item.getActualWeight = function() return inside:getContentsWeight() end
    return item
end

-- Where it ripens faster
check("a loft ripens twice as fast", F.palletSpeed("Sheltered", 1) == 2 and F.palletSpeed("Sheltered", 2) == 2)
check("a ground-floor room half as fast again", F.palletSpeed("Sheltered", 0) == 1.5)
check("covered, outdoors and a basement no faster than a shelf", F.palletSpeed("Covered", 1) == 1 and F.palletSpeed("Open", 0) == 1
    and F.palletSpeed("Basement", -1) == 1)

-- The stack
check("an empty pallet shows no stack", F.palletLevel(container({})) == nil)
check("a little stockfish shows the low stack", F.palletLevel(container({ stockfish(0, 0.2) })) == 1)
local twoThirds, full = {}, {}
for i = 1, 60 do twoThirds[i] = stockfish(0, 0.2) end
for i = 1, 100 do full[i] = stockfish(0, 0.2) end
check("12 of 20 weight shows the middle stack", F.palletLevel(container(twoThirds)) == 2)
check("20 of 20 the full one", F.palletLevel(container(full)) == 3)
check("anything else on it hides the stack", F.palletLevel(container({ stockfish(0), other("Base.Plank") })) == nil)
check("salt fish too", F.palletLevel(container({ stockfish(0), other("TraditionalPreservationFish.SaltDriedFish") })) == nil)
check("a bale of stockfish counts", F.palletLevel(container({ bale({ stockfish(0), stockfish(0) }) })) == 1)
check("a bale with anything else doesn't", F.palletLevel(container({ bale({ stockfish(0), other("Base.Plank") }) })) == nil)

-- Ripening
local fresh, ripe, inBale, old = stockfish(10), stockfish(70), stockfish(10), stockfish(10)
old:getModData().matureAge = nil
ripe:getModData().matureAge = 10
F.ripenOnPallet(container({ fresh, ripe, old, bale({ inBale }) }), 15)
check("extra days move the stamp back", fresh:getModData().matureAge == -5 and near(F.ripeness(fresh), 0.25))
check("fish in a bale on it ripen too", inBale:getModData().matureAge == -5)
check("a ripe fish and one made before maturing are left alone", ripe:getModData().matureAge == 10 and old:getModData().matureAge == nil)

-- In the world
Events = Events or {}
function isClient() return false end
MapObjects = { OnLoadWithSprite = function() end }
local placeOf = "Sheltered"
package.loaded["TraditionalPreservationCore/Weather"].placeOf = function() return placeOf end
local hours = 100
function getGameTime() return { getWorldAgeHours = function() return hours end } end
dofile("42/media/lua/server/TraditionalPreservationFishPallet.lua")
local shown
local onIt = stockfish(0)
local floor = 1
local pallet = { modData = {} }
function pallet:getContainer() return container({ onIt }) end
function pallet:getSquare() return { getZ = function() return floor end } end
function pallet:getModData() return self.modData end
function pallet:clearAttachedAnimSprite() shown = {} end
function pallet:addAttachedAnimSpriteByName(name) table.insert(shown, name) end
local entry = {}
local refresh = TraditionalPreservationFishPallet.refresh
refresh(pallet, entry)
check("a pallet starts counting when first seen", pallet.modData.palletHour == 100 and onIt:getModData().matureAge == 0)
check("and shows the low stack", #shown == 1 and shown[1] == Tiles.PALLET_STACKS[1])
hours = 100.5
refresh(pallet, entry)
check("less than an hour waits", pallet.modData.palletHour == 100 and onIt:getModData().matureAge == 0)
hours = 124
refresh(pallet, entry)
check("a day in a loft gives a day more", pallet.modData.palletHour == 124 and near(onIt:getModData().matureAge, -1))
floor, hours = 0, 148
refresh(pallet, entry)
check("a day in a ground-floor room half a day more", near(onIt:getModData().matureAge, -1.5))
placeOf, hours = "Basement", 172
refresh(pallet, entry)
check("a day in a basement nothing more", near(onIt:getModData().matureAge, -1.5) and pallet.modData.palletHour == 172)

H.done()
