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
local Station = require "TraditionalPreservationCore/Station"
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

-- The ham hung by the door while finished stacks wait in the shed (user's idea): on the door's tile only, by facing.
function F.hamSprite(face, part, finished)
    if part ~= 1 or not finished or not Tiles.CHAMBER_HAM then return nil end
    return Tiles.CHAMBER_HAM + face
end

-- Hot smoking (ROADMAP §7, 5c). A salt stack (Salt Cured fish, or charque) in a chamber joined to a Firebox counts the
-- Firebox's fire on two counters: hot, the hours of the stoked session now running (TP Core's Hearth.logFire), and
-- cold, banked hours and the hours of stoked sessions that broke off. Hot reaching the stack's need finishes it at
-- once as Hot Smoked; short of that it dries on as the Smokehouse always does, and keeps cold for Cold Smoked (5d).
-- The need goes by the heaviest piece, as the press does: a cook is one unbroken run (real hot-smoked fish must reach
-- 63 C inside and hold it).
F.HOT_FISH_HOURS = { { 1.1, 4 }, { 2.2, 6 } }
F.HOT_MEAT_HOURS = { { 0.3, 6 }, { 0.5, 8 } }
F.HOT_MIN_HOURS = 4
F.HOT_MAX_HOURS = 12
F.HOT_FISH = "TraditionalPreservationFishMeat.HotSmokedFish"
F.HOT_MEAT = "TraditionalPreservationFishMeat.HotSmokedMeat"

-- Cold smoke (5d): a stack whose cold counter reaches COLD_SMOKE_SHARE of its clock hours in the shed comes out Cold
-- Smoked when it has dried (smoked-dried fish, balyk, suho meso: a few hours of smoke a day over the drying). Hours
-- with the fire burning dry it at the Covered rate, not Sheltered's: the warm draught through the shed.
F.COLD_SMOKE_SHARE = 1 / 3
F.COLD_FISH_OUT = "TraditionalPreservationFishMeat.ColdSmokedFish"
F.DRY_CURED = "TraditionalPreservationFishMeat.DryCuredMeat"

-- The stoked hours a stack needs, by its heaviest piece: straight between the two points, on past them, clamped.
function F.hotHours(isMeat, heaviest)
    local points = isMeat and F.HOT_MEAT_HOURS or F.HOT_FISH_HOURS
    local low, high = points[1], points[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.max(F.HOT_MIN_HOURS, math.min(hours, F.HOT_MAX_HOURS))
end

-- Sets a new stack's counters and need from its pieces (an ArrayList of items).
function F.startSmoke(modData, items, isMeat)
    local heaviest = 0
    for i = 0, items:size() - 1 do heaviest = math.max(heaviest, items:get(i):getActualWeight()) end
    modData.heaviest = heaviest
    modData.hotNeed = F.hotHours(isMeat, heaviest)
    modData.hot, modData.hotCool, modData.cold = 0, 0, 0
    modData.smokeMeat = isMeat
    modData.smokeFrom, modData.smokeSession, modData.lastStoked, modData.lastBanked = nil, nil, nil, nil
end

-- The ledger totals a stack's draught reads: salt fish's or charque's Covered and Sheltered drying.
local function draughtTotals(modData, ledger)
    if modData.smokeMeat then return ledger.charqueCovered or 0, ledger.charqueSheltered or 0 end
    return ledger.covered or 0, ledger.sheltered or 0
end

-- Since the stack's last look: the share of the hours that were cool enough for cold smoke, and how much more a
-- Covered stack dried than a Sheltered one per hour, from the ledger's totals (a week away reads the week's weather).
-- With no hours between, the weather now.
local function sinceLast(modData, ledger)
    local covered, sheltered = draughtTotals(modData, ledger)
    local hours = (ledger.clock or 0) - (modData.lastClock or ledger.clock or 0)
    local coolShare, draught
    if hours > 0 then
        coolShare = ((ledger.smokeCool or 0) - (modData.lastSmokeCool or 0)) / hours
        draught = ((covered - (modData.lastDraughtCovered or covered)) - (sheltered - (modData.lastDraughtSheltered or sheltered))) / hours
    else
        coolShare = (ledger.temperature or 0) <= F.COLD_SMOKE_MAX and 1 or 0
        draught = 0
    end
    modData.lastClock, modData.lastSmokeCool = ledger.clock or 0, ledger.smokeCool or 0
    modData.lastDraughtCovered, modData.lastDraughtSheltered = covered, sheltered
    return math.max(0, math.min(coolShare, 1)), math.max(draught, 0)
end

-- Brings a stack's counters up to the fire's record (a Firebox's Hearth state), or none (not joined). A new or
-- rebuilt Firebox starts from what it has now; whatever hot the stack had becomes cold, as it does when the session
-- it counted in ends. Of the stoked hours since the last look, those in a session that has since begun are hot.
-- With the ledger (the World's look; tests may leave it out): fire hours count as cold only on cool days, stoked
-- or banked (user: no Cold Smoked in summer from short stoked bursts), so hot keeps its cool part (hotCool) for
-- when its session breaks off; and every hour of fire adds the Covered rate's extra drying.
local function hotToCold(modData)
    modData.cold = (modData.cold or 0) + (modData.hotCool or modData.hot or 0)
    modData.hot, modData.hotCool = 0, 0
end

function F.smokeStep(modData, fire, ledger)
    if not modData.hotNeed then return end
    modData.burning = fire ~= nil and fire.fireMode ~= nil
    local coolShare, draught = 1, 0
    if ledger then coolShare, draught = sinceLast(modData, ledger) end
    if not fire or fire.fireId ~= modData.smokeFrom or (fire.stokedHours or 0) < (modData.lastStoked or 0) then
        hotToCold(modData)
        if fire and fire.fireId then
            modData.smokeFrom, modData.smokeSession = fire.fireId, fire.session
            modData.lastStoked, modData.lastBanked = fire.stokedHours or 0, fire.bankedHours or 0
        else
            modData.smokeFrom, modData.smokeSession = nil, nil
        end
        return
    end
    local stoked = (fire.stokedHours or 0) - modData.lastStoked
    local banked = (fire.bankedHours or 0) - (modData.lastBanked or 0)
    -- No session running now: whatever was stoked since belonged to one that has ended (even one that began and
    -- ended between two looks, while away).
    if not fire.session or fire.session ~= modData.smokeSession then
        local inNew = fire.session and math.min(stoked, (fire.stokedHours or 0) - fire.sessionBase) or 0
        hotToCold(modData)
        modData.cold = modData.cold + (stoked - inNew) * coolShare
        modData.hot, modData.hotCool = inNew, inNew * coolShare
        modData.smokeSession = fire.session
    else
        modData.hotCool = (modData.hotCool or modData.hot) + stoked * coolShare
        modData.hot = modData.hot + stoked
    end
    banked = math.max(banked, 0)
    modData.cold = modData.cold + banked * coolShare
    if modData.dried then modData.dried = modData.dried + (math.max(stoked, 0) + banked) * draught end
    modData.lastStoked, modData.lastBanked = fire.stokedHours or 0, fire.bankedHours or 0
end

-- Whether a stack's hot counter has done its cook.
function F.hotDone(modData)
    return modData.hotNeed ~= nil and (modData.hot or 0) >= modData.hotNeed
end

-- Whether a stack has had smoke for its share of the hours since it was hung (stackId is its start time).
function F.coldNeed(modData, now)
    return math.max(now - (modData.stackId or now), 0) * F.COLD_SMOKE_SHARE
end

function F.coldDone(modData, now)
    return (modData.cold or 0) > 0 and modData.cold >= F.coldNeed(modData, now)
end

-- Stacks whose cook is done, by stackId, with their chamber: the World sets them, the stack's OnUpdate finishes it,
-- its OnCreate swaps the outputs in the chamber's slots. Not saved: the World's next look after a load sets it again.
F.hotStations = {}

-- Swaps a finished stack's outputs, already in the chamber's slots (the engine makes them before OnCreate), for
-- smoked ones made from its inputs: fishType for fish, meatType for meat (Hot Smoked, or Cold Smoked and Dry-Cured).
function F.smokedOutputs(craftRecipeData, station, fishType, meatType)
    local modData = craftRecipeData:getModData()
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    local logic = station:getComponent(ComponentType.DryingCraftLogic)
    local resources = station:getComponent(ComponentType.Resources)
    if not logic or not resources then return false end
    local slots = Station.itemSlots(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local spoiled = modData.spoiled or 0
    for i = 0, math.min(inputs:size(), created:size()) - 1 do
        local input, made = inputs:get(i), created:get(i)
        local hot = instanceItem(input:getFullType() == F.CURED_MEAT and meatType or fishType)
        F.carry(input, hot)
        hot:getModData().stackId = modData.stackId
        hot:getModData().style = modData.style
        hot:setAge(spoiled >= 1 and hot:getOffAgeMax() or hot:getOffAge() * spoiled)
        for j = 0, slots:size() - 1 do
            local slot = slots:get(j)
            if slot:containsItem(made) then
                slot:removeItem(made)
                slot:offerItem(hot, true)
                break
            end
        end
    end
    return true
end
