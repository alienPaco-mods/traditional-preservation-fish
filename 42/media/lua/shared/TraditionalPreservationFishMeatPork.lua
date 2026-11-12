-- Traditional Preservation (Fish & Meat): the Leg of Pork, phase 6a. Vanilla's pig gives Pork and Pork Chops; a
-- country ham wants the whole leg. A table row can't keep a pig's meat at vanilla's (its count rounds by the animal's
-- size and meat ratio, and from the ground it never gives less than one), so the legs come out of the Pork the pig
-- just gave instead: LEG_PORK pieces make one leg, which takes their food. At most LEG_SHARE of the Pork goes, and
-- LEG_MAX legs, so a pig on the Hook gives one or two, a big one three, and one from the ground usually none.
require "Definitions/animal/AnimalPartsDefinitions"
require "Definitions/animal/ButcheringUtil"

TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

F.LEG_PORK = 5
F.LEG_SHARE = 0.5
F.LEG_MAX = 3
-- The adult pigs (type and breed); piglets have their own, leaner table.
F.LEG_ANIMALS = { sowlandrace = true, boarlandrace = true, sowlargeblack = true, boarlargeblack = true }

-- How many legs this much Pork makes.
function F.legsFrom(porkCount)
    return math.min(F.LEG_MAX, math.floor(porkCount * F.LEG_SHARE / F.LEG_PORK))
end

-- Whether the sandbox lets butchering give legs. On unless the option says otherwise.
function F.legsEnabled()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    return not options or options.LegsOfPork ~= false
end

-- The leg takes the pieces' food, summed, and the age of the oldest.
function F.fillLeg(leg, pieces)
    local hunger, calories, proteins, lipids, carbohydrates, age = 0, 0, 0, 0, 0, 0
    for _, piece in ipairs(pieces) do
        hunger = hunger + piece:getBaseHunger()
        calories = calories + piece:getCalories()
        proteins = proteins + piece:getProteins()
        lipids = lipids + piece:getLipids()
        carbohydrates = carbohydrates + piece:getCarbohydrates()
        age = math.max(age, piece:getAge())
    end
    leg:setBaseHunger(hunger)
    leg:setHungChange(hunger)
    leg:setCalories(calories)
    leg:setProteins(proteins)
    leg:setLipids(lipids)
    leg:setCarbohydrates(carbohydrates)
    leg:setAge(age)
end

local function porkIn(inventory)
    local found = inventory:getAllType("Base.Pork")
    local pork = {}
    for i = 0, found:size() - 1 do pork[found:get(i)] = true end
    return pork
end

-- Turns some of the Pork just given into legs. Returns the text for the butchering log.
local function makeLegs(player, before)
    local inventory = player:getInventory()
    local given = {}
    for piece in pairs(porkIn(inventory)) do
        if not before[piece] then table.insert(given, piece) end
    end
    local legs = F.legsFrom(#given)
    local text = ""
    for _ = 1, legs do
        local pieces = {}
        for _ = 1, F.LEG_PORK do table.insert(pieces, table.remove(given)) end
        local leg = instanceItem(F.LEG_OF_PORK)
        F.fillLeg(leg, pieces)
        for _, piece in ipairs(pieces) do
            inventory:Remove(piece)
            sendRemoveItemFromContainer(inventory, piece)
        end
        inventory:AddItem(leg)
        sendAddItemToContainer(inventory, leg)
        text = text .. leg:getDisplayName() .. "\r\n"
    end
    return text
end

local addAnimalPart = ButcheringUtil.addAnimalPart
function ButcheringUtil.addAnimalPart(part, player, carcass, fromGround)
    if part.item ~= "Base.Pork" or not F.legsEnabled() or not F.LEG_ANIMALS[ButcheringUtil.getCarcassName(carcass)] then
        return addAnimalPart(part, player, carcass, fromGround)
    end
    local before = porkIn(player:getInventory())
    local text = addAnimalPart(part, player, carcass, fromGround) or ""
    return text .. makeLegs(player, before)
end
