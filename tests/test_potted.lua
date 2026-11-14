-- Checks Potted Meat (phase 4b) outside the game: the batch in the pot, adding cuts, packing the crock, eating
-- from it and getting the jar back. Run from the mod folder: luajit tests/test_potted.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installGetText()

-- A food item with just what the Potted Meat code calls.
local function newFood(fullType, v)
    local item = { fullType = fullType, modData = {}, age = v.age or 0, condition = 10, burnt = v.burnt, cooked = v.cooked,
        hunger = v.hunger or 0, base = v.hunger or 0, calories = v.calories or 0, carbs = v.carbs or 0,
        lipids = v.lipids or 0, proteins = v.proteins or 0, weight = v.weight or 0 }
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:getHungChange() return self.hunger end
    function item:setHungChange(x) self.hunger = x end
    function item:getBaseHunger() return self.base end
    function item:setBaseHunger(x) self.base = x end
    function item:getCalories() return self.calories end
    function item:setCalories(x) self.calories = x end
    function item:getCarbohydrates() return self.carbs end
    function item:setCarbohydrates(x) self.carbs = x end
    function item:getLipids() return self.lipids end
    function item:setLipids(x) self.lipids = x end
    function item:getProteins() return self.proteins end
    function item:setProteins(x) self.proteins = x end
    function item:getActualWeight() return self.weight end
    function item:setActualWeight(x) self.weight = x end
    function item:setCustomWeight(x) self.customWeight = x end
    function item:setName(x) self.name = x end
    function item:setCustomName(x) self.customName = x end
    function item:setModelIndex(x) self.modelIndex = x end
    function item:getAge() return self.age end
    function item:setAge(x) self.age = x end
    function item:getCondition() return self.condition end
    function item:setCondition(x) self.condition = x end
    function item:isBurnt() return self.burnt == true end
    function item:isCooked() return self.cooked == true end
    function item:getContainer() return self.container end
    function item:getOffAge() return v.offAge or 60 end
    function item:getOffAgeMax() return v.offAgeMax or 90 end
    function item:getOutermostContainer() return nil end
    function item:getWorldItem() return nil end
    return item
end

-- Vanilla's values, hunger as the engine keeps it.
local function steak() return newFood("Base.Steak", { hunger = -0.4, calories = 220, lipids = 9.35, proteins = 31.62, weight = 0.3 }) end
local function beef() return newFood("Base.Beef", { hunger = -0.8, calories = 440, lipids = 18.7, proteins = 62.62, weight = 0.5 }) end
local function porkChop() return newFood("Base.PorkChop", { hunger = -0.3, calories = 150, lipids = 6, proteins = 25, weight = 0.3 }) end
local function lard(share)
    share = share or 1
    return newFood("Base.Lard", { hunger = -0.24 * share, calories = 4095 * share, lipids = 454 * share, weight = 0.3 })
end

local function craft(consumed, created, character)
    return {
        getAllConsumedItems = function() return H.list(consumed) end,
        getAllCreatedItems = function() return H.list(created) end,
        getCharacter = function() return character end,
    }
end

ScriptManager = { instance = { getItem = function(_, fullType)
    local weights = { ["Base.ClayJar"] = 0.3, ["Base.ClayJarGlazed"] = 0.3, ["Base.ClayPot"] = 0.3 }
    return weights[fullType] and { getActualWeight = function() return weights[fullType] end }
end } }
getItemNameFromFullType = function() return "Crock of Potted Meat" end
Perks = { Cooking = "Cooking" }
local xp = 0
H.installClock(0)
local globalData = {}
ModData = { getOrCreate = function(key) globalData[key] = globalData[key] or {} return globalData[key] end }
addXp = function(_, perk, amount) if perk == Perks.Cooking then xp = xp + amount end end

-- A stub eat action, wrapped by the mod as the game's is: it eats a share of the item's food.
ISEatFoodAction = {}
function ISEatFoodAction.complete(self)
    local item = self.item
    for _, key in ipairs({ "hunger", "calories", "carbs", "lipids", "proteins" }) do item[key] = item[key] * (1 - self.share) end
    return true
end
ISEatFoodAction.serverStop = ISEatFoodAction.complete

dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
local F = TraditionalPreservationFishMeat
local POT, CROCK = "TraditionalPreservationFishMeat.PotOfMeatInFat", F.CROCK

-- Putting meat in fat
local pot = newFood(POT, {})
local salt = newFood("Base.Salt", {})
F.onPutMeatInFat(craft({ steak(), lard(), salt }, { pot }))
local batch = pot.modData.tpfmPotted
check("a Steak and a block of Lard make a batch of one portion", batch.portions == 1)
check("it takes a quarter block of the fat", near(batch.blocks, 0.75) and near(pot.calories, 220 + 4095 / 4))
check("the pot shows the batch's food", near(pot.hunger, -0.4 - 0.06) and near(pot.base, pot.hunger))
check("its weight: two thirds of the cut plus the fat", near(batch.weight, 0.3 * 0.67 + 0.3 / 4))

check("an uncooked pot of one cut takes more", F.canAddPottedCut(pot))
for _, cut in ipairs({ beef(), porkChop(), steak() }) do
    local again = newFood(POT, {})
    F.onAddPottedCut(craft({ pot, cut }, { again }))
    again.age = pot.age
    pot = again
end
batch = pot.modData.tpfmPotted
check("three more cuts make four portions", batch.portions == 4)
check("four cuts use the whole block", near(batch.blocks, 0))
check("food is the cuts' and the block's", near(pot.calories, 220 + 440 + 150 + 220 + 4095))
check("a pot of four takes no fifth", not F.canAddPottedCut(pot))
pot.modData.tpfmPotted = { portions = 2, food = {}, weight = 0, fat = F.FAT_BLOCK, blocks = 0.5 }
pot.cooked = true
check("a cooked pot takes no more", not F.canAddPottedCut(pot))
pot.modData.tpfmPotted = batch
check("other inputs pass the test", F.canAddPottedCut(steak()))

-- Melted fat counts as a whole block; a part-used block gives what it has left
local melted = newFood(POT, {})
F.onPutMeatInFat(craft({ beef(), salt }, { melted }))
check("a pot of melted fat is a block", near(melted.calories, 440 + 4095 / 4))
local scraps = newFood(POT, {})
F.onPutMeatInFat(craft({ steak(), lard(0.1), salt }, { scraps }))
check("a tenth of a block gives a tenth", near(scraps.calories, 220 + 409.5) and near(scraps.modData.tpfmPotted.blocks, 0))
local more = newFood(POT, {})
F.onAddPottedCut(craft({ scraps, steak() }, { more }))
check("and a second cut gets none", near(more.calories, 220 + 409.5 + 220))

-- Chicken, turkey and rabbit pot as red meat does, in any mix; the script's three cut lists name them all
for _, cut in ipairs(F.POTTED_GAME) do check(cut .. " goes into a pot", F.POTTED_CUTS[cut] == true) end
local birds = newFood(POT, {})
F.onPutMeatInFat(craft({ newFood("Base.Chicken", { hunger = -0.33, calories = 230, lipids = 9, proteins = 38, weight = 0.3 }),
    lard(), salt }, { birds }))
local mixed = newFood(POT, {})
F.onAddPottedCut(craft({ birds, newFood("Base.Rabbitmeat", { hunger = -0.3, calories = 969, carbs = 20, lipids = 20,
    proteins = 185, weight = 0.3 }) }, { mixed }))
check("a chicken leg and a rabbit share a pot", mixed.modData.tpfmPotted.portions == 2
    and near(mixed.calories, 230 + 969 + 2 * 4095 / 4) and near(mixed.carbs, 20))
local script = io.open("42/media/scripts/TraditionalPreservationFishMeat_Meat.txt"):read("*a")
script = script:sub((script:find("item PotOfMeatInFat", 1, true)))
local lists = 0
for list in script:gmatch("item 1 %[(Base%.Beef;[^%]]*)%]") do
    lists = lists + 1
    local named = {}
    for cut in list:gmatch("[^;]+") do named[cut] = true end
    for cut in pairs(F.POTTED_CUTS) do check("a recipe's cut list names " .. cut, named[cut]) end
    for cut in pairs(named) do check("a recipe's cut list is a potted cut: " .. cut, F.POTTED_CUTS[cut]) end
end
check("three recipes take the cuts", lists == 3)

-- Packing
check("a burnt pot can't be packed", not F.canPackPotted(newFood(POT, { burnt = true })))
check("a pot with no batch can't be packed", not F.canPackPotted(newFood(POT, {})))
check("a cooked pot can", F.canPackPotted(pot))
local crock = newFood(CROCK, { age = 3 })
local glazed = newFood("Base.ClayJarGlazed", {})
F.onPackPotted(craft({ pot, glazed }, { newFood("Base.Pot", {}), crock }, {}))
check("the crock holds four portions", near(F.crockPortions(crock), 4))
check("its food is the pot's", near(crock.calories, pot.calories) and near(crock.base, crock.hunger))
check("it starts fresh", crock.age == 0)
check("it remembers the glazed jar and looks it", crock.modData.tpfmVessel == "Base.ClayJarGlazed" and crock.modelIndex == 1)
check("it keeps its plain name", crock.name == "Crock of Potted Meat" and crock.customName == false)
check("it weighs the jar and the meat", near(crock.weight, 0.3 + batch.weight) and crock.customWeight)
check("packing gives Cooking XP for each cut", xp == 4 * F.POTTED_XP)

-- Eating
local container = { items = { [crock] = true } }
function container:contains(item) return self.items[item] == true end
function container:DoRemoveItem(item) self.items[item] = nil end
function container:AddItem(fullType) self.added = fullType return fullType end
crock.container = container
ISEatFoodAction.complete({ item = crock, share = 0.25 })
check("a quarter eaten leaves three portions", near(F.crockPortions(crock), 3, 1e-4) and crock.name == "Crock of Potted Meat")
check("and it weighs less", near(crock.weight, 0.3 + 3 * batch.weight / 4, 1e-4))
ISEatFoodAction.complete({ item = crock, share = 2 / 3 })
check("one portion left, still its plain name", near(F.crockPortions(crock), 1, 1e-4) and crock.name == "Crock of Potted Meat")
ISEatFoodAction.serverStop({ item = crock, share = 1 })
check("the last bite gives the glazed jar back", not container:contains(crock) and container.added == "Base.ClayJarGlazed")

-- A bare crock (the debug Item List): its script's food is one portion in a plain Clay Jar
local bare = newFood(CROCK, { hunger = -0.46, calories = 1244, lipids = 123, proteins = 32, weight = 1.0 })
bare.base = -0.46
local shelf = { items = { [bare] = true } }
setmetatable(shelf, { __index = container })
bare.container = shelf
ISEatFoodAction.complete({ item = bare, share = 0.25 })
check("a bare crock eaten by a quarter keeps the rest", shelf:contains(bare) and near(F.crockPortions(bare), 0.75, 1e-4)
    and bare.name == "Crock of Potted Meat")
check("it weighs its plain jar and what is left", near(bare.weight, 0.3 + 0.75 * 0.7, 1e-4))
ISEatFoodAction.complete({ item = bare, share = 1 })
check("eaten out, it gives the plain Clay Jar back", not shelf:contains(bare) and shelf.added == "Base.ClayJar")

-- Keeping by place (4c): a day in a basement is a day of the crock's script age
local ledger = F.pottedLedger()
local function keptCrock()
    local item = newFood(CROCK, {})
    F.keepCrock(item, 0, "Basement", ledger)
    return item
end
local cellar, cold, fridge, freezer, warm = keptCrock(), keptCrock(), keptCrock(), keptCrock(), keptCrock()
for _, item in ipairs({ cold, fridge, freezer, warm }) do F.keepCrock(item, 0, "Open", ledger) end
F.keepCrock(fridge, 0, "Fridge", ledger)
F.keepCrock(freezer, 0, "Freezer", ledger)
F.keepCrock(warm, 0, "Sheltered", ledger)
-- A cold snap in a hot season: 0 C outdoors, a room at the season's mean, 25 C.
for hour = 1, 240 do
    ledger.seasonTemperature = 25
    F.recordPotted(hour, 0)
end
for _, item in ipairs({ cellar, cold, fridge, freezer, warm }) do F.keepCrock(item, 240, nil, ledger) end
check("ten days in a basement age it by the basement's own warmth", near(cellar.age, 10 * F.pottedRate("Basement", ledger), 1e-6)
    and cellar.age < warm.age)
check("ten days outdoors at 0 C age it a sixth of that, frozen hard nothing", near(cold.age, 10 / 6, 1e-6)
    and F.pottedRate("Open", { temperature = -2 }) == 0 and F.pottedRate("Open", { temperature = -10 }) == 0)
check("ten days in a fridge age it five, by the clock", near(fridge.age, 5, 1e-6))
check("a freezer stops it", near(freezer.age, 0))
-- The ledger's season mean slips a little towards the 0 C days each hour, so a room reads a hair under 25 C.
check("a room in a hot season (25 C) ages it about 60/14 as fast", near(warm.age, 10 * 60 / 14, 0.5))
ledger.seasonTemperature, ledger.groundTemperature = 25, 23.125
check("so a summer basement (15 C) keeps it about 55 days, the cold 120, a warm room 14",
    near(F.pottedRate("Basement", ledger), 1.08, 0.01) and near(F.pottedRate("Fridge", ledger), 0.5)
    and near(60 / F.pottedRate("Sheltered", ledger), 14, 1e-6))
ledger.seasonTemperature = 14
check("a room in a 14 C season (15 C inside) keeps it as a basement does, not as Weather's 25 C room", near(F.pottedRate("Sheltered", ledger), 1))
ledger.seasonTemperature = 2
check("and in a 2 C winter season (4 C inside) as a fridge", near(F.pottedRate("Sheltered", ledger), 0.5))
ledger.seasonTemperature = -4
check("in a frozen room it keeps as in a freezer", F.pottedRate("Sheltered", ledger) == 0)
check("an unseen crock keeps counting where it was last seen", cellar.modData.tpfmKeep.record.place == "Basement")

-- The first portion taken costs a third of the keeping left, once
local opened = keptCrock()
opened.modData.tpfmPortion = { hunger = -0.5 }
opened.hunger = -2
opened.age, opened.modData.tpfmKeep.base = 10, 10
local box = { items = { [opened] = true } }
function box:contains(item) return self.items[item] == true end
function box:DoRemoveItem(item) self.items[item] = nil end
function box:AddItem(fullType) return fullType end
opened.container = box
H.hours = 240
ISEatFoodAction.complete({ item = opened, share = 0.25 })
check("the first portion takes a third of the 50 days left", near(opened.age, 10 + 50 / 3, 1e-4) and opened.modData.tpfmOpened)
local afterOpening = opened.age
ISEatFoodAction.complete({ item = opened, share = 1 / 3 })
check("the second takes nothing more", near(opened.age, afterOpening, 1e-6))
local stale = keptCrock()
stale.age, stale.modData.tpfmKeep.base = 75, 75
F.openCrock(stale)
check("a stale crock loses a third of its days to rotten", near(stale.age, 80, 1e-6))

-- Keeping by place off: plain food
SandboxVars = { TraditionalPreservationFishMeat = { PottedByPlace = false } }
local plain = newFood(CROCK, { age = 4 })
check("off, a crock gets no clock", F.keepCrock(plain, 240, "Sheltered", ledger) == nil and plain.modData.tpfmKeep == nil)
F.openCrock(plain)
check("and no opening loss", plain.age == 4)
SandboxVars = { FoodRotSpeed = 1, TraditionalPreservationFishMeat = {} }
check("vanilla's Very Fast food spoilage speeds it up", near(F.POTTED_AGEING.speed(), 1.7))
SandboxVars = nil

check("text checks", #H.textWarnings == 0)
H.done()
