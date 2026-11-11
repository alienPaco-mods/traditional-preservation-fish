-- Phase 3a: how Charque (tub-salted beef) would dry on the frame through the year, before any constant goes into the mod.
-- Run from the mod folder: luajit tools/charque_report.lua [path/to/climate.csv] [path/to/wind.csv]
-- Same weather as tools/season_report.lua (its forecasts, rain hours and wind factors); the curve below is a draft.
dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua").useModPaths()
ModData = { getOrCreate = function() return {} end }
Events = { OnInitGlobalModData = { Add = function() end } }
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
local T = TraditionalPreservationFishMeat

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local RAIN_HOURS = 6
local DRY_WIND, WET_WIND = 0.65, 1.3

-- Draft constants.
local B = {
    HOURS = 120,          -- hours at full rate: 5 days of hot sun in a good breeze (user, 2026-11-11)
    WARM_FROM = 0,        -- no drying at or below this
    WARM_FULL = 25,       -- full rate from here up: charque is dried in the summer sun
    CALM = 0.65, WINDY = 1.2, WIND_GOOD = 0.25,  -- still air dries as indoors; breeze as stockfish
    COVERED_WIND = 1,     -- shade and no rain, as salt fish
    INDOORS = 0.65,       -- still air, windows open (salt fish's SHELTERED_RATE), no wind term
    REWET = 0.1,          -- share of progress a rainy day (RAIN_HOURS of rain) takes back on an open frame
    -- Heavy salt: only salt fish's rule (hot and muggy season, T.SALT_SPOIL_ABOVE / _HUMIDITY / _HOURS), no heat damage.
}

local function warmRate(celsius)
    if celsius <= B.WARM_FROM then return 0 end
    return math.min((celsius - B.WARM_FROM) / (B.WARM_FULL - B.WARM_FROM), 1)
end

local function windRate(wind)
    if not wind then return 1 end
    return B.CALM + math.min(math.max(wind, 0) / B.WIND_GOOD, 1) * (B.WINDY - B.CALM)
end

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
        if offset >= 0 then
            worlds[world] = worlds[world] or {}
            table.insert(worlds[world], { month = month, min = tonumber(f[4]), max = tonumber(f[6]), humidity = tonumber(f[8]),
                rainy = f[10] == "true", wind = wind[month .. " " .. offset] })
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

-- One stack, hour by hour from start. Returns days to finish (nil if the data ran out), spoilage, and progress lost to rain.
local function runStack(start, hours, place)
    local dried, spoiled, lost = 0, 0, 0
    local index = start
    while hours[index + 1] do
        index = index + 1
        local h = hours[index]
        local rate = warmRate(h.temperature) * T.airRate(h.humidity)
        if place == "indoors" then
            rate = rate * B.INDOORS
        else
            rate = rate * windRate(h.wind) * (place == "covered" and B.COVERED_WIND or 1)
        end
        if place == "open" and h.wetness > 0 then
            if h.raining then
                local back = dried * B.REWET / RAIN_HOURS
                dried, lost = dried - back, lost + back
            end
            rate = 0
        end
        if h.saltSpoiling then spoiled = spoiled + 1 / T.SALT_SPOIL_HOURS end
        dried = dried + rate
        if spoiled >= 1 then return (index - start) / 24, 1, lost end
        if dried >= B.HOURS then return (index - start) / 24, spoiled, lost end
    end
    return nil
end

local function report(worlds)
    print(string.format("HOURS %d, full rate from %d C, salt fish's spoilage rule, rain takes back %d%% a wet day",
        B.HOURS, B.WARM_FULL, B.REWET * 100))
    print("month  temp  season  rainy | days open / covered / indoors | rotted% open/covered | kept-life lost open/covered | rain took back")
    local rows = {}
    for _, days in pairs(worlds) do
        local ledger = T.newLedger(0)
        local hours = {}
        for index, day in ipairs(days) do
            for hour = 0, 23 do
                local now = (index - 1) * 24 + hour + 1
                local weather = weatherAt(day, hour)
                T.advance(ledger, now, weather)
                hours[now] = { temperature = weather.temperature, humidity = weather.humidity, wind = weather.wind,
                    raining = weather.precipitation > 0 and not weather.isSnow, wetness = ledger.wetness, season = ledger.seasonTemperature,
                    saltSpoiling = ledger.saltSpoiling }
            end
        end
        for index, day in ipairs(days) do
            local row = rows[day.month] or { n = 0, t = 0, s = 0, rain = 0, open = {}, covered = {}, indoors = {},
                rotO = 0, rotC = 0, lostO = 0, lostC = 0, nO = 0, nC = 0, back = 0 }
            rows[day.month] = row
            local start = (index - 1) * 24 + 1
            row.n, row.t, row.rain = row.n + 1, row.t + (day.min + day.max) / 2, row.rain + (day.rainy and 1 or 0)
            row.s = row.s + (hours[start].season or 0)
            local d, sp, back = runStack(start, hours, "open")
            if d then
                row.nO = row.nO + 1
                if sp >= 1 then row.rotO = row.rotO + 1 else table.insert(row.open, d); row.lostO = row.lostO + sp end
                row.back = row.back + back / B.HOURS
            end
            d, sp = runStack(start, hours, "covered")
            if d then
                row.nC = row.nC + 1
                if sp >= 1 then row.rotC = row.rotC + 1 else table.insert(row.covered, d); row.lostC = row.lostC + sp end
            end
            d, sp = runStack(start, hours, "indoors")
            if d and sp < 1 then table.insert(row.indoors, d) end
        end
    end
    local function span(list)
        if #list == 0 then return "-" end
        table.sort(list)
        return string.format("%.0f-%.0f", list[1], list[#list])
    end
    local function share(a, b) return b > 0 and a / b * 100 or 0 end
    for month = 1, 12 do
        local r = rows[month]
        if r then
            print(string.format("%-5s %5.1f %6.1f %5.0f%% | %6s / %-6s / %-6s | %4.0f%% / %3.0f%% | %4.0f%% / %3.0f%% | %4.0f%%",
                MONTHS[month], r.t / r.n, r.s / r.n, share(r.rain, r.n), span(r.open), span(r.covered), span(r.indoors),
                share(r.rotO, r.nO), share(r.rotC, r.nC), share(r.lostO, #r.open), share(r.lostC, #r.covered), share(r.back, r.nO)))
        end
    end
end

report(readDays(arg[1] or "tools/climate_year.csv", readWind(arg[2] or "tools/climate_wind.csv")))
