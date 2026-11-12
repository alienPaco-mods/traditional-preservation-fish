-- Checks the Leg of Pork (6a): legs made from the Pork a pig gives, outside the game.
-- Run from the mod folder: luajit tests/test_pork.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installEvents()
H.installGetText()

-- A piece of food, as vanilla's butchering leaves it.
local function food(fullType, values)
    local item = { fullType = fullType, values = values or {} }
    function item:getFullType() return self.fullType end
    for _, field in ipairs({ "BaseHunger", "Calories", "Proteins", "Lipids", "Carbohydrates", "Age" }) do
        item["get" .. field] = function(self) return self.values[field] or 0 end
        item["set" .. field] = function(self, value) self.values[field] = value end
    end
    function item:setHungChange(value) self.values.HungChange = value end
    function item:getDisplayName() return "Leg of Pork" end
    return item
end

local inventory = { items = {} }
function inventory:getAllType(fullType)
    local found = {}
    for _, item in ipairs(self.items) do
        if item:getFullType() == fullType then table.insert(found, item) end
    end
    return H.list(found)
end
function inventory:AddItem(item) table.insert(self.items, item) end
function inventory:Remove(item)
    for index, held in ipairs(self.items) do
        if held == item then table.remove(self.items, index) return end
    end
end
local player = { getInventory = function() return inventory end }
function sendAddItemToContainer() end
function sendRemoveItemFromContainer() end
function instanceItem(fullType) return food(fullType) end

-- Vanilla's addAnimalPart gives `given` pieces of whatever row it is asked for.
local given = 0
ButcheringUtil = {
    addAnimalPart = function(part)
        for _ = 1, given do
            inventory:AddItem(food(part.item, { BaseHunger = -0.6, Calories = 300, Proteins = 50, Lipids = 12, Age = 0.5 }))
        end
        return "pork\r\n"
    end,
    getCarcassName = function(carcass) return carcass end,
}
package.loaded["Definitions/animal/AnimalPartsDefinitions"] = true
package.loaded["Definitions/animal/ButcheringUtil"] = true
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPork.lua")
local F = TraditionalPreservationFishMeat

local function count(fullType) return inventory:getAllType(fullType):size() end
local function butcher(carcass, pieces, item)
    inventory.items, given = {}, pieces
    return ButcheringUtil.addAnimalPart({ item = item or "Base.Pork" }, player, carcass, false)
end

check("half the Pork at most, five a leg, three at most", F.legsFrom(4) == 0 and F.legsFrom(10) == 1 and F.legsFrom(19) == 1
    and F.legsFrom(20) == 2 and F.legsFrom(60) == 3)
local text = butcher("sowlandrace", 22)
check("a pig with 22 Pork gives 2 legs and keeps 12 Pork", count(F.LEG_OF_PORK) == 2 and count("Base.Pork") == 12)
check("the log names the legs", text == "pork\r\nLeg of Pork\r\nLeg of Pork\r\n")
local leg = inventory:getAllType(F.LEG_OF_PORK):get(0)
check("a leg holds five pieces' food", near(leg.values.Calories, 1500) and near(leg.values.BaseHunger, -3)
    and near(leg.values.HungChange, -3) and near(leg.values.Proteins, 250) and leg.values.Age == 0.5)
butcher("sowlandrace", 4)
check("from the ground, too few Pork make no leg", count(F.LEG_OF_PORK) == 0 and count("Base.Pork") == 4)
butcher("pigletlandrace", 22)
check("a piglet gives none", count(F.LEG_OF_PORK) == 0)
butcher("sowlandrace", 22, "Base.PorkChop")
check("nor do Pork Chops", count(F.LEG_OF_PORK) == 0)
SandboxVars = { TraditionalPreservationFishMeat = { LegsOfPork = false } }
butcher("boarlargeblack", 22)
check("off in the sandbox, all Pork as in vanilla", count(F.LEG_OF_PORK) == 0 and count("Base.Pork") == 22)
SandboxVars = nil
H.done()
