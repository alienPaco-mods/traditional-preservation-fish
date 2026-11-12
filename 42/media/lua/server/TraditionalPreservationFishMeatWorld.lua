-- Traditional Preservation (Fish & Meat): keeps the weather totals, and shows what is in each tub and frame.
-- SpriteOverlayConfig can't show a tub waiting to start or one sprite per fish, so this reads
-- each station and layers sprites itself.
if isClient() then return end

TraditionalPreservationFishMeatWorld = TraditionalPreservationFishMeatWorld or {}
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Hearth = require "TraditionalPreservationCore/Hearth"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local F = TraditionalPreservationFishMeat

local FACE_COUNT = Tiles.FACE_COUNT

local TUB_FILLED_SPRITE, TUB_WEIGHTED_SPRITE, TUB_MEAT_SPRITES = Tiles.TUB_FILLED, Tiles.TUB_WEIGHTED, Tiles.TUB_MEAT
local FRAME_SPRITE = Tiles.FRAME
local STAGE_FRESH = 0

-- How many fish, how many stacks, each stack's style, and the items in slot order (the last in last). Finished dry-cured meat still hanging (hangingSince, the
-- hour) ages faster as it is counted (F.ageHanging). rotten[n] is true when any piece of the nth stack has rotted.
local function countItems(resources, group, io, hangingSince)
    local count, stacks = 0, 0
    local seen, styles, all, rotten = {}, {}, {}, {}
    local items = Station.itemSlots(resources, group, io)
    for i = 0, items:size() - 1 do
        local stored = items:get(i):getStoredItems()
        count = count + stored:size()
        for j = 0, stored:size() - 1 do
            table.insert(all, stored:get(j))
            if hangingSince then F.ageHanging(stored:get(j), hangingSince) end
            local stackId = tostring(stored:get(j):getModData().stackId)
            if not seen[stackId] then
                stacks = stacks + 1
                seen[stackId] = stacks
                table.insert(styles, F.fishStyle(stored:get(j)))
            end
            if stored:get(j):isRotten() then rotten[seen[stackId]] = true end
        end
    end
    return count, stacks, styles, all, rotten
end

-- One sprite per stack. Driest first: finished stacks, then running ones by progress, then the
-- stack waiting to start. Each style has its own run of stages. A rotted stack shows its kind's rotten look
-- (F.ROTTEN_STATE on): a running one when it is lost as a whole, a finished one when any piece in it rotted.
function TraditionalPreservationFishMeatWorld.fishStates(waitingStyle, batches, finishedStyles, finishedRotten)
    local stages = F.DRYING_STAGES
    local states = {}
    for n, style in ipairs(finishedStyles) do
        local rotten = finishedRotten and finishedRotten[n]
        table.insert(states, rotten and F.ROTTEN_STATE + F.rottenKind(style) or style * stages + stages - 1)
    end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        table.insert(states, batch.rotten and F.ROTTEN_STATE + F.rottenKind(batch.style)
            or batch.style * stages + F.dryingStage(batch.progress))
    end

    if waitingStyle then table.insert(states, waitingStyle * stages + STAGE_FRESH) end
    return states
end

-- What shows in an uncovered tub: fish (nil), or the meat on top, the last put in (a tub holds fish or meat, and
-- cuts of any kind together). A leg always shows: it fills the tub.
function TraditionalPreservationFishMeatWorld.tubKind(items)
    local last = items[#items]
    if not last or not F.isMeatStage(last:getFullType()) then return nil end
    for _, item in ipairs(items) do
        if F.isLeg(item) then return "leg" end
    end
    return F.isPork(last) and "pork" or "meat"
end

-- The board and stones stay on until the pressed fish is taken out. Before that the top layer shows: fish or meat.
function TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, finished, kind)
    if #batches > 0 or finished > 0 then return TUB_WEIGHTED_SPRITE end
    if waiting > 0 then return kind and TUB_MEAT_SPRITES[kind] or TUB_FILLED_SPRITE end
    return nil
end

-- place is the station's: indoors (and inside the Smokehouse) is sheltered, a roof with no room round it covered.
-- In the Smokehouse each stack also counts the joined Firebox's fire (F.smokeStep); a done cook is noted for its
-- OnUpdate to finish, and every stack's shed for OnCreate's Cold Smoked swap (F.smokeStations).
local function readBatches(station, entry, logic, uiLogic, place)
    local batches = {}
    local smoking = entry.hanger and entry.hanger.closed
    local firebox = smoking and F.joinedFirebox(station)
    local fire = firebox and Hearth.stateOf(firebox:getModData())
    local ledger = smoking and F.getLedger()
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        local modData = craftData:getModData()
        modData.sheltered = place ~= "Open" and place ~= "Covered"
        modData.covered = place == "Covered"
        modData.basement = place == "Basement"
        if modData.stackId then F.stackStations[modData.stackId] = station end
        if smoking then
            F.smokeStep(modData, fire, ledger)
            modData.inShed = true
            if modData.stackId then F.smokeStations[modData.stackId] = station end
            if F.hotDone(modData) then F.hotStations[modData.stackId] = station end
        end
        table.insert(batches, { progress = logic:getProgress(craftData), style = modData.style or F.STYLE_SALT,
            rotten = F.stackRotten(modData) })
    end
    return batches
end

local function showSprites(station, entry, signature, sprites)
    local names = {}
    for slot, index in ipairs(sprites) do names[slot] = F.spriteName(index) end
    Station.showSprites(station, entry, signature, names)
end

local function refreshTub(tub, entry, faceIndex, waiting, _, batches, finishedStyles, waitingItems)
    local sprite = TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, #finishedStyles,
        TraditionalPreservationFishMeatWorld.tubKind(waitingItems))
    showSprites(tub, entry, tostring(sprite), sprite and { sprite + faceIndex } or {})
end

-- The same numbering as fish_index in tools/build_tileset.py. Meat has its own run of tiles, one per stage, and
-- rotted stacks theirs, one per kind.
function TraditionalPreservationFishMeatWorld.hangingSprite(hanger, state, slot, faceIndex)
    local first = hanger.fishSprite
    local meatState = F.STYLE_MEAT * F.DRYING_STAGES
    if state >= F.ROTTEN_STATE then
        first, state = hanger.rottenSprite, state - F.ROTTEN_STATE
    elseif state >= meatState then
        first, state = hanger.meatSprite, state - meatState
    end
    return first + (state * hanger.stacks + slot - 1) * FACE_COUNT + faceIndex
end

local function refreshFrame(frame, entry, faceIndex, _, waitingStyle, batches, finishedStyles, _, finishedRotten)
    local states = TraditionalPreservationFishMeatWorld.fishStates(waitingStyle, batches, finishedStyles, finishedRotten)
    local sprites = {}
    for slot, state in ipairs(states) do
        table.insert(sprites, TraditionalPreservationFishMeatWorld.hangingSprite(entry.hanger, state, slot, faceIndex))
    end
    showSprites(frame, entry, table.concat(states, ","), sprites)
end

-- Whether either tile of the shed holds finished stacks not yet taken out (the slots are on one of them).
local function hasFinished(station)
    for _, found in ipairs(F.chamberTiles(station)) do
        local resources = found[1]:getComponent(ComponentType.Resources)
        local logic = found[1]:getComponent(ComponentType.DryingCraftLogic)
        if resources and logic and Station.countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output) > 0 then
            return true
        end
    end
    return false
end

-- The Smokehouse chamber is closed: nothing hangs in sight. Each of its tiles shows where a joined Firebox's flue
-- enters it, master or not (the other tile has no slots), and the door's tile a ham while finished stacks wait.
local function showEntry(station, entry)
    local sprites = {}
    local face, part = F.chamberTile(F.stationIndex(station))
    local flue = F.chamberEntry(station)
    local ham = F.hamSprite(face, part, part == 1 and hasFinished(station))
    if flue then table.insert(sprites, flue) end
    if ham then table.insert(sprites, ham) end
    showSprites(station, entry, table.concat(sprites, ","), sprites)
end

local function refresh(station, entry)
    if entry.hanger and entry.hanger.closed then showEntry(station, entry) end
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(entry.logicType)
    local sprite = station:getSprite()
    if not resources or not logic or not sprite then return end
    local uiLogic = Station.uiLogic(station, entry, logic)
    if not uiLogic then return end

    local waiting, _, waitingStyles, waitingItems = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local _, finishedStacks, finishedStyles, _, finishedRotten = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output,
        entry.hanger and getGameTime():getWorldAgeHours())
    local batches = readBatches(station, entry, logic, uiLogic, entry.place or Weather.placeOf(station, true))
    entry.busyStacks = finishedStacks + #batches
    entry.show(station, entry, entry.faceIndex, waiting, waitingStyles[1], batches, finishedStyles, waitingItems, finishedRotten)
end

local function newEntry(station)
    local index = F.stationIndex(station)
    if not index then return nil end

    local isFrame = index >= FRAME_SPRITE
    local hanger = F.hangerFor(index)
    local closed = hanger and hanger.closed
    local logic = closed and station:getComponent(ComponentType.DryingCraftLogic)
    if logic and logic:getRecipeTagQuery() ~= F.SMOKEHOUSE_RECIPES then logic:setRecipeTagQuery(F.SMOKEHOUSE_RECIPES) end
    -- Inside the chamber's walls and roof it is always Sheltered, wherever the shed stands.
    return {
        hanger = hanger,
        faceIndex = index % FACE_COUNT,
        logicType = isFrame and ComponentType.DryingCraftLogic or ComponentType.CraftLogic,
        show = closed and function() end or isFrame and refreshFrame or refreshTub,
        place = closed and "Sheltered" or nil,
    }
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, entry = newEntry, refresh = refresh })

TraditionalPreservationFishMeatWorld.track = tracker.track

-- Redraws a tracked station now, without waiting for the next tick, e.g. after a player adds fish.
function TraditionalPreservationFishMeatWorld.refresh(station)
    local entry = tracker.entry(station)
    if entry then refresh(station, entry) end
end

-- The stacks on a station that are past its input slots: running, or finished and not yet taken.
function TraditionalPreservationFishMeatWorld.busyStacks(station)
    local entry = tracker.entry(station)
    return entry and entry.busyStacks or 0
end

-- What a station holds now, for its Info window: its hanger (nil for a tub) and place, the items waiting in its
-- input slots, the finished ones and their stacks, and the running batches, furthest along first, each with its
-- recipe data and progress. Either tile of a Smokehouse answers for the one with the slots. Nil for anything else,
-- or before there is a player.
function TraditionalPreservationFishMeatWorld.inspect(station)
    for _, found in ipairs(F.chamberTiles(station)) do
        if found[1]:getComponent(ComponentType.DryingCraftLogic) then station = found[1] end
    end
    local entry = tracker.track(station)
    if not entry then return nil end
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(entry.logicType)
    local uiLogic = resources and logic and Station.uiLogic(station, entry, logic)
    if not uiLogic then return nil end

    local _, _, _, waiting = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local finished, finishedStacks = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local batches = {}
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        table.insert(batches, { data = craftData, progress = logic:getProgress(craftData) })
    end
    table.sort(batches, function(a, b) return a.progress > b.progress end)
    return { station = station, hanger = entry.hanger, place = entry.place or Weather.placeOf(station, true),
        waiting = waiting, finished = finished, finishedStacks = finishedStacks, batches = batches }
end

Weather.record(function(now, climate)
    F.advance(F.getLedger(), now, {
        temperature = climate:getTemperature(),
        humidity = climate:getHumidity(),
        precipitation = climate:getPrecipitationIntensity(),
        isSnow = climate:getPrecipitationIsSnow(),
        wind = climate:getWindIntensity(),
    })
    F.recordPotted(now, climate:getTemperature())
end)

tracker.start()
