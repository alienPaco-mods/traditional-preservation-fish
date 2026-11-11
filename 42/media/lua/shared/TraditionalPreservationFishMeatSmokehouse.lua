-- Traditional Preservation (Fish & Meat): joining TP Core's Firebox to the Smokehouse chamber (ROADMAP §7, 5b-2b).
-- Connect the Firebox lays a clay pipe (2 Clay Pipe Segments + 1 Clay, a mason's trowel) or a trench roofed with flat
-- stones (3 Flat Stones + 2 Clay, a shovel or spade) from a Firebox to a chamber tile beside it; Disconnect takes it
-- up again, the pipe or stones back, the clay lost. The link lives on the Firebox alone (Core's flue and flueSide):
-- the chamber tile it joins is the square on that side. Each chamber tile is checked on its own, so a bigger shed can
-- reuse the rules.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Hearth = require "TraditionalPreservationCore/Hearth"
local Doors = require "TraditionalPreservationCore/Doors"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"

F.CONNECT_TICKS = 400
F.DISCONNECT_TICKS = 200
F.CONNECT_XP = 5

-- The two ways to join them, in menu order. Items are { full type, count }; the tool (an ItemTag's name) stays.
F.FLUE_KINDS = { "Pipe", "Stones" }
F.FLUE_KITS = {
    Pipe = { tool = "MASONS_TROWEL", items = { { "Base.ClayPipeSegment", 2 }, { "Base.Clay", 1 } }, back = "Base.ClayPipeSegment" },
    Stones = { tool = "DIG_GRAVE", items = { { "Base.FlatStone", 3 }, { "Base.Clay", 2 } }, back = "Base.FlatStone" },
}

local CHAMBER = Tiles.HANGERS.chamber.base
local FACES = #Tiles.HANGERS.chamber.bases
-- World steps (+x east, +y south) by facing (0 S, 1 E): towards the door's end, and to the long side the camera sees.
local DOOR_STEP = { [0] = { 0, 1 }, [1] = { 1, 0 } }
local VISIBLE_STEP = { [0] = { 1, 0 }, [1] = { 0, 1 } }
local SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- The door's tile of each facing needs its front free, as the Firebox's door does (Core's Doors).
do
    local doors = {}
    for face = 0, FACES - 1 do doors[F.spriteName(CHAMBER + face * 2 + 1)] = face == 0 and "S" or "E" end
    Doors.register(doors)
end

-- A chamber tile's facing (0 S, 1 E) and part (0 the back tile, 1 the door's), from its sprite number, or nil.
function F.chamberTile(spriteIndex)
    if not spriteIndex then return nil end
    local offset = spriteIndex - CHAMBER
    if offset < 0 or offset >= FACES * 2 then return nil end
    return math.floor(offset / 2), offset % 2
end

-- The step from a chamber tile to the shed's other tile.
function F.chamberOther(face, part)
    local step = DOOR_STEP[face]
    local sign = part == 0 and 1 or -1
    return step[1] * sign, step[2] * sign
end

-- Whether a Firebox one step (dx, dy) from this chamber tile may join it: a long side, or the back gable of the
-- back tile; never the door's end, nor the shed's other tile.
function F.chamberSideAllowed(face, part, dx, dy)
    if math.abs(dx) + math.abs(dy) ~= 1 then return false end
    local door = DOOR_STEP[face]
    if dx == door[1] and dy == door[2] then return false end
    local ox, oy = F.chamberOther(face, part)
    return not (dx == ox and dy == oy)
end

-- The overlay showing where the flue enters, on the long side the camera sees; nil anywhere else.
function F.entrySprite(kind, face, part, dx, dy)
    local step = VISIBLE_STEP[face]
    if not Tiles.CHAMBER_ENTRY or dx ~= step[1] or dy ~= step[2] then return nil end
    local kindIndex = kind == "Stones" and 1 or kind == "Pipe" and 0
    if not kindIndex then return nil end
    return Tiles.CHAMBER_ENTRY + (kindIndex * FACES + face) * 2 + part
end

-- Why Connect can't be done, as a translation key, or nil. c = { burning, fireboxJoined, chamberJoined, allowed,
-- flueSide (Core's Hearth.flueSideTo: nil on the Firebox's door side) }.
function F.connectRefusal(c)
    if c.fireboxJoined then return "IGUI_TraditionalPreservationFishMeat_FlueFireboxJoined" end
    if c.chamberJoined then return "IGUI_TraditionalPreservationFishMeat_FlueChamberJoined" end
    if not c.allowed then return "IGUI_TraditionalPreservationFishMeat_FlueDoorEnd" end
    if not c.flueSide then return "IGUI_TraditionalPreservationFishMeat_FlueFireboxDoor" end
    if c.burning then return "IGUI_TraditionalPreservationFishMeat_FlueBurning" end
    return nil
end

-- What a kit lacks from counts (full type -> how many) and whether the tool is there: { {type, missing} }.
function F.flueKitMissing(kind, counts, hasTool)
    local missing = {}
    for _, need in ipairs(F.FLUE_KITS[kind].items) do
        local short = need[2] - (counts[need[1]] or 0)
        if short > 0 then table.insert(missing, { need[1], short }) end
    end
    return missing, not hasTool
end

-- The world

local function squareAt(square, dx, dy)
    return getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
end

-- The chamber tile on a square, with its facing and part.
function F.chamberOn(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local face, part = F.chamberTile(F.stationIndex(object))
        if face then return object, face, part end
    end
end

local function fireboxOn(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if Hearth.isFirebox(object) then return object end
    end
end

-- A Firebox's flue kind (Pipe or Stones) and side if it's joined to anything, else nil.
function F.flueOf(firebox)
    local state = Hearth.stateOf(firebox:getModData())
    return state.flue, state.flueSide
end

-- The chamber tile a joined Firebox's flue goes into, or nil (capped, or its shed is gone).
function F.joinedChamber(firebox)
    local flue, side = F.flueOf(firebox)
    if not flue then return nil end
    return F.chamberOn(Hearth.flueSquare(firebox, side))
end

-- Both tiles of a chamber, from either: { {tile, face, part} }.
function F.chamberTiles(tile)
    local face, part = F.chamberTile(F.stationIndex(tile))
    if not face then return {} end
    local tiles = { { tile, face, part } }
    local ox, oy = F.chamberOther(face, part)
    local other, otherFace, otherPart = F.chamberOn(squareAt(tile:getSquare(), ox, oy))
    if other and otherFace == face then table.insert(tiles, { other, otherFace, otherPart }) end
    return tiles
end

-- Every Firebox beside a chamber tile, joined or not: { firebox, tile, face, part, dx, dy, allowed }.
function F.fireboxesBy(tile)
    local found = {}
    for _, entry in ipairs(F.chamberTiles(tile)) do
        local here, face, part = entry[1], entry[2], entry[3]
        for _, step in ipairs(SIDES) do
            local firebox = fireboxOn(squareAt(here:getSquare(), step[1], step[2]))
            if firebox then
                table.insert(found, { firebox = firebox, tile = here, face = face, part = part, dx = -step[1], dy = -step[2],
                    allowed = F.chamberSideAllowed(face, part, step[1], step[2]) })
            end
        end
    end
    return found
end

-- The Firebox joined to this chamber (either tile), with its entry from fireboxesBy, or nil.
function F.joinedFirebox(tile)
    for _, found in ipairs(F.fireboxesBy(tile)) do
        local into = F.joinedChamber(found.firebox)
        if into == found.tile then return found.firebox, found end
    end
end

-- The chamber tile beside a Firebox that it could join, or the one it's joined to: { tile, ... } as fireboxesBy, or nil.
function F.chamberBy(firebox)
    for _, side in ipairs({ "Back", "Left", "Right" }) do
        local tile = F.chamberOn(Hearth.flueSquare(firebox, side))
        if tile then
            for _, found in ipairs(F.fireboxesBy(tile)) do
                if found.firebox == firebox and found.tile == tile then return found end
            end
        end
    end
end

-- The refusal for joining this Firebox to the chamber tile in found (fireboxesBy's), or nil.
function F.connectRefusalFor(found)
    return F.connectRefusal({
        burning = Hearth.isBurning(found.firebox),
        fireboxJoined = F.flueOf(found.firebox) ~= nil,
        chamberJoined = F.joinedFirebox(found.tile) ~= nil,
        allowed = found.allowed,
        flueSide = Hearth.flueSideTo(found.firebox, found.tile:getSquare()),
    })
end

-- Lays the flue, or takes it up (kind nil). The Firebox and both chamber tiles redraw at once.
function F.setFlue(firebox, tile, kind)
    local side = kind and Hearth.flueSideTo(firebox, tile:getSquare())
    Hearth.setFlue(Hearth.stateOf(firebox:getModData()), kind, side)
    if Hearth.World then Hearth.World.refresh(firebox) end
    if TraditionalPreservationFishMeatWorld then
        for _, entry in ipairs(F.chamberTiles(tile)) do TraditionalPreservationFishMeatWorld.refresh(entry[1]) end
    end
end

-- The overlay a chamber tile shows now: where a joined Firebox's flue enters it, if the camera sees that side.
function F.chamberEntry(tile)
    local face, part = F.chamberTile(F.stationIndex(tile))
    if not face then return nil end
    local step = VISIBLE_STEP[face]
    local firebox = fireboxOn(squareAt(tile:getSquare(), step[1], step[2]))
    if not firebox or F.joinedChamber(firebox) ~= tile then return nil end
    return F.entrySprite(F.flueOf(firebox), face, part, step[1], step[2])
end
