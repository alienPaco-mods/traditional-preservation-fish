-- Traditional Preservation (Fish & Meat): the Stockfish Pallet. Once an in-game hour it gives the stockfish on it the extra days of
-- ripening its place earned since the last one (while the area was unloaded too, as nothing could move them), and
-- shows the stack while it holds only stockfish.
if isClient() then return end

local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local F = TraditionalPreservationFishMeat

TraditionalPreservationFishMeatPallet = TraditionalPreservationFishMeatPallet or {}

local function isPallet(object)
    local sprite = object:getSprite()
    return sprite ~= nil and sprite:getName() == Tiles.PALLET
end

-- The hour last counted is kept on the pallet, not its movableData, so one picked up and put down starts afresh.
function TraditionalPreservationFishMeatPallet.refresh(pallet, entry, now)
    local container = pallet:getContainer()
    local square = pallet:getSquare()
    if not container or not square then return end
    local modData = pallet:getModData()
    now = now or getGameTime():getWorldAgeHours()
    local last = modData.palletHour or now
    if not modData.palletHour or now - last >= 1 then
        modData.palletHour = now
        local speed = F.palletSpeed(Weather.placeOf(pallet))
        F.ripenOnPallet(container, (now - last) / 24 * (speed - 1))
    end

    local level = F.palletLevel(container)
    Station.showSprites(pallet, entry, tostring(level), level and { Tiles.PALLET_STACKS[level] } or {})
end

local tracker = Station.tracker({
    sprites = { Tiles.PALLET },
    entry = function(object) return isPallet(object) and {} or nil end,
    refresh = function(pallet, entry) TraditionalPreservationFishMeatPallet.refresh(pallet, entry) end,
    scan = true,
})

tracker.start()
