-- Traditional Preservation (Fish): the curing rules shared by the recipes and the world.
-- Weather is the same everywhere, so one running total in global ModData tells every frame
-- how much drying it has had, including while its chunk was unloaded.
TraditionalPreservationFish = TraditionalPreservationFish or {}
local F = TraditionalPreservationFish
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFish/Tiles"

F.MOD_DATA_KEY = "TraditionalPreservationFish"

-- Hours in the tub, and hours on the frame at a drying rate of 1. These set the recipes' times.
F.PRESS_HOURS = 12
F.DRY_HOURS = 288
F.COLD_DRY_HOURS = 480

-- The most weight of fish a tub takes, with room for a few bigger fish.
F.TUB_CAPACITY = 50
-- Fish too, so a tub can't be filled with fillets. A tub built with more slots still stops here.
F.TUB_MAX_ITEMS = 35
-- Each press of Craft hangs one stack, with one sprite and one timer, and every stack is limited
-- by weight alone. A full frame holds 20. MAX_STACKS is the frame's spots, from the Tiles.lua that
-- tools/build_tileset.py writes.
F.STACK_WEIGHT = 2.5
F.MAX_STACKS = Tiles.HANGERS.frame.stacks
-- Every station that hangs fish, by its first sprite: the first hanging fish sprite and its stacks
-- (from Tiles.lua), and the weight of each stack.
local STACK_WEIGHTS = { frame = F.STACK_WEIGHT, medium = 15, large = 50 }
F.HANGERS = {}
for name, hanger in pairs(Tiles.HANGERS) do
    F.HANGERS[hanger.base] = { fishSprite = hanger.fishSprite, stacks = hanger.stacks, stackWeight = STACK_WEIGHTS[name] }
end

-- Vanilla's rules for cutting a fish: over this weight, into two fillets of this share of its
-- weight (more in spawning season, when part goes to roe), each with half its food.
F.MIN_SLICE_WEIGHT = 0.6
F.FILLET_WEIGHT = 0.05
-- These are already cut, so vanilla doesn't slice them.
F.UNSLICEABLE = { ["Base.FishFillet"] = true, ["Base.Salmon"] = true }
-- Vanilla's guts: only a fish it could cut has them, and they are this share of its weight.
F.GUTS_WEIGHT = 0.1
-- A fillet vanilla cut weighs a twentieth of its fish and holds half its food. Salted, it counts as what it
-- holds, half the gutted fish: it pays that much salt and comes out of the salt that heavy.
F.FILLET_FOOD_WEIGHT = (1 - F.GUTS_WEIGHT) * 0.5 / F.FILLET_WEIGHT
-- Packing takes SALT_PER_STEP salt for each started SALT_STEP of the packed fish's weight, and never less
-- than the SALT_MIN the recipe itself asks for.
F.SALT_STEP = 0.5
F.SALT_PER_STEP = 2
F.SALT_MIN = 2
-- A fish over this weight is too thick to salt whole, as on the Volga: gut and split it first. Halves always pack.
F.SALT_WHOLE_MAX = 4.5
-- Gut Fish takes the head off too, as stockfish did, and a fish over HEAD_MIN_WEIGHT gives a Fish
-- Head for the pot: this share of its weight and of its food. The limit is above the guts' so small
-- fish can't be farmed for heads. Salted fish keep their heads.
F.HEAD_MIN_WEIGHT = 1.0
F.HEAD_WEIGHT = 0.1
F.HEAD_FOOD = 0.06
-- Butchering XP for gutting a whole fish while packing it.
F.PACK_GUTTING_XP = 5
-- What a frame cold dries.
F.COLD_FISH = { ["TraditionalPreservationFish.GuttedFish"] = true, ["TraditionalPreservationFish.FishHalf"] = true }

-- How many looks a hanging fish has, from fresh to done, and its styles. A stack picks a style at
-- random when it starts, whatever is in it, so a frame doesn't look all alike. Both come from Tiles.lua.
F.DRYING_STAGES = Tiles.DRYING_STAGES
F.STYLE_SALT = Tiles.STYLES.SALT
F.STYLE_GUTTED = Tiles.STYLES.GUTTED
F.STYLE_HALF = Tiles.STYLES.HALF
F.STYLE_SALT_GUTTED = Tiles.STYLES.SALT_GUTTED
F.STYLE_SALT_HALF = Tiles.STYLES.SALT_HALF
F.SALT_STYLES = { 0, 0, 3, 4 }
F.COLD_STYLES = { 1, 1, 2 }

-- Air above DRY_AIR_HUMIDITY slows drying, down to DAMP_AIR_RATE in saturated air.
F.DRY_AIR_HUMIDITY = 0.5
F.DAMP_AIR_RATE = 0.4
-- Weather can slow a frame this far and no further, so a batch takes MAX_DRY_DAYS at most, plus rain.
F.MAX_DRY_DAYS = 27
F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
-- Under a roof the fish stays dry and the air moves less. People dried fish indoors with the
-- windows open, so it's slower but a fair choice.
F.SHELTERED_RATE = 0.65

-- Cold drying runs at full rate up to COLD_BEST, slows to COLD_MIN_RATE at COLD_LIMIT and stops
-- above that. Deep frost also gives COLD_MIN_RATE.
F.COLD_BEST = 5
F.COLD_LIMIT = 10
F.DEEP_FROST = -10
F.COLD_MIN_RATE = 0.67

-- Spoilage follows the season, not the day: it reads a running average of the weather over the
-- core's Weather.SEASON_HOURS, so a warm afternoon in January does nothing.
-- Unsalted fish spoils once the season is above RAW_SPOIL_ABOVE, and rots on the frame after
-- RAW_SPOIL_HOURS of that. Each 10 degrees more adds as much again
-- (twice as fast at +10, three times at +20).
F.RAW_SPOIL_ABOVE = 10
F.RAW_SPOIL_HOURS = 48
-- Salt fish only suffers in a hot, muggy season. SALT_SPOIL_HOURS of that is a rotten stack, and
-- less takes the same share off how long it keeps.
F.SALT_SPOIL_ABOVE = 22
F.SALT_SPOIL_HUMIDITY = 0.4
F.SALT_SPOIL_HOURS = 480

-- From DryingCraftLogic, so the frame's wetness readout tells the truth.
local RAIN_WETTING = 0.001  -- per game second, at full intensity
local SNOW_WETTING = 0.5
local WET_DRYING_OFF = 0.0002  -- per game second, at a temperature rate of 1
local SECONDS_PER_HOUR = 3600

-- The fish each IconsForTexture entry in the item scripts belongs to, in the same order.
F.FISH_ICONS = {
    "Base.FishFillet", "Base.Salmon", "Base.LargemouthBass", "Base.SmallmouthBass", "Base.SpottedBass",
    "Base.StripedBass", "Base.Walleye", "Base.Sauger", "Base.BlackCrappie", "Base.WhiteCrappie",
    "Base.Bluegill", "Base.RedearSunfish", "Base.GreenSunfish", "Base.BlueCatfish", "Base.ChannelCatfish",
    "Base.FlatheadCatfish", "Base.Muskellunge", "Base.WhiteBass", "Base.YellowPerch", "Base.FreshwaterDrum",
    "Base.AligatorGar", "Base.Paddlefish",
}

-- What each stage keeps of the item it was made from. With a maxWeight, each fish keeps a
-- random share between weight and maxWeight. Soaking gives back the bulk drying took (hunger 0.7).
F.STAGES = {
    ["TraditionalPreservationFish.SaltPackedFish"] = { name = "IGUI_TraditionalPreservationFish_Packed", weight = 1, nutrition = 1, hunger = 1, gutted = true },
    ["TraditionalPreservationFish.SaltPressedFish"] = { name = "IGUI_TraditionalPreservationFish_Pressed", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFish.SaltDriedFish"] = { name = "IGUI_TraditionalPreservationFish_Dried", weight = 0.45, nutrition = 0.9, hunger = 0.7 },
    ["TraditionalPreservationFish.SoakedSaltFish"] = { name = "IGUI_TraditionalPreservationFish_SoakedSalt", weight = 1.8, nutrition = 1, hunger = 1 / 0.7 },
    ["TraditionalPreservationFish.GuttedFish"] = { name = "IGUI_TraditionalPreservationFish_Gutted", weight = 1, nutrition = 1, hunger = 1, gutted = true, headless = true },
    ["TraditionalPreservationFish.FishHalf"] = { name = "IGUI_TraditionalPreservationFish_Half", weight = 1, nutrition = 1, hunger = 1 },
    ["TraditionalPreservationFish.ColdDriedFish"] = { name = "IGUI_TraditionalPreservationFish_ColdDried", weight = 0.22, nutrition = 0.95, hunger = 0.7 },
    ["TraditionalPreservationFish.SoakedColdFish"] = { name = "IGUI_TraditionalPreservationFish_SoakedCold", weight = 3, nutrition = 1, hunger = 1 / 0.7 },
}

-- The low end of DryingCraftLogic's curve: nothing at freezing, 1 at 20 C. It stops there, so
-- heat can't finish a batch in under DRY_HOURS.
function F.temperatureRate(celsius)
    local rate = math.max(0, math.min(celsius, 20)) / 20
    return rate * rate
end

-- Cold drying (unsalted fish in frost and wind): full speed up to COLD_BEST, slowing to COLD_MIN_RATE
-- at COLD_LIMIT, nothing above it. Deep frost slows it to COLD_MIN_RATE too.
function F.coldRate(celsius)
    if celsius > F.COLD_LIMIT then return 0 end
    if celsius < F.DEEP_FROST then return F.COLD_MIN_RATE end
    if celsius <= F.COLD_BEST then return 1 end
    local warmth = (celsius - F.COLD_BEST) / (F.COLD_LIMIT - F.COLD_BEST)
    return 1 - warmth * (1 - F.COLD_MIN_RATE)
end

-- Damp air slows open drying: full speed up to DRY_AIR_HUMIDITY, down to DAMP_AIR_RATE in saturated air.
function F.airRate(humidity)
    local dryAir = F.DRY_AIR_HUMIDITY
    if humidity <= dryAir then return 1 end
    local dampness = math.min((humidity - dryAir) / (1 - dryAir), 1)
    return 1 - dampness * (1 - F.DAMP_AIR_RATE)
end

-- The weather totals: hours of drying done open, sheltered and cold, hours of spoiling raw and salted,
-- and the wetness rain left on open frames.
function F.newLedger(now)
    return { lastHour = now, wetness = 0, open = 0, sheltered = 0, cold = 0, rawSpoil = 0, saltSpoil = 0 }
end

-- Adds one stretch of weather to the totals. Open frames dry nothing until the rain has gone
-- and the wetness it left has dried off. Cold drying only minds rain, as snow doesn't wet frozen fish.
function F.advance(ledger, now, weather)
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now

    local minRate = F.MIN_DRY_RATE
    local temperatureRate = F.temperatureRate(weather.temperature)
    local seconds = hours * SECONDS_PER_HOUR
    if weather.precipitation > 0 then
        local wetting = RAIN_WETTING * weather.precipitation * (weather.isSnow and SNOW_WETTING or 1)
        ledger.wetness = math.min(ledger.wetness + wetting * seconds, 1)
    else
        ledger.wetness = math.max(ledger.wetness - WET_DRYING_OFF * math.max(temperatureRate, minRate) * seconds, 0)
    end

    local rate = temperatureRate * F.airRate(weather.humidity)
    ledger.openRate = ledger.wetness <= 0 and math.max(rate, minRate) or 0
    ledger.shelteredRate = math.max(rate * F.SHELTERED_RATE, minRate)
    ledger.coldRate = (weather.isSnow or weather.precipitation <= 0) and F.coldRate(weather.temperature) or 0
    ledger.temperature = weather.temperature
    ledger.open = ledger.open + ledger.openRate * hours
    ledger.sheltered = ledger.sheltered + ledger.shelteredRate * hours
    ledger.cold = ledger.cold + ledger.coldRate * hours

    Weather.season(ledger, "seasonTemperature", weather.temperature, hours)
    Weather.season(ledger, "seasonHumidity", weather.humidity, hours)
    local warmth = ledger.seasonTemperature - F.RAW_SPOIL_ABOVE
    ledger.rawSpoiling = warmth > 0
    if ledger.rawSpoiling then
        ledger.rawSpoil = ledger.rawSpoil + (1 + warmth / 10) * hours
    end
    ledger.saltSpoiling = ledger.seasonTemperature > F.SALT_SPOIL_ABOVE and ledger.seasonHumidity > F.SALT_SPOIL_HUMIDITY
    if ledger.saltSpoiling then
        ledger.saltSpoil = ledger.saltSpoil + hours
    end
end

-- How a hanging stack is doing right now, for its popup. reason says why it isn't drying, and
-- hoursLeft assumes the weather stays as it is.
function F.stackStatus(isCold, modData, ledger)
    local hours = isCold and F.COLD_DRY_HOURS or F.DRY_HOURS
    local temperature = ledger.temperature or 0
    local rate, reason
    if isCold and modData.sheltered then
        rate, reason = 0, "Roof"
    elseif isCold and temperature > F.COLD_LIMIT then
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

-- The popup's word for the temperature, a translation key: good, cool, mild, too warm or frost.
function F.temperatureWord(isCold, celsius)
    if isCold then
        if celsius > F.COLD_LIMIT then return "IGUI_TraditionalPreservationFish_TempTooWarm" end
        if celsius > F.COLD_BEST then return "IGUI_TraditionalPreservationFish_TempMild" end
        return "IGUI_TraditionalPreservationFish_TempGoodCold"
    end
    if celsius >= 20 then return "IGUI_TraditionalPreservationFish_TempGoodWarm" end
    if celsius > 0 then return "IGUI_TraditionalPreservationFish_TempCool" end
    return "IGUI_TraditionalPreservationFish_TempFrost"
end

-- The ledger is the mod's global ModData table itself, so its keys are the ones in every save.
function F.getLedger()
    local data = ModData.getOrCreate(F.MOD_DATA_KEY)
    -- cold came after the first release, so a save can have the rest without it.
    if not data.cold then
        local ledger = F.newLedger(getGameTime():getWorldAgeHours())
        for key, value in pairs(ledger) do
            if data[key] == nil then data[key] = value end
        end
    end
    return data
end

-- The press runs on the plain game clock (no weather), timed from here.
function F.onPressStart(craftRecipeData)
    Weather.startClock(craftRecipeData, "pressStartHour", getGameTime():getWorldAgeHours())
end

-- Craft timers tick at a fixed speed whatever Day Length says and stop when the area unloads,
-- so this replaces their count with the game clock.
function F.onPressUpdate(craftRecipeData)
    Weather.showClock(craftRecipeData, "pressStartHour", getGameTime():getWorldAgeHours())
end

function F.hasRoom(capacity, storedWeight, weight)
    return storedWeight + weight <= capacity
end

-- Vanilla slots take any item and leave Craft greyed out, so each station names its fish.
function F.fishRefusal(isTub, fullType)
    if isTub and fullType ~= "TraditionalPreservationFish.SaltPackedFish" then return "IGUI_TraditionalPreservationFish_NeedsPacked" end
    if not isTub and fullType ~= "TraditionalPreservationFish.SaltPressedFish" and not F.COLD_FISH[fullType] then
        return "IGUI_TraditionalPreservationFish_NeedsPressed"
    end
    return nil
end

-- A tileset can't hold more than 512 tiles, so everything from FIRST_SHEET_SIZE on is in a second
-- one. Sprites are numbered straight through both.
F.FIRST_SHEET_SIZE = Tiles.FIRST_SHEET_SIZE

function F.spriteName(index)
    if index < F.FIRST_SHEET_SIZE then return Tiles.SHEETS[1].prefix .. index end
    return Tiles.SHEETS[2].prefix .. (index - F.FIRST_SHEET_SIZE)
end

-- The number of one of this mod's sprites, or nil for any other.
function F.spriteIndex(name)
    local sheet, index = string.match(name or "", "^traditionalpreservationfish_0([12])_(%d+)$")
    if not sheet then return nil end
    return tonumber(index) + (sheet == "2" and F.FIRST_SHEET_SIZE or 0)
end

-- The number of a station's own sprite, or nil for anything that isn't one of this mod's stations. A table
-- lookup: the slot rules ask this of every crafting station's slot.
local STATION_INDEX = {}
for _, name in ipairs(Tiles.STATIONS) do STATION_INDEX[name] = F.spriteIndex(name) end

function F.stationIndex(object)
    local sprite = object and object:getSprite()
    local name = sprite and sprite:getName()
    return name and STATION_INDEX[name]
end

-- The big beams stand in the open, unlike the frame.
function F.isOutdoors(params)
    return params.square:isOutside()
end

-- The hanger a station's sprite belongs to, whichever way it faces, or nil for a tub.
function F.hangerFor(spriteIndex)
    return F.HANGERS[spriteIndex - spriteIndex % 2]
end

-- Why a fish can't join the stack waiting on a frame, as a translation key, or nil if it can.
-- busyStacks is what is already hanging: running stacks and finished ones not yet taken.
function F.frameRefusal(hanger, busyStacks, waitingWeight, weight)
    if busyStacks >= hanger.stacks then return "IGUI_TraditionalPreservationFish_FrameFull" end
    if weight > hanger.stackWeight then return "IGUI_TraditionalPreservationFish_TooHeavy" end
    if not F.hasRoom(hanger.stackWeight, waitingWeight, weight) then
        return "IGUI_TraditionalPreservationFish_StackFull"
    end
    return nil
end

-- A random hanging look for a new stack, kept in its modData so it doesn't change.
function F.pickStyle(styles)
    return styles[ZombRand(#styles) + 1]
end

-- The style to show for an item: its stack's, or for fish still waiting, what it is.
function F.fishStyle(item)
    local style = item:getModData().style
    if style then return style end
    local fullType = item:getFullType()
    if fullType == "TraditionalPreservationFish.FishHalf" then return F.STYLE_HALF end
    if fullType == "TraditionalPreservationFish.GuttedFish" or fullType == "TraditionalPreservationFish.ColdDriedFish" then return F.STYLE_GUTTED end
    return F.STYLE_SALT
end

-- The look for a fish still drying. The last stage is kept for fish that have finished.
function F.dryingStage(progress)
    local running = F.DRYING_STAGES - 1
    return math.min(math.floor(progress * running), running - 1)
end

local function startStack(craftRecipeData)
    local ledger = F.getLedger()
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

-- OnStart for salted fish on a frame: marks the ledger and picks a look.
function F.onDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = F.pickStyle(F.SALT_STYLES)
end

-- Adds what the weather has given since the last update. It goes by the frame's shelter now,
-- so a roof built over a running frame counts from then on.
function F.onDryUpdate(craftRecipeData)
    local ledger = F.getLedger()
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end

    if modData.sheltered then
        modData.dried = modData.dried + ledger.sheltered - modData.lastSheltered
    else
        modData.dried = modData.dried + ledger.open - modData.lastOpen
    end
    -- A stack from before spoilage has no starting point, so it counts from now.
    modData.spoiled = (modData.spoiled or 0) + (ledger.saltSpoil - (modData.lastSaltSpoil or ledger.saltSpoil)) / F.SALT_SPOIL_HOURS
    modData.lastOpen = ledger.open
    modData.lastSheltered = ledger.sheltered
    modData.lastSaltSpoil = ledger.saltSpoil
    showProgress(craftRecipeData, modData, F.DRY_HOURS)
end

-- OnStart for unsalted fish on a cold frame.
function F.onColdDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = F.pickStyle(F.COLD_STYLES)
end

-- A roof keeps the wind off, so unsalted fish under one doesn't dry. It can still spoil.
function F.onColdDryUpdate(craftRecipeData)
    local ledger = F.getLedger()
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end

    if not modData.sheltered then
        modData.dried = modData.dried + ledger.cold - modData.lastCold
    end
    modData.spoiled = modData.spoiled + (ledger.rawSpoil - modData.lastRawSpoil) / F.RAW_SPOIL_HOURS
    modData.lastCold = ledger.cold
    modData.lastRawSpoil = ledger.rawSpoil
    showProgress(craftRecipeData, modData, F.COLD_DRY_HOURS)
end

-- A fish from another mod isn't in the list, and keeps the stage's own icon.
function F.iconIndex(source)
    local fullType = source:getFullType()
    -- Stages after these list their icons three times over: whole, gutted, then half.
    if fullType == "TraditionalPreservationFish.GuttedFish" then return source:getModelIndex() + #F.FISH_ICONS end
    if fullType == "TraditionalPreservationFish.FishHalf" then return source:getModelIndex() + #F.FISH_ICONS * 2 end
    if source:getModelIndex() >= 0 then return source:getModelIndex() end
    for index, fishType in ipairs(F.FISH_ICONS) do
        if fishType == fullType then return index - 1 end
    end
    return -1
end

-- Whether vanilla could cut this fish, which is what gives guts.
function F.hasGuts(fish)
    return fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
        and fish:getActualWeight() > F.MIN_SLICE_WEIGHT
end

-- Whether gutting this fish gives a Fish Head.
function F.hasHead(fish)
    return F.hasGuts(fish) and fish:getActualWeight() > F.HEAD_MIN_WEIGHT
end

-- A fillet vanilla cut counts as the food it holds; anything else, a loot fillet included, as what it weighs.
function F.foodWeight(fish)
    if fish:getFullType() == "Base.FishFillet" and fish:isCustomWeight() then
        return fish:getActualWeight() * F.FILLET_FOOD_WEIGHT
    end
    return fish:getActualWeight()
end

-- What a fish weighs once packed: gutted if it has guts, and a fillet by its food.
function F.packedWeight(fish)
    if F.hasGuts(fish) then return fish:getActualWeight() * (1 - F.GUTS_WEIGHT) end
    return F.foodWeight(fish)
end

-- The salt packing this fish takes in all, the recipe's own SALT_MIN included.
function F.saltFor(fish)
    local steps = math.ceil(F.packedWeight(fish) / F.SALT_STEP - 1e-6)
    return math.max(F.SALT_MIN, F.SALT_PER_STEP * steps)
end

-- A whole or gutted fish over SALT_WHOLE_MAX, which has to be split before it goes in the salt.
function F.tooBigToSaltWhole(fish)
    local whole = fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
    local gutted = fish:getFullType() == "TraditionalPreservationFish.GuttedFish"
    return (whole or gutted) and fish:getActualWeight() > F.SALT_WHOLE_MAX
end

-- The salt the character carries, bags included, with uses left.
local function saltCarried(character)
    local found = character:getInventory():getAllTagRecurse(ItemTag.SALT, ArrayList.new())
    local salt = {}
    for i = 0, found:size() - 1 do
        local item = found:get(i)
        if item:getCurrentUses() > 0 then table.insert(salt, item) end
    end
    return salt
end

function F.saltCarried(character)
    local uses = 0
    for _, item in ipairs(saltCarried(character)) do uses = uses + item:getCurrentUses() end
    return uses
end

-- OnTest sees every input, so the knife and the salt pass here too. The recipe finds its first SALT_MIN
-- anywhere in reach; the rest must be on you.
function F.canPack(item, character)
    if item:hasTag(ItemTag.SALT) or not instanceof(item, "Food") then return true end
    if F.tooBigToSaltWhole(item) then return false end
    if not character then return true end
    return F.saltCarried(character) >= F.saltFor(item)
end

-- Uses up the salt this fish takes past the recipe's own, part-used salt first. The Salt mod gives an empty
-- shaker or paper bag for what this empties, as it does for what the recipe empties.
function F.chargeSalt(fish, character)
    local owed = F.saltFor(fish) - F.SALT_MIN
    if owed <= 0 or not character then return end
    local salt = saltCarried(character)
    table.sort(salt, function(a, b) return a:getCurrentUses() < b:getCurrentUses() end)
    local emptied = ArrayList.new()
    for _, item in ipairs(salt) do
        if owed <= 0 then break end
        local uses = item:getCurrentUses()
        local taken = math.min(uses, owed)
        owed = owed - taken
        item:setCurrentUses(uses - taken)
        if taken == uses then
            item:getContainer():DoRemoveItem(item)
            emptied:add(item)
        end
    end
    local Salt = TraditionalPreservationSalt
    if Salt and Salt.returnEmpties and emptied:size() > 0 then Salt.returnEmpties(character, emptied) end
end

-- Hands a share of a fish's food to another item; hungerShare defaults to share.
-- Eating lowers HungChange and leaves BaseHunger, so a part-eaten fish stays part-eaten.
local function copyFood(from, to, share, hungerShare)
    hungerShare = hungerShare or share
    to:setCalories(from:getCalories() * share)
    to:setProteins(from:getProteins() * share)
    to:setLipids(from:getLipids() * share)
    to:setCarbohydrates(from:getCarbohydrates() * share)
    to:setBaseHunger(from:getBaseHunger() * hungerShare)
    to:setHungChange(from:getHungChange() * hungerShare)
end

-- Gives the next stage of a fish its share of the last stage's food, less the head if this stage takes it off.
function F.carry(source, target)
    local stage = F.STAGES[target:getFullType()]
    local headless = stage.headless and F.hasHead(source)
    -- The head takes its share of the food with it.
    local kept = headless and 1 - F.HEAD_FOOD or 1
    copyFood(source, target, stage.nutrition * kept, stage.hunger * kept)
    local keptWeight = stage.maxWeight and ZombRandFloat(stage.weight, stage.maxWeight) or stage.weight
    local cut = 0
    if stage.gutted and F.hasGuts(source) then cut = F.GUTS_WEIGHT end
    if headless then cut = cut + F.HEAD_WEIGHT end
    keptWeight = keptWeight * (1 - cut)
    target:setActualWeight(F.foodWeight(source) * keptWeight)
    target:setCustomWeight(true)

    -- The display name has the fish's size, as in Small Black Crappie, and a trailing space from vanilla.
    -- A stage item that never had a species (one spawned in) keeps its plain name, so a Salt Dried
    -- Fish doesn't become a Rehydrated Salt Dried Salt Dried Fish.
    local sourceData, targetData = source:getModData(), target:getModData()
    local fishName = sourceData.fishName
    if not fishName and not F.STAGES[source:getFullType()] then
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
        targetData.sliceable = not F.UNSLICEABLE[source:getFullType()] and source:getActualWeight() > F.MIN_SLICE_WEIGHT
    end

    target:setModelIndex(F.iconIndex(source))
end

-- InheritFood would copy the first fish onto all of them, and a batch can mix sizes, so each
-- fish hands its own values to one output.
function F.onCreateCured(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        F.carry(fish:get(i), created:get(i))
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
function F.fishHead(fish)
    local share = F.HEAD_FOOD
    local head = cutFrom(fish, "TraditionalPreservationFish.FishHead", F.HEAD_WEIGHT, share)
    copyFood(fish, head, share)
    head:setAge(fish:getAge())
    local fishName = fish:getModData().fishName or string.gsub(fish:getDisplayName(), "%s+$", "")
    head:setName(getText("IGUI_TraditionalPreservationFish_Head", fishName))
    head:setCustomName(true)
    return head
end

-- The stock carries the head's food on top of its own broth, and lists the head among its
-- ingredients, as a vanilla stew lists what went in.
function F.onCreateHeadStock(craftRecipeData)
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
function F.onCreateGutted(craftRecipeData, character)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local stage = F.STAGES[craftRecipeData:getAllCreatedItems():get(0):getFullType()]
    F.onCreateCured(craftRecipeData)
    if not F.hasGuts(fish) then return end

    local share = F.GUTS_WEIGHT
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    inventory:AddItem(cutFrom(fish, "Base.FishGuts", share, share))
    if stage.headless and F.hasHead(fish) then
        inventory:AddItem(F.fishHead(fish))
    end
end

-- Packing a whole fish guts it, but a fillet only takes the salt. One recipe packs both, so its
-- xpAward can't tell them apart. Both pack recipes end here, and take the rest of the fish's salt.
function F.onCreatePacked(craftRecipeData, character)
    character = character or craftRecipeData:getCharacter()
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local gutting = F.hasGuts(fish)
    F.onCreateGutted(craftRecipeData, character)
    F.chargeSalt(fish, character)
    if gutting then addXp(character, Perks.Butchering, F.PACK_GUTTING_XP) end
end

-- OnTest sees every input, so the knife passes here too.
function F.canSplit(item, character)
    if item:getFullType() ~= "TraditionalPreservationFish.GuttedFish" then return true end
    return item:getActualWeight() > F.STACK_WEIGHT
end

-- Each half keeps half the weight, not a fillet's share, so halves can't stack deep on a frame.
function F.onCreateSplit(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local halfName = getText("IGUI_TraditionalPreservationFish_Half", fish:getModData().fishName)
    for i = 0, created:size() - 1 do
        local half = created:get(i)
        copyFood(fish, half, 0.5)
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
function F.canSlice(item, character)
    if not F.STAGES[item:getFullType()] then return true end
    return item:getModData().sliceable == true
end

-- Slicing keeps the stage, so a Salt Packed fish gives Salt Packed fillets. A cured fish has no guts left
-- to lose, so each fillet keeps half its weight with half its food, not vanilla's raw share.
function F.onCreateSliced(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local filletName = getItemNameFromFullType("Base.FishFillet")
    for i = 0, created:size() - 1 do
        local fillet = created:get(i)
        local stage = F.STAGES[fillet:getFullType()]
        copyFood(fish, fillet, 0.5)
        fillet:setActualWeight(fish:getActualWeight() / 2)
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
function F.onCreateDried(craftRecipeData)
    F.onCreateCured(craftRecipeData)
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
local RAW_SPOIL_HOURS, SALT_SPOIL_HOURS = F.RAW_SPOIL_HOURS, F.SALT_SPOIL_HOURS
local BASE_DRY_HOURS, BASE_COLD_DRY_HOURS = F.DRY_HOURS, F.COLD_DRY_HOURS

-- Reads the sandbox options into the drying times and spoilage limits.
function F.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFish
    if not options then return end
    if options.DryDays then
        F.DRY_HOURS = options.DryDays * 24
        F.COLD_DRY_HOURS = BASE_COLD_DRY_HOURS * F.DRY_HOURS / BASE_DRY_HOURS
    end
    if options.MaxDryDays then F.MAX_DRY_DAYS = math.max(options.MaxDryDays, F.DRY_HOURS / 24) end
    F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
    local scale = SPOILAGE_SCALES[options.Spoilage] or 1
    F.RAW_SPOIL_HOURS = RAW_SPOIL_HOURS * scale
    F.SALT_SPOIL_HOURS = SALT_SPOIL_HOURS * scale
end

local function applyRecipeTime(name, hours)
    Weather.setRecipeHours(name, hours, "TraditionalPreservationFish")
end

-- Sets each slow recipe's script time to the sandbox's, so the crafting window shows the right length.
function F.applyRecipeTimes()
    F.applySandbox()
    applyRecipeTime("TraditionalPreservationFish.PressSaltedFish", F.PRESS_HOURS)
    applyRecipeTime("TraditionalPreservationFish.HangFishToDry", F.DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFish.HangFishToColdDry", F.COLD_DRY_HOURS)
end

Events.OnInitGlobalModData.Add(F.applyRecipeTimes)
