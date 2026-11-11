-- Traditional Preservation (Fish): Untie Bale, putting a Stockfish Bale's fish and the cord that tied it back
-- in the inventory.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFish"

TPFishUntieBale = ISBaseTimedAction:derive("TPFishUntieBale")

local F = TraditionalPreservationFish
local Action = require "TraditionalPreservationCore/Action"

function TPFishUntieBale:isValid()
    return self.character:getInventory():contains(self.bale)
end

function TPFishUntieBale:start()
    self:setActionAnim(CharacterActionAnims.Craft)
end

function TPFishUntieBale:complete()
    if not self.character:getInventory():contains(self.bale) then return false end
    F.untieBale(self.character:getInventory(), self.bale)
    return true
end

function TPFishUntieBale:perform()
    ISBaseTimedAction.perform(self)
end

function TPFishUntieBale:getDuration()
    return Action.duration(self.character, F.BALE_UNTIE_TICKS)
end

function TPFishUntieBale:new(character, bale)
    local o = ISBaseTimedAction.new(self, character)
    o.bale = bale
    o.maxTime = o:getDuration()
    return o
end
