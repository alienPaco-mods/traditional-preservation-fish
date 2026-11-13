-- Traditional Preservation (Fish & Meat): Put Fat in the Copper, putting pieces of raw fat from the inventory into
-- a Hearth's copper (TP Core's), as many as fit.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeatFat"

TPFMFatCopper = ISBaseTimedAction:derive("TPFMFatCopper")

local F = TraditionalPreservationFishMeat
local Hearth = require "TraditionalPreservationCore/Hearth"
local Action = require "TraditionalPreservationCore/Action"

local TICKS_A_PIECE = 15

-- The pieces still on the player and not rotten.
local function piecesHere(self)
    local inventory, here = self.character:getInventory(), {}
    for _, item in ipairs(self.pieces) do
        if inventory:containsRecursive(item) and not item:isRotten() then table.insert(here, item) end
    end
    return here
end

function TPFMFatCopper:isValid()
    return self.hearth:getSquare() ~= nil and #piecesHere(self) > 0
        and F.copperFatRoom(Hearth.copperState(self.hearth:getModData()), self.raw) > 0
end

function TPFMFatCopper:waitToStart()
    self.character:faceThisObject(self.hearth)
    return self.character:shouldBeTurning()
end

function TPFMFatCopper:start()
    self:setActionAnim("Loot")
end

function TPFMFatCopper:complete()
    -- Brought up to the minute first, so the fat mixes with the copper as it is now.
    local copper = Hearth.copperOf(self.hearth)
    local now = getGameTime():getWorldAgeHours()
    local pieces, hoursLeft = piecesHere(self), {}
    for index, item in ipairs(pieces) do hoursLeft[index] = F.fatHoursLeft(item) end
    local count = F.putFatInCopper(copper, self.raw, hoursLeft, now)
    for index = 1, count do
        pieces[index]:getContainer():Remove(pieces[index])
    end
    if Hearth.World then Hearth.World.refresh(self.hearth) end
    return count > 0
end

function TPFMFatCopper:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMFatCopper:getDuration()
    return Action.duration(self.character, TICKS_A_PIECE * #self.pieces)
end

function TPFMFatCopper:new(character, hearth, raw, pieces)
    local o = ISBaseTimedAction.new(self, character)
    o.hearth = hearth
    o.raw = raw
    o.pieces = pieces
    o.maxTime = o:getDuration()
    return o
end
