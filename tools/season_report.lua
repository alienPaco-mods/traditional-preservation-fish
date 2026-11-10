-- Shows how the frame behaves through the year, from forecasts read from the real game.
-- Run from the mod folder: luajit tools/season_report.lua [path/to/climate.csv]
-- Each line of the file: world month offset tempMin tempMean tempMax humMin humMean humMax rainy snowy
dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua").useModPaths()
ModData = { getOrCreate = function() return {} end }
Events = { OnInitGlobalModData = { Add = function() end } }
dofile("42/media/lua/shared/TraditionalPreservationFish.lua")
local T = TraditionalPreservationFish

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local RAIN_HOURS = 6

local function readDays(path)
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
            })
        end
    end
    return worlds
end

local function weatherAt(day, hour)
    local swing = math.cos((hour - 15) / 24 * 2 * math.pi)
    local temperature = (day.min + day.max) / 2 + (day.max - day.min) / 2 * swing
    local raining = day.rainy and hour >= 12 and hour < 12 + RAIN_HOURS
    return { temperature = temperature, humidity = day.humidity, precipitation = raining and 0.5 or 0, isSnow = temperature <= 0 }
end

-- Hangs a stack on the given day and runs it until it is done or rotted.
local function runStack(days, start, field, needed, spoilField, spoilHours, sheltered, snapshots)
    local first = snapshots[start]
    local dried, spoiled = 0, 0
    for index = start, #days * 24 do
        local now = snapshots[index]
        if not now then break end
        dried = now[field] - first[field]
        spoiled = (now[spoilField] - first[spoilField]) / spoilHours
        if spoiled >= 1 then return (index - start) / 24, spoiled end
        if dried >= needed then return (index - start) / 24, spoiled end
    end
    return nil
end

local function report(worlds)
    print("month  temp(mean) humidity(mean) rainy%  | salt days (open/roof) salt shelf-life lost | cold days, rotted%")
    local rows = {}
    for _, days in pairs(worlds) do
        local ledger = T.newLedger(0)
        local snapshots = {}
        for index, day in ipairs(days) do
            for hour = 0, 23 do
                local now = (index - 1) * 24 + hour + 1
                T.advance(ledger, now, weatherAt(day, hour))
                snapshots[now] = { open = ledger.open, sheltered = ledger.sheltered, cold = ledger.cold, rawSpoil = ledger.rawSpoil, saltSpoil = ledger.saltSpoil }
            end
        end
        for index, day in ipairs(days) do
            local row = rows[day.month] or { n = 0, t = 0, h = 0, rain = 0, open = {}, roof = {}, lost = 0, salts = 0, cold = {}, rotted = 0, stacks = 0 }
            rows[day.month] = row
            row.n, row.t, row.h = row.n + 1, row.t + (day.min + day.max) / 2, row.h + day.humidity
            row.rain = row.rain + (day.rainy and 1 or 0)
            local start = (index - 1) * 24 + 1
            local openDays, saltSpoiled = runStack(days, start, "open", T.DRY_HOURS, "saltSpoil", T.SALT_SPOIL_HOURS, false, snapshots)
            local roofDays = runStack(days, start, "sheltered", T.DRY_HOURS, "saltSpoil", T.SALT_SPOIL_HOURS, true, snapshots)
            if openDays then
                table.insert(row.open, openDays)
                row.lost, row.salts = row.lost + saltSpoiled, row.salts + 1
            end
            if roofDays then table.insert(row.roof, roofDays) end
            local coldDays, rawSpoiled = runStack(days, start, "cold", T.COLD_DRY_HOURS, "rawSpoil", T.RAW_SPOIL_HOURS, false, snapshots)
            if coldDays then
                row.stacks = row.stacks + 1
                if rawSpoiled >= 1 then row.rotted = row.rotted + 1 else table.insert(row.cold, coldDays) end
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
            print(string.format("%-5s %6.1f %8.2f %8.0f%%  | %7s / %-7s %5.0f%%  | %7s %5.0f%%", MONTHS[month], r.t / r.n, r.h / r.n, r.rain / r.n * 100,
                span(r.open), span(r.roof), r.salts > 0 and r.lost / r.salts * 100 or 0, span(r.cold), r.stacks > 0 and r.rotted / r.stacks * 100 or 0))
        end
    end
end

report(readDays(arg[1] or "tools/climate_year.csv"))
