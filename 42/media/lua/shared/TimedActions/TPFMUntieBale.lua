-- Traditional Preservation (Fish & Meat): Untie Bale, putting a Stockfish Bale's fish and the cord that tied it back
-- in the inventory.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeat"

TPFMUntieBale = ISBaseTimedAction:derive("TPFMUntieBale")

local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"

function TPFMUntieBale:isValid()
    return self.character:getInventory():contains(self.bale)
end

function TPFMUntieBale:start()
    self:setActionAnim(CharacterActionAnims.Craft)
end

function TPFMUntieBale:complete()
    if not self.character:getInventory():contains(self.bale) then return false end
    F.untieBale(self.character:getInventory(), self.bale)
    return true
end

function TPFMUntieBale:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMUntieBale:getDuration()
    return Action.duration(self.character, F.BALE_UNTIE_TICKS)
end

function TPFMUntieBale:new(character, bale)
    local o = ISBaseTimedAction.new(self, character)
    o.bale = bale
    o.maxTime = o:getDuration()
    return o
end
