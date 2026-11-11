-- Traditional Preservation (Fish & Meat): Tie a Bale, tying stockfish from the inventory into a Stockfish Bale with one use
-- of Twine or a Rope.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeat"

TPFMTieBale = ISBaseTimedAction:derive("TPFMTieBale")

local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"

local function cordLeft(self)
    return self.character:getInventory():contains(self.cordItem)
        and (not self.cord.uses or self.cordItem:getCurrentUses() >= self.cord.uses)
end

local function fishHere(self)
    local inventory = self.character:getInventory()
    for _, fish in ipairs(self.fish) do
        if not inventory:contains(fish) then return false end
    end
    return true
end

function TPFMTieBale:isValid()
    return cordLeft(self) and fishHere(self)
end

function TPFMTieBale:start()
    self:setActionAnim(CharacterActionAnims.Craft)
end

function TPFMTieBale:complete()
    if not cordLeft(self) or not fishHere(self) then return false end
    F.tieBale(self.character:getInventory(), self.fish, self.cordItem, self.cord)
    return true
end

function TPFMTieBale:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMTieBale:getDuration()
    return Action.duration(self.character, F.BALE_TIE_TICKS)
end

function TPFMTieBale:new(character, fish, cordItem, cord)
    local o = ISBaseTimedAction.new(self, character)
    o.fish = fish
    o.cordItem = cordItem
    o.cord = cord
    o.maxTime = o:getDuration()
    return o
end
