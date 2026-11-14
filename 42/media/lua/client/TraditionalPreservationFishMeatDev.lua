-- Traditional Preservation (Fish & Meat): commands for the debug Lua console, loaded only in debug mode.
-- Type TPFM.help() in the console for the list. See DEVHELP.md in the mod folder.
if not isDebugEnabled() then return end

local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Season = require "TraditionalPreservationCore/Season"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
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
    say("TPFM.here()                which place you're standing in: Open, Covered (a roof, no room), Sheltered (a room), Loft (a room upstairs) or Basement")
    say("TPFM.wind()                start a log of live wind every 10 minutes; again to print it beside the forecast")
    say("TPFM.age(hours)            give every hanging stack this many hours of perfect drying weather (Corned meat in a Smokehouse spoils with it)")
    say("TPFM.spoil(hours)          add this many hours of spoiling weather, to test rotting stacks")
    say("TPFM.underSalt(hours)      add this many hours of a 10 C shed (default 168) for Corned meat hanging in a Smokehouse, a room or under a roof")
    say("TPFM.frost(hours)          add this many hours of hard frost, to test early frost on fresh cold stacks")
    say("TPFM.heat(hours)           add this many hours of hot sun, to test it on fresh open salt stacks")
    say("TPFM.warmCure(hours)       add this many hours of a warm cure at 25 C, to test a warm cure spoiling a running tub")
    say("TPFM.longCure(hours)       add this many hours of a 15 C season (default 168) to a running Country Cure, which wants 10 C or less")
    say("TPFM.dry()                 clear the wetness, so open and cold frames start drying again at once")
    say("TPFM.mature(days)          age the stockfish and dry cured meat you carry by this many days, to test maturing and ageing")
    say("TPFM.food()                the cured fish and meat you carry: hunger, unhappiness, boredom, thirst, age against its days, ageing")
    say("TPFM.fish(name, n, weight, stage) spawn n fish, e.g. TPFM.fish(\"Walleye\", 2, 4); stage \"cured\", \"dried\", \"hotSmoked\", \"coldSmoked\" or \"stockfish\" (it may take weight's place); TPFM.fish() lists the names, \"all\" gives each")
    say("TPFM.meat(name, n, stage)  spawn n of a cut, e.g. TPFM.meat(\"Steak\", 2) or TPFM.meat(\"all\", 1, \"corned\"); stage \"corned\", \"country\", \"charque\", \"hotSmoked\" or \"dryCured\" (chicken, turkey and rabbit: corned and hotSmoked only); TPFM.meat() lists the names")
    say("TPFM.give(name, n, option) spawn n of: head, stock, salt, fat, fatPot (option \"burnt\" or \"raw\"), crock (full, four Steaks in Lard), blood (a Bucket of 4 L; option \"cured\" or \"spoiled\"), casings, saltedCasings, blackPudding, bloodSausage (boiled; option \"stale\"), smokedBloodSausage, freshSausage (raw; option \"seasoned\" or \"stale\"), smokedSausage (option \"seasoned\"). TPFM.give() lists them")
    say("TPFM.kit(kind)             the things a test needs: \"potted\" (Potted Meat), \"stock\", \"poultry\" (hot smoked poultry), \"blood\" (black pudding, blood sausage, smoked blood sausage) or \"sausage\" (Smoked Sausage); the Smokehouse's and the flue's are TP Core's (TPC.kit). TPFM.kit() lists the kinds")
    say("TPFM.animals()             live animals and carcasses within 6 tiles: weight, and the blood each gives (3.5 cl a kg)")
    say("TPFM.blood(hours)          the blood you carry: state, age, hours left at 20 C, place; with hours, ages it that much first")
    say("TPFM.pallet()              the Stockfish Pallet near you: its place, ripening speed, stack and fish")
    say("TPFM.rain(hours)           add this many hours of rain and wet the open frames, to test rain on open charque")
    say("TPFM.fatRows()             the fat each vanilla animal's butchering table gives now")
    say("TPFM.crocks()              each Crock of Potted Meat on you or within 4 tiles: place, keeping rate, days left")
    say("TPFM.keep(days)            age those crocks by this many days at their place's rate now")
    say("TPFM.smoke()               the joined Stone Hearth's fire record and each stack's hot and smoke hours, Smokehouses within 3 tiles")
    say("TPFM.stoke(hours)          add stoked hours to the running session of those joined Stone Hearths (stoke it first)")
    say("TPFM.bank(hours)           add banked hours (default 6) to those joined Stone Hearths: smoke, but only on a day of 15 C or less")
    say("TPFM.addSmoke(hours)       add hours of smoke (default 60) straight to the stacks in those Smokehouses, whatever the weather")
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
        .. ", charque " .. n(ledger.charqueRate) .. ", charque covered " .. n(ledger.charqueCoveredRate) .. ", charque indoors " .. n(ledger.charqueShelteredRate)
        .. "; Smokehouse banked " .. n(ledger.bankedRate) .. ", stoked " .. n(ledger.stokedRate)
        .. ", charque banked " .. n(ledger.charqueBankedRate) .. ", charque stoked " .. n(ledger.charqueStokedRate))
    say("Basement (" .. n(Weather.placeTemperature(ledger, "Basement")) .. " C): salt fish " .. n(ledger.basementShelteredRate)
        .. ", charque " .. n(ledger.charqueBasementRate) .. ", dry cure " .. n(ledger.dryCureBasementRate)
        .. "; a tub there: warm cure " .. tostring(ledger.basementWarmCuring == true) .. ", long cure " .. tostring(ledger.basementLongCuring == true))
    say("Loft (" .. n(Weather.placeTemperature(ledger, "Loft")) .. " C): salt fish " .. n(ledger.loftShelteredRate)
        .. ", charque " .. n(ledger.charqueLoftRate) .. ", dry cure " .. n(ledger.dryCureLoftRate)
        .. "; a tub there: warm cure " .. tostring(ledger.loftWarmCuring == true) .. ", long cure " .. tostring(ledger.loftLongCuring == true))
    say("Room (" .. n(Weather.placeTemperature(ledger, "Sheltered")) .. " C): salt fish " .. n(ledger.roomShelteredRate)
        .. ", charque " .. n(ledger.charqueRoomRate) .. ", dry cure " .. n(ledger.dryCureRoomRate)
        .. "; a tub there: warm cure " .. tostring(ledger.roomWarmCuring == true) .. ", long cure " .. tostring(ledger.roomLongCuring == true))
    say("Under a roof (" .. n(Weather.placeTemperature(ledger, "Covered")) .. " C): dry cure " .. n(ledger.dryCureCoveredRate)
        .. "; a tub in the open air (the day's): warm cure " .. tostring(ledger.openWarmCuring == true) .. ", long cure "
        .. tostring(ledger.openLongCuring == true) .. "; the Smokehouse's indoors figures above go by the day's temperature")
    say("Spoiling now: unsalted " .. tostring(ledger.rawSpoiling == true) .. ", salted " .. tostring(ledger.saltSpoiling == true)
        .. ", warm cure " .. tostring(ledger.warmCuring == true) .. ", hot sun " .. tostring((ledger.temperature or 0) > F.HEAT_ABOVE))
    say("Totals (hours at full speed): open " .. n(ledger.open) .. ", covered " .. n(ledger.covered) .. ", indoors " .. n(ledger.sheltered)
        .. ", cold " .. n(ledger.cold) .. ", cold covered " .. n(ledger.coldCovered)
        .. ", raw spoil " .. n(ledger.rawSpoil) .. ", salt spoil " .. n(ledger.saltSpoil)
        .. ", hard frost " .. n(ledger.hardFrost) .. ", cold fish wet " .. n(ledger.coldWet) .. ", warm cure " .. n(ledger.warmCure)
        .. ", hot sun " .. n(ledger.heat) .. ", charque " .. n(ledger.charque) .. ", charque covered " .. n(ledger.charqueCovered)
        .. ", charque indoors " .. n(ledger.charqueSheltered) .. ", rain " .. n(ledger.charqueRain)
        .. ", Smokehouse banked " .. n(ledger.smokeBanked) .. ", stoked " .. n(ledger.smokeStoked)
        .. ", charque banked " .. n(ledger.charqueBanked) .. ", charque stoked " .. n(ledger.charqueStoked))
    say(string.format("A stack needs %d hours to salt dry, %d to cold dry and %d to dry as charque.", F.DRY_HOURS, F.COLD_DRY_HOURS, F.CHARQUE_HOURS))
end

-- Wind probe for the cold-drying wind curve: live wind every 10 minutes against the day's forecast.
local windLog
function TPFM.here()
    say("You're in: " .. tostring(Weather.placeOf(getPlayer())))
end

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
    ledger.smokeBanked, ledger.smokeStoked = ledger.smokeBanked + hours, ledger.smokeStoked + hours
    ledger.charqueBanked, ledger.charqueStoked = ledger.charqueBanked + hours, ledger.charqueStoked + hours
    ledger.dryCure, ledger.dryCureBanked, ledger.dryCureStoked = ledger.dryCure + hours, ledger.dryCureBanked + hours, ledger.dryCureStoked + hours
    -- Perfect dry-curing weather is a shed at 12 C: Corned meat hanging in a Smokehouse spoils as it would there.
    local under = hours * F.underCureRate(F.DRY_CURE_FULL_HEAT)
    ledger.underCure, ledger.underCureBanked, ledger.underCureStoked = ledger.underCure + under, ledger.underCureBanked + under, ledger.underCureStoked + under
    ledger.dryCureBasement, ledger.underCureBasement = (ledger.dryCureBasement or 0) + hours, (ledger.underCureBasement or 0) + under
    ledger.basementSheltered, ledger.charqueBasement = (ledger.basementSheltered or 0) + hours, (ledger.charqueBasement or 0) + hours
    ledger.dryCureLoft, ledger.underCureLoft = (ledger.dryCureLoft or 0) + hours, (ledger.underCureLoft or 0) + under
    ledger.loftSheltered, ledger.charqueLoft = (ledger.loftSheltered or 0) + hours, (ledger.charqueLoft or 0) + hours
    ledger.dryCureRoom, ledger.underCureRoom = (ledger.dryCureRoom or 0) + hours, (ledger.underCureRoom or 0) + under
    ledger.roomSheltered, ledger.charqueRoom = (ledger.roomSheltered or 0) + hours, (ledger.charqueRoom or 0) + hours
    ledger.dryCureCovered, ledger.underCureCovered = (ledger.dryCureCovered or 0) + hours, (ledger.underCureCovered or 0) + under
    say(string.format("Added %.0f hours of perfect drying weather. Stacks update within a few seconds. Corned meat in a Smokehouse spoiled %.0f%% (a 12 C shed).", hours, under * 100))
end

function TPFM.spoil(hours)
    hours = hours or 24
    local ledger = F.getLedger()
    ledger.rawSpoil, ledger.saltSpoil = ledger.rawSpoil + hours, ledger.saltSpoil + hours
    ledger.rawSpoilOpen = (ledger.rawSpoilOpen or 0) + hours
    for _, place in ipairs({ "Room", "Loft", "Basement" }) do ledger["saltSpoil" .. place] = (ledger["saltSpoil" .. place] or 0) + hours end
    say(string.format("Added %.0f hours of spoiling weather. A fresh cold stack rots after %d.", hours, F.RAW_SPOIL_HOURS))
end

-- Hours of a 10 C shed for under-salted (Corned) meat hanging in a Smokehouse, a room or under a roof: rotten after
-- F.UNDER_CURE_HOURS.
function TPFM.underSalt(hours)
    hours = hours or 168
    local ledger = F.getLedger()
    local share = hours / F.UNDER_CURE_HOURS
    ledger.underCure, ledger.underCureBanked, ledger.underCureStoked = ledger.underCure + share, ledger.underCureBanked + share, ledger.underCureStoked + share
    ledger.underCureRoom, ledger.underCureCovered = (ledger.underCureRoom or 0) + share, (ledger.underCureCovered or 0) + share
    say(string.format("Added %.0f hours at 10 C for Corned meat in the Smokehouse, a room or under a roof. It rots after %.0f.", hours, F.UNDER_CURE_HOURS))
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
    ledger.warmCureRoom = (ledger.warmCureRoom or 0) + hours * 1.5
    ledger.warmCureOpen = (ledger.warmCureOpen or 0) + hours * 1.5
    say(string.format("Added %.0f hours of a warm cure at 25 C: about %.0f%% off a batch in a tub above ground or in a room (a basement or loft tub goes by its own).",
        hours, hours * 1.5 * F.WARM_CURE_SHARE / F.RAW_SPOIL_HOURS * 100))
end

-- Ripeness runs on the fish's own food clock, so this ages the fish themselves.
-- Hours of a 15 C season for a running Country Cure: a leg's 504 hours of it are a rotten batch.
function TPFM.longCure(hours)
    hours = hours or 168
    local ledger = F.getLedger()
    ledger.longCureSpoil = (ledger.longCureSpoil or 0) + hours / F.LONG_CURE_ROT_HOURS
    ledger.longCureRoom = (ledger.longCureRoom or 0) + hours / F.LONG_CURE_ROT_HOURS
    ledger.longCureOpen = (ledger.longCureOpen or 0) + hours / F.LONG_CURE_ROT_HOURS
    say(string.format("Added %.0f hours of a 15 C season to running Country Cures above ground and in a room: %.0f%% spoiled (a basement or loft tub goes by its own).", hours, hours / F.LONG_CURE_ROT_HOURS * 100))
end

function TPFM.mature(days)
    days = days or 10
    local fish = getPlayer():getInventory():getAllTypeRecurse("TraditionalPreservationFishMeat.ColdDriedFish")
    for i = 0, fish:size() - 1 do
        local item = fish:get(i)
        item:setAge(item:getAge() + days)
        F.rename(item)
    end
    say(string.format("Aged %d Cold Dried fish by %d days. Ripe after %d.", fish:size(), days, F.MATURE_DAYS))
    local meat = 0
    for _, fullType in ipairs({ F.DRY_CURED, F.COUNTRY_HAM }) do
        local items = getPlayer():getInventory():getAllTypeRecurse(fullType)
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            item:setAge(item:getAge() + days)
            F.rename(item)
        end
        meat = meat + items:size()
    end
    say(string.format("Aged %d dry cured pieces by %d days. A cut is Aged after %d, a Country Ham after %d.", meat, days, F.AGE_CUT_DAYS, F.AGE_HAM_DAYS))
end

-- The numbers the game's tooltip rounds or hides, for every stage item in the main inventory.
function TPFM.food()
    local inventory = getPlayer():getInventory()
    local count = 0
    for fullType in pairs(F.STAGES) do
        local items = inventory:getAllTypeRecurse(fullType)
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local ageing = F.ageDays(item) and string.format(", aged %.0f%%", F.agedness(item) * 100) or ""
            say(string.format("%s: hunger %.1f, unhappiness %.1f, boredom %.1f, thirst %.1f, weight %.2f, age %.1f of %d / %d days%s",
                item:getDisplayName(), item:getHungChange() * 100, item:getUnhappyChange(), item:getBoredomChange(),
                item:getThirstChange() * 100, item:getActualWeight(), item:getAge(), item:getOffAge(), item:getOffAgeMax(), ageing))
            count = count + 1
        end
    end
    if count == 0 then say("No cured fish or meat on you.") end
end

function TPFM.dry()
    local ledger = F.getLedger()
    ledger.wetness, ledger.coldWetness = 0, 0
    say("Wetness cleared.")
end

-- Scales a spawned fish to a weight, its food with it, as a caught fish's is.
local function setWeight(fish, weight)
    if not weight or fish:getActualWeight() <= 0 then return end
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

local function shortName(fullType)
    return (fullType:gsub("^.*%.", ""))
end

-- The full types a spawn command's name stands for: one of the list by its short name, or all of it.
local function named(list, name)
    if name == "all" then return list end
    for _, fullType in ipairs(list) do
        if shortName(fullType) == name then return { fullType } end
    end
    return nil
end

local function listNames(label, list, stages)
    local names = {}
    for _, fullType in ipairs(list) do table.insert(names, shortName(fullType)) end
    say(label .. ": " .. table.concat(names, ", ") .. ", or \"all\". Stages: " .. stages)
end

-- A fish packed and cured as the tub would: "Walleye (Salt Cured)".
local function curedFish(fullType, weight)
    local raw, packed, cured = instanceItem(fullType), instanceItem(F.PACKED_FISH), instanceItem("TraditionalPreservationFishMeat.SaltPressedFish")
    setWeight(raw, weight)
    F.carry(raw, packed)
    F.carry(packed, cured)
    return cured
end

-- A fish as a stage gives it: whole, "cured", then as the stations give a cured one with nothing spoiled: "dried"
-- (Salt Dried), "hotSmoked", "coldSmoked"; or "stockfish" (young, fresh off the frame).
local FISH_STAGES = {
    cured = function(inventory, fullType, weight) inventory:AddItem(curedFish(fullType, weight)) end,
    dried = function(inventory, fullType, weight)
        local dried = instanceItem("TraditionalPreservationFishMeat.SaltDriedFish")
        F.carry(curedFish(fullType, weight), dried)
        inventory:AddItem(dried)
    end,
    hotSmoked = function(inventory, fullType, weight)
        inventory:AddItem(F.smokedItem(curedFish(fullType, weight), {}, F.HOT_FISH, F.HOT_MEAT))
    end,
    coldSmoked = function(inventory, fullType, weight)
        inventory:AddItem(F.smokedItem(curedFish(fullType, weight), {}, F.COLD_FISH_OUT, F.DRY_CURED))
    end,
    stockfish = function(inventory, fullType)
        local fish = inventory:AddItem("TraditionalPreservationFishMeat.ColdDriedFish")
        fish:getModData().fishName = shortName(fullType)
        fish:getModData().matureAge = fish:getAge()
        F.rename(fish)
    end,
}

-- The third argument may be the stage, for a fish at its own weight: TPFM.fish("Walleye", 3, "cured").
function TPFM.fish(name, count, weight, stage)
    if type(weight) == "string" then weight, stage = nil, weight end
    local types = name and named(F.FISH_ICONS, name)
    if not types or stage and not FISH_STAGES[stage] then return listNames("Fish", F.FISH_ICONS, "\"cured\", \"dried\", \"hotSmoked\", \"coldSmoked\", \"stockfish\"") end
    local inventory = getPlayer():getInventory()
    for _, fullType in ipairs(types) do
        for _ = 1, count or 1 do
            if stage then
                FISH_STAGES[stage](inventory, fullType, weight)
            else
                setWeight(inventory:AddItem(fullType), weight)
            end
        end
    end
    say(string.format("Gave %d %s%s%s.", count or 1, name == "all" and "of each fish" or name,
        weight and (" at weight " .. weight) or "", stage and (", " .. stage) or ""))
end

-- A cut as a stage gives it: raw, "corned" (the short cure: "Steak (Corned)"), "country" (the long cure: "Steak
-- (Country Cured)"), "charque" (a Corned cut dried on a frame; no pork, which never hangs in the open), "hotSmoked"
-- (a Corned cut from a stoked Smokehouse; pork comes out as vanilla's Ham) or "dryCured" (as the Smokehouse gives it
-- after the long cure and its smoke, young: "Beef (Cold Smoked)"). Poultry and rabbit take "corned" and
-- "hotSmoked" only, as in the game.
local function curedCut(cut, long)
    local cured = instanceItem(F.CURED_MEAT)
    cured:getModData().longCure = long or nil
    F.carry(instanceItem(cut), cured)
    if F.isHotOnly(cured) then
        cured:setOffAge(F.HOT_ONLY_DAYS[1])
        cured:setOffAgeMax(F.HOT_ONLY_DAYS[2])
    end
    return cured
end

local function hotOnlyCut(cut)
    return F.isHotOnly({ getFullType = function() return cut end })
end

local MEAT_SPAWNS = {
    -- The short cure refuses a leg, so there is no Leg of Pork (Corned).
    corned = function(inventory, cut) if cut ~= F.LEG_OF_PORK then inventory:AddItem(curedCut(cut, false)) end end,
    country = function(inventory, cut) if not hotOnlyCut(cut) then inventory:AddItem(curedCut(cut, true)) end end,
    charque = function(inventory, cut)
        local corned = curedCut(cut, false)
        if F.isPork(corned) or F.isHotOnly(corned) then return end
        local charque = instanceItem("TraditionalPreservationFishMeat.Charque")
        F.carry(corned, charque)
        inventory:AddItem(charque)
    end,
    -- A leg never hot smokes.
    hotSmoked = function(inventory, cut)
        if cut ~= F.LEG_OF_PORK then inventory:AddItem(F.smokedItem(curedCut(cut, false), {}, F.HOT_FISH, F.HOT_MEAT)) end
    end,
    dryCured = function(inventory, cut)
        if hotOnlyCut(cut) then return end
        inventory:AddItem(F.smokedItem(curedCut(cut, true), {}, F.COLD_FISH_OUT, F.DRY_CURED, false))
    end,
}

function TPFM.meat(name, count, stage)
    local types = name and named(F.MEAT_CUTS, name)
    if not types or stage and not MEAT_SPAWNS[stage] then
        return listNames("Meat", F.MEAT_CUTS, "\"corned\", \"country\", \"charque\", \"hotSmoked\", \"dryCured\" (poultry and rabbit: corned and hotSmoked only)")
    end
    local inventory = getPlayer():getInventory()
    for _, cut in ipairs(types) do
        for _ = 1, count or 1 do
            if not stage then inventory:AddItem(cut) else MEAT_SPAWNS[stage](inventory, cut) end
        end
    end
    say(string.format("Gave %d %s%s.", count or 1, name == "all" and "of each cut" or name, stage and (", " .. stage) or ""))
end

-- The other things a test wants, by name. option is the fat pot's state: "cooked" (the default), "burnt" or "raw".
local GIVES = {
    head = function(count) give("TraditionalPreservationFishMeat.FishHead", count) end,
    stock = function(count) give("TraditionalPreservationFishMeat.PotOfFishHeadStock", count) end,
    boneBroth = function(count) give("TraditionalPreservationFishMeat.PotOfBoneBroth", count) end,
    chickenStock = function(count) give("TraditionalPreservationFishMeat.PotOfChickenStock", count) end,
    soups = function(count)
        for _, kind in ipairs({ "FishHead", "BoneBroth", "Chicken" }) do
            for _, dish in ipairs({ "Soup", "Stew" }) do give("TraditionalPreservationFishMeat.PotOf" .. kind .. dish, count) end
        end
    end,
    salt = function(count) give("Base.Salt", count) end,
    fat = function(count) for _, row in ipairs(F.FAT_ROWS) do give(row.item, count) end end,
    fatPot = function(count, state)
        for _, pot in ipairs(give("TraditionalPreservationFishMeat.PotOfPorkFat", count)) do
            if state == "burnt" then pot:setBurnt(true) elseif state ~= "raw" then pot:setCooked(true) end
        end
    end,
    crock = function(count)
        local batch = F.newPottedBatch(nil)
        for _ = 1, F.POTTED_MAX do F.addPottedCut(batch, instanceItem("Base.Steak")) end
        for _, crock in ipairs(give(F.CROCK, count)) do F.fillCrock(crock, batch, "Base.ClayJarGlazed") end
    end,
}
GIVES.blood = function(count, state)
    local states = { cured = { "Cured" } }
    local now = getGameTime():getWorldAgeHours()
    for _, bucket in ipairs(give("Base.Bucket", count)) do
        bucket:getFluidContainer():addFluid(FluidType.AnimalBlood, 4)
        FluidAgeing.look(bucket, now)
        for _, treatment in ipairs(states[state] or {}) do FluidAgeing.treat(bucket, now, treatment) end
        local record = bucket:getModData()[FluidAgeing.KEY]
        if state == "spoiled" and record then
            record.age = F.BLOOD_SPOIL_HOURS
            FluidAgeing.apply(bucket:getFluidContainer(), record, F.BLOOD_SPEC)
        end
    end
end
GIVES.casings = function(count) give("TraditionalPreservationFishMeat.RawCasings", count) end
GIVES.saltedCasings = function(count) give("TraditionalPreservationFishMeat.SaltedCasings", count) end
GIVES.blackPudding = function(count) give("TraditionalPreservationFishMeat.BlackPudding", count) end
-- Boiled links, cooked as the pot gives them (the Smokehouse takes only cooked ones); "stale" a day short of a week.
GIVES.bloodSausage = function(count, state)
    for _, item in ipairs(give("TraditionalPreservationFishMeat.BloodSausage", count)) do
        item:setCooked(true)
        if state == "stale" then item:setAge(item:getOffAge() - 0.1) end
    end
end
GIVES.smokedBloodSausage = function(count)
    for _, item in ipairs(give("TraditionalPreservationFishMeat.SmokedBloodSausage", count)) do item:setCooked(true) end
end
-- Raw links (the Smokehouse takes only raw ones); "seasoned" with garlic, pepper and oregano (as TP Core's Season
-- menu puts them in, nothing taken), "stale" a tenth of a day from going off.
local function seasoned()
    return { bonus = 3 * F.SEASONING_UNHAPPY, boredom = 3 * F.SEASONING_BOREDOM, spices = { "Base.Garlic", "Base.Pepper", "Base.Oregano" } }
end
GIVES.freshSausage = function(count, state)
    for _, item in ipairs(give(F.FRESH_SAUSAGE, count)) do
        if state == "seasoned" then Season.apply(item, seasoned()) end
        if state == "stale" then item:setAge(item:getOffAge() - 0.1) end
    end
end
GIVES.smokedSausage = function(count, state)
    for _, item in ipairs(give(F.SMOKED_SAUSAGE, count)) do
        item:setCooked(true)
        if state == "seasoned" then Season.apply(item, seasoned()) end
    end
end
local GIVE_NAMES = "head, stock, boneBroth, chickenStock, soups (one of each stock's soup and stew), salt, fat (one of each raw fat), fatPot (option \"burnt\" or \"raw\"), crock, blood (a Bucket of 4 L; option \"cured\" or \"spoiled\"), casings, saltedCasings, blackPudding, bloodSausage (boiled; option \"stale\": 0.1 days from stale), smokedBloodSausage, freshSausage (raw; option \"seasoned\" or \"stale\"), smokedSausage (option \"seasoned\")"

function TPFM.give(name, count, option)
    if not GIVES[name] then return say("Things: " .. GIVE_NAMES) end
    GIVES[name](count or 1, option)
    say(string.format("Gave %d %s%s. Spawned food has the item's default values.", count or 1, name, option and (" (" .. option .. ")") or ""))
end

-- What a test of kind needs.
local KITS = {
    potted = { about = "2 Pots, 2 Lard, Salt, a Steak, Beef, Pork Chop and Pork, a Chicken leg, Turkey Legs, Turkey Wings and Rabbit Meat, and a Clay Jar, Glazed Clay Jar and Clay Pot, for Potted Meat",
        "Base.Pot", "Base.Pot", "Base.Lard", "Base.Lard", "Base.Salt", "Base.Steak", "Base.Beef", "Base.PorkChop",
        "Base.Pork", "Base.Chicken", "Base.TurkeyLegs", "Base.TurkeyWings", "Base.Rabbitmeat", "Base.ClayJar",
        "Base.ClayJarGlazed", "Base.ClayPot" },
    stock = { about = "what every stock takes: a Fish Head, 2 Animal Bones, a Large Animal Bone, 6 Small Animal Bones, 2 Chicken Feet, a hen's and a turkey's head, 5 Pots (fill them with 1.5 L of water) and 4 Bowls",
        "TraditionalPreservationFishMeat.FishHead",
        "Base.AnimalBone", "Base.AnimalBone", "Base.LargeAnimalBone", "Base.SmallAnimalBone", "Base.SmallAnimalBone",
        "Base.SmallAnimalBone", "Base.SmallAnimalBone", "Base.SmallAnimalBone", "Base.SmallAnimalBone", "Base.ChickenFoot",
        "Base.ChickenFoot", "Base.Chicken_Hen_Brown_Head", "Base.Turkey_Hen_Head", "Base.Pot", "Base.Pot", "Base.Pot", "Base.Pot", "Base.Pot", "Base.Bowl", "Base.Bowl", "Base.Bowl", "Base.Bowl" },
    poultry = { about = "a whole Chicken and Turkey, a Chicken leg, Wing and Fillet, Turkey Legs, Wings and Fillet, Rabbit Meat, a Steak, 2 Salt and a Kitchen Knife, for hot smoked poultry (TPFM.meat(\"ChickenWhole\", 1, \"hotSmoked\") to carve at once)",
        "Base.ChickenWhole", "Base.TurkeyWhole", "Base.Chicken", "Base.ChickenWings", "Base.ChickenFillet", "Base.TurkeyLegs",
        "Base.TurkeyWings", "Base.TurkeyFillet", "Base.Rabbitmeat", "Base.Steak", "Base.Salt", "Base.Salt",
        "Base.KitchenKnife" },
    blood = { about = "a Bucket of 4 L of fresh blood, an Empty Jar, a Baking Pan, a Pot, every filler (Oats, Rice, 12 grains each of Barley, Rye and Wheat), Lard, Pork Fat, 4 Salt, Vinegar, Raw Casings, Salted Casings and a Kitchen Knife, for black pudding and blood sausage (fill the Pot with 1.5 L of water); 6 boiled Blood Sausages for the Smokehouse and a Smoked Blood Sausage",
        counts = { ["Base.BarleySeed"] = 12, ["Base.RyeSeed"] = 12, ["Base.WheatSeed"] = 12 },
        "Base.EmptyJar", "Base.BakingPan", "Base.Pot", "Base.OatsRaw", "Base.Rice", "Base.Lard",
        "TraditionalPreservationFishMeat.PorkFat", "Base.Salt", "Base.Salt", "Base.Salt", "Base.Salt", "Base.Vinegar2",
        "TraditionalPreservationFishMeat.RawCasings", "TraditionalPreservationFishMeat.SaltedCasings", "Base.KitchenKnife",
        give = { blood = 1, bloodSausage = 6, smokedBloodSausage = 1 } },
    sausage = { about = "2 Pork, a Pork Chop, Beef, Venison, Pork Fat, Lard, 2 Salt, Garlic, Onion, Pepper, Oregano, Thyme, Sage (to season links), 2 Salted Casings, a Pot and a Kitchen Knife, for Smoked Sausage (fill the Pot with 1.5 L of water); 6 raw Fresh Sausages for the Smokehouse and a seasoned Smoked Sausage",
        "Base.Pork", "Base.Pork", "Base.PorkChop", "Base.Beef", "Base.Venison", "TraditionalPreservationFishMeat.PorkFat",
        "Base.Lard", "Base.Salt", "Base.Salt", "Base.Garlic", "Base.Onion", "Base.Pepper", "Base.Oregano", "Base.Thyme", "Base.Sage",
        "TraditionalPreservationFishMeat.SaltedCasings", "TraditionalPreservationFishMeat.SaltedCasings", "Base.Pot",
        "Base.KitchenKnife",
        give = { freshSausage = 6 }, giveOptions = { smokedSausage = "seasoned" } },
}

function TPFM.kit(kind)
    local kit = KITS[kind]
    if not kit then
        for name, entry in pairs(KITS) do say("TPFM.kit(\"" .. name .. "\"): " .. entry.about) end
        return
    end
    for _, fullType in ipairs(kit) do give(fullType) end
    for fullType, count in pairs(kit.counts or {}) do give(fullType, count) end
    for name, count in pairs(kit.give or {}) do GIVES[name](count) end
    for name, option in pairs(kit.giveOptions or {}) do GIVES[name](1, option) end
    say("Gave " .. kit.about .. ".")
end

-- Animals within ANIMAL_REACH tiles: a live one's weight and the blood it would give (the game's own sum), and a
-- carcass's blood left. The game's Animal Info window shows no weight.
local ANIMAL_REACH = 6
function TPFM.animals()
    local square, cell, found = getPlayer():getSquare(), getCell(), 0
    for dx = -ANIMAL_REACH, ANIMAL_REACH do
        for dy = -ANIMAL_REACH, ANIMAL_REACH do
            local there = cell:getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            local animals = there and there:getAnimals()
            for i = 0, animals and animals:size() - 1 or -1 do
                local animal = animals:get(i)
                local weight = animal:getData():getWeight()
                say(string.format("%s (%s): %.0f kg, blood %.2f L (%.1f cl a kg)", animal:getFullName(), animal:getAnimalType(),
                    weight, animal:getBloodQuantity(), weight > 0 and animal:getBloodQuantity() * 100 / weight or 0))
                found = found + 1
            end
            local bodies = there and there:getDeadBodys()
            for i = 0, bodies and bodies:size() - 1 or -1 do
                local data = bodies:get(i):getModData()
                if data.AnimalType then
                    say(string.format("Carcass of a %s: %.2f L of blood left", tostring(data.AnimalType), tonumber(data.BloodQty) or 0))
                    found = found + 1
                end
            end
        end
    end
    if found == 0 then say("No animal or carcass within " .. ANIMAL_REACH .. " tiles.") end
end

-- The blood the player carries (bags included): its fluid, treatments, age against its spoiling, and place. With
-- hours, each record is first aged that many hours at the reference (20 C).
function TPFM.blood(hours)
    local now = getGameTime():getWorldAgeHours()
    local items = getPlayer():getInventory():getAllEvalRecurse(function(item)
        local usable, spoiled = F.bloodIn(item)
        return usable + spoiled > 0
    end)
    if items:size() == 0 then return say("You carry no blood.") end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local record, spec = FluidAgeing.look(item, now)
        if record and hours then
            record.age = record.age + hours
            FluidAgeing.apply(item:getFluidContainer(), record, spec)
        end
        if not record then
            say(item:getDisplayName() .. ": no record (blood ageing off?)")
        else
            local state = FluidAgeing.state(record, spec)
            local left = FluidAgeing.hoursLeft(record, spec)
            say(string.format("%s: %.2f L, %s, %s, age %.1f h, %s, in %s", item:getDisplayName(),
                item:getFluidContainer():getAmount(), item:getFluidContainer():getUiName(), state and state.name or "untreated",
                record.age, left and string.format("spoils in %.1f h at 20 C", left) or "spoiled", tostring(record.place)))
        end
    end
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

function TPFM.pallet()
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
                    local place = Weather.placeOf(object)
                    local count, ripest = 0, 0
                    F.eachStockfish(object:getContainer(), function(fish)
                        count = count + 1
                        ripest = math.max(ripest, F.ripeness(fish))
                    end)
                    say(string.format("Pallet at %d,%d floor %d: %s, ripens x%.1f (%d days to ripe). Stack: %s. %d stockfish, ripest %.0f%%.",
                        x, y, z, place, F.palletSpeed(place), F.MATURE_DAYS / F.palletSpeed(place),
                        tostring(F.palletLevel(object:getContainer()) or "none"), count, ripest * 100))
                    return
                end
            end
        end
    end
    say("No Stockfish Pallet within 3 tiles on this floor.")
end

-- The chamber tiles holding slots within 3 tiles, each with its joined Firebox (or nil).
local function smokehouses()
    local player, found = getPlayer(), {}
    local cell, x, y, z = getCell(), math.floor(player:getX()), math.floor(player:getY()), player:getZ()
    for dx = -3, 3 do
        for dy = -3, 3 do
            local tile = Smokehouse.chamberOn(cell:getGridSquare(x + dx, y + dy, z))
            if tile and tile:getComponent(ComponentType.DryingCraftLogic) then
                table.insert(found, { tile = tile, firebox = Smokehouse.joinedFirebox(tile) })
            end
        end
    end
    return found
end

function TPFM.smoke()
    local Hearth = require "TraditionalPreservationCore/Hearth"
    local found = smokehouses()
    for _, shed in ipairs(found) do
        local fire = shed.firebox and Hearth.stateOf(shed.firebox:getModData())
        say(string.format("Smokehouse at %d,%d: %s", shed.tile:getX(), shed.tile:getY(), fire and string.format(
            "fire %s, stoked %.1f h, banked %.1f h, session %s (%.1f h)", tostring(fire.fireMode), fire.stokedHours or 0,
            fire.bankedHours or 0, fire.session and string.format("%.2f", fire.session) or "none", Hearth.sessionHours(fire))
            or "no Stone Hearth joined"))
        local logic = shed.tile:getComponent(ComponentType.DryingCraftLogic)
        local items = CraftLogicUILogic.new(getPlayer(), shed.tile, logic):getItemsInProgress()
        for craftData, _ in pairs(items) do
            local modData = craftData:getModData()
            say(string.format("  stack %s (heaviest piece %.2f): hot %.1f of %s h, smoke %.1f of %.1f h%s, dried %.0f h%s", tostring(modData.stackId), modData.heaviest or 0, modData.hot or 0,
                modData.hotNeed and string.format("%.0f", modData.hotNeed) or "-", modData.cold or 0, F.coldNeed(modData),
                F.coldDone(modData) and " (Cold Smoked)" or "", modData.dried or 0,
                F.hotStations[modData.stackId] and ", cook done" or ""))
            if modData.sausage then
                local now = getGameTime():getWorldAgeHours()
                say(string.format("    %s: %s, the freshest link stale in %.1f h",
                    modData.sausage == "pork" and "fresh sausage (hot run)" or "blood sausage", modData.smokedAt
                    and string.format("smoked %.1f h ago", now - modData.smokedAt) or "not smoked yet",
                    (modData.staleAt or now) - now))
            end
            if modData.cureNeed then
                say(string.format("    meat: dry curing needs %.0f h%s%s", modData.cureNeed, modData.noHot and ", a leg: no hot cook" or "",
                    modData.underCured and string.format(", under-salted, %.0f%% spoiled", (modData.underSpoiled or 0) * 100) or ""))
            end
        end
    end
    if #found == 0 then say("No Smokehouse within 3 tiles on this floor.") end
end

function TPFM.stoke(hours)
    local Hearth = require "TraditionalPreservationCore/Hearth"
    for _, shed in ipairs(smokehouses()) do
        local fire = shed.firebox and Hearth.stateOf(shed.firebox:getModData())
        if fire and fire.session then
            fire.stokedHours = (fire.stokedHours or 0) + (hours or 1)
            say(string.format("Session now %.1f h", Hearth.sessionHours(fire)))
        else
            say("No stoked session running: join a Stone Hearth and stoke it first.")
        end
    end
end

-- Adds banked hours (default 6) to the joined Fireboxes' record, as if they had smouldered that long.
function TPFM.bank(hours)
    local Hearth = require "TraditionalPreservationCore/Hearth"
    for _, shed in ipairs(smokehouses()) do
        local fire = shed.firebox and Hearth.stateOf(shed.firebox:getModData())
        if fire then
            fire.bankedHours = (fire.bankedHours or 0) + (hours or 6)
            say(string.format("Added %.0f banked hours (the fire's record is now %.1f h in all).", hours or 6, fire.bankedHours))
            local outdoors = F.getLedger().temperature or 0
            if outdoors > F.COLD_SMOKE_MAX then
                say(string.format("It is %.0f C outdoors: over %d C banked hours don't count as smoke. TPFM.addSmoke(hours) gives the stacks smoke whatever the weather.",
                    outdoors, F.COLD_SMOKE_MAX))
            end
        else
            say("No Stone Hearth joined to this Smokehouse.")
        end
    end
end

-- Adds hours of smoke (default 60) straight to every stack in those Smokehouses, whatever the weather or the fire.
function TPFM.addSmoke(hours)
    hours = hours or 60
    local stacks = 0
    for _, shed in ipairs(smokehouses()) do
        local logic = shed.tile:getComponent(ComponentType.DryingCraftLogic)
        for craftData, _ in pairs(CraftLogicUILogic.new(getPlayer(), shed.tile, logic):getItemsInProgress()) do
            local modData = craftData:getModData()
            modData.cold = (modData.cold or 0) + hours
            stacks = stacks + 1
            say(string.format("Stack %s: %.0f of %.0f h of smoke.", tostring(modData.stackId), modData.cold, F.coldNeed(modData)))
        end
    end
    if stacks == 0 then say("No stack hanging in a Smokehouse within 3 tiles.") end
end

say("Debug commands loaded. Type TPFM.help() in the Lua console.")
