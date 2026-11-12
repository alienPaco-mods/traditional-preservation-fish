-- How much a winter of cold drying (and a year of salt drying) puts by, against what a survivor eats.
-- Each station is kept full all season: a stack is rehung the day one comes down, and the days a stack
-- takes and its chance of rotting go by the month it was hung, from the season table in the README.
-- Run from the mod folder: luajit tools/storage_model.lua
local KCAL_PER_KG = 159 / 0.4 * 2.2   -- every vanilla species: 159 calories at weight 0.4, and 1 kg is 2.2 weight
local GUTTED_WEIGHT = 0.9             -- a salt packed fish weighs 90% of the fish
local HEADLESS_WEIGHT = 0.8           -- Gut Fish also takes the head (fish over 1.0 weight)
local COLD_KEEPS = 0.95 * 0.94        -- Cold Dried keeps 95% of the calories, after the head's 6%
local SALT_KEEPS = 0.90
local DAILY_KCAL = 2500               -- a working survivor
local FISH_SHARE = 1 / 3              -- fish as a third of the diet, the rest from farming, foraging and hunting

-- Days a stack takes and the chance it rots, by the month it is hung (README season table, middle of each range).
local COLD = { [10] = { 26, 0.30 }, [11] = { 22, 0 }, [12] = { 22, 0 }, [1] = { 22, 0 }, [2] = { 23, 0 }, [3] = { 30, 0.07 } }
local SALT_ROOF = { 27, 27, 27, 25.5, 23, 22, 22, 23, 25, 27, 27, 27 }
local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- Stacks a station holds and the inventory weight of gutted fish each takes.
local STATIONS = {
    { "Drying Frame (Carpentry 2)", 8, 2.5 },
    { "Hanging Beam (Carpentry 4)", 4, 15 },
    { "Gantry (Carpentry 6)", 2, 50 },
}

local function monthOf(day)
    local month = 1
    while day > MONTH_DAYS[month] do day, month = day - MONTH_DAYS[month], month % 12 + 1 end
    return month
end

-- Fresh kilos dried and kept in one season, hanging only in the given months. startDay counts from 1 January.
local function season(stacks, stackWeight, table, startDay, endDay, keeps, cutWeight)
    local freshKg = stackWeight / 2.2 / cutWeight
    local kept, hung = 0, 0
    for _ = 1, stacks do
        local day = startDay
        while day <= endDay do
            local month = monthOf((day - 1) % 365 + 1)
            local rule = table[month]
            if not rule then break end
            local takes, rots = rule[1], rule[2] or 0
            if day + takes > endDay + 40 then break end
            hung = hung + freshKg
            kept = kept + freshKg * (1 - rots)
            day = day + takes
        end
    end
    return kept * KCAL_PER_KG * keeps, hung
end

local yearNeed = DAILY_KCAL * 365 * FISH_SHARE
print(string.format("Fresh fish: %.0f kcal per kg for every species. A survivor eating %d kcal a day with fish as a third of the diet needs %.0f kcal of fish a year.", KCAL_PER_KG, DAILY_KCAL, yearNeed))
print("")
print("| Station | Fresh fish per cold load | Cold route: Nov 1 to Mar 15 | Share of a year's fish | Salt route under a roof, all year | Share |")
print("|---|---|---|---|---|---|")
for _, station in ipairs(STATIONS) do
    local name, stacks, weight = station[1], station[2], station[3]
    local loadKg = stacks * weight / 2.2 / HEADLESS_WEIGHT
    local cold, coldHung = season(stacks, weight, COLD, 305, 365 + 74, COLD_KEEPS, HEADLESS_WEIGHT)
    local saltTable = {}
    for month, days in ipairs(SALT_ROOF) do saltTable[month] = { days, 0 } end
    local salt, saltHung = season(stacks, weight, saltTable, 1, 365, SALT_KEEPS, GUTTED_WEIGHT)
    print(string.format("| %s | %.1f kg | %.0f kcal from %.0f kg | %.0f%% | %.0f kcal from %.0f kg | %.0f%% |",
        name, loadKg, cold, coldHung, cold / yearNeed * 100, salt, saltHung, salt / yearNeed * 100))
end
print("")
print("Salt fish keeps 4 to 6 months, so a year of salt drying can't all be stored at once; cold fish keeps 1 to 2 years.")
