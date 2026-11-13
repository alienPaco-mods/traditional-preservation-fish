-- Checks the debug console (TPFM) loads and its commands run. Run from the mod folder: luajit tests/test_console.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
function getItemNameFromFullType(fullType) return (fullType:gsub("^[^.]*%.", "")) end
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

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
AnimalPartsDefinitions = { animals = { sowlandrace = { parts = {} } } }
package.loaded["Definitions/animal/AnimalPartsDefinitions"] = true
dofile("42/media/lua/shared/TraditionalPreservationFishMeatFat.lua")
local F = TraditionalPreservationFishMeat
local TPFM, run = H.checkConsole("42/media/lua/client/TraditionalPreservationFishMeatDev.lua", "TPFM")

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
local under = ledger.underCure
run("age", 100)
check("age spoils Corned meat in a Smokehouse as a 12 C shed would", math.abs(ledger.underCure - under - 100 * F.underCureRate(12)) < 1e-9
    and ledger.dryCure ~= nil)
covered = ledger.covered - 10
check("age feeds covered frames, heat and warmCure their totals", ledger.covered == covered + 10 and ledger.heat == heat + 5 and ledger.warmCure == warmCure + 36)
ledger.wetness = 3
run("dry")
check("dry clears the wetness", ledger.wetness == 0)

check("fish with no name lists the fish", run("fish"):find("Fish: ", 1, true) ~= nil and #player.given == 0)
run("fish", "Walleye", 2)
check("fish gives whole fish from Base", #player.given == 2 and player.given[1] == "Base.Walleye")
run("give", "head", 2)
run("give", "stock")
run("give", "salt")
check("give with no name lists the things", run("give"):find("fatPot", 1, true) ~= nil and #player.given == 6)
check("heads, stock and salt land in the inventory", #player.given == 6
    and player.given[3] == "TraditionalPreservationFishMeat.FishHead"
    and player.given[5] == "TraditionalPreservationFishMeat.PotOfFishHeadStock" and player.given[6] == "Base.Salt")

run("give", "fat", 2)
check("fat gives each raw fat", #player.given == 12 and player.given[7] == "TraditionalPreservationFishMeat.PorkFat"
    and player.given[9] == "TraditionalPreservationFishMeat.BeefSuet" and player.given[11] == "TraditionalPreservationFishMeat.MuttonFat")
check("fatRows says there are none before a world starts", run("fatRows"):find("sowlandrace: no row", 1, true) ~= nil)
F.applyFatRows(true)
local fatRows = run("fatRows")
check("fatRows prints each animal's row, and the ones vanilla lacks", fatRows:find("sowlandrace: TraditionalPreservationFishMeat.PorkFat 2-3", 1, true) ~= nil
    and fatRows:find("cowangus: not in vanilla's table", 1, true) ~= nil)

local stamped = {}
player:getInventory().AddItem = function(_, fullType)
    table.insert(player.given, fullType)
    local modData, fish = {}, { fullType = fullType }
    function fish:getModData() return modData end
    function fish:getFullType() return self.fullType end
    function fish:getAge() return 3 end
    function fish:getModelIndex() return -1 end
    function fish:getDisplayName() return self.name or "" end
    function fish:setName(name) self.name = name end
    function fish:setCustomName() end
    function fish:setTooltip(tooltip) self.tooltip = tooltip end
    function fish:setCooked(cooked) self.cooked = cooked end
    function fish:setBurnt(burnt) self.burnt = burnt end
    table.insert(stamped, fish)
    return fish
end
local pots = #stamped
run("give", "fatPot")
run("give", "fatPot", 1, "burnt")
check("fatPot gives a cooked pot, or a burnt one", #stamped == pots + 2 and stamped[pots + 1].cooked and not stamped[pots + 1].burnt
    and stamped[pots + 2].burnt and stamped[pots + 1].fullType == "TraditionalPreservationFishMeat.PotOfPorkFat")
stamped = {}
H.installGetText()
run("fish", "Walleye", 2, "stockfish")
check("stockfish gives young stockfish", #stamped == 2 and stamped[1].fullType == "TraditionalPreservationFishMeat.ColdDriedFish"
    and stamped[1]:getModData().matureAge == 3 and stamped[1].name == "Walleye Stockfish")
check("meat with no name lists the cuts and the stages", run("meat"):find("LegOfPork", 1, true) ~= nil and run("meat"):find("dryCured", 1, true) ~= nil
    and run("meat"):find("charque", 1, true) ~= nil and run("meat"):find("hotSmoked", 1, true) ~= nil)
check("fish lists its stages, the dried and smoked ones too", run("fish"):find("\"dried\", \"hotSmoked\", \"coldSmoked\"", 1, true) ~= nil)
local before = #player.given
run("meat", "all", 2)
check("meat gives each cut", #player.given == before + 2 * #F.MEAT_CUTS and player.given[before + 1] == "Base.Beef")
before = #player.given
check("kit with no kind lists them", run("kit"):find("TPFM.kit(\"potted\")", 1, true) ~= nil and #player.given == before)
check("the flue kit is TP Core's now", run("kit"):find("TPFM.kit(\"flue\")", 1, true) == nil)
function getCell() return { getGridSquare = function() return nil end } end
check("pallet says when there is none near", run("pallet"):find("No Stockfish Pallet", 1, true) ~= nil)
check("smoke says when no Smokehouse is near", run("smoke"):find("No Smokehouse", 1, true) ~= nil)

H.done()
