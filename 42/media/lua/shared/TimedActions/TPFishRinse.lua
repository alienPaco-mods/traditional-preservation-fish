-- Traditional Preservation (Fish): Rinse at Sink, rinsing the excess salt off one Salt Pressed fish with
-- RINSE_LITRES from a sink, bathtub, barrel or well of clean water. With carried water it is the Rinse recipe.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFish"

TPFishRinse = ISBaseTimedAction:derive("TPFishRinse")

local F = TraditionalPreservationFish
local Action = require "TraditionalPreservationCore/Action"

local function hasWater(self)
    return self.source:getSquare() ~= nil and not self.source:isTaintedWater() and self.source:getFluidAmount() >= F.RINSE_LITRES
end

function TPFishRinse:isValid()
    return self.character:getInventory():containsRecursive(self.fish) and F.canRinse(self.fish) and hasWater(self)
end

function TPFishRinse:waitToStart()
    self.character:faceThisObject(self.source)
    return self.character:shouldBeTurning()
end

function TPFishRinse:start()
    self:setActionAnim("ScrubClothWithSoap")
    self:setOverrideHandModels(nil, nil)
end

function TPFishRinse:complete()
    if not hasWater(self) or not F.canRinse(self.fish) then return false end
    self.source:useFluid(F.RINSE_LITRES)
    F.rinse(self.fish)
    return true
end

function TPFishRinse:perform()
    ISBaseTimedAction.perform(self)
end

function TPFishRinse:getDuration()
    return Action.duration(self.character, F.RINSE_TICKS)
end

function TPFishRinse:new(character, fish, source)
    local o = ISBaseTimedAction.new(self, character)
    o.fish = fish
    o.source = source
    o.maxTime = o:getDuration()
    return o
end
