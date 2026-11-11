-- Checks joining the Firebox to the Smokehouse chamber outside the game. Run from the mod folder: luajit tests/test_smokehouse.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
local F = TraditionalPreservationFishMeat
local Tiles = require "TraditionalPreservationFishMeat/Tiles"

local CHAMBER = Tiles.HANGERS.chamber.base

-- Sprite numbers: facing S back and door tile, then facing E.
local face, part = F.chamberTile(CHAMBER)
check("the first chamber tile is facing S, back", face == 0 and part == 0)
face, part = F.chamberTile(CHAMBER + 3)
check("the fourth is facing E, door", face == 1 and part == 1)
check("anything else isn't a chamber tile", F.chamberTile(CHAMBER + 4) == nil and F.chamberTile(CHAMBER - 1) == nil and F.chamberTile(nil) == nil)
check("an entry overlay isn't a chamber tile", F.chamberTile(Tiles.CHAMBER_ENTRY) == nil)

-- The other tile: facing S the door's tile is south of the back one.
local dx, dy = F.chamberOther(0, 0)
check("facing S the door tile is one south of the back tile", dx == 0 and dy == 1)
dx, dy = F.chamberOther(1, 1)
check("facing E the back tile is one west of the door tile", dx == -1 and dy == 0)

-- Where a Firebox may stand.
check("facing S the back tile's long sides", F.chamberSideAllowed(0, 0, 1, 0) and F.chamberSideAllowed(0, 0, -1, 0))
check("facing S the back gable", F.chamberSideAllowed(0, 0, 0, -1))
check("never on the shed's other tile", not F.chamberSideAllowed(0, 0, 0, 1))
check("facing S the door tile's long sides", F.chamberSideAllowed(0, 1, 1, 0) and F.chamberSideAllowed(0, 1, -1, 0))
check("never at the door's end", not F.chamberSideAllowed(0, 1, 0, 1))
check("facing E: back gable west, door end east", F.chamberSideAllowed(1, 0, -1, 0) and not F.chamberSideAllowed(1, 1, 1, 0))
check("facing E the door tile's long sides", F.chamberSideAllowed(1, 1, 0, 1) and F.chamberSideAllowed(1, 1, 0, -1))
check("not diagonal or further away", not F.chamberSideAllowed(0, 0, 1, 1) and not F.chamberSideAllowed(0, 0, 2, 0))

-- The entry art, only on the side the camera sees (S: east, E: south), numbered as the tile builder's.
check("pipe, facing S, back tile", F.entrySprite("Pipe", 0, 0, 1, 0) == Tiles.CHAMBER_ENTRY)
check("pipe, facing E, door tile", F.entrySprite("Pipe", 1, 1, 0, 1) == Tiles.CHAMBER_ENTRY + 3)
check("trench, facing S, door tile", F.entrySprite("Stones", 0, 1, 1, 0) == Tiles.CHAMBER_ENTRY + 5)
check("trench, facing E, back tile", F.entrySprite("Stones", 1, 0, 0, 1) == Tiles.CHAMBER_ENTRY + 6)
check("nothing on hidden sides", F.entrySprite("Pipe", 0, 0, -1, 0) == nil and F.entrySprite("Pipe", 0, 0, 0, -1) == nil)
check("nothing when the flue isn't laid", F.entrySprite(nil, 0, 0, 1, 0) == nil)
check("every entry tile is on the second sheet", Tiles.CHAMBER_ENTRY + 7 < Tiles.FIRST_SHEET_SIZE + Tiles.SHEETS[2].tiles)

-- Refusals, the first that applies.
local ok = { allowed = true, flueSide = "Back" }
check("a cold Firebox by a long side joins", F.connectRefusal(ok) == nil)
check("door end refused", F.connectRefusal({ allowed = false, flueSide = "Back" }) == "IGUI_TraditionalPreservationFishMeat_FlueDoorEnd")
check("the Firebox's door side refused", F.connectRefusal({ allowed = true }) == "IGUI_TraditionalPreservationFishMeat_FlueFireboxDoor")
check("not while it burns", F.connectRefusal({ allowed = true, flueSide = "Left", burning = true }) == "IGUI_TraditionalPreservationFishMeat_FlueBurning")
check("one flue a Firebox", F.connectRefusal({ allowed = true, flueSide = "Left", fireboxJoined = true }) == "IGUI_TraditionalPreservationFishMeat_FlueFireboxJoined")
check("one Firebox a shed", F.connectRefusal({ allowed = true, flueSide = "Left", chamberJoined = true }) == "IGUI_TraditionalPreservationFishMeat_FlueChamberJoined")

-- Kits.
local missing, noTool = F.flueKitMissing("Pipe", { ["Base.ClayPipeSegment"] = 2, ["Base.Clay"] = 1 }, true)
check("a full pipe kit", #missing == 0 and not noTool)
missing, noTool = F.flueKitMissing("Stones", { ["Base.FlatStone"] = 1 }, false)
check("two flat stones, two clay and the shovel short",
    #missing == 2 and missing[1][1] == "Base.FlatStone" and missing[1][2] == 2 and missing[2][2] == 2 and noTool)
for _, kind in ipairs(F.FLUE_KINDS) do
    local kit = F.FLUE_KITS[kind]
    local gives = false
    for _, need in ipairs(kit.items) do gives = gives or need[1] == kit.back end
    check(kind .. ": what comes back is part of the kit, and a tool is named", gives and kit.tool ~= nil)
end

H.done()
