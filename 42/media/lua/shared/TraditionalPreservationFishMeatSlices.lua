-- Traditional Preservation (Fish & Meat): slices, phase 6c. Hot Smoked meat and dry cured cuts slice into as many
-- slices of about SLICE_HUNGER as they hold, MIN_SLICES at least (a Beef (Hot Smoked) six, a dry cured chop two). A
-- Country Ham is carved: CARVE_SLICES slices of CARVE_HUNGER in all come off and the ham stays, lighter, on its own
-- long clock, until the last carving takes what is left: fifteen slices from a leg in three carvings. A
-- slice takes its share of the piece's food and mood, keeps half the piece's days (its script) and starts as far
-- through them as the piece was. Hot smoked pork is vanilla's Ham, which vanilla slices.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

F.SLICE_HUNGER = 0.14
-- What the slicing recipes' scripts give; the rest are made in OnCreate.
F.MIN_SLICES = 2
F.CARVE_SLICES = 5
F.CARVE_HUNGER = 0.7
-- With this much hunger or less left on it, the next carving is the ham's last.
F.CARVE_LAST = 1.05
F.SLICES = {
    ["TraditionalPreservationFishMeat.HotSmokedMeat"] = "TraditionalPreservationFishMeat.HotSmokedMeatSlice",
    ["TraditionalPreservationFishMeat.DryCuredMeat"] = "TraditionalPreservationFishMeat.DryCuredMeatSlice",
    ["TraditionalPreservationFishMeat.CountryHam"] = "TraditionalPreservationFishMeat.CountryHamSlice",
}
local HAM = "TraditionalPreservationFishMeat.CountryHam"

-- The mood and thirst a food item gives as it is, not as staleness or cooking would change them.
local EXTRAS = { "UnhappyChange", "BoredomChange", "ThirstChange" }
local function extra(item, field)
    local unmodified = item["get" .. field .. "Unmodified"]
    if unmodified then return unmodified(item) end
    return item["get" .. field](item)
end

-- A slice's age: as far through its shorter days as the piece is through its own, fresh and stale alike.
function F.sliceAge(age, offAge, offAgeMax, sliceOffAge, sliceOffAgeMax)
    if age <= offAge or offAgeMax <= offAge then return age / offAge * sliceOffAge end
    return sliceOffAge + math.min((age - offAge) / (offAgeMax - offAge), 1) * (sliceOffAgeMax - sliceOffAge)
end

-- How many slices a cut gives: what is left of it in slices of about SLICE_HUNGER.
function F.sliceCount(piece)
    return math.max(F.MIN_SLICES, math.floor(-piece:getHungChange() / F.SLICE_HUNGER + 0.5))
end

-- Gives each slice (a Lua list) an equal part of `share` of the piece: food, weight, mood, what it was made of and
-- whether it had aged. A slice is a whole thing, not a part-eaten one.
function F.fillSlices(piece, slices, share)
    F.rename(piece)
    local each = share / #slices
    local pieceData = piece:getModData()
    for _, slice in ipairs(slices) do
        F.copyFood(piece, slice, each)
        slice:setBaseHunger(slice:getHungChange())
        for _, field in ipairs(EXTRAS) do slice["set" .. field](slice, extra(piece, field) * each) end
        slice:setActualWeight(piece:getActualWeight() * each)
        slice:setCustomWeight(true)
        slice:setAge(F.sliceAge(piece:getAge(), piece:getOffAge(), piece:getOffAgeMax(), slice:getOffAge(), slice:getOffAgeMax()))
        local modData = slice:getModData()
        modData.cut = piece:getModelIndex()
        modData.airDried = pieceData.airDried
        modData.aged = pieceData.aged
        F.rename(slice)
    end
end

-- Takes `share` off what is left of a piece: its food, mood and weight. BaseHunger stays, as when it is eaten.
function F.carveOff(piece, share)
    local left = 1 - share
    piece:setHungChange(piece:getHungChange() * left)
    piece:setCalories(piece:getCalories() * left)
    piece:setProteins(piece:getProteins() * left)
    piece:setLipids(piece:getLipids() * left)
    piece:setCarbohydrates(piece:getCarbohydrates() * left)
    for _, field in ipairs(EXTRAS) do piece["set" .. field](piece, extra(piece, field) * left) end
    piece:setActualWeight(piece:getActualWeight() * left)
    piece:setCustomWeight(true)
end

-- Whether a ham has more on it than one last carving. HungChange is negative.
function F.carvesOn(ham)
    return -ham:getHungChange() > F.CARVE_LAST + 0.001
end

-- OnTest sees every input, so the knife passes here too.
function F.canCarve(item)
    return item:getFullType() ~= HAM or F.carvesOn(item)
end

function F.canCarveLast(item)
    return item:getFullType() ~= HAM or not F.carvesOn(item)
end

local function created(craftRecipeData)
    local list, slices = craftRecipeData:getAllCreatedItems(), {}
    for i = 0, list:size() - 1 do slices[i + 1] = list:get(i) end
    return slices
end

-- Slice Hot Smoked Meat and Slice Dry Cured Meat: the whole cut, in as many slices as it holds. The recipe makes
-- MIN_SLICES; the rest go straight to the character.
function F.onCreateMeatSliced(craftRecipeData, character)
    local piece = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local slices = created(craftRecipeData)
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    for _ = #slices + 1, F.sliceCount(piece) do
        table.insert(slices, inventory:AddItem(instanceItem(slices[1]:getFullType())))
    end
    F.fillSlices(piece, slices, 1)
end

-- Carve the Last of a Country Ham: all that is left, in the carving's slices.
function F.onCreateLastCarved(craftRecipeData)
    local ham = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    F.fillSlices(ham, created(craftRecipeData), 1)
end

-- Carve a Country Ham: the ham is kept, less the slices.
function F.onCreateCarved(craftRecipeData)
    local ham = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local share = math.min(1, F.CARVE_HUNGER / -ham:getHungChange())
    F.fillSlices(ham, created(craftRecipeData), share)
    F.carveOff(ham, share)
end
