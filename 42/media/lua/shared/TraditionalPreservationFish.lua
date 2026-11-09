-- Traditional Preservation (Fish): the curing rules shared by the recipes and the world.
-- Weather is the same everywhere, so one running total in global ModData tells every frame
-- how much drying it has had, including while its chunk was unloaded.
TraditionalPreservationFish = TraditionalPreservationFish or {}
local Weather = require "TraditionalPreservationFish/Core/Weather"

TraditionalPreservationFish.MOD_DATA_KEY = "TraditionalPreservationFish"

-- Hours in the tub, and hours on the frame at a drying rate of 1. These set the recipes' times.
TraditionalPreservationFish.PRESS_HOURS = 12
TraditionalPreservationFish.DRY_HOURS = 288
TraditionalPreservationFish.COLD_DRY_HOURS = 480

-- The most weight of fish a tub takes, with room for a few bigger fish.
TraditionalPreservationFish.TUB_CAPACITY = 50
-- Fish too, so a tub can't be filled with fillets. A tub built with more slots still stops here.
TraditionalPreservationFish.TUB_MAX_ITEMS = 35
-- Each press of Craft hangs one stack, with one sprite and one timer, and every stack is limited
-- by weight alone. A full frame holds 20. MAX_STACKS must match the frame spots in
-- tools/build_tileset.py.
TraditionalPreservationFish.STACK_WEIGHT = 2.5
TraditionalPreservationFish.MAX_STACKS = 8
-- Every station that hangs fish, by its first sprite: the first hanging fish sprite, its stacks and
-- the weight of each. Must match tools/build_tileset.py.
TraditionalPreservationFish.HANGERS = {
    [6] = { fishSprite = 8, stacks = TraditionalPreservationFish.MAX_STACKS, stackWeight = TraditionalPreservationFish.STACK_WEIGHT },
    [408] = { fishSprite = 412, stacks = 4, stackWeight = 15 },
    [410] = { fishSprite = 612, stacks = 2, stackWeight = 50 },
}

-- Vanilla's rules for cutting a fish: over this weight, into two fillets of this share of its
-- weight, each with half its food.
TraditionalPreservationFish.MIN_SLICE_WEIGHT = 0.6
TraditionalPreservationFish.FILLET_WEIGHT = 0.05
-- These are already cut, so vanilla doesn't slice them.
TraditionalPreservationFish.UNSLICEABLE = { ["Base.FishFillet"] = true, ["Base.Salmon"] = true }
-- Vanilla's guts: only a fish it could cut has them, and they are this share of its weight.
TraditionalPreservationFish.GUTS_WEIGHT = 0.1
-- Gut Fish takes the head off too, as stockfish did, and a fish over HEAD_MIN_WEIGHT gives a Fish
-- Head for the pot: this share of its weight and of its food. The limit is above the guts' so small
-- fish can't be farmed for heads. Salted fish keep their heads.
TraditionalPreservationFish.HEAD_MIN_WEIGHT = 1.0
TraditionalPreservationFish.HEAD_WEIGHT = 0.1
TraditionalPreservationFish.HEAD_FOOD = 0.06
-- Butchering XP for gutting a whole fish while packing it.
TraditionalPreservationFish.PACK_GUTTING_XP = 5
-- What a frame cold dries.
TraditionalPreservationFish.COLD_FISH = { ["TraditionalPreservationFish.GuttedFish"] = true, ["TraditionalPreservationFish.FishHalf"] = true }

-- How many looks a hanging fish has, from fresh to done, and its styles. A stack picks a style at
-- random when it starts, whatever is in it, so a frame doesn't look all alike. Must match
-- tools/build_tileset.py.
TraditionalPreservationFish.DRYING_STAGES = 5
TraditionalPreservationFish.STYLE_SALT = 0
TraditionalPreservationFish.STYLE_GUTTED = 1
TraditionalPreservationFish.STYLE_HALF = 2
TraditionalPreservationFish.STYLE_SALT_GUTTED = 3
TraditionalPreservationFish.STYLE_SALT_HALF = 4
TraditionalPreservationFish.SALT_STYLES = { 0, 0, 3, 4 }
TraditionalPreservationFish.COLD_STYLES = { 1, 1, 2 }

-- Air above DRY_AIR_HUMIDITY slows drying, down to DAMP_AIR_RATE in saturated air.
TraditionalPreservationFish.DRY_AIR_HUMIDITY = 0.5
TraditionalPreservationFish.DAMP_AIR_RATE = 0.4
-- Weather can slow a frame this far and no further, so a batch takes MAX_DRY_DAYS at most, plus rain.
TraditionalPreservationFish.MAX_DRY_DAYS = 27
TraditionalPreservationFish.MIN_DRY_RATE = TraditionalPreservationFish.DRY_HOURS / (TraditionalPreservationFish.MAX_DRY_DAYS * 24)
-- Under a roof the fish stays dry and the air moves less. People dried fish indoors with the
-- windows open, so it's slower but a fair choice.
TraditionalPreservationFish.SHELTERED_RATE = 0.65

-- Cold drying runs at full rate up to COLD_BEST, slows to COLD_MIN_RATE at COLD_LIMIT and stops
-- above that. Deep frost also gives COLD_MIN_RATE.
TraditionalPreservationFish.COLD_BEST = 5
TraditionalPreservationFish.COLD_LIMIT = 10
TraditionalPreservationFish.DEEP_FROST = -10
TraditionalPreservationFish.COLD_MIN_RATE = 0.67

-- Spoilage follows the season, not the day: it reads a running average of the weather over the
-- core's Weather.SEASON_HOURS, so a warm afternoon in January does nothing.
-- Unsalted fish spoils once the season is above RAW_SPOIL_ABOVE, and rots on the frame after
-- RAW_SPOIL_HOURS of that. Each 10 degrees more counts double.
TraditionalPreservationFish.RAW_SPOIL_ABOVE = 10
TraditionalPreservationFish.RAW_SPOIL_HOURS = 48
-- Salt fish only suffers in a hot, muggy season. SALT_SPOIL_HOURS of that is a rotten stack, and
-- less takes the same share off how long it keeps.
TraditionalPreservationFish.SALT_SPOIL_ABOVE = 22
TraditionalPreservationFish.SALT_SPOIL_HUMIDITY = 0.4
TraditionalPreservationFish.SALT_SPOIL_HOURS = 480

-- From DryingCraftLogic, so the frame's wetness readout tells the truth.
local RAIN_WETTING = 0.001  -- per game second, at full intensity
local SNOW_WETTING = 0.5
local WET_DRYING_OFF = 0.0002  -- per game second, at a temperature rate of 1
local SECONDS_PER_HOUR = 3600

-- The fish each IconsForTexture entry in the item scripts belongs to, in the same order.
TraditionalPreservationFish.FISH_ICONS = {
    "Base.FishFillet", "Base.Salmon", "Base.LargemouthBass", "Base.SmallmouthBass", "Base.SpottedBass",
    "Base.StripedBass", "Base.Walleye", "Base.Sauger", "Base.BlackCrappie", "Base.WhiteCrappie",
    "Base.Bluegill", "Base.RedearSunfish", "Base.GreenSunfish", "Base.BlueCatfish", "Base.ChannelCatfish",
    "Base.FlatheadCatfish", "Base.Muskellunge", "Base.WhiteBass", "Base.YellowPerch", "Base.FreshwaterDrum",
    "Base.AligatorGar", "Base.Paddlefish",
}

-- What each stage keeps of the item it was made from. With a maxWeight, each fish keeps a
-- random share between weight and maxWeight.
TraditionalPreservationFish.STAGES = {
    ["TraditionalPreservationFish.SaltPackedFish"] = { name = "IGUI_TraditionalPreservationFish_Packed", weight = 1, nutrition = 1, hunger = 1, gutted = true },
    ["TraditionalPreservationFish.SaltPressedFish"] = { name = "IGUI_TraditionalPreservationFish_Pressed", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFish.SaltDriedFish"] = { name = "IGUI_TraditionalPreservationFish_Dried", weight = 0.45, nutrition = 0.9, hunger = 0.7 },
    ["TraditionalPreservationFish.SoakedSaltFish"] = { name = "IGUI_TraditionalPreservationFish_SoakedSalt", weight = 1.8, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFish.GuttedFish"] = { name = "IGUI_TraditionalPreservationFish_Gutted", weight = 1, nutrition = 1, hunger = 1, gutted = true, headless = true },
    ["TraditionalPreservationFish.FishHalf"] = { name = "IGUI_TraditionalPreservationFish_Half", weight = 1, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFish.ColdDriedFish"] = { name = "IGUI_TraditionalPreservationFish_ColdDried", weight = 0.22, nutrition = 0.95, hunger = 0.7 },
    ["TraditionalPreservationFish.SoakedColdFish"] = { name = "IGUI_TraditionalPreservationFish_SoakedCold", weight = 3, nutrition = 1, hunger = 1 },
}

-- The low end of DryingCraftLogic's curve: nothing at freezing, 1 at 20 C. It stops there, so
-- heat can't finish a batch in under DRY_HOURS.
function TraditionalPreservationFish.temperatureRate(celsius)
    local rate = math.max(0, math.min(celsius, 20)) / 20
    return rate * rate
end

function TraditionalPreservationFish.coldRate(celsius)
    if celsius > TraditionalPreservationFish.COLD_LIMIT then return 0 end
    if celsius < TraditionalPreservationFish.DEEP_FROST then return TraditionalPreservationFish.COLD_MIN_RATE end
    if celsius <= TraditionalPreservationFish.COLD_BEST then return 1 end
    local warmth = (celsius - TraditionalPreservationFish.COLD_BEST) / (TraditionalPreservationFish.COLD_LIMIT - TraditionalPreservationFish.COLD_BEST)
    return 1 - warmth * (1 - TraditionalPreservationFish.COLD_MIN_RATE)
end

function TraditionalPreservationFish.airRate(humidity)
    local dryAir = TraditionalPreservationFish.DRY_AIR_HUMIDITY
    if humidity <= dryAir then return 1 end
    local dampness = math.min((humidity - dryAir) / (1 - dryAir), 1)
    return 1 - dampness * (1 - TraditionalPreservationFish.DAMP_AIR_RATE)
end

function TraditionalPreservationFish.newLedger(now)
    return { lastHour = now, wetness = 0, open = 0, sheltered = 0, cold = 0, rawSpoil = 0, saltSpoil = 0 }
end

-- Adds one stretch of weather to the totals. Open frames dry nothing until the rain has gone
-- and the wetness it left has dried off. Cold drying only minds rain, as snow doesn't wet frozen fish.
function TraditionalPreservationFish.advance(ledger, now, weather)
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now

    local minRate = TraditionalPreservationFish.MIN_DRY_RATE
    local temperatureRate = TraditionalPreservationFish.temperatureRate(weather.temperature)
    local seconds = hours * SECONDS_PER_HOUR
    if weather.precipitation > 0 then
        local wetting = RAIN_WETTING * weather.precipitation * (weather.isSnow and SNOW_WETTING or 1)
        ledger.wetness = math.min(ledger.wetness + wetting * seconds, 1)
    else
        ledger.wetness = math.max(ledger.wetness - WET_DRYING_OFF * math.max(temperatureRate, minRate) * seconds, 0)
    end

    local rate = temperatureRate * TraditionalPreservationFish.airRate(weather.humidity)
    ledger.openRate = ledger.wetness <= 0 and math.max(rate, minRate) or 0
    ledger.shelteredRate = math.max(rate * TraditionalPreservationFish.SHELTERED_RATE, minRate)
    ledger.coldRate = (weather.isSnow or weather.precipitation <= 0) and TraditionalPreservationFish.coldRate(weather.temperature) or 0
    ledger.temperature = weather.temperature
    ledger.open = ledger.open + ledger.openRate * hours
    ledger.sheltered = ledger.sheltered + ledger.shelteredRate * hours
    ledger.cold = ledger.cold + ledger.coldRate * hours

    Weather.seasonMean(ledger, "seasonTemperature", weather.temperature, hours)
    Weather.seasonMean(ledger, "seasonHumidity", weather.humidity, hours)
    local warmth = ledger.seasonTemperature - TraditionalPreservationFish.RAW_SPOIL_ABOVE
    ledger.rawSpoiling = warmth > 0
    if ledger.rawSpoiling then
        ledger.rawSpoil = ledger.rawSpoil + (1 + warmth / 10) * hours
    end
    ledger.saltSpoiling = ledger.seasonTemperature > TraditionalPreservationFish.SALT_SPOIL_ABOVE and ledger.seasonHumidity > TraditionalPreservationFish.SALT_SPOIL_HUMIDITY
    if ledger.saltSpoiling then
        ledger.saltSpoil = ledger.saltSpoil + hours
    end
end

-- How a hanging stack is doing right now, for its popup. reason says why it isn't drying, and
-- hoursLeft assumes the weather stays as it is.
function TraditionalPreservationFish.stackStatus(isCold, modData, ledger)
    local hours = isCold and TraditionalPreservationFish.COLD_DRY_HOURS or TraditionalPreservationFish.DRY_HOURS
    local temperature = ledger.temperature or 0
    local rate, reason
    if isCold and modData.sheltered then
        rate, reason = 0, "Roof"
    elseif isCold and temperature > TraditionalPreservationFish.COLD_LIMIT then
        rate, reason = 0, "TooWarm"
    elseif isCold then
        rate = ledger.coldRate or 0
        if rate <= 0 then reason = "Rain" end
    elseif modData.sheltered then
        rate = ledger.shelteredRate or 0
    else
        rate = ledger.openRate or 0
        if rate <= 0 then reason = "Rain" end
    end
    local dried = modData.dried or 0
    return {
        progress = math.min(dried / hours, 1),
        rate = rate,
        reason = reason,
        hoursLeft = rate > 0 and math.max(hours - dried, 0) / rate or nil,
        spoiled = math.min(modData.spoiled or 0, 1),
        spoiling = (isCold and ledger.rawSpoiling or not isCold and ledger.saltSpoiling) == true,
    }
end

function TraditionalPreservationFish.temperatureWord(isCold, celsius)
    if isCold then
        if celsius > TraditionalPreservationFish.COLD_LIMIT then return "IGUI_TraditionalPreservationFish_TempTooWarm" end
        if celsius > TraditionalPreservationFish.COLD_BEST then return "IGUI_TraditionalPreservationFish_TempMild" end
        return "IGUI_TraditionalPreservationFish_TempGoodCold"
    end
    if celsius >= 20 then return "IGUI_TraditionalPreservationFish_TempGoodWarm" end
    if celsius > 0 then return "IGUI_TraditionalPreservationFish_TempCool" end
    return "IGUI_TraditionalPreservationFish_TempFrost"
end

function TraditionalPreservationFish.getLedger()
    local data = ModData.getOrCreate(TraditionalPreservationFish.MOD_DATA_KEY)
    -- cold came after the first release, so a save can have the rest without it.
    if not data.cold then
        local ledger = TraditionalPreservationFish.newLedger(getGameTime():getWorldAgeHours())
        for key, value in pairs(ledger) do
            if data[key] == nil then data[key] = value end
        end
    end
    return data
end

-- The engine pools recipe data without clearing its ModData, so every run must set this.
function TraditionalPreservationFish.onPressStart(craftRecipeData)
    craftRecipeData:getModData().pressStartHour = getGameTime():getWorldAgeHours()
end

-- Craft timers tick at a fixed speed whatever Day Length says and stop when the area unloads,
-- so this replaces their count with the game clock.
function TraditionalPreservationFish.onPressUpdate(craftRecipeData)
    local startHour = craftRecipeData:getModData().pressStartHour
    if not startHour then return end

    local elapsed = (getGameTime():getWorldAgeHours() - startHour) * SECONDS_PER_HOUR
    craftRecipeData:setElapsedTime(math.min(elapsed, craftRecipeData:getRecipe():getTime()))
end

function TraditionalPreservationFish.hasRoom(capacity, storedWeight, weight)
    return storedWeight + weight <= capacity
end

-- Vanilla slots take any item and leave Craft greyed out, so each station names its fish.
function TraditionalPreservationFish.fishRefusal(isTub, fullType)
    if isTub and fullType ~= "TraditionalPreservationFish.SaltPackedFish" then return "IGUI_TraditionalPreservationFish_NeedsPacked" end
    if not isTub and fullType ~= "TraditionalPreservationFish.SaltPressedFish" and not TraditionalPreservationFish.COLD_FISH[fullType] then
        return "IGUI_TraditionalPreservationFish_NeedsPressed"
    end
    return nil
end

-- A tileset can't hold more than 512 tiles, so everything from FIRST_SHEET_SIZE on is in a second
-- one. Sprites are numbered straight through both. Must match tools/build_tileset.py.
TraditionalPreservationFish.FIRST_SHEET_SIZE = 408

function TraditionalPreservationFish.spriteName(index)
    if index < TraditionalPreservationFish.FIRST_SHEET_SIZE then return "traditionalpreservationfish_01_" .. index end
    return "traditionalpreservationfish_02_" .. (index - TraditionalPreservationFish.FIRST_SHEET_SIZE)
end

-- The number of one of this mod's sprites, or nil for any other.
function TraditionalPreservationFish.spriteIndex(name)
    local sheet, index = string.match(name or "", "^traditionalpreservationfish_0([12])_(%d+)$")
    if not sheet then return nil end
    return tonumber(index) + (sheet == "2" and TraditionalPreservationFish.FIRST_SHEET_SIZE or 0)
end

-- The big beams stand in the open, unlike the frame.
function TraditionalPreservationFish.isOutdoors(params)
    return params.square:isOutside()
end

-- The hanger a station's sprite belongs to, whichever way it faces, or nil for a tub.
function TraditionalPreservationFish.hangerFor(spriteIndex)
    return TraditionalPreservationFish.HANGERS[spriteIndex - spriteIndex % 2]
end

-- Why a fish can't join the stack waiting on a frame, as a translation key, or nil if it can.
-- busyStacks is what is already hanging: running stacks and finished ones not yet taken.
function TraditionalPreservationFish.frameRefusal(hanger, busyStacks, waitingWeight, weight)
    if busyStacks >= hanger.stacks then return "IGUI_TraditionalPreservationFish_FrameFull" end
    if weight > hanger.stackWeight then return "IGUI_TraditionalPreservationFish_TooHeavy" end
    if not TraditionalPreservationFish.hasRoom(hanger.stackWeight, waitingWeight, weight) then
        return "IGUI_TraditionalPreservationFish_StackFull"
    end
    return nil
end

function TraditionalPreservationFish.pickStyle(styles)
    return styles[ZombRand(#styles) + 1]
end

-- The style to show for an item: its stack's, or for fish still waiting, what it is.
function TraditionalPreservationFish.fishStyle(item)
    local style = item:getModData().style
    if style then return style end
    local fullType = item:getFullType()
    if fullType == "TraditionalPreservationFish.FishHalf" then return TraditionalPreservationFish.STYLE_HALF end
    if fullType == "TraditionalPreservationFish.GuttedFish" or fullType == "TraditionalPreservationFish.ColdDriedFish" then return TraditionalPreservationFish.STYLE_GUTTED end
    return TraditionalPreservationFish.STYLE_SALT
end

-- The look for a fish still drying. The last stage is kept for fish that have finished.
function TraditionalPreservationFish.dryingStage(progress)
    local running = TraditionalPreservationFish.DRYING_STAGES - 1
    return math.min(math.floor(progress * running), running - 1)
end

local function startStack(craftRecipeData)
    local ledger = TraditionalPreservationFish.getLedger()
    local modData = craftRecipeData:getModData()
    modData.dried = 0
    modData.spoiled = 0
    modData.stackId = getGameTime():getWorldAgeHours()
    modData.lastOpen = ledger.open
    modData.lastSheltered = ledger.sheltered
    modData.lastCold = ledger.cold
    modData.lastRawSpoil = ledger.rawSpoil
    modData.lastSaltSpoil = ledger.saltSpoil
    modData.sheltered = nil
end

-- Shows a stack's progress, and ends it early if it has rotted.
local function showProgress(craftRecipeData, modData, hours)
    local time = craftRecipeData:getRecipe():getTime()
    local progress = modData.spoiled >= 1 and 1 or math.min(modData.dried / hours, 1)
    craftRecipeData:setElapsedTime(progress * time)
end

function TraditionalPreservationFish.onDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = TraditionalPreservationFish.pickStyle(TraditionalPreservationFish.SALT_STYLES)
end

-- Adds what the weather has given since the last update. It goes by the frame's shelter now,
-- so a roof built over a running frame counts from then on.
function TraditionalPreservationFish.onDryUpdate(craftRecipeData)
    local ledger = TraditionalPreservationFish.getLedger()
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end

    if modData.sheltered then
        modData.dried = modData.dried + ledger.sheltered - modData.lastSheltered
    else
        modData.dried = modData.dried + ledger.open - modData.lastOpen
    end
    -- A stack from before spoilage has no starting point, so it counts from now.
    modData.spoiled = (modData.spoiled or 0) + (ledger.saltSpoil - (modData.lastSaltSpoil or ledger.saltSpoil)) / TraditionalPreservationFish.SALT_SPOIL_HOURS
    modData.lastOpen = ledger.open
    modData.lastSheltered = ledger.sheltered
    modData.lastSaltSpoil = ledger.saltSpoil
    showProgress(craftRecipeData, modData, TraditionalPreservationFish.DRY_HOURS)
end

function TraditionalPreservationFish.onColdDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = TraditionalPreservationFish.pickStyle(TraditionalPreservationFish.COLD_STYLES)
end

-- A roof keeps the wind off, so unsalted fish under one doesn't dry. It can still spoil.
function TraditionalPreservationFish.onColdDryUpdate(craftRecipeData)
    local ledger = TraditionalPreservationFish.getLedger()
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end

    if not modData.sheltered then
        modData.dried = modData.dried + ledger.cold - modData.lastCold
    end
    modData.spoiled = modData.spoiled + (ledger.rawSpoil - modData.lastRawSpoil) / TraditionalPreservationFish.RAW_SPOIL_HOURS
    modData.lastCold = ledger.cold
    modData.lastRawSpoil = ledger.rawSpoil
    showProgress(craftRecipeData, modData, TraditionalPreservationFish.COLD_DRY_HOURS)
end

-- A fish from another mod isn't in the list, and keeps the stage's own icon.
function TraditionalPreservationFish.iconIndex(source)
    local fullType = source:getFullType()
    -- Stages after these list their icons three times over: whole, gutted, then half.
    if fullType == "TraditionalPreservationFish.GuttedFish" then return source:getModelIndex() + #TraditionalPreservationFish.FISH_ICONS end
    if fullType == "TraditionalPreservationFish.FishHalf" then return source:getModelIndex() + #TraditionalPreservationFish.FISH_ICONS * 2 end
    if source:getModelIndex() >= 0 then return source:getModelIndex() end
    for index, fishType in ipairs(TraditionalPreservationFish.FISH_ICONS) do
        if fishType == fullType then return index - 1 end
    end
    return -1
end

-- Whether vanilla could cut this fish, which is what gives guts.
function TraditionalPreservationFish.hasGuts(fish)
    return fish:hasTag(ItemTag.UNCUT_FISH) and not TraditionalPreservationFish.UNSLICEABLE[fish:getFullType()]
        and fish:getActualWeight() > TraditionalPreservationFish.MIN_SLICE_WEIGHT
end

-- Whether gutting this fish gives a Fish Head.
function TraditionalPreservationFish.hasHead(fish)
    return TraditionalPreservationFish.hasGuts(fish) and fish:getActualWeight() > TraditionalPreservationFish.HEAD_MIN_WEIGHT
end

function TraditionalPreservationFish.carry(source, target)
    local stage = TraditionalPreservationFish.STAGES[target:getFullType()]
    local headless = stage.headless and TraditionalPreservationFish.hasHead(source)
    -- The head takes its share of the food with it.
    local kept = headless and 1 - TraditionalPreservationFish.HEAD_FOOD or 1
    target:setCalories(source:getCalories() * stage.nutrition * kept)
    target:setProteins(source:getProteins() * stage.nutrition * kept)
    target:setLipids(source:getLipids() * stage.nutrition * kept)
    target:setCarbohydrates(source:getCarbohydrates() * stage.nutrition * kept)
    -- Eating lowers HungChange and leaves BaseHunger, so a part-eaten fish stays part-eaten.
    target:setBaseHunger(source:getBaseHunger() * stage.hunger * kept)
    target:setHungChange(source:getHungChange() * stage.hunger * kept)
    local keptWeight = stage.maxWeight and ZombRandFloat(stage.weight, stage.maxWeight) or stage.weight
    local cut = 0
    if stage.gutted and TraditionalPreservationFish.hasGuts(source) then cut = TraditionalPreservationFish.GUTS_WEIGHT end
    if headless then cut = cut + TraditionalPreservationFish.HEAD_WEIGHT end
    keptWeight = keptWeight * (1 - cut)
    target:setActualWeight(source:getActualWeight() * keptWeight)
    target:setCustomWeight(true)

    -- The display name has the fish's size, as in Small Black Crappie, and a trailing space from vanilla.
    -- A stage item that never had a species (one spawned in) keeps its plain name, so a Salt Dried
    -- Fish doesn't become a Rehydrated Salt Dried Salt Dried Fish.
    local sourceData, targetData = source:getModData(), target:getModData()
    local fishName = sourceData.fishName
    if not fishName and not TraditionalPreservationFish.STAGES[source:getFullType()] then
        fishName = string.gsub(source:getDisplayName(), "%s+$", "")
    end
    if fishName then
        targetData.fishName = fishName
        target:setName(getText(stage.name, fishName))
        target:setCustomName(true)
    end

    if sourceData.fishName then
        targetData.sliceable = sourceData.sliceable
    else
        targetData.sliceable = not TraditionalPreservationFish.UNSLICEABLE[source:getFullType()] and source:getActualWeight() > TraditionalPreservationFish.MIN_SLICE_WEIGHT
    end

    target:setModelIndex(TraditionalPreservationFish.iconIndex(source))
end

-- InheritFood would copy the first fish onto all of them, and a batch can mix sizes, so each
-- fish hands its own values to one output.
function TraditionalPreservationFish.onCreateCured(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        TraditionalPreservationFish.carry(fish:get(i), created:get(i))
    end
end

-- A part cut from a fish, scaled to it as vanilla's guts are.
local function cutFrom(fish, fullType, weightShare, foodShare)
    local part = instanceItem(fullType)
    part:setActualWeight(fish:getActualWeight() * weightShare)
    part:setWeight(part:getActualWeight())
    part:setCustomWeight(true)
    part:setBaseHunger(fish:getBaseHunger() * foodShare)
    part:setHungChange(fish:getHungChange() * foodShare)
    return part
end

-- The head keeps the fish's name and age.
function TraditionalPreservationFish.fishHead(fish)
    local share = TraditionalPreservationFish.HEAD_FOOD
    local head = cutFrom(fish, "TraditionalPreservationFish.FishHead", TraditionalPreservationFish.HEAD_WEIGHT, share)
    head:setCalories(fish:getCalories() * share)
    head:setProteins(fish:getProteins() * share)
    head:setLipids(fish:getLipids() * share)
    head:setCarbohydrates(fish:getCarbohydrates() * share)
    head:setAge(fish:getAge())
    local fishName = fish:getModData().fishName or string.gsub(fish:getDisplayName(), "%s+$", "")
    head:setName(getText("IGUI_TraditionalPreservationFish_Head", fishName))
    head:setCustomName(true)
    return head
end

-- The stock carries the head's food on top of its own broth, and lists the head among its
-- ingredients, as a vanilla stew lists what went in.
function TraditionalPreservationFish.onCreateHeadStock(craftRecipeData)
    local head
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    for i = 0, inputs:size() - 1 do
        if inputs:get(i):getFullType() == "TraditionalPreservationFish.FishHead" then head = inputs:get(i) end
    end
    local stock = craftRecipeData:getAllCreatedItems():get(0)
    if not head or not stock then return end
    stock:setCalories(head:getCalories())
    stock:setProteins(head:getProteins())
    stock:setLipids(head:getLipids())
    stock:setCarbohydrates(head:getCarbohydrates())
    stock:setBaseHunger(stock:getBaseHunger() + head:getBaseHunger())
    stock:setHungChange(stock:getHungChange() + head:getHungChange())
    stock:addExtraItem(head:getFullType())
end

-- For recipes that clean a fish. A recipe can't leave an output out, so the guts and head go
-- straight in the inventory.
function TraditionalPreservationFish.onCreateGutted(craftRecipeData, character)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local stage = TraditionalPreservationFish.STAGES[craftRecipeData:getAllCreatedItems():get(0):getFullType()]
    TraditionalPreservationFish.onCreateCured(craftRecipeData)
    if not TraditionalPreservationFish.hasGuts(fish) then return end

    local share = TraditionalPreservationFish.GUTS_WEIGHT
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    inventory:AddItem(cutFrom(fish, "Base.FishGuts", share, share))
    if stage.headless and TraditionalPreservationFish.hasHead(fish) then
        inventory:AddItem(TraditionalPreservationFish.fishHead(fish))
    end
end

-- Packing a whole fish guts it, but a fillet only takes the salt. One recipe packs both, so its
-- xpAward can't tell them apart.
function TraditionalPreservationFish.onCreatePacked(craftRecipeData, character)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local gutting = TraditionalPreservationFish.hasGuts(fish)
    TraditionalPreservationFish.onCreateGutted(craftRecipeData, character)
    if gutting then addXp(character or craftRecipeData:getCharacter(), Perks.Butchering, TraditionalPreservationFish.PACK_GUTTING_XP) end
end

-- OnTest sees every input, so the knife passes here too.
function TraditionalPreservationFish.canSplit(item, character)
    if item:getFullType() ~= "TraditionalPreservationFish.GuttedFish" then return true end
    return item:getActualWeight() > TraditionalPreservationFish.STACK_WEIGHT
end

-- Each half keeps half the weight, not a fillet's share, so halves can't stack deep on a frame.
function TraditionalPreservationFish.onCreateSplit(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local halfName = getText("IGUI_TraditionalPreservationFish_Half", fish:getModData().fishName)
    for i = 0, created:size() - 1 do
        local half = created:get(i)
        half:setCalories(fish:getCalories() / 2)
        half:setProteins(fish:getProteins() / 2)
        half:setLipids(fish:getLipids() / 2)
        half:setCarbohydrates(fish:getCarbohydrates() / 2)
        half:setBaseHunger(fish:getBaseHunger() / 2)
        half:setHungChange(fish:getHungChange() / 2)
        half:setActualWeight(fish:getActualWeight() / 2)
        half:setCustomWeight(true)

        local modData = half:getModData()
        modData.fishName = halfName
        modData.sliceable = false
        half:setName(halfName)
        half:setCustomName(true)
        half:setModelIndex(fish:getModelIndex())
    end
end

-- OnTest sees every input, so the knife passes here too.
function TraditionalPreservationFish.canSlice(item, character)
    if not TraditionalPreservationFish.STAGES[item:getFullType()] then return true end
    return item:getModData().sliceable == true
end

-- Slicing keeps the stage, so a Salt Packed fish gives Salt Packed fillets.
function TraditionalPreservationFish.onCreateSliced(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local filletName = getItemNameFromFullType("Base.FishFillet")
    for i = 0, created:size() - 1 do
        local fillet = created:get(i)
        local stage = TraditionalPreservationFish.STAGES[fillet:getFullType()]
        fillet:setCalories(fish:getCalories() / 2)
        fillet:setProteins(fish:getProteins() / 2)
        fillet:setLipids(fish:getLipids() / 2)
        fillet:setCarbohydrates(fish:getCarbohydrates() / 2)
        fillet:setBaseHunger(fish:getBaseHunger() / 2)
        fillet:setHungChange(fish:getHungChange() / 2)
        fillet:setActualWeight(fish:getActualWeight() * TraditionalPreservationFish.FILLET_WEIGHT)
        fillet:setCustomWeight(true)

        local modData = fillet:getModData()
        modData.fishName = filletName
        modData.sliceable = false
        fillet:setName(getText(stage.name, filletName))
        fillet:setCustomName(true)
        fillet:setModelIndex(0)
    end
end

-- Marks the fish of a stack, so a frame can tell its finished stacks apart, and ages it by what
-- the season took out of it.
function TraditionalPreservationFish.onCreateDried(craftRecipeData)
    TraditionalPreservationFish.onCreateCured(craftRecipeData)
    local modData = craftRecipeData:getModData()
    local spoiled = modData.spoiled or 0
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local fish = created:get(i)
        fish:getModData().stackId = modData.stackId
        fish:getModData().style = modData.style
        fish:setAge(spoiled >= 1 and fish:getOffAgeMax() or fish:getOffAge() * spoiled)
    end
end

-- What the sandbox's spoilage setting does to the limits: off, forgiving, normal and harsh.
local SPOILAGE_SCALES = { math.huge, 2, 1, 0.5 }
local RAW_SPOIL_HOURS, SALT_SPOIL_HOURS = TraditionalPreservationFish.RAW_SPOIL_HOURS, TraditionalPreservationFish.SALT_SPOIL_HOURS
local BASE_DRY_HOURS, BASE_COLD_DRY_HOURS = TraditionalPreservationFish.DRY_HOURS, TraditionalPreservationFish.COLD_DRY_HOURS

function TraditionalPreservationFish.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFish
    if not options then return end
    if options.DryDays then
        TraditionalPreservationFish.DRY_HOURS = options.DryDays * 24
        TraditionalPreservationFish.COLD_DRY_HOURS = BASE_COLD_DRY_HOURS * TraditionalPreservationFish.DRY_HOURS / BASE_DRY_HOURS
    end
    if options.MaxDryDays then TraditionalPreservationFish.MAX_DRY_DAYS = math.max(options.MaxDryDays, TraditionalPreservationFish.DRY_HOURS / 24) end
    TraditionalPreservationFish.MIN_DRY_RATE = TraditionalPreservationFish.DRY_HOURS / (TraditionalPreservationFish.MAX_DRY_DAYS * 24)
    local scale = SPOILAGE_SCALES[options.Spoilage or 3]
    TraditionalPreservationFish.RAW_SPOIL_HOURS = RAW_SPOIL_HOURS * scale
    TraditionalPreservationFish.SALT_SPOIL_HOURS = SALT_SPOIL_HOURS * scale
end

local function applyRecipeTime(name, hours)
    local recipe = ScriptManager.instance:getCraftRecipe(name)
    if not recipe then
        print("[TraditionalPreservationFish] Could not find " .. name)
        return
    end
    local seconds = math.floor(hours * SECONDS_PER_HOUR)
    recipe:Load(name, "{ time = " .. tostring(seconds) .. ", }")
end

function TraditionalPreservationFish.applyRecipeTimes()
    TraditionalPreservationFish.applySandbox()
    applyRecipeTime("TraditionalPreservationFish.PressSaltedFish", TraditionalPreservationFish.PRESS_HOURS)
    applyRecipeTime("TraditionalPreservationFish.HangFishToDry", TraditionalPreservationFish.DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFish.HangFishToColdDry", TraditionalPreservationFish.COLD_DRY_HOURS)
end

Events.OnInitGlobalModData.Add(TraditionalPreservationFish.applyRecipeTimes)
