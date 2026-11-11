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
    cellSquares[x .. ",0," .. z] = s
    return s
end

local function fish(fullType, modData)
    return { getFullType = function() return fullType end, getModData = function() return modData or {} end }
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
    local resources = {}
    function resources:getResourcesFromGroup(group)
        local items = group == "in" and waiting or finished
        return list({ { getStoredItems = function() return list(items) end } })
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
dofile("42/media/lua/server/TraditionalPreservationFishMeatWorld.lua")
local T, W = TraditionalPreservationFishMeat, TraditionalPreservationFishMeatWorld
local PRESSED, GUTTED = "TraditionalPreservationFishMeat.SaltPressedFish", "TraditionalPreservationFishMeat.GuttedFish"

check("the map loader knows the tub, the frame and both beams", loaders.traditionalpreservationfishmeat_01_0
    and loaders.traditionalpreservationfishmeat_01_7 and loaders.traditionalpreservationfishmeat_02_0 and loaders.traditionalpreservationfishmeat_02_3)
check("and nothing else", loaders.traditionalpreservationfishmeat_01_8 == nil)

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

-- Tubs
local tub = station("traditionalpreservationfishmeat_01_1", 3, true, {}, { recipeData(0.3) }, {})
W.track(tub)
W.refresh(tub)
check("a pressing tub shows its weights", table.concat(tub.sprites, " ") == "traditionalpreservationfishmeat_01_5")
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
