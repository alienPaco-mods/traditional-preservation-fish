-- Traditional Preservation (Fish): commands for the debug Lua console, loaded only in debug mode.
-- Type TPF.help() in the console for the list. See DEVHELP.md in the mod folder.
if not isDebugEnabled() then return end

local F = TraditionalPreservationFish
TPF = {}

local function say(text) print("[TPF] " .. text) end

local function give(fullType, count)
    local inventory = getPlayer():getInventory()
    local items = {}
    for _ = 1, count or 1 do table.insert(items, inventory:AddItem(fullType)) end
    return items
end

function TPF.help()
    say("TPF.weather()             the drying weather now: temperature, season, wetness, rates, spoilage and totals")
    say("TPF.wind()                start a log of live wind every 10 minutes; again to print it beside the forecast")
    say("TPF.age(hours)            give every hanging stack this many hours of perfect drying weather")
    say("TPF.spoil(hours)          add this many hours of spoiling weather, to test rotting stacks")
    say("TPF.frost(hours)          add this many hours of hard frost, to test early frost on fresh cold stacks")
    say("TPF.heat(hours)           add this many hours of hot sun, to test it on fresh open salt stacks")
    say("TPF.warmCure(hours)       add this many hours of a warm cure at 25 C, to test souring in a running tub")
    say("TPF.dry()                 clear the wetness, so open and cold frames start drying again at once")
    say("TPF.mature(days)          age the Cold Dried fish you carry by this many days, to test ripening")
    say("TPF.stockfish(n)          spawn n unripe Cold Dried fish (fresh off the frame), for the pallet")
    say("TPF.pallet()              the Stockfish Pallet near you: its place, ripening speed, stack and fish")
    say("TPF.fish(name, weight, n) spawn n whole fish, e.g. TPF.fish(\"Walleye\", 4, 2). TPF.fish() lists the names")
    say("TPF.heads(n)              spawn n Fish Heads")
    say("TPF.stock()               spawn a Pot of Fish Head Stock")
    say("TPF.salt(n)               spawn n vanilla Salt shakers")
    say("The Salting Tub runs on the game clock, so TPF.age doesn't speed up pressing.")
end

function TPF.weather()
    local ledger = F.getLedger()
    local function n(value) return value and string.format("%.2f", value) or "-" end
    say("Temperature now " .. n(ledger.temperature) .. " C, season (10-day average) " .. n(ledger.seasonTemperature)
        .. " C, humidity " .. n(ledger.seasonHumidity) .. ", wetness " .. n(ledger.wetness) .. " (cold frames " .. n(ledger.coldWetness) .. ")"
        .. ", wind " .. n(ledger.wind))
    say("Drying speed now: open " .. n(ledger.openRate) .. ", covered " .. n(ledger.coveredRate) .. ", indoors " .. n(ledger.shelteredRate)
        .. ", cold " .. n(ledger.coldRate) .. ", cold covered " .. n(ledger.coldCoveredRate))
    say("Spoiling now: unsalted " .. tostring(ledger.rawSpoiling == true) .. ", salted " .. tostring(ledger.saltSpoiling == true)
        .. ", warm cure " .. tostring(ledger.warmCuring == true) .. ", hot sun " .. tostring((ledger.temperature or 0) > F.HEAT_ABOVE))
    say("Totals (hours at full speed): open " .. n(ledger.open) .. ", covered " .. n(ledger.covered) .. ", indoors " .. n(ledger.sheltered)
        .. ", cold " .. n(ledger.cold) .. ", cold covered " .. n(ledger.coldCovered)
        .. ", raw spoil " .. n(ledger.rawSpoil) .. ", salt spoil " .. n(ledger.saltSpoil)
        .. ", hard frost " .. n(ledger.hardFrost) .. ", cold fish wet " .. n(ledger.coldWet) .. ", warm cure " .. n(ledger.warmCure)
        .. ", hot sun " .. n(ledger.heat))
    say(string.format("A stack needs %d hours to salt dry and %d to cold dry.", F.DRY_HOURS, F.COLD_DRY_HOURS))
end

-- Wind probe for the cold-drying wind curve: live wind every 10 minutes against the day's forecast.
local windLog
local function sampleWind()
    local climate = getClimateManager()
    local forecast = climate:getClimateForecaster():getForecast()
    local wet = climate:getPrecipitationIntensity() > 0
    local s = windLog[wet and "wet" or "dry"]
    local wind = climate:getWindIntensity()
    s.n, s.sum, s.min, s.max = s.n + 1, s.sum + wind, math.min(s.min, wind), math.max(s.max, wind)
    windLog.forecast = windLog.forecast + (forecast and forecast:getWindPower():getTotalMean() or 0)
end

function TPF.wind()
    local function line(name, s)
        if s.n == 0 then return say(name .. ": no samples") end
        say(string.format("%s: %d samples, mean %.3f, min %.3f, max %.3f", name, s.n, s.sum / s.n, s.min, s.max))
    end
    if not windLog then
        local function empty() return { n = 0, sum = 0, min = 1, max = 0 } end
        windLog = { dry = empty(), wet = empty(), forecast = 0 }
        Events.EveryTenMinutes.Add(sampleWind)
        return say("Wind log started: live wind every 10 minutes. TPF.wind() again prints it and stops.")
    end
    Events.EveryTenMinutes.Remove(sampleWind)
    line("Live wind, dry", windLog.dry)
    line("Live wind, rain or snow", windLog.wet)
    local n = windLog.dry.n + windLog.wet.n
    if n > 0 then say(string.format("Forecast wind for the same days: mean %.3f", windLog.forecast / n)) end
    windLog = nil
end

function TPF.age(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.open, ledger.sheltered, ledger.cold = ledger.open + hours, ledger.sheltered + hours, ledger.cold + hours
    ledger.covered, ledger.coldCovered = ledger.covered + hours, ledger.coldCovered + hours
    say(string.format("Added %.0f hours of perfect drying weather. Stacks update within a few seconds.", hours))
end

function TPF.spoil(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.rawSpoil, ledger.saltSpoil = ledger.rawSpoil + hours, ledger.saltSpoil + hours
    say(string.format("Added %.0f hours of spoiling weather. A fresh cold stack rots after %d.", hours, F.RAW_SPOIL_HOURS))
end

function TPF.frost(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.hardFrost = ledger.hardFrost + hours
    say(string.format("Added %.0f hours of hard frost. A fresh cold stack loses %.0f%% of its keeping per %d hours, at most %.0f%%.",
        hours, F.FREEZE_DAMAGE * 100, F.FREEZE_DAMAGE_HOURS, F.DAMAGE_CAP * 100))
end

function TPF.heat(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.heat = ledger.heat + hours
    say(string.format("Added %.0f hours of hot sun. A fresh open salt stack loses %.0f%% of its keeping per %d hours, at most %.0f%%.",
        hours, F.HEAT_DAMAGE * 100, F.HEAT_DAMAGE_HOURS, F.DAMAGE_CAP * 100))
end

-- At 25 C a warm cure runs at 1.5 times its 20 C rate.
function TPF.warmCure(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.warmCure = ledger.warmCure + hours * 1.5
    say(string.format("Added %.0f hours of a warm cure at 25 C: about %.0f%% off a batch in the tub now.",
        hours, hours * 1.5 * F.WARM_CURE_SHARE / F.RAW_SPOIL_HOURS * 100))
end

-- Ripeness runs on the fish's own food clock, so this ages the fish themselves.
function TPF.mature(days)
    days = days or 10
    local fish = getPlayer():getInventory():getAllTypeRecurse("TraditionalPreservationFish.ColdDriedFish")
    for i = 0, fish:size() - 1 do
        local item = fish:get(i)
        item:setAge(item:getAge() + days)
        F.rename(item)
    end
    say(string.format("Aged %d Cold Dried fish by %d days. Ripe after %d.", fish:size(), days, F.MATURE_DAYS))
end

function TPF.dry()
    local ledger = F.getLedger()
    ledger.wetness, ledger.coldWetness = 0, 0
    say("Wetness cleared.")
end

function TPF.fish(name, weight, count)
    if not name then
        local names = {}
        for _, fullType in ipairs(F.FISH_ICONS) do table.insert(names, (fullType:gsub("^Base%.", ""))) end
        return say("Fish: " .. table.concat(names, ", "))
    end
    local fullType = name:find("%.") and name or "Base." .. name
    for _, fish in ipairs(give(fullType, count)) do
        if weight and fish:getActualWeight() > 0 then
            -- Scales the food with the weight, as a caught fish's is.
            local scale = weight / fish:getActualWeight()
            fish:setCalories(fish:getCalories() * scale)
            fish:setProteins(fish:getProteins() * scale)
            fish:setLipids(fish:getLipids() * scale)
            fish:setCarbohydrates(fish:getCarbohydrates() * scale)
            fish:setBaseHunger(fish:getBaseHunger() * scale)
            fish:setHungChange(fish:getHungChange() * scale)
            fish:setActualWeight(weight)
            fish:setWeight(weight)
            fish:setCustomWeight(true)
        end
    end
    say(string.format("Gave %d %s%s.", count or 1, fullType, weight and (" at weight " .. weight) or ""))
end

function TPF.heads(count)
    give("TraditionalPreservationFish.FishHead", count)
    say("Gave " .. (count or 1) .. " Fish Head(s). Spawned heads have the item's default food values.")
end

function TPF.stock()
    give("TraditionalPreservationFish.PotOfFishHeadStock")
    say("Gave a Pot of Fish Head Stock (default values, no head listed).")
end

function TPF.salt(count)
    give("Base.Salt", count)
    say("Gave " .. (count or 1) .. " Salt shaker(s).")
end

function TPF.stockfish(count)
    for _, fish in ipairs(give("TraditionalPreservationFish.ColdDriedFish", count)) do
        fish:getModData().fishName = "Walleye"
        fish:getModData().matureAge = fish:getAge()
        F.rename(fish)
    end
    say(string.format("Gave %d unripe Cold Dried fish. Ripe after %d days on a shelf.", count or 1, F.MATURE_DAYS))
end

function TPF.pallet()
    local Weather = require "TraditionalPreservationCore/Weather"
    local Tiles = require "TraditionalPreservationFish/Tiles"
    local player = getPlayer()
    local px, py, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    for x = px - 3, px + 3 do
        for y = py - 3, py + 3 do
            local square = getCell():getGridSquare(x, y, z)
            local objects = square and square:getObjects()
            for i = 0, objects and objects:size() - 1 or -1 do
                local object = objects:get(i)
                if object:getSprite() and object:getSprite():getName() == Tiles.PALLET and object:getContainer() then
                    local place = Weather.placeOf(object, true)
                    local count, ripest = 0, 0
                    F.eachStockfish(object:getContainer(), function(fish)
                        count = count + 1
                        ripest = math.max(ripest, F.ripeness(fish))
                    end)
                    say(string.format("Pallet at %d,%d floor %d: %s, ripens x%.1f (%d days to ripe). Stack: %s. %d stockfish, ripest %.0f%%.",
                        x, y, z, place, F.palletSpeed(place, z), F.MATURE_DAYS / F.palletSpeed(place, z),
                        tostring(F.palletLevel(object:getContainer()) or "none"), count, ripest * 100))
                    return
                end
            end
        end
    end
    say("No Stockfish Pallet within 3 tiles on this floor.")
end

say("Debug commands loaded. Type TPF.help() in the Lua console.")
