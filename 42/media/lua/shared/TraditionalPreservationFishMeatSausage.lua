-- Traditional Preservation (Fish & Meat): Smoked Sausage (user, 2026-11-13), kielbasa style. Two pieces of raw pork
-- and a third of pork, beef or venison, a piece of pork fat or half a block of lard, salt and a Salted Casings make six
-- Fresh Sausage links. A fresh link fries in place (Fresh Sausage (Fried)) or poaches in a pot (Fresh Sausage
-- (Boiled)) and keeps as vanilla's sausage does; hung raw in the Smokehouse (Hang Sausage to Smoke, the recipe blood
-- sausage hangs with too) it takes a hot run, SAUSAGE_HOT_HOURS stoked in a row on the Smokehouse's hot counter, and
-- comes down Smoked Sausage (14 / 30). The stack itself runs on the blood sausage's code
-- (TraditionalPreservationFishMeatBlood.lua, modData.sausage = "pork").
-- Seasoning (user, 2026-11-13), for these links and blood sausage's: added to a link afterwards, as a spice to a stew
-- (TP Core's Season menu), raw or boiled; each kind once, no cap, each SEASONING_UNHAPPY. It goes with the link into
-- the pot, the pan, the smoke and the slices.
local Season = require "TraditionalPreservationCore/Season"

local F = TraditionalPreservationFishMeat

-- A hot run, as a Pork piece's (F.HOT_MEAT_HOURS at 0.3): links are thin, but the run is one unbroken stretch.
F.SAUSAGE_HOT_HOURS = 6
F.FRESH_SAUSAGE = "TraditionalPreservationFishMeat.FreshSausage"
F.SMOKED_SAUSAGE = "TraditionalPreservationFishMeat.SmokedSausage"

-- The short list (user): what real sausages take. Oregano stands in for marjoram, which the game doesn't have. Each
-- takes what vanilla takes for a stew: a use, half an onion (5).
F.SEASONINGS = {
    { name = "garlic", types = { "Base.Garlic", "Base.WildGarlic2", "Base.WildGarlicDried" } },
    { name = "onion", types = { "Base.Onion" }, uses = 5 },
    { name = "pepper", types = { "Base.Pepper" } },
    { name = "oregano", types = { "Base.Oregano", "Base.OreganoDried", "Base.Seasoning_Oregano" } },
    { name = "thyme", types = { "Base.Thyme", "Base.ThymeDried", "Base.Seasoning_Thyme" } },
    { name = "sage", types = { "Base.Sage", "Base.SageDried", "Base.Seasoning_Sage" } },
}
-- Each kind: vanilla's spice in a stew, -2 unhappiness and -2 boredom.
F.SEASONING_UNHAPPY = -2
F.SEASONING_BOREDOM = -2
-- The links a seasoning goes into (links only, user): raw or fried or boiled fresh sausage, raw or boiled blood sausage.
F.SEASONED_LINKS = { "TraditionalPreservationFishMeat.FreshSausage", "TraditionalPreservationFishMeat.RawBloodSausage",
    "TraditionalPreservationFishMeat.BloodSausage" }
Season.register(F.SEASONED_LINKS, { kinds = F.SEASONINGS, unhappy = F.SEASONING_UNHAPPY, boredom = F.SEASONING_BOREDOM })

-- The links a pot boils, and what comes out (TakeOut): seasoning goes from one to the other in order.
local POT_LINKS = { [F.FRESH_SAUSAGE] = true, ["TraditionalPreservationFishMeat.RawBloodSausage"] = true }
local BOILED_LINKS = { [F.FRESH_SAUSAGE] = true, ["TraditionalPreservationFishMeat.BloodSausage"] = true }
-- The links a knife slices, its slices a quarter of the link.
local SLICED_LINKS = { [F.SMOKED_SAUSAGE] = true, ["TraditionalPreservationFishMeat.SmokedBloodSausage"] = true,
    ["TraditionalPreservationFishMeat.BloodSausage"] = true }

local function rename(item, key)
    item:setName(getText(key))
    item:setCustomName(true)
end

function F.onCookedFreshSausage(item)
    rename(item, "IGUI_TraditionalPreservationFishMeat_FreshSausageFried")
end

-- Put Sausages / Blood Sausages in Water: the pot keeps each link's seasoning for the links that come out of it.
function F.onCreateSausagePot(craftRecipeData)
    local consumed, records = craftRecipeData:getAllConsumedItems(), {}
    for i = 0, consumed:size() - 1 do
        local item = consumed:get(i)
        if POT_LINKS[item:getFullType()] then table.insert(records, Season.record(item) or false) end
    end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local pot = created:get(i)
        if pot:getFullType() ~= "Base.Pot" and pot:getFullType() ~= "Base.PotForged" then
            pot:getModData().tpLinks = records
        end
    end
end

-- Take Out Sausages / Blood Sausages: the links come out cooked (fresh ones named Boiled), each with its seasoning.
function F.onCreateBoiledSausages(craftRecipeData)
    local consumed, records = craftRecipeData:getAllConsumedItems(), {}
    for i = 0, consumed:size() - 1 do
        records = consumed:get(i):getModData().tpLinks or records
    end
    local created, n = craftRecipeData:getAllCreatedItems(), 0
    for i = 0, created:size() - 1 do
        local item = created:get(i)
        if BOILED_LINKS[item:getFullType()] then
            n = n + 1
            item:setCooked(true)
            if item:getFullType() == F.FRESH_SAUSAGE then rename(item, "IGUI_TraditionalPreservationFishMeat_FreshSausageBoiled") end
            Season.apply(item, records[n] or nil)
        end
    end
end

-- Slicing a link: cooked slices, each a quarter of the link's seasoning.
function F.onCreateSausageSlices(craftRecipeData)
    TraditionalPreservationCore.OnCreateCooked(craftRecipeData)
    local consumed, link = craftRecipeData:getAllConsumedItems(), nil
    for i = 0, consumed:size() - 1 do
        if SLICED_LINKS[consumed:get(i):getFullType()] then link = consumed:get(i) end
    end
    if not link then return end
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do Season.carry(link, created:get(i), 0.25) end
end

-- Only the Smokehouse takes Fresh Sausage, raw: a cooked link has had its chance.
function F.freshSausageRefusal(hanger, item)
    if item:getFullType() ~= F.FRESH_SAUSAGE then return nil end
    if not hanger.closed then return "IGUI_TraditionalPreservationFishMeat_FreshSausageSmokehouse" end
    if item:isCooked() then return "IGUI_TraditionalPreservationFishMeat_FreshSausageCooked" end
    return nil
end
