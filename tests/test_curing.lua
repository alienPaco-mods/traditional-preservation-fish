-- Checks the curing rules outside the game. Run from the mod folder: luajit tests/test_curing.lua
local H = dofile((os.getenv("TPCORE") or "../_tpcore") .. "/tests/harness.lua")
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
local NAMES = {
    IGUI_TraditionalPreservationFish_Packed = "Salt Packed %1",
    IGUI_TraditionalPreservationFish_Pressed = "Salt Pressed %1",
    IGUI_TraditionalPreservationFish_Dried = "Salt Dried %1",
    IGUI_TraditionalPreservationFish_Gutted = "Gutted %1",
    IGUI_TraditionalPreservationFish_Half = "%1 Half",
    IGUI_TraditionalPreservationFish_ColdDried = "Cold Dried %1",
    IGUI_TraditionalPreservationFish_SoakedSalt = "Rehydrated Salt Dried %1",
    IGUI_TraditionalPreservationFish_SoakedCold = "Rehydrated Cold Dried %1",
    IGUI_TraditionalPreservationFish_Head = "%1 Head",
}
local keptShare
function ZombRandFloat(low, high)
    keptShare = low + (high - low) * 0.5
    return keptShare
end
ItemTag = { UNCUT_FISH = "uncut" }
local nextRoll = 0
function ZombRand(limit) return nextRoll % limit end
function getText(key, ...)
    local values = { ... }
    return (NAMES[key]:gsub("%%(%d)", function(n) return values[tonumber(n)] end))
end
function getItemNameFromFullType(fullType) return fullType == "Base.FishFillet" and "Fish Fillet" or fullType end
local onInit
Events = { OnInitGlobalModData = { Add = function(handler) onInit = handler end } }
local loaded = {}
ScriptManager = { instance = {} }
function ScriptManager.instance:getCraftRecipe(name)
    return { Load = function(_, recipeName, text) loaded[recipeName] = text end }
end
dofile("42/media/lua/shared/TraditionalPreservationFish.lua")
local T = TraditionalPreservationFish

local check = H.check

local function near(a, b) return math.abs(a - b) < 0.0001 end

local list = H.list

local function newRecipeData(time, fish, created)
    local data = { modData = {}, elapsed = 0 }
    function data:getModData() return self.modData end
    function data:setElapsedTime(value) self.elapsed = value end
    function data:getRecipe() return { getTime = function() return time end } end
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
    function food:getDisplayName() return self.displayName or "Fish" end
    function food:setCustomWeight(value) self.customWeight = value end
    function food:getModData() self.modData = self.modData or {}; return self.modData end
    function food:setName(value) self.name = value end
    function food:setCustomName(value) self.customName = value end
    function food:getModelIndex() return self.modelIndex or -1 end
    function food:setModelIndex(value) self.modelIndex = value end
    function food:hasTag(tag) return tag == ItemTag.UNCUT_FISH and self.fullType:sub(1, 5) == "Base." and self.fullType ~= "Base.FishFillet" end
    function food:setWeight(value) self.weight = value end
    function food:getOffAge() return 120 end
    function food:getOffAgeMax() return 180 end
    function food:setAge(value) self.age = value end
    function food:getAge() return self.age or 0 end
    return food
end

local MILD = { temperature = 20, humidity = 0.4, precipitation = 0 }

-- Recipe times
onInit()
check("the press time comes from PRESS_HOURS", loaded["TraditionalPreservationFish.PressSaltedFish"] == "{ time = " .. T.PRESS_HOURS * 3600 .. ", }")
check("the drying time comes from DRY_HOURS", loaded["TraditionalPreservationFish.HangFishToDry"] == "{ time = " .. T.DRY_HOURS * 3600 .. ", }")

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
local RECIPE_TIME = T.PRESS_HOURS * 3600
local press = newRecipeData(RECIPE_TIME)
T.onPressStart(press)
hours = hours + T.PRESS_HOURS / 2
T.onPressUpdate(press)
check("half the hours is half the press", near(press.elapsed, RECIPE_TIME / 2))
hours = hours + 100
T.onPressUpdate(press)
check("time away finishes the press, and no further", press.elapsed == RECIPE_TIME)

press.elapsed = 0
T.onPressStart(press)
T.onPressUpdate(press)
check("a reused object starts its own run", press.elapsed == 0)

-- The tub
check("a tub takes fish up to its capacity", T.hasRoom(T.TUB_CAPACITY, T.TUB_CAPACITY - 1, 1))
check("and no more", not T.hasRoom(T.TUB_CAPACITY, T.TUB_CAPACITY - 0.5, 1))
check("a fish over the capacity never fits", not T.hasRoom(T.TUB_CAPACITY, 0, T.TUB_CAPACITY + 1))

-- The right fish for each station
check("a tub takes packed fish", T.fishRefusal(true, "TraditionalPreservationFish.SaltPackedFish") == nil)
check("but not pressed or raw fish", T.fishRefusal(true, "TraditionalPreservationFish.SaltPressedFish") == "IGUI_TraditionalPreservationFish_NeedsPacked" and T.fishRefusal(true, "Base.Walleye") == "IGUI_TraditionalPreservationFish_NeedsPacked")
check("a frame takes pressed fish", T.fishRefusal(false, "TraditionalPreservationFish.SaltPressedFish") == nil)
check("but not packed fish", T.fishRefusal(false, "TraditionalPreservationFish.SaltPackedFish") == "IGUI_TraditionalPreservationFish_NeedsPressed")

-- The frame
check("a stack takes four fish too small to slice", T.frameRefusal(T.HANGERS[6], 0, 0.6 * 3, 0.6) == nil)
check("but not a fifth", T.frameRefusal(T.HANGERS[6], 0, 2.4, 0.6) == "IGUI_TraditionalPreservationFish_StackFull")
check("a fish at the limit hangs", T.frameRefusal(T.HANGERS[6], 0, 0, 2.5) == nil)
check("and takes nothing with it", T.frameRefusal(T.HANGERS[6], 0, 2.5, 0.1) == "IGUI_TraditionalPreservationFish_StackFull")
check("a heavier fish is told to slice", T.frameRefusal(T.HANGERS[6], 0, 0, 2.6) == "IGUI_TraditionalPreservationFish_TooHeavy")
check("eight stacks fill the frame", T.frameRefusal(T.HANGERS[6], 7, 0, 0.1) == nil and T.frameRefusal(T.HANGERS[6], 8, 0, 0.1) == "IGUI_TraditionalPreservationFish_FrameFull")
check("a full frame is 20 weight", T.STACK_WEIGHT * T.MAX_STACKS == 20)
check("every station finds its hanger, either way round", T.hangerFor(7) == T.HANGERS[6] and T.hangerFor(409) == T.HANGERS[408] and T.hangerFor(410) == T.HANGERS[410])
check("a tub has none", T.hangerFor(0) == nil and T.hangerFor(5) == nil)
local function square(outside) return { square = { isOutside = function() return outside end } } end
check("the big beams go up outdoors", T.isOutdoors(square(true)))
check("not indoors", not T.isOutdoors(square(false)))
for _, name in ipairs({ "Medium", "Large" }) do
    local entity = io.open("42/media/scripts/entities/entity_Drying_Beam_" .. name .. ".txt"):read("*a")
    check(name .. " beam is outdoors only", entity:find("OnIsValid = TraditionalPreservationFish.isOutdoors", 1, true) ~= nil)
end
check("the frame isn't", not io.open("42/media/scripts/entities/entity_Drying_Frame.txt"):read("*a"):find("OnIsValid", 1, true))
check("sprites below the first sheet's end are on it", T.spriteName(407) == "traditionalpreservationfish_01_407")
check("the rest are on the second", T.spriteName(408) == "traditionalpreservationfish_02_0" and T.spriteName(711) == "traditionalpreservationfish_02_303")
for _, index in ipairs({ 0, 7, 407, 408, 411, 711 }) do
    check("sprite " .. index .. " reads back", T.spriteIndex(T.spriteName(index)) == index)
end
check("other mods' sprites aren't ours", T.spriteIndex("carpentry_02_122") == nil and T.spriteIndex(nil) == nil)

-- The game drops the whole tile file if a sheet has too many tiles, and every station with it.
local tiles = io.open("42/media/traditionalpreservationfish.tiles", "rb"):read("*a")
local function u32(at)
    local a, b, c, d = tiles:byte(at, at + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end
check("the tile file has both sheets", u32(9) == 2)
local sheetCount = u32(13 + #"traditionalpreservationfish_01\ntraditionalpreservationfish_01.png\n" + 12)
check("the first sheet ends where the sprites say", sheetCount == T.FIRST_SHEET_SIZE and sheetCount <= 512)
check("a medium beam takes 15 a stack on 4 hooks", T.frameRefusal(T.HANGERS[408], 3, 0, 15) == nil and T.frameRefusal(T.HANGERS[408], 0, 0, 15.1) == "IGUI_TraditionalPreservationFish_TooHeavy" and T.frameRefusal(T.HANGERS[408], 4, 0, 1) == "IGUI_TraditionalPreservationFish_FrameFull")
check("a large beam takes 50 a stack on 2 hooks", T.frameRefusal(T.HANGERS[410], 1, 0, 50) == nil and T.frameRefusal(T.HANGERS[410], 2, 0, 1) == "IGUI_TraditionalPreservationFish_FrameFull")

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

dry.modData.sheltered = nil
hours = hours + 1000
T.advance(shared, hours, MILD)
T.onDryUpdate(dry)
check("time unloaded counts, and stops at done", dry.elapsed == DRY_TIME)

local reused = newRecipeData(DRY_TIME)
reused.modData = { dried = 90, sheltered = true }
T.onDryStart(reused)
T.onDryUpdate(reused)
check("a reused object starts from nothing", reused.elapsed == 0 and reused.modData.sheltered == nil)

local stacked = newRecipeData(DRY_TIME, { newFood("TraditionalPreservationFish.SaltPressedFish", {}) }, { newFood("TraditionalPreservationFish.SaltDriedFish", {}) })
T.onDryStart(stacked)
T.onCreateDried(stacked)
check("dried fish remembers its stack", stacked:getAllCreatedItems():get(0):getModData().stackId == stacked.modData.stackId)

-- Sandbox options
SandboxVars = { TraditionalPreservationFish = { DryDays = 24, MaxDryDays = 48, Spoilage = 4 } }
T.applySandbox()
check("drying days set both methods' hours", T.DRY_HOURS == 576 and T.COLD_DRY_HOURS == 960)
check("the slowest days set the lowest rate", near(T.MIN_DRY_RATE, 0.5))
check("harsh spoilage halves the limits", T.RAW_SPOIL_HOURS == 24 and T.SALT_SPOIL_HOURS == 240)
SandboxVars.TraditionalPreservationFish = { DryDays = 30, MaxDryDays = 10, Spoilage = 1 }
T.applySandbox()
check("the slowest can't beat the fastest", T.MIN_DRY_RATE == 1)
check("spoilage can be turned off", T.RAW_SPOIL_HOURS == math.huge and T.SALT_SPOIL_HOURS == math.huge)
SandboxVars.TraditionalPreservationFish = { DryDays = 12, MaxDryDays = 27, Spoilage = 3 }
T.applySandbox()
check("the defaults put it all back", T.DRY_HOURS == 288 and T.COLD_DRY_HOURS == 480 and T.RAW_SPOIL_HOURS == 48 and T.SALT_SPOIL_HOURS == 480)
SandboxVars = nil

-- What a stack's popup reports
local readings = T.newLedger(0)
T.advance(readings, 1, { temperature = 0, humidity = 0.2, precipitation = 0 })
local coldNow = T.stackStatus(true, { dried = 120 }, readings)
check("cold fish dries at full rate in the cold", coldNow.rate == 1 and near(coldNow.hoursLeft, 360) and near(coldNow.progress, 0.25))
local saltNow = T.stackStatus(false, { dried = 144 }, readings)
check("salt fish goes by its own rate", near(saltNow.rate, T.MIN_DRY_RATE) and near(saltNow.hoursLeft, 144 / T.MIN_DRY_RATE))
check("a roof stops cold drying but not salt", T.stackStatus(true, { sheltered = true }, readings).reason == "Roof" and T.stackStatus(false, { sheltered = true }, readings).reason == nil)
local rained = T.newLedger(0)
T.advance(rained, 1, { temperature = 3, humidity = 0.3, precipitation = 1 })
check("rain pauses both", T.stackStatus(true, {}, rained).reason == "Rain" and T.stackStatus(false, {}, rained).reason == "Rain" and T.stackStatus(true, {}, rained).hoursLeft == nil)
local hot = T.newLedger(0)
hot.seasonTemperature, hot.seasonHumidity = 25, 0.6
T.advance(hot, 1, { temperature = 25, humidity = 0.6, precipitation = 0 })
check("a warm season stops cold drying and warns", T.stackStatus(true, {}, hot).reason == "TooWarm" and T.stackStatus(true, {}, hot).spoiling)
check("a muggy one warns for salt fish", T.stackStatus(false, {}, hot).spoiling)
check("a fresh ledger is safe to read", T.stackStatus(false, {}, T.newLedger(0)).rate == 0)
check("the words fit the method", T.temperatureWord(true, 2) == "IGUI_TraditionalPreservationFish_TempGoodCold" and T.temperatureWord(false, 25) == "IGUI_TraditionalPreservationFish_TempGoodWarm" and T.temperatureWord(true, 25) == "IGUI_TraditionalPreservationFish_TempTooWarm")

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
check("full rate around freezing", T.coldRate(-5) == 1 and T.coldRate(5) == 1)
check("slower in deep frost and near the limit", T.coldRate(-15) == T.COLD_MIN_RATE and near(T.coldRate(10), T.COLD_MIN_RATE))
check("stops above the limit", T.coldRate(11) == 0)
local snowfall = T.newLedger(0)
T.advance(snowfall, 1, { temperature = -2, humidity = 0.3, precipitation = 1, isSnow = true })
check("snow doesn't stop it", near(snowfall.cold, 1) and snowfall.open == 0)
local rainfall = T.newLedger(0)
T.advance(rainfall, 1, { temperature = 3, humidity = 0.3, precipitation = 1 })
check("rain does", rainfall.cold == 0)

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
check("a warm spell in winter doesn't spoil it", mildStack.modData.spoiled == 0)

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
check("a roof stops cold drying", roofedStack.modData.dried == 0)

-- Salt fish in summer
local function saltStack(season, humidity)
    ModData.tables = {}
    hours = 0
    local stack = newRecipeData(T.DRY_HOURS * 3600)
    T.onDryStart(stack)
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

local oldSave = newRecipeData(T.DRY_HOURS * 3600)
oldSave.modData = { dried = 10, lastOpen = 0, lastSheltered = 0 }
T.onDryUpdate(oldSave)
check("a stack from an older version carries on", oldSave.modData.spoiled == 0)

ModData.tables = { [T.MOD_DATA_KEY] = { lastHour = 5, wetness = 0, open = 3, sheltered = 2 } }
local upgraded = T.getLedger()
check("an older ledger gains the new totals", upgraded.open == 3 and upgraded.cold == 0 and upgraded.rawSpoil == 0)
ModData.tables = {}

-- What the season took shows on the finished fish
local function finished(spoiled)
    local stack = newRecipeData(0, { newFood("TraditionalPreservationFish.SaltPressedFish", {}) }, { newFood("TraditionalPreservationFish.SaltDriedFish", {}) })
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
local outBig = newFood("TraditionalPreservationFish.SaltDriedFish", {})
local outSmall = newFood("TraditionalPreservationFish.SaltDriedFish", {})
T.onCreateCured(newRecipeData(0, { big, small }, { outBig, outSmall }))
check("each fish keeps its own size", near(outBig.values.Calories, 720) and near(outSmall.values.Calories, 90))
check("drying takes most of the weight", near(outBig.values.ActualWeight, 3.6) and outBig.customWeight)
check("each fish keeps its own name", outBig.name == "Salt Dried Big Walleye" and outSmall.name == "Salt Dried Small Bluegill" and outBig.customName)
check("hunger shrinks with it", near(outBig.values.BaseHunger, -0.42) and near(outBig.values.HungChange, -0.42))

local whole = { Calories = 800, BaseHunger = -0.6, ActualWeight = 8 }
local item = newFood("Base.Walleye", whole)
item.displayName = "Medium Walleye "
for _, stage in ipairs({ "SaltPackedFish", "SaltPressedFish", "SaltDriedFish", "SoakedSaltFish" }) do
    local nextItem = newFood("TraditionalPreservationFish." .. stage, {})
    T.carry(item, nextItem)
    item = nextItem
    if stage == "SaltPressedFish" then
        check("pressed fish keeps the walleye's icon", item.modelIndex == 6)
        check("the name follows the fish", item.name == "Salt Pressed Medium Walleye")
        check("pressing takes 7 to 12 percent", keptShare >= 0.88 and keptShare <= 0.93 and near(item.values.ActualWeight, 8 * 0.9 * keptShare))
    end
end
check("the species survives every stage", item.name == "Rehydrated Salt Dried Medium Walleye")
check("the fish's icon lasts to the end", item.modelIndex == 6)

-- A part-eaten fish stays part-eaten. The engine has already scaled its calories.
local bitten = newFood("Base.BlackCrappie", { Calories = 50, BaseHunger = -0.2, HungChange = -0.1, ActualWeight = 1 })
local bittenPacked = newFood("TraditionalPreservationFish.SaltPackedFish", {})
T.carry(bitten, bittenPacked)
check("a part-eaten fish doesn't grow back", near(bittenPacked.values.HungChange, -0.1) and near(bittenPacked.values.BaseHunger, -0.2))
check("and keeps what's left of its calories", bittenPacked.values.Calories == 50)

-- Slicing
local function through(source, stage)
    local nextItem = newFood("TraditionalPreservationFish." .. stage, {})
    T.carry(source, nextItem)
    return nextItem
end
local function slice(source, stage)
    local one, two = newFood("TraditionalPreservationFish." .. stage, {}), newFood("TraditionalPreservationFish." .. stage, {})
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
check("and vanilla's share of the weight", near(one.values.ActualWeight, pressedBass.values.ActualWeight * 0.05))
check("it stays at its stage", one.name == "Salt Pressed Fish Fillet" and one.customName)
check("it shows the fillet icon", one.modelIndex == 0)
check("it can't be cut again", not T.canSlice(one))
check("and carries on through the stages", through(one, "SaltDriedFish").name == "Salt Dried Fish Fillet")
local driedOne = slice(driedBass, "SaltDriedFish")
check("dried fillets show the fillet icon too", driedOne.modelIndex == 0)

local stranger = newFood("OtherMod.Fish", {})
check("a fish from another mod has no icon to keep", T.iconIndex(stranger) == -1)

-- The script's icons have to line up with FISH_ICONS, or a fish shows another's icon.
local script = io.open("42/media/scripts/TraditionalPreservationFish.txt"):read("*a")
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
check("all eight stages have the list", lists == 8)

-- Each model list runs in the same order as the icons, and every model exists.
local models = io.open("42/media/scripts/TraditionalPreservationFish_models.txt"):read("*a")
local modelLists = 0
for list in script:gmatch("WorldStaticModelsByIndex = ([^,]+),") do
    modelLists = modelLists + 1
    local position = 0
    for model in list:gmatch("[^;]+") do
        position = position + 1
        local name = model:gsub("^TraditionalPreservationFish%.", "")
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
check("all eight stages have models", modelLists == 8)

local headBody = script:match("item FishHead\n    {(.-)\n    }")
check("a head spoils like fresh fish", headBody:find("DaysFresh = 3,", 1, true) and headBody:find("DaysTotallyRotten = 6,", 1, true))
check("and is a little unpleasant to eat", headBody:find("UnhappyChange = 5,", 1, true) ~= nil and not headBody:find("RemoveUnhappinessWhenCooked", 1, true))
check("no drying recipe takes a head", not script:find("FishHead", (script:find("craftRecipe PressSaltedFish", 1, true)), true))
for _, name in ipairs({ "FishHeadStock", "FishHeadStockForged" }) do
    local evolved = script:match("evolvedrecipe " .. name .. "\n    {(.-)\n    }")
    check(name .. " takes the head and 6 stew ingredients", evolved and evolved:find("MaxItems = 7,", 1, true) and evolved:find("Template = Stew,", 1, true))
    local pot = evolved:match("BaseItem = ([%w%.]+),")
    check(name .. " is already a stew", evolved:find("ResultItem = " .. pot .. ",", 1, true) ~= nil)
    local body = script:match("item " .. pot:gsub("^.-%.", "") .. "\n    {(.-)\n    }")
    check(name .. " starts tastier than vanilla stew's -20", tonumber(body:match("UnhappyChange = (%-?%d+)")) < -20)
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
check("cold drying leaves about a fifth of the weight", near(coldFish.values.ActualWeight, 1.76) and coldFish.name == "Cold Dried Medium Walleye")
coldFish = through(coldFish, "SoakedColdFish")
check("soaking gives back about 60%", near(coldFish.values.ActualWeight, 5.28) and near(coldFish.values.Calories, 714.4))
check("and says it was cold dried", coldFish.name == "Rehydrated Cold Dried Medium Walleye")
local spawned = newFood("TraditionalPreservationFish.SaltDriedFish", { ActualWeight = 1 })
spawned.displayName = "Salt Dried Fish"
spawned = through(spawned, "SoakedSaltFish")
check("a spawned dried fish keeps the plain item name", spawned.name == nil and spawned:getModData().fishName == nil)

-- Guts
local gutsMade = {}
local inventory = { AddItem = function(_, item) table.insert(gutsMade, item) end }
local gutter = { getInventory = function() return inventory end }
function instanceItem(fullType) return newFood(fullType, {}) end
local function gut(fish, stage)
    gutsMade = {}
    local output = newFood("TraditionalPreservationFish." .. stage, {})
    T.onCreateGutted(newRecipeData(0, { fish }, { output }), gutter)
    return output
end
local walleye = newFood("Base.Walleye", { ActualWeight = 4, BaseHunger = -0.5, HungChange = -0.5, Calories = 400, Proteins = 80 })
walleye.displayName, walleye.age = "Medium Walleye ", 1.5
local gutted = gut(walleye, "GuttedFish")
check("gutting gives guts, then a head", #gutsMade == 2 and gutsMade[1].fullType == "Base.FishGuts" and gutsMade[2].fullType == "TraditionalPreservationFish.FishHead")
check("the guts are a tenth of the fish, by weight and hunger", near(gutsMade[1].values.ActualWeight, 0.4) and near(gutsMade[1].weight, 0.4) and near(gutsMade[1].values.HungChange, -0.05))
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
local stockHead = newFood("TraditionalPreservationFish.FishHead", { Calories = 24, Proteins = 4.8, BaseHunger = -0.03, HungChange = -0.03 })
local stock = newFood("TraditionalPreservationFish.PotOfFishHeadStock", { Calories = 60, BaseHunger = -0.05, HungChange = -0.05 })
function stock:addExtraItem(fullType) self.extras = self.extras or {}; table.insert(self.extras, fullType) end
local pot = newFood("Base.Pot", {})
T.onCreateHeadStock(newRecipeData(0, { pot, stockHead }, { stock }))
check("the stock carries the head's food", near(stock.values.Calories, 24) and near(stock.values.Proteins, 4.8))
check("on top of the broth's hunger", near(stock.values.BaseHunger, -0.08) and near(stock.values.HungChange, -0.08))
check("and lists the head as an ingredient", stock.extras and #stock.extras == 1 and stock.extras[1] == "TraditionalPreservationFish.FishHead")

-- Ingredient stand-ins
ISAddItemInRecipe = { complete = function() return true end }
function require() end
dofile("42/media/lua/shared/TraditionalPreservationFishEvolved.lua")
local listed = { "TraditionalPreservationFish.FishHead", "Base.Carrots", "TraditionalPreservationFish.GuttedFish", "TraditionalPreservationFish.SoakedColdFish" }
local extras = { size = function() return #listed end, get = function(_, i) return listed[i + 1] end, set = function(_, i, v) listed[i + 1] = v end }
T.useStandins({ getExtraItems = function() return extras end })
check("fish stages in a dish become stand-ins", listed[3] == "TraditionalPreservationFish.GuttedFishIngredient" and listed[4] == "TraditionalPreservationFish.SoakedColdFishIngredient")
check("everything else stays", listed[1] == "TraditionalPreservationFish.FishHead" and listed[2] == "Base.Carrots")
-- In a fixed order, so the output is the same on every run.
local standinTypes = {}
for fullType in pairs(T.INGREDIENT_STANDINS) do table.insert(standinTypes, fullType) end
table.sort(standinTypes)
for _, fullType in ipairs(standinTypes) do
    local standin = T.INGREDIENT_STANDINS[fullType]
    local stage, name = fullType:match("%.(.+)$"), standin:match("%.(.+)$")
    local body = script:match("item " .. stage .. "\n    {(.-)\n    }")
    local standinBody = script:match("item " .. name .. "\n    {(.-)\n    }")
    check(name .. " exists with its stage's icon", standinBody and standinBody:find("Icon = " .. stage .. ",", 1, true) ~= nil)
    check(name .. " can't go into a dish itself", not standinBody:find("EvolvedRecipe =", 1, true))
    check(stage .. " goes into dishes", body:find("EvolvedRecipe =", 1, true) ~= nil)
end

-- Fish Head Stock names
NAMES.ContextMenu_EvolvedRecipe_FishHeadStock = "Fish Head Stock"
NAMES.ContextMenu_EvolvedRecipe_and = "and"
NAMES.ContextMenu_EvolvedRecipe_comma = ","
NAMES.IGUI_TraditionalPreservationFish_StockWith = "%1 with %2"
local FOODS = {
    ["TraditionalPreservationFish.FishHead"] = { "Fish", "Fish Head", "Fish" },
    ["TraditionalPreservationFish.GuttedFishIngredient"] = { "Fish", "Gutted Fish", "Fish" },
    ["Base.Carrots"] = { "Vegetables", "Carrots" }, ["Base.Potato"] = { "Vegetables", "Potato" },
    ["Base.Rabbitmeat"] = { "Game", "Rabbit Meat" }, ["Base.Rice"] = { "Rice", "Rice" }, ["Base.Mushroom"] = { "Mushroom", "Mushroom" },
    ["Base.Pepper"] = { "NoExplicit", "Pepper" }, ["Base.Salt"] = { "NoExplicit", "Salt" },
}
for _, t in ipairs({ "Vegetables", "Game", "Rice", "Mushroom", "Fish" }) do NAMES["ContextMenu_FoodType_" .. t] = t end
function isItemFood(t) return FOODS[t] ~= nil end
function hasItemTag(t) return t == "Base.Salt" end
ItemTag.MINOR_INGREDIENT = "minor"
function getItemFoodType(t) return FOODS[t][1] end
function getItemDisplayName(t) return FOODS[t][2] end
function getItemEvolvedRecipeName(t) return FOODS[t][3] end
local function javaList(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
local recipe = { getUntranslatedName = function() return "FishHeadStock" end }
local function stockNamed(extras, spices)
    return T.stockName({ getExtraItems = function() return javaList(extras) end, getSpices = function() return spices and javaList(spices) end }, recipe)
end
check("the head alone leaves the name be", stockNamed({ "TraditionalPreservationFish.FishHead" }) == nil)
check("a fish is named after the stock", stockNamed({ "TraditionalPreservationFish.FishHead", "TraditionalPreservationFish.GuttedFishIngredient" }) == "Fish Head Stock with Fish")
check("two kinds join with and", stockNamed({ "TraditionalPreservationFish.FishHead", "TraditionalPreservationFish.GuttedFishIngredient", "Base.Carrots" }) == "Fish Head Stock with Fish and Carrots")
check("two vegetables become Vegetables", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots", "Base.Potato" }) == "Fish Head Stock with Vegetables")
check("three kinds use a comma", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice" }) == "Fish Head Stock with Carrots, Rabbit Meat and Rice")
check("more than three is just the stock", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice", "Base.Mushroom" }) == "Fish Head Stock")
check("a seasoning is named while there's room", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots" }, { "Base.Pepper" }) == "Fish Head Stock with Carrots and Pepper")
check("minor seasonings such as salt aren't", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots" }, { "Base.Salt" }) == "Fish Head Stock with Carrots")
check("seasonings drop out past three", stockNamed({ "TraditionalPreservationFish.FishHead", "Base.Carrots", "Base.Rabbitmeat", "Base.Rice" }, { "Base.Pepper" }) == "Fish Head Stock with Carrots, Rabbit Meat and Rice")
check("a second head added as an ingredient is named", stockNamed({ "TraditionalPreservationFish.FishHead", "TraditionalPreservationFish.FishHead" }) == "Fish Head Stock with Fish")

-- Butchering XP for packing
Perks = { Butchering = "Butchering" }
local xpGiven = {}
function addXp(character, perk, amount) table.insert(xpGiven, { character = character, perk = perk, amount = amount }) end
local function pack(fish)
    xpGiven, gutsMade = {}, {}
    T.onCreatePacked(newRecipeData(0, { fish }, { newFood("TraditionalPreservationFish.SaltPackedFish", {}) }), gutter)
end
pack(newFood("Base.Walleye", { ActualWeight = 4 }))
check("packing a whole fish guts it, for Butchering XP", #gutsMade == 1 and #xpGiven == 1 and xpGiven[1].perk == "Butchering" and xpGiven[1].amount == T.PACK_GUTTING_XP and xpGiven[1].character == gutter)
pack(newFood("Base.FishFillet", { ActualWeight = 4 }))
check("a fillet only takes the salt, so gives none", #gutsMade == 0 and #xpGiven == 0)
pack(newFood("Base.Bluegill", { ActualWeight = 0.5 }))
check("nor does a fish too small to gut", #xpGiven == 0)

-- How a stack looks on the frame
check("salted fish hangs as salted", T.fishStyle(newFood("TraditionalPreservationFish.SaltPressedFish", {})) == T.STYLE_SALT)
check("gutted fish as gutted", T.fishStyle(newFood("TraditionalPreservationFish.GuttedFish", {})) == T.STYLE_GUTTED)
check("halves as halves", T.fishStyle(newFood("TraditionalPreservationFish.FishHalf", {})) == T.STYLE_HALF)
check("finished salt fish from before styles stays salted", T.fishStyle(newFood("TraditionalPreservationFish.SaltDriedFish", {})) == T.STYLE_SALT)

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
local styled = newRecipeData(0, { newFood("TraditionalPreservationFish.GuttedFish", {}) }, { newFood("TraditionalPreservationFish.ColdDriedFish", {}) })
nextRoll = 2
T.onColdDryStart(styled)
T.onCreateDried(styled)
check("a finished stack keeps the look it had", T.fishStyle(styled:getAllCreatedItems():get(0)) == T.STYLE_HALF)

-- Splitting
local heavy = through(newFood("Base.Walleye", { Calories = 800, BaseHunger = -0.6, HungChange = -0.6, ActualWeight = 4 }), "GuttedFish")
heavy.displayName = nil
check("a fish that fits a stack can't be split", not T.canSplit(through(newFood("Base.Walleye", { ActualWeight = 2 }), "GuttedFish")))
check("a heavier one can", T.canSplit(heavy) and T.canSplit(newFood("Base.KitchenKnife", {})))
local halfOne, halfTwo = newFood("TraditionalPreservationFish.FishHalf", {}), newFood("TraditionalPreservationFish.FishHalf", {})
T.onCreateSplit(newRecipeData(0, { heavy }, { halfOne, halfTwo }))
check("each half keeps half of everything", near(halfOne.values.ActualWeight, 1.6) and near(halfTwo.values.Calories, 376) and near(halfOne.values.HungChange, -0.282))
check("a half is named for its fish, without Gutted", halfOne.name == "Fish Half")
check("a half can't be sliced", not T.canSlice(halfOne))
local driedHalf = through(halfOne, "ColdDriedFish")
check("a half keeps its name through the stages", driedHalf.name == "Cold Dried Fish Half")
local saltedHalf = through(through(through(halfTwo, "SaltPackedFish"), "SaltPressedFish"), "SaltDriedFish")
check("a half can take the salt route too", saltedHalf.name == "Salt Dried Fish Half" and not T.canSlice(saltedHalf))
check("and stays a half in its icon", saltedHalf.modelIndex == halfTwo.modelIndex + #T.FISH_ICONS * 2)
check("as it does when cold dried", driedHalf.modelIndex == halfOne.modelIndex + #T.FISH_ICONS * 2)
local saltedGutted = through(through(heavy, "SaltPackedFish"), "SaltPressedFish")
check("a gutted fish stays headless through the salt route", saltedGutted.modelIndex == heavy.modelIndex + #T.FISH_ICONS)

H.done()
