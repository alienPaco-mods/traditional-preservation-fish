-- Traditional Preservation (Fish): keeps the weather totals, and shows what is in each tub and frame.
-- SpriteOverlayConfig can't show a tub waiting to start or one sprite per fish, so this reads
-- each station and layers sprites itself.
if isClient() then return end

TraditionalPreservationFishWorld = TraditionalPreservationFishWorld or {}

local FACE_COUNT = 2
local TICKS_PER_REFRESH = 30
local MAP_PRIORITY = 5

-- Keep in step with the tile numbers in tools/build_tileset.py.
local TUB_SPRITE, TUB_FILLED_SPRITE, TUB_WEIGHTED_SPRITE = 0, 2, 4
local FRAME_SPRITE = 6
local STAGE_FRESH = 0

local tracked = {}
local ticksSinceRefresh = 0

local function getItems(resources, group, io)
    return resources:getResourcesFromGroup(group, ArrayList.new(), io, ResourceType.Item)
end

-- How many fish, how many stacks, and each stack's style.
local function countItems(resources, group, io)
    local count, stacks = 0, 0
    local seen, styles = {}, {}
    local items = getItems(resources, group, io)
    for i = 0, items:size() - 1 do
        local stored = items:get(i):getStoredItems()
        count = count + stored:size()
        for j = 0, stored:size() - 1 do
            local stackId = tostring(stored:get(j):getModData().stackId)
            if not seen[stackId] then
                seen[stackId] = true
                stacks = stacks + 1
                table.insert(styles, TraditionalPreservationFish.fishStyle(stored:get(j)))
            end
        end
    end
    return count, stacks, styles
end

-- One sprite per stack. Driest first: finished stacks, then running ones by progress, then the
-- stack waiting to start. Each style has its own run of stages.
function TraditionalPreservationFishWorld.fishStates(waitingStyle, batches, finishedStyles)
    local stages = TraditionalPreservationFish.DRYING_STAGES
    local states = {}
    for _, style in ipairs(finishedStyles) do table.insert(states, style * stages + stages - 1) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        table.insert(states, batch.style * stages + TraditionalPreservationFish.dryingStage(batch.progress))
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
        table.insert(batches, { progress = logic:getProgress(craftData), style = craftData:getModData().style or TraditionalPreservationFish.STYLE_SALT })
    end
    return batches
end

local function showSprites(station, entry, signature, sprites)
    if signature == entry.signature then return end
    entry.signature = signature

    station:clearAttachedAnimSprite()
    for _, index in ipairs(sprites) do
        station:addAttachedAnimSpriteByName(TraditionalPreservationFish.spriteName(index))
    end
end

local function refreshTub(tub, entry, faceIndex, waiting, _, batches, finishedStyles)
    local sprite = TraditionalPreservationFishWorld.tubSprite(waiting, batches, #finishedStyles)
    showSprites(tub, entry, tostring(sprite), sprite and { sprite + faceIndex } or {})
end

-- Keep in step with fish_index in tools/build_tileset.py.
local function refreshFrame(frame, entry, faceIndex, _, waitingStyle, batches, finishedStyles)
    local states = TraditionalPreservationFishWorld.fishStates(waitingStyle, batches, finishedStyles)
    local sprites = {}
    for slot, state in ipairs(states) do
        table.insert(sprites, entry.hanger.fishSprite + (state * entry.hanger.stacks + slot - 1) * FACE_COUNT + faceIndex)
    end
    showSprites(frame, entry, table.concat(states, ","), sprites)
end

function TraditionalPreservationFishWorld.refresh(station)
    local entry = tracked[station]
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(entry.logicType)
    local sprite = station:getSprite()
    if not resources or not logic or not sprite then return end

    if not entry.uiLogic or entry.uiLogic:getCraftLogic() ~= logic then
        -- Its constructor reads the player's mod data, so it needs a real player.
        local player = getPlayer()
        if not player then return end
        entry.uiLogic = CraftLogicUILogic.new(player, station, logic)
    end

    local waiting, _, waitingStyles = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local _, finishedStacks, finishedStyles = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local batches = readBatches(logic, entry.uiLogic, not station:isOutside())
    entry.busyStacks = finishedStacks + #batches
    entry.show(station, entry, entry.faceIndex, waiting, waitingStyles[1], batches, finishedStyles)
end

-- The stacks on a station that are past its input slots: running, or finished and not yet taken.
function TraditionalPreservationFishWorld.busyStacks(station)
    local entry = tracked[station]
    return entry and entry.busyStacks or 0
end

function TraditionalPreservationFishWorld.track(station)
    if tracked[station] then return end
    local sprite = station:getSprite()
    local index = sprite and TraditionalPreservationFish.spriteIndex(sprite:getName())
    if not index then return end

    local isFrame = index >= FRAME_SPRITE
    tracked[station] = {
        hanger = TraditionalPreservationFish.hangerFor(index),
        faceIndex = index % FACE_COUNT,
        logicType = isFrame and ComponentType.DryingCraftLogic or ComponentType.CraftLogic,
        show = isFrame and refreshFrame or refreshTub,
    }
end

local function onTick()
    ticksSinceRefresh = ticksSinceRefresh + 1
    if ticksSinceRefresh < TICKS_PER_REFRESH then return end
    ticksSinceRefresh = 0

    for station in pairs(tracked) do
        if station:getSquare() and station:getObjectIndex() >= 0 then
            TraditionalPreservationFishWorld.refresh(station)
        else
            tracked[station] = nil
        end
    end
end

local function recordWeather()
    local climate = getClimateManager()
    TraditionalPreservationFish.advance(TraditionalPreservationFish.getLedger(), getGameTime():getWorldAgeHours(), {
        temperature = climate:getTemperature(),
        humidity = climate:getHumidity(),
        precipitation = climate:getPrecipitationIntensity(),
        isSnow = climate:getPrecipitationIsSnow(),
    })
end

Events.OnTick.Add(onTick)
Events.EveryTenMinutes.Add(recordWeather)

local stations = { TUB_SPRITE }
for base in pairs(TraditionalPreservationFish.HANGERS) do table.insert(stations, base) end
for _, base in ipairs(stations) do
    for faceIndex = 0, FACE_COUNT - 1 do
        MapObjects.OnLoadWithSprite(TraditionalPreservationFish.spriteName(base + faceIndex), TraditionalPreservationFishWorld.track, MAP_PRIORITY)
    end
end
