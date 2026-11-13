-- Checks ageing dry cured meat and the slices (6c) outside the game. Run from the mod folder: luajit tests/test_aged.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()
function getItemNameFromFullType(fullType) return (fullType:gsub("^[^.]*%.", "")) end
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSlices.lua")
local F = TraditionalPreservationFishMeat

-- A food item with the script's keeping days.
local DAYS = {
    [F.DRY_CURED] = { 120, 180 }, [F.COUNTRY_HAM] = { 180, 365 }, [F.HOT_MEAT] = { 7, 14 },
    ["TraditionalPreservationFishMeat.DryCuredMeatSlice"] = { 60, 90 },
    ["TraditionalPreservationFishMeat.CountryHamSlice"] = { 90, 180 },
    ["TraditionalPreservationFishMeat.HotSmokedMeatSlice"] = { 3, 7 },
}
local FIELDS = { "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange", "ActualWeight", "Age",
    "UnhappyChange", "BoredomChange", "ThirstChange", "ModelIndex", "Tooltip", "Name" }
local function food(fullType, values, modData)
    local item = { fullType = fullType, values = values or {}, modData = modData or {} }
    for _, field in ipairs(FIELDS) do
        item["get" .. field] = function(self) return self.values[field] or 0 end
        item["set" .. field] = function(self, value) self.values[field] = value end
    end
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:getDisplayName() return self.values.Name end
    function item:setCustomName() end
    function item:setCustomWeight() end
    function item:getOffAge() return DAYS[self.fullType][1] end
    function item:getOffAgeMax() return DAYS[self.fullType][2] end
    return item
end
local function recipe(piece, sliceType, count)
    local slices = {}
    for index = 1, count do slices[index] = food(sliceType) end
    return {
        getAllInputItemsWithFlag = function() return H.list({ piece }) end,
        getAllCreatedItems = function() return H.list(slices) end,
    }, slices
end

-- Ageing
local beef = food(F.DRY_CURED, { ModelIndex = 0, Age = 10, BaseHunger = -0.28, HungChange = -0.28, UnhappyChange = -3 }, { agedFrom = 10 })
check("a cut takes 30 days, a ham 90, a slice doesn't age", F.ageDays(beef) == 30 and F.ageDays(food(F.COUNTRY_HAM)) == 90
    and F.ageDays(food("TraditionalPreservationFishMeat.DryCuredMeatSlice")) == nil and F.ageDays(food(F.HOT_MEAT)) == nil)
check("young off the hook", F.agedness(beef) == 0 and F.stageName(beef) == "Beef (Cold Smoked)")
beef:setAge(25)
F.rename(beef)
check("half aged after 15 days: the tooltip says so, the mood is the young one's", near(F.agedness(beef), 0.5)
    and beef.values.Tooltip == "Tooltip_TraditionalPreservationFishMeat_DryCured_50" and beef.values.UnhappyChange == -3 and not beef.modData.aged)
beef:setAge(40)
F.rename(beef)
check("Aged after 30", beef.values.Name == "Beef (Cold Smoked, Aged)" and beef.modData.aged == true and beef.values.UnhappyChange == F.AGED_CUT_UNHAPPY
    and beef.values.Tooltip == "Tooltip_TraditionalPreservationFishMeat_DryCured_Aged")
beef:setAge(0)
check("and it stays Aged", F.agedness(beef) == 1)
local old = food(F.COUNTRY_HAM, { ModelIndex = 6, Age = 95 }, { airDried = true })
check("a ham from before 6c counts all its days", F.agedness(old) == 1 and F.stageName(old) == "Country Ham (Aged)")
local eaten = food(F.COUNTRY_HAM, { ModelIndex = 6, Age = 90, BaseHunger = -2, HungChange = -1, UnhappyChange = -5 })
F.rename(eaten)
check("a half-eaten ham gets half the aged mood and boredom", near(eaten.values.UnhappyChange, F.AGED_HAM_UNHAPPY / 2)
    and near(eaten.values.BoredomChange, F.AGED_HAM_BOREDOM / 2) and eaten.values.Name == "Smoked Country Ham (Aged)"
    and eaten.values.Tooltip == "Tooltip_TraditionalPreservationFishMeat_CountryHam_Aged")
local texts = H.loadTranslations("42/media/lua/shared/Translate/EN")
local missing = {}
for _, base in ipairs({ "DryCured", "AirDried", "CountryHam" }) do
    for _, suffix in ipairs({ "0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "Aged" }) do
        local key = "Tooltip_TraditionalPreservationFishMeat_" .. base .. "_" .. suffix
        if not texts[key] then table.insert(missing, key) end
    end
end
check("every ageing tooltip has its text" .. table.concat(missing, " "), #missing == 0)

-- Left hanging: three quarters of the time
local hung = food(F.COUNTRY_HAM, { ModelIndex = 6, Age = 0 }, { agedFrom = 0 })
F.ageHanging(hung, 1000)
check("the first look only notes the hour", hung.modData.hungHour == 1000 and hung.modData.agedFrom == 0)
F.ageHanging(hung, 1000.5)
check("not within the hour", hung.modData.hungHour == 1000)
F.ageHanging(hung, 1000 + 67.5 * 24)
check("67.5 days hanging add 22.5", near(hung.modData.agedFrom, -22.5))
hung:setAge(67.5)
check("so a hanging ham is Aged in 67.5 days", near(F.agedness(hung), 1))
local shelf = food(F.COUNTRY_HAM, { ModelIndex = 6, Age = 67.5 }, { agedFrom = 0 })
check("on a shelf it is three quarters there", near(F.agedness(shelf), 0.75))
local fish = food("TraditionalPreservationFishMeat.SaltDriedFish")
F.ageHanging(fish, 1000)
check("fish left hanging is left alone", fish.modData.hungHour == nil)

-- Slicing a cut: slices of about hunger 14, the first two the recipe's, the rest handed to the character
local given = {}
local inventory = { AddItem = function(_, item) table.insert(given, item) return item end }
local character = { getInventory = function() return inventory end }
function instanceItem(fullType) return food(fullType) end
local piece = food(F.DRY_CURED, { ModelIndex = 0, Age = 60, Calories = 396, Proteins = 30, Lipids = 9, BaseHunger = -0.56, HungChange = -0.54,
    ActualWeight = 0.25, UnhappyChange = -3, ThirstChange = 0.24 }, { agedFrom = 0, airDried = true })
check("a dry cured Beef is four slices, a chop two, a Beef (Hot Smoked) six", F.sliceCount(piece) == 4
    and F.sliceCount(food(F.DRY_CURED, { HungChange = -0.21 })) == 2 and F.sliceCount(food(F.HOT_MEAT, { HungChange = -0.8 })) == 6
    and F.sliceCount(food(F.HOT_MEAT, { HungChange = -0.05 })) == 2)
local data, slices = recipe(piece, "TraditionalPreservationFishMeat.DryCuredMeatSlice", F.MIN_SLICES)
F.onCreateMeatSliced(data, character)
local slice = given[2]
check("the recipe's two and two more to the character", #given == 2 and slice.fullType == "TraditionalPreservationFishMeat.DryCuredMeatSlice")
check("four slices share the cut's food and weight", near(slice.values.Calories, 99) and near(slice.values.HungChange, -0.135)
    and near(slices[1].values.HungChange, -0.135) and near(slice.values.ActualWeight, 0.0625) and near(slice.values.ThirstChange, 0.06))
check("a slice is whole, not part eaten", slice.values.BaseHunger == slice.values.HungChange)
check("named by the piece, aged with it", slice.values.Name == "Beef Slice (Dry Cured, Aged)" and slice.modData.aged == true and slice.modData.cut == 0)
check("the aged mood is shared out", near(slice.values.UnhappyChange, F.AGED_CUT_UNHAPPY * (0.54 / 0.56) / 4))
check("half through its days, as the cut was", near(slice.values.Age, 30))
check("stale keeps its share too", near(F.sliceAge(150, 120, 180, 60, 90), 75) and near(F.sliceAge(400, 120, 180, 60, 90), 90))
given = {}
local hot = food(F.HOT_MEAT, { ModelIndex = 3, Age = 3.5, HungChange = -0.8, BaseHunger = -0.8 })
data, slices = recipe(hot, "TraditionalPreservationFishMeat.HotSmokedMeatSlice", F.MIN_SLICES)
F.onCreateMeatSliced(data, character)
check("hot smoked venison: six slices of about 13", #given == 4 and slices[2].values.Name == "Venison Slice (Hot Smoked)"
    and near(slices[2].values.Age, 1.5) and near(given[4].values.HungChange, -0.8 / 6))

-- Hot smoked poultry (0.4.34): no slicing; a whole bird carves into vanilla's six cuts, food by their hunger
local VANILLA_HUNGER = { ["Base.Chicken"] = -0.33, ["Base.ChickenWings"] = -0.19, ["Base.ChickenFillet"] = -0.3 }
local oldInstance = instanceItem
function instanceItem(fullType) return food(fullType, { HungChange = VANILLA_HUNGER[fullType] }) end
local smokedBird = food(F.HOT_MEAT, { ModelIndex = 10, Age = 2, Calories = 1640, HungChange = -1.64, BaseHunger = -1.64,
    ActualWeight = 0.8, ThirstChange = 0.15, UnhappyChange = -5 }, { rinsed = true })
check("hot smoked poultry isn't sliced, red meat and anything else is", not F.canSliceHot(smokedBird)
    and F.canSliceHot(food(F.HOT_MEAT, { ModelIndex = 3 })) and F.canSliceHot(knife or food("Base.KitchenKnife")))
check("the chicken recipe takes a whole chicken only", F.canCarveChicken(smokedBird) and not F.canCarveTurkey(smokedBird)
    and not F.canCarveChicken(food(F.HOT_MEAT, { ModelIndex = 7 })) and F.canCarveChicken(food("Base.KitchenKnife")))
local birdData, cuts = recipe(smokedBird, F.HOT_MEAT, 6)
F.onCreateBirdCarved(birdData)
check("2 legs, 2 wings, 2 fillets", cuts[1].values.ModelIndex == 7 and cuts[2].values.ModelIndex == 7 and cuts[3].values.ModelIndex == 8
    and cuts[6].values.ModelIndex == 9)
check("sharing the bird by vanilla's hunger", near(cuts[1].values.HungChange, -1.64 * 0.33 / 1.64) and near(cuts[3].values.Calories, 1640 * 0.19 / 1.64)
    and near(cuts[1].values.ActualWeight + cuts[3].values.ActualWeight + cuts[5].values.ActualWeight, 0.8 * 0.9 / 2))
check("each keeps the bird's age and rinse, named by its cut", cuts[5].values.Age == 2 and cuts[5].modData.rinsed
    and cuts[1].values.Name == "Chicken (Hot Smoked)" and cuts[5].values.Name == "ChickenFillet (Hot Smoked)")
instanceItem = oldInstance

-- Carving a ham: 15 slices of hunger 14 from a leg, in three carvings
local ham = food(F.COUNTRY_HAM, { ModelIndex = 6, Age = 45, Calories = 1350, Proteins = 225, Lipids = 54, BaseHunger = -2.1, HungChange = -2.1,
    ActualWeight = 1.25, UnhappyChange = -10, ThirstChange = 0.25 }, { agedFrom = 0 })
local knife = food("Base.KitchenKnife")
check("a whole ham carves, and it isn't its last", F.canCarve(ham) and not F.canCarveLast(ham) and F.canCarve(knife) and F.canCarveLast(knife))
data, slices = recipe(ham, "TraditionalPreservationFishMeat.CountryHamSlice", F.CARVE_SLICES)
F.onCreateCarved(data)
check("five slices of hunger 14 come off", #slices == 5 and near(slices[1].values.HungChange, -0.14) and near(slices[5].values.Calories, 1350 / 15)
    and near(slices[1].values.ActualWeight, 1.25 / 15) and slices[1].values.Name == "Smoked Country Ham Slice" and not slices[1].modData.aged)
check("the ham stays, lighter", near(ham.values.HungChange, -1.4) and ham.values.BaseHunger == -2.1 and near(ham.values.Calories, 900)
    and near(ham.values.ActualWeight, 1.25 * 2 / 3) and near(ham.values.UnhappyChange, -10 * 2 / 3))
check("a slice starts a quarter through its 90 days, as the ham is through its 180", near(slices[1].values.Age, 22.5) and ham.values.Age == 45)
F.onCreateCarved((recipe(ham, "TraditionalPreservationFishMeat.CountryHamSlice", F.CARVE_SLICES)))
check("after two carvings the next is the last", near(ham.values.HungChange, -0.7) and not F.canCarve(ham) and F.canCarveLast(ham))
ham:setAge(100)
data, slices = recipe(ham, "TraditionalPreservationFishMeat.CountryHamSlice", F.CARVE_SLICES)
F.onCreateLastCarved(data)
check("the last carving takes it all, Aged by now", near(slices[1].values.HungChange, -0.14)
    and slices[1].values.Name == "Smoked Country Ham Slice (Aged)"
    and near(slices[1].values.UnhappyChange, F.AGED_HAM_UNHAPPY / 15) and near(slices[1].values.BoredomChange, F.AGED_HAM_BOREDOM / 15))

-- Sandbox
SandboxVars = { TraditionalPreservationFishMeat = { AgeCutDays = 10, AgeHamDays = 45 } }
F.applySandbox()
check("the sandbox sets both ageing times", F.AGE_CUT_DAYS == 10 and F.AGE_HAM_DAYS == 45)

-- Scripts
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
for piece, sliceType in pairs(F.SLICES) do
    local name = sliceType:gsub("^[^.]*%.", "")
    local body = script:match("item " .. name .. "%s*{(.-)}")
    local fresh, rotten = DAYS[sliceType][1], DAYS[sliceType][2]
    check(name .. " keeps half its piece's days", body ~= nil and body:find("DaysFresh = " .. fresh .. ",%s*DaysTotallyRotten = " .. rotten .. ",") ~= nil
        and fresh <= DAYS[piece][1] / 2 and rotten <= DAYS[piece][2] / 2)
    local dish = tonumber(body:match("Sandwich:(%d+)"))
    check(name .. " goes into a dish whole", dish ~= nil and dish >= F.SLICE_HUNGER * 100 and dish >= F.CARVE_HUNGER / F.CARVE_SLICES * 100)
    check(name .. " is in the stage tables", F.STAGES[sliceType].slice == true and F.isMeatStage(sliceType))
end
-- The engine reads UnhappyChange and BoredomChange as whole numbers: a fraction fails the whole script load.
local fractions = {}
for _, path in ipairs({ "42/media/scripts/TraditionalPreservationFishMeat_Meat.txt", "42/media/scripts/TraditionalPreservationFishMeat.txt" }) do
    for field, value in io.open(path):read("*a"):gmatch("(%a+Change) = (-?[%d.]+),") do
        if (field == "UnhappyChange" or field == "BoredomChange") and value:find(".", 1, true) then table.insert(fractions, field .. " " .. value) end
    end
end
check("no script gives a fraction of mood " .. table.concat(fractions, ", "), #fractions == 0)
check("the scripts give the two slices and the five the code counts on",
    script:match("craftRecipe SliceDryCuredMeat%s*{(.-)\n    }"):find("item " .. F.MIN_SLICES .. " TraditionalPreservationFishMeat.DryCuredMeatSlice", 1, true) ~= nil
    and script:match("craftRecipe SliceHotSmokedMeat%s*{(.-)\n    }"):find("item " .. F.MIN_SLICES .. " TraditionalPreservationFishMeat.HotSmokedMeatSlice", 1, true) ~= nil
    and script:match("craftRecipe CarveCountryHam%s*{(.-)\n    }"):find("item " .. F.CARVE_SLICES .. " TraditionalPreservationFishMeat.CountryHamSlice", 1, true) ~= nil
    and script:match("craftRecipe CarveLastOfCountryHam%s*{(.-)\n    }"):find("item " .. F.CARVE_SLICES .. " TraditionalPreservationFishMeat.CountryHamSlice", 1, true) ~= nil)
check("carving keeps the ham, the last carving doesn't",
    script:match("craftRecipe CarveCountryHam%s*{(.-)outputs"):find("CountryHam] flags[ItemCount] mode:keep", 1, true) ~= nil
    and script:match("craftRecipe CarveLastOfCountryHam%s*{(.-)outputs"):find("CountryHam] flags[ItemCount] mode:destroy", 1, true) ~= nil)
check("a young Country Ham lifts the mood by 10", script:match("item CountryHam%s*{(.-)}"):find("UnhappyChange = -10,", 1, true) ~= nil)

H.done()
