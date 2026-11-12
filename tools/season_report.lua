-- Shows how the frame behaves through the year, from forecasts read from the real game.
-- Run from the mod folder: luajit tools/season_report.lua [path/to/climate.csv] [path/to/wind.csv]
-- Each line of the climate file: world month offset tempMin tempMean tempMax humMin humMean humMax rainy snowy
-- The wind file (tools/climate_wind.csv) gives each day's forecast wind by month and offset. Forecast wind
-- is the base wind: live wind measured on 42.22 ran at about DRY_WIND of it in dry spells and WET_WIND in rain.
dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua").useModPaths()
ModData = { getOrCreate = function() return {} end }
Events = { OnInitGlobalModData = { Add = function() end } }
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
local T = TraditionalPreservationFishMeat

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local RAIN_HOURS = 6
local DRY_WIND, WET_WIND = 0.65, 1.3

local function readWind(path)
    local wind = {}
    for line in io.lines(path) do
        if not line:match("^#") then
            local f = {}
            for value in line:gmatch("%S+") do table.insert(f, value) end
            wind[f[1] .. " " .. f[2]] = tonumber(f[6])
        end
    end
    return wind
end

local function readDays(path, wind)
    local worlds = {}
    for line in io.lines(path) do
        local f = {}
        for value in line:gmatch("%S+") do table.insert(f, value) end
        local world, month, offset = tonumber(f[1]), tonumber(f[2]), tonumber(f[3])
        -- Only the first 30 days ahead of each month's start, so the months join up.
        if offset >= 0 then
            worlds[world] = worlds[world] or {}
            table.insert(worlds[world], {
                month = month, min = tonumber(f[4]), max = tonumber(f[6]), humidity = tonumber(f[8]), rainy = f[10] == "true",
                wind = wind[month .. " " .. offset],
            })
        end
    end
    return worlds
end

local function weatherAt(day, hour)
    local swing = math.cos((hour - 15) / 24 * 2 * math.pi)
    local temperature = (day.min + day.max) / 2 + (day.max - day.min) / 2 * swing
    local raining = day.rainy and hour >= 12 and hour < 12 + RAIN_HOURS
    local wind = day.wind and day.wind * (raining and WET_WIND or DRY_WIND)
    return { temperature = temperature, humidity = day.humidity, precipitation = raining and 0.5 or 0, isSnow = temperature <= 0, wind = wind }
end

-- Each stack goes through the mod's own step every hour, as its spoilage depends on how far it has dried.
-- place is nil (open), "covered" (a roof, no room), "sheltered" (a room, by Core's room temperature) or "loft" (the top
-- storey, by Core's loft temperature; a loft stack is sheltered too, as the World marks it).
local function runSaltStack(start, snapshots, place)
    local first = snapshots[start]
    local modData = { dried = 0, spoiled = 0, lastOpen = first.open, lastSheltered = first.sheltered, lastRoomSheltered = first.roomSheltered, lastCovered = first.covered,
        lastLoftSheltered = first.loftSheltered, lastSaltSpoil = first.saltSpoil, lastSaltSpoilRoom = first.saltSpoilRoom, lastSaltSpoilLoft = first.saltSpoilLoft,
        lastHeat = first.heat }
    if place then modData[place] = true end
    if place == "loft" then modData.sheltered = true end
    local index = start
    while snapshots[index + 1] do
        index = index + 1
        T.saltStep(modData, snapshots[index])
        if modData.spoiled >= 1 or modData.dried >= T.DRY_HOURS then return (index - start) / 24, modData.spoiled end
    end
    return nil
end

local function runColdStack(start, snapshots, place)
    local first = snapshots[start]
    local modData = { dried = 0, spoiled = 0, lastCold = first.cold, lastColdCovered = first.coldCovered, lastRawSpoil = first.rawSpoil, lastRawSpoilOpen = first.rawSpoilOpen,
        lastHardFrost = first.hardFrost, lastHardFrostCovered = first.hardFrostCovered, lastColdWet = first.coldWet }
    if place then modData[place] = true end
    local index = start
    while snapshots[index + 1] do
        index = index + 1
        T.coldStep(modData, snapshots[index])
        if modData.spoiled >= 1 or modData.dried >= T.COLD_DRY_HOURS then return (index - start) / 24, modData.spoiled end
    end
    return nil
end

local function report(worlds)
    print("month  temp(mean) humidity(mean) rainy%  | salt days (open/covered/indoors/loft) shelf-life lost (open/covered/loft) | cold days (open/covered), rotted%, shelf-life lost | 2-day press lost")
    local rows = {}
    for _, days in pairs(worlds) do
        local ledger = T.newLedger(0)
        local snapshots = {}
        for index, day in ipairs(days) do
            for hour = 0, 23 do
                local now = (index - 1) * 24 + hour + 1
                T.advance(ledger, now, weatherAt(day, hour))
                snapshots[now] = { open = ledger.open, sheltered = ledger.sheltered, roomSheltered = ledger.roomSheltered, covered = ledger.covered, cold = ledger.cold,
                    loftSheltered = ledger.loftSheltered, saltSpoilRoom = ledger.saltSpoilRoom, saltSpoilLoft = ledger.saltSpoilLoft,
                    coldCovered = ledger.coldCovered, rawSpoil = ledger.rawSpoil, rawSpoilOpen = ledger.rawSpoilOpen, saltSpoil = ledger.saltSpoil,
                    hardFrost = ledger.hardFrost, hardFrostCovered = ledger.hardFrostCovered, coldWet = ledger.coldWet, heat = ledger.heat, warmCure = ledger.warmCure }
            end
        end
        for index, day in ipairs(days) do
            local row = rows[day.month] or { n = 0, t = 0, h = 0, rain = 0, open = {}, covered = {}, roof = {}, loft = {}, loftLost = 0, lost = 0, coveredLost = 0, salts = 0,
                coveredSalts = 0, cold = {}, coldCovered = {}, rotted = 0, stacks = 0, coldLost = 0, cure = 0, cures = 0 }
            rows[day.month] = row
            row.n, row.t, row.h = row.n + 1, row.t + (day.min + day.max) / 2, row.h + day.humidity
            row.rain = row.rain + (day.rainy and 1 or 0)
            local start = (index - 1) * 24 + 1
            local openDays, saltSpoiled = runSaltStack(start, snapshots)
            local coveredDays, coveredSpoiled = runSaltStack(start, snapshots, "covered")
            local roofDays = runSaltStack(start, snapshots, "sheltered")
            if openDays then
                table.insert(row.open, openDays)
                row.lost, row.salts = row.lost + saltSpoiled, row.salts + 1
            end
            if coveredDays then
                table.insert(row.covered, coveredDays)
                row.coveredLost, row.coveredSalts = row.coveredLost + coveredSpoiled, row.coveredSalts + 1
            end
            if roofDays then table.insert(row.roof, roofDays) end
            local loftDays, loftSpoiled = runSaltStack(start, snapshots, "loft")
            if loftDays then
                table.insert(row.loft, loftDays)
                row.loftLost = row.loftLost + loftSpoiled
            end
            local pressEnd = snapshots[start + T.PRESS_HOURS]
            if pressEnd then
                row.cure, row.cures = row.cure + T.cureSpoiled({ lastWarmCure = snapshots[start].warmCure }, pressEnd), row.cures + 1
            end
            local shedDays, shedSpoiled = runColdStack(start, snapshots, "covered")
            if shedDays and shedSpoiled < 1 then table.insert(row.coldCovered, shedDays) end
            local coldDays, coldSpoiled = runColdStack(start, snapshots)
            if coldDays then
                row.stacks = row.stacks + 1
                if coldSpoiled >= 1 then
                    row.rotted = row.rotted + 1
                else
                    table.insert(row.cold, coldDays)
                    row.coldLost = row.coldLost + coldSpoiled
                end
            end
        end
    end

    local function span(list)
        if #list == 0 then return "-" end
        table.sort(list)
        return string.format("%.0f-%.0f", list[1], list[#list])
    end
    for month = 1, 12 do
        local r = rows[month]
        if r then
            local function share(total, count) return count > 0 and total / count * 100 or 0 end
            print(string.format("%-5s %6.1f %8.2f %8.0f%%  | %7s / %-7s / %-7s / %-7s %4.0f%% / %3.0f%% / %3.0f%%  | %7s / %-7s %5.0f%% %5.0f%%  | %4.0f%%", MONTHS[month],
                r.t / r.n, r.h / r.n, r.rain / r.n * 100, span(r.open), span(r.covered), span(r.roof), span(r.loft), share(r.lost, r.salts),
                share(r.coveredLost, r.coveredSalts), share(r.loftLost, #r.loft), span(r.cold), span(r.coldCovered), share(r.rotted, r.stacks), share(r.coldLost, #r.cold),
                share(r.cure, r.cures)))
        end
    end
end

report(readDays(arg[1] or "tools/climate_year.csv", readWind(arg[2] or "tools/climate_wind.csv")))
