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
    }
end
local player = H.player()
function getPlayer() return player end

dofile("42/media/lua/shared/TraditionalPreservationFish.lua")
local F = TraditionalPreservationFish
local TPF, run = H.checkConsole("42/media/lua/client/TraditionalPreservationFishDev.lua", "TPF")

check("weather prints the rates and the totals", run("weather"):find("Totals", 1, true) ~= nil)

local ledger = F.getLedger()
local open, rawSpoil = ledger.open, ledger.rawSpoil
run("age", 10)
check("age adds drying hours", ledger.open == open + 10 and ledger.cold ~= nil)
run("spoil")
check("spoil adds a day of spoiling weather", ledger.rawSpoil == rawSpoil + 24)
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

H.done()
