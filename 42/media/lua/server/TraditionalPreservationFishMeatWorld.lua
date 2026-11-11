-- Traditional Preservation (Fish & Meat): keeps the weather totals, and shows what is in each tub and frame.
-- SpriteOverlayConfig can't show a tub waiting to start or one sprite per fish, so this reads
-- each station and layers sprites itself.
if isClient() then return end

TraditionalPreservationFishMeatWorld = TraditionalPreservationFishMeatWorld or {}
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local F = TraditionalPreservationFishMeat

local FACE_COUNT = Tiles.FACE_COUNT

local TUB_FILLED_SPRITE, TUB_WEIGHTED_SPRITE = Tiles.TUB_FILLED, Tiles.TUB_WEIGHTED
local FRAME_SPRITE = Tiles.FRAME
local STAGE_FRESH = 0

-- How many fish, how many stacks, and each stack's style.
local function countItems(resources, group, io)
    local count, stacks = 0, 0
    local seen, styles = {}, {}
    local items = Station.itemSlots(resources, group, io)
    for i = 0, items:size() - 1 do
        local stored = items:get(i):getStoredItems()
        count = count + stored:size()
        for j = 0, stored:size() - 1 do
            local stackId = tostring(stored:get(j):getModData().stackId)
            if not seen[stackId] then
                seen[stackId] = true
                stacks = stacks + 1
                table.insert(styles, F.fishStyle(stored:get(j)))
            end
        end
    end
    return count, stacks, styles
end

-- One sprite per stack. Driest first: finished stacks, then running ones by progress, then the
-- stack waiting to start. Each style has its own run of stages.
function TraditionalPreservationFishMeatWorld.fishStates(waitingStyle, batches, finishedStyles)
    local stages = F.DRYING_STAGES
    local states = {}
    for _, style in ipairs(finishedStyles) do table.insert(states, style * stages + stages - 1) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        table.insert(states, batch.style * stages + F.dryingStage(batch.progress))
    end

    if waitingStyle then table.insert(states, waitingStyle * stages + STAGE_FRESH) end
    return states
end

-- The board and stones stay on until the pressed fish is taken out.
function TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, finished)
    if #batches > 0 or finished > 0 then return TUB_WEIGHTED_SPRITE end
    if waiting > 0 then return TUB_FILLED_SPRITE end
    return nil
end

-- place is the station's: indoors (and inside the Smokehouse) is sheltered, a roof with no room round it covered.
local function readBatches(logic, uiLogic, place)
    local batches = {}
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        craftData:getModData().sheltered = place ~= "Open" and place ~= "Covered"
        craftData:getModData().covered = place == "Covered"
        table.insert(batches, { progress = logic:getProgress(craftData), style = craftData:getModData().style or F.STYLE_SALT })
    end
    return batches
end

local function showSprites(station, entry, signature, sprites)
    local names = {}
    for slot, index in ipairs(sprites) do names[slot] = F.spriteName(index) end
    Station.showSprites(station, entry, signature, names)
end

local function refreshTub(tub, entry, faceIndex, waiting, _, batches, finishedStyles)
    local sprite = TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, #finishedStyles)
    showSprites(tub, entry, tostring(sprite), sprite and { sprite + faceIndex } or {})
end

-- The same numbering as fish_index in tools/build_tileset.py. Meat has its own run of tiles, one per stage.
function TraditionalPreservationFishMeatWorld.hangingSprite(hanger, state, slot, faceIndex)
    local first = hanger.fishSprite
    local meatState = F.STYLE_MEAT * F.DRYING_STAGES
    if state >= meatState then first, state = hanger.meatSprite, state - meatState end
    return first + (state * hanger.stacks + slot - 1) * FACE_COUNT + faceIndex
end

local function refreshFrame(frame, entry, faceIndex, _, waitingStyle, batches, finishedStyles)
    local states = TraditionalPreservationFishMeatWorld.fishStates(waitingStyle, batches, finishedStyles)
    local sprites = {}
    for slot, state in ipairs(states) do
        table.insert(sprites, TraditionalPreservationFishMeatWorld.hangingSprite(entry.hanger, state, slot, faceIndex))
    end
    showSprites(frame, entry, table.concat(states, ","), sprites)
end

-- The Smokehouse chamber is closed: nothing hangs in sight. Each of its tiles shows only where a joined Firebox's flue
-- enters it, master or not (the other tile has no slots).
local function showEntry(station, entry)
    local sprite = F.chamberEntry(station)
    showSprites(station, entry, tostring(sprite), sprite and { sprite } or {})
end

local function refresh(station, entry)
    if entry.hanger and entry.hanger.closed then showEntry(station, entry) end
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(entry.logicType)
    local sprite = station:getSprite()
    if not resources or not logic or not sprite then return end
    local uiLogic = Station.uiLogic(station, entry, logic)
    if not uiLogic then return end

    local waiting, _, waitingStyles = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local _, finishedStacks, finishedStyles = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local batches = readBatches(logic, uiLogic, entry.place or Weather.placeOf(station, true))
    entry.busyStacks = finishedStacks + #batches
    entry.show(station, entry, entry.faceIndex, waiting, waitingStyles[1], batches, finishedStyles)
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
