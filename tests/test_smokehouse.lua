-- Checks joining the Firebox to the Smokehouse chamber outside the game. Run from the mod folder: luajit tests/test_smokehouse.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
local F = TraditionalPreservationFishMeat
local Tiles = require "TraditionalPreservationFishMeat/Tiles"

local CHAMBER = Tiles.HANGERS.chamber.base

-- Sprite numbers: facing S back and door tile, then facing E.
local face, part = F.chamberTile(CHAMBER)
check("the first chamber tile is facing S, back", face == 0 and part == 0)
face, part = F.chamberTile(CHAMBER + 3)
check("the fourth is facing E, door", face == 1 and part == 1)
check("anything else isn't a chamber tile", F.chamberTile(CHAMBER + 4) == nil and F.chamberTile(CHAMBER - 1) == nil and F.chamberTile(nil) == nil)
check("an entry overlay isn't a chamber tile", F.chamberTile(Tiles.CHAMBER_ENTRY) == nil)

-- The other tile: facing S the door's tile is south of the back one.
local dx, dy = F.chamberOther(0, 0)
check("facing S the door tile is one south of the back tile", dx == 0 and dy == 1)
dx, dy = F.chamberOther(1, 1)
check("facing E the back tile is one west of the door tile", dx == -1 and dy == 0)

-- Where a Firebox may stand.
check("facing S the back tile's long sides", F.chamberSideAllowed(0, 0, 1, 0) and F.chamberSideAllowed(0, 0, -1, 0))
check("facing S the back gable", F.chamberSideAllowed(0, 0, 0, -1))
check("never on the shed's other tile", not F.chamberSideAllowed(0, 0, 0, 1))
check("facing S the door tile's long sides", F.chamberSideAllowed(0, 1, 1, 0) and F.chamberSideAllowed(0, 1, -1, 0))
check("never at the door's end", not F.chamberSideAllowed(0, 1, 0, 1))
check("facing E: back gable west, door end east", F.chamberSideAllowed(1, 0, -1, 0) and not F.chamberSideAllowed(1, 1, 1, 0))
check("facing E the door tile's long sides", F.chamberSideAllowed(1, 1, 0, 1) and F.chamberSideAllowed(1, 1, 0, -1))
check("not diagonal or further away", not F.chamberSideAllowed(0, 0, 1, 1) and not F.chamberSideAllowed(0, 0, 2, 0))

-- The entry art, only on the side the camera sees (S: east, E: south), numbered as the tile builder's.
check("pipe, facing S, back tile", F.entrySprite("Pipe", 0, 0, 1, 0) == Tiles.CHAMBER_ENTRY)
check("pipe, facing E, door tile", F.entrySprite("Pipe", 1, 1, 0, 1) == Tiles.CHAMBER_ENTRY + 3)
check("trench, facing S, door tile", F.entrySprite("Stones", 0, 1, 1, 0) == Tiles.CHAMBER_ENTRY + 5)
check("trench, facing E, back tile", F.entrySprite("Stones", 1, 0, 0, 1) == Tiles.CHAMBER_ENTRY + 6)
check("nothing on hidden sides", F.entrySprite("Pipe", 0, 0, -1, 0) == nil and F.entrySprite("Pipe", 0, 0, 0, -1) == nil)
check("nothing when the flue isn't laid", F.entrySprite(nil, 0, 0, 1, 0) == nil)
check("every entry tile is on the second sheet", Tiles.CHAMBER_ENTRY + 7 < Tiles.FIRST_SHEET_SIZE + Tiles.SHEETS[2].tiles)

-- Refusals, the first that applies.
local ok = { allowed = true, flueSide = "Back" }
check("a cold Firebox by a long side joins", F.connectRefusal(ok) == nil)
check("door end refused", F.connectRefusal({ allowed = false, flueSide = "Back" }) == "IGUI_TraditionalPreservationFishMeat_FlueDoorEnd")
check("the Firebox's door side refused", F.connectRefusal({ allowed = true }) == "IGUI_TraditionalPreservationFishMeat_FlueFireboxDoor")
check("not while it burns", F.connectRefusal({ allowed = true, flueSide = "Left", burning = true }) == "IGUI_TraditionalPreservationFishMeat_FlueBurning")
check("one flue a Firebox", F.connectRefusal({ allowed = true, flueSide = "Left", fireboxJoined = true }) == "IGUI_TraditionalPreservationFishMeat_FlueFireboxJoined")
check("one Firebox a shed", F.connectRefusal({ allowed = true, flueSide = "Left", chamberJoined = true }) == "IGUI_TraditionalPreservationFishMeat_FlueChamberJoined")

-- Kits.
local missing, noTool = F.flueKitMissing("Pipe", { ["Base.ClayPipeSegment"] = 2, ["Base.Clay"] = 1 }, true)
check("a full pipe kit", #missing == 0 and not noTool)
missing, noTool = F.flueKitMissing("Stones", { ["Base.FlatStone"] = 1 }, false)
check("two flat stones, two clay and the shovel short",
    #missing == 2 and missing[1][1] == "Base.FlatStone" and missing[1][2] == 2 and missing[2][2] == 2 and noTool)
for _, kind in ipairs(F.FLUE_KINDS) do
    local kit = F.FLUE_KITS[kind]
    local gives = false
    for _, need in ipairs(kit.items) do gives = gives or need[1] == kit.back end
    check(kind .. ": what comes back is part of the kit, and a tool is named", gives and kit.tool ~= nil)
end

-- Hot smoking (5c): the cook's hours by the heaviest piece, and the two counters against the Firebox's record.
local Hearth = require "TraditionalPreservationCore/Hearth"
local Weather = require "TraditionalPreservationCore/Weather"
local near = H.near
check("small fish need 4 stoked hours", F.hotHours(false, 0.8) == 4 and F.hotHours(false, 1.1) == 4)
check("big fish 6, between them in step", F.hotHours(false, 2.2) == 6 and near(F.hotHours(false, 1.65), 5))
check("a 0.3 meat cut 6, a 0.5 cut 8", near(F.hotHours(true, 0.3), 6) and near(F.hotHours(true, 0.5), 8))
check("never past 12", F.hotHours(false, 9) == F.HOT_MAX_HOURS and F.hotHours(true, 2) == F.HOT_MAX_HOURS)

local function pieces(...)
    local list = {}
    for _, weight in ipairs({ ... }) do
        -- A number is a country cured Beef of that weight; a table gives its own index and cure.
        local piece = type(weight) == "table" and weight or { weight = weight, index = 0, longCure = true }
        local modData = { longCure = piece.longCure }
        table.insert(list, { getActualWeight = function() return piece.weight end, getFullType = function() return F.CURED_MEAT end,
            getModelIndex = function() return piece.index end, getModData = function() return modData end })
    end
    return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
end
local stack = {}
F.startSmoke(stack, pieces(0.3, 0.5, 0.4), true)
check("the heaviest cut sets the stack's need", near(stack.hotNeed, 8) and stack.hot == 0 and stack.cold == 0)

local fire = {}
Hearth.logFire(fire, 100, nil, nil)
F.smokeStep(stack, fire)
check("joining takes the fire's record as it stands", stack.smokeFrom == fire.fireId and stack.lastStoked == 0)
Hearth.logFire(fire, 101, Hearth.STOKED, 120)
Hearth.logFire(fire, 104, Hearth.STOKED, 120)
F.smokeStep(stack, fire)
check("stoked hours in the session are hot", near(stack.hot, 3) and not F.hotDone(stack))
Hearth.logFire(fire, 104.5, nil, nil)
Hearth.logFire(fire, 105, Hearth.STOKED, 120)
Hearth.logFire(fire, 110, Hearth.STOKED, 120)
F.smokeStep(stack, fire)
check("a short gap keeps the cook going", near(stack.hot, 8.5) and F.hotDone(stack))

local fish = {}
F.startSmoke(fish, pieces(1.1), false)
F.smokeStep(fish, fire)
Hearth.logFire(fire, 112, Hearth.STOKED, 113)
Hearth.logFire(fire, 120, nil, nil)
F.smokeStep(fish, fire)
check("a fire that burnt out while away counts to its end", near(fish.hot, 0) and near(fish.cold, 3))
Hearth.logFire(fire, 121, Hearth.STOKED, 140)
Hearth.logFire(fire, 123, Hearth.BANKED, 160)
Hearth.logFire(fire, 127, Hearth.BANKED, 160)
F.smokeStep(fish, fire)
check("a broken session's hours and banked hours are smoke", near(fish.hot, 0) and near(fish.cold, 3 + 2 + 4))
Hearth.logFire(fire, 128, Hearth.STOKED, 140)
Hearth.logFire(fire, 132, Hearth.STOKED, 140)
F.smokeStep(fish, fire)
check("a new session cooks from its own start", near(fish.hot, 4) and F.hotDone(fish) and near(fish.cold, 3 + 2 + 5))

local moved = { hotNeed = 4, hot = 2, cold = 1, smokeFrom = fire.fireId, lastStoked = fire.stokedHours, lastBanked = fire.bankedHours }
F.smokeStep(moved, nil)
check("disconnected, the hot hours become smoke", moved.hot == 0 and near(moved.cold, 3) and moved.smokeFrom == nil)
local rebuilt = {}
Hearth.logFire(rebuilt, 200, nil, nil)
local before = { hotNeed = 4, hot = 1, cold = 0, smokeFrom = fire.fireId, lastStoked = 50, lastBanked = 0 }
F.smokeStep(before, rebuilt)
check("a rebuilt Firebox starts the count again", before.hot == 0 and near(before.cold, 1) and before.smokeFrom == 200)
local frame = {}
F.smokeStep(frame, fire)
check("a stack from before 5c has no need and never counts", frame.hot == nil and not F.hotDone(frame))
-- Cold smoke (5d): banked hours count on cool days only, by the ledger's share of cool hours since the last look;
-- every hour of fire dries in the fire's warmed air; a third of the clock hours in smoke makes it Cold Smoked.
local ledger = { clock = 0, smokeCool = 0, smokeBanked = 0, smokeStoked = 0, sheltered = 0, charqueBanked = 0, charqueStoked = 0,
    charqueSheltered = 0, temperature = 10 }
local cool = {}
F.startSmoke(cool, pieces(1.1), false)
cool.dried, cool.stackId = 0, 0
local bankFire = {}
Hearth.logFire(bankFire, 300, nil, nil)
F.smokeStep(cool, bankFire, ledger)
check("joining with the ledger takes its totals as they stand", cool.lastClock == 0 and cool.dried == 0)
Hearth.logFire(bankFire, 301, Hearth.BANKED, 400)
Hearth.logFire(bankFire, 311, Hearth.BANKED, 400)
ledger.clock, ledger.smokeCool, ledger.smokeBanked, ledger.smokeStoked, ledger.sheltered = 10, 5, 10, 20, 6.5
F.smokeStep(cool, bankFire, ledger)
check("half the hours were cool: half the banked hours are smoke", near(cool.cold, 5))
check("banked hours dry at the banked fire's rate", near(cool.dried, 10 * 0.35))
ledger.clock, ledger.smokeCool, ledger.smokeBanked, ledger.smokeStoked, ledger.sheltered = 20, 5, 20, 30, 13.5
Hearth.logFire(bankFire, 321, Hearth.BANKED, 400)
F.smokeStep(cool, bankFire, ledger)
check("a hot spell counts none", near(cool.cold, 5) and near(cool.dried, 3.5 + 10 * 0.3))
check("smoke by the heaviest piece: fish a day or two, a Beef 60 hours, a leg 120", F.smokeHours(false, 0.5) == 24
    and F.smokeHours(false, 2.2) == 48 and near(F.smokeHours(false, 1.65), 36) and F.smokeHours(true, 0.3) == 60
    and F.smokeHours(true, 0.45) == 60 and near(F.smokeHours(true, 1.35), 90) and F.smokeHours(true, 2.25) == 120 and F.smokeHours(true, 4) == 120)
check("a small fish stack needs 24 hours of smoke, however long it hangs", cool.smokeNeed == 24 and F.coldNeed(cool) == 24 and not F.coldDone(cool))
cool.cold = 24
check("with them it is Cold Smoked", F.coldDone(cool))
cool.cold = 5
check("no smoke, never Cold Smoked", not F.coldDone({ cold = 0, heaviest = 1 }))
check("a stack hung before the fixed hours takes its need from its heaviest piece", F.coldNeed({ smokeMeat = true, heaviest = 2.25 }) == 120
    and F.coldNeed({ heaviest = 1.1 }) == 24)
ledger.temperature = 25
local warm = {}
F.startSmoke(warm, pieces(0.3), true)
F.smokeStep(warm, bankFire, ledger)
Hearth.logFire(bankFire, 322, Hearth.BANKED, 400)
F.smokeStep(warm, bankFire, ledger)
check("with no ledger hours between, the weather now decides", warm.cold == 0)
local burst = {}
F.startSmoke(burst, pieces(1.1), false)
burst.dried, burst.stackId = 0, 20
local burstFire = {}
Hearth.logFire(burstFire, 330, nil, nil)
F.smokeStep(burst, burstFire, ledger)
Hearth.logFire(burstFire, 331, Hearth.STOKED, 333)
Hearth.logFire(burstFire, 333, Hearth.STOKED, 333)
ledger.clock, ledger.smokeBanked, ledger.smokeStoked, ledger.sheltered = 22, 22, 34, 15
F.smokeStep(burst, burstFire, ledger)
Hearth.logFire(burstFire, 340, nil, nil)
ledger.clock, ledger.smokeBanked, ledger.smokeStoked, ledger.sheltered = 29, 29, 46, 22
F.smokeStep(burst, burstFire, ledger)
check("a stoked burst on a hot day is no cold smoke when it breaks off", burst.hot == 0 and burst.cold == 0)
check("but its hours dry the stack at the stoked fire's rate", near(burst.dried, 2 * ((34 - 30) - (15 - 13.5)) / 2))
local old = { hotNeed = 4, hot = 0, cold = 0, dried = 0, smokeFrom = bankFire.fireId, lastStoked = bankFire.stokedHours or 0,
    lastBanked = bankFire.bankedHours or 0, lastClock = 29, lastSmokeCool = 5, lastDraughtCovered = 29, lastDraughtSheltered = 22 }
Hearth.logFire(bankFire, 330, Hearth.BANKED, 400)
ledger.clock, ledger.smokeBanked, ledger.smokeStoked, ledger.sheltered = 38, 38, 55, 28
F.smokeStep(old, bankFire, ledger)
check("a stack from before the smoulder's warmth starts its warm totals now, gaining nothing yet", old.dried == 0
    and old.lastDraughtBanked == 38 and old.lastDraughtStoked == 55)

check("a stack by a burning fire knows how it burns", cool.burning == Hearth.BANKED)
local rates = { shelteredRate = 0.4, bankedRate = 0.6, stokedRate = 0.9, charqueShelteredRate = 0.3, charqueBankedRate = 0.5,
    charqueStokedRate = 0.8 }
check("banked, its Drying Rate is the banked fire's", near(F.stackStatus(false, { sheltered = true, burning = Hearth.BANKED, dried = 0 }, rates).rate, 0.6)
    and near(F.charqueStatus({ sheltered = true, burning = Hearth.BANKED, dried = 0 }, rates).rate, 0.5))
check("stoked, the stoked fire's", near(F.stackStatus(false, { sheltered = true, burning = Hearth.STOKED, dried = 0 }, rates).rate, 0.9)
    and near(F.charqueStatus({ sheltered = true, burning = Hearth.STOKED, dried = 0 }, rates).rate, 0.8))
check("a stack saved burning before reads banked", near(F.stackStatus(false, { sheltered = true, burning = true, dried = 0 }, rates).rate, 0.6))
check("with the fire out, Sheltered's", near(F.stackStatus(false, { sheltered = true, dried = 0 }, rates).rate, 0.4))

-- The smoulder's warmth: the shed reads BANKED_LIFT (15) / STOKED_LIFT (20) warmer, its humidity halved per 10 C, outdoor wind.
local damp = { temperature = 5, humidity = 0.8, wind = F.WIND_GOOD, precipitation = 0 }
local fish, meat = F.liftedRates(damp, F.BANKED_LIFT)
check("banked at 5 C: 20 C in air of 28%", near(fish, 1) and near(meat, F.charqueWarmRate(20) * F.CHARQUE_WINDY_RATE))
fish = F.liftedRates({ temperature = 2.3, humidity = 0.8 }, F.BANKED_LIFT)
check("banked at 2.3 C beats the Sheltered floor", near(fish, F.temperatureRate(17.3)) and fish > F.MIN_DRY_RATE)
fish, meat = F.liftedRates(damp, F.STOKED_LIFT)
check("stoked at 5 C: salt fish at full speed", near(fish, 1) and near(meat, F.charqueWarmRate(25) * F.CHARQUE_WINDY_RATE))
fish = F.liftedRates({ temperature = -10, humidity = 0.8 }, F.BANKED_LIFT)
check("never under the floor", near(fish, F.MIN_DRY_RATE))
local warmLedger = F.newLedger(0)
F.advance(warmLedger, 10, damp)
check("the ledger keeps the warmed totals", near(warmLedger.smokeBanked, 10)
    and near(warmLedger.smokeStoked, 10) and warmLedger.smokeBanked > warmLedger.sheltered
    and warmLedger.charqueBanked < warmLedger.charqueStoked)

-- The bar and the badge follow the hot cook while a stoked run counts.
check("no run counting: no cook share", F.cookShare({ hotNeed = 6, hot = 0 }) == nil and F.cookShare({ dried = 5 }) == nil)
check("a leg's stack never cooks", F.cookShare({ hotNeed = 6, hot = 3, noHot = true }) == nil)
check("half way through the cook", near(F.cookShare({ hotNeed = 6, hot = 3 }), 0.5))
check("the bar shows the cook when it is ahead of the drying", near(F.stackProgress({ dried = 10, hotNeed = 6, hot = 3 }, 288), 0.5))
check("the drying when that is ahead", near(F.stackProgress({ dried = 200, hotNeed = 6, hot = 1 }, 288), 200 / 288))
check("a broken run drops the bar back to the drying", near(F.stackProgress({ dried = 10, hotNeed = 6, hot = 0 }, 288), 10 / 288))
check("the cook never ends the stack by the bar alone", F.stackProgress({ dried = 10, hotNeed = 6, hot = 6 }, 288) == F.SHED_WAIT)

-- Dry Cured meat is named by the animal its cut came from.
local function meatItem(index)
    return { getFullType = function() return F.DRY_CURED end, getModelIndex = function() return index end,
        getAge = function() return 0 end, getModData = function() return { fishName = "Steak" } end }
end
check("a smoked steak is Suho Meso", F.stageName(meatItem(1)) == "Suho Meso")
check("a mutton chop is Mutton Ham, venison Jerked Venison", F.stageName(meatItem(2)) == "Mutton Ham" and F.stageName(meatItem(3)) == "Jerked Venison")
check("pork is Smoked Dry Cured Pork, a leg Smoked Country Ham", F.stageName(meatItem(5)) == "Smoked Dry Cured Pork" and F.stageName(meatItem(6)) == "Smoked Country Ham")

check("air dried, beef is Bresaola and a leg plain Country Ham", F.stageName({ getFullType = function() return F.DRY_CURED end,
    getModelIndex = function() return 0 end, getAge = function() return 0 end, getModData = function() return { airDried = true } end }) == "Bresaola"
    and F.stageName({ getFullType = function() return F.COUNTRY_HAM end, getModelIndex = function() return F.LEG_INDEX end,
        getAge = function() return 0 end, getModData = function() return { airDried = true } end }) == "Country Ham")

-- Dry curing (6b): meat in the shed dries in cool air on its own need, by the heaviest piece.
check("full from 12 C, a quarter in frost", F.dryCureRate(12) == 1 and F.dryCureRate(25) == 1 and near(F.dryCureRate(6), 0.5)
    and F.dryCureRate(0) == 0.25 and F.dryCureRate(-15) == 0.25)
check("a Beef needs three weeks, a leg six, a Steak a little less", near(F.dryCureHours(0.45), 504) and near(F.dryCureHours(2.25), 1008)
    and near(F.dryCureHours(0.27), 453.6) and F.dryCureHours(5) == 1008)
check("under-salted meat rots in four weeks at 10 C, five times slower at 0 C, five times faster at 20 C",
    near(F.underCureRate(10) * 672, 1) and near(F.underCureRate(0) * 672, 0.2) and near(F.underCureRate(20) * 672, 5)
    and F.underCureRate(40) == F.underCureRate(30))
local cureLedger = F.newLedger(0)
F.advance(cureLedger, 10, { temperature = 6, humidity = 0.3, precipitation = 0, wind = 0 })
check("the ledger keeps dry curing's totals, the fire's above the shed's", near(cureLedger.dryCure, 5)
    and near(cureLedger.dryCureBanked, 10) and near(cureLedger.dryCureStoked, 10) and near(cureLedger.dryCureRate, 0.5))
check("and the under-salted's, warmer by the fire", near(cureLedger.underCure, 10 * F.underCureRate(6))
    and near(cureLedger.underCureBanked, 10 * F.underCureRate(21)) and near(cureLedger.underCureStoked, 10 * F.underCureRate(26)))

local ham = {}
F.startSmoke(ham, pieces({ weight = 2.25, index = F.LEG_INDEX, longCure = true }, 0.45), true)
check("a stack with a leg needs six weeks and takes no hot cook", near(ham.cureNeed, 1008) and ham.noHot and not ham.underCured)
ham.hot = 99
check("however long it is stoked", not F.hotDone(ham))
local corned = {}
F.startSmoke(corned, pieces({ weight = 0.45, index = 0 }, { weight = 0.3, index = 1 }), true)
check("Corned meat is under-salted, and still hot smokes", corned.underCured and near(corned.cureNeed, 504) and not corned.noHot)
check("only a stack that is all Corned can end by under-salting", corned.allUnder and not ham.allUnder)
local mixed = {}
F.startSmoke(mixed, pieces({ weight = 0.45, index = 0 }, 0.45), true)
check("a mixed stack is under-salted but dries on", mixed.underCured and not mixed.allUnder)
check("fish has no dry-curing need", cool.cureNeed == nil and not F.dryCuring(cool))

-- A corned stack in the shed, a day with the fire out and a day banked: it dries and spoils by the shed's totals.
local shed = F.newLedger(0)
corned.dried, corned.spoiled, corned.stackId = 0, 0, 0
corned.lastDryCure, corned.lastUnderCure, corned.lastSaltSpoil = 0, 0, 0
corned.inShed = true
local shedFire = {}
Hearth.logFire(shedFire, 500, nil, nil)
F.smokeStep(corned, shedFire, shed)
F.advance(shed, 24, { temperature = 0, humidity = 0.3, precipitation = 0, wind = 0 })
F.charqueStep(corned, shed)
F.smokeStep(corned, shedFire, shed)
check("with the fire out it dries at the frost rate", near(corned.dried, 24 * 0.25))
check("and spoils as at 0 C", near(corned.underSpoiled, 24 * F.underCureRate(0)))
Hearth.logFire(shedFire, 501, Hearth.BANKED, 600)
Hearth.logFire(shedFire, 525, Hearth.BANKED, 600)
F.advance(shed, 48, { temperature = 0, humidity = 0.3, precipitation = 0, wind = 0 })
F.charqueStep(corned, shed)
F.smokeStep(corned, shedFire, shed)
check("banked, the shed is 15 C: full rate", near(corned.dried, 24 * 0.25 + 24 * 1))
check("and the under-salted spoils as at 15 C", near(corned.underSpoiled, 24 * F.underCureRate(0) + 24 * F.underCureRate(15)))
check("all its banked hours were smoke", near(corned.cold, 24))
local status = F.charqueStatus(corned, shed)
check("its popup reads dry curing, under-salted, the shed at 15 C", status.dryCuring and status.underSalted and status.shedTemperature == 15
    and near(status.rate, 1) and near(status.progress, 30 / 504) and near(status.spoiled, corned.underSpoiled))
check("the shed's words", F.dryCureTemperatureWord(15) == "IGUI_TraditionalPreservationFishMeat_TempGoodCure"
    and F.dryCureTemperatureWord(-3) == "IGUI_TraditionalPreservationFishMeat_TempFrostSlow")
check("on a frame it is still charque", not F.dryCuring({ cureNeed = 504 }) and F.meatHours({ cureNeed = 504 }) == F.CHARQUE_HOURS
    and F.meatHours({ cureNeed = 504, inShed = true }) == 504)

-- Country Cured meat on a Frame or Beam in the shade (0.4.15): it dry cures there too, air dried; a basement by its own
-- temperature, times two thirds (sweep step D).
local shade = {}
F.startSmoke(shade, pieces(0.45), true)
check("a stack with Country Cured meat dry cures wherever it hangs", shade.longStack and F.dryCuring(shade) and F.meatHours(shade) == 504)
check("an all-Corned stack on a frame in the open or under a roof is charque", not corned.longStack
    and not F.dryCuring({ cureNeed = 504, underCured = true }) and not F.dryCuring({ cureNeed = 504, underCured = true, covered = true }))
check("in a room or a basement it dry cures, under-salted: no charque indoors", F.dryCuring({ cureNeed = 504, underCured = true, sheltered = true })
    and F.curePlace({ sheltered = true, basement = true }) == "Basement" and F.meatHours({ cureNeed = 504, sheltered = true }) == 504)
check("a charque stack from before 6b stays charque indoors", not F.dryCuring({ sheltered = true }))
local cellar = F.newLedger(0)
for _, stack in ipairs({ shade }) do
    stack.dried, stack.spoiled, stack.lastSaltSpoil = 0, 0, 0
    stack.lastDryCure, stack.lastUnderCure, stack.lastCureBasement, stack.lastUnderBasement = 0, 0, 0, 0
end
F.advance(cellar, 24, { temperature = 0, humidity = 0.3, precipitation = 0, wind = 0 })
check("in the open it waits for a roof", F.curePlace(shade) == "Open" and F.charqueStatus(shade, cellar).reason == "NeedsRoof")
F.charqueStep(shade, cellar)
check("and dries nothing", shade.dried == 0)
shade.covered = true
F.advance(cellar, 48, { temperature = 0, humidity = 0.3, precipitation = 0, wind = 0 })
F.charqueStep(shade, cellar)
check("under a roof it dries as the shed with the fire out", near(shade.dried, 24 * 0.25) and F.curePlace(shade) == "Shade")
shade.covered, shade.basement, shade.sheltered = nil, true, true
F.advance(cellar, 72, { temperature = 0, humidity = 0.3, precipitation = 0, wind = 0 })
F.charqueStep(shade, cellar)
local cellarRate = F.dryCureRate(Weather.placeTemperature(cellar, "Basement")) * 2 / 3
check("in a basement by the basement's temperature, at two thirds", near(shade.dried, 24 * 0.25 + 24 * cellarRate)
    and cellarRate > 0.25 and cellarRate < 2 / 3 and F.curePlace(shade) == "Basement")
local cellarStatus = F.charqueStatus(shade, cellar)
check("its popup reads the cellar's temperature and rate", near(cellarStatus.rate, cellarRate)
    and cellarStatus.shedTemperature == Weather.placeTemperature(cellar, "Basement")
    and cellarStatus.dryCuring and not cellarStatus.underSalted)
check("a warm basement (12 C and up) dries a cut in about 32 days, a leg 63", near(F.dryCureRate(12) * 2 / 3, 2 / 3)
    and near(504 / (2 / 3) / 24, 31.5) and near(1008 / (2 / 3) / 24, 63))
local cellarCorned = { cureNeed = 504, longStack = true, underCured = true, basement = true, sheltered = true, dried = 0, spoiled = 0,
    lastSaltSpoil = cellar.saltSpoil, lastDryCure = cellar.dryCure, lastUnderCure = cellar.underCure,
    lastCureBasement = cellar.dryCureBasement, lastUnderBasement = cellar.underCureBasement }
F.advance(cellar, 96, { temperature = -10, humidity = 0.3, precipitation = 0, wind = 0 })
-- The stretch goes by the basement as the season stands at its end.
local cellarC = Weather.placeTemperature(cellar, "Basement")
F.charqueStep(cellarCorned, cellar)
check("a Corned piece in a basement stack spoils at the basement's temperature", near(cellarCorned.underSpoiled, 24 * F.underCureRate(cellarC)))

-- Sweep step D: whatever dries in a basement goes by the basement's temperature, and a tub there minds it.
local hot = F.newLedger(0)
local summer = { temperature = 30, humidity = 0.3, precipitation = 0, wind = 0 }
F.advance(hot, 24, summer)
local hotC = Weather.placeTemperature(hot, "Basement")
local cellarFish = { dried = 0, spoiled = 0, basement = true, sheltered = true, lastOpen = hot.open, lastSheltered = hot.sheltered,
    lastCovered = hot.covered, lastSaltSpoil = hot.saltSpoil, lastHeat = hot.heat, lastBasementSheltered = hot.basementSheltered }
local cellarMeat = { dried = 0, spoiled = 0, basement = true, sheltered = true, lastSaltSpoil = hot.saltSpoil,
    lastCharqueRain = hot.charqueRain, lastCharqueBasement = hot.charqueBasement }
F.advance(hot, 48, summer)
F.saltStep(cellarFish, hot)
F.charqueStep(cellarMeat, hot)
check("salt fish in a basement dries indoors by the basement's temperature", near(hot.basementShelteredRate,
    math.max(F.temperatureRate(hotC) * F.airRate(0.3) * F.SHELTERED_RATE, F.MIN_DRY_RATE))
    and hot.basementShelteredRate < hot.shelteredRate and near(cellarFish.dried, 24 * hot.basementShelteredRate))
check("so does charque", near(cellarMeat.dried, 24 * F.charqueWarmRate(hotC) * F.airRate(0.3) * F.CHARQUE_INDOORS_RATE)
    and near(F.charqueStatus(cellarMeat, hot).rate, hot.charqueBasementRate))
local upstairsTub = { lastWarmCure = 0, lastWarmCureBasement = 0, lastLongCure = 0, lastLongCureBasement = 0 }
local cellarTub = { basement = true, lastWarmCure = 0, lastWarmCureBasement = 0, lastLongCure = 0, lastLongCureBasement = 0 }
local oldCellarTub = { basement = true, lastWarmCure = 0, lastLongCure = 0 }
check("a tub in a basement has no warm cure in a 30 C season, only the long cure's share",
    F.cureSpoiled(upstairsTub, hot) > F.cureSpoiled(cellarTub, hot) and hot.warmCureBasement == 0
    and near(F.cureSpoiled(cellarTub, hot), hot.longCureBasement) and hot.longCureBasement > 0
    and F.tubSpoiling(cellarTub, hot) and F.tubSpoiling(upstairsTub, hot))
check("a basement tub pressed before step D keeps the season's totals", F.cureSpoiled(oldCellarTub, hot) == F.cureSpoiled(upstairsTub, hot))

-- A leg's stoked hours are smoke at once.
local legFire = {}
Hearth.logFire(legFire, 700, nil, nil)
F.smokeStep(ham, legFire)
ham.hot, ham.hotCool = 0, 0
Hearth.logFire(legFire, 701, Hearth.STOKED, 720)
Hearth.logFire(legFire, 705, Hearth.STOKED, 720)
F.smokeStep(ham, legFire)
check("a leg's stoked hours are smoke, not a cook", ham.hot == 0 and near(ham.cold, 4))

-- A stack hung before 6b keeps its share of progress on the new need.
local before6b = { hotNeed = 8, hot = 0, cold = 0, smokeMeat = true, heaviest = 0.45, dried = 60, inShed = true }
F.smokeStep(before6b, legFire, shed)
check("an older stack halfway through charque's clock is halfway through its cure", near(before6b.cureNeed, 504) and near(before6b.dried, 252))

-- The ham by the door (user's idea): the door's tile, by facing, only with finished stacks.
check("the ham hangs on the door's tile while stacks wait", F.hamSprite(0, 1, true) == Tiles.CHAMBER_HAM and F.hamSprite(1, 1, true) == Tiles.CHAMBER_HAM + 1)
check("never on the back tile, nor with nothing finished", F.hamSprite(0, 0, true) == nil and F.hamSprite(0, 1, false) == nil)
H.done()
