-- Checks the debug console (TPF) loads and its commands run. Run from the mod folder: luajit tests/test_console.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()

-- Engine stand-ins
function getClimateManager()
    return {
        getTemperature = function() return 20 end,
        getHumidity = function() return 0.4 end,
        getPrecipitationIntensity = function() return 0 end,
        getPrecipitationIsSnow = function() return false end,
        getWindIntensity = function() return 0.3 end,
        getWindIntensity = function() return 0.3 end,
        getClimateForecaster = function()
            return { getForecast = function() return { getWindPower = function() return { getTotalMean = function() return 0.25 end } end } end }
        end,
    }
end
local player = H.player()
function getPlayer() return player end

dofile("42/media/lua/shared/TraditionalPreservationFish.lua")
local F = TraditionalPreservationFish
local TPF, run = H.checkConsole("42/media/lua/client/TraditionalPreservationFishDev.lua", "TPF")

check("weather prints the rates and the totals", run("weather"):find("Totals", 1, true) ~= nil)

check("wind starts a log", run("wind"):find("started", 1, true) ~= nil)
H.fire("EveryTenMinutes")
local wind = run("wind")
check("wind prints live and forecast wind", wind:find("dry: 1 samples, mean 0.300", 1, true) ~= nil
    and wind:find("Forecast wind for the same days: mean 0.250", 1, true) ~= nil)

local ledger = F.getLedger()
local open, rawSpoil = ledger.open, ledger.rawSpoil
run("age", 10)
check("age adds drying hours", ledger.open == open + 10 and ledger.cold ~= nil)
run("spoil")
check("spoil adds a day of spoiling weather", ledger.rawSpoil == rawSpoil + 24)
local covered, heat, warmCure = ledger.covered, ledger.heat, ledger.warmCure
run("age", 10)
run("heat", 5)
run("warmCure", 24)
check("age feeds covered frames, heat and warmCure their totals", ledger.covered == covered + 10 and ledger.heat == heat + 5 and ledger.warmCure == warmCure + 36)
ledger.wetness = 3
run("dry")
check("dry clears the wetness", ledger.wetness == 0)

check("fish with no name lists the fish", run("fish"):find("Fish: ", 1, true) ~= nil and #player.given == 0)
run("fish", "Walleye", nil, 2)
check("fish gives whole fish from Base", #player.given == 2 and player.given[1] == "Base.Walleye")
run("heads", 2)
run("stock")
run("salt")
check("heads, stock and salt land in the inventory", #player.given == 6
    and player.given[3] == "TraditionalPreservationFish.FishHead"
    and player.given[5] == "TraditionalPreservationFish.PotOfFishHeadStock" and player.given[6] == "Base.Salt")

local stamped = {}
player:getInventory().AddItem = function(_, fullType)
    table.insert(player.given, fullType)
    local modData, fish = {}, { fullType = fullType }
    function fish:getModData() return modData end
    function fish:getFullType() return self.fullType end
    function fish:getAge() return 3 end
    function fish:getModelIndex() return 0 end
    function fish:getDisplayName() return self.name or "" end
    function fish:setName(name) self.name = name end
    function fish:setCustomName() end
    function fish:setTooltip(tooltip) self.tooltip = tooltip end
    table.insert(stamped, fish)
    return fish
end
H.installGetText()
run("stockfish", 2)
check("stockfish gives unripe Cold Dried fish", #stamped == 2 and stamped[1].fullType == "TraditionalPreservationFish.ColdDriedFish"
    and stamped[1]:getModData().matureAge == 3 and stamped[1].name == "Walleye (Cold Dried, Unripe)")
function getCell() return { getGridSquare = function() return nil end } end
check("pallet says when there is none near", run("pallet"):find("No Stockfish Pallet", 1, true) ~= nil)

H.done()
