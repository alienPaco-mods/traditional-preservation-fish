-- Traditional Preservation (Fish & Meat): Connect the Firebox to the Smokehouse chamber with a clay pipe or a stone
-- trench, or Disconnect it (kind nil): the pipe segments or flat stones come back, the clay is lost. The tool stays.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeat"

TPFMFlue = ISBaseTimedAction:derive("TPFMFlue")

local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"
local Hearth = require "TraditionalPreservationCore/Hearth"

local function toolHere(self)
    return self.character:getInventory():containsTagRecurse(ItemTag[self.tool])
end

-- The kit's items, all in the main inventory (the menu brings them there first).
local function kitItems(self)
    local inventory = self.character:getInventory()
    local items = {}
    for _, need in ipairs(F.FLUE_KITS[self.kind].items) do
        local found = inventory:getSomeType(need[1], need[2], ArrayList.new())
        if found:size() < need[2] then return nil end
        for i = 0, need[2] - 1 do table.insert(items, found:get(i)) end
    end
    return items
end

local function stillFits(self)
    if not self.firebox:getSquare() or not self.tile:getSquare() or Hearth.isBurning(self.firebox) then return false end
    if self.kind then return F.flueOf(self.firebox) == nil and F.joinedFirebox(self.tile) == nil end
    return F.flueOf(self.firebox) ~= nil
end

function TPFMFlue:isValid()
    return toolHere(self) and stillFits(self) and (not self.kind or kitItems(self) ~= nil)
end

function TPFMFlue:waitToStart()
    self.character:faceThisObject(self.firebox)
    return self.character:shouldBeTurning()
end

function TPFMFlue:start()
    self:setActionAnim(self.kind == "Stones" and CharacterActionAnims.DigShovel or CharacterActionAnims.Build)
end

function TPFMFlue:complete()
    if not stillFits(self) then return false end
    local inventory = self.character:getInventory()
    if self.kind then
        local items = kitItems(self)
        if not items then return false end
        for _, item in ipairs(items) do inventory:Remove(item) end
        F.setFlue(self.firebox, self.tile, self.kind)
    else
        local kit = F.FLUE_KITS[F.flueOf(self.firebox)]
        for _, need in ipairs(kit.items) do
            if need[1] == kit.back then
                for _ = 1, need[2] do inventory:AddItem(need[1]) end
            end
        end
        F.setFlue(self.firebox, self.tile, nil)
    end
    self.character:getXp():AddXP(Perks.Masonry, F.CONNECT_XP)
    return true
end

function TPFMFlue:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMFlue:getDuration()
    return Action.duration(self.character, self.kind and F.CONNECT_TICKS or F.DISCONNECT_TICKS)
end

-- kind is Pipe or Stones to connect, nil to disconnect; tool is the kit's ItemTag name.
function TPFMFlue:new(character, firebox, tile, kind, tool)
    local o = ISBaseTimedAction.new(self, character)
    o.firebox = firebox
    o.tile = tile
    o.kind = kind
    o.tool = tool
    o.maxTime = o:getDuration()
    return o
end
