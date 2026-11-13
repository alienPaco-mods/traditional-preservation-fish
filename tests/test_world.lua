-- Checks the tubs' and frames' sprites and the weather record with stand-ins for the engine. Run from the mod
-- folder: luajit tests/test_world.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()

-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationFishMeat/") or name:find("^TraditionalPreservationCore/") then return realRequire(name) end
end

-- Engine stand-ins
function isClient() return false end
ComponentType = { Resources = "Resources", CraftLogic = "CraftLogic", DryingCraftLogic = "DryingCraftLogic" }
ResourceIO = { Input = "Input", Output = "Output" }
ResourceType = { Item = "Item" }
ArrayList = { new = function() return list({}) end }
function getPlayer() return {} end
function getClimateManager()
    return {
        getTemperature = function() return 20 end,
        getHumidity = function() return 0.4 end,
        getPrecipitationIntensity = function() return 0 end,
        getPrecipitationIsSnow = function() return false end,
        getWindIntensity = function() return 0.3 end,
    }
end
local loaders = {}
MapObjects = { OnLoadWithSprite = function(name, handler) loaders[name] = handler end }
local cellSquares = {}
function getCell()
    return { getGridSquare = function(_, x, y, z) return cellSquares[x .. "," .. y .. "," .. z] end }
end
CraftLogicUILogic = {
    new = function(_, _, logic)
        return { getCraftLogic = function() return logic end, getItemsInProgress = function() return logic.inProgress end }
    end,
}
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }

local function square(x, z)
    local s = {}
    function s:getX() return x end
    function s:getY() return 0 end
    function s:getZ() return z end
    -- Nothing else stands on it: no Firebox beside a Smokehouse.
    function s:getObjects() return { size = function() return 0 end } end
    cellSquares[x .. ",0," .. z] = s
    return s
end

local function fish(fullType, modData, rotten)
    return { getFullType = function() return fullType end, getModData = function() return modData or {} end,
        isRotten = function() return rotten or false end }
end

local function recipeData(progress, style)
    local data = { modData = { style = style }, progress = progress }
    function data:getModData() return self.modData end
    return data
end

-- A station with this sprite, with waiting fish, running batches and finished fish.
local function station(spriteName, x, outside, waiting, batches, finished)
    local logic = { inProgress = {} }
    for _, batch in ipairs(batches) do logic.inProgress[batch] = {} end
    function logic:getInputsGroupName() return "in" end
    function logic:getOutputsGroupName() return "out" end
    function logic:getProgress(data) return data.progress end
    logic.tag = "DryingFrame"
    function logic:getRecipeTagQuery() return self.tag end
    function logic:setRecipeTagQuery(tag) self.tag = tag end
    local resources = {}
    function resources:getResourcesFromGroup(group)
        local items = group == "in" and waiting or finished
        return list({ { getStoredItems = function() return list(items) end, storedSize = function() return #items end } })
    end
    local object = { square = square(x, 0), sprites = {}, clears = 0 }
    function object:getComponent(kind) return kind == "Resources" and resources or logic end
    function object:getSprite() return { getName = function() return spriteName end } end
    function object:getSquare() return self.square end
    function object:getObjectIndex() return 0 end
    function object:isOutside() return outside end
    function object.square:isOutside() return outside end
    function object.square:isInARoom() return not outside and not object.porch end
    function object:clearAttachedAnimSprite() self.sprites = {} self.clears = self.clears + 1 end
    function object:addAttachedAnimSpriteByName(name) table.insert(self.sprites, name) end
    return object
end

local function tick(times)
    for _ = 1, times do H.fire("OnTick") end
end

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer", "AnimalParts" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")
dofile("42/media/lua/server/TraditionalPreservationFishMeatWorld.lua")
local T, W = TraditionalPreservationFishMeat, TraditionalPreservationFishMeatWorld
local PRESSED, GUTTED = "TraditionalPreservationFishMeat.SaltPressedFish", "TraditionalPreservationFishMeat.GuttedFish"

check("the map loader knows the tub, the frame and both beams", loaders.traditionalpreservationfishmeat_01_0
    and loaders.traditionalpreservationfishmeat_01_7 and loaders.traditionalpreservationfishmeat_02_0 and loaders.traditionalpreservationfishmeat_02_3)
check("and nothing else", loaders.traditionalpreservationfishmeat_01_8 == nil)
check("and both tiles of TP Core's Smokehouse, either way round, for this mod's stacks in it", loaders.traditionalpreservationcore_01_32
    and loaders.traditionalpreservationcore_01_33 and loaders.traditionalpreservationcore_01_34 and loaders.traditionalpreservationcore_01_35)

-- Frames: a finished salt stack, a gutted stack halfway, and pressed fish waiting.
local running = recipeData(0.5, T.STYLE_GUTTED)
local shed = station("traditionalpreservationfishmeat_01_6", 1, false, { fish(PRESSED) }, { running },
    { fish("TraditionalPreservationFishMeat.SaltDriedFish", { stackId = 5, style = T.STYLE_SALT }) })
loaders.traditionalpreservationfishmeat_01_6(shed)
tick(30)
-- States 4 (salt, done), 7 (gutted, stage 2), 0 (salt, fresh) in slots 0-2 of face 0.
check("each stack gets its sprite, driest first", table.concat(shed.sprites, " ") ==
    "traditionalpreservationfishmeat_01_72 traditionalpreservationfishmeat_01_122 traditionalpreservationfishmeat_01_12")
check("running stacks learn they are under a roof", running.modData.sheltered == true)
check("the frame counts its busy stacks", W.busyStacks(shed) == 2)
tick(30)
check("an unchanged frame is left alone", shed.clears == 1)

local outdoors = recipeData(0.1, T.STYLE_SALT)
local yard = station("traditionalpreservationfishmeat_01_7", 2, true, {}, { outdoors }, {})
W.track(yard)
tick(30)
check("an open frame is open", outdoors.modData.sheltered == false and outdoors.modData.covered == false and yard.sprites[1] == "traditionalpreservationfishmeat_01_9")
check("a frame in a room is indoors", running.modData.covered == false)

local porched = recipeData(0.1, T.STYLE_SALT)
local porch = station("traditionalpreservationfishmeat_01_7", 4, false, {}, { porched }, {})
porch.porch = true
W.track(porch)
W.refresh(porch)
check("a frame under an open roof is covered", porched.modData.covered == true and porched.modData.sheltered == false)

-- Charque: a meat stack halfway and Salt Cured meat waiting, from the meat's own tiles at the end of sheet 2.
local charque = recipeData(0.5, T.STYLE_MEAT)
local rack = station("traditionalpreservationfishmeat_01_6", 5, true, { fish(T.CURED_MEAT) }, { charque }, {})
W.track(rack)
W.refresh(rack)
-- Meat stage 2 in slot 0 (716 + 32 = 748), fresh in slot 1 (718).
check("charque hangs from the meat tiles", table.concat(rack.sprites, " ") ==
    "traditionalpreservationfishmeat_02_340 traditionalpreservationfishmeat_02_310")
check("a beam's charque is its own run too", W.hangingSprite(T.HANGERS[408], T.STYLE_MEAT * T.DRYING_STAGES, 1, 1) == 797
    and W.hangingSprite(T.HANGERS[410], T.STYLE_MEAT * T.DRYING_STAGES + 4, 2, 0) == 836 + (4 * 2 + 1) * 2)
check("fish keep theirs", W.hangingSprite(T.HANGERS[6], 4, 1, 0) == 8 + 4 * 8 * 2)

-- Rotted stacks (0.4.21): one look a kind, on the third sheet.
check("rotten tiles start the third sheet", W.hangingSprite(T.HANGERS[6], T.ROTTEN_STATE, 1, 0) == 880
    and T.spriteName(880) == "traditionalpreservationfishmeat_03_0")
check("and run to its 84th", W.hangingSprite(T.HANGERS[410], T.ROTTEN_STATE + T.ROTTEN_KINDS.MEAT, 2, 1) == 963
    and T.spriteName(963) == "traditionalpreservationfishmeat_03_83" and T.spriteIndex("traditionalpreservationfishmeat_03_83") == 963)
check("the first two sheets keep their names", T.spriteName(407) == "traditionalpreservationfishmeat_01_407"
    and T.spriteName(408) == "traditionalpreservationfishmeat_02_0" and T.spriteIndex("traditionalpreservationfishmeat_02_471") == 879
    and T.spriteIndex("traditionalpreservationfishmeat_04_0") == nil)
check("a style's rotten kind", T.rottenKind(T.STYLE_SALT_HALF) == T.ROTTEN_KINDS.SALT and T.rottenKind(T.STYLE_HALF) == T.ROTTEN_KINDS.COLD
    and T.rottenKind(T.STYLE_MEAT) == T.ROTTEN_KINDS.MEAT)
local lost = recipeData(0.4, T.STYLE_GUTTED)
lost.modData.spoiled = 1
local spoiledFrame = station("traditionalpreservationfishmeat_01_6", 7, true, {},
    { lost }, { fish(T.CURED_MEAT, { stackId = 3, style = T.STYLE_MEAT }), fish(T.CURED_MEAT, { stackId = 3, style = T.STYLE_MEAT }, true),
        fish("TraditionalPreservationFishMeat.SaltDriedFish", { stackId = 4, style = T.STYLE_SALT }) })
W.track(spoiledFrame)
W.refresh(spoiledFrame)
-- Slot 1: the finished meat stack with a rotten piece, meat kind (880 + (2 * 8) * 2); slot 2: the dried fish, done;
-- slot 3: the running cold stack that rotted, cold kind (880 + (1 * 8 + 2) * 2).
check("a rotted stack shows its kind, a finished one with any rotten piece", table.concat(spoiledFrame.sprites, " ") ==
    "traditionalpreservationfishmeat_03_32 traditionalpreservationfishmeat_01_74 traditionalpreservationfishmeat_03_20")
local mixed = recipeData(0.5, T.STYLE_MEAT)
mixed.modData.underSpoiled, mixed.modData.spoiled = 1.5, 0
check("a mixed stack whose Corned share rotted keeps drying, and its look", not T.stackRotten(mixed.modData))
mixed.modData.allUnder = true
check("all Corned, it is lost", T.stackRotten(mixed.modData))

-- TP Core's Smokehouse: Enclosed wherever it stands (out of the rain, by the day's air). Core draws its look; this
-- mod steps only its own stacks, and counts another mod's as taking room.
local SHED = "traditionalpreservationcore_01_33"
local smoked = recipeData(0.5, T.STYLE_MEAT)
smoked.modData.smokeOwner = T.OWNER
local cheese = recipeData(0.2)
cheese.modData.smokeOwner = "TraditionalPreservationDairy"
local smokehouse = station(SHED, 6, true, { fish(T.CURED_MEAT) }, { smoked, cheese }, {})
smokehouse.sprites = { "core's" }
W.track(smokehouse)
W.refresh(smokehouse)
check("a Smokehouse in the open is out of the rain inside, and marked as the shed", smoked.modData.sheltered == true
    and smoked.modData.covered == false and smoked.modData.inShed == true and smoked.modData.loft == false)
check("another mod's stack in it is left alone", cheese.modData.sheltered == nil and cheese.modData.inShed == nil)
check("and the look is Core's to draw", smokehouse.sprites[1] == "core's" and smokehouse.clears == 0)
check("it counts every busy stack, another mod's too", W.busyStacks(smokehouse) == 2)
check("a frame keeps the frame's", rack:getComponent("DryingCraftLogic").tag == "DryingFrame")

-- What the Info window is told about a station.
local seen = W.inspect(shed)
check("a look at the frame: its hanger, place and contents", seen.hanger == T.HANGERS[6] and seen.place == "Sheltered"
    and #seen.waiting == 1 and seen.finished == 1 and seen.finishedStacks == 1)
check("and its running batch with its progress", #seen.batches == 1 and seen.batches[1].data == running and seen.batches[1].progress == 0.5)
check("a Smokehouse is Enclosed to the window too", W.inspect(smokehouse).place == "Enclosed" and W.inspect(smokehouse).hanger.closed)
check("and the window lists this mod's stacks only", #W.inspect(smokehouse).batches == 1 and W.inspect(smokehouse).batches[1].data == smoked)
-- A stack hung before step J was last marked Sheltered with inShed: the next look marks it the same, so it keeps
-- reading the same totals.
local oldStack = recipeData(0.3, T.STYLE_MEAT)
oldStack.modData.sheltered, oldStack.modData.inShed, oldStack.modData.smokeOwner = true, true, T.OWNER
local oldShed = station(SHED, 6, true, {}, { oldStack }, {})
W.track(oldShed)
W.refresh(oldShed)
check("an old Smokehouse stack keeps its marks", oldStack.modData.sheltered == true and oldStack.modData.inShed == true
    and not oldStack.modData.basement and not oldStack.modData.covered)
check("another mod's object gives nothing", W.inspect(station("carpentry_02_122", 4, true, {}, {}, {})) == nil)

-- Tubs
local tub = station("traditionalpreservationfishmeat_01_1", 3, true, {}, { recipeData(0.3) }, {})
W.track(tub)
W.refresh(tub)
check("a pressing tub shows its weights", table.concat(tub.sprites, " ") == "traditionalpreservationfishmeat_01_5")
-- An uncovered tub shows its top layer: fish, or the meat by its kind (tiles 870-875, the second sheet from 408).
local function meat(index)
    local item = fish(T.PACKED_MEAT)
    item.getModelIndex = function() return index end
    return item
end
local filled = station("traditionalpreservationfishmeat_01_0", 9, true, { fish(T.PACKED_FISH) }, {}, {})
W.track(filled)
W.refresh(filled)
check("a tub of fish waiting shows fish", table.concat(filled.sprites, " ") == "traditionalpreservationfishmeat_01_2")
for _, case in ipairs({ { 0, "beef", "traditionalpreservationfishmeat_02_462" }, { 4, "pork", "traditionalpreservationfishmeat_02_464" },
                         { T.LEG_INDEX, "a leg", "traditionalpreservationfishmeat_02_466" } }) do
    local salted = station("traditionalpreservationfishmeat_01_0", 10 + case[1], true, { meat(case[1]) }, {}, {})
    W.track(salted)
    W.refresh(salted)
    check("a tub of " .. case[2] .. " waiting shows it", table.concat(salted.sprites, " ") == case[3])
end
check("the kind of a fish is none", W.tubKind({ fish(T.PACKED_FISH) }) == nil and W.tubKind({}) == nil)
check("mixed cuts show the last put in", W.tubKind({ meat(0), meat(4) }) == "pork" and W.tubKind({ meat(4), meat(3) }) == "meat")
check("a leg shows wherever it is", W.tubKind({ meat(T.LEG_INDEX), meat(0), meat(3) }) == "leg")
check("other mods' objects aren't tracked", W.track(station("carpentry_02_122", 4, true, {}, {}, {})) == nil)
check("an untracked station is safe to ask", W.busyStacks({}) == 0)

-- The stale-station fix: once its chunk unloads the cell no longer returns its square, though the object keeps it.
cellSquares["2,0,0"] = {}
yard.sprites = {}
outdoors.progress = 0.9
tick(30)
check("an unloaded frame is dropped, not refreshed", #yard.sprites == 0 and W.busyStacks(yard) == 0)

-- Weather
local ledger = T.getLedger()
local open = ledger.open
H.setHours(101)
H.fire("EveryTenMinutes")
check("the world file records the weather", ledger.temperature == 20 and ledger.wind == 0.3 and ledger.lastHour == 101 and near(ledger.open - open, 1))

H.done()
