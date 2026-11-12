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

-- Cold smoke (5d; fixed hours since 6b): a stack whose cold counter reaches its smoke need comes out Cold Smoked
-- when it has dried (smoked-dried fish, balyk, suho meso: a few hours of smoke a day over the drying). The need is
-- by the heaviest piece, as the cook's: a day or two of smoke for fish, a week or two of daily fires for meat (a
-- Beef 60 hours, a Leg of Pork 120). Hours with the fire burning dry it in air warmed by the fire (F.BANKED_LIFT,
-- F.STOKED_LIFT), not at Sheltered's rate.
F.SMOKE_FISH_HOURS = { { 1.1, 24 }, { 2.2, 48 } }
F.SMOKE_MEAT_HOURS = { { 0.45, 60 }, { 2.25, 120 } }
F.COLD_FISH_OUT = "TraditionalPreservationFishMeat.ColdSmokedFish"
F.DRY_CURED = "TraditionalPreservationFishMeat.DryCuredMeat"
-- 6b: a Leg of Pork dries to a Country Ham and never takes a hot cook (a hot-smoked whole ham is a wet-cured city
-- ham, another product); the other pork cuts hot smoke to vanilla's Ham.
F.COUNTRY_HAM = "TraditionalPreservationFishMeat.CountryHam"
F.VANILLA_HAM = "Base.Ham"

-- The stoked hours a stack needs, by its heaviest piece: straight between the two points, on past them, clamped.
function F.hotHours(isMeat, heaviest)
    local points = isMeat and F.HOT_MEAT_HOURS or F.HOT_FISH_HOURS
    local low, high = points[1], points[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.max(F.HOT_MIN_HOURS, math.min(hours, F.HOT_MAX_HOURS))
end

-- Sets a new stack's counters and need from its pieces (an ArrayList of items). Meat also gets its dry-curing need
-- for the Smokehouse; a stack with a leg never hot smokes, and one with Corned meat (no long cure) is under-salted.
function F.startSmoke(modData, items, isMeat)
    local heaviest = 0
    modData.noHot, modData.underCured, modData.allUnder, modData.longStack = nil, nil, isMeat or nil, nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        heaviest = math.max(heaviest, item:getActualWeight())
        if isMeat then
            if F.isLeg(item) then modData.noHot = true end
            if item:getModData().longCure then
                modData.allUnder, modData.longStack = nil, true
            else
                modData.underCured = true
            end
        end
    end
    modData.heaviest = heaviest
    modData.cureNeed = isMeat and F.dryCureHours(heaviest) or nil
    modData.underSpoiled = 0
    modData.hotNeed = F.hotHours(isMeat, heaviest)
    modData.smokeNeed = F.smokeHours(isMeat, heaviest)
    modData.hot, modData.hotCool, modData.cold = 0, 0, 0
    modData.smokeMeat = isMeat
    modData.smokeFrom, modData.smokeSession, modData.lastStoked, modData.lastBanked = nil, nil, nil, nil
end

-- The ledger totals a stack's warmth reads: salt fish's drying Sheltered or meat's dry curing with the fire out, and
-- by a banked and by a stoked fire.
local function warmthTotals(modData, ledger)
    if modData.smokeMeat then return ledger.dryCure or 0, ledger.dryCureBanked or 0, ledger.dryCureStoked or 0 end
    return ledger.sheltered or 0, ledger.smokeBanked or 0, ledger.smokeStoked or 0
end

-- How much more under-salted meat spoiled an hour by a banked and by a stoked fire than with the fire out, since the
-- stack's last look (hours of the ledger's clock), as sinceLast's gains.
local function underGains(modData, ledger, hours)
    local base, banked, stoked = ledger.underCure or 0, ledger.underCureBanked or 0, ledger.underCureStoked or 0
    local bankedGain, stokedGain = 0, 0
    if hours > 0 then
        local plain = base - (modData.lastUnderBase or base)
        bankedGain = (banked - (modData.lastUnderBanked or banked) - plain) / hours
        stokedGain = (stoked - (modData.lastUnderStoked or stoked) - plain) / hours
    end
    modData.lastUnderBase, modData.lastUnderBanked, modData.lastUnderStoked = base, banked, stoked
    return math.max(bankedGain, 0), math.max(stokedGain, 0)
end

-- Since the stack's last look: the share of the hours that were cool enough for cold smoke, and how much more a stack
-- by a banked and by a stoked fire dried than a Sheltered one per hour, from the ledger's totals (a week away reads
-- the week's weather). With no hours between, the weather now and no gain. A stack from before the smoulder's
-- warmth starts its warm totals at this look.
local function sinceLast(modData, ledger)
    local sheltered, banked, stoked = warmthTotals(modData, ledger)
    local hours = (ledger.clock or 0) - (modData.lastClock or ledger.clock or 0)
    local coolShare, bankedGain, stokedGain = nil, 0, 0
    local underBanked, underStoked = underGains(modData, ledger, hours)
    if hours > 0 then
        coolShare = ((ledger.smokeCool or 0) - (modData.lastSmokeCool or 0)) / hours
        local base = sheltered - (modData.lastDraughtSheltered or sheltered)
        bankedGain = (banked - (modData.lastDraughtBanked or banked) - base) / hours
        stokedGain = (stoked - (modData.lastDraughtStoked or stoked) - base) / hours
    else
        coolShare = (ledger.temperature or 0) <= F.COLD_SMOKE_MAX and 1 or 0
    end
    modData.lastClock, modData.lastSmokeCool = ledger.clock or 0, ledger.smokeCool or 0
    modData.lastDraughtSheltered, modData.lastDraughtBanked, modData.lastDraughtStoked = sheltered, banked, stoked
    return math.max(0, math.min(coolShare, 1)), math.max(bankedGain, 0), math.max(stokedGain, 0), underBanked, underStoked
end

-- A stack of meat hung in a shed before 6b dried on charque's clock: it gets its dry-curing need, keeps its share
-- of progress and starts the new totals from this look.
local function toDryCure(modData, ledger)
    local need = F.dryCureHours(modData.heaviest or F.DRY_CURE_HOURS[1][1])
    modData.dried = (modData.dried or 0) / F.CHARQUE_HOURS * need
    modData.cureNeed = need
    modData.lastDryCure, modData.lastUnderCure = ledger.dryCure, ledger.underCure
    modData.lastDraughtSheltered, modData.lastDraughtBanked, modData.lastDraughtStoked = nil, nil, nil
end

-- Brings a stack's counters up to the fire's record (a Firebox's Hearth state), or none (not joined). A new or
-- rebuilt Firebox starts from what it has now; whatever hot the stack had becomes cold, as it does when the session
-- it counted in ends. Of the stoked hours since the last look, those in a session that has since begun are hot.
-- With the ledger (the World's look; tests may leave it out): fire hours count as cold only on cool days, stoked
-- or banked (user: no Cold Smoked in summer from short stoked bursts), so hot keeps its cool part (hotCool) for
-- when its session breaks off; and every hour of fire adds the warmed air's extra drying, banked or stoked.
local function hotToCold(modData)
    modData.cold = (modData.cold or 0) + (modData.hotCool or modData.hot or 0)
    modData.hot, modData.hotCool = 0, 0
end

function F.smokeStep(modData, fire, ledger)
    if not modData.hotNeed then return end
    modData.burning = fire and fire.fireMode or nil
    local coolShare, bankedGain, stokedGain, underBanked, underStoked = 1, 0, 0, 0, 0
    if ledger then
        if modData.smokeMeat and not modData.cureNeed then toDryCure(modData, ledger) end
        coolShare, bankedGain, stokedGain, underBanked, underStoked = sinceLast(modData, ledger)
    end
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
    if modData.dried then modData.dried = modData.dried + math.max(stoked, 0) * stokedGain + banked * bankedGain end
    if modData.underCured then
        modData.underSpoiled = (modData.underSpoiled or 0) + math.max(stoked, 0) * underStoked + banked * underBanked
    end
    modData.lastStoked, modData.lastBanked = fire.stokedHours or 0, fire.bankedHours or 0
    -- A stack with a leg takes no cook: its stoked hours are smoke at once.
    if modData.noHot then hotToCold(modData) end
end

-- Whether a stack's hot counter has done its cook.
function F.hotDone(modData)
    return modData.hotNeed ~= nil and not modData.noHot and (modData.hot or 0) >= modData.hotNeed
end

-- The hours of smoke a stack needs, by its heaviest piece: straight between the two points, never under the first
-- nor over the second.
function F.smokeHours(isMeat, heaviest)
    local points = isMeat and F.SMOKE_MEAT_HOURS or F.SMOKE_FISH_HOURS
    local low, high = points[1], points[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.max(low[2], math.min(hours, high[2]))
end

-- A stack's smoke need (one hung before 6b gets it from its heaviest piece), and whether it has had it.
function F.coldNeed(modData)
    return modData.smokeNeed or F.smokeHours(modData.smokeMeat == true, modData.heaviest or 0)
end

function F.coldDone(modData)
    return (modData.cold or 0) > 0 and modData.cold >= F.coldNeed(modData)
end

-- Stacks whose cook is done, by stackId, with their chamber: the World sets them, the stack's OnUpdate finishes it,
-- its OnCreate swaps the outputs in the chamber's slots. Not saved: the World's next look after a load sets it again.
F.hotStations = {}

-- Swaps a finished stack's outputs, already in the chamber's slots (the engine makes them before OnCreate), for
-- smoked ones made from its inputs: fishType for fish, meatType for meat (Hot Smoked, or Cold Smoked and Dry-Cured).
-- Of the meat, hot smoked pork is vanilla's Ham and a dried leg a Country Ham; airDried marks Dry-Cured meat that
-- had too little smoke (Bresaola, plain Country Ham). Corned pieces take the stack's under-salted spoilage.
local function smokedMeatType(input, meatType)
    if meatType == F.HOT_MEAT then return F.isPork(input) and not F.isLeg(input) and F.VANILLA_HAM or meatType end
    return F.isLeg(input) and F.COUNTRY_HAM or meatType
end

-- One smoked piece from its input, by the stack's modData. A piece that rotted on the way comes down as what was
-- hung (F.rottenStage).
function F.smokedItem(input, modData, fishType, meatType, airDried)
    local isMeat = input:getFullType() == F.CURED_MEAT
    local lost = modData.spoiled or 0
    if isMeat and not input:getModData().longCure then lost = lost + (modData.underSpoiled or 0) end
    if lost >= 1 then return F.rottenStage(input) end
    local hot = instanceItem(isMeat and smokedMeatType(input, meatType) or fishType)
    if hot:getFullType() == F.VANILLA_HAM then
        F.carryHam(input, hot)
    else
        if isMeat and airDried then hot:getModData().airDried = true end
        F.carry(input, hot)
        hot:getModData().stackId = modData.stackId
        hot:getModData().style = modData.style
    end
    hot:setAge(hot:getOffAge() * lost)
    -- Dry-cured meat ages from here (6c).
    if F.ageDays(hot) then hot:getModData().agedFrom = hot:getAge() end
    return hot
end

-- Swaps a finished stack's outputs, already in the station's slots, for make(input) of each of its inputs.
local function swapOutputs(craftRecipeData, station, make)
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    local logic = station:getComponent(ComponentType.DryingCraftLogic)
    local resources = station:getComponent(ComponentType.Resources)
    if not logic or not resources then return false end
    local slots = Station.itemSlots(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    for i = 0, math.min(inputs:size(), created:size()) - 1 do
        local made = created:get(i)
        local swapped = make(inputs:get(i))
        for j = 0, slots:size() - 1 do
            local slot = slots:get(j)
            if slot:containsItem(made) then
                slot:removeItem(made)
                slot:offerItem(swapped, true)
                break
            end
        end
    end
    return true
end

function F.smokedOutputs(craftRecipeData, station, fishType, meatType, airDried)
    local modData = craftRecipeData:getModData()
    return swapOutputs(craftRecipeData, station, function(input) return F.smokedItem(input, modData, fishType, meatType, airDried) end)
end

-- A stack that rotted on any station comes down as what was hung, rotten.
function F.rottenOutputs(craftRecipeData, station)
    return swapOutputs(craftRecipeData, station, F.rottenStage)
end
