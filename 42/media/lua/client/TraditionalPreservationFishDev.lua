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
    say("TPF.dry()                 clear the wetness, so open frames start drying again at once")
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
        .. " C, humidity " .. n(ledger.seasonHumidity) .. ", wetness " .. n(ledger.wetness))
    say("Drying speed now: open " .. n(ledger.openRate) .. ", under a roof " .. n(ledger.shelteredRate) .. ", cold " .. n(ledger.coldRate))
    say("Spoiling now: unsalted " .. tostring(ledger.rawSpoiling == true) .. ", salted " .. tostring(ledger.saltSpoiling == true))
    say("Totals (hours at full speed): open " .. n(ledger.open) .. ", roof " .. n(ledger.sheltered) .. ", cold " .. n(ledger.cold)
        .. ", raw spoil " .. n(ledger.rawSpoil) .. ", salt spoil " .. n(ledger.saltSpoil))
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
    say(string.format("Added %.0f hours of perfect drying weather. Stacks update within a few seconds.", hours))
end

function TPF.spoil(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.rawSpoil, ledger.saltSpoil = ledger.rawSpoil + hours, ledger.saltSpoil + hours
    say(string.format("Added %.0f hours of spoiling weather. A cold stack rots after %d.", hours, F.RAW_SPOIL_HOURS))
end

function TPF.dry()
    F.getLedger().wetness = 0
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

say("Debug commands loaded. Type TPF.help() in the Lua console.")
