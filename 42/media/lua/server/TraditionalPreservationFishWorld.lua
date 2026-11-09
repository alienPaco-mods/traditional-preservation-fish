-- Traditional Preservation (Fish): keeps the weather totals, and shows what is in each tub and frame.
-- SpriteOverlayConfig can't show a tub waiting to start or one sprite per fish, so this reads
-- each station and layers sprites itself.
if isClient() then return end

TraditionalPreservationFishWorld = TraditionalPreservationFishWorld or {}
local Station = require "TraditionalPreservationFish/Core/Station"
local Weather = require "TraditionalPreservationFish/Core/Weather"
local Tiles = require "TraditionalPreservationFish/Tiles"
local F = TraditionalPreservationFish

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
function TraditionalPreservationFishWorld.fishStates(waitingStyle, batches, finishedStyles)
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
function TraditionalPreservationFishWorld.tubSprite(waiting, batches, finished)
    if #batches > 0 or finished > 0 then return TUB_WEIGHTED_SPRITE end
    if waiting > 0 then return TUB_FILLED_SPRITE end
    return nil
end

local function readBatches(logic, uiLogic, sheltered)
    local batches = {}
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        craftData:getModData().sheltered = sheltered
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
    local sprite = TraditionalPreservationFishWorld.tubSprite(waiting, batches, #finishedStyles)
    showSprites(tub, entry, tostring(sprite), sprite and { sprite + faceIndex } or {})
end

-- The same numbering as fish_index in tools/build_tileset.py.
local function refreshFrame(frame, entry, faceIndex, _, waitingStyle, batches, finishedStyles)
    local states = TraditionalPreservationFishWorld.fishStates(waitingStyle, batches, finishedStyles)
    local sprites = {}
    for slot, state in ipairs(states) do
        table.insert(sprites, entry.hanger.fishSprite + (state * entry.hanger.stacks + slot - 1) * FACE_COUNT + faceIndex)
    end
    showSprites(frame, entry, table.concat(states, ","), sprites)
end

local function refresh(station, entry)
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(entry.logicType)
    local sprite = station:getSprite()
    if not resources or not logic or not sprite then return end
    local uiLogic = Station.uiLogic(station, entry, logic)
    if not uiLogic then return end

    local waiting, _, waitingStyles = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local _, finishedStacks, finishedStyles = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local batches = readBatches(logic, uiLogic, Weather.placeOf(station) ~= "Open")
    entry.busyStacks = finishedStacks + #batches
    entry.show(station, entry, entry.faceIndex, waiting, waitingStyles[1], batches, finishedStyles)
end

local function newEntry(station)
    local sprite = station:getSprite()
    local index = sprite and F.spriteIndex(sprite:getName())
    if not index then return nil end

    local isFrame = index >= FRAME_SPRITE
    return {
        hanger = F.hangerFor(index),
        faceIndex = index % FACE_COUNT,
        logicType = isFrame and ComponentType.DryingCraftLogic or ComponentType.CraftLogic,
        show = isFrame and refreshFrame or refreshTub,
    }
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, entry = newEntry, refresh = refresh })

TraditionalPreservationFishWorld.track = tracker.track

-- Redraws a tracked station now, without waiting for the next tick, e.g. after a player adds fish.
function TraditionalPreservationFishWorld.refresh(station)
    local entry = tracker.entry(station)
    if entry then refresh(station, entry) end
end

-- The stacks on a station that are past its input slots: running, or finished and not yet taken.
function TraditionalPreservationFishWorld.busyStacks(station)
    local entry = tracker.entry(station)
    return entry and entry.busyStacks or 0
end

Weather.record(function(now, climate)
    F.advance(F.getLedger(), now, {
        temperature = climate:getTemperature(),
        humidity = climate:getHumidity(),
        precipitation = climate:getPrecipitationIntensity(),
        isSnow = climate:getPrecipitationIsSnow(),
    })
end)

tracker.start()
