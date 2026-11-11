-- Checks the Stockfish Pallet outside the game. Run from the mod folder: luajit tests/test_pallet.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
local F = TraditionalPreservationFishMeat
local Tiles = require "TraditionalPreservationFishMeat/Tiles"

local function stockfish(age, weight)
    local modData = { fishName = "Walleye", matureAge = age }
    local fish = { fullType = "TraditionalPreservationFishMeat.ColdDriedFish", weight = weight or 0.2 }
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
check("salt fish too", F.palletLevel(container({ stockfish(0), other("TraditionalPreservationFishMeat.SaltDriedFish") })) == nil)
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

-- The bale
check("a bale takes stockfish", F.acceptBale(nil, stockfish(0)))
check("and nothing else", not F.acceptBale(nil, other("TraditionalPreservationFishMeat.SaltDriedFish"))
    and not F.acceptBale(nil, other("Base.Plank")))
local many = {}
for i = 1, 60 do many[i] = stockfish(0, 0.2) end
table.insert(many, 1, other("Base.Plank", 0.1))
local load = F.baleLoad(many)
check("a bale is loaded up to 10 weight", #load == 50 and load[1] == many[2])

-- An inventory that holds items and makes what it is asked for.
local function inventory(items)
    local inv = { items = items }
    local function owned(item)
        item.getContainer = function() return inv end
        return item
    end
    for _, item in ipairs(items) do owned(item) end
    function inv:getItems() return H.list(self.items) end
    function inv:contains(item)
        for _, held in ipairs(self.items) do if held == item then return true end end
        return false
    end
    function inv:Remove(item)
        for i, held in ipairs(self.items) do
            if held == item then table.remove(self.items, i) return end
        end
    end
    function inv:AddItem(item)
        if type(item) == "string" then
            local made = other(item, 0)
            local modData, weight, uses = {}, nil, 5
            made.getModData = function() return modData end
            made.setCustomWeight = function() end
            made.setActualWeight = function(_, w) weight = w end
            made.getActualWeight = function() return weight end
            made.getCurrentUses = function() return uses end
            made.setCurrentUses = function(_, n) uses = n end
            if item == F.BALE_TYPE then
                local inside = inventory({})
                made.getInventory = function() return inside end
            end
            item = made
        end
        table.insert(self.items, owned(item))
        return item
    end
    function inv:getFirstEvalRecurse(fn)
        for _, item in ipairs(self.items) do if fn(item) then return item end end
        return nil
    end
    return inv
end
local function twine(uses)
    local item = other("Base.Twine", 0.5)
    item.uses = uses
    function item:getCurrentUses() return self.uses end
    function item:UseAndSync()
        self.uses = self.uses - 1
        if self.uses == 0 then self:getContainer():Remove(self) end
    end
    return item
end
local rope = other("Base.Rope", 0.8)
local a, b, string1 = stockfish(0), stockfish(0), twine(1)
local inv = inventory({ a, b, rope, string1 })
local cordItem, cord = F.findCord(inv)
check("twine is the cord when there is some", cordItem == string1 and cord.key == "twine")
local tied = F.tieBale(inv, { a, b }, cordItem, cord)
check("tying moves the fish into the bale", tied:getInventory():contains(a) and tied:getInventory():contains(b)
    and not inv:contains(a) and not inv:contains(b))
check("and uses the twine's last use up", not inv:contains(string1))
check("the bale records its cord and weighs it", tied:getModData().cord == "twine" and near(tied:getActualWeight(), 0.1))
check("with no twine left the rope is the cord", F.findCord(inv) == rope)
check("a twine with no use left is no cord", F.findCord(inventory({ twine(0) })) == nil)
F.untieBale(inv, tied)
local given
for _, item in ipairs(inv.items) do if item:getFullType() == "Base.Twine" then given = item end end
check("untying gives the fish back", inv:contains(a) and inv:contains(b) and not inv:contains(tied))
check("and a twine of one use", given ~= nil and given:getCurrentUses() == 1)
local roped = F.tieBale(inv, { a }, rope, F.cordByKey("rope"))
check("a rope is taken whole", not inv:contains(rope) and near(roped:getActualWeight(), 0.8))
F.untieBale(inv, roped)
check("and given back whole", inv:getFirstEvalRecurse(function(item) return item:getFullType() == "Base.Rope" end) ~= nil)

-- In the world
Events = Events or {}
function isClient() return false end
MapObjects = { OnLoadWithSprite = function() end }
local placeOf = "Sheltered"
package.loaded["TraditionalPreservationCore/Weather"].placeOf = function() return placeOf end
local hours = 100
function getGameTime() return { getWorldAgeHours = function() return hours end } end
dofile("42/media/lua/server/TraditionalPreservationFishMeatPallet.lua")
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
local refresh = TraditionalPreservationFishMeatPallet.refresh
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
