-- Checks the curing rules outside the game. Run from the mod folder: luajit tests/test_curing.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
local hours = 100
ModData = { tables = {} }
function ModData.getOrCreate(key)
    ModData.tables[key] = ModData.tables[key] or {}
    return ModData.tables[key]
end
function getGameTime()
    return { getWorldAgeHours = function() return hours end }
end
local keptShare
function ZombRandFloat(low, high)
    keptShare = low + (high - low) * 0.5
    return keptShare
end
ItemTag = { UNCUT_FISH = "uncut", SALT = "salt" }
local nextRoll = 0
function ZombRand(limit) return nextRoll % limit end
-- The real EN texts, so the names tested are the ones players see.
H.installGetText()
function getItemNameFromFullType(fullType)
    if fullType == "Base.FishFillet" then return "Fish Fillet" end
    return (fullType:gsub("^[^.]*%.", ""))
end
local onInit
Events = { OnInitGlobalModData = { Add = function(handler) onInit = handler end } }
local loaded = {}
ScriptManager = { instance = {} }
function ScriptManager.instance:getCraftRecipe(name)
    return { Load = function(_, recipeName, text) loaded[recipeName] = text end, getName = function() return (name:gsub("^Base%.", "")) end }
end
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
local T = TraditionalPreservationFishMeat

local check = H.check

local function near(a, b) return math.abs(a - b) < 0.0001 end

local list = H.list

local function newRecipeData(time, fish, created, name)
    local data = { modData = {}, elapsed = 0 }
    function data:getModData() return self.modData end
    function data:setElapsedTime(value) self.elapsed = value end
    function data:getRecipe() return { getTime = function() return time end, getName = function() return "TraditionalPreservationFishMeat." .. (name or "PressSaltedFish") end } end
    function data:getAllInputItemsWithFlag(flag)
        assert(flag == "ItemCount", "the fish input is marked with ItemCount")
        return list(fish or {})
    end
    function data:getAllCreatedItems() return list(created or {}) end
    return data
end

local function newFood(fullType, values)
    local food = { fullType = fullType, values = values }
    for _, name in ipairs({ "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange", "ActualWeight" }) do
        food["get" .. name] = function(self) return self.values[name] or 0 end
        food["set" .. name] = function(self, value) self.values[name] = value end
    end
    function food:getFullType() return self.fullType end
    function food:getDisplayName() return self.name or self.displayName or "Fish" end
    function food:setTooltip(value) self.tooltip = value end
    function food:setUnhappyChange(value) self.unhappy = value end
    function food:setCustomWeight(value) self.customWeight = value end
    function food:isCustomWeight() return self.customWeight == true end
    function food:getModData() self.modData = self.modData or {}; return self.modData end
    function food:setName(value) self.name = value end
    function food:setCustomName(value) self.customName = value end
    function food:getModelIndex() return self.modelIndex or -1 end
    function food:setModelIndex(value) self.modelIndex = value end
    function food:hasTag(tag)
        if tag == ItemTag.SALT then return self.salt == true end
        local meat = { ["Base.Beef"] = true, ["Base.Steak"] = true, ["Base.MuttonChop"] = true, ["Base.Venison"] = true }
        return tag == ItemTag.UNCUT_FISH and self.fullType:sub(1, 5) == "Base." and self.fullType ~= "Base.FishFillet" and not meat[self.fullType]
    end
    function food:setWeight(value) self.weight = value end
    function food:getOffAge() return self.offAge or 120 end
    function food:getOffAgeMax() return self.offAgeMax or 180 end
    function food:setOffAge(value) self.offAge = value end
    function food:setOffAgeMax(value) self.offAgeMax = value end
    function food:getThirstChange() return self.thirst or 0 end
    function food:setThirstChange(value) self.thirst = value end
    function food:setAge(value) self.age = value end
    function food:getAge() return self.age or 0 end
    return food
end

local MILD = { temperature = 20, humidity = 0.4, precipitation = 0 }

-- Recipe times
onInit()
check("the press time comes from PRESS_HOURS", loaded["TraditionalPreservationFishMeat.PressSaltedFish"] == "{ time = " .. T.PRESS_HOURS * 3600 .. ", }")
check("the drying time comes from DRY_HOURS", loaded["TraditionalPreservationFishMeat.HangFishToDry"] == "{ time = " .. T.DRY_HOURS * 3600 .. ", }")

-- Rates
check("freezing air dries nothing", T.temperatureRate(-5) == 0 and T.temperatureRate(0) == 0)
check("10 C matches vanilla's squared curve", near(T.temperatureRate(10), 0.25))
check("20 C is the top rate, so heat can't beat 12 days", T.temperatureRate(20) == 1 and T.temperatureRate(55) == 1)
check("dry air is full speed", T.airRate(0.3) == 1 and T.airRate(0.5) == 1)
check("saturated air is the slowest", near(T.airRate(1), T.DAMP_AIR_RATE))
check("damp air falls between", T.airRate(0.75) < 1 and T.airRate(0.75) > T.DAMP_AIR_RATE)

-- Ledger
local ledger = T.newLedger(0)
T.advance(ledger, 10, MILD)
check("good weather counts hour for hour", near(ledger.open, 10))
check("a roof slows drying", near(ledger.sheltered, 10 * T.SHELTERED_RATE))

local before, beforeSheltered = ledger.open, ledger.sheltered
T.advance(ledger, 11, { temperature = 20, humidity = 0.4, precipitation = 1 })
check("rain stops open drying", ledger.open == before and ledger.wetness == 1)
check("rain doesn't reach a sheltered frame", ledger.sheltered > beforeSheltered)

T.advance(ledger, 11.5, MILD)
check("wet fish doesn't dry until the wet has gone", ledger.open == before and ledger.wetness > 0)
T.advance(ledger, 14, MILD)
check("then drying picks up again", ledger.wetness == 0 and ledger.open > before)

local snowy = T.newLedger(0)
T.advance(snowy, 1 / 6, { temperature = -2, humidity = 0.4, precipitation = 1, isSnow = true })
local rainy = T.newLedger(0)
T.advance(rainy, 1 / 6, { temperature = 5, humidity = 0.4, precipitation = 1 })
check("snow wets half as fast", near(snowy.wetness * 2, rainy.wetness))

local still = T.newLedger(5)
T.advance(still, 5, MILD)
check("no time passing changes nothing", still.open == 0)

-- Pressing
check("small fish press for a day", T.pressHours(0.3) == 24 and T.pressHours(T.PRESS_SMALL_WEIGHT) == 24)
check("fish of about a kilo or more, two", T.pressHours(T.PRESS_BIG_WEIGHT) == 48 and T.pressHours(T.SALT_WHOLE_MAX) == 48)
check("in between by weight", near(T.pressHours((T.PRESS_SMALL_WEIGHT + T.PRESS_BIG_WEIGHT) / 2), 36))

local RECIPE_TIME = T.PRESS_HOURS * 3600
local function pressed(weights)
    local fish = {}
    for i, weight in ipairs(weights) do fish[i] = newFood("TraditionalPreservationFishMeat.SaltPackedFish", { ActualWeight = weight }) end
    return newRecipeData(RECIPE_TIME, fish)
end
local press = pressed({ 0.4, 3, 0.6 })
T.onPressStart(press)
check("the heaviest fish sets the batch's hours", press.modData.pressHours == 48)
hours = hours + T.PRESS_HOURS / 2
T.onPressUpdate(press)
check("half the hours is half the press", near(press.elapsed, RECIPE_TIME / 2))
hours = hours + 100
T.onPressUpdate(press)
check("time away finishes the press, and no further", press.elapsed == RECIPE_TIME)

local small = pressed({ 0.4, 0.8 })
T.onPressStart(small)
hours = hours + 12
T.onPressUpdate(small)
check("a batch of small fish is half done in 12 hours", near(small.elapsed, RECIPE_TIME / 2))
hours = hours + 12
T.onPressUpdate(small)
check("and done in a day", near(small.elapsed, RECIPE_TIME))
local status = T.pressStatus({ pressStartHour = 100, pressHours = 24 }, 106, T.newLedger(0))
check("the popup says a small batch's own time left", near(status.hoursLeft, 18) and near(status.progress, 0.25))
check("a press from before has 12 hours", near(T.pressStatus({ pressStartHour = 100 }, 106, T.newLedger(0)).hoursLeft, 6))

-- A warm cure: above 20 C a quarter of raw fish's rate at 10 C, and as much again for each 10 degrees more
local function warmCure(season, cureHours)
    local ledger = T.newLedger(0)
    ledger.seasonTemperature = season
    T.advance(ledger, cureHours, { temperature = season, humidity = 0.4, precipitation = 0 })
    return T.cureSpoiled({ lastWarmCure = 0 }, ledger), ledger
end
check("a cool cure loses nothing", warmCure(18, 48) == 0)
check("21 C for a day costs about 14%", near(warmCure(21, 24), 1.1 * 24 * T.WARM_CURE_SHARE / T.RAW_SPOIL_HOURS))
local hotCure, hotLedger = warmCure(25, 48)
check("25 C for two days, 37.5%", near(hotCure, 0.375) and hotLedger.warmCuring)
check("the tub's popup shows it", near(T.pressStatus({ pressStartHour = 0, pressHours = 48, lastWarmCure = 0 }, 48, hotLedger).spoiled, 0.375))
check("a press from before counts from now", T.cureSpoiled({}, hotLedger) == 0)
-- The long cure wants the cold: above a 10 C season it spoils in step, rotten in a leg's 21 days at 15 C.
local function longCure(season, cureHours)
    local ledger = T.newLedger(0)
    ledger.seasonTemperature = season
    T.advance(ledger, cureHours, { temperature = season, humidity = 0.3, precipitation = 0 })
    return T.cureSpoiled({ lastWarmCure = 0, lastLongCure = 0 }, ledger), ledger, T.cureSpoiled({ lastWarmCure = 0 }, ledger)
end
local coolLong, coolLedger = longCure(10, 504)
check("a long cure at 10 C loses nothing", coolLong == 0 and not coolLedger.longCuring)
local mildLeg, mildLedger, mildShort = longCure(12, 504)
check("a leg at 12 C loses two fifths, cuts a fifth, the short cure nothing", near(mildLeg, 0.4) and near(longCure(12, 240), 0.4 * 240 / 504)
    and mildShort == 0 and mildLedger.longCuring)
check("a leg at 15 C rots in the tub, cuts lose about half", near(longCure(15, 504), 1) and near(longCure(15, 240), 240 / 504))
check("the tub's popup says a long cure is spoiling, a short one not", T.pressStatus({ pressStartHour = 0, pressHours = 504, lastWarmCure = 0, lastLongCure = 0 }, 100, mildLedger).spoiling
    and not T.pressStatus({ pressStartHour = 0, pressHours = 48, lastWarmCure = 0 }, 48, mildLedger).spoiling)
local hotPress = newRecipeData(RECIPE_TIME, { newFood("TraditionalPreservationFishMeat.SaltPackedFish", { ActualWeight = 1 }) },
    { newFood("TraditionalPreservationFishMeat.SaltPressedFish", {}) })
hotPress.modData.lastWarmCure = 0
ModData.tables[T.MOD_DATA_KEY] = hotLedger
T.onCreatePressed(hotPress)
local hotFish = hotPress:getAllCreatedItems():get(0)
check("pressed fish carries what the warm cure took", near(hotFish:getModData().cureSpoiled, 0.375) and hotFish.age > 0)
local mixed = list({ newFood("TraditionalPreservationFishMeat.SaltPressedFish", { ActualWeight = 3 }), newFood("TraditionalPreservationFishMeat.SaltPressedFish", { ActualWeight = 1 }) })
mixed:get(0):getModData().cureSpoiled = 0.4
check("a stack starts with its fish's share, by weight", near(T.stackCureSpoiled(mixed), 0.3))
ModData.tables = {}

local old = newRecipeData(RECIPE_TIME)
old.modData.pressStartHour = hours
hours = hours + 12
T.onPressUpdate(old)
check("a press from before keeps its 12 hours", near(old.elapsed, RECIPE_TIME))

press.elapsed = 0
T.onPressStart(press)
T.onPressUpdate(press)
check("a reused object starts its own run", press.elapsed == 0)

-- The tub
check("a tub takes fish up to its capacity", T.hasRoom(T.TUB_CAPACITY, T.TUB_CAPACITY - 1, 1))
check("and no more", not T.hasRoom(T.TUB_CAPACITY, T.TUB_CAPACITY - 0.5, 1))
check("a fish over the capacity never fits", not T.hasRoom(T.TUB_CAPACITY, 0, T.TUB_CAPACITY + 1))

-- The right fish for each station
check("a tub takes packed fish", T.fishRefusal(true, "TraditionalPreservationFishMeat.SaltPackedFish") == nil)
check("but not pressed or raw fish", T.fishRefusal(true, "TraditionalPreservationFishMeat.SaltPressedFish") == "IGUI_TraditionalPreservationFishMeat_NeedsPacked" and T.fishRefusal(true, "Base.Walleye") == "IGUI_TraditionalPreservationFishMeat_NeedsPacked")
check("a frame takes pressed fish", T.fishRefusal(false, "TraditionalPreservationFishMeat.SaltPressedFish") == nil)
check("but not packed fish", T.fishRefusal(false, "TraditionalPreservationFishMeat.SaltPackedFish") == "IGUI_TraditionalPreservationFishMeat_NeedsPressed")

-- The frame
check("a stack takes four fish too small to slice", T.frameRefusal(T.HANGERS[6], 0, 0.6 * 3, 0.6) == nil)
check("but not a fifth", T.frameRefusal(T.HANGERS[6], 0, 2.4, 0.6) == "IGUI_TraditionalPreservationFishMeat_StackFull")
check("a fish at the limit hangs", T.frameRefusal(T.HANGERS[6], 0, 0, 2.5) == nil)
check("and takes nothing with it", T.frameRefusal(T.HANGERS[6], 0, 2.5, 0.1) == "IGUI_TraditionalPreservationFishMeat_StackFull")
check("a heavier fish is told to slice", T.frameRefusal(T.HANGERS[6], 0, 0, 2.6) == "IGUI_TraditionalPreservationFishMeat_TooHeavy")
check("eight stacks fill the frame", T.frameRefusal(T.HANGERS[6], 7, 0, 0.1) == nil and T.frameRefusal(T.HANGERS[6], 8, 0, 0.1) == "IGUI_TraditionalPreservationFishMeat_FrameFull")
check("a full frame is 20 weight", T.STACK_WEIGHT * T.MAX_STACKS == 20)
check("every station finds its hanger, either way round", T.hangerFor(7) == T.HANGERS[6] and T.hangerFor(409) == T.HANGERS[408] and T.hangerFor(410) == T.HANGERS[410])
check("a tub has none", T.hangerFor(0) == nil and T.hangerFor(5) == nil)
check("both tiles of the Smokehouse find it, either way round", T.hangerFor(856) == T.HANGERS[856] and T.hangerFor(857) == T.HANGERS[856]
    and T.hangerFor(858) == T.HANGERS[856] and T.hangerFor(859) == T.HANGERS[856] and T.HANGERS[856].closed)
check("gutted fish hang in the open or under an open roof", T.coldRefusal("Open") == nil and T.coldRefusal("Covered") == nil)
check("not in a room, a basement or the Smokehouse", T.coldRefusal("Sheltered") == "IGUI_TraditionalPreservationFishMeat_NoColdIndoors"
    and T.coldRefusal("Basement") == "IGUI_TraditionalPreservationFishMeat_NoColdIndoors")
check("the Smokehouse takes 6 stacks of 15", T.frameRefusal(T.HANGERS[856], 5, 0, 15) == nil
    and T.frameRefusal(T.HANGERS[856], 0, 0, 15.1) == "IGUI_TraditionalPreservationFishMeat_TooHeavy"
    and T.frameRefusal(T.HANGERS[856], 6, 0, 1) == "IGUI_TraditionalPreservationFishMeat_FrameFull")
IsoFlagType = IsoFlagType or {}
-- A tiny map: squares by "x,y", each with the sprites standing on it.
local grid = {}
local function gridSquare(x, y, sprites)
    local s = { x = x, y = y, sprites = sprites or {} }
    function s:getX() return self.x end
    function s:getY() return self.y end
    function s:getZ() return 0 end
    function s:isInARoom() return self.inRoom end
    function s:getProperties() return { has = function() return false end } end
    function s:getObjects()
        local objects = {}
        for i, name in ipairs(self.sprites) do
            objects[i] = { getSprite = function() return { getName = function() return name end,
                getProperties = function() return { has = function() return true end } end } end }
        end
        return { size = function() return #objects end, get = function(_, i) return objects[i + 1] end }
    end
    grid[x .. "," .. y] = s
    return s
end
getCell = function() return { getGridSquare = function(_, x, y) return grid[x .. "," .. y] end } end
local function building(square, spriteName)
    return { square = square, tileInfo = spriteName and { getSpriteName = function() return spriteName end } }
end
local outside, inside = gridSquare(0, 0), gridSquare(10, 10)
inside.inRoom = true
check("the big beams go up outdoors or under an open roof", T.notInRoom(building(outside)))
check("not in a room", not T.notInRoom(building(inside)))
-- The Smokehouse facing S, its door's tile at 20,20: nothing goes up on 20,21, and its door needs that tile free.
gridSquare(20, 20, { T.spriteName(857) })
check("nothing is built in front of the Smokehouse's door", not T.notInRoom(building(gridSquare(20, 21))))
check("beside it is fine", T.notInRoom(building(gridSquare(21, 20))))
gridSquare(30, 31, { "a crate" })
check("the Smokehouse's door needs its front free", not T.notInRoom(building(gridSquare(30, 30), T.spriteName(857)))
    and T.notInRoom(building(gridSquare(31, 30), T.spriteName(857))))
check("the Hanging Beam goes up in a room too, but not in front of a door", T.doorFree(building(inside)) and T.doorFree(building(outside))
    and not T.doorFree(building(gridSquare(20, 21))))
for name, rule in pairs({ Medium = "doorFree", Large = "notInRoom" }) do
    local entity = io.open("42/media/scripts/entities/entity_Drying_Beam_" .. name .. ".txt"):read("*a")
    check(name .. " beam: " .. rule, entity:find("OnIsValid = TraditionalPreservationFishMeat." .. rule .. ",", 1, true) ~= nil)
end
do
    local Tiles = require "TraditionalPreservationFishMeat/Tiles"
    local medium, large = T.spriteName(408), T.spriteName(410)
    check("only the Gantry and the Smokehouse are kept out of rooms", not Tiles.OUTDOOR[medium] and Tiles.OUTDOOR[large]
        and Tiles.OUTDOOR[T.spriteName(856)] and Tiles.DOOR_KEPT[medium] and Tiles.DOOR_KEPT[large])
end
check("the frame isn't", not io.open("42/media/scripts/entities/entity_Drying_Frame.txt"):read("*a"):find("OnIsValid", 1, true))
check("sprites below the first sheet's end are on it", T.spriteName(407) == "traditionalpreservationfishmeat_01_407")
check("the rest are on the second", T.spriteName(408) == "traditionalpreservationfishmeat_02_0" and T.spriteName(711) == "traditionalpreservationfishmeat_02_303")
for _, index in ipairs({ 0, 7, 407, 408, 411, 711 }) do
    check("sprite " .. index .. " reads back", T.spriteIndex(T.spriteName(index)) == index)
end
check("other mods' sprites aren't ours", T.spriteIndex("carpentry_02_122") == nil and T.spriteIndex(nil) == nil)

-- The game drops the whole tile file if a sheet has too many tiles, and every station with it.
local tiles = io.open("42/media/traditionalpreservationfishmeat.tiles", "rb"):read("*a")
local function u32(at)
    local a, b, c, d = tiles:byte(at, at + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end
check("the tile file has all three sheets", u32(9) == 3)
local sheetCount = u32(13 + #"traditionalpreservationfishmeat_01\ntraditionalpreservationfishmeat_01.png\n" + 12)
check("the first sheet ends where the sprites say", sheetCount == T.FIRST_SHEET_SIZE and sheetCount <= 512)
check("a medium beam takes 15 a stack on 4 hooks", T.frameRefusal(T.HANGERS[408], 3, 0, 15) == nil and T.frameRefusal(T.HANGERS[408], 0, 0, 15.1) == "IGUI_TraditionalPreservationFishMeat_TooHeavy" and T.frameRefusal(T.HANGERS[408], 4, 0, 1) == "IGUI_TraditionalPreservationFishMeat_FrameFull")
check("a large beam takes 50 a stack on 2 hooks", T.frameRefusal(T.HANGERS[410], 1, 0, 50) == nil and T.frameRefusal(T.HANGERS[410], 2, 0, 1) == "IGUI_TraditionalPreservationFishMeat_FrameFull")
local FULL = "IGUI_TraditionalPreservationFishMeat_StackFull"
check("a Hanging Beam stack takes 12 pieces", T.frameRefusal(T.HANGERS[408], 0, 11, 0.5, 11) == nil
    and T.frameRefusal(T.HANGERS[408], 0, 6, 0.5, 12) == FULL)
check("a Gantry stack takes 6 pieces, however light", T.frameRefusal(T.HANGERS[410], 0, 30, 5, 5) == nil
    and T.frameRefusal(T.HANGERS[410], 0, 3, 0.5, 6) == FULL)
check("the Drying Frame and the Smokehouse keep 25", T.frameRefusal(T.HANGERS[6], 0, 0, 0.05, 24) == nil
    and T.frameRefusal(T.HANGERS[6], 0, 0, 0.05, 25) == FULL
    and T.frameRefusal(T.HANGERS[856], 0, 0, 0.5, 24) == nil and T.frameRefusal(T.HANGERS[856], 0, 0, 0.5, 25) == FULL)

-- Drying
local DRY_TIME = T.DRY_HOURS * 3600
local shared = T.getLedger()
local dry = newRecipeData(DRY_TIME)
T.onDryStart(dry)
hours = hours + T.DRY_HOURS / 2
T.advance(shared, hours, MILD)
T.onDryUpdate(dry)
check("half the time in good weather is half dry", near(dry.elapsed, DRY_TIME / 2))

T.onDryUpdate(dry)
check("updating twice doesn't count twice", near(dry.elapsed, DRY_TIME / 2))

dry.modData.sheltered = true
hours = hours + 1
T.advance(shared, hours, MILD)
local afterRoof = dry.modData.dried
T.onDryUpdate(dry)
check("a roofed frame gets the sheltered rate", near(dry.modData.dried - afterRoof, T.SHELTERED_RATE))

dry.modData.sheltered, dry.modData.covered = nil, true
hours = hours + 1
T.advance(shared, hours, MILD)
local afterCover = dry.modData.dried
T.onDryUpdate(dry)
check("an open shed dries as the open air", near(dry.modData.dried - afterCover, 1))

dry.modData.covered = nil
hours = hours + 1000
T.advance(shared, hours, MILD)
T.onDryUpdate(dry)
check("time unloaded counts, and stops at done", dry.elapsed == DRY_TIME)

local reused = newRecipeData(DRY_TIME)
reused.modData = { dried = 90, sheltered = true }
T.onDryStart(reused)
T.onDryUpdate(reused)
check("a reused object starts from nothing", reused.elapsed == 0 and reused.modData.sheltered == nil and reused.modData.spoiled == 0)

local stacked = newRecipeData(DRY_TIME, { newFood("TraditionalPreservationFishMeat.SaltPressedFish", {}) }, { newFood("TraditionalPreservationFishMeat.SaltDriedFish", {}) })
T.onDryStart(stacked)
T.onCreateDried(stacked)
check("dried fish remembers its stack", stacked:getAllCreatedItems():get(0):getModData().stackId == stacked.modData.stackId)

-- Sandbox options
SandboxVars = { TraditionalPreservationFishMeat = { DryDays = 24, MaxDryDays = 48, Spoilage = 4 } }
T.applySandbox()
check("salt drying days set salt drying alone", T.DRY_HOURS == 576 and T.COLD_DRY_HOURS == 768)
check("the slowest days set the lowest rate", near(T.MIN_DRY_RATE, 0.5))
check("harsh spoilage halves the limits", T.RAW_SPOIL_HOURS == 24 and T.SALT_SPOIL_HOURS == 240)
check("the under-salted and the long cure's too", T.UNDER_CURE_HOURS == 336 and T.LONG_CURE_ROT_HOURS == 252
    and near(T.underCureRate(10) * 336, 1))
SandboxVars.TraditionalPreservationFishMeat = { ColdDryDays = 90, MatureDays = 30, PressDays = 4 }
T.applySandbox()
check("stockfish drying has its own days", T.COLD_DRY_HOURS == 2160)
check("and maturing", T.MATURE_DAYS == 30)
check("press days set the big fish's time, small fish half of it", T.PRESS_HOURS == 96 and T.PRESS_MIN_HOURS == 48
    and T.pressHours(5) == 96 and T.pressHours(0.5) == 48)
SandboxVars.TraditionalPreservationFishMeat = { DryDays = 30, MaxDryDays = 10, Spoilage = 1 }
T.applySandbox()
check("the slowest can't beat the fastest", T.MIN_DRY_RATE == 1)
check("spoilage can be turned off", T.RAW_SPOIL_HOURS == math.huge and T.SALT_SPOIL_HOURS == math.huge and T.FREEZE_DAMAGE_HOURS == math.huge and T.WET_DAMAGE_HOURS == math.huge)
do
    local off = T.newLedger(0)
    off.seasonTemperature = 25
    T.advance(off, 500, { temperature = 25, humidity = 0.3, precipitation = 0 })
    check("off, Corned meat in the shed and a warm long cure lose nothing", T.underCureRate(25) == 0 and off.underCure == 0
        and off.underCureBanked == 0 and off.underCureBasement == 0 and off.longCureSpoil == 0
        and T.cureSpoiled({ lastWarmCure = 0, lastLongCure = 0 }, off) == 0)
end
SandboxVars.TraditionalPreservationFishMeat = { DryDays = 30, MaxDryDays = 10, Spoilage = 9 }
check("a spoilage value out of range loads as normal", pcall(T.applySandbox) and T.RAW_SPOIL_HOURS == 48 and T.SALT_SPOIL_HOURS == 480)
SandboxVars.TraditionalPreservationFishMeat = { DryDays = 12, MaxDryDays = 27, ColdDryDays = 32, MatureDays = 60, PressDays = 2, Spoilage = 3 }
T.applySandbox()
check("the defaults put it all back", T.DRY_HOURS == 288 and T.COLD_DRY_HOURS == 768 and T.MATURE_DAYS == 60
    and T.PRESS_HOURS == 48 and T.PRESS_MIN_HOURS == 24 and T.RAW_SPOIL_HOURS == 48 and T.SALT_SPOIL_HOURS == 480
    and T.UNDER_CURE_HOURS == 672 and T.LONG_CURE_ROT_HOURS == 504)
SandboxVars = nil

-- What a stack's popup reports
local readings = T.newLedger(0)
T.advance(readings, 1, { temperature = 0, humidity = 0.2, precipitation = 0 })
local coldNow = T.stackStatus(true, { dried = 192 }, readings)
check("cold fish dries at full rate in the cold", coldNow.rate == 1 and near(coldNow.hoursLeft, 576) and near(coldNow.progress, 0.25))
local saltNow = T.stackStatus(false, { dried = 144 }, readings)
check("salt fish goes by its own rate", near(saltNow.rate, T.MIN_DRY_RATE) and near(saltNow.hoursLeft, 144 / T.MIN_DRY_RATE))
check("indoors stops cold drying but not salt", T.stackStatus(true, { sheltered = true }, readings).reason == "Roof" and T.stackStatus(false, { sheltered = true }, readings).reason == nil)
local rained = T.newLedger(0)
T.advance(rained, 1, { temperature = 3, humidity = 0.3, precipitation = 1 })
check("rain pauses both", T.stackStatus(true, {}, rained).reason == "Rain" and T.stackStatus(false, {}, rained).reason == "Rain" and T.stackStatus(true, {}, rained).hoursLeft == nil)
local shedCold, shedSalt = T.stackStatus(true, { covered = true }, rained), T.stackStatus(false, { covered = true }, rained)
check("an open shed keeps the rain off both", shedCold.reason == nil and near(shedCold.rate, T.coldRate(3) * T.windRate(nil) * T.COVERED_COLD_RATE)
    and shedSalt.reason == nil and shedSalt.rate > 0)
local hot = T.newLedger(0)
hot.seasonTemperature, hot.seasonHumidity = 25, 0.6
T.advance(hot, 1, { temperature = 25, humidity = 0.6, precipitation = 0 })
check("a warm season stops cold drying and warns", T.stackStatus(true, {}, hot).reason == "TooWarm" and T.stackStatus(true, {}, hot).spoiling)
check("a muggy one warns for salt fish", T.stackStatus(false, {}, hot).spoiling)
check("a fresh ledger is safe to read", T.stackStatus(false, {}, T.newLedger(0)).rate == 0)
local heatWave = T.newLedger(0)
T.advance(heatWave, 1, { temperature = 30, humidity = 0.3, precipitation = 0 })
check("hot sun warns for fresh salt fish in the open", T.stackStatus(false, { dried = 0 }, heatWave).scorching)
check("not in the shade, nor once it is half dry", not T.stackStatus(false, { dried = 0, covered = true }, heatWave).scorching
    and not T.stackStatus(false, { dried = 0, sheltered = true }, heatWave).scorching and not T.stackStatus(false, { dried = T.DRY_HOURS / 2 }, heatWave).scorching)
check("the popup says too hot only in the open", T.temperatureWord(false, 30, true) == "IGUI_TraditionalPreservationFishMeat_TempHot" and T.temperatureWord(false, 30, false) == "IGUI_TraditionalPreservationFishMeat_TempGoodWarm")
check("frost words for cold fish", T.temperatureWord(true, -2) == "IGUI_TraditionalPreservationFishMeat_TempFrost" and T.temperatureWord(true, -8) == "IGUI_TraditionalPreservationFishMeat_TempHardFrost")
check("the words fit the method", T.temperatureWord(true, 2) == "IGUI_TraditionalPreservationFishMeat_TempGoodCold" and T.temperatureWord(false, 25) == "IGUI_TraditionalPreservationFishMeat_TempGoodWarm" and T.temperatureWord(true, 25) == "IGUI_TraditionalPreservationFishMeat_TempTooWarm")

-- Limits on how long drying takes
local slowest = T.newLedger(0)
T.advance(slowest, 100, { temperature = -5, humidity = 1, precipitation = 0 })
check("the worst dry weather still gives the slowest rate", near(slowest.open, 100 * T.MIN_DRY_RATE) and near(slowest.sheltered, 100 * T.MIN_DRY_RATE))
check("which is about 30 days at most", T.DRY_HOURS / T.MIN_DRY_RATE / 24 <= 30)
local frosted = T.newLedger(0)
T.advance(frosted, 1, { temperature = -5, humidity = 0.3, precipitation = 1, isSnow = true })
T.advance(frosted, 1000, { temperature = -5, humidity = 0.3, precipitation = 0 })
check("a frame still dries off in a hard frost", frosted.wetness == 0)

-- Cold drying
check("full rate from freezing to 5 C", T.coldRate(0) == 1 and T.coldRate(5) == 1)
check("slower in frost, slowest in hard frost", near(T.coldRate(-2.5), 0.9) and near(T.coldRate(-5), T.FROST_RATE) and T.coldRate(-15) == T.HARD_FROST_RATE)
check("slower near the limit", near(T.coldRate(10), T.COLD_MIN_RATE))
check("stops above the limit", T.coldRate(11) == 0)
local snowfall = T.newLedger(0)
T.advance(snowfall, 1, { temperature = -2, humidity = 0.3, precipitation = 1, isSnow = true })
check("snow doesn't stop it", near(snowfall.cold, T.coldRate(-2)) and snowfall.open == 0 and snowfall.coldWetness == 0)
local rainfall = T.newLedger(0)
T.advance(rainfall, 1, { temperature = 3, humidity = 0.3, precipitation = 1 })
check("rain does", rainfall.cold == 0 and rainfall.coldWetness > 0)
T.advance(rainfall, 2, { temperature = 3, humidity = 0.3, precipitation = 0 })
check("and the fish has to dry off first", rainfall.cold == 0 and rainfall.coldWet == 2)
T.advance(rainfall, 100, { temperature = 3, humidity = 0.3, precipitation = 0 })
check("then it dries again", rainfall.coldWetness == 0 and rainfall.cold > 0)

-- Wind
check("still air halves it", T.windRate(0) == T.CALM_RATE)
check("a good breeze beats full speed", near(T.windRate(T.WIND_GOOD), T.WINDY_RATE) and near(T.windRate(1), T.WINDY_RATE))
check("in between it rises", near(T.windRate(T.WIND_GOOD / 2), (T.CALM_RATE + T.WINDY_RATE) / 2))
check("no reading leaves it alone", T.windRate(nil) == 1)
local windy = T.newLedger(0)
T.advance(windy, 10, { temperature = 2, humidity = 0.3, precipitation = 0, wind = 0 })
check("wind sets the cold rate", near(windy.cold, 10 * T.CALM_RATE) and windy.wind == 0)
check("the words for the wind", T.windWord(0.05) == "IGUI_TraditionalPreservationFishMeat_WindCalm"
    and T.windWord(0.2) == "IGUI_TraditionalPreservationFishMeat_WindLight" and T.windWord(0.5) == "IGUI_TraditionalPreservationFishMeat_WindGood")
local frosty = T.newLedger(0)
T.advance(frosty, 5, { temperature = -8, humidity = 0.3, precipitation = 0 })
check("hard frost is counted", frosty.hardFrost == 5 and frosty.coldWet == 0)

local function coldStack()
    ModData.tables = {}
    hours = 0
    local stack = newRecipeData(T.COLD_DRY_HOURS * 3600)
    T.onColdDryStart(stack)
    return stack, T.getLedger()
end

local WINTER = { temperature = 0, humidity = 0.2, precipitation = 0 }
local winterStack, winter = coldStack()
winter.seasonTemperature = 0
hours = T.COLD_DRY_HOURS / 2
T.advance(winter, hours, WINTER)
T.onColdDryUpdate(winterStack)
check("half the time in winter is half dry", near(winterStack.elapsed, T.COLD_DRY_HOURS * 3600 / 2) and winterStack.modData.spoiled == 0)

local mildStack, mild = coldStack()
mild.seasonTemperature = 0
for hour = 1, 12 do
    hours = hour
    T.advance(mild, hours, { temperature = 15, humidity = 0.2, precipitation = 0 })
end
T.onColdDryUpdate(mildStack)
check("twelve warm hours in winter spoil an open stack, by the day's (step I), not the season's", mildStack.modData.spoiled > 0
    and mild.rawSpoil == 0)

local warmStack, warm = coldStack()
warm.seasonTemperature = 20
hours = T.RAW_SPOIL_HOURS
T.advance(warm, hours, { temperature = 20, humidity = 0.4, precipitation = 0 })
T.onColdDryUpdate(warmStack)
check("a warm season rots it early", warmStack.modData.spoiled >= 1 and warmStack.elapsed == T.COLD_DRY_HOURS * 3600)

local roofedStack, roofed = coldStack()
roofed.seasonTemperature = 0
roofedStack.modData.sheltered = true
hours = 10
T.advance(roofed, hours, WINTER)
T.onColdDryUpdate(roofedStack)
check("indoors stops cold drying", roofedStack.modData.dried == 0)

local shedStack, shedLedger = coldStack()
shedLedger.seasonTemperature = 0
shedStack.modData.covered = true
hours = 10
T.advance(shedLedger, hours, WINTER)
T.onColdDryUpdate(shedStack)
check("an open shed dries cold fish at three quarters", near(shedStack.modData.dried, shedLedger.cold * T.COVERED_COLD_RATE) and shedStack.modData.dried > 0)

-- Early frost and wet add to the spoilage, the more the wetter the fish
local function coldStep(dried, totals, sheltered, covered)
    local ledger = T.newLedger(0)
    local modData = { dried = dried, spoiled = 0, lastCold = 0, lastRawSpoil = 0, lastRawSpoilOpen = 0, lastHardFrost = 0, lastColdWet = 0, sheltered = sheltered, covered = covered }
    for key, value in pairs(totals) do ledger[key] = value end
    T.coldStep(modData, ledger)
    return modData
end
check("hard frost on a fresh stack", near(coldStep(0, { hardFrost = 36 }).spoiled, T.FREEZE_DAMAGE / 2))
check("less once it has dried a little", near(coldStep(T.COLD_DRY_HOURS * 0.2, { hardFrost = 36 }).spoiled, T.FREEZE_DAMAGE / 2 * 0.8))
check("none once it is under way", coldStep(T.COLD_DRY_HOURS * 0.3, { hardFrost = 36 }).spoiled == 0)
check("frost alone never rots it", coldStep(0, { hardFrost = 1000 }).spoiled == T.DAMAGE_CAP)
check("lying wet early harms it", near(coldStep(0, { coldWet = 48 }).spoiled, T.WET_DAMAGE))
check("but not once it has a dry skin", coldStep(T.COLD_DRY_HOURS * 0.3, { coldWet = 48 }).spoiled == 0)
check("a roof keeps the rain off", coldStep(0, { coldWet = 48 }, true).spoiled == 0 and coldStep(0, { coldWet = 48 }, nil, true).spoiled == 0)
check("frost and wet together stop at the cap", coldStep(0, { hardFrost = 150, coldWet = 150 }).spoiled == T.DAMAGE_CAP)
check("rot weighs by how wet it still is, squared (the skin, step I)", near(coldStep(T.COLD_DRY_HOURS * 0.5,
    { rawSpoilOpen = T.RAW_SPOIL_HOURS }).spoiled, 0.25) and near(coldStep(T.COLD_DRY_HOURS * 0.9, { rawSpoil = T.RAW_SPOIL_HOURS },
    nil, true).spoiled, 0.01))
check("and still rots a fresh stack, in the open by the day's", near(coldStep(0, { rawSpoilOpen = T.RAW_SPOIL_HOURS }).spoiled, 1)
    and coldStep(0, { rawSpoil = T.RAW_SPOIL_HOURS }).spoiled == 0)
local older = { dried = 0, spoiled = 0, lastCold = 0, lastRawSpoil = 0 }
local olderLedger = T.newLedger(0)
olderLedger.hardFrost, olderLedger.coldWet = 500, 500
T.coldStep(older, olderLedger)
check("a cold stack from an older version starts counting frost and wet now", older.spoiled == 0 and older.lastHardFrost == 500)

-- Salt fish in summer, in the shade (hot sun has its own checks below)
local function saltStack(season, humidity)
    ModData.tables = {}
    hours = 0
    local stack = newRecipeData(T.DRY_HOURS * 3600)
    T.onDryStart(stack)
    stack.modData.covered = true
    local ledger = T.getLedger()
    ledger.seasonTemperature, ledger.seasonHumidity = season, humidity
    hours = T.SALT_SPOIL_HOURS / 2
    T.advance(ledger, hours, { temperature = season, humidity = humidity, precipitation = 0 })
    T.onDryUpdate(stack)
    return stack
end
check("a cool season leaves salt fish alone", saltStack(15, 0.6).modData.spoiled == 0)
check("so does a hot dry one", saltStack(28, 0.2).modData.spoiled == 0)
check("a hot muggy one takes half its keeping", near(saltStack(28, 0.6).modData.spoiled, 0.5))

-- Hot sun on fresh salt fish
local function saltStep(dried, heat, place)
    local ledger = T.newLedger(0)
    ledger.heat = heat
    local modData = { dried = dried, spoiled = 0, lastOpen = 0, lastSheltered = 0, lastCovered = 0, lastSaltSpoil = 0, lastHeat = 0 }
    if place then modData[place] = true end
    T.saltStep(modData, ledger)
    return modData
end
check("a day of hot sun on a fresh stack", near(saltStep(0, 24).spoiled, T.HEAT_DAMAGE))
check("less once it has dried a little", near(saltStep(T.DRY_HOURS * 0.4, 24).spoiled, T.HEAT_DAMAGE * 0.6))
check("none once it is half dry", saltStep(T.DRY_HOURS * 0.5, 24).spoiled == 0)
check("none in the shade", saltStep(0, 24, "covered").spoiled == 0 and saltStep(0, 24, "sheltered").spoiled == 0)
check("heat alone stops at the cap", saltStep(0, 10000).spoiled == T.DAMAGE_CAP)
local heatLedger = T.newLedger(0)
T.advance(heatLedger, 5, { temperature = 30, humidity = 0.3, precipitation = 0 })
T.advance(heatLedger, 10, { temperature = 24, humidity = 0.3, precipitation = 0 })
check("the ledger counts hours above 25 C", heatLedger.heat == 5)

local oldSave = newRecipeData(T.DRY_HOURS * 3600)
oldSave.modData = { dried = 10, lastOpen = 0, lastSheltered = 0 }
T.onDryUpdate(oldSave)
check("a stack from an older version carries on", oldSave.modData.spoiled == 0 and oldSave.modData.lastHeat ~= nil)

ModData.tables = { [T.MOD_DATA_KEY] = { lastHour = 5, wetness = 0, open = 3, sheltered = 2 } }
local upgraded = T.getLedger()
check("an older ledger gains the new totals", upgraded.open == 3 and upgraded.cold == 0 and upgraded.rawSpoil == 0
    and upgraded.hardFrost == 0 and upgraded.coldWet == 0 and upgraded.coldWetness == 0
    and upgraded.covered == 0 and upgraded.coldCovered == 0 and upgraded.warmCure == 0 and upgraded.heat == 0)
ModData.tables = {}

-- What the season took shows on the finished fish
local function finished(spoiled)
    local stack = newRecipeData(0, { newFood("TraditionalPreservationFishMeat.SaltPressedFish", {}) }, { newFood("TraditionalPreservationFishMeat.SaltDriedFish", {}) })
    stack.modData = { spoiled = spoiled, stackId = 1 }
    T.onCreateDried(stack)
    return stack:getAllCreatedItems():get(0)
end
check("a sound stack comes out fresh", finished(0).age == 0)
check("a part spoiled stack keeps for less", near(finished(0.25).age, 30))
check("a spoiled stack comes out rotten", finished(1).age == 180)

-- How a hanging fish looks
local seen, last = {}, 0
for step = 0, 99 do
    local stage = T.dryingStage(step / 100)
    check("the look only moves forward at " .. step .. "%", stage >= last and stage <= last + 1)
    seen[stage], last = true, stage
end
check("it passes through every running look", seen[0] and seen[1] and seen[2] and seen[3])
check("the last look waits for the finish", T.dryingStage(0.999) == T.DRYING_STAGES - 2)

-- Carrying a fish through the stages
local big = newFood("Base.Walleye", { Calories = 800, Proteins = 100, Lipids = 10, Carbohydrates = 4, BaseHunger = -0.6, HungChange = -0.6, ActualWeight = 8 })
big.displayName = "Big Walleye "
local small = newFood("Base.Bluegill", { Calories = 100, Proteins = 20, Lipids = 2, Carbohydrates = 1, BaseHunger = -0.1, HungChange = -0.1, ActualWeight = 1 })
small.displayName = "Small Bluegill "
local outBig = newFood("TraditionalPreservationFishMeat.SaltDriedFish", {})
local outSmall = newFood("TraditionalPreservationFishMeat.SaltDriedFish", {})
T.onCreateCured(newRecipeData(0, { big, small }, { outBig, outSmall }))
check("each fish keeps its own size", near(outBig.values.Calories, 720) and near(outSmall.values.Calories, 90))
check("drying takes most of the weight", near(outBig.values.ActualWeight, 3.6) and outBig.customWeight)
check("each fish keeps its own name", outBig.name == "Big Walleye (Salt Dried)" and outSmall.name == "Small Bluegill (Salt Dried)" and outBig.customName)
check("hunger shrinks with it", near(outBig.values.BaseHunger, -0.42) and near(outBig.values.HungChange, -0.42))

local whole = { Calories = 800, BaseHunger = -0.6, ActualWeight = 8 }
local item = newFood("Base.Walleye", whole)
item.displayName = "Medium Walleye "
for _, stage in ipairs({ "SaltPackedFish", "SaltPressedFish", "SaltDriedFish", "SoakedSaltFish" }) do
    local nextItem = newFood("TraditionalPreservationFishMeat." .. stage, {})
    T.carry(item, nextItem)
    item = nextItem
    if stage == "SaltPressedFish" then
        check("pressed fish keeps the walleye's icon", item.modelIndex == 6)
        check("the name follows the fish", item.name == "Medium Walleye (Salt Cured)")
        check("pressing takes 7 to 12 percent", keptShare >= 0.88 and keptShare <= 0.93 and near(item.values.ActualWeight, 8 * 0.9 * keptShare))
    end
end
check("the species survives every stage", item.name == "Medium Walleye (Soaked, Salt Dried)")
check("the fish's icon lasts to the end", item.modelIndex == 6)

-- A part-eaten fish stays part-eaten. The engine has already scaled its calories.
local bitten = newFood("Base.BlackCrappie", { Calories = 50, BaseHunger = -0.2, HungChange = -0.1, ActualWeight = 1 })
local bittenPacked = newFood("TraditionalPreservationFishMeat.SaltPackedFish", {})
T.carry(bitten, bittenPacked)
check("a part-eaten fish doesn't grow back", near(bittenPacked.values.HungChange, -0.1) and near(bittenPacked.values.BaseHunger, -0.2))
check("and keeps what's left of its calories", bittenPacked.values.Calories == 50)

-- Slicing
local function through(source, stage)
    local nextItem = newFood("TraditionalPreservationFishMeat." .. stage, {})
    T.carry(source, nextItem)
    return nextItem
end
local function slice(source, stage)
    local one, two = newFood("TraditionalPreservationFishMeat." .. stage, {}), newFood("TraditionalPreservationFishMeat." .. stage, {})
    T.onCreateSliced(newRecipeData(0, { source }, { one, two }))
    return one, two
end
local bass = newFood("Base.Walleye", { Calories = 800, Proteins = 40, Lipids = 8, Carbohydrates = 2, BaseHunger = -0.6, HungChange = -0.6, ActualWeight = 3 })
bass.displayName = "Medium Walleye "
local packedBass = through(bass, "SaltPackedFish")
check("a fish that could be cut still can be", T.canSlice(packedBass))
local pressedBass = through(packedBass, "SaltPressedFish")
local driedBass = through(pressedBass, "SaltDriedFish")
local soakedBass = through(driedBass, "SoakedSaltFish")
check("through every stage", T.canSlice(pressedBass) and T.canSlice(driedBass) and T.canSlice(soakedBass))

local tiny = newFood("Base.BlackCrappie", { BaseHunger = -0.1, HungChange = -0.1, ActualWeight = 0.6 })
local tinyPacked = through(tiny, "SaltPackedFish")
check("a fish too small to slice stays that way", not T.canSlice(tinyPacked) and not T.canSlice(through(tinyPacked, "SaltPressedFish")))
local fillet = newFood("Base.FishFillet", { BaseHunger = -0.2, HungChange = -0.2, ActualWeight = 2 })
check("a fillet can't be cut again", not T.canSlice(through(fillet, "SaltPackedFish")))
check("nor can salmon", not T.canSlice(through(newFood("Base.Salmon", { ActualWeight = 2 }), "SaltPackedFish")))
check("the knife passes", T.canSlice(newFood("Base.HuntingKnife", {})))

local one, two = slice(pressedBass, "SaltPressedFish")
check("each fillet gets half the food", near(one.values.Calories, 400) and near(two.values.Proteins, 20) and near(one.values.HungChange, -0.3))
check("and half the weight, as a cured fish has no guts to lose", near(one.values.ActualWeight, pressedBass.values.ActualWeight / 2))
check("it stays at its stage", one.name == "Fish Fillet (Salt Cured)" and one.customName)
check("it shows the fillet icon", one.modelIndex == 0)
check("it can't be cut again", not T.canSlice(one))
check("and carries on through the stages", through(one, "SaltDriedFish").name == "Fish Fillet (Salt Dried)")
local driedOne = slice(driedBass, "SaltDriedFish")
check("dried fillets show the fillet icon too", driedOne.modelIndex == 0)

local stranger = newFood("OtherMod.Fish", {})
check("a fish from another mod has no icon to keep", T.iconIndex(stranger) == -1)

-- The script's icons have to line up with FISH_ICONS, or a fish shows another's icon.
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat.txt"):read("*a")
local vanillaIcons = {
    ["Base.FishFillet"] = "FishFillet", ["Base.Salmon"] = "Salmon", ["Base.LargemouthBass"] = "Fish_BassLargemouth",
    ["Base.SmallmouthBass"] = "Fish_BassSmallmouth", ["Base.SpottedBass"] = "Fish_BassSpotted",
    ["Base.StripedBass"] = "Fish_BassStriped", ["Base.Walleye"] = "Fish_Walleye", ["Base.Sauger"] = "Fish_Sauger",
    ["Base.BlackCrappie"] = "Fish_CrappieBlack", ["Base.WhiteCrappie"] = "Fish_CrappieWhite",
    ["Base.Bluegill"] = "Fish_Bluegill", ["Base.RedearSunfish"] = "Fish_SunfishRedear",
    ["Base.GreenSunfish"] = "Fish_SunfishGreen", ["Base.BlueCatfish"] = "Fish_CatfishBlue",
    ["Base.ChannelCatfish"] = "Fish_CatfishChannel", ["Base.FlatheadCatfish"] = "Fish_CatfishFlathead",
    ["Base.Muskellunge"] = "Fish_Muskellunge", ["Base.WhiteBass"] = "Fish_BassWhite",
    ["Base.YellowPerch"] = "Fish_PerchYellow", ["Base.FreshwaterDrum"] = "Fish_DrumFreshwater",
    ["Base.AligatorGar"] = "Fish_GarAlligator", ["Base.Paddlefish"] = "Fish_Paddlefish",
}
check("nothing relies on IsWholeFoodItem", not script:find("flags%[[^%]]*IsWholeFoodItem"))
local function vanillaName(icon)
    local prefix, rest = icon:match("^(%a+)_(.+)$")
    if prefix and prefix ~= "Fish" then return rest end
    return icon
end
local lists = 0
for list in script:gmatch("IconsForTexture = ([^,]+),") do
    lists = lists + 1
    local position = 0
    for icon in list:gmatch("[^;]+") do
        position = position + 1
        local fullType = T.FISH_ICONS[(position - 1) % #T.FISH_ICONS + 1]
        local vanillaIcon = vanillaName(icon)
        check("icon " .. position .. " of list " .. lists, vanillaIcons[fullType] == vanillaIcon)
        if icon ~= vanillaIcon then
            local file = io.open("42/media/textures/Item_" .. icon .. ".png", "rb")
            check(icon .. " has its image", file ~= nil)
            if file then file:close() end
        end
    end
    check("the list covers every fish, once or three times", position == #T.FISH_ICONS or position == #T.FISH_ICONS * 3)
end
check("all ten stages have the list (Hot Smoked 5c, Cold Smoked 5d)", lists == 10)

-- Each model list runs in the same order as the icons, and every model exists.
local models = io.open("42/media/scripts/TraditionalPreservationFishMeat_models.txt"):read("*a")
local modelLists = 0
for list in script:gmatch("WorldStaticModelsByIndex = ([^,]+),") do
    modelLists = modelLists + 1
    local position = 0
    for model in list:gmatch("[^;]+") do
        position = position + 1
        local name = model:gsub("^TraditionalPreservationFishMeat%.", "")
        if (position - 1) % #T.FISH_ICONS >= 2 then
            local icon = vanillaIcons[T.FISH_ICONS[(position - 1) % #T.FISH_ICONS + 1]]
            check(name .. " is in place", name:sub(-#icon - 1) == "_" .. icon)
            check(name .. " is defined", models:find("model " .. name .. "\n", 1, true) ~= nil)
            local file = io.open("42/media/textures/FishModels/" .. name .. ".png", "rb")
            check(name .. " has its texture", file ~= nil)
            if file then file:close() end
        else
            check(name .. " is defined", script:find("model " .. name .. "\n", 1, true) ~= nil)
        end
    end
    check("the model list covers every fish, once or three times", position == #T.FISH_ICONS or position == #T.FISH_ICONS * 3)
end
check("all ten stages have models (Hot Smoked 5c, Cold Smoked 5d)", modelLists == 10)

local headBody = script:match("item FishHead\n    {(.-)\n    }")
check("a head spoils like fresh fish", headBody:find("DaysFresh = 3,", 1, true) and headBody:find("DaysTotallyRotten = 6,", 1, true))
check("and is a little unpleasant to eat", headBody:find("UnhappyChange = 5,", 1, true) ~= nil and not headBody:find("RemoveUnhappinessWhenCooked", 1, true))
check("no drying recipe takes a head", not script:find("FishHead", (script:find("craftRecipe PressSaltedFish", 1, true)), true))
-- Design decision (user, 2026-11-13): every stock, and the soups and stews made from them, starts at -10
-- unhappiness and -10 boredom, at hunger -5 (vanilla's soups and stews start at 0). A balance pass that changes them has to change this test, on the
-- user's word.
do
local both = script .. io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
local STOCKS = { FishHead = { "PotOfFishHeadStock", "PotForgedFishHeadStock", 7 }, BoneBroth = { "PotOfBoneBroth", "PotForgedBoneBroth", 7 },
    Chicken = { "PotOfChickenStock", "PotForgedChickenStock", 7 } }
local bowlRecipes = {}
for _, n in ipairs({ "4", "2" }) do bowlRecipes[n] = script:match("craftRecipe MakeFishHeadStock" .. n .. "Bowls\n    {(.-)\n    }\n") end
local function checkPot(pot, minutes, bowl)
    local body = both:match("item " .. pot .. "\n    {(.-)\n    }")
    check(pot .. " starts at -10 unhappiness, -10 boredom, hunger -5 (design decision)", body
        and tonumber(body:match("UnhappyChange = (%-?%d+)")) == -10 and tonumber(body:match("BoredomChange = (%-?%d+)")) == -10
        and body:find("HungerChange = -5.0,", 1, true))
    check(pot .. " keeps 3 / 5 days and cooks " .. minutes .. " minutes", body:find("DaysFresh = 3,", 1, true) and body:find("MinutesToCook = " .. minutes .. ",", 1, true))
    for n, recipe in pairs(bowlRecipes) do
        check(pot .. " divides into " .. n .. " " .. bowl .. "s", recipe:find("Base." .. bowl .. "Clay = TraditionalPreservationFishMeat." .. pot .. ",", 1, true) ~= nil)
    end
end
for kind, stock in pairs(STOCKS) do
    for index = 1, 2 do
        checkPot(stock[index], 70, "SoupBowl")
        for _, dish in ipairs({ "Soup", "Stew" }) do
            local forged = index == 2 and "Forged" or ""
            local result = (index == 2 and "PotForged" or "PotOf") .. kind .. dish
            checkPot(result, dish == "Soup" and 50 or 70, dish .. "Bowl")
            local evolved = both:match("evolvedrecipe " .. kind .. dish .. forged .. "\n    {(.-)\n    }")
            check(kind .. dish .. forged .. " turns the stock into " .. result, evolved
                and evolved:find("BaseItem = TraditionalPreservationFishMeat." .. stock[index] .. ",", 1, true)
                and evolved:find("ResultItem = TraditionalPreservationFishMeat." .. result .. ",", 1, true)
                and evolved:find("Template = " .. dish .. ",", 1, true) and evolved:find("MaxItems = " .. stock[3] .. ",", 1, true))
        end
    end
end
for recipeName, bones in pairs({ MakeBoneBroth = "item 2 [Base.AnimalBone] mode:keep", MakeMarrowBoneBroth = "item 1 [Base.LargeAnimalBone] mode:keep",
        MakeSmallBoneBroth = "item 6 [Base.SmallAnimalBone] mode:keep" }) do
    local recipe = both:match("craftRecipe " .. recipeName .. "\n    {(.-)\n    }\n")
    check(recipeName .. " keeps its bones and refuses boiled ones", recipe and recipe:find(bones, 1, true)
        and recipe:find("OnTest = TraditionalPreservationFishMeat.canBoil,", 1, true) and recipe:find("-fluid 1.5 categories[Water]", 1, true))
end
end

for _, name in ipairs({ "SaltPackedFish", "SaltPressedFish", "GuttedFish", "FishHalf", "FishHead" }) do
    local body = script:match("item " .. name .. "\n    {(.-)\n    }")
    check(name .. " is dangerous uncooked", body:find("DangerousUncooked = true", 1, true) ~= nil)
end
for _, name in ipairs({ "SaltDriedFish", "ColdDriedFish", "SoakedSaltFish", "SoakedColdFish" }) do
    local body = script:match("item " .. name .. "\n    {(.-)\n    }")
    check(name .. " is safe", body:find("DangerousUncooked", 1, true) == nil)
end
check("soaking gives back most of the weight", item.values.ActualWeight > 5 and item.values.ActualWeight < 8)
check("the full process keeps most of the calories", near(item.values.Calories, 720))

local coldFish = newFood("Base.Walleye", { Calories = 800, BaseHunger = -0.6, ActualWeight = 10 })
coldFish.displayName = "Medium Walleye "
coldFish = through(coldFish, "GuttedFish")
check("gutting takes the guts and head, a fifth of the weight", near(coldFish.values.ActualWeight, 8) and coldFish.name == "Gutted Medium Walleye")
check("and the head's share of the food", near(coldFish.values.Calories, 752) and near(coldFish.values.BaseHunger, -0.564))
coldFish = through(coldFish, "ColdDriedFish")
check("cold drying leaves about a fifth of the weight", near(coldFish.values.ActualWeight, 1.76) and coldFish.name == "Walleye Stockfish (Matured)")
local soakedCold = newFood("TraditionalPreservationFishMeat.SoakedColdFish", {})
T.onCreateSoaked(newRecipeData(0, { coldFish }, { soakedCold }))
coldFish = soakedCold
check("soaking gives back about 60%", near(coldFish.values.ActualWeight, 5.28) and near(coldFish.values.Calories, 714.4))
check("and the bulk drying took", near(coldFish.values.BaseHunger, -0.564))
check("and says it was cold dried", coldFish.name == "Walleye Stockfish (Soaked)")
local spawned = newFood("TraditionalPreservationFishMeat.SaltDriedFish", { ActualWeight = 1 })
spawned.displayName = "Salt Dried Fish"
spawned = through(spawned, "SoakedSaltFish")
check("a spawned dried fish keeps the plain item name", spawned.name == nil and spawned:getModData().fishName == nil)

-- Guts
local gutsMade = {}
local inventory = { AddItem = function(_, item) table.insert(gutsMade, item) end }
function inventory:getAllTagRecurse(tag, found) return found end
ArrayList = { new = function()
    local items = {}
    local found = list(items)
    function found:add(item) table.insert(items, item) end
    return found
end }
local gutter = { getInventory = function() return inventory end }
function instanceItem(fullType) return newFood(fullType, {}) end
local function gut(fish, stage)
    gutsMade = {}
    local output = newFood("TraditionalPreservationFishMeat." .. stage, {})
    T.onCreateGutted(newRecipeData(0, { fish }, { output }), gutter)
    return output
end
local walleye = newFood("Base.Walleye", { ActualWeight = 4, BaseHunger = -0.5, HungChange = -0.5, Calories = 400, Proteins = 80 })
walleye.displayName, walleye.age = "Medium Walleye ", 1.5
local gutted = gut(walleye, "GuttedFish")
check("gutting gives guts, then a head", #gutsMade == 2 and gutsMade[1].fullType == "Base.FishGuts" and gutsMade[2].fullType == "TraditionalPreservationFishMeat.FishHead")
check("the guts are a tenth of the fish, by weight and hunger", near(gutsMade[1].values.ActualWeight, 0.4) and near(gutsMade[1].weight, 0.4) and near(gutsMade[1].values.HungChange, -0.05))
check("and keep their own nutrition", gutsMade[1].values.Calories == nil and gutsMade[1].values.Proteins == nil)
local head = gutsMade[2]
check("the head is a tenth of the weight", near(head.values.ActualWeight, 0.4) and near(head.weight, 0.4) and head.customWeight)
check("and 6 percent of the food", near(head.values.Calories, 24) and near(head.values.Proteins, 4.8) and near(head.values.HungChange, -0.03) and near(head.values.BaseHunger, -0.03))
check("which the fish lost", near(gutted.values.Calories, 376) and near(gutted.values.Proteins, 75.2) and near(gutted.values.HungChange, -0.47))
check("the head is named for its fish, and keeps its age", head.name == "Medium Walleye Head" and head.age == 1.5)
check("the fish lost the guts' and head's weight", near(gutted.values.ActualWeight, 3.2))
local packedWhole = gut(newFood("Base.Walleye", { ActualWeight = 4, Calories = 400 }), "SaltPackedFish")
check("packing a whole fish guts it but keeps the head", #gutsMade == 1 and near(packedWhole.values.ActualWeight, 3.6) and near(packedWhole.values.Calories, 400))
gut(newFood("Base.Bluegill", { ActualWeight = 0.9 }), "GuttedFish")
check("a fish too small for a head still gives guts", #gutsMade == 1 and gutsMade[1].fullType == "Base.FishGuts")
gut(newFood("Base.Bluegill", { ActualWeight = T.HEAD_MIN_WEIGHT }), "GuttedFish")
check("the head limit is above, not at", #gutsMade == 1)
local packedFillet = gut(newFood("Base.FishFillet", { ActualWeight = 4 }), "SaltPackedFish")
check("a fillet has no guts and keeps its weight", #gutsMade == 0 and near(packedFillet.values.ActualWeight, 4))
local tinyGutted = gut(newFood("Base.Bluegill", { ActualWeight = 0.5 }), "GuttedFish")
check("nor has a fish too small for vanilla to cut", #gutsMade == 0 and near(tinyGutted.values.ActualWeight, 0.5))
gut(newFood("Base.Salmon", { ActualWeight = 2 }), "GuttedFish")
check("nor has salmon, which comes cut", #gutsMade == 0)
local gutPacked = gut(gutted, "SaltPackedFish")
check("a gutted fish can't give guts or a head twice", #gutsMade == 0 and near(gutPacked.values.ActualWeight, 3.2))

-- Fish Head Stock
local stockHead = newFood("TraditionalPreservationFishMeat.FishHead", { Calories = 24, Proteins = 4.8, BaseHunger = -0.03, HungChange = -0.03 })
local stock = newFood("TraditionalPreservationFishMeat.PotOfFishHeadStock", { Calories = 60, BaseHunger = -0.05, HungChange = -0.05 })
function stock:addExtraItem(fullType) self.extras = self.extras or {}; table.insert(self.extras, fullType) end
local pot = newFood("Base.Pot", {})
T.onCreateHeadStock(newRecipeData(0, { pot, stockHead }, { stock }))
check("the stock carries the head's food", near(stock.values.Calories, 24) and near(stock.values.Proteins, 4.8))
check("but not its hunger: every stock reads -5", near(stock.values.BaseHunger, -0.05) and near(stock.values.HungChange, -0.05))
check("and lists the head as an ingredient", stock.extras and #stock.extras == 1 and stock.extras[1] == "TraditionalPreservationFishMeat.FishHead")

do
-- Bone Broth: two Animal Bones, one Large or six Small, about 80 kcal; the bones come back boiled
local function newBone(fullType) local bone = newFood(fullType, {}); function bone:getHungChange() return 0 end; return bone end
local boneBroth = newFood("TraditionalPreservationFishMeat.PotOfBoneBroth", { Calories = 80, BaseHunger = -0.05, HungChange = -0.05 })
function boneBroth:addExtraItem(fullType) self.extras = self.extras or {}; table.insert(self.extras, fullType) end
local bones = { newBone("Base.AnimalBone"), newBone("Base.AnimalBone") }
check("a fresh bone can make stock", T.canBoil(bones[1]) and T.canBoil(newFood("Base.Pot", {})))
T.onCreateBoneBroth(newRecipeData(0, bones, { boneBroth }))
check("two bones give about 80 kcal, mostly protein", near(boneBroth.values.Calories, 80) and near(boneBroth.values.Proteins, 10) and near(boneBroth.values.Lipids, 3))
check("and no more hunger than the broth's", near(boneBroth.values.HungChange, -0.05))
check("it lists one bone icon, as Fish Head Stock lists its head", boneBroth.extras and #boneBroth.extras == 1 and boneBroth.extras[1] == "TraditionalPreservationFishMeat.BoneBrothIngredient")
check("the bones come back boiled", bones[1]:getModData().boiled and bones[2].name == "Boiled AnimalBone" and bones[2].customName)
check("a boiled bone makes no more stock", not T.canBoil(bones[1]))
local marrow = newFood("TraditionalPreservationFishMeat.PotOfBoneBroth", { BaseHunger = -0.05, HungChange = -0.05 })
function marrow:addExtraItem() end
T.onCreateBoneBroth(newRecipeData(0, { newBone("Base.LargeAnimalBone") }, { marrow }))
check("a Large bone's marrow gives more", near(marrow.values.Calories, 150) and near(marrow.values.Lipids, 12))
local small = newFood("TraditionalPreservationFishMeat.PotOfBoneBroth", { BaseHunger = -0.05, HungChange = -0.05 })
function small:addExtraItem() end
local smalls = {}
for i = 1, 6 do smalls[i] = newBone("Base.SmallAnimalBone") end
T.onCreateBoneBroth(newRecipeData(0, smalls, { small }))
check("six Small bones give what two Animal Bones do", near(small.values.Calories, 80) and near(small.values.Proteins, 10) and near(small.values.Lipids, 3))

-- Smashing a boiled bone gives boiled pieces
T.hookSmashBone()
check("Smash Bone gets the OnCreate under its own name, so it keeps its translation", loaded["SmashBone"] == "{ OnCreate = TraditionalPreservationFishMeat.onCreateSmashedBone, }")
local function smashData(input, pieces)
    local data = newRecipeData(0, {}, pieces)
    function data:getAllInputItems() return list({ newFood("Base.Hammer", {}), input }) end
    return data
end
local pieces = { newBone("Base.SmallAnimalBone"), newBone("Base.SmallAnimalBone") }
T.onCreateSmashedBone(smashData(bones[1], pieces))
check("a boiled bone smashes into boiled pieces", pieces[1]:getModData().boiled and pieces[2]:getModData().boiled and not T.canBoil(pieces[1]))
local freshPieces = { newBone("Base.SmallAnimalBone"), newBone("Base.SmallAnimalBone") }
T.onCreateSmashedBone(smashData(newBone("Base.AnimalBone"), freshPieces))
check("a fresh bone smashes into fresh pieces", T.canBoil(freshPieces[1]) and not freshPieces[1]:getModData().boiled)

-- Chicken Stock: a foot gives its gelatin, a head a little, no hunger, and all are listed
local poultry = newFood("TraditionalPreservationFishMeat.PotOfChickenStock", { Calories = 140, BaseHunger = -0.05, HungChange = -0.05 })
function poultry:addExtraItem(fullType) self.extras = self.extras or {}; table.insert(self.extras, fullType) end
local foot = newFood("Base.ChickenFoot", { Calories = 70, Proteins = 16, Lipids = 14, Carbohydrates = 17, BaseHunger = -0.12, HungChange = -0.12 })
local hen = newFood("Base.Chicken_Hen_Brown_Head", {})
T.onCreateChickenStock(newRecipeData(0, { foot, hen }, { poultry }))
check("a foot and a head give 50 kcal", near(poultry.values.Calories, 50) and near(poultry.values.Proteins, 9) and near(poultry.values.Lipids, 1.8) and near(poultry.values.Carbohydrates, 0))
check("and no hunger: every stock reads -5", near(poultry.values.HungChange, -0.05) and near(poultry.values.BaseHunger, -0.05))
check("it lists one chicken icon, not its parts", poultry.extras and #poultry.extras == 1 and poultry.extras[1] == "TraditionalPreservationFishMeat.ChickenStockIngredient")

end

-- Ingredient stand-ins
ISAddItemInRecipe = { complete = function() return true end }
function require() end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatEvolved.lua")
local listed = { "TraditionalPreservationFishMeat.FishHead", "Base.Carrots", "TraditionalPreservationFishMeat.GuttedFish", "TraditionalPreservationFishMeat.SoakedColdFish" }
local extras = { size = function() return #listed end, get = function(_, i) return listed[i + 1] end, set = function(_, i, v) listed[i + 1] = v end }
T.useStandins({ getExtraItems = function() return extras end })
check("fish stages in a dish become stand-ins", listed[3] == "TraditionalPreservationFishMeat.GuttedFishIngredient" and listed[4] == "TraditionalPreservationFishMeat.SoakedColdFishIngredient")
check("everything else stays", listed[1] == "TraditionalPreservationFishMeat.FishHead" and listed[2] == "Base.Carrots")
-- Both item scripts: the meat stages are in their own file.
local bothScripts = script .. io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
-- In a fixed order, so the output is the same on every run.
local standinTypes = {}
for fullType in pairs(T.INGREDIENT_STANDINS) do table.insert(standinTypes, fullType) end
table.sort(standinTypes)
for _, fullType in ipairs(standinTypes) do
    local standin = T.INGREDIENT_STANDINS[fullType]
    local stage, name = fullType:match("%.(.+)$"), standin:match("%.(.+)$")
    local body = bothScripts:match("item " .. stage .. "\n    {(.-)\n    }")
    local standinBody = bothScripts:match("item " .. name .. "\n    {(.-)\n    }")
    check(name .. " exists with its stage's icon", standinBody and standinBody:find("Icon = " .. stage .. ",", 1, true) ~= nil)
    check(name .. " can't go into a dish itself", not standinBody:find("EvolvedRecipe =", 1, true))
    check(stage .. " goes into dishes", body:find("EvolvedRecipe =", 1, true) ~= nil)
end

-- Fish Head Stock names
H.texts.ContextMenu_EvolvedRecipe_FishHeadSoup = "Fish Head Soup"
H.texts.ContextMenu_EvolvedRecipe_and = "and"
H.texts.ContextMenu_EvolvedRecipe_comma = ","
local FOODS = {
    ["TraditionalPreservationFishMeat.FishHead"] = { "Fish", "Fish Head", "Fish" },
    ["TraditionalPreservationFishMeat.GuttedFishIngredient"] = { "Fish", "Gutted Fish", "Fish" },
    ["Base.Carrots"] = { "Vegetables", "Carrots" }, ["Base.Potato"] = { "Vegetables", "Potato" },
    ["Base.Rabbitmeat"] = { "Game", "Rabbit Meat" }, ["Base.Rice"] = { "Rice", "Rice" }, ["Base.Mushroom"] = { "Mushroom", "Mushroom" },
    ["Base.Pepper"] = { "NoExplicit", "Pepper" }, ["Base.Salt"] = { "NoExplicit", "Salt" },
}
for _, t in ipairs({ "Vegetables", "Game", "Rice", "Mushroom", "Fish" }) do H.texts["ContextMenu_FoodType_" .. t] = t end
function isItemFood(t) return FOODS[t] ~= nil end
function hasItemTag(t) return t == "Base.Salt" end
ItemTag.MINOR_INGREDIENT = "minor"
function getItemFoodType(t) return FOODS[t][1] end
function getItemDisplayName(t) return FOODS[t][2] end
function getItemEvolvedRecipeName(t) return FOODS[t][3] end
local function javaList(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
local recipe = { getUntranslatedName = function() return "FishHeadSoup" end }
local function stockNamed(extras, spices)
    return T.stockName({ getExtraItems = function() return javaList(extras) end, getSpices = function() return spices and javaList(spices) end }, recipe)
end
check("the head alone leaves the name be", stockNamed({ "TraditionalPreservationFishMeat.FishHead" }) == nil)
check("a fish is named after the soup", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "TraditionalPreservationFishMeat.GuttedFishIngredient" }) == "Fish Head Soup with Fish")
check("two kinds join with and", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "TraditionalPreservationFishMeat.GuttedFishIngredient", "Base.Carrots" }) == "Fish Head Soup with Fish and Carrots")
check("two vegetables become Vegetables", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots", "Base.Potato" }) == "Fish Head Soup with Vegetables")
check("three kinds use a comma", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice" }) == "Fish Head Soup with Carrots, Rabbit Meat and Rice")
check("more than three is just the soup", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice", "Base.Mushroom" }) == "Fish Head Soup")
check("a seasoning is named while there's room", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots" }, { "Base.Pepper" }) == "Fish Head Soup with Carrots and Pepper")
check("minor seasonings such as salt aren't", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots" }, { "Base.Salt" }) == "Fish Head Soup with Carrots")
check("seasonings drop out past three", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice" }, { "Base.Pepper" }) == "Fish Head Soup with Carrots, Rabbit Meat and Rice")
do
H.texts.ContextMenu_EvolvedRecipe_ChickenStew = "Chicken Stew"
FOODS["Base.ChickenFoot"] = { "NoExplicit", "Chicken Foot" }
FOODS["Base.Turkey_Hen_Head"] = { "NoExplicit", "Turkey Head" }
local poultryRecipe = { getUntranslatedName = function() return "ChickenStew" end }
local function poultryNamed(extras)
    return T.stockName({ getExtraItems = function() return javaList(extras) end, getSpices = function() return nil end }, poultryRecipe)
end
FOODS["TraditionalPreservationFishMeat.ChickenStockIngredient"] = { "NoExplicit", "Chicken Stock" }
check("a Chicken Stew's stock icon leaves the name be", poultryNamed({ "TraditionalPreservationFishMeat.ChickenStockIngredient" }) == nil)
check("and isn't named with what went in", poultryNamed({ "TraditionalPreservationFishMeat.ChickenStockIngredient", "Base.Carrots" }) == "Chicken Stew with Carrots")
check("nor are an older pot's feet and heads", poultryNamed({ "Base.ChickenFoot", "Base.Turkey_Hen_Head", "Base.Carrots" }) == "Chicken Stew with Carrots")

-- Stock bowls are named after the stock, not the pot
H.texts.Tooltip_food_Bowl = "Bowl of %1"
H.texts.ContextMenu_EvolvedRecipe_BoneBroth = "Bone Broth"
local function bowlsFrom(potName)
    local pot = newFood("TraditionalPreservationFishMeat.PotOfBoneBroth", {})
    function pot:getDisplayName() return potName end
    local bowls = { newFood("Base.StewBowl", {}), newFood("Base.StewBowl", {}), newFood("Base.Pot", {}) }
    T.onCreateStockBowls(newRecipeData(0, { newFood("Base.Bowl", {}), pot }, bowls))
    return bowls
end
local savedName = getItemNameFromFullType
function getItemNameFromFullType(fullType)
    if fullType == "TraditionalPreservationFishMeat.PotOfBoneBroth" then return "Pot of Bone Broth" end
    return savedName(fullType)
end
local plain = bowlsFrom("Pot of Bone Broth")
check("a plain stock's bowls are Bowl of Bone Broth", plain[1].name == "Bowl of Bone Broth" and plain[2].name == "Bowl of Bone Broth" and plain[1].customName)
check("the pot keeps its name", plain[3].name == nil)
check("a named stock's bowls keep its name", bowlsFrom("Bone Broth with Carrots")[1].name == "Bowl of Bone Broth with Carrots")
getItemNameFromFullType = savedName
end
check("a second head added as an ingredient is named", stockNamed({ "TraditionalPreservationFishMeat.FishHead", "TraditionalPreservationFishMeat.FishHead" }) == "Fish Head Soup with Fish")

-- The stock's first soup or stew: vanilla makes a fresh pot, with no mood and no listed parts; they come back
do
local function moodItem(fullType, unhappy, boredom, extras)
    local item = { fullType = fullType, unhappy = unhappy, boredom = boredom, list = extras }
    function item:getFullType() return self.fullType end
    function item:getUnhappyChangeUnmodified() return self.unhappy end
    function item:getBoredomChangeUnmodified() return self.boredom end
    function item:setUnhappyChange(x) self.unhappy = x end
    function item:setBoredomChange(x) self.boredom = x end
    function item:isCustomName() return false end
    function item:setName(x) self.name = x end
    function item:getSpices() return nil end
    function item:getExtraItems()
        local list = self.list
        return { size = function() return #list end, get = function(_, i) return list[i + 1] end,
            clear = function() for i = #list, 1, -1 do list[i] = nil end end }
    end
    function item:addExtraItem(x) table.insert(self.list, x) end
    return item
end
function isServer() return true end
local stockPot = moodItem("TraditionalPreservationFishMeat.PotOfFishHeadStock", -10, -10, { "TraditionalPreservationFishMeat.FishHead" })
local soup = moodItem("TraditionalPreservationFishMeat.PotOfFishHeadSoup", -2, 0, { "Base.Carrots" })
T.carryStock(stockPot, soup, recipe)
check("the soup gets the stock's -10 unhappiness and -10 boredom, on top of what went in", soup.unhappy == -12 and soup.boredom == -10)
check("and its head, listed first", #soup.list == 2 and soup.list[1] == "TraditionalPreservationFishMeat.FishHead" and soup.list[2] == "Base.Carrots")
check("and is named with the head skipped", soup.name == "Fish Head Soup with Carrots")
local again = moodItem("TraditionalPreservationFishMeat.PotOfFishHeadSoup", -12, -10, { "Base.Carrots" })
T.carryStock(again, again, recipe)
check("a soup taking more keeps its mood as it is", again.unhappy == -12 and again.boredom == -10 and #again.list == 1)
local plain = moodItem("Base.WaterPot", 0, 0, {})
local vanillaSoup = moodItem("Base.PotOfSoupRecipe", 0, 0, { "Base.Carrots" })
T.carryStock(plain, vanillaSoup, recipe)
check("a vanilla soup is left alone", vanillaSoup.unhappy == 0 and vanillaSoup.name == nil)
end

-- Butchering XP for packing
Perks = { Butchering = "Butchering" }
local xpGiven = {}
function addXp(character, perk, amount) table.insert(xpGiven, { character = character, perk = perk, amount = amount }) end
local function pack(fish)
    xpGiven, gutsMade = {}, {}
    T.onCreatePacked(newRecipeData(0, { fish }, { newFood("TraditionalPreservationFishMeat.SaltPackedFish", {}) }), gutter)
end
pack(newFood("Base.Walleye", { ActualWeight = 4 }))
check("packing a whole fish guts it, for Butchering XP", #gutsMade == 1 and #xpGiven == 1 and xpGiven[1].perk == "Butchering" and xpGiven[1].amount == T.PACK_GUTTING_XP and xpGiven[1].character == gutter)
pack(newFood("Base.FishFillet", { ActualWeight = 4 }))
check("a fillet only takes the salt, so gives none", #gutsMade == 0 and #xpGiven == 0)
pack(newFood("Base.Bluegill", { ActualWeight = 0.5 }))
check("nor does a fish too small to gut", #xpGiven == 0)

-- Salt by the packed fish's weight (C11)
local cutFillet = newFood("Base.FishFillet", { ActualWeight = 0.5 })
cutFillet.customWeight = true
check("a half-weight fish too small to gut takes two quarter steps, 4", T.saltFor(newFood("Base.Bluegill", { ActualWeight = 0.5 })) == 4)
check("a small panfish takes one step, 2, and never less", T.saltFor(newFood("Base.Bluegill", { ActualWeight = 0.3 })) == 2
    and T.saltFor(newFood("Base.Bluegill", { ActualWeight = 0.05 })) == 2)
check("a whole fish pays for what is left once gutted", T.saltFor(newFood("Base.Walleye", { ActualWeight = 4 })) == 28)
check("a whole number of steps pays no extra", T.saltFor(newFood("TraditionalPreservationFishMeat.GuttedFish", { ActualWeight = 1 })) == 8)
check("a gutted fish or a half by its weight, to the nearest step", T.saltFor(gutted) == 26)
check("a fillet vanilla cut pays for its food, half the gutted fish", T.saltFor(cutFillet) == 36)
check("a loot fillet, by its own weight", T.saltFor(newFood("Base.FishFillet", { ActualWeight = 0.2 })) == 2)
check("about 15% of the fish's weight, a use weighing 0.02", near(T.SALT_PER_STEP / T.SALT_STEP * 0.02, 0.16))
local packedCut = through(cutFillet, "SaltPackedFish")
check("and comes out of the salt that heavy (C26)", near(packedCut.values.ActualWeight, 4.5))

local function saltItem(fullType, uses)
    local item = newFood(fullType, {})
    item.salt, item.uses = true, uses
    function item:getCurrentUses() return self.uses end
    function item:setCurrentUses(value) self.uses = value end
    return item
end
instanceof = function(item, name) return name == "Food" and item.fullType ~= "Base.HuntingKnife" end
local carried = {}
local salter = { getInventory = function() return {
    getAllTagRecurse = function(_, tag, found)
        for _, item in ipairs(carried) do if item:hasTag(tag) then found:add(item) end end
        return found
    end,
    AddItem = function() end,
} end }
local removed = {}
local container = { DoRemoveItem = function(_, item) table.insert(removed, item) end }
local function carry(...)
    carried, removed = { ... }, {}
    for _, item in ipairs(carried) do function item:getContainer() return container end end
end
local walleye4 = newFood("Base.Walleye", { ActualWeight = 4.5 })  -- packs at 4.05: 16 quarter steps, 32 salt
carry(saltItem("Base.Salt", 10), saltItem("TraditionalPreservationSalt.LooseSalt", 5), saltItem("TraditionalPreservationSalt.BagOfSalt", 16))
check("31 salt carried can't pack a fish that takes 32", not T.canPack(walleye4, salter))
check("the knife, the salt and a test without a character pass", T.canPack(newFood("Base.HuntingKnife", {}), salter) and T.canPack(carried[1], salter) and T.canPack(walleye4, nil))
local shaker, loose, bag, spent = saltItem("Base.Salt", 10), saltItem("TraditionalPreservationSalt.LooseSalt", 5), saltItem("TraditionalPreservationSalt.BagOfSalt", 20), saltItem("Base.Salt", 0)
carry(shaker, loose, bag, spent)
check("35 can, and a used-up shaker doesn't count", T.canPack(walleye4, salter) and T.saltCarried(salter) == 35)
check("a whole fish over 4.5 weight is too thick to salt whole",
    not T.canPack(newFood("Base.Walleye", { ActualWeight = 4.6 }), salter)
    and not T.canPack(newFood("Base.Walleye", { ActualWeight = 4.6 }), nil)
    and T.canPack(newFood("Base.Walleye", { ActualWeight = 4.5 }), nil))
check("so is a gutted one; a half of any size packs",
    not T.canPack(newFood("TraditionalPreservationFishMeat.GuttedFish", { ActualWeight = 9 }), nil)
    and T.canPack(newFood("TraditionalPreservationFishMeat.FishHalf", { ActualWeight = 9 }), nil))
local returned
TraditionalPreservationSalt = { returnEmpties = function(character, emptied) returned = { character = character, emptied = emptied } end }
T.chargeSalt(walleye4, salter)
check("packing takes the other 30, part-used salt first", loose.uses == 0 and shaker.uses == 0 and bag.uses == 5 and spent.uses == 0)
check("what it empties leaves the inventory", #removed == 2 and removed[1] == loose and removed[2] == shaker)
check("and the Salt mod gives its empties back", returned and returned.character == salter and returned.emptied:size() == 2)
TraditionalPreservationSalt, returned = nil, nil
carry(saltItem("Base.Salt", 10))
T.chargeSalt(newFood("Base.Bluegill", { ActualWeight = 0.5 }), salter)
check("a small fish takes 2 past the recipe's 2", carried[1].uses == 8 and #removed == 0)
T.chargeSalt(walleye4, salter)
check("without the Salt mod, an emptied shaker just goes", carried[1].uses == 0 and #removed == 1 and returned == nil)
local packer = { getInventory = salter.getInventory }
carry(saltItem("Base.Salt", 20))
local packData = newRecipeData(0, { newFood("Base.Walleye", { ActualWeight = 2 }) }, { newFood("TraditionalPreservationFishMeat.SaltPackedFish", {}) })
function packData:getCharacter() return packer end
T.onCreatePacked(packData)
check("both pack recipes charge in onCreatePacked, finding the packer", carried[1].uses == 8)
instanceof = nil

-- How a stack looks on the frame
check("salted fish hangs as salted", T.fishStyle(newFood("TraditionalPreservationFishMeat.SaltPressedFish", {})) == T.STYLE_SALT)
check("gutted fish as gutted", T.fishStyle(newFood("TraditionalPreservationFishMeat.GuttedFish", {})) == T.STYLE_GUTTED)
check("halves as halves", T.fishStyle(newFood("TraditionalPreservationFishMeat.FishHalf", {})) == T.STYLE_HALF)
check("finished salt fish from before styles stays salted", T.fishStyle(newFood("TraditionalPreservationFishMeat.SaltDriedFish", {})) == T.STYLE_SALT)

local function rolled(start, data)
    local seen = {}
    for roll = 0, 11 do
        nextRoll = roll
        local stack = newRecipeData(0)
        start(stack)
        seen[stack.modData.style] = true
    end
    return seen
end
local saltLooks = rolled(T.onDryStart)
check("salt stacks can be whole, gutted or half", saltLooks[T.STYLE_SALT] and saltLooks[T.STYLE_SALT_GUTTED] and saltLooks[T.STYLE_SALT_HALF])
check("in salt colours only", not saltLooks[T.STYLE_GUTTED] and not saltLooks[T.STYLE_HALF])
local coldLooks = rolled(T.onColdDryStart)
check("cold stacks are gutted or half, never whole", coldLooks[T.STYLE_GUTTED] and coldLooks[T.STYLE_HALF] and not coldLooks[T.STYLE_SALT])
local styled = newRecipeData(0, { newFood("TraditionalPreservationFishMeat.GuttedFish", {}) }, { newFood("TraditionalPreservationFishMeat.ColdDriedFish", {}) })
nextRoll = 2
T.onColdDryStart(styled)
T.onCreateDried(styled)
check("a finished stack keeps the look it had", T.fishStyle(styled:getAllCreatedItems():get(0)) == T.STYLE_HALF)

-- Splitting
local heavy = through(newFood("Base.Walleye", { Calories = 800, BaseHunger = -0.6, HungChange = -0.6, ActualWeight = 4 }), "GuttedFish")
heavy.displayName = nil
check("a fish that fits a stack can't be split", not T.canSplit(through(newFood("Base.Walleye", { ActualWeight = 2 }), "GuttedFish")))
check("a heavier one can", T.canSplit(heavy) and T.canSplit(newFood("Base.KitchenKnife", {})))
local halfOne, halfTwo = newFood("TraditionalPreservationFishMeat.FishHalf", {}), newFood("TraditionalPreservationFishMeat.FishHalf", {})
T.onCreateSplit(newRecipeData(0, { heavy }, { halfOne, halfTwo }))
check("each half keeps half of everything", near(halfOne.values.ActualWeight, 1.6) and near(halfTwo.values.Calories, 376) and near(halfOne.values.HungChange, -0.282))
check("a half is named for its fish, without Gutted", halfOne.name == "Fish Half")
check("a half can't be sliced", not T.canSlice(halfOne))
local driedHalf = through(halfOne, "ColdDriedFish")
check("a cold dried half is stockfish of its species", driedHalf.name == "Walleye Stockfish (Matured)")
local saltedHalf = through(through(through(halfTwo, "SaltPackedFish"), "SaltPressedFish"), "SaltDriedFish")
check("a half can take the salt route too", saltedHalf.name == "Fish Half (Salt Dried)" and not T.canSlice(saltedHalf))
check("and stays a half in its icon", saltedHalf.modelIndex == halfTwo.modelIndex + #T.FISH_ICONS * 2)
check("as it does when cold dried", driedHalf.modelIndex == halfOne.modelIndex + #T.FISH_ICONS * 2)
local saltedGutted = through(through(heavy, "SaltPackedFish"), "SaltPressedFish")
check("a gutted fish stays headless through the salt route", saltedGutted.modelIndex == heavy.modelIndex + #T.FISH_ICONS)
heavy:getModData().fishName = "Big Walleye"
check("and keeps Gutted in its name", through(heavy, "SaltPackedFish").name == "Gutted Big Walleye (Salt Packed)")


-- Maturing
local function coldDried(age)
    local gutted = through(newFood("Base.Walleye", { ActualWeight = 3 }), "GuttedFish")
    local dried = newFood("TraditionalPreservationFishMeat.ColdDriedFish", {})
    T.onCreateDried(newRecipeData(0, { gutted }, { dried }))
    dried.age = age
    T.rename(dried)
    return dried
end
local fresh = coldDried(0)
check("stockfish comes off the frame with no age word", T.ripeness(fresh) == 0 and fresh.name == "Walleye Stockfish")
check("its tooltip says how far along it is", fresh.tooltip == "Tooltip_TraditionalPreservationFishMeat_ColdDried_0")
local halfway = coldDried(T.MATURE_DAYS / 2 + 1)
check("it ripens on its food clock", near(T.ripeness(halfway), 0.5 + 1 / T.MATURE_DAYS) and halfway.tooltip == "Tooltip_TraditionalPreservationFishMeat_ColdDried_50")
local ripe = coldDried(T.MATURE_DAYS + 30)
check("after MATURE_DAYS it is ripe", T.ripeness(ripe) == 1 and ripe.name == "Walleye Stockfish (Matured)")
check("and the tooltip goes back to the plain one", ripe.tooltip == "Tooltip_TraditionalPreservationFishMeat_ColdDried")
local stale = newFood("TraditionalPreservationFishMeat.ColdDriedFish", {})
stale.age = 3
stale:getModData().fishName = "Small Bass"
stale.name = "Cold Dried Small Bass"
T.rename(stale)
check("stockfish from before maturing counts as ripe, under the new name", T.ripeness(stale) == 1 and stale.name == "Small Bass Stockfish (Matured)")
local function soak(dried)
    local soaked = newFood("TraditionalPreservationFishMeat.SoakedColdFish", {})
    T.onCreateSoaked(newRecipeData(0, { dried }, { soaked }))
    return soaked
end
local soakedFresh, soakedHalf, soakedRipe = soak(fresh), soak(coldDried(T.MATURE_DAYS / 2)), soak(ripe)
check("unripe stockfish soaks into a dull fish", soakedFresh.unhappy == T.MATURE_UNHAPPY and soakedFresh.name == "Walleye Stockfish (Soaked)")
check("halfway is neither", soakedHalf.unhappy == 0)
check("ripe stockfish cheers you up", soakedRipe.unhappy == -T.MATURE_UNHAPPY and soakedRipe.name == "Walleye Stockfish (Soaked)")
check("the soaked fish keeps how ripe it was", T.ripeness(soakedHalf) == 0.5)
local ripeFillet = slice(ripe, "ColdDriedFish")
ripeFillet.age = ripe.age
check("a slice of stockfish keeps its ripeness", T.ripeness(ripeFillet) == 1)
local oldSoaked = newFood("TraditionalPreservationFishMeat.SoakedColdFish", {})
oldSoaked:getModData().fishName = "Small Bass"
T.rename(oldSoaked)
check("a fish soaked before maturing is Soaked stockfish", oldSoaked.name == "Small Bass Stockfish (Soaked)")
local tooltips = io.open("42/media/lua/shared/Translate/EN/Tooltip.json"):read("*a")
for tenth = 0, 90, 10 do
    check("the tooltip has a text for " .. tenth .. "%", tooltips:find('"Tooltip_TraditionalPreservationFishMeat_ColdDried_' .. tenth .. '"', 1, true) ~= nil)
end
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat.txt"):read("*a")
check("soaking stockfish goes through onCreateSoaked", script:match("craftRecipe SoakColdFish.-OnCreate = ([%w%.]+)") == "TraditionalPreservationFishMeat.onCreateSoaked")

-- Rinsing
local unrinsed = through(through(packedBass, "SaltPressedFish"), "SaltDriedFish")
unrinsed.thirst = 0.3
local toRinse = through(packedBass, "SaltPressedFish")
toRinse.thirst = 0.2
check("a Salt Cured fish can be rinsed", T.canRinse(toRinse))
check("other stages can't", not T.canRinse(packedBass) and not T.canRinse(unrinsed) and not T.canRinse(fresh))
check("rinsing works once", T.rinse(toRinse) and not T.canRinse(toRinse) and not T.rinse(toRinse))
check("a rinsed pressed fish is less salty and keeps a tenth less", near(toRinse.thirst, 0.2 * T.RINSED_THIRST) and toRinse.offAge == 108 and toRinse.offAgeMax == 162)
check("and says so", toRinse.name == "Medium Walleye (Salt Cured, Rinsed)")
local rinsedDried = newFood("TraditionalPreservationFishMeat.SaltDriedFish", {})
rinsedDried.thirst = 0.3
rinsedDried.unhappy = 3
T.onCreateDried(newRecipeData(0, { toRinse }, { rinsedDried }))
check("the dried fish from it keeps the rinse: thirst 30 to 20, no sharp tang", near(rinsedDried.thirst, 0.2) and rinsedDried.unhappy == 0)
check("and keeps a tenth less long, counted from its own script", rinsedDried.offAge == 108)
check("and its name says so", rinsedDried.name == "Medium Walleye (Salt Dried, Rinsed)")
check("an unrinsed fish is as it was", unrinsed.thirst == 0.3 and unrinsed.offAge == nil and unrinsed.name == "Medium Walleye (Salt Dried)")
local rinsedFillet = slice(rinsedDried, "SaltDriedFish")
check("a slice of rinsed fish is rinsed too", rinsedFillet:getModData().rinsed and rinsedFillet.offAge == 108)
local soakedRinsed = through(rinsedDried, "SoakedSaltFish")
check("soaking doesn't rinse a second time", soakedRinsed.offAge == nil and soakedRinsed.name == "Medium Walleye (Soaked, Salt Dried)")

-- The Rinse recipe
local beforeRecipe = through(packedBass, "SaltPressedFish")
beforeRecipe.thirst, beforeRecipe.age = 0.2, 4
beforeRecipe:getModData().stackId = 7
check("the recipe's test lets the water container through", T.canRinseInput(newFood("Base.WaterBottle", {})))
check("and a fish not rinsed yet", T.canRinseInput(beforeRecipe))
local fromRecipe = newFood("TraditionalPreservationFishMeat.SaltPressedFish", {})
fromRecipe.thirst = 0.2
T.onCreateRinsed(newRecipeData(0, { beforeRecipe }, { fromRecipe }))
check("the rinsed fish is the same fish: food, weight, age, data", fromRecipe.values.Calories == beforeRecipe.values.Calories
    and fromRecipe.values.ActualWeight == beforeRecipe.values.ActualWeight and fromRecipe.age == 4
    and fromRecipe:getModData().stackId == 7 and fromRecipe:getModData().fishName == beforeRecipe:getModData().fishName)
check("only rinsed", fromRecipe:getModData().rinsed and near(fromRecipe.thirst, 0.2 * T.RINSED_THIRST) and fromRecipe.offAge == 108)
check("named so", fromRecipe.name == "Medium Walleye (Salt Cured, Rinsed)")
check("and the test turns it down a second time", not T.canRinseInput(fromRecipe))
local rinseRecipe = script:match("craftRecipe RinseSaltedFish(.-)\n    }\n")
check("the recipe takes 0.15 L of clean water", rinseRecipe:find("-fluid " .. T.RINSE_LITRES .. " [Water]", 1, true) ~= nil)
check("and goes through canRinseInput and onCreateRinsed", rinseRecipe:find("OnTest = TraditionalPreservationFishMeat.canRinseInput", 1, true)
    and rinseRecipe:find("OnCreate = TraditionalPreservationFishMeat.onCreateRinsed", 1, true))

-- Charque, phase 3b: red meat in the Salting Tub (a function of its own: the main chunk is at Lua's 200 locals)
;(function()
    check("a 0.5 cut presses for two days", T.meatPressHours(0.5) == 48)
    check("a 0.3 cut, by weight", near(T.meatPressHours(0.3), 28.8))
    check("never under a day, never over two", T.meatPressHours(0.1) == T.PRESS_MIN_HOURS and T.meatPressHours(2) == T.PRESS_HOURS)
    local function meatPress(weights)
        local cuts = {}
        for i, weight in ipairs(weights) do cuts[i] = newFood(T.PACKED_MEAT, { ActualWeight = weight }) end
        return newRecipeData(RECIPE_TIME, cuts)
    end
    local steaks = meatPress({ 0.3, 0.3 })
    T.onPressStart(steaks)
    check("a batch of steaks sets its own hours", near(steaks.modData.pressHours, 28.8))
    local mixedCuts = meatPress({ 0.3, 0.5, 0.3 })
    T.onPressStart(mixedCuts)
    check("the heaviest cut sets the batch", mixedCuts.modData.pressHours == 48)
    check("the press time is set for meat too", loaded["TraditionalPreservationFishMeat.PressSaltedMeat"] == "{ time = " .. T.PRESS_HOURS * 3600 .. ", }")

    check("a tub takes packed meat", T.fishRefusal(true, T.PACKED_MEAT) == nil)
    check("but not raw meat", T.fishRefusal(true, "Base.Steak") == "IGUI_TraditionalPreservationFishMeat_NeedsPacked")
    check("a frame takes cured meat, not packed", T.fishRefusal(false, T.PACKED_MEAT) and T.fishRefusal(false, T.CURED_MEAT) == nil)
    check("an empty tub takes either", T.mixedTub(nil, T.PACKED_MEAT) == nil and T.mixedTub(nil, T.PACKED_FISH) == nil)
    check("meat on meat is fine", T.mixedTub(T.PACKED_MEAT, T.PACKED_MEAT) == nil)
    check("fish and meat never share a tub", T.mixedTub(T.PACKED_FISH, T.PACKED_MEAT) == "IGUI_TraditionalPreservationFishMeat_MixedTub"
        and T.mixedTub(T.PACKED_MEAT, T.PACKED_FISH) == "IGUI_TraditionalPreservationFishMeat_MixedTub")

    local steak = newFood("Base.Steak", { Calories = 220, Proteins = 31.62, Lipids = 9.35, BaseHunger = -0.4, HungChange = -0.4, ActualWeight = 0.3 })
    steak.displayName = "Steak "
    local packedSteak = through(steak, "SaltPackedMeat")
    check("packing a cut keeps all of it", near(packedSteak.values.ActualWeight, 0.3) and packedSteak.values.Calories == 220)
    check("its icon is the steak's", packedSteak.modelIndex == 1)
    check("its name too", packedSteak.name == "Steak (Salt Packed)")
    check("a cut has nothing to slice", not T.canSlice(packedSteak))
    check("and no guts or head", not T.hasGuts(steak) and not T.hasHead(steak))
    local curedSteak = through(packedSteak, "SaltCuredMeat")
    check("curing takes 7 to 12 percent", near(curedSteak.values.ActualWeight, 0.3 * keptShare))
    check("the cured cut keeps its food, icon and name", curedSteak.values.Calories == 220 and curedSteak.modelIndex == 1
        and curedSteak.name == "Steak (Corned)")
    local venison = newFood("Base.Venison", { ActualWeight = 0.5 })
    check("venison is the fourth icon", through(venison, "SaltPackedMeat").modelIndex == 3)
    check("a Beef takes 4 salt, as a half-weight fish, and a Steak 2", T.saltFor(newFood("Base.Beef", { ActualWeight = 0.5 })) == 4
        and T.saltFor(steak) == 2)
    instanceof = function(_, name) return name == "Food" end
    check("a cut is never too big to salt whole", T.canPack(newFood("Base.Beef", { ActualWeight = 5 }), nil))
    instanceof = nil

    -- Pork and the leg (6a)
    local pork = through(newFood("Base.Pork", { ActualWeight = 0.5 }), "SaltPackedMeat")
    local leg = newFood(T.LEG_OF_PORK, { ActualWeight = 2.5 })
    local packedLeg = through(leg, "SaltPackedMeat")
    check("pork and the leg take their own icons", pork.modelIndex == 4 and packedLeg.modelIndex == T.LEG_INDEX)
    check("and their names", pork.name == "Pork (Salt Packed)" and packedLeg.name == "LegOfPork (Salt Packed)")
    check("a leg takes half fish's salt, 10 for 2.5", T.saltFor(leg) == 10 and T.saltFor(newFood("Base.Pork", { ActualWeight = 0.5 })) == 4)
    check("the short cure refuses a leg, not a cut", not T.canCorn(packedLeg) and not T.canCorn(leg) and T.canCorn(pork))
    check("pork is pork, beef is not", T.isPork(pork) and T.isPork(packedLeg) and not T.isPork(packedSteak))
    local frame, beam, gantry, shed = T.HANGERS[6], T.HANGERS[408], T.HANGERS[410], { closed = true }
    check("pork that isn't Country Cured hangs in the Smokehouse only", T.meatRefusal(frame, "Open", pork) == "IGUI_TraditionalPreservationFishMeat_PorkSmokehouse"
        and T.meatRefusal(frame, "Covered", pork) == "IGUI_TraditionalPreservationFishMeat_PorkSmokehouse"
        and T.meatRefusal(shed, "Sheltered", pork) == nil and T.meatRefusal(frame, "Open", packedSteak) == nil)
    local longCuts = newRecipeData(T.LONG_LEG_HOURS * 3600, { packedSteak, pork }, nil, T.LONG_CURE_RECIPE)
    T.onPressStart(longCuts)
    local longLeg = newRecipeData(T.LONG_LEG_HOURS * 3600, { pork, packedLeg }, nil, T.LONG_CURE_RECIPE)
    T.onPressStart(longLeg)
    check("the long cure: 10 days for cuts, 21 with a leg", longCuts.modData.pressHours == 240 and longLeg.modData.pressHours == 504)
    -- The recipe's time is the leg's 21 days, not the short press's 2: each batch's bar ends on its own hours.
    hours = hours + 240
    T.onPressUpdate(longCuts)
    T.onPressUpdate(longLeg)
    check("cuts are cured after their 10 days, a leg 10 days into its 21", near(longCuts.elapsed, T.LONG_LEG_HOURS * 3600)
        and near(longLeg.elapsed, 240 * 3600))
    hours = hours - 240
    local countryPork = newFood(T.CURED_MEAT, {})
    T.onCreateLongCured(newRecipeData(0, { pork }, { countryPork }))
    check("it comes out Country Cured", countryPork:getModData().longCure and countryPork.name == "Pork (Country Cured)")
    local countrySteak = newFood(T.CURED_MEAT, {})
    T.onCreateLongCured(newRecipeData(0, { packedSteak }, { countrySteak }))
    local cornedSteak = through(packedSteak, "SaltCuredMeat")
    local needsShade = "IGUI_TraditionalPreservationFishMeat_CountryCuredSmokehouse"
    check("a frame in the open refuses Country Cured beef, not Corned", T.meatRefusal(frame, "Open", countrySteak) == needsShade
        and T.meatRefusal(frame, "Open", cornedSteak) == nil and T.meatRefusal(shed, "Sheltered", countrySteak) == nil)
    check("in the shade a Frame or Beam takes Country Cured meat, pork too", T.meatRefusal(frame, "Covered", countrySteak) == nil
        and T.meatRefusal(beam, "Sheltered", countrySteak) == nil and T.meatRefusal(beam, "Basement", countryPork) == nil
        and T.meatRefusal(frame, "Covered", countryPork) == nil and T.meatRefusal(frame, "Open", countryPork) == needsShade)
    check("a roofed Gantry does too, an open one not", T.meatRefusal(gantry, "Covered", countrySteak) == nil and T.meatRefusal(gantry, "Covered", countryPork) == nil
        and T.meatRefusal(gantry, "Open", countrySteak) == needsShade and T.meatRefusal(gantry, "Open", cornedSteak) == nil)
    check("the short cure refuses a leg, the long one takes it", T.recipeRefusal("PressSaltedMeat", packedLeg) == "IGUI_TraditionalPreservationFishMeat_LegNeedsLongCure"
        and T.recipeRefusal("PressSaltedMeat", pork) == nil and T.recipeRefusal(T.LONG_CURE_RECIPE, packedLeg) == nil)
    check("the long cure's time is set from the leg's", loaded["TraditionalPreservationFishMeat.CountryCureMeat"] == "{ time = " .. T.LONG_LEG_HOURS * 3600 .. ", }")

    local meatScript = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
    local cutList = meatScript:match("craftRecipe PackMeatInSalt.-item 1 %[([^%]]+)%]")
    check("the pack recipe takes the cuts in MEAT_CUTS", cutList == table.concat(T.MEAT_CUTS, ";"))
    check("pork and the leg go in the salt (6a)", cutList:find("Base.Pork;Base.PorkChop;TraditionalPreservationFishMeat.LegOfPork", 1, true) ~= nil)
    for _, stage in ipairs({ "SaltPackedMeat", "SaltCuredMeat" }) do
        local body = meatScript:match("item " .. stage .. "%s*{(.-)}")
        local icons = body:match("IconsForTexture = ([^,]+),")
        local count, missing = 0, {}
        for icon in icons:gmatch("[^;]+") do
            count = count + 1
            local file = io.open("42/media/textures/Item_" .. icon .. ".png", "rb")
            if file then file:close() else table.insert(missing, icon) end
        end
        check(stage .. " has an icon for each cut", count == #T.MEAT_CUTS and #missing == 0)
        local models = body:match("WorldStaticModelsByIndex = ([^,]+),")
        local modelCount = select(2, models:gsub("[^;]+", ""))
        check(stage .. " has a model for each cut", modelCount == #T.MEAT_CUTS)
    end
    check("both press recipes are the tub's", meatScript:find("craftRecipe PressSaltedMeat%s*{%s*time = %d+,%s*Tags = SaltingTub") ~= nil)
end)()

-- Charque, phase 3c: Salt Cured meat sun dried on the frames
;(function()
    check("nothing at freezing, full from 25 C", T.charqueWarmRate(0) == 0 and T.charqueWarmRate(-5) == 0
        and T.charqueWarmRate(25) == 1 and T.charqueWarmRate(35) == 1 and near(T.charqueWarmRate(10), 0.4))
    check("still air dries at 0.65, a good breeze at 1.2", near(T.charqueWindRate(0), 0.65) and near(T.charqueWindRate(T.WIND_GOOD), 1.2)
        and near(T.charqueWindRate(1), 1.2) and T.charqueWindRate(nil) == 1)
    local HOT = { temperature = 30, humidity = 0.4, precipitation = 0, wind = T.WIND_GOOD }
    local sun = T.newLedger(0)
    T.advance(sun, 10, HOT)
    check("hot sun and a breeze dry charque at 1.2", near(sun.charque, 12) and near(sun.charqueCovered, 12))
    check("indoors at 0.65 with no wind", near(sun.charqueSheltered, 6.5))
    local winter = T.newLedger(0)
    T.advance(winter, 10, { temperature = -3, humidity = 0.4, precipitation = 0 })
    check("winter dries no charque", winter.charque == 0 and winter.charqueCovered == 0 and winter.charqueSheltered == 0)
    T.advance(sun, 16, { temperature = 30, humidity = 0.4, precipitation = 1, wind = 0.5 })
    check("rain counts its hours and stops the open frame", near(sun.charqueRain, 6) and near(sun.charque, 12) and sun.charqueCovered > 12)
    local snow = T.newLedger(0)
    T.advance(snow, 5, { temperature = -2, humidity = 0.4, precipitation = 1, isSnow = true })
    check("snow isn't rain", snow.charqueRain == 0)

    local function stack(place)
        local cured = newFood(T.CURED_MEAT, {})
        local data = newRecipeData(T.CHARQUE_HOURS * 3600, { cured })
        T.onCharqueStart(data)
        data.modData.sheltered = place == "indoors" or nil
        data.modData.covered = place == "covered" or nil
        return data
    end
    local shared = T.getLedger()
    local open, covered, indoors = stack("open"), stack("covered"), stack("indoors")
    check("a meat stack hangs as meat", open.modData.style == T.STYLE_MEAT and open.modData.dried == 0)
    shared.charque, shared.charqueCovered, shared.charqueSheltered = shared.charque + 60, shared.charqueCovered + 60, shared.charqueSheltered + 30
    shared.dryCureRoom, shared.underCureRoom = shared.dryCureRoom + 20, shared.underCureRoom + 0.1
    shared.dryCure, shared.underCure = shared.dryCure + 99, shared.underCure + 0.5
    for _, data in ipairs({ open, covered, indoors }) do T.onCharqueUpdate(data) end
    check("each place reads its own total", open.modData.dried == 60 and covered.modData.dried == 60)
    check("in a room there is no charque: Corned meat dry cures, under-salted (0.4.15)", near(indoors.modData.dried, 20)
        and near(indoors.modData.underSpoiled, 0.1) and T.dryCuring(indoors.modData) and not T.dryCuring(covered.modData)
        and near(indoors.elapsed, T.CHARQUE_HOURS * 3600 * 20 / indoors.modData.cureNeed))
    check("half way is half the bar", near(open.elapsed, T.CHARQUE_HOURS * 3600 / 2))
    shared.charqueRain = shared.charqueRain + T.CHARQUE_RAIN_HOURS
    for _, data in ipairs({ open, covered }) do T.onCharqueUpdate(data) end
    check("a day's rain takes a tenth back on an open frame", near(open.modData.dried, 54))
    check("not under a roof", covered.modData.dried == 60)
    shared.saltSpoil = shared.saltSpoil + T.SALT_SPOIL_HOURS / 4
    T.onCharqueUpdate(covered)
    check("a muggy season spoils it as salt fish", near(covered.modData.spoiled, 0.25))
    shared.charqueCovered = shared.charqueCovered + 100
    T.onCharqueUpdate(covered)
    check("done stops at the end", covered.elapsed == T.CHARQUE_HOURS * 3600)

    local status = T.charqueStatus({ dried = 60 }, { charqueRate = 1.2, wetness = 0 })
    check("the popup's time left goes by the rate", near(status.progress, 0.5) and near(status.hoursLeft, 50))
    check("wet open charque says rain", T.charqueStatus({}, { charqueRate = 0, wetness = 0.5 }).reason == "Rain")
    check("frozen says too cold", T.charqueStatus({ covered = true }, { charqueCoveredRate = 0, wetness = 0 }).reason == "TooCold")
    check("hot sun is the best word", T.charqueTemperatureWord(30) == "IGUI_TraditionalPreservationFishMeat_TempHotGood"
        and T.charqueTemperatureWord(-1) == "IGUI_TraditionalPreservationFishMeat_TempTooCold")

    check("one stack is one kind", T.hangKind(T.CURED_MEAT) == "meat" and T.hangKind("TraditionalPreservationFishMeat.SaltPressedFish") == "salt"
        and T.hangKind("TraditionalPreservationFishMeat.GuttedFish") == "cold")
    check("cured meat waiting shows as meat", T.fishStyle(newFood(T.CURED_MEAT, {})) == T.STYLE_MEAT)

    local steak = newFood("Base.Steak", { Calories = 220, Proteins = 31.62, Lipids = 9.35, BaseHunger = -0.4, HungChange = -0.4, ActualWeight = 0.3 })
    steak.displayName = "Steak "
    local cured = through(through(steak, "SaltPackedMeat"), "SaltCuredMeat")
    local charque = newFood("TraditionalPreservationFishMeat.Charque", {})
    T.onCreateDried(newRecipeData(0, { cured }, { charque }))
    check("charque is named for its animal", charque.name == "Beef Charque" and charque.modelIndex == 1)
    check("about half the raw weight", near(charque.values.ActualWeight, 0.3 * keptShare * 0.55))
    check("it keeps 90% of the food, 70% of the bulk", near(charque.values.Calories, 198) and near(charque.values.HungChange, -0.28))
    local soaked = through(charque, "SoakedCharque")
    check("soaking gives the bulk back", near(soaked.values.HungChange, -0.4) and soaked.name == "Beef Charque (Soaked)")

    check("cured meat can be rinsed", T.canRinse(cured))
    local rinsedCured = newFood(T.CURED_MEAT, {})
    rinsedCured.displayName = "Steak "
    T.carry(through(steak, "SaltPackedMeat"), rinsedCured)
    rinsedCured.thirst = 20
    T.rinse(rinsedCured)
    check("the rinse stays out of the name", rinsedCured.name == "Steak (Corned)" and near(rinsedCured.thirst, 20 * T.RINSED_THIRST))
    local rinsedCharque = newFood("TraditionalPreservationFishMeat.Charque", {})
    T.carry(rinsedCured, rinsedCharque)
    local rinsedSoaked = newFood("TraditionalPreservationFishMeat.SoakedCharque", {})
    rinsedSoaked.thirst = 10
    T.carry(rinsedCharque, rinsedSoaked)
    check("rinsed meat soaks less salty", near(rinsedSoaked.thirst, 10 * T.RINSED_THIRST) and rinsedSoaked:getModData().rinsed)

    T.CHARQUE_ON = false
    instanceof = function(_, name) return name == "Food" end
    check("off, the frame refuses meat and the tub too", T.fishRefusal(false, T.CURED_MEAT) == "IGUI_TraditionalPreservationFishMeat_CharqueOff"
        and T.fishRefusal(true, T.PACKED_MEAT) == "IGUI_TraditionalPreservationFishMeat_CharqueOff"
        and not T.canPack(newFood("Base.Beef", { ActualWeight = 0.5 }), nil))
    check("fish is untouched", T.fishRefusal(false, "TraditionalPreservationFishMeat.SaltPressedFish") == nil
        and T.canPack(newFood("Base.Walleye", { ActualWeight = 1 }), nil))
    instanceof = nil
    T.CHARQUE_ON = true

    local meatScript = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
    local fishScript = io.open("42/media/scripts/TraditionalPreservationFishMeat.txt"):read("*a")
    check("charque hangs on every drying station", meatScript:find("craftRecipe HangMeatToDry%s*{[^}]-Tags = DryingFrame") ~= nil)
    check("and in the Smokehouse", meatScript:find("craftRecipe HangMeatToDry%s*{[^}]-Tags = DryingFrame;Smokehouse") ~= nil)
    check("salt fish too", fishScript:find("craftRecipe HangFishToDry%s*{[^}]-Tags = DryingFrame;Smokehouse") ~= nil)
    check("but not cold drying: it needs open air", fishScript:find("craftRecipe HangFishToColdDry%s*{[^}]-Tags = DryingFrame,") ~= nil)
    check("its time is set from CHARQUE_HOURS", loaded["TraditionalPreservationFishMeat.HangMeatToDry"] == "{ time = " .. T.CHARQUE_HOURS * 3600 .. ", }")
    for _, stage in ipairs({ "Charque", "SoakedCharque" }) do
        local body = meatScript:match("item " .. stage .. "%s*{(.-)}")
        local count, missing = 0, {}
        for icon in body:match("IconsForTexture = ([^,]+),"):gmatch("[^;]+") do
            count = count + 1
            local file = io.open("42/media/textures/Item_" .. icon .. ".png", "rb")
            if file then file:close() else table.insert(missing, icon) end
        end
        check(stage .. " has an icon for each cut", count == #T.MEAT_CUTS and #missing == 0)
    end
    check("charque can't be eaten unsoaked", meatScript:match("item Charque%s*{(.-)}"):find("CantEat = true", 1, true) ~= nil)
    check("nor can stockfish", fishScript:match("item ColdDriedFish%s*{(.-)}"):find("CantEat = true", 1, true) ~= nil)
    check("Salt Dried fish still can", not fishScript:match("item SaltDriedFish%s*{(.-)}"):find("CantEat", 1, true))
    check("the rinse gives back what went in", fishScript:find("TraditionalPreservationFishMeat.SaltCuredMeat = TraditionalPreservationFishMeat.SaltCuredMeat", 1, true) ~= nil)
end)()

-- 6b: what comes out of the Smokehouse, piece by piece (F.smokedItem)
;(function()
    local oldInstance = instanceItem
    instanceItem = function(fullType) return newFood(fullType, {}) end
    local meatScript = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
    local fishScript = io.open("42/media/scripts/TraditionalPreservationFishMeat.txt"):read("*a")
    local function cut(fullType, values, longCure)
        local raw = newFood(fullType, values)
        local cured = through(through(raw, "SaltPackedMeat"), "SaltCuredMeat")
        cured:getModData().longCure = longCure
        return cured
    end
    local porkValues = { Calories = 300, Proteins = 40, Lipids = 15, BaseHunger = -0.6, HungChange = -0.6, ActualWeight = 0.5 }
    local pork = cut("Base.Pork", porkValues, false)
    local ham = T.smokedItem(pork, { stackId = 1 }, T.HOT_FISH, T.HOT_MEAT)
    check("hot smoked pork is vanilla's Ham with the cut's food", ham.fullType == "Base.Ham" and near(ham.values.Calories, 300)
        and near(ham.values.ActualWeight, pork.values.ActualWeight * 0.78) and ham.name == nil)
    local beef = cut("Base.Beef", { Calories = 440, BaseHunger = -0.8, HungChange = -0.8, ActualWeight = 0.5 }, false)
    check("hot smoked beef is ours", T.smokedItem(beef, {}, T.HOT_FISH, T.HOT_MEAT).name == "Beef (Hot Smoked)")
    local smoked = T.smokedItem(beef, { underSpoiled = 0.5 }, T.COLD_FISH_OUT, T.DRY_CURED, false)
    check("Corned beef dried in smoke is Suho Meso, half its keeping gone", smoked.name == "Suho Meso" and near(smoked.age, 60))
    local longBeef = cut("Base.Beef", { Calories = 440, BaseHunger = -0.8, HungChange = -0.8, ActualWeight = 0.5 }, true)
    local aired = T.smokedItem(longBeef, { underSpoiled = 0.5 }, T.COLD_FISH_OUT, T.DRY_CURED, true)
    check("Country Cured beef with no smoke is Bresaola, and the stack's under-salting isn't its own", aired.name == "Bresaola"
        and aired.fullType == T.DRY_CURED and aired.age == 0 and near(aired.values.Calories, 396))
    check("Bresaola's tooltip has no smoke in it, Suho Meso's has; both start ageing", aired.tooltip == "Tooltip_TraditionalPreservationFishMeat_AirDried_0"
        and smoked.tooltip == "Tooltip_TraditionalPreservationFishMeat_DryCured_0")
    check("ageing counts from the age it came down with", smoked:getModData().agedFrom == smoked.age and aired:getModData().agedFrom == 0)
    local rotten = T.smokedItem(beef, { underSpoiled = 1.2 }, T.COLD_FISH_OUT, T.DRY_CURED, true)
    check("under-salted meat that rots comes down as the Beef (Corned) that was hung, rotten", rotten.fullType == T.CURED_MEAT
        and rotten.name == "Beef (Corned)" and rotten.age == 180 and near(rotten.values.ActualWeight, beef.values.ActualWeight)
        and near(rotten.values.Calories, 440))
    check("a Country Cured piece in the same stack is spared", T.smokedItem(longBeef, { underSpoiled = 1.2 }, T.COLD_FISH_OUT, T.DRY_CURED, true).name == "Bresaola")
    local pressed = newFood("TraditionalPreservationFishMeat.SaltPressedFish", { Calories = 200, ActualWeight = 1 })
    pressed:getModData().fishName = "Walleye"
    local rottenFish = T.rottenStage(pressed)
    check("a rotted salt stack's fish is still the pressed fish", rottenFish.fullType == pressed.fullType and rottenFish.age == 180
        and rottenFish:getModData().fishName == "Walleye")
    local kept = T.rottenStage(pressed, { stackId = 12, style = T.STYLE_SALT_HALF })
    check("and keeps its stack, so the station counts and draws it with the rest", kept:getModData().stackId == 12
        and kept:getModData().style == T.STYLE_SALT_HALF)
    local leg = cut(T.LEG_OF_PORK, { Calories = 1500, BaseHunger = -3, HungChange = -3, ActualWeight = 2.5 }, true)
    local countryHam = T.smokedItem(leg, {}, T.COLD_FISH_OUT, T.DRY_CURED, false)
    check("a leg dried in smoke is a Smoked Country Ham, an item of its own", countryHam.fullType == T.COUNTRY_HAM
        and countryHam.name == "Smoked Country Ham" and near(countryHam.values.Calories, 1350))
    check("air dried, a Country Ham", T.smokedItem(leg, {}, T.COLD_FISH_OUT, T.DRY_CURED, true).name == "Country Ham")
    check("a leg is never vanilla's Ham", T.smokedItem(leg, {}, T.HOT_FISH, T.HOT_MEAT).fullType == T.HOT_MEAT)
    local fish = newFood("TraditionalPreservationFishMeat.SaltPressedFish", { Calories = 200, ActualWeight = 1 })
    check("fish is as before", T.smokedItem(fish, {}, T.COLD_FISH_OUT, T.DRY_CURED, false).fullType == T.COLD_FISH_OUT)
    check("the Country Ham keeps half a year to a year", meatScript:match("item CountryHam%s*{(.-)}"):find("DaysFresh = 180,%s*DaysTotallyRotten = 365") ~= nil)
    check("stockfish keeps a year, rotten at a year and a half", fishScript:match("item ColdDriedFish%s*{(.-)}"):find("DaysTotallyRotten = 540", 1, true) ~= nil)
    instanceItem = oldInstance
end)()

H.done()
