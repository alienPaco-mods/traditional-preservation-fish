-- Traditional Preservation (Fish & Meat): what its stacks do in the Smokehouse. The chamber, joining the Firebox and
-- the fire's two counters are TP Core's (Smokehouse.lua, moved there 2026-11-13); this is the fish and meat's side:
-- each stack's needs, its drying by the fire's warmth, and what comes out. Only stacks this mod hung are stepped
-- here (F.OWNER): another mod's cheese in the same shed is its own.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
local Station = require "TraditionalPreservationCore/Station"

F.OWNER = "TraditionalPreservationFishMeat"

-- Whether a stack in the Smokehouse is this mod's.
function F.ownsStack(modData)
    return Smokehouse.owns(modData, F.OWNER)
end

-- Hot smoking (ROADMAP §7, 5c). A salt stack (Salt Cured fish, or charque) in a chamber joined to a Firebox counts the
-- Firebox's fire on two counters: hot, the hours of the stoked session now running (TP Core's Hearth.logFire), and
-- cold, banked hours and the hours of stoked sessions that broke off. Hot reaching the stack's need finishes it at
-- once as Hot Smoked; short of that it dries on as the Smokehouse always does, and keeps cold for Cold Smoked (5d).
-- Poultry and rabbit (hotOnly, 0.4.34) never dry: a broken run starts again, and the stack spoils until a cook ends it.
-- The need goes by the heaviest piece, as the press does: a cook is one unbroken run (real hot smoked fish must reach
-- 63 C inside and hold it).
F.HOT_FISH_HOURS = { { 1.1, 4 }, { 2.2, 6 } }
F.HOT_MEAT_HOURS = { { 0.3, 6 }, { 0.5, 8 } }
F.HOT_MIN_HOURS = 4
F.HOT_MAX_HOURS = 12
F.HOT_FISH = "TraditionalPreservationFishMeat.HotSmokedFish"
F.HOT_MEAT = "TraditionalPreservationFishMeat.HotSmokedMeat"

-- Cold smoke (5d; fixed hours since 6b): a stack whose cold counter reaches its smoke need comes out Cold Smoked
-- when it has dried (smoked-dried fish, balyk, suho meso: a few hours of smoke a day over the drying). The need is
-- by the heaviest piece, as the cook's: a day or two of smoke for fish, a week or two of daily fires for meat (a
-- Beef 60 hours, a Leg of Pork 120). Hours with the fire burning dry it in air warmed by the fire (F.BANKED_LIFT,
-- F.STOKED_LIFT), not at the cold shed's rate (Enclosed: the day's temperature).
F.SMOKE_FISH_HOURS = { { 1.1, 24 }, { 2.2, 48 } }
F.SMOKE_MEAT_HOURS = { { 0.45, 60 }, { 2.25, 120 } }
F.COLD_FISH_OUT = "TraditionalPreservationFishMeat.ColdSmokedFish"
F.DRY_CURED = "TraditionalPreservationFishMeat.DryCuredMeat"
-- 6b: a Leg of Pork dries to a Country Ham and never takes a hot cook (a hot smoked whole ham is a wet-cured city
-- ham, another product); the other pork cuts hot smoke to vanilla's Ham.
F.COUNTRY_HAM = "TraditionalPreservationFishMeat.CountryHam"
F.VANILLA_HAM = "Base.Ham"

-- The stoked hours a stack needs, by its heaviest piece: straight between the two points, on past them, clamped.
function F.hotHours(isMeat, heaviest)
    local points = isMeat and F.HOT_MEAT_HOURS or F.HOT_FISH_HOURS
    local low, high = points[1], points[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.max(F.HOT_MIN_HOURS, math.min(hours, F.HOT_MAX_HOURS))
end

-- Sets a new stack's counters and need from its pieces (an ArrayList of items). Meat also gets its dry-curing need
-- for the Smokehouse; a stack with a leg never hot smokes, and one with Corned meat (no long cure) is under-salted.
function F.startSmoke(modData, items, isMeat)
    local heaviest = 0
    modData.noHot, modData.underCured, modData.allUnder, modData.longStack = nil, nil, isMeat or nil, nil
    modData.hotOnly, modData.underScale = nil, nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        heaviest = math.max(heaviest, F.timingWeight(item))
        if isMeat then
            if F.isLeg(item) then modData.noHot = true end
            if F.isHotOnly(item) then modData.hotOnly = true end
            if item:getModData().longCure then
                modData.allUnder, modData.longStack = nil, true
            else
                modData.underCured = true
                -- The stack as a whole goes when its slowest Corned piece does: rinsed only if every one was.
                local scale = item:getModData().rinsed and 1 / F.RINSED_KEEPING or 1
                modData.underScale = math.min(modData.underScale or scale, scale)
            end
        end
    end
    modData.heaviest = heaviest
    modData.cureNeed = isMeat and F.dryCureHours(heaviest) or nil
    modData.underSpoiled = 0
    Smokehouse.startCounters(modData, F.OWNER, F.hotHours(isMeat, heaviest))
    modData.smokeNeed = F.smokeHours(isMeat, heaviest)
    modData.smokeMeat = isMeat
end

-- The ledger totals a stack's warmth reads: salt fish's drying in the shed (the ledger's sheltered, by the day's
-- temperature) or meat's dry curing with the fire out, and
-- by a banked and by a stoked fire.
local function warmthTotals(modData, ledger)
    if modData.smokeMeat then return ledger.dryCure or 0, ledger.dryCureBanked or 0, ledger.dryCureStoked or 0 end
    return ledger.sheltered or 0, ledger.smokeBanked or 0, ledger.smokeStoked or 0
end

-- How much more under-salted meat spoiled an hour by a banked and by a stoked fire than with the fire out, since the
-- stack's last look (hours of the ledger's clock), as sinceLast's gains.
local function underGains(modData, ledger, hours)
    -- Poultry and rabbit go by their own totals (faster, F.hotOnlyUnderRate).
    local prefix = modData.hotOnly and "hotOnlyUnder" or "underCure"
    local base, banked, stoked = ledger[prefix] or 0, ledger[prefix .. "Banked"] or 0, ledger[prefix .. "Stoked"] or 0
    local bankedGain, stokedGain = 0, 0
    if hours > 0 then
        local plain = base - (modData.lastUnderBase or base)
        bankedGain = (banked - (modData.lastUnderBanked or banked) - plain) / hours
        stokedGain = (stoked - (modData.lastUnderStoked or stoked) - plain) / hours
    end
    modData.lastUnderBase, modData.lastUnderBanked, modData.lastUnderStoked = base, banked, stoked
    return math.max(bankedGain, 0), math.max(stokedGain, 0)
end

-- Since the stack's last look: the share of the hours that were cool enough for cold smoke, and how much more a stack
-- by a banked and by a stoked fire dried than one with the fire out per hour, from the ledger's totals (a week away reads
-- the week's weather). With no hours between, the weather now and no gain. A stack from before the smoulder's
-- warmth starts its warm totals at this look.
local function sinceLast(modData, ledger)
    local sheltered, banked, stoked = warmthTotals(modData, ledger)
    local hours = (ledger.clock or 0) - (modData.lastClock or ledger.clock or 0)
    local coolShare, bankedGain, stokedGain = nil, 0, 0
    local underBanked, underStoked = underGains(modData, ledger, hours)
    if hours > 0 then
        coolShare = ((ledger.smokeCool or 0) - (modData.lastSmokeCool or 0)) / hours
        local base = sheltered - (modData.lastDraughtSheltered or sheltered)
        bankedGain = (banked - (modData.lastDraughtBanked or banked) - base) / hours
        stokedGain = (stoked - (modData.lastDraughtStoked or stoked) - base) / hours
    else
        coolShare = (ledger.temperature or 0) <= F.COLD_SMOKE_MAX and 1 or 0
    end
    modData.lastClock, modData.lastSmokeCool = ledger.clock or 0, ledger.smokeCool or 0
    modData.lastDraughtSheltered, modData.lastDraughtBanked, modData.lastDraughtStoked = sheltered, banked, stoked
    return math.max(0, math.min(coolShare, 1)), math.max(bankedGain, 0), math.max(stokedGain, 0), underBanked, underStoked
end

-- A stack of meat hung in a shed before 6b dried on charque's clock: it gets its dry-curing need, keeps its share
-- of progress and starts the new totals from this look.
local function toDryCure(modData, ledger)
    local need = F.dryCureHours(modData.heaviest or F.DRY_CURE_HOURS[1][1])
    modData.dried = (modData.dried or 0) / F.CHARQUE_HOURS * need
    modData.cureNeed = need
    modData.lastDryCure, modData.lastUnderCure = ledger.dryCure, ledger.underCure
    modData.lastDraughtSheltered, modData.lastDraughtBanked, modData.lastDraughtStoked = nil, nil, nil
end

-- Brings a stack's counters up to the fire's record (a Firebox's Hearth state), or none (not joined): TP Core's
-- Smokehouse.fireStep. With the ledger (the World's look; tests may leave it out): fire hours count as cold only on
-- cool days, stoked or banked (user: no Cold Smoked in summer from short stoked bursts), and every hour of fire adds
-- the warmed air's extra drying, banked or stoked, and an under-salted stack's extra spoiling.
function F.smokeStep(modData, fire, ledger)
    if not modData.hotNeed then return end
    local coolShare, bankedGain, stokedGain, underBanked, underStoked = 1, 0, 0, 0, 0
    if ledger then
        if modData.smokeMeat and not modData.cureNeed then toDryCure(modData, ledger) end
        coolShare, bankedGain, stokedGain, underBanked, underStoked = sinceLast(modData, ledger)
    end
    local stoked, banked = Smokehouse.fireStep(modData, fire, coolShare)
    if not stoked then return end
    if modData.dried and not modData.hotOnly then
        modData.dried = modData.dried + math.max(stoked, 0) * stokedGain + banked * bankedGain
    end
    if modData.underCured then
        modData.underSpoiled = (modData.underSpoiled or 0) + math.max(stoked, 0) * underStoked + banked * underBanked
    end
end

-- Whether a stack's hot counter has done its cook.
F.hotDone = Smokehouse.hotDone

-- The hours of smoke a stack needs, by its heaviest piece: straight between the two points, never under the first
-- nor over the second.
function F.smokeHours(isMeat, heaviest)
    local points = isMeat and F.SMOKE_MEAT_HOURS or F.SMOKE_FISH_HOURS
    local low, high = points[1], points[2]
    local hours = low[2] + (heaviest - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
    return math.max(low[2], math.min(hours, high[2]))
end

-- A stack's smoke need (one hung before 6b gets it from its heaviest piece), and whether it has had it.
function F.coldNeed(modData)
    return modData.smokeNeed or F.smokeHours(modData.smokeMeat == true, modData.heaviest or 0)
end

function F.coldDone(modData)
    return (modData.cold or 0) > 0 and modData.cold >= F.coldNeed(modData)
end

-- Stacks whose cook is done, by stackId, with their chamber: the World sets them, the stack's OnUpdate finishes it,
-- its OnCreate swaps the outputs in the chamber's slots. Not saved: the World's next look after a load sets it again.
F.hotStations = {}

-- Swaps a finished stack's outputs, already in the chamber's slots (the engine makes them before OnCreate), for
-- smoked ones made from its inputs: fishType for fish, meatType for meat (Hot Smoked, or Cold Smoked and Dry Cured).
-- Of the meat, hot smoked pork is vanilla's Ham and a dried leg a Country Ham; airDried marks Dry Cured meat that
-- had too little smoke (Beef (Dry Cured), plain Country Ham). Corned pieces take the stack's under-salted spoilage.
local function smokedMeatType(input, meatType)
    if meatType == F.HOT_MEAT then return F.isPork(input) and not F.isLeg(input) and F.VANILLA_HAM or meatType end
    return F.isLeg(input) and F.COUNTRY_HAM or meatType
end

-- One smoked piece from its input, by the stack's modData. A piece that rotted on the way comes down as what was
-- hung (F.rottenStage).
function F.smokedItem(input, modData, fishType, meatType, airDried)
    local isMeat = input:getFullType() == F.CURED_MEAT
    local lost = modData.spoiled or 0
    if isMeat then lost = lost + F.underLoss(input, modData) end
    if lost >= 1 then return F.rottenStage(input, modData) end
    local hot = instanceItem(isMeat and smokedMeatType(input, meatType) or fishType)
    if hot:getFullType() == F.VANILLA_HAM then
        F.carryHam(input, hot)
    else
        if isMeat and airDried then hot:getModData().airDried = true end
        F.carry(input, hot)
        hot:getModData().stackId = modData.stackId
        hot:getModData().style = modData.style
    end
    hot:setAge(hot:getOffAge() * lost)
    -- Dry cured meat ages from here (6c).
    if F.ageDays(hot) then hot:getModData().agedFrom = hot:getAge() end
    return hot
end

-- Swaps a finished stack's outputs, already in the station's slots, for make(input) of each of its inputs.
local function swapOutputs(craftRecipeData, station, make)
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    local logic = station:getComponent(ComponentType.DryingCraftLogic)
    local resources = station:getComponent(ComponentType.Resources)
    if not logic or not resources then return false end
    local slots = Station.itemSlots(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    for i = 0, math.min(inputs:size(), created:size()) - 1 do
        local made = created:get(i)
        local swapped = make(inputs:get(i))
        for j = 0, slots:size() - 1 do
            local slot = slots:get(j)
            if slot:containsItem(made) then
                slot:removeItem(made)
                slot:offerItem(swapped, true)
                break
            end
        end
    end
    return true
end

F.swapOutputs = swapOutputs

function F.smokedOutputs(craftRecipeData, station, fishType, meatType, airDried)
    local modData = craftRecipeData:getModData()
    return swapOutputs(craftRecipeData, station, function(input) return F.smokedItem(input, modData, fishType, meatType, airDried) end)
end

-- A stack that rotted on any station comes down as what was hung, rotten.
function F.rottenOutputs(craftRecipeData, station)
    local modData = craftRecipeData:getModData()
    return swapOutputs(craftRecipeData, station, function(input) return F.rottenStage(input, modData) end)
end
