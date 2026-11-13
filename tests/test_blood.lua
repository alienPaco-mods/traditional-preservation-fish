-- Checks blood: the amounts by weight, its going off and treating, the casing rows, and the recipe script outside
-- the game. Run from the mod folder: luajit tests/test_blood.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(0)
H.installModData()
H.installEvents()

-- Engine stand-ins
Fluid = { Get = function(name) return { name = name } end }
ItemTag = { SALT = "base:salt", VINEGAR = "base:vinegar" }
instanceof = function(o, class) return type(o) == "table" and o.class == class end
ArrayList = { new = function()
    local list = { items = {} }
    function list:add(item) table.insert(self.items, item) end
    function list:size() return #self.items end
    function list:get(i) return self.items[i + 1] end
    return list
end }

local recipeTimes = {}
ScriptManager = { instance = {} }
function ScriptManager.instance:getCraftRecipe(name)
    return { Load = function(_, recipeName, text) recipeTimes[recipeName] = text end }
end

-- Vanilla's tables as the animal definitions build them (the numbers are vanilla's).
AnimalDefinitions = { animals = {
    cow = { minWeight = 360, maxWeight = 950, minBlood = 1000, maxBlood = 3500 },
    sow = { minWeight = 115, maxWeight = 350, minBlood = 800, maxBlood = 2500 },
    ewe = { minWeight = 60, maxWeight = 120, minBlood = 800, maxBlood = 2500 },
    piglet = { minWeight = 15, maxWeight = 110, minBlood = 200, maxBlood = 600 },
    hen = { minWeight = 1, maxWeight = 3 },
} }
local pigParts = { { item = "Base.Pork", minNb = 8, maxNb = 13 } }
local cowParts = { { item = "Base.Steak", minNb = 10, maxNb = 18 } }
AnimalPartsDefinitions = { animals = {
    sowlandrace = { parts = pigParts }, boarlandrace = { parts = pigParts },
    cowangus = { parts = cowParts }, bullangus = { parts = cowParts },
    doewhitetailed = { parts = {} },
} }
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
package.loaded["Definitions/animal/AnimalPartsDefinitions"] = true

dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")
local F = TraditionalPreservationFishMeat
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"

-- Amounts: 3.5 cl a kg of the weight range.
local animals = AnimalDefinitions.animals
check("a cow: 12.6 to 33.3 L", animals.cow.minBlood == 1260 and animals.cow.maxBlood == 3325)
check("a sow: 4 to 12.25 L (vanilla 8 to 25)", animals.sow.minBlood == 403 and animals.sow.maxBlood == 1225)
check("a ewe: 2.1 to 4.2 L", animals.ewe.minBlood == 210 and animals.ewe.maxBlood == 420)
check("a piglet: 0.5 to 3.9 L", animals.piglet.minBlood == 53 and animals.piglet.maxBlood == 385)
check("an animal vanilla gives no blood stays without", animals.hen.minBlood == nil)
F.realBlood(animals)
check("running twice changes nothing", animals.sow.minBlood == 403)

-- Casing rows: one per shared table, however often it runs.
H.fire("OnInitGlobalModData")
F.applyCasingRows()
local function casings(parts)
    local n, row = 0, nil
    for _, part in ipairs(parts) do
        if part.item == F.CASING_ITEM then n, row = n + 1, part end
    end
    return n, row
end
check("the hang recipe's window time is the 24 h of smoke",
    recipeTimes["TraditionalPreservationFishMeat.HangBloodSausageToSmoke"] == "{ time = 86400, }")
local pigN, pigRow = casings(pigParts)
local cowN, cowRow = casings(cowParts)
check("a pig's table gets one casing row", pigN == 1 and pigRow.minNb == 1 and pigRow.maxNb == 1)
check("cattle's gets one, 1 to 2", cowN == 1 and cowRow.maxNb == 2)
check("a deer's too", casings(AnimalPartsDefinitions.animals.doewhitetailed.parts) == 1)

-- Going off
local spec = F.BLOOD_SPEC
check("blood is registered with Core", FluidAgeing.spec("blood") == spec and FluidAgeing.specOfFluid("CuredBlood") == spec)
check("rate 1 at 20 C, a third in a fridge, none frozen", near(spec.rate(20), 1) and near(spec.rate(4), 1 / 3)
    and spec.rate(-1) == 0)
check("fresh blood: a day at 20 C, three in a fridge", FluidAgeing.spoilHours({}, spec) == 24
    and near(24 / spec.rate(4), 72))
check("cured: three days, seven in a fridge", FluidAgeing.spoilHours({ treated = { Cured = true } }, spec) == 72
    and near(72 / F.BLOOD_STATES.Cured.rate(4), 168) and F.BLOOD_STATES.Cured.rate(20) == 1)
check("salt and vinegar are one treatment, Cured", F.BLOOD_TREATMENTS[1].name == "Cured" and F.BLOOD_TREATMENTS[2].name == "Cured")
check("blood never turns: fresh until it spoils", FluidAgeing.stage({ age = 23 }, spec) == "Fresh"
    and FluidAgeing.stage({ age = 24 }, spec) == "Spoiled")

-- Treating
check("a use for each 2 L", FluidAgeing.treatUses(spec, 0.5) == 1 and FluidAgeing.treatUses(spec, 2) == 1
    and FluidAgeing.treatUses(spec, 2.1) == 2 and FluidAgeing.treatUses(spec, 4) == 2)
check("the treat menu is Cure Blood", spec.treatMenu == "ContextMenu_TraditionalPreservationFishMeat_CureBlood" and #spec.treatments == 2)

local function container(fluids)
    local c = { fluids = fluids or {} }
    function c:getSpecificFluidAmount(fluid) return self.fluids[fluid.name] or 0 end
    function c:adjustSpecificFluidAmount(fluid, amount) self.fluids[fluid.name] = amount > 0 and amount or nil end
    function c:addFluid(name, amount) self.fluids[name] = (self.fluids[name] or 0) + amount end
    function c:isEmpty() return next(self.fluids) == nil end
    return c
end
local function bucket(fluids)
    local o = { class = "InventoryItem", fc = container(fluids), md = {} }
    function o:getFluidContainer() return self.fc end
    function o:getModData() return self.md end
    function o:getFullType() return "Base.Bucket" end
    function o:getOutermostContainer() return nil end
    function o:getWorldItem() return nil end
    function o:hasTag() return false end
    return o
end
local function seasoning(tag, uses)
    local o = { uses = uses, tag = tag }
    function o:hasTag(t) return t == self.tag end
    function o:getCurrentUses() return self.uses end
    function o:setCurrentUses(n) self.uses = n end
    function o:getContainer() return { DoRemoveItem = function() o.removed = true end } end
    return o
end
local function carrying(items)
    local character = {}
    function character:getInventory()
        return { getAllTagRecurse = function(_, tag, list)
            for _, item in ipairs(items) do if item.tag == tag then list:add(item) end end
            return list
        end }
    end
    return character
end
local function recipeData(keep)
    return { getAllKeepInputItems = function() return H.list(keep) end }
end

local SALT, VINEGAR = F.BLOOD_TREATMENTS[1], F.BLOOD_TREATMENTS[2]
local pail = bucket({ AnimalBlood = 4 })
local salt = seasoning("base:salt", 1)
check("4 L wants 2 salt: one use is not enough", FluidAgeing.treatRefusal(pail, spec, SALT, carrying({ salt }))
    == "IGUI_TraditionalPreservationCore_TreatShort")
local more = seasoning("base:salt", 10)
check("with enough salt it can", FluidAgeing.treatRefusal(pail, spec, SALT, carrying({ salt, more })) == nil)
check("curing takes both uses, part-used salt first", FluidAgeing.treatBy(pail, spec, SALT, carrying({ salt, more }))
    and pail.fc.fluids.CuredBlood == 4 and salt.uses == 0 and salt.removed and more.uses == 9)
check("cured blood can't be cured again with salt", FluidAgeing.treatRefusal(pail, spec, SALT, carrying({ more }))
    == "IGUI_TraditionalPreservationCore_TreatDone")
local vinegar = seasoning("base:vinegar", 10)
check("nor with vinegar", FluidAgeing.treatRefusal(pail, spec, VINEGAR, carrying({ vinegar }))
    == "IGUI_TraditionalPreservationCore_TreatDone")
local soured = bucket({ AnimalBlood = 1 })
FluidAgeing.treatBy(soured, spec, VINEGAR, carrying({ vinegar }))
check("vinegar alone cures it too", soured.fc.fluids.CuredBlood == 1 and vinegar.uses == 9)
local jar = bucket({})
FluidAgeing.pour(soured, jar, 0)
jar.fc.fluids.CuredBlood = 1
FluidAgeing.look(jar, 0, "Sheltered")
check("cured into cured stays cured", jar.md.tpFluidAge.treated.Cured and jar.fc.fluids.CuredBlood == 1)
check("water is not blood", FluidAgeing.treatRefusal(bucket({ Water = 2 }), spec, SALT, carrying({ more }))
    == "IGUI_TraditionalPreservationCore_TreatNoFluid")
local old = bucket({ AnimalBlood = 1 })
FluidAgeing.look(old, 0, "Sheltered")
old.md.tpFluidAge.age = 30
FluidAgeing.look(old, 0, "Sheltered")
check("spoiled blood can't be saved", old.fc.fluids.SpoiledBlood == 1
    and FluidAgeing.treatRefusal(old, spec, SALT, carrying({ more })) == "IGUI_TraditionalPreservationCore_TreatSpoiled")

-- The ledger counts blood by place
H.setHours(1)
F.recordBlood(1, 20)
check("the blood ledger counts an hour at 20 C in the open, for each kind", near(F.bloodLedger().bloodOpen, 1)
    and near(F.bloodLedger().bloodCuredOpen, 1))

-- The script: every recipe takes only usable blood, and every item a recipe names exists.
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat_Blood.txt"):read("*a")
local items = {}
for name in script:gmatch("\n    item (%w+)") do items[name] = true end
for line in script:gmatch("%-fluid [%d.]+ %[([^%]]+)%]") do
    if line ~= "Water" then
        local ok = true
        for name in line:gmatch("[^;]+") do ok = ok and F.USABLE_BLOOD[name] == true end
        check("a recipe's blood is fresh or treated: " .. line, ok)
    end
end
for name in script:gmatch("TraditionalPreservationFishMeat%.(%u%w+)") do
    check("the script's item exists: " .. name, items[name] or name == "PorkFat" or name == "BeefSuet"
        or name == "MuttonFat" or name == "Tallow")
end
local Charge = require "TraditionalPreservationCore/Charge"
local fillerLines = 0
for line in script:gmatch("item 1 %[[^%]]*%] mode:keep") do
    if Charge.forScriptLine(line) == F.FILLER then fillerLines = fillerLines + 1 end
end
check("both mixes take the filler on one charged line", fillerLines == 2 and F.FILLER.need("Base.Rice") == 12
    and F.FILLER.need("Base.WheatSeed") == 12)
local fluids = io.open("42/media/scripts/TraditionalPreservationFishMeat_fluids.txt"):read("*a")
for _, name in ipairs({ "CuredBlood", "SpoiledBlood" }) do
    check("fluid " .. name .. " is defined", fluids:find("fluid " .. name .. "\n", 1, true) ~= nil)
end

-- The food: a slice or a link is a sixth of the mix.
local function field(item, key)
    local body = script:match("\n    item " .. item .. "\n    {(.-)\n    }")
    return tonumber(body:match(key .. " = (%-?[%d.]+)"))
end
check("a slice is a sixth of the loaf", near(field("BlackPuddingSlice", "Calories") * 6, field("BlackPudding", "Calories"), 1)
    and near(field("BlackPuddingSlice", "HungerChange") * 6, field("BlackPudding", "HungerChange")))
check("a link is a slice's food", field("BloodSausage", "Calories") == field("BlackPuddingSlice", "Calories")
    and field("RawBloodSausage", "Calories") == field("BloodSausage", "Calories"))
check("a sausage slice is a quarter link", near(field("BloodSausageSlice", "Calories") * 4, field("BloodSausage", "Calories"))
    and near(field("BloodSausageSlice", "Weight") * 4, field("BloodSausage", "Weight")))
check("calories follow the macros", near(field("BloodSausage", "Proteins") * 4 + field("BloodSausage", "Lipids") * 9
    + field("BloodSausage", "Carbohydrates") * 4, field("BloodSausage", "Calories"), 1))

-- Smoked Blood Sausage: the script, then the stack against the Smokehouse's cold counter.
check("a smoked link keeps 21 / 40, a boiled link's food, and dries to 0.22",
    field("SmokedBloodSausage", "DaysFresh") == 21 and field("SmokedBloodSausage", "DaysTotallyRotten") == 40
    and field("SmokedBloodSausage", "Calories") == field("BloodSausage", "Calories")
    and field("SmokedBloodSausage", "HungerChange") == field("BloodSausage", "HungerChange")
    and field("SmokedBloodSausage", "Weight") == 0.22)
check("a smoked slice is a quarter link and keeps as the link",
    near(field("SmokedBloodSausageSlice", "Calories") * 4, field("SmokedBloodSausage", "Calories"))
    and near(field("SmokedBloodSausageSlice", "Weight") * 4, field("SmokedBloodSausage", "Weight"))
    and field("SmokedBloodSausageSlice", "DaysFresh") == 21 and field("SmokedBloodSausageSlice", "DaysTotallyRotten") == 40)
local hang = script:match("craftRecipe HangBloodSausageToSmoke\n    {(.-)\n    }\n")
check("the hang recipe is the Smokehouse's alone and takes only boiled links", hang
    and hang:find("Tags = Smokehouse,", 1, true) and hang:find("[TraditionalPreservationFishMeat.BloodSausage]", 1, true)
    and hang:find("IsCookedFoodItem", 1, true))

H.installGetText()
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
local Hearth = require "TraditionalPreservationCore/Hearth"
local OnHeat = require "TraditionalPreservationCore/OnHeat"

local OFF_AGES = { ["TraditionalPreservationFishMeat.BloodSausage"] = 7, ["TraditionalPreservationFishMeat.SmokedBloodSausage"] = 21 }
local function link(fullType, age, share)
    local o = { fullType = fullType, age = age or 0, md = {}, hunger = -30 * (share or 1), calories = 538 * (share or 1),
        weight = fullType == "TraditionalPreservationFishMeat.BloodSausage" and 0.25 or 0.22 }
    function o:getFullType() return self.fullType end
    function o:getModData() return self.md end
    function o:getAge() return self.age end
    function o:setAge(age) self.age = age end
    function o:getOffAge() return OFF_AGES[self.fullType] end
    function o:setCooked(cooked) self.cooked = cooked end
    function o:getBaseHunger() return -30 end
    function o:getHungChange() return self.hunger end
    function o:setHungChange(n) self.hunger = n end
    function o:getCalories() return 538 end
    function o:setCalories(n) self.calories = n end
    for _, name in ipairs({ "Proteins", "Lipids", "Carbohydrates" }) do
        o["get" .. name] = function() return 10 end
        o["set" .. name] = function(self, n) self[name] = n end
    end
    function o:getActualWeight() return self.weight end
    function o:setActualWeight(n) self.weight = n end
    function o:setCustomWeight() end
    return o
end
instanceItem = function(fullType) return link(fullType) end
local function links(...)
    local list = ArrayList.new()
    for _, item in ipairs({ ... }) do list:add(item) end
    return list
end

local fried = link(F.BLOOD_SAUSAGE)
fried.md[OnHeat.KEY] = { done = true }
check("a fried link stays out, a boiled one goes in", not F.canSmokeBloodSausage(fried)
    and F.canSmokeBloodSausage(link(F.BLOOD_SAUSAGE)))
check("only the Smokehouse takes blood sausage, and never a fried link",
    F.sausageRefusal({ closed = true }, link(F.BLOOD_SAUSAGE)) == nil
    and F.sausageRefusal({}, link(F.BLOOD_SAUSAGE)) == "IGUI_TraditionalPreservationFishMeat_SausageSmokehouse"
    and F.sausageRefusal({ closed = true }, fried) == "IGUI_TraditionalPreservationFishMeat_SausageFried")
check("a sausage stack is its own kind", F.hangKind(F.BLOOD_SAUSAGE) == "sausage"
    and F.hangKind(F.CURED_MEAT) ~= "sausage")

local stack = { leftover = true, cold = 50 }
F.startSausageSmoke(stack, links(link(F.BLOOD_SAUSAGE, 1), link(F.BLOOD_SAUSAGE, 3)), 100, 1)
check("a new stack forgets the pooled data, needs 24 h and takes no cook", stack.leftover == nil and stack.cold == 0
    and F.coldNeed(stack) == 24 and stack.noHot and stack.sausage and stack.stackId == 100)
check("it goes stale when its freshest link would (6 days left)", near(stack.staleAt, 100 + 6 * 24))

local fire = {}
Hearth.logFire(fire, 100, nil, nil)
F.smokeStep(stack, fire)
Hearth.logFire(fire, 101, Hearth.STOKED, 140)
Hearth.logFire(fire, 111, Hearth.STOKED, 140)
F.smokeStep(stack, fire)
check("stoked hours are smoke at once, never a cook", near(stack.cold, 10) and not F.hotDone(stack))
F.sausageSmokeStep(stack, 111)
check("10 of 24 h: not smoked, the bar at 10/24", stack.smokedAt == nil and near(F.sausageProgress(stack, 111), 10 / 24))
Hearth.logFire(fire, 112, Hearth.BANKED, 200)
Hearth.logFire(fire, 132, Hearth.BANKED, 200)
F.smokeStep(stack, fire)
F.sausageSmokeStep(stack, 132)
check("banked hours count too, and the smoked hour is placed within the stretch", near(stack.cold, 31)
    and near(stack.smokedAt, 111 + 21 * 14 / 21))
check("done, it waits for the World's look at its shed", F.sausageProgress(stack, 132) == F.SHED_WAIT)
F.smokeStations[stack.stackId] = {}
check("then it ends", F.sausageProgress(stack, 132) == 1)

local now = 132
local smoked = F.smokedLink(link(F.BLOOD_SAUSAGE, 1), stack, now, 1)
local ageThen = 1 + (stack.smokedAt - 100) / 24
check("smoked in time: Smoked, cooked, its age the same share of 21 days plus the days since",
    smoked.fullType == F.SMOKED_BLOOD_SAUSAGE and smoked.cooked
    and near(smoked.age, ageThen / 7 * 21 + (now - stack.smokedAt) / 24))
local stale = F.smokedLink(link(F.BLOOD_SAUSAGE, 6.5), stack, now, 1)
check("one that went stale before the smoke was done comes down Boiled, aged by the days it hung",
    stale.fullType == F.BLOOD_SAUSAGE and stale.cooked and near(stale.age, 6.5 + 32 / 24))
local half = F.smokedLink(link(F.BLOOD_SAUSAGE, 0, 0.5), stack, now, 1)
check("a part-eaten link keeps its share", near(half.hunger, -15) and near(half.calories, 269) and near(half.weight, 0.11))
check("Food Spoilage's speed runs the clock", near(F.smokedLink(link(F.BLOOD_SAUSAGE, 6.5), stack, now, 0.25).age,
    (6.5 + (stack.smokedAt - 100) / 24 * 0.25) / 7 * 21 + (now - stack.smokedAt) / 24 * 0.25))

local cold = {}
F.startSausageSmoke(cold, links(link(F.BLOOD_SAUSAGE, 0)), 200, 1)
F.smokeStations[200] = {}
check("with no fire the stack ends when its links have gone stale", F.sausageProgress(cold, 200 + 7 * 24 - 1) < 1
    and F.sausageProgress(cold, 200 + 7 * 24) == 1)
check("and they come down Boiled", F.smokedLink(link(F.BLOOD_SAUSAGE, 0), cold, 200 + 7 * 24, 1).fullType == F.BLOOD_SAUSAGE)
local status = F.sausageStatus(cold, { temperature = 5 }, 200 + 24)
check("the popup: no fire, six days left", status.state == "NoFire" and near(status.staleDays, 6) and status.need == 24)
cold.burning = Hearth.BANKED
check("a fire on a warm day doesn't count", F.sausageStatus(cold, { temperature = 20 }, 200).state == "TooWarm"
    and F.sausageStatus(cold, { temperature = 10 }, 200).state == "Smoking")
check("once smoked, no stale countdown", F.sausageStatus(stack, { temperature = 5 }, now).staleDays == nil)

H.done()
