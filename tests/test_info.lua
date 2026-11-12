-- Checks a station's info block (in its own crafting window) outside the game: its rows, a bar for each batch, the
-- notes, and which entities get one.
-- Run from the mod folder: luajit tests/test_info.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(1000)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules and TP Core's load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") then return realRequire(name) end
end
H.installMenus()
-- What TP Core's StationInfo derives from and wraps.
ISPanel = H.class("ISPanel")
ISWidgetCraftLogicOutputProgress = { createDynamicChildren = function() end, calculateLayout = function() end }

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
dofile("42/media/lua/client/TraditionalPreservationFishMeatInfo.lua")
local F, Info = TraditionalPreservationFishMeat, TraditionalPreservationFishMeatInfo

local function batch(recipe, modData, progress)
    local data = {}
    function data:getRecipe() return { getName = function() return "TraditionalPreservationFishMeat." .. recipe end } end
    function data:getModData() return modData end
    return { data = data, progress = progress }
end

local function piece(weight)
    return { getActualWeight = function() return weight end }
end

local function valueOf(shown, label)
    for _, row in ipairs(shown.rows) do
        if row[1] == "IGUI_TraditionalPreservationFishMeat_" .. label then return row[2] end
    end
end

local function hasNote(shown, text)
    for _, note in ipairs(shown.notes) do
        if note:find(text, 1, true) then return true end
    end
    return false
end

local beam = F.hangerFor(F.spriteIndex("traditionalpreservationfishmeat_02_0"))
-- A Beam in the open on a dry summer day: a salt stack two thirds dried, a stockfish stack that can't dry, and a
-- finished stack waiting.
local ledger = { temperature = 22, seasonTemperature = 19, wind = 0.3, wetness = 0, coldWetness = 0, openRate = 1,
    coveredRate = 1, shelteredRate = 0.65, coldRate = 0, coldCoveredRate = 0, rawSpoiling = true, rawSpoilingOpen = true, saltSpoiling = false }
local shown = Info.rows({ hanger = beam, place = "Open", waiting = { piece(1), piece(2) }, finished = 3, finishedStacks = 1,
    batches = { batch("HangFishToDry", { dried = 192, spoiled = 0 }, 0.67), batch("HangFishToColdDry", { dried = 0, spoiled = 0.2 }, 0) } },
    ledger, 1000)
check("the place and the stacks in use", valueOf(shown, "Place") == "Open air"
    and valueOf(shown, "InfoHolds") == "3 of 4 stacks, up to 15 weight each")
check("the air now and over the season", valueOf(shown, "InfoAir") == "22 C now, 19 C over the season")
check("wind and wetness in the open", valueOf(shown, "Wind") == "Good drying wind" and valueOf(shown, "InfoWetness") == "0%")
check("no Firebox line off the Smokehouse", valueOf(shown, "InfoFire") == nil)
check("a bar for each batch", #shown.bars == 2 and shown.bars[1].text == "1. Salt fish" and shown.bars[2].text == "2. Stockfish")
check("the salt stack's share and time left", H.near(shown.bars[1].share, 192 / 288) and shown.bars[1].value == "67%, 4 d 0 h left")
check("the stockfish says why it stands still", shown.bars[2].value == "0%, Stopped (Too warm)")
check("and is marked as held back", shown.bars[2].colour ~= shown.bars[1].colour)
check("its spoilage is noted by its number", hasNote(shown, "Stack 2: Spoiling (Warm season), 20%"))
check("the pieces not yet started", hasNote(shown, "Loaded and not started: 2"))
check("the finished stack", hasNote(shown, "Finished and waiting to be taken: 3, on 1 of the stacks"))
check("and that times go by today's weather", hasNote(shown, "assume the weather holds"))
check("no line passed a percentage to the translator", #H.textWarnings == 0)

-- Under an open roof there is wind but no wetness; in a room neither.
local covered = Info.rows({ hanger = beam, place = "Covered", waiting = {}, finished = 0, finishedStacks = 0, batches = {} }, ledger, 1000)
check("under a roof: wind, no wetness", valueOf(covered, "Wind") ~= nil and valueOf(covered, "InfoWetness") == nil
    and valueOf(covered, "Place") == "Under an open roof")
check("an empty station says so", #covered.bars == 0 and hasNote(covered, "Nothing in it."))
local cellar = Info.rows({ hanger = beam, place = "Basement", waiting = {}, finished = 0, finishedStacks = 0, batches = {} }, ledger, 1000)
check("a basement: its name, no wind", valueOf(cellar, "Place") == "Basement" and valueOf(cellar, "Wind") == nil)
check("its air is the basement's own, not the day's", valueOf(cellar, "InfoAir") == require("TraditionalPreservationCore/UI").placeText("Basement",
    10 + 0.4 * (ledger.seasonTemperature - 10)))

-- The tub: what waits against its limits, then a long cure in a warm season.
local tub = Info.rows({ place = "Sheltered", waiting = { piece(0.5), piece(2.5) }, finished = 0, finishedStacks = 0, batches = {} }, ledger, 1000)
check("the tub's weight and pieces", valueOf(tub, "InfoHolds") == "3.0 of 50 weight, 2 of 35 pieces" and valueOf(tub, "Place") == "Indoors")
check("the tub has no wind line", valueOf(tub, "Wind") == nil)
local warm = { temperature = 22, seasonTemperature = 14, warmCure = 0, longCureSpoil = 0.3, warmCuring = false, longCuring = true }
local curing = Info.rows({ place = "Sheltered", waiting = {}, finished = 0, finishedStacks = 0,
    batches = { batch("CountryCureMeat", { pressHours = 240, pressStartHour = 880, lastWarmCure = 0, lastLongCure = 0.1 }, 0.5) } }, warm, 1000)
check("a curing tub is closed", valueOf(curing, "InfoHolds") == "Curing: closed until the last piece is out")
check("the long cure's bar", curing.bars[1].text == "Country cure" and curing.bars[1].value == "50%, 5 d 0 h left")
check("its warm season is noted", curing.notes[1] == "Spoiling (Warm cure), 20%")
check("the tub's clock doesn't go by the weather", not hasNote(curing, "assume the weather holds"))
local function tubBar(recipe)
    return Info.rows({ place = "Sheltered", waiting = {}, finished = 0, finishedStacks = 0,
        batches = { batch(recipe, { pressHours = 48, pressStartHour = 990, lastWarmCure = 0 }, 0.2) } }, warm, 1000).bars[1].text
end
check("the tub names its cure, with no number", tubBar("PressSaltedFish") == "Fish cure" and tubBar("PressSaltedMeat") == "Corning")
local cured = Info.rows({ place = "Sheltered", waiting = {}, finished = 4, finishedStacks = 1, batches = {} }, warm, 1000)
check("cured pieces wait in the tub", hasNote(cured, "Cured and waiting to be taken: 4"))

-- The Smokehouse: Corned meat with a stoked run on it, and its smoke.
local shed = F.hangerFor(F.spriteIndex("traditionalpreservationfishmeat_02_448"))
local cool = { temperature = 8, seasonTemperature = 6, dryCureRate = 0.7, dryCureStokedRate = 1, dryCureBankedRate = 0.9, saltSpoiling = false }
local Hearth = require "TraditionalPreservationCore/Hearth"
local smoking = Info.rows({ hanger = shed, place = "Sheltered", waiting = {}, finished = 0, finishedStacks = 0,
    batches = { batch("HangMeatToDry", { dried = 100, spoiled = 0, underSpoiled = 0.1, inShed = true, sheltered = true, cureNeed = 504,
        underCured = true, burning = Hearth.STOKED, hot = 3, hotNeed = 8, cold = 12, smokeNeed = 60, smokeFrom = 7, smokeMeat = true }, 0.2) } },
    cool, 1000, "stoked")
check("the Smokehouse's fire", valueOf(smoking, "InfoFire") == "Stoked (hot)" and valueOf(smoking, "Wind") == nil)
check("meat in the shed dry cures", smoking.bars[1].text == "1. Dry cure")
check("the cook is called out", hasNote(smoking, "Stack 1: Hot smoking, 3.0 of 8 h stoked in a row: it comes out Hot Smoked"))
check("and the smoke so far", hasNote(smoking, "Stack 1: 12.0 of 60 h of smoke"))
check("and the under-salting", hasNote(smoking, "Stack 1: Spoiling (28 C where it hangs)"))
check("no fire joined", valueOf(Info.rows({ hanger = shed, place = "Sheltered", waiting = {}, finished = 0, finishedStacks = 0, batches = {} },
    cool, 1000, "none"), "InfoFire") == "None joined")
check("still no percentage passed to the translator", #H.textWarnings == 0)

-- Which entities get a block: the mod's stations only, and the block is the World's look at them.
local function object(sprite)
    return { class = "IsoObject", getSprite = function() return { getName = function() return sprite end } end }
end
local looked
TraditionalPreservationFishMeatWorld = { inspect = function(station)
    looked = station
    return { station = station, hanger = beam, place = "Covered", waiting = {}, finished = 0, finishedStacks = 0, batches = {} }
end }
local gantry = object("traditionalpreservationfishmeat_02_2")
local block = Info.forEntity(gantry)
check("a station gets its block", looked == gantry and valueOf(block, "Place") == "Under an open roof")
looked = nil
check("another mod's station gets none, and isn't looked at", Info.forEntity(object("walls_01_0")) == nil and looked == nil)
check("nor an item that crafts", Info.forEntity({ class = "InventoryItem" }) == nil)
TraditionalPreservationFishMeatWorld = { inspect = function() return nil end }
check("nor a station the World can't read yet", Info.forEntity(gantry) == nil)

H.done()
