-- Traditional Preservation (Fish & Meat): commands for the debug Lua console, loaded only in debug mode.
-- Type TPFM.help() in the console for the list. See DEVHELP.md in the mod folder.
if not isDebugEnabled() then return end

local F = TraditionalPreservationFishMeat
TPFM = {}

local function say(text) print("[TPFM] " .. text) end

local function give(fullType, count)
    local inventory = getPlayer():getInventory()
    local items = {}
    for _ = 1, count or 1 do table.insert(items, inventory:AddItem(fullType)) end
    return items
end

function TPFM.help()
    say("TPFM.weather()             the drying weather now: temperature, season, wetness, rates, spoilage and totals")
    say("TPFM.wind()                start a log of live wind every 10 minutes; again to print it beside the forecast")
    say("TPFM.age(hours)            give every hanging stack this many hours of perfect drying weather")
    say("TPFM.spoil(hours)          add this many hours of spoiling weather, to test rotting stacks")
    say("TPFM.frost(hours)          add this many hours of hard frost, to test early frost on fresh cold stacks")
    say("TPFM.heat(hours)           add this many hours of hot sun, to test it on fresh open salt stacks")
    say("TPFM.warmCure(hours)       add this many hours of a warm cure at 25 C, to test souring in a running tub")
    say("TPFM.dry()                 clear the wetness, so open and cold frames start drying again at once")
    say("TPFM.mature(days)          age the Cold Dried fish you carry by this many days, to test ripening")
    say("TPFM.stockfish(n)          spawn n unripe Cold Dried fish (fresh off the frame), for the pallet")
    say("TPFM.pallet()              the Stockfish Pallet near you: its place, ripening speed, stack and fish")
    say("TPFM.fish(name, weight, n) spawn n whole fish, e.g. TPFM.fish(\"Walleye\", 4, 2). TPFM.fish() lists the names")
    say("TPFM.heads(n)              spawn n Fish Heads")
    say("TPFM.stock()               spawn a Pot of Fish Head Stock")
    say("TPFM.salt(n)               spawn n vanilla Salt shakers")
    say("TPFM.fat(n)                spawn n each of Pork Fat, Beef Suet and Mutton Fat")
    say("TPFM.meat(n)               spawn n each of the cuts that go in the salt: Beef, Steak, Mutton Chop, Venison")
    say("TPFM.cured(n)              spawn n each of those cuts already Salt Cured, ready for the frame as charque")
    say("TPFM.rain(hours)           add this many hours of rain and wet the open frames, to test rain on open charque")
    say("TPFM.fatPot(state)         spawn a Pot of Pork Fat: \"cooked\" (the default), \"burnt\" or \"raw\"")
    say("TPFM.fatRows()             the fat each vanilla animal's butchering table gives now")
    say("TPFM.potted()              spawn a Pot, Lard, Salt, four cuts and the three clay vessels for Potted Meat")
    say("TPFM.crock(count)          spawn full Crocks of Potted Meat (four Steaks in Lard each, in a Glazed Clay Jar)")
    say("TPFM.crocks()              each Crock of Potted Meat on you or within 4 tiles: place, keeping rate, days left")
    say("TPFM.keep(days)            age those crocks by this many days at their place's rate now")
    say("TPFM.flueKit()             spawn both flue kits: 2 Clay Pipe Segments, 3 Flat Stones, 3 Clay, a trowel and a shovel")
    say("TPFM.smokehouse()          each Smokehouse tile within 3 tiles: facing, part, the Fireboxes beside it and why each can't join")
    say("The Salting Tub runs on the game clock, so TPFM.age doesn't speed up curing.")
end

function TPFM.weather()
    local ledger = F.getLedger()
    local function n(value) return value and string.format("%.2f", value) or "-" end
    say("Temperature now " .. n(ledger.temperature) .. " C, season (10-day average) " .. n(ledger.seasonTemperature)
        .. " C, humidity " .. n(ledger.seasonHumidity) .. ", wetness " .. n(ledger.wetness) .. " (cold frames " .. n(ledger.coldWetness) .. ")"
        .. ", wind " .. n(ledger.wind))
    say("Drying speed now: open " .. n(ledger.openRate) .. ", covered " .. n(ledger.coveredRate) .. ", indoors " .. n(ledger.shelteredRate)
        .. ", cold " .. n(ledger.coldRate) .. ", cold covered " .. n(ledger.coldCoveredRate)
        .. ", charque " .. n(ledger.charqueRate) .. ", charque covered " .. n(ledger.charqueCoveredRate) .. ", charque indoors " .. n(ledger.charqueShelteredRate))
    say("Spoiling now: unsalted " .. tostring(ledger.rawSpoiling == true) .. ", salted " .. tostring(ledger.saltSpoiling == true)
        .. ", warm cure " .. tostring(ledger.warmCuring == true) .. ", hot sun " .. tostring((ledger.temperature or 0) > F.HEAT_ABOVE))
    say("Totals (hours at full speed): open " .. n(ledger.open) .. ", covered " .. n(ledger.covered) .. ", indoors " .. n(ledger.sheltered)
        .. ", cold " .. n(ledger.cold) .. ", cold covered " .. n(ledger.coldCovered)
        .. ", raw spoil " .. n(ledger.rawSpoil) .. ", salt spoil " .. n(ledger.saltSpoil)
        .. ", hard frost " .. n(ledger.hardFrost) .. ", cold fish wet " .. n(ledger.coldWet) .. ", warm cure " .. n(ledger.warmCure)
        .. ", hot sun " .. n(ledger.heat) .. ", charque " .. n(ledger.charque) .. ", charque covered " .. n(ledger.charqueCovered)
        .. ", charque indoors " .. n(ledger.charqueSheltered) .. ", rain " .. n(ledger.charqueRain))
    say(string.format("A stack needs %d hours to salt dry, %d to cold dry and %d to dry as charque.", F.DRY_HOURS, F.COLD_DRY_HOURS, F.CHARQUE_HOURS))
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

function TPFM.wind()
    local function line(name, s)
        if s.n == 0 then return say(name .. ": no samples") end
        say(string.format("%s: %d samples, mean %.3f, min %.3f, max %.3f", name, s.n, s.sum / s.n, s.min, s.max))
    end
    if not windLog then
        local function empty() return { n = 0, sum = 0, min = 1, max = 0 } end
        windLog = { dry = empty(), wet = empty(), forecast = 0 }
        Events.EveryTenMinutes.Add(sampleWind)
        return say("Wind log started: live wind every 10 minutes. TPFM.wind() again prints it and stops.")
    end
    Events.EveryTenMinutes.Remove(sampleWind)
    line("Live wind, dry", windLog.dry)
    line("Live wind, rain or snow", windLog.wet)
    local n = windLog.dry.n + windLog.wet.n
    if n > 0 then say(string.format("Forecast wind for the same days: mean %.3f", windLog.forecast / n)) end
    windLog = nil
end

function TPFM.age(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.open, ledger.sheltered, ledger.cold = ledger.open + hours, ledger.sheltered + hours, ledger.cold + hours
    ledger.covered, ledger.coldCovered = ledger.covered + hours, ledger.coldCovered + hours
    ledger.charque, ledger.charqueCovered, ledger.charqueSheltered = ledger.charque + hours, ledger.charqueCovered + hours, ledger.charqueSheltered + hours
    say(string.format("Added %.0f hours of perfect drying weather. Stacks update within a few seconds.", hours))
end

function TPFM.spoil(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.rawSpoil, ledger.saltSpoil = ledger.rawSpoil + hours, ledger.saltSpoil + hours
    say(string.format("Added %.0f hours of spoiling weather. A fresh cold stack rots after %d.", hours, F.RAW_SPOIL_HOURS))
end

function TPFM.frost(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.hardFrost = ledger.hardFrost + hours
    say(string.format("Added %.0f hours of hard frost. A fresh cold stack loses %.0f%% of its keeping per %d hours, at most %.0f%%.",
        hours, F.FREEZE_DAMAGE * 100, F.FREEZE_DAMAGE_HOURS, F.DAMAGE_CAP * 100))
end

function TPFM.heat(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.heat = ledger.heat + hours
    say(string.format("Added %.0f hours of hot sun. A fresh open salt stack loses %.0f%% of its keeping per %d hours, at most %.0f%%.",
        hours, F.HEAT_DAMAGE * 100, F.HEAT_DAMAGE_HOURS, F.DAMAGE_CAP * 100))
end

-- Rain on an open charque frame takes back CHARQUE_REWET of its progress each CHARQUE_RAIN_HOURS, and leaves it wet.
function TPFM.rain(hours)
    hours = hours or F.CHARQUE_RAIN_HOURS
    local ledger = F.getLedger()
    ledger.charqueRain = ledger.charqueRain + hours
    ledger.wetness = 1
    say(string.format("Added %.0f hours of rain: an open charque stack keeps %.0f%% of its progress, and waits for the frame to dry off (TPFM.dry()).",
        hours, (1 - F.CHARQUE_REWET) ^ (hours / F.CHARQUE_RAIN_HOURS) * 100))
end

-- At 25 C a warm cure runs at 1.5 times its 20 C rate.
function TPFM.warmCure(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.warmCure = ledger.warmCure + hours * 1.5
    say(string.format("Added %.0f hours of a warm cure at 25 C: about %.0f%% off a batch in the tub now.",
        hours, hours * 1.5 * F.WARM_CURE_SHARE / F.RAW_SPOIL_HOURS * 100))
end

-- Ripeness runs on the fish's own food clock, so this ages the fish themselves.
function TPFM.mature(days)
    days = days or 10
    local fish = getPlayer():getInventory():getAllTypeRecurse("TraditionalPreservationFishMeat.ColdDriedFish")
    for i = 0, fish:size() - 1 do
        local item = fish:get(i)
        item:setAge(item:getAge() + days)
        F.rename(item)
    end
    say(string.format("Aged %d Cold Dried fish by %d days. Ripe after %d.", fish:size(), days, F.MATURE_DAYS))
end

function TPFM.dry()
    local ledger = F.getLedger()
    ledger.wetness, ledger.coldWetness = 0, 0
    say("Wetness cleared.")
end

function TPFM.fish(name, weight, count)
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

function TPFM.heads(count)
    give("TraditionalPreservationFishMeat.FishHead", count)
    say("Gave " .. (count or 1) .. " Fish Head(s). Spawned heads have the item's default food values.")
end

function TPFM.stock()
    give("TraditionalPreservationFishMeat.PotOfFishHeadStock")
    say("Gave a Pot of Fish Head Stock (default values, no head listed).")
end

function TPFM.salt(count)
    give("Base.Salt", count)
    say("Gave " .. (count or 1) .. " Salt shaker(s).")
end

function TPFM.fat(count)
    for _, row in ipairs(F.FAT_ROWS) do give(row.item, count) end
    say("Gave " .. (count or 1) .. " each of Pork Fat, Beef Suet and Mutton Fat.")
end

function TPFM.meat(count)
    for _, cut in ipairs(F.MEAT_CUTS) do give(cut, count) end
    say("Gave " .. (count or 1) .. " each of Beef, Steak, Mutton Chop and Venison.")
end

-- Each cut as the tub gives it, named for the cut ("Steak (Salt Cured)").
function TPFM.cured(count)
    local inventory = getPlayer():getInventory()
    for _, cut in ipairs(F.MEAT_CUTS) do
        for _ = 1, count or 1 do
            local raw = instanceItem(cut)
            F.carry(raw, inventory:AddItem(F.CURED_MEAT))
        end
    end
    say("Gave " .. (count or 1) .. " each of Beef, Steak, Mutton Chop and Venison, Salt Cured.")
end

function TPFM.fatPot(state)
    local pot = give("TraditionalPreservationFishMeat.PotOfPorkFat")[1]
    state = state or "cooked"
    if state == "cooked" then pot:setCooked(true) end
    if state == "burnt" then pot:setBurnt(true) end
    say("Gave a Pot of Pork Fat (" .. state .. ").")
end

-- What Potted Meat takes: a Pot, a Lard, salt, four cuts (two of them pork) and one of each clay vessel.
function TPFM.potted()
    for _, fullType in ipairs({ "Base.Pot", "Base.Lard", "Base.Salt", "Base.Steak", "Base.Beef", "Base.PorkChop",
            "Base.Pork", "Base.ClayJar", "Base.ClayJarGlazed", "Base.ClayPot" }) do
        give(fullType)
    end
    say("Gave a Pot, Lard, Salt, Steak, Beef, Pork Chop, Pork and a Clay Jar, Glazed Clay Jar and Clay Pot.")
end

function TPFM.crock(count)
    local batch = F.newPottedBatch(nil)
    for _ = 1, F.POTTED_MAX do F.addPottedCut(batch, instanceItem("Base.Steak")) end
    for _, crock in ipairs(give(F.CROCK, count)) do F.fillCrock(crock, batch, "Base.ClayJarGlazed") end
    say(string.format("Gave %d full Crock(s) of Potted Meat.", count or 1))
end

-- Crocks carried, and in containers within CROCK_REACH tiles on the player's floor.
local CROCK_REACH = 4
local function nearbyCrocks()
    local player, found = getPlayer(), {}
    local function add(container)
        local crocks = container and container:getAllTypeRecurse(F.CROCK)
        for i = 0, crocks and crocks:size() - 1 or -1 do table.insert(found, crocks:get(i)) end
    end
    add(player:getInventory())
    local cell, x, y, z = getCell(), player:getX(), player:getY(), player:getZ()
    for dx = -CROCK_REACH, CROCK_REACH do
        for dy = -CROCK_REACH, CROCK_REACH do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            local objects = square and square:getObjects()
            for i = 0, objects and objects:size() - 1 or -1 do
                local object = objects:get(i)
                for c = 0, object:getContainerCount() - 1 do add(object:getContainerByIndex(c)) end
            end
        end
    end
    return found
end

function TPFM.crocks()
    if not F.pottedByPlace() then say("Potted Meat keeping by place is off in the sandbox.") end
    local crocks, ledger = nearbyCrocks(), F.pottedLedger()
    if #crocks == 0 then return say("No Crock of Potted Meat on you or within " .. CROCK_REACH .. " tiles.") end
    for _, crock in ipairs(crocks) do
        F.keepCrock(crock)
        local keep = crock:getModData().tpfmKeep
        local place = keep and keep.record.place or "?"
        local rate = F.pottedRate(place, ledger) * F.POTTED_KEEP.speed()
        local age = crock:getAge()
        local function left(limit)
            if age >= limit then return "past" end
            return rate > 0 and string.format("%.0f d", (limit - age) / rate) or "never"
        end
        say(string.format("%s in %s: x%.2f (%.0f days fresh here), age %.1f d, stale in %s, rotten in %s%s",
            crock:getDisplayName(), place, rate, rate > 0 and crock:getOffAge() / rate or 0, age,
            left(crock:getOffAge()), left(crock:getOffAgeMax()), crock:getModData().tpfmOpened and ", opened" or ""))
    end
end

function TPFM.keep(days)
    days = days or 10
    local crocks, ledger = nearbyCrocks(), F.pottedLedger()
    for _, crock in ipairs(crocks) do
        local keep = F.keepCrock(crock)
        if keep then
            keep.record.age = keep.record.age + days * 24 * F.pottedRate(keep.record.place, ledger) * F.POTTED_KEEP.speed()
            crock:setAge(keep.base + keep.record.age / 24)
        end
    end
    say(string.format("Kept %d crock(s) for %d days at their places. TPFM.crocks() to see them.", #crocks, days))
end

function TPFM.fatRows()
    say("Butchering fat is " .. (F.fatEnabled() and "on" or "off") .. " in the sandbox.")
    for _, row in ipairs(F.FAT_ROWS) do
        for _, name in ipairs(row.animals) do
            local found = "no row"
            local animal = AnimalPartsDefinitions.animals[name]
            for _, part in ipairs(animal and animal.parts or {}) do
                if part.item == row.item then found = string.format("%s %d-%d", row.item, part.minNb, part.maxNb) end
            end
            say(name .. ": " .. (animal and found or "not in vanilla's table"))
        end
    end
end

function TPFM.stockfish(count)
    for _, fish in ipairs(give("TraditionalPreservationFishMeat.ColdDriedFish", count)) do
        fish:getModData().fishName = "Walleye"
        fish:getModData().matureAge = fish:getAge()
        F.rename(fish)
    end
    say(string.format("Gave %d unripe Cold Dried fish. Ripe after %d days on a shelf.", count or 1, F.MATURE_DAYS))
end

function TPFM.pallet()
    local Weather = require "TraditionalPreservationCore/Weather"
    local Tiles = require "TraditionalPreservationFishMeat/Tiles"
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

function TPFM.flueKit()
    for _, fullType in ipairs({ "Base.ClayPipeSegment", "Base.ClayPipeSegment", "Base.FlatStone", "Base.FlatStone",
        "Base.FlatStone", "Base.Clay", "Base.Clay", "Base.Clay", "Base.MasonsTrowel", "Base.Shovel" }) do
        give(fullType)
    end
    say("Gave both flue kits, a Mason's Trowel and a Shovel. Connect from the Firebox's menu or the Smokehouse's.")
end

local PARTS = { [0] = "back", [1] = "door" }

function TPFM.smokehouse()
    local player, seen = getPlayer(), 0
    local cell, x, y, z = getCell(), math.floor(player:getX()), math.floor(player:getY()), player:getZ()
    for dx = -3, 3 do
        for dy = -3, 3 do
            local tile, face, part = F.chamberOn(cell:getGridSquare(x + dx, y + dy, z))
            if tile then
                seen = seen + 1
                local lines = {}
                for _, found in ipairs(F.fireboxesBy(tile)) do
                    if found.tile == tile then
                        local flue, side = F.flueOf(found.firebox)
                        table.insert(lines, string.format("Firebox at %d,%d: flue %s %s, %s", found.firebox:getX(), found.firebox:getY(),
                            tostring(flue), tostring(side), F.joinedChamber(found.firebox) == tile and "joined here"
                            or (F.connectRefusalFor(found) or "may join")))
                    end
                end
                say(string.format("%d,%d facing %s, %s tile, entry art %s; %s", tile:getX(), tile:getY(), face == 0 and "S" or "E",
                    PARTS[part], tostring(F.chamberEntry(tile)), #lines > 0 and table.concat(lines, "; ") or "no Firebox beside it"))
            end
        end
    end
    if seen == 0 then say("No Smokehouse within 3 tiles on this floor.") end
end

say("Debug commands loaded. Type TPFM.help() in the Lua console.")
