#!/usr/bin/env python3
"""Builds the Traditional Preservation (Fish & Meat) tileset (42/media/traditionalpreservationfishmeat.tiles and texturepacks/traditionalpreservationfishmeat.pack).

Tiles 0 and 1 are the empty Salting Tub, 2 and 3 its filled overlay, 4 and 5 its weighted overlay. Tiles 6 and 7
are the Drying Frame. From tile 8 there is one hanging fish per frame slot, drying stage and face, made from vanilla's
fish icons, which TraditionalPreservationFishMeatWorld.lua layers on top. In every pair the even tile is face S and the odd one face E.
Workstations need their own sprite: the game refuses to load a world if two entities share one.

It also writes the item icons and the fish model textures to 42/media/textures. The model textures are vanilla's
fish fillet recoloured and the Salt Cured (SaltPressedFish), Salt Dried and Cold Dried icons are vanilla's fish icons tinted, and the Half icons are those fish split open, so they read the game's files.

Usage: python3 tools/build_tileset.py [path/to/ProjectZomboid/projectzomboid]
Needs Pillow. Rerun after editing the colours or sizes below.
"""
import math
import os
import random
import re
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(os.environ.get("TPCORE", Path(__file__).resolve().parents[2] / "TraditionalPreservationCore")) / "tools"))
import pzart  # noqa: E402
from pzart import FOOT, TILE_W, TILE_H, light_at, project, shrink, tint  # noqa: E402

GAME = Path.home() / ".local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
NAME = "traditionalpreservationfishmeat"
# A tileset can't hold more than 512 tiles (pzart.MAX_SHEET_TILES), or the game drops the whole file and every
# station with it. Tiles are numbered straight through both. The Lua reads these numbers from the generated Tiles.lua.
TILESETS = [NAME + "_01", NAME + "_02"]
COLUMNS = 8
SHEET_ROWS = [51, 58]
FIRST_SHEET_SIZE = COLUMNS * SHEET_ROWS[0]
NAME_TITLE = "TraditionalPreservationFishMeat"
PAGE_SIZE = 2048
SS = 4
# How much of the beam to keep from the top: enough for the fish, as the list draws icons small.
MOD_ICON_KEEP = 0.72
ICON_SIZE = 32

TUB, TUB_FILLED, TUB_WEIGHTED, FRAME, FISH = 0, 2, 4, 6, 8
# The beams come after the frame's fish.
MEDIUM_BEAM, LARGE_BEAM, MEDIUM_FISH, LARGE_FISH = 408, 410, 412, 612
MEDIUM_HOOKS, LARGE_HOOKS = 4, 2
FACES = ["S", "E"]
# The Stockfish Pallet (one face, like vanilla's crates) and its stack of stockfish at a third, two thirds and full.
PALLET, PALLET_STACK = 712, 713
# Charque hanging on each station (phase 3c), after the pallet so no station's tile number moves: one run of
# stages per spot and face, numbered as the fish (fish_index with the meat's first tile).
FRAME_MEAT, MEDIUM_MEAT, LARGE_MEAT = 716, 796, 836
# The Smokehouse chamber (5b-2), two tiles a face: back half, then the front half with the door (chamber_index).
CHAMBER = 856
CHAMBER_STACKS = 6
CHAMBER_HALF = 0.46       # half the shed's width, and how far each end wall stands from its tile's middle, in tiles
CHAMBER_OVERHANG = 0.06   # the roof past the walls
CHAMBER_FRONT = 136       # px up to the roof's high edge, over the door
CHAMBER_BACK = 108        # and its low edge at the back
CHAMBER_SILL = 7          # the stone sill under the planks
CHAMBER_DOOR = 112        # the door's top
CHAMBER_DOOR_HALF = 0.17
CHAMBER_PLANK = 0.11      # a plank's width, in tiles
CHAMBER_WOOD = (112, 78, 50)
CHAMBER_ROOF = (90, 64, 44)
CHAMBER_STONE = (120, 112, 100)
CHAMBER_DARK = (24, 18, 14)
# Where a joined Firebox's flue enters the chamber (5b-2b), on the long side the camera sees: one overlay per flue
# kind, face and part (chamber_entry_index). TP Core's Firebox pipe ends at its tile's edge this high (its TOP + CAP +
# FLUE_RISE) and its trench at ground level, both on the tile's middle; the colours are Core's clay pipe and daub.
CHAMBER_ENTRY = 860
FLUE_KINDS = ["Pipe", "Stones"]
FLUE_Z = 56
FLUE_R = 4.5
FLUE_CLAY = (172, 96, 64)
FLUE_DAUB = (150, 124, 98)
TRENCH_W = 0.07
# A ham hung by the door while finished stacks wait in the chamber (5c, user's idea): one overlay per face, on the
# door's tile, on the door's end wall beside the door.
CHAMBER_HAM = 868
HAM_A = 0.33              # across the end wall, right of the door
HAM_TOP = 92              # px up to the bone's knob; the nail is above it
HAM_COLOUR = (100, 52, 28)  # a shade under the Hot Smoked meat icons' mahogany: it hangs in the shade of the eave
HAM_CORD = (196, 176, 136)
HAM_BONE = (232, 222, 196)
JOIN = 0.02               # the back tile runs this far under the front one, so no seam shows
PALLET_LEVELS = [3, 6, 10]  # layers of fish
PALLET_SPRITE = "construction_01_5"  # vanilla's Empty Pallet, in Tiles2x.pack
PALLET_TOP_Z = 16  # its boards, in pixels above the floor
STACK_LAYER_Z = 5
STACK_HALF = 0.4  # how far the necks reach from the middle, in tiles
STACK_FISH_LENGTH = 0.44
STACK_ROW = [-0.3, -0.15, 0.0, 0.15, 0.3]  # where the fish of a row lie across it
STACK_FISH = ["Fish_Walleye", "Fish_Sauger", "Fish_PerchYellow"]
STACK_SHADE = 0.55  # the underside of each layer
STACK_BOTTOM_LIGHT = 0.8  # the lowest layer; the top one is 1

# The tub: a wide coopered bucket of tilted staves with two iron hoops. Radii and heights in pixels.
TUB_BASE_RX, TUB_RIM_RX, TUB_HEIGHT = 27.0, 33.0, 44.0
SQUASH = 0.5
STAVES = 8
HOOPS = [(0.08, 3.2), (0.5, 2.6), (0.85, 2.6)]  # height as a fraction of the tub, half the band's width
# Colours follow vanilla's rain barrels: deep reddish wood and dark seams.
STAVE = (130, 84, 50)
SEAM = (38, 22, 14)
TUB_INSIDE = (110, 74, 46)
TUB_INSIDE_STAVES = 7
TUB_INSIDE_DEPTH = 22.0
TUB_FLOOR_SIZE = 0.78
TUB_FLOOR_LIGHT = 0.62
TUB_INSIDE_SHADE = 0.62
TUB_RIM_LIGHT = 1.1
TUB_FOOT_SHADE = 0.55
IRON = (70, 71, 75)
IRON_LIT = (104, 105, 110)
RUST = (84, 60, 44)
RUST_CHANCE = 0.07  # of a patch starting at each step round a hoop
SALT = (192, 188, 170)
SALT_SHADE = (150, 144, 124)
SALT_GRAIN = (222, 218, 204, 255)
BURIED_FISH = (122, 130, 128)
BURIED_FISH_BACK = (78, 86, 88)
BURIED_FISH_SPOTS = [(-10.0, -4.0, 24.0, 0.3), (11.0, -3.0, 22.0, 2.8), (0.0, 7.0, 26.0, -0.12)]  # x, y, length, angle
WOOD_WEATHER = 0.3
SALT_WEATHER = 0.3
STICK_WEATHER = 0.32
FISH_WEATHER = 0.14
BOARD = (98, 68, 44)
BOARD_EDGE = (60, 42, 28)
STONE_BLUR = 1.2  # in the oversized layer, so its edges sit into the art
# Field stones side by side on the board, back to front: x and y in tiles, half width in pixels.
# One overhangs the board's edge, and the big one on the right fills the board for an even press.
STONES = [(-0.02, -0.14, 9.5), (-0.1, 0.09, 10.5), (0.19, 0.03, 13.5)]
TURNED_STONES = [(-0.02, -0.14, 9.5), (-0.07, 0.11, 13.5), (0.24, 0.02, 10.0)]
BOARD_RX, BOARD_DROP = 22.0, 2.0  # the tub's opening is 30 wide

# The frame: two A-shaped ends joined by a top and a low rail, with the fish on twine.
FRAME_HALF_LENGTH = 0.44
FRAME_LEG_SPREAD = 0.3
FRAME_TOP_Z = 128
RAILS_Z = [118, 66]
RAIL_SLOTS = [0.14, 0.38, 0.62, 0.86]
SLOTS = [(rail, t) for rail in RAILS_Z for t in RAIL_SLOTS]
# Sticks take their colours from vanilla's butcher hook.
STICK_LIT = (98, 68, 44)
STICK_MID = (74, 50, 33)
STICK_DARK = (44, 30, 20)
STICK_GRAIN = (0.72, 0.84, 0.92, 1.08, 1.2)
END_GRAIN = (186, 146, 116)
STRAW = [(150, 104, 42), (118, 80, 34), (84, 58, 30)]
LEG_RADIUS, BRACE_RADIUS, RAIL_RADIUS = 2.5, 1.8, 2.1
FRAME_BRACE_Z = 34
FRAME_FOOT_SHADE = 0.5
TWINE = (150, 132, 98)
TWINE_DROP = 7

# The beams: heavier timber than the frame, and iron hooks like vanilla's butcher hook.
POST_RADIUS, BEAM_RADIUS = 4.2, 3.4
LARGE_POST_RADIUS, LARGE_BEAM_RADIUS = 5.6, 4.6
MEDIUM_HALF_LENGTH, MEDIUM_BEAM_Z, MEDIUM_HOOK_SIZE, MEDIUM_FISH_SCALE = 0.46, 132, 9, 1.3
LARGE_HALF_LENGTH, LARGE_BEAM_Z, LARGE_HOOK_SIZE, LARGE_FISH_SCALE = 0.46, 160, 17.5, 1.9

# A hanging fish fades from the first of these to the last as it dries, and salt blooms on it.
FISH_STAGES = 5
# Each look a hanging fish can have gets a full set of tiles: whole, then gutted and half for cold drying,
# then gutted and half for salt drying, named for the Lua's STYLE_ values.
STYLE_NAMES = ["SALT", "GUTTED", "HALF", "SALT_GUTTED", "SALT_HALF"]
FISH_STYLES = len(STYLE_NAMES)
GUTTED_STYLES, HALF_STYLES, COLD_STYLES = (1, 3), (2, 4), (1, 2)
FRESH_FISH = dict(colour=(226, 224, 212), strength=0.42, grains=5)
DONE_FISH = dict(colour=(120, 76, 40), strength=0.62, grains=3)
FRESH_COLD_FISH = dict(colour=(222, 200, 188), strength=0.2, grains=0)
DONE_COLD_FISH = dict(colour=(170, 164, 146), strength=0.65, grains=0)
# Charque darkens from cured red, with a little salt, to deep brown.
FRESH_MEAT = dict(colour=(140, 58, 46), strength=0.6, grains=3)
DONE_MEAT = dict(colour=(78, 40, 26), strength=0.9, grains=0)
# The style number the Lua gives a meat stack. It has its own tiles, so it isn't counted in FISH_STYLES.
MEAT_STYLE = FISH_STYLES
# The vanilla meat icons hung as charque, picked at random for each spot like the fish.
HANGING_MEAT = [("BeefLoin", 0), ("Steak", 0), ("Venison", 0)]
MEAT_SCALE = 0.75
# The vanilla icons hung on a frame, picked at random for each spot, and which way to turn each.
HANGING_FISH = [("Fish_Walleye", 0), ("Fish_PerchYellow", 0), ("Fish_Sauger", 0)]  # bass icons are too curved to hang
HANGING_SCALE = 0.74
# Wide fish turn to blobs at a beam's size, so beams only hang the slim ones.
BEAM_FISH = [("Fish_Walleye", 0), ("Fish_Sauger", 0)]
TAIL_OVER_HOOK = 4
HOOK_INTO_FISH = 1 / 3
HOOK_SHIFT = 1.3
OUTLINE_SHADE, OUTLINE_DEPTH = 0.62, 3
SHADOW = (0, 0, 0, 110)


def fish_stage(stage, fresh=FRESH_FISH, done=DONE_FISH):
    """The tint for a drying stage, fading from pale and salty to brown, or to grey for cold drying."""
    amount = stage / (FISH_STAGES - 1)
    colour = tuple(int(a + (b - a) * amount) for a, b in zip(fresh["colour"], done["colour"]))
    strength = fresh["strength"] + (done["strength"] - fresh["strength"]) * amount
    grains = int(fresh["grains"] + (done["grains"] - fresh["grains"]) * amount)
    return colour, strength, grains


# Soaked fish never gets its colour back: it stays darker than fresh.
SOAKED_ICON, SOAKED_COLD_ICON = ((150, 118, 88), 0.5), ((142, 130, 110), 0.5)

# Fallback icons for fish from other mods: tint colour, tint strength, salt grains.
STAGES = {
    "SaltPackedFish": ((232, 232, 224), 0.3, 30),
    "SaltPressedFish": ((232, 228, 214), 0.5, 16),
    "SaltDriedFish": ((128, 84, 44), 0.5, 0),
    "SoakedSaltFish": SOAKED_ICON + (0,),
    "ColdDriedFish": ((176, 170, 150), 0.55, 0),
    "SoakedColdFish": SOAKED_COLD_ICON + (0,),
}
# Vanilla's fish icons, in the order of IconsForTexture. Salmon's is in the older UI.pack.
FISH_ICONS = ["FishFillet", "Salmon", "Fish_BassLargemouth", "Fish_BassSmallmouth", "Fish_BassSpotted", "Fish_BassStriped",
              "Fish_Walleye", "Fish_Sauger", "Fish_CrappieBlack", "Fish_CrappieWhite", "Fish_Bluegill", "Fish_SunfishRedear",
              "Fish_SunfishGreen", "Fish_CatfishBlue", "Fish_CatfishChannel", "Fish_CatfishFlathead", "Fish_Muskellunge",
              "Fish_BassWhite", "Fish_PerchYellow", "Fish_DrumFreshwater", "Fish_GarAlligator", "Fish_Paddlefish"]
OLD_PACK_ICONS = {"Salmon"}
OLD_PACK_MEAT = {"Steak"}
# Copies of those icons for five stages: prefix, tint colour, tint strength, salt grains.
FLESH, SPINE, HEAD_RED = (232, 176, 164, 255), (120, 44, 48, 255), (150, 30, 34, 255)
HALF_FLESH, HALF_FLESH_WIDTH, HALF_FLESH_HEIGHT = (214, 96, 92), 0.3, 0.32
# Slightly bigger than a fillet's 0.3. FishHalfGround in the item script must match.
HALF_MODEL_SCALE = 0.36
HALF_ICON_SKIN = 2
# Tails and fins too thick to be told from the body, in the same form as HEAD_CUTS. They keep their skin.
SKIN_CUTS = {
    "Fish_Sauger": [(20, 25, 26, 17, 29, 25)],
    "Fish_Muskellunge": [(16, 2, 16, 12, 10, 4)],
    "Fish_CatfishBlue": [(16, 14, 30, 14, 15, 3)],
    "Fish_CatfishChannel": [(16, 14, 30, 14, 14, 3)],
    "Fish_CatfishFlathead": [(16, 14, 30, 14, 15, 3)],
    "Fish_CrappieBlack": [(20, 27, 27, 19, 27, 29), (24, 5, 27, 16, 29, 10)],
}
# The largest a Fish Head's art may be in its icon.
HEAD_ICON_FIT = 28
# The Fish Head icon's cut face, from the outside in, and how dark the gill-cover line is.
HEAD_CUT_RIM, HEAD_CUT_MEAT, HEAD_CUT_BONE = (70, 18, 22, 255), (176, 58, 60, 255), (236, 226, 206, 255)
HEAD_GILL_SHADE = 0.55
# Where the head comes off each vanilla icon: two points on the cut, and a point on the head.
HEAD_CUTS = {
    "Fish_BassLargemouth": (13, 3, 10, 15, 4, 8), "Fish_BassSmallmouth": (13, 3, 10, 15, 4, 8),
    "Fish_BassSpotted": (13, 3, 10, 15, 4, 8), "Fish_BassStriped": (13, 3, 10, 15, 4, 8),
    "Fish_BassWhite": (13, 3, 10, 15, 4, 8), "Fish_Walleye": (11, 3, 3, 11, 2, 2), "Fish_Sauger": (11, 4, 3, 12, 2, 2),
    "Fish_CrappieBlack": (11, 1, 8, 18, 2, 8), "Fish_CrappieWhite": (12, 2, 4, 14, 2, 4), "Fish_Bluegill": (10, 1, 7, 17, 3, 6),
    "Fish_SunfishRedear": (10, 2, 6, 16, 2, 8), "Fish_SunfishGreen": (12, 2, 6, 18, 3, 8), "Fish_PerchYellow": (10, 1, 5, 14, 2, 3),
    "Fish_DrumFreshwater": (10, 1, 5, 15, 2, 4), "Fish_CatfishBlue": (10, 19, 14, 30, 3, 26), "Fish_CatfishChannel": (10, 19, 14, 30, 3, 26),
    "Fish_CatfishFlathead": (11, 20, 13, 30, 3, 27), "Fish_Muskellunge": (11, 19, 12, 30, 2, 25),
    "Fish_GarAlligator": (15, 20, 17, 31, 2, 28), "Fish_Paddlefish": (14, 20, 15, 31, 2, 28),
}
ICON_STAGES = [("Pressed", (232, 228, 214), 0.5, 16), ("Dried", (128, 84, 44), 0.5, 0), ("Cold", (176, 170, 150), 0.55, 0),
               ("Soaked",) + SOAKED_ICON + (0,), ("SoakedCold",) + SOAKED_COLD_ICON + (0,)]
MODEL_TINTS = {
    "SaltPackedFishModel": ((222, 222, 214), 0.75),
    "SaltPressedFishModel": ((190, 182, 156), 0.6),
    "SaltDriedFishModel": ((140, 96, 54), 0.7),
    "ColdDriedFishModel": ((176, 170, 150), 0.7),
    "SoakedFishModel": SOAKED_ICON[:1] + (0.65,),
}
# Each stage's model for a species is the vanilla fish with its texture repainted. Both sides of a
# fish share one area of the texture, head up, so anything painted shows on both.
MODEL_PREFIXES = {"Packed": ((222, 222, 214), 0.6), "Pressed": ((190, 182, 156), 0.5), "Dried": ((140, 96, 54), 0.6), "Cold": ((176, 170, 150), 0.65),
                  "Soaked": SOAKED_ICON[:1] + (0.55,), "SoakedCold": SOAKED_COLD_ICON[:1] + (0.55,)}
SALT_MODEL_PREFIXES = ["Packed", "Pressed", "Dried", "Soaked"]  # cold stages are already gutted
# The vanilla items behind FISH_ICONS, past the fillet and salmon, which have no fish model to copy.
FISH_ITEMS = dict(zip(FISH_ICONS[2:], ["LargemouthBass", "SmallmouthBass", "SpottedBass", "StripedBass", "Walleye", "Sauger", "BlackCrappie",
                                       "WhiteCrappie", "Bluegill", "RedearSunfish", "GreenSunfish", "BlueCatfish", "ChannelCatfish",
                                       "FlatheadCatfish", "Muskellunge", "WhiteBass", "YellowPerch", "FreshwaterDrum", "AligatorGar", "Paddlefish"]))


def station_props(custom, group, facing, weight):
    return [("BlocksPlacement", ""), ("CustomName", custom), ("Facing", facing), ("GroupName", group), ("IsMoveAble", ""), ("PickUpWeight", weight), ("solidtrans", "")]


def chamber_index(face_index, part):
    """part 0 is the back tile, 1 the front one with the door."""
    return CHAMBER + face_index * 2 + part


def chamber_entry_index(kind, face_index, part):
    """chamberEntry / F.entrySprite in TraditionalPreservationFishMeatSmokehouse.lua number them the same way."""
    return CHAMBER_ENTRY + (FLUE_KINDS.index(kind) * len(FACES) + face_index) * 2 + part


def fish_index(face_index, slot, stage, first=FISH, slots=len(SLOTS)):
    """refreshFrame in TraditionalPreservationFishMeatWorld.lua numbers them the same way, from the generated Tiles.lua."""
    return first + (stage * slots + slot) * len(FACES) + face_index


TILE_PROPS = {}
TILE_PROPS[PALLET] = [("BlocksPlacement", ""), ("CanScrap", ""), ("container", "stockfishpallet"), ("ContainerCapacity", "20"),
                      ("CustomName", "Pallet"), ("GroupName", "Stockfish"), ("IsLow", ""), ("IsMoveAble", ""),
                      ("Material", "Wood"), ("Material2", "Nails"), ("PickUpWeight", "50"), ("ScrapSize", "Small")]
for level in range(len(PALLET_LEVELS)):
    TILE_PROPS[PALLET_STACK + level] = []
# A two-tile station names each tile's place in the grid ("x,y", as vanilla's Drying Rack and Loom): facing S the
# back tile is 0,0 and the door's 0,1; facing E 0,0 and 1,0.
for face_index, face in enumerate(FACES):
    for part in range(2):
        grid = f"0,{part}" if face == "S" else f"{part},0"
        TILE_PROPS[chamber_index(face_index, part)] = station_props("Chamber", "Smokehouse", face, "200") + [
            ("ForceSingleItem", ""), ("SpriteGridPos", grid)]
for kind in FLUE_KINDS:
    for face_index, face in enumerate(FACES):
        for part in range(2):
            TILE_PROPS[chamber_entry_index(kind, face_index, part)] = [("Facing", face)]
for face_index, face in enumerate(FACES):
    TILE_PROPS[CHAMBER_HAM + face_index] = [("Facing", face)]
for face_index, face in enumerate(FACES):
    TILE_PROPS[TUB + face_index] = station_props("Tub", "Salting", face, "100")
    TILE_PROPS[FRAME + face_index] = station_props("Frame", "Drying", face, "100")
    TILE_PROPS[MEDIUM_BEAM + face_index] = station_props("BeamMedium", "Drying", face, "100")
    TILE_PROPS[LARGE_BEAM + face_index] = station_props("BeamLarge", "Drying", face, "150")
    TILE_PROPS[TUB_FILLED + face_index] = [("Facing", face)]
    TILE_PROPS[TUB_WEIGHTED + face_index] = [("Facing", face)]
    for slot in range(len(SLOTS)):
        for stage in range(FISH_STAGES * FISH_STYLES):
            TILE_PROPS[fish_index(face_index, slot, stage)] = [("Facing", face)]
    for first, hooks in ((MEDIUM_FISH, MEDIUM_HOOKS), (LARGE_FISH, LARGE_HOOKS)):
        for slot in range(hooks):
            for stage in range(FISH_STAGES * FISH_STYLES):
                TILE_PROPS[fish_index(face_index, slot, stage, first, hooks)] = [("Facing", face)]
    for first, hooks in ((FRAME_MEAT, len(SLOTS)), (MEDIUM_MEAT, MEDIUM_HOOKS), (LARGE_MEAT, LARGE_HOOKS)):
        for slot in range(hooks):
            for stage in range(FISH_STAGES):
                TILE_PROPS[fish_index(face_index, slot, stage, first, hooks)] = [("Facing", face)]


def new_layer():
    return pzart.new_layer(SS)


def scaled(points):
    return [(x * SS, y * SS) for x, y in points]


def ellipse(draw, cx, cy, rx, ry, fill):
    draw.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=fill)


def ring_point(cy, rx, angle):
    return (FOOT[0] + rx * math.cos(angle), cy + rx * SQUASH * math.sin(angle))


def weather(tile, seed, depth, streaks=False):
    """Mottles a finished tile with dirt and grain, and water stains running down it when streaks is set.
    Vanilla art is hand painted and never flat, so everything goes through this."""
    return pzart.weather(tile, random.Random(seed * 31 + 7), depth, streaks)


def tub_rim_y():
    return FOOT[1] - TUB_HEIGHT


def paint_hoop(draw, rng, level, half_height):
    """A flat iron band round the front of the tub, level being its height as a fraction of the tub's."""
    base_y, rim_y = FOOT[1], tub_rim_y()
    rx = TUB_BASE_RX + (TUB_RIM_RX - TUB_BASE_RX) * level + 0.7
    cy = base_y + (rim_y - base_y) * level
    for first, second, colour, shade in pzart.hoop_bands(rng, RUST_CHANCE, IRON, RUST):
        band = [ring_point(cy - half_height, rx, first), ring_point(cy - half_height, rx, second),
                ring_point(cy + half_height, rx, second), ring_point(cy + half_height, rx, first)]
        draw.polygon(scaled(band), fill=tint(colour, shade))
        draw.line(scaled(band[:2]), fill=tint(IRON_LIT, shade), width=SS // 2 + 1)
        draw.line(scaled(band[2:]), fill=tint(IRON, shade * 0.45), width=SS)


def paint_tub_inside(rng):
    """The far wall's staves running down to the floor, as vanilla's buckets show. The light comes from the
    left, so it lands on the inside of the right-hand wall."""
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    rim_y = tub_rim_y() + 0.6
    floor_y = rim_y + TUB_INSIDE_DEPTH
    rim_rx = TUB_RIM_RX - 3
    floor_rx = rim_rx * TUB_FLOOR_SIZE
    ellipse(draw, FOOT[0], rim_y, rim_rx, rim_rx * SQUASH, TUB_INSIDE + (255,))

    edges = pzart.stave_edges(rng, TUB_INSIDE_STAVES, 0.8, 1.2, start=math.pi)
    for first, second in zip(edges, edges[1:]):
        shade = pzart.inside_light((first + second) / 2) * rng.uniform(0.95, 1.05)
        quad = [ring_point(rim_y, rim_rx, first), ring_point(rim_y, rim_rx, second),
                ring_point(floor_y, floor_rx, second), ring_point(floor_y, floor_rx, first)]
        draw.polygon(scaled(quad), fill=tint(TUB_INSIDE, shade))
        for _ in range(14):
            t = rng.random()
            top = ring_point(rim_y, rim_rx, first + (second - first) * t)
            bottom = ring_point(floor_y, floor_rx, first + (second - first) * t)
            start, length = rng.random(), rng.uniform(0.2, 0.5)
            line = [(top[0] + (bottom[0] - top[0]) * u, top[1] + (bottom[1] - top[1]) * u) for u in (start, min(1, start + length))]
            draw.line(scaled(line), fill=tint(TUB_INSIDE, shade * rng.uniform(0.82, 1.14)), width=2)
        draw.line(scaled([ring_point(rim_y, rim_rx, second), ring_point(floor_y, floor_rx, second)]), fill=SEAM + (255,), width=SS // 2 + 1)

    ellipse(draw, FOOT[0], floor_y, floor_rx, floor_rx * SQUASH, tint(TUB_INSIDE, TUB_FLOOR_LIGHT))
    return pzart.darken_down(layer, rim_y, floor_y + floor_rx * SQUASH, TUB_INSIDE_SHADE, SS)


def paint_tub(seed):
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    base_y, rim_y = FOOT[1], tub_rim_y()

    ellipse(draw, FOOT[0] + 1, base_y + 1, TUB_BASE_RX + 2, (TUB_BASE_RX + 2) * SQUASH, SHADOW)
    ellipse(draw, FOOT[0], rim_y, TUB_RIM_RX, TUB_RIM_RX * SQUASH, tint(STAVE, TUB_RIM_LIGHT))
    layer.alpha_composite(clipped(paint_tub_inside(rng), inside_mask()))

    edges = pzart.stave_edges(rng, STAVES, 0.75, 1.25)
    for first, second in zip(edges, edges[1:]):
        shade = light_at((first + second) / 2) * rng.uniform(0.94, 1.06)
        quad = [ring_point(rim_y, TUB_RIM_RX, first), ring_point(rim_y, TUB_RIM_RX, second),
                ring_point(base_y, TUB_BASE_RX, second), ring_point(base_y, TUB_BASE_RX, first)]
        draw.polygon(scaled(quad), fill=tint(STAVE, shade))
        draw.line(scaled([quad[0], quad[3]]), fill=SEAM + (255,), width=SS)

    layer = pzart.darken_down(layer, rim_y, base_y, TUB_FOOT_SHADE, SS)
    draw = ImageDraw.Draw(layer)
    for level, half_height in HOOPS:
        paint_hoop(draw, rng, level, half_height)
    return weather(shrink(layer), seed, WOOD_WEATHER, streaks=True)


def clipped(art, mask):
    """Keeps only the part of a layer inside mask. Pasting straight onto art would also copy its clear pixels."""
    result = Image.new("RGBA", art.size, (0, 0, 0, 0))
    result.paste(art, (0, 0), mask)
    return result


def inside_mask():
    """The tub's opening, which limits what sits inside it."""
    mask = Image.new("L", (TILE_W * SS, TILE_H * SS), 0)
    rx = TUB_RIM_RX - 3
    ellipse(ImageDraw.Draw(mask), FOOT[0], tub_rim_y() + 0.6, rx, rx * SQUASH, 255)
    return mask


def paint_buried_fish(draw, x, y, length, angle):
    """One fish lying in the salt, seen from above, with a tail at one end."""
    along = (math.cos(angle), math.sin(angle) * SQUASH)
    across = (-math.sin(angle), math.cos(angle) * SQUASH)
    at = lambda u, v: (x + along[0] * u + across[0] * v, y + along[1] * u + across[1] * v)
    half = length / 2
    body = []
    for i in range(17):
        t = i / 16
        width = length * 0.3 * math.sin(math.pi * t ** 0.8)
        body.append(at(-half + length * t, width))
    for i in range(16, -1, -1):
        t = i / 16
        width = length * 0.3 * math.sin(math.pi * t ** 0.8)
        body.append(at(-half + length * t, -width))
    tail = [at(-half + 1, 0), at(-half - length * 0.22, length * 0.24), at(-half - length * 0.12, 0), at(-half - length * 0.22, -length * 0.24)]
    draw.polygon(scaled(tail), fill=BURIED_FISH_BACK + (255,))
    draw.polygon(scaled(body), fill=BURIED_FISH + (255,))
    ridge = [at(-half + length * t, -length * 0.05) for t in (0.1, 0.5, 0.9)]
    draw.line(scaled(ridge), fill=BURIED_FISH_BACK + (255,), width=int(2.4 * SS))


def salt_layer(seed, fish=False):
    """A bed of salt just below the rim. Uncovered, the top layer of fish shows through it."""
    contents = new_layer()
    draw = ImageDraw.Draw(contents)
    rng = random.Random(seed)
    cy = tub_rim_y() + 4
    ellipse(draw, FOOT[0], cy, TUB_RIM_RX, TUB_RIM_RX * SQUASH, SALT + (255,))
    if fish:
        for x, y, length, angle in BURIED_FISH_SPOTS:
            paint_buried_fish(draw, FOOT[0] + x, cy + y, length, angle + rng.uniform(-0.15, 0.15))
    for _ in range(130 if fish else 320):
        angle = rng.uniform(0, math.tau)
        reach = math.sqrt(rng.random()) * TUB_RIM_RX
        x, y = FOOT[0] + reach * math.cos(angle), cy + reach * SQUASH * math.sin(angle)
        ellipse(draw, x, y, 0.8, 0.5, rng.choice([SALT, SALT, SALT_SHADE]) + (255,))

    return clipped(contents, inside_mask())


def paint_stone(layer, rng, boulder, cx, cy, rx):
    """Vanilla's large stone, turned and sized, with its base at (cx, cy)."""
    draw = ImageDraw.Draw(layer)
    ellipse(draw, cx + 1.5, cy + rx * 0.45, rx * 1.05, rx * 0.34, (30, 24, 18, 120))
    stone = soften_outline(boulder).rotate(rng.choice([0, 12, -14, 170, 190]), resample=Image.BICUBIC, expand=True)
    stone = stone.crop(stone.getbbox())
    if rng.random() < 0.5:
        stone = stone.transpose(Image.FLIP_LEFT_RIGHT)
    width = round(rx * 2 * SS)
    stone = stone.resize((width, round(width * stone.height / stone.width * rng.uniform(0.86, 1.0))), Image.BICUBIC)
    stone = stone.filter(ImageFilter.GaussianBlur(STONE_BLUR))
    layer.alpha_composite(stone, (round(cx * SS - stone.width / 2), round(cy * SS - stone.height / 2)))


def paint_weighted(seed, turned, boulder):
    """A round board sunk into the tub on the salt, which shows around it, held down by stones."""
    layer = salt_layer(seed)
    draw = ImageDraw.Draw(layer)
    cy = tub_rim_y() + BOARD_DROP
    rx = BOARD_RX
    ellipse(draw, FOOT[0], cy + 3, rx + 2, (rx + 2) * SQUASH, tint(SALT_SHADE, 0.7))
    ellipse(draw, FOOT[0], cy + 1.8, rx, rx * SQUASH, BOARD_EDGE + (255,))
    ellipse(draw, FOOT[0], cy, rx, rx * SQUASH, BOARD + (255,))

    grain = new_layer()
    grain_draw = ImageDraw.Draw(grain)
    slope = -0.5 if turned else 0.5
    for i in range(-2, 3):
        offset = i * 5.5
        first = (FOOT[0] - 40, cy + offset - 40 * slope)
        second = (FOOT[0] + 40, cy + offset + 40 * slope)
        grain_draw.line(scaled([first, second]), fill=BOARD_EDGE + (255,), width=SS // 2 + 1)
    mask = Image.new("L", layer.size, 0)
    ellipse(ImageDraw.Draw(mask), FOOT[0], cy, rx, rx * SQUASH, 255)
    layer.alpha_composite(clipped(grain, mask))

    rng = random.Random(seed + 40)
    for x, y, rx in TURNED_STONES if turned else STONES:
        px, py = project(y, x, TUB_HEIGHT - BOARD_DROP + 3) if turned else project(x, y, TUB_HEIGHT - BOARD_DROP + 3)
        paint_stone(layer, rng, boulder, px, py, rx)
    return shrink(layer)


def rail_point(face, along, across=0.0, z=0.0):
    """along runs the length of the frame, across its width."""
    if face == "S":
        return project(along, across, z)
    return project(across, along, z)


def paint_stick(draw, rng, start, end, radius, cap=True):
    """A long stick with the butcher hook's colours: round, so lit down one side and dark down the other,
    wandering a little and changing thickness along its length, with pale end grain where it was cut."""
    span = math.dist(start, end)
    ux, uy = (end[0] - start[0]) / span, (end[1] - start[1]) / span
    nx, ny = -uy, ux
    if (abs(uy) > abs(ux) and nx > 0) or (abs(uy) <= abs(ux) and ny > 0):
        nx, ny = -nx, -ny  # points to the lit side
    steps = max(3, int(span / 9))
    nodes = []
    for i in range(steps + 1):
        t = i / steps
        wander = 0.0 if i in (0, steps) else rng.uniform(-0.7, 0.7)
        nodes.append((start[0] + (end[0] - start[0]) * t + nx * wander, start[1] + (end[1] - start[1]) * t + ny * wander, radius * rng.uniform(0.84, 1.12)))

    def edge(offset):
        return [(x + nx * offset * r, y + ny * offset * r) for x, y, r in nodes]

    for near, far, colour in ((1.0, 0.25, STICK_LIT), (0.25, -0.35, STICK_MID), (-0.35, -1.0, STICK_DARK)):
        draw.polygon(scaled(edge(near) + edge(far)[::-1]), fill=colour + (255,))
    for _ in range(int(span * radius * 0.9)):
        t = rng.random()
        run = min(rng.uniform(2, 9) / span, 1 - t)
        across = rng.uniform(-0.9, 0.9) * radius
        first = (start[0] + (end[0] - start[0]) * t + nx * across, start[1] + (end[1] - start[1]) * t + ny * across)
        second = (first[0] + (end[0] - start[0]) * run, first[1] + (end[1] - start[1]) * run)
        draw.line(scaled([first, second]), fill=tint(STICK_MID, rng.choice(STICK_GRAIN)), width=rng.choice((1, 2, 2, 3)))
    if cap:
        ellipse(draw, end[0], end[1], radius * 1.05, radius * 0.75, END_GRAIN + (255,))
        ellipse(draw, end[0], end[1], radius * 0.45, radius * 0.3, tint(END_GRAIN, 0.8))


def paint_lashing(draw, rng, point, radius):
    """Turns of twine round a joint."""
    for i in range(-2, 3):
        y = point[1] + i * 1.1
        draw.line(scaled([(point[0] - radius - 0.8, y + 0.7), (point[0] + radius + 0.8, y - 0.7)]), fill=tint(TWINE, rng.uniform(0.62, 1.0)), width=SS // 2 + 2)


def paint_tuft(draw, rng, foot):
    """Trodden dirt and dry straw where a post goes into the ground."""
    ellipse(draw, foot[0], foot[1] + 0.5, 6.5, 3.2, SHADOW)
    for _ in range(26):
        angle = rng.uniform(0, math.tau)
        reach = rng.uniform(2, 9)
        start = (foot[0] + math.cos(angle) * reach * 0.4, foot[1] + math.sin(angle) * reach * 0.2)
        stop = (foot[0] + math.cos(angle) * reach, foot[1] + math.sin(angle) * reach * 0.5)
        draw.line(scaled([start, stop]), fill=tint(rng.choice(STRAW), rng.uniform(0.7, 1.1)), width=rng.choice((2, 3)))


def paint_frame(face):
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    rng = random.Random(FACES.index(face) + 70)
    half, spread = FRAME_HALF_LENGTH, FRAME_LEG_SPREAD
    ends = sorted([-half, half], key=lambda along: rail_point(face, along)[1])

    def paint_end(along):
        top = rail_point(face, along, 0.0, FRAME_TOP_Z)
        back, front = rail_point(face, along, -spread), rail_point(face, along, spread)
        brace_at = 1 - FRAME_BRACE_Z / FRAME_TOP_Z
        brace = [rail_point(face, along, -spread * brace_at, FRAME_BRACE_Z), rail_point(face, along, spread * brace_at, FRAME_BRACE_Z)]
        paint_stick(draw, rng, back, top, LEG_RADIUS)
        paint_stick(draw, rng, front, top, LEG_RADIUS)
        paint_stick(draw, rng, brace[0], brace[1], BRACE_RADIUS, cap=False)
        for point in brace:
            paint_lashing(draw, rng, point, BRACE_RADIUS)
        paint_lashing(draw, rng, (top[0], top[1] + 8), LEG_RADIUS)

    paint_end(ends[0])
    for z in RAILS_Z:
        first, second = rail_point(face, -half - 0.05, 0.0, z), rail_point(face, half + 0.05, 0.0, z)
        paint_stick(draw, rng, first, second, RAIL_RADIUS)
        for along in (-half, half):
            paint_lashing(draw, rng, rail_point(face, along, 0.0, z), RAIL_RADIUS)
    paint_end(ends[1])
    layer = pzart.darken_down(layer, FOOT[1] - 74, FOOT[1] + 30, FRAME_FOOT_SHADE, SS)

    ground = new_layer()
    ground_draw = ImageDraw.Draw(ground)
    feet = [rail_point(face, along, across) for along in ends for across in (-spread, spread)]
    for foot in sorted(feet, key=lambda point: point[1]):
        paint_tuft(ground_draw, rng, foot)
    ground.alpha_composite(layer)
    return weather(shrink(ground), FACES.index(face) + 70, STICK_WEATHER, streaks=True)


def hook_tip(point, size):
    """The end of a hook's straight drop, which goes into a fish's tail."""
    return (point[0], point[1] + size * 0.8)


def paint_hook(draw, point, tip):
    x, y = point
    shape = [(x, y), (x, tip)]
    draw.line(scaled(shape), fill=tint(IRON, 0.75), width=int(SS * 1.6))
    draw.line(scaled([(a - 0.5, b) for a, b in shape]), fill=tint(IRON_LIT, 1.05), width=SS // 2 + 1)


def finish_beam(layer, rng, feet, face):
    layer = pzart.darken_down(layer, FOOT[1] - 74, FOOT[1] + 30, FRAME_FOOT_SHADE, SS)
    ground = new_layer()
    ground_draw = ImageDraw.Draw(ground)
    for foot in sorted(feet, key=lambda point: point[1]):
        paint_tuft(ground_draw, rng, foot)
    ground.alpha_composite(layer)
    return weather(shrink(ground), FACES.index(face) + 90, STICK_WEATHER, streaks=True)


def shifted(face, point, scale):
    """Moves a hook along its beam, to the right on screen, so it ends where the fish's body looks centred."""
    shift = HOOK_SHIFT * scale
    return (point[0] + shift, point[1] + shift * (0.5 if face == "S" else -0.5))


def medium_hooks(face):
    half = MEDIUM_HALF_LENGTH
    return [shifted(face, rail_point(face, -half + 2 * half * (hook + 0.5) / MEDIUM_HOOKS, 0.0, MEDIUM_BEAM_Z - BEAM_RADIUS - 2), MEDIUM_FISH_SCALE) for hook in range(MEDIUM_HOOKS)]


def large_hooks(face):
    along = LARGE_HALF_LENGTH / 2
    return sorted((shifted(face, rail_point(face, side * along, 0.0, LARGE_BEAM_Z - LARGE_BEAM_RADIUS - 2), LARGE_FISH_SCALE) for side in (-1, 1)), key=lambda point: point[1])


def paint_beam(face, seed, half, top, post_radius, beam_radius, hooks, hook_size):
    """Two posts and a long beam, with the hooks along it."""
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    rng = random.Random(FACES.index(face) + seed)
    ends = sorted([-half, half], key=lambda along: rail_point(face, along)[1])
    paint_stick(draw, rng, rail_point(face, ends[0]), rail_point(face, ends[0], 0.0, top + 8), post_radius)
    paint_stick(draw, rng, rail_point(face, -half - 0.06, 0.0, top), rail_point(face, half + 0.06, 0.0, top), beam_radius)
    paint_stick(draw, rng, rail_point(face, ends[1]), rail_point(face, ends[1], 0.0, top + 8), post_radius)
    for point in hooks:
        paint_hook(draw, point, hook_tip(point, hook_size)[1])
    return finish_beam(layer, rng, [rail_point(face, end) for end in ends], face)


def paint_medium_beam(face):
    return paint_beam(face, 90, MEDIUM_HALF_LENGTH, MEDIUM_BEAM_Z, POST_RADIUS, BEAM_RADIUS, medium_hooks(face), MEDIUM_HOOK_SIZE)


def paint_large_beam(face):
    return paint_beam(face, 95, LARGE_HALF_LENGTH, LARGE_BEAM_Z, LARGE_POST_RADIUS, LARGE_BEAM_RADIUS, large_hooks(face), LARGE_HOOK_SIZE)


def long_axis(icon):
    """The angle in degrees of the longest line through an icon's solid pixels."""
    solid = [(x, y) for x in range(icon.width) for y in range(icon.height) if icon.getpixel((x, y))[3] > 128]
    mean_x = sum(x for x, _ in solid) / len(solid)
    mean_y = sum(y for _, y in solid) / len(solid)
    xx = sum((x - mean_x) ** 2 for x, _ in solid)
    yy = sum((y - mean_y) ** 2 for _, y in solid)
    xy = sum((x - mean_x) * (y - mean_y) for x, y in solid)
    return math.degrees(0.5 * math.atan2(2 * xy, xx - yy))


def hanging_icon(icon, turn, scale=1.0):
    """Stands a vanilla fish icon on end, tail up. turn is 0 or 180, depending which way its head points."""
    big = icon.resize((icon.width * 4, icon.height * 4), Image.NEAREST)
    upright = big.rotate(long_axis(icon) + 90 + turn, resample=Image.BICUBIC, expand=True)
    upright = upright.crop(upright.getbbox())
    size = HANGING_SCALE * scale / 4
    return upright.resize((max(1, round(upright.width * size)), max(1, round(upright.height * size))), Image.LANCZOS)


def fish_spot(face, slot):
    rail_z, t = SLOTS[slot]
    along = -FRAME_HALF_LENGTH + 2 * FRAME_HALF_LENGTH * t
    return rail_point(face, along, 0.0, rail_z)


def paint_fish_tile(icons, face, slot, stage):
    layer = new_layer()
    x, y = fish_spot(face, slot)
    ImageDraw.Draw(layer).line(scaled([(x, y), (x, y + TWINE_DROP)]), fill=TWINE + (255,), width=SS // 2 + 1)
    tile = shrink(layer)

    fish = hanging_fish(icons, face, slot, stage)
    tile.alpha_composite(fish, (round(x - fish.width / 2), round(y + TWINE_DROP - 2)))
    return weather(tile, slot * 5 + stage + 90, FISH_WEATHER)


def hanging_meat(icons, face, slot, stage, scale=1.0):
    """A cut of charque for a spot, at one drying stage."""
    name, turn = random.Random(f"meat{face}{slot}").choice(HANGING_MEAT)
    colour, strength, grains = fish_stage(stage, FRESH_MEAT, DONE_MEAT)
    return stage_icon(hanging_icon(icons[f"Item_{name}"], turn, scale * MEAT_SCALE), colour, strength, grains, slot * 5 + stage)


def hanging_fish(icons, face, slot, stage, scale=1.0, choices=HANGING_FISH):
    """A fish for a spot. stage carries its style, as in the tile numbers; the meat style has a stage only."""
    if stage >= FISH_STAGES * FISH_STYLES:
        return hanging_meat(icons, face, slot, stage - FISH_STAGES * FISH_STYLES, scale)
    name, turn = random.Random(f"{face}{slot}").choice(choices)
    style, stage = divmod(stage, FISH_STAGES)
    icon = icons[f"Item_{name}"]
    if style in GUTTED_STYLES:
        icon = headless_icon(icon, name)
    elif style in HALF_STYLES:
        icon = half_icon(icon, name)
    colour, strength, grains = fish_stage(stage, FRESH_COLD_FISH, DONE_COLD_FISH) if style in COLD_STYLES else fish_stage(stage)
    return stage_icon(hanging_icon(icon, turn, scale), colour, strength, grains, slot * 5 + stage)


def soften_outline(fish):
    """Enlarging a fish thickens its dark outline, so the edge takes the fish's own colour instead."""
    result = fish.copy()
    solid = [fish.getpixel((x, y))[:3] for x in range(fish.width) for y in range(fish.height) if fish.getpixel((x, y))[3] > 200]
    middle = sorted(solid, key=sum)[len(solid) // 2]
    edge = tuple(int(c * OUTLINE_SHADE) for c in middle)
    for (x, y), depth in edge_distances(fish).items():
        pixel = fish.getpixel((x, y))
        if depth <= OUTLINE_DEPTH and sum(pixel[:3]) < sum(edge) * 1.1:
            result.putpixel((x, y), edge + (pixel[3],))
    return result


def body_x(fish):
    """The middle of a hanging fish's body, leaving out its thin fins and tail, for equal margins each side of the hook."""
    distances = edge_distances(fish)
    deepest = max(distances.values())
    body = [x for (x, _), depth in distances.items() if depth >= deepest * 0.5]
    return (min(body) + max(body) + 1) / 2


def front_post_mask(face, half, top, radius):
    """Everything but the post nearest the viewer. Hanging fish are layered over the station, so this keeps them behind it."""
    along = max([-half, half], key=lambda end: rail_point(face, end)[1])
    mask = Image.new("L", (TILE_W * SS, TILE_H * SS), 255)
    ImageDraw.Draw(mask).line(scaled([rail_point(face, along), rail_point(face, along, 0.0, top + 8)]), fill=0, width=int(radius * 2 * SS))
    return mask.resize((TILE_W, TILE_H), Image.LANCZOS)


def paint_hook_fish_tile(icons, face, slot, stage, point, size, scale, post_mask):
    """A fish on a beam's hook, bigger than a frame's, with no twine."""
    tile = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    fish = soften_outline(hanging_fish(icons, face, slot, stage, scale, BEAM_FISH))
    x, y = hook_tip(point, size)
    top = round(y - TAIL_OVER_HOOK * scale)
    # The fish stays where it was, and only the hook moves.
    tile.alpha_composite(fish, (round(x - HOOK_SHIFT * scale - body_x(fish)), top))
    tile = weather(tile, slot * 5 + stage + 190, FISH_WEATHER)
    # The hook goes back on top, a third of the way into the fish.
    hook = new_layer()
    paint_hook(ImageDraw.Draw(hook), point, top + fish.height * HOOK_INTO_FISH)
    tile.alpha_composite(shrink(hook))
    tile.putalpha(ImageChops.multiply(tile.getchannel("A"), post_mask))
    return tile


def recolour_texture(image, colour, amount):
    """Pulls a texture towards one colour, keeping its light and dark."""
    image = image.convert("RGBA")
    grey = image.convert("L")
    channels = [grey.point(lambda value, c=c: min(255, int(c * (0.55 + value / 255 * 0.7)))) for c in colour]
    tinted = Image.merge("RGBA", channels + [image.getchannel("A")])
    return Image.blend(image, tinted, amount)


def stage_icon(icon, colour, amount, grains, seed):
    """A vanilla icon tinted for a stage, with salt grains scattered over the fish."""
    result = recolour_texture(icon, colour, amount)
    rng = random.Random(seed)
    solid = [(x, y) for x in range(result.width) for y in range(result.height) if result.getpixel((x, y))[3] > 200]
    for x, y in rng.sample(solid, min(grains, len(solid))):
        result.putpixel((x, y), SALT_GRAIN)
    return result


def skin_colours(fish):
    """The fish's own colours, dark to light, leaving out its outline."""
    fish = fish.convert("RGBA")
    pixels = sorted((fish.getpixel((x, y)) for x in range(fish.width) for y in range(fish.height) if fish.getpixel((x, y))[3] > 200), key=sum)
    return [pixels[int(len(pixels) * share)][:3] + (255,) for share in (0.3, 0.55, 0.8)]


def paint_scales(image, solid, colours):
    """Scales in a diamond pattern over the given pixels, keeping the image's outline."""
    for x, y in solid:
        image.putpixel((x, y), colours[0] if (x + y) % 4 == 0 or (x - y) % 4 == 0 else colours[1 + (x // 2 + y // 2) % 2])


def largest_part(image):
    """Clears everything but the biggest connected piece, so a cut leaves no stray pixels."""
    seen, best = set(), []
    for start in ((x, y) for x in range(image.width) for y in range(image.height)):
        if start in seen or image.getpixel(start)[3] == 0:
            continue
        part, queue = [], [start]
        seen.add(start)
        while queue:
            x, y = queue.pop()
            part.append((x, y))
            for near in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= near[0] < image.width and 0 <= near[1] < image.height and near not in seen and image.getpixel(near)[3] > 0:
                    seen.add(near)
                    queue.append(near)
        best = max(best, part, key=len)
    keep = set(best)
    for x in range(image.width):
        for y in range(image.height):
            if (x, y) not in keep:
                image.putpixel((x, y), (0, 0, 0, 0))


def beyond_cut(image, cut):
    """The pixels joined to a point on one side of a cut: two points on the line, then the point."""
    x1, y1, x2, y2, start_x, start_y = cut
    length = math.hypot(x2 - x1, y2 - y1)

    def distance(x, y):
        return ((x2 - x1) * (y - y1) - (y2 - y1) * (x - x1)) / length

    side = 1 if distance(start_x, start_y) > 0 else -1
    found, queue = {(start_x, start_y)}, [(start_x, start_y)]
    while queue:
        x, y = queue.pop()
        for near in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if near not in found and 0 <= near[0] < image.width and 0 <= near[1] < image.height \
                    and image.getpixel(near)[3] > 0 and distance(*near) * side > 0:
                found.add(near)
                queue.append(near)
    return found


def headless_icon(icon, name):
    """A vanilla fish with its head cut off and the flesh showing at the cut. Fish with no head stay as they are."""
    result = icon.convert("RGBA").copy()
    if name not in HEAD_CUTS:
        return result
    # Spreading from the head up to the cut leaves alone a tail curling round to the same side.
    head = beyond_cut(result, HEAD_CUTS[name])
    for x, y in head:
        result.putpixel((x, y), (0, 0, 0, 0))
    for x in range(result.width):
        for y in range(result.height):
            beside_head = any((x + dx, y + dy) in head for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2))
            if beside_head and (x, y) not in head and result.getpixel((x, y))[3] > 200:
                result.putpixel((x, y), FLESH)
    largest_part(result)
    return result


def shade_head_cut(art):
    """Gives the cut face depth: a dark rim where it meets the air, red meat inside that, paler flesh and a
    bone at the middle, and a dark gill-cover line where the skin meets the cut."""
    flesh = {(x, y) for x in range(art.width) for y in range(art.height) if art.getpixel((x, y)) == FLESH}
    skin = {(x, y) for x in range(art.width) for y in range(art.height) if art.getpixel((x, y))[3] > 0} - flesh
    def near(x, y):
        return ((x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy)
    rim = {pixel for pixel in flesh if any(other not in flesh and other not in skin for other in near(*pixel))}
    meat = {pixel for pixel in flesh - rim if any(other in rim for other in near(*pixel))}
    for pixel in skin:
        if any(other in flesh for other in near(*pixel)):
            art.putpixel(pixel, tuple(int(c * HEAD_GILL_SHADE) for c in art.getpixel(pixel)[:3]) + (255,))
    for pixel in rim:
        art.putpixel(pixel, HEAD_CUT_RIM)
    for pixel in meat:
        art.putpixel(pixel, HEAD_CUT_MEAT)
    inner = sorted(flesh - rim - meat)
    if inner:
        cx = sum(x for x, _ in inner) / len(inner)
        cy = sum(y for _, y in inner) / len(inner)
        bone = min(inner, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
        art.putpixel(bone, HEAD_CUT_BONE)


def head_icon(icon, name):
    """The head a Gutted Fish loses, with the flesh showing at the cut."""
    source = icon.convert("RGBA")
    head = beyond_cut(source, HEAD_CUTS[name])
    result = Image.new("RGBA", source.size, (0, 0, 0, 0))
    for x, y in head:
        beside_body = any((x + dx, y + dy) not in head and 0 <= x + dx < source.width and 0 <= y + dy < source.height
                          and source.getpixel((x + dx, y + dy))[3] > 200 for dx in (-1, 0, 1) for dy in (-1, 0, 1))
        result.putpixel((x, y), FLESH if beside_body and source.getpixel((x, y))[3] > 200 else source.getpixel((x, y)))
    largest_part(result)
    # Centred, and doubled when that still fits, as a head alone is small for an icon.
    art = result.crop(result.getbbox())
    if max(art.size) * 2 <= HEAD_ICON_FIT:
        art = art.resize((art.width * 2, art.height * 2), Image.NEAREST)
    shade_head_cut(art)
    centred = Image.new("RGBA", source.size, (0, 0, 0, 0))
    centred.alpha_composite(art, ((source.width - art.width) // 2, (source.height - art.height) // 2))
    return centred


def edge_distances(image):
    """How many pixels each solid pixel is from the edge of the art."""
    solid = {(x, y) for x in range(image.width) for y in range(image.height) if image.getpixel((x, y))[3] > 200}
    distances, ring, depth = {}, solid, 0
    while ring:
        depth += 1
        inner = {(x, y) for x, y in ring if all(near in ring for near in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))}
        distances.update({pixel: depth for pixel in ring - inner})
        ring = inner
    return distances


def half_icon(icon, name):
    """A headless fish split open: red flesh and a backbone down the body, its fins, tail and edge left as they are."""
    result = headless_icon(icon, name)
    distances = edge_distances(result)
    # The thick middle of the fish, grown back out, leaves the thin fins and tail out of it.
    core_depth = max(HALF_ICON_SKIN + 1, round(max(distances.values()) * 0.6))
    core = [pixel for pixel, depth in distances.items() if depth >= core_depth]
    reach = core_depth - HALF_ICON_SKIN + 1
    body = {(x, y) for (x, y), depth in distances.items() if depth >= HALF_ICON_SKIN
            and any(abs(x - cx) + abs(y - cy) <= reach for cx, cy in core)}
    for cut in SKIN_CUTS.get(name, ()):
        body -= beyond_cut(result, cut)
    for x, y in body:
        light = 0.8 + sum(result.getpixel((x, y))[:3]) / 765 * 0.4
        result.putpixel((x, y), tuple(min(255, int(c * light)) for c in HALF_FLESH) + (255,))
    for (x, y) in body.intersection(core):
        neighbours = [distances.get((x + dx, y + dy), 0) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
        if distances[(x, y)] >= max(neighbours) and (x + y) % 3:
            result.putpixel((x, y), SPINE)
    return result


def half_model_texture(fillet, fish):
    """The fillet's texture with redder flesh and that fish's skin around it, so the edges and back show scales."""
    result = recolour_texture(fillet, HALF_FLESH, 0.55)
    width, height = result.size
    skin = [(x, y) for x in range(width) for y in range(height)
            if ((x - width / 2) / (width * HALF_FLESH_WIDTH)) ** 2 + ((y - height * 0.38) / (height * HALF_FLESH_HEIGHT)) ** 2 > 1]
    paint_scales(result, skin, skin_colours(fish))
    return result


def body_pixels(texture):
    """The fish's body in its texture, as (x, y, how far down, how far across) for each pixel."""
    width, height = texture.size
    for x in range(width):
        for y in range(height):
            across, down = x / width, y / height
            if ((across - 0.5) / 0.3) ** 2 + ((down - 0.4) / 0.4) ** 2 < 1:
                yield x, y, down, across


def blend(pixel, colour, amount):
    return tuple(int(a + (b - a) * amount) for a, b in zip(pixel[:3], colour[:3])) + (255,)


def gutted_texture(texture, seed):
    """Pink along the belly where it was opened, and a head flecked with red where it came off."""
    result = texture.convert("RGBA").copy()
    rng = random.Random(seed)
    for x, y, down, across in body_pixels(result):
        if down < 0.2:
            result.putpixel((x, y), blend(result.getpixel((x, y)), HEAD_RED, 0.85) if rng.random() < 0.35 else blend(result.getpixel((x, y)), FLESH, 0.75))
        elif across < 0.44 and down < 0.68:
            result.putpixel((x, y), blend(result.getpixel((x, y)), FLESH, 0.85))
    return result


def vanilla_ground_models(game):
    """The ground model block of each fish, by icon name."""
    items = (game / "media/scripts/generated/items/food.txt").read_text()
    models = (game / "media/scripts/generated/models_fish.txt").read_text()
    blocks = {}
    for icon, item in FISH_ITEMS.items():
        body = re.search(rf"\n    item {item}\n    \{{(.*?)\n    \}}", items, re.S).group(1)
        name = re.search(r"WorldStaticModel = (\w+)", body).group(1)
        blocks[icon] = re.search(rf"    model {name}\n    \{{.*?\n    \}}\n", models, re.S).group(0)
    return blocks


def write_fish_models(media, game):
    """A repainted model for each species at each stage, picked by each item's WorldStaticModelsByIndex. Halves use the fillet mesh."""
    folder = media / "textures" / "FishModels"
    folder.mkdir(exist_ok=True)
    icons = read_icons(game)
    fillet = Image.open(game / "media/textures/WorldItems/FishFillet.png")
    blocks = vanilla_ground_models(game)
    lines = ["/* Written by tools/build_tileset.py. */", "module TraditionalPreservationFishMeat", "{"]
    for index, (icon, block) in enumerate(blocks.items()):
        path = re.search(r"texture = (\S+?),", block).group(1)
        source = Image.open(game / f"media/textures/{path}.png").convert("RGBA")
        gutted = gutted_texture(source, index)
        textures = {prefix: recolour_texture(source, colour, amount) for prefix, (colour, amount) in MODEL_PREFIXES.items()}
        textures["Cold"] = recolour_texture(gutted, *MODEL_PREFIXES["Cold"])
        textures["SoakedCold"] = recolour_texture(gutted, *MODEL_PREFIXES["SoakedCold"])
        textures["Gutted"] = gutted
        for prefix in SALT_MODEL_PREFIXES:
            textures[prefix + "Gutted"] = recolour_texture(gutted, *MODEL_PREFIXES[prefix])
        for prefix, texture in textures.items():
            texture.save(folder / f"{prefix}_{icon}.png")
            model = re.sub(r"model \w+", f"model {prefix}_{icon}", block, count=1)
            lines.append(re.sub(r"texture = \S+?,", f"texture = FishModels/{prefix}_{icon},", model, count=1).rstrip())
        half = half_model_texture(fillet, icons[f"Item_{icon}"])
        halves = {"Half": half}
        for prefix, tint_values in MODEL_PREFIXES.items():
            halves[prefix + "Half"] = recolour_texture(half, *tint_values)
        for prefix, texture in halves.items():
            texture.save(folder / f"{prefix}_{icon}.png")
            lines += [f"    model {prefix}_{icon}", "    {", "        mesh = WorldItems/FishFillet,", f"        texture = FishModels/{prefix}_{icon},", f"        scale = {HALF_MODEL_SCALE},", "    }"]
    lines.append("}")
    (media / "scripts" / f"{NAME_TITLE}_models.txt").write_text("\n".join(lines) + "\n")


def read_icons(game):
    packs = game / "media/texturepacks"
    icons = pzart.extract_sprites(packs / "UI2.pack", {f"Item_{icon}" for icon in FISH_ICONS if icon not in OLD_PACK_ICONS} | {"Item_Boulder"})
    for icon in OLD_PACK_ICONS:
        icons[f"Item_{icon}"] = pzart.extract_old_sprite(packs / "UI.pack", f"Item_{icon}")
    icons.update(pzart.extract_sprites(packs / "UI2.pack", {f"Item_{name}" for name, _ in HANGING_MEAT if name not in OLD_PACK_MEAT}))
    for name in OLD_PACK_MEAT:
        icons[f"Item_{name}"] = pzart.extract_old_sprite(packs / "UI.pack", f"Item_{name}")
    return icons


def write_textures(folder, game):
    icons = read_icons(game)
    for name, (colour, amount, grains) in STAGES.items():
        source = headless_icon(icons["Item_Fish_Walleye"], "Fish_Walleye") if "Cold" in name else icons["Item_Fish_Walleye"]
        stage_icon(source, colour, amount, grains, len(name)).save(folder / f"Item_{name}.png")
    for index, icon in enumerate(FISH_ICONS):
        for prefix, colour, amount, grains in ICON_STAGES:
            source = headless_icon(icons[f"Item_{icon}"], icon) if "Cold" in prefix else icons[f"Item_{icon}"]
            stage_icon(source, colour, amount, grains, index).save(folder / f"Item_{prefix}_{icon}.png")
        for prefix, colour, amount, grains in ICON_STAGES + [("Packed",) + STAGES["SaltPackedFish"]]:
            for variant, source in (("Gutted", headless_icon(icons[f"Item_{icon}"], icon)), ("Half", half_icon(icons[f"Item_{icon}"], icon))):
                stage_icon(source, colour, amount, grains, index).save(folder / f"Item_{prefix}{variant}_{icon}.png")
    for icon in FISH_ICONS:
        half_icon(icons[f"Item_{icon}"], icon).save(folder / f"Item_Half_{icon}.png")
        headless_icon(icons[f"Item_{icon}"], icon).save(folder / f"Item_Gutted_{icon}.png")
    # One head for every species, the bass's as it reads best. It has no ground model, so it lies as its icon.
    head_icon(icons["Item_Fish_BassLargemouth"], "Fish_BassLargemouth").save(folder / "Item_FishHead.png")
    headless_icon(icons["Item_Fish_Walleye"], "Fish_Walleye").save(folder / "Item_GuttedFish.png")
    half_icon(icons["Item_Fish_Walleye"], "Fish_Walleye").save(folder / "Item_FishHalf.png")
    fillet = Image.open(game / "media/textures/WorldItems/FishFillet.png")
    half_model_texture(fillet, icons["Item_Fish_Walleye"]).save(folder / "FishHalfModel.png")
    for name, (colour, amount) in MODEL_TINTS.items():
        recolour_texture(fillet, colour, amount).save(folder / f"{name}.png")


def tile_name(index):
    if index < FIRST_SHEET_SIZE:
        return f"{TILESETS[0]}_{index}"
    return f"{TILESETS[1]}_{index - FIRST_SHEET_SIZE}"


def stack_fish(icons, name, seed):
    """A gutted stockfish lying flat, neck down the image, sized for the floor canvas of stack_layer."""
    icon = headless_icon(icons[f"Item_{name}"], name)
    big = icon.resize((icon.width * 8, icon.height * 8), Image.NEAREST)
    upright = big.rotate(long_axis(icon) + 90, resample=Image.BICUBIC, expand=True)
    upright = upright.crop(upright.getbbox())
    colour, strength, grains = fish_stage(FISH_STAGES - 1, FRESH_COLD_FISH, DONE_COLD_FISH)
    return stage_icon(upright, colour, strength, grains, seed)


def stack_layer(icons, layer, canvas):
    """One layer of the stack on a flat canvas of the floor (canvas pixels a tile): two rows of fish, necks out and
    tails overlapping in the middle, turned a quarter each layer as real stacks are laid."""
    floor = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    rng = random.Random(f"stack{layer}")
    for side in (-1, 1):
        for across in STACK_ROW:
            fish = stack_fish(icons, rng.choice(STACK_FISH), layer * 11 + int(across * 100) + side)
            scale = STACK_FISH_LENGTH * canvas / fish.height
            fish = fish.resize((max(1, round(fish.width * scale)), max(1, round(fish.height * scale))), Image.LANCZOS)
            # Upright the neck points down the image (+y); turn it to point out along +x or -x, or +y or -y.
            along_x = layer % 2 == 0
            angle = (90 if side > 0 else -90) if along_x else (0 if side > 0 else 180)
            fish = fish.rotate(angle + rng.uniform(-6, 6), resample=Image.BICUBIC, expand=True)
            out = side * (STACK_HALF - STACK_FISH_LENGTH / 2) + rng.uniform(-0.02, 0.02)
            spread = across + rng.uniform(-0.03, 0.03)
            x, y = (out, spread) if along_x else (spread, out)
            floor.alpha_composite(fish, (round((x + 0.5) * canvas - fish.width / 2), round((y + 0.5) * canvas - fish.height / 2)))
    return floor


def to_tile(floor, z):
    """Lays a floor canvas (x and y from -0.5 to 0.5 tile) onto the supersampled tile, z pixels up."""
    canvas = floor.width
    f0, f1 = FOOT[0] * SS, (FOOT[1] - z) * SS
    hw, hh = pzart.DIAMOND_HALF_W * SS, pzart.DIAMOND_HALF_H * SS
    # u = (x + 0.5) canvas, with x - y = (X - f0) / hw and x + y = (Y - f1) / hh.
    a, b = canvas / (2 * hw), canvas / (2 * hh)
    coefficients = (a, b, canvas / 2 - a * f0 - b * f1, -a, b, canvas / 2 + a * f0 - b * f1)
    return floor.transform((TILE_W * SS, TILE_H * SS), Image.AFFINE, coefficients, resample=Image.BICUBIC)


def shaded(layer, amount):
    rgb = layer.convert("RGB").point(lambda v: int(v * amount))
    result = rgb.convert("RGBA")
    result.putalpha(layer.getchannel("A"))
    return result


def paint_pallet_stack(icons, layers):
    tile = new_layer()
    for layer in range(layers):
        floor = to_tile(stack_layer(icons, layer, 512), PALLET_TOP_Z + layer * STACK_LAYER_Z)
        light = STACK_BOTTOM_LIGHT + (1 - STACK_BOTTOM_LIGHT) * layer / max(1, PALLET_LEVELS[-1] - 1)
        # The layer's edge, a little below it, then the layer itself.
        edge = floor.transform(floor.size, Image.AFFINE, (1, 0, 0, 0, 1, -STACK_LAYER_Z * SS * 0.6))
        tile.alpha_composite(shaded(edge, STACK_SHADE * light))
        tile.alpha_composite(shaded(floor, light))
    return pzart.hard_edges(shrink(tile))


# --- The Smokehouse chamber ----------------------------------------------------------------------------------
# A plank hut two tiles long under one roof slope, high over the door on the front end. Drawn in the shed's own coordinates: a across
# it (+a the visible long side), b along it (+b the door's end); the front tile's middle is b = 0, the back tile's
# b = -1. Each tile paints only its half, so the two meet on screen.

def chamber_world(face, a, b):
    """World x, y of a shed point: facing S the door looks south (+y), facing E east (+x)."""
    return (a, b) if face == "S" else (b, a)


def chamber_px(face, part, a, b, z):
    """A shed point on the tile of that part (0 back, 1 front), supersampled."""
    x, y = chamber_world(face, a, b + (1 - part))
    sx, sy = project(x, y, z)
    return (sx * SS, sy * SS)


def chamber_planks(draw, rng, quad, start, stop, width, colour, light, clip=None):
    """Planks from start to stop along a wall or roof; quad(u0, u1) gives each one's polygon, each a tone of its own
    with a dark seam between. clip (u0, u1) paints only that stretch: the planks are laid from start all the same,
    so a run over both tiles matches where they meet."""
    low, high = clip or (start, stop)
    u = start
    while u < stop - 1e-6:
        u1 = min(u + width * rng.uniform(0.85, 1.15), stop)
        tone = rng.uniform(0.86, 1.1)
        if max(u, low) < min(u1, high):
            draw.polygon(quad(max(u, low), min(u1, high)), fill=tint(colour, light * tone))
        if low < u1 < min(stop, high) - 1e-6:
            draw.polygon(quad(u1 - 0.006, u1 + 0.006), fill=tint(BOARD_EDGE, light * 0.8))
        u = u1


def paint_chamber(face, part):
    rng = random.Random(200 + 2 * FACES.index(face) + part)
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    h, o = CHAMBER_HALF, CHAMBER_OVERHANG
    # This tile's stretch of the shed along b, and its walls' lights by the way the world face looks.
    b0, b1 = (-1 - h, -0.5 + JOIN) if part == 0 else (-0.5, h)
    door_light, side_light = (1.0, 0.72) if face == "S" else (0.72, 1.0)
    back, front = -1 - h - o, h + o

    def px(a, b, z):
        return chamber_px(face, part, a, b, z)

    def roof_z(b):
        """One slope, high over the door's end and falling to the back."""
        return CHAMBER_BACK + (CHAMBER_FRONT - CHAMBER_BACK) * (b - back) / (front - back)

    # The visible long side, its top following the roof, then the stone sill and two battens along it.
    side = lambda u0, u1: [px(h, u0, 0), px(h, u1, 0), px(h, u1, roof_z(u1) - 2), px(h, u0, roof_z(u0) - 2)]
    chamber_planks(draw, random.Random(210 + FACES.index(face)), side, -1 - h, h, CHAMBER_PLANK, CHAMBER_WOOD, side_light, (b0, b1))
    draw.polygon([px(h, b0, 0), px(h, b1, 0), px(h, b1, CHAMBER_SILL), px(h, b0, CHAMBER_SILL)], fill=tint(CHAMBER_STONE, side_light * 0.8))
    for z in (CHAMBER_SILL + 4, CHAMBER_BACK - 12):
        draw.polygon([px(h + 0.004, b0, z), px(h + 0.004, b1, z), px(h + 0.004, b1, z + 4), px(h + 0.004, b0, z + 4)],
                     fill=tint(CHAMBER_WOOD, side_light * 0.78))

    if part == 1:
        # The door's end: planks up to the high eave, the smoke slot under it with two slats, a sill and the door.
        top = roof_z(h) - 2
        end = lambda u0, u1: [px(u0, h, 0), px(u1, h, 0), px(u1, h, top), px(u0, h, top)]
        chamber_planks(draw, random.Random(220 + FACES.index(face)), end, -h, h, CHAMBER_PLANK, CHAMBER_WOOD, door_light)
        slot_low, slot_high = top - 14, top - 3
        draw.polygon([px(-h + 0.05, h, slot_low), px(h - 0.05, h, slot_low), px(h - 0.05, h, slot_high), px(-h + 0.05, h, slot_high)],
                     fill=tint(CHAMBER_DARK, 1))
        for z in (slot_low + 3, slot_low + 7):
            draw.polygon([px(-h + 0.05, h + 0.004, z), px(h - 0.05, h + 0.004, z), px(h - 0.05, h + 0.004, z + 2), px(-h + 0.05, h + 0.004, z + 2)],
                         fill=tint(CHAMBER_WOOD, door_light * 0.7))
        draw.polygon([px(-h, h, 0), px(h, h, 0), px(h, h, CHAMBER_SILL), px(-h, h, CHAMBER_SILL)], fill=tint(CHAMBER_STONE, door_light * 0.8))
        # The door: darker boards in a frame, two ledges and a brace, strap hinges on its left and a wooden latch.
        d = CHAMBER_DOOR_HALF
        draw.polygon([px(-d - 0.03, h + 0.003, CHAMBER_SILL), px(d + 0.03, h + 0.003, CHAMBER_SILL),
                      px(d + 0.03, h + 0.003, CHAMBER_DOOR + 4), px(-d - 0.03, h + 0.003, CHAMBER_DOOR + 4)], fill=tint(BOARD_EDGE, door_light))
        door = lambda u0, u1: [px(u0, h + 0.006, CHAMBER_SILL + 1), px(u1, h + 0.006, CHAMBER_SILL + 1),
                               px(u1, h + 0.006, CHAMBER_DOOR), px(u0, h + 0.006, CHAMBER_DOOR)]
        chamber_planks(draw, random.Random(230 + FACES.index(face)), door, -d, d, CHAMBER_PLANK * 0.8, CHAMBER_WOOD, door_light * 0.82)
        for z0 in (CHAMBER_SILL + 12, CHAMBER_DOOR - 16):
            draw.polygon([px(-d, h + 0.008, z0), px(d, h + 0.008, z0), px(d, h + 0.008, z0 + 6), px(-d, h + 0.008, z0 + 6)],
                         fill=tint(CHAMBER_WOOD, door_light * 0.68))
        draw.polygon([px(-d, h + 0.008, CHAMBER_SILL + 18), px(-d + 0.05, h + 0.008, CHAMBER_SILL + 18),
                      px(d, h + 0.008, CHAMBER_DOOR - 16), px(d - 0.05, h + 0.008, CHAMBER_DOOR - 16)], fill=tint(CHAMBER_WOOD, door_light * 0.72))
        for z0 in (CHAMBER_SILL + 13, CHAMBER_DOOR - 15):
            draw.polygon([px(-d - 0.02, h + 0.01, z0), px(-d + 0.13, h + 0.01, z0 + 1), px(-d + 0.13, h + 0.01, z0 + 3),
                          px(-d - 0.02, h + 0.01, z0 + 4)], fill=tint(IRON, 1.0))
        latch = CHAMBER_DOOR * 0.55
        draw.polygon([px(d - 0.06, h + 0.01, latch), px(d + 0.02, h + 0.01, latch), px(d + 0.02, h + 0.01, latch + 3),
                      px(d - 0.06, h + 0.01, latch + 3)], fill=tint(CHAMBER_WOOD, door_light * 0.6))

    # The roof: boards running down the slope, laid across the shed, over the walls and past them; a fascia board
    # on the high front edge and along the visible side.
    low, high = b0 - (o if part == 0 else 0), b1 + (o if part == 1 else 0)
    if part == 1:
        high = front
    roof = lambda u0, u1: [px(u0, low, roof_z(low)), px(u1, low, roof_z(low)), px(u1, high, roof_z(high)), px(u0, high, roof_z(high))]
    chamber_planks(draw, random.Random(240 + FACES.index(face) + 4 * part), roof, -h - o, h + o, CHAMBER_PLANK, CHAMBER_ROOF, 1.0)
    draw.polygon([px(h + o, low, roof_z(low)), px(h + o, high, roof_z(high)), px(h + o, high, roof_z(high) - 5), px(h + o, low, roof_z(low) - 5)],
                 fill=tint(BOARD_EDGE, side_light * 0.9))
    if part == 1:
        draw.polygon([px(-h - o, front, roof_z(front)), px(h + o, front, roof_z(front)), px(h + o, front, roof_z(front) - 5),
                      px(-h - o, front, roof_z(front) - 5)], fill=tint(BOARD_EDGE, door_light * 0.9))

    layer = pzart.darken_down(layer, FOOT[1] - 60, FOOT[1] + 30, FRAME_FOOT_SHADE, SS)
    return pzart.hard_edges(weather(shrink(layer), 250 + 2 * FACES.index(face) + part, WOOD_WEATHER, streaks=True).convert("RGBA"))


def paint_chamber_entry(kind, face, part):
    """Where the flue enters the visible long side, at this tile's middle: a clay pipe's last stub through a collar
    of clay on the planks, or the stone-roofed trench running in under the sill through a dark gap."""
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    h, mid = CHAMBER_HALF, part - 1
    light = 0.72 if face == "S" else 1.0

    def px(a, b, z):
        return chamber_px(face, part, a, b, z)

    def wall(b0, b1, z0, z1):
        return [px(h, mid + b0, z0), px(h, mid + b1, z0), px(h, mid + b1, z1), px(h, mid + b0, z1)]

    if kind == "Pipe":
        draw.polygon(wall(-0.075, 0.075, FLUE_Z - 8, FLUE_Z + 9), fill=tint(FLUE_DAUB, light * 0.95))
        draw.polygon(wall(-0.06, 0.06, FLUE_Z - 6, FLUE_Z + 7), fill=tint(FLUE_DAUB, light * 1.08))
        steps = 8
        for i in range(steps + 1):
            a = h + (0.5 - h) * i / steps
            x, y = px(a, mid, FLUE_Z)
            r = FLUE_R + (0.8 if i == 0 else 0)
            draw.ellipse([x - r * SS, y - r * 0.85 * SS, x + r * SS, y + r * 0.85 * SS], fill=tint(FLUE_CLAY, 0.78))
            draw.ellipse([x - (r - 1.6) * SS, y - (r - 0.6) * 0.85 * SS, x + (r - 2.6) * SS, y + (r - 2.4) * 0.85 * SS],
                         fill=tint(FLUE_CLAY, 1.16))
    else:
        w = TRENCH_W
        draw.polygon(wall(-w - 0.03, w + 0.03, 0, CHAMBER_SILL + 2), fill=tint(FLUE_DAUB, light * 0.9))
        draw.polygon(wall(-w + 0.01, w - 0.01, 0, 3), fill=tint(CHAMBER_DARK, 1))
        draw.polygon(wall(-w - 0.02, w + 0.02, 3, CHAMBER_SILL + 1), fill=tint(CHAMBER_STONE, light * 1.05))

        def ground(a, across, z):
            return px(a, mid + across, z)

        a0, a1 = h, 0.5
        draw.polygon([ground(a0, -w - 0.03, 0), ground(a1, -w - 0.03, 0), ground(a1, w + 0.03, 0), ground(a0, w + 0.03, 0)],
                     fill=tint(FLUE_DAUB, 0.7))
        draw.polygon([ground(a0, -w - 0.02, 2.2), ground(a1, -w - 0.02, 2.2), ground(a1, w + 0.02, 2.2), ground(a0, w + 0.02, 2.2)],
                     fill=tint(FLUE_DAUB, 0.95))
        draw.polygon([ground(a0 + 0.004, -w, 2.8), ground(a1, -w, 3.0), ground(a1, w, 3.0), ground(a0 + 0.004, w, 2.8)],
                     fill=tint(CHAMBER_STONE, 1.1))
    return pzart.hard_edges(shrink(layer).convert("RGBA"))


def paint_chamber_ham(face):
    """A smoked ham on a cord from a nail on the door's end wall: the shank up, the round of it at the bottom, a lighter
    face where the light falls and the bone's knob at the top."""
    layer = new_layer()
    draw = ImageDraw.Draw(layer)
    h, a = CHAMBER_HALF, HAM_A
    light = 1.0 if face == "S" else 0.72

    def px(da, z, out=0.012):
        return chamber_px(face, 1, a + da, h + out, z)

    nail = HAM_TOP + 9
    draw.line([px(0, nail), px(0, HAM_TOP)], fill=tint(HAM_CORD, light), width=SS)
    draw.ellipse([px(0, nail)[0] - 1.2 * SS, px(0, nail)[1] - 1.2 * SS, px(0, nail)[0] + 1.2 * SS, px(0, nail)[1] + 1.2 * SS],
                 fill=tint(IRON, 1.0))
    # Half-widths (in tiles) down the ham, from the shank to the round bottom.
    zs = [HAM_TOP - 2 - 5 * i for i in range(9)] + [HAM_TOP - 44]
    ws = [0.02, 0.026, 0.042, 0.07, 0.092, 0.102, 0.1, 0.088, 0.06, 0.028]
    outline = [px(-w, z) for z, w in zip(zs, ws)] + [px(w, z) for z, w in reversed(list(zip(zs, ws)))]
    draw.polygon(outline, fill=tint(HAM_COLOUR, light * 0.78))
    inner = [px(-w * 0.7 - 0.006, z) for z, w in zip(zs[2:-1], ws[2:-1])] + [px(w * 0.45, z) for z, w in reversed(list(zip(zs[2:-1], ws[2:-1])))]
    draw.polygon(inner, fill=tint(HAM_COLOUR, light * 1.08))
    knob = px(0, HAM_TOP)
    draw.ellipse([knob[0] - 2 * SS, knob[1] - 1.6 * SS, knob[0] + 2 * SS, knob[1] + 1.6 * SS], fill=tint(HAM_BONE, light))
    return pzart.hard_edges(shrink(layer).convert("RGBA"))


def chamber_icon(tiles, face_index=0):
    """Both halves of the chamber as they stand, the back one drawn first, for the build menu."""
    face = FACES[face_index]
    dx, dy = chamber_world(face, 0, -1)
    sx, sy = round((dx - dy) * pzart.DIAMOND_HALF_W), round((dx + dy) * pzart.DIAMOND_HALF_H)
    canvas = Image.new("RGBA", (TILE_W + abs(sx), TILE_H + abs(sy)), (0, 0, 0, 0))
    ox, oy = max(0, -sx), max(0, -sy)
    canvas.alpha_composite(tiles[chamber_index(face_index, 0)], (ox + sx, oy + sy))
    canvas.alpha_composite(tiles[chamber_index(face_index, 1)], (ox, oy))
    return canvas


def build_tiles(game=GAME):
    icons = read_icons(game)
    tiles = {}
    for index, face in enumerate(FACES):
        tiles[TUB + index] = paint_tub(40 + index)
        tiles[TUB_FILLED + index] = weather(shrink(salt_layer(50 + index, fish=True)), 50 + index, SALT_WEATHER)
        tiles[TUB_WEIGHTED + index] = weather(shrink(paint_weighted(50 + index, face == "E", icons["Item_Boulder"].convert("RGBA"))), 60 + index, WOOD_WEATHER)
        tiles[FRAME + index] = paint_frame(face)
        for slot in range(len(SLOTS)):
            for stage in range(FISH_STAGES * FISH_STYLES):
                tiles[fish_index(index, slot, stage)] = paint_fish_tile(icons, face, slot, stage)
            for stage in range(FISH_STAGES):
                meat = FISH_STAGES * FISH_STYLES + stage
                tiles[fish_index(index, slot, stage, FRAME_MEAT)] = paint_fish_tile(icons, face, slot, meat)
        tiles[MEDIUM_BEAM + index] = paint_medium_beam(face)
        tiles[LARGE_BEAM + index] = paint_large_beam(face)
        medium_mask = front_post_mask(face, MEDIUM_HALF_LENGTH, MEDIUM_BEAM_Z, POST_RADIUS)
        large_mask = front_post_mask(face, LARGE_HALF_LENGTH, LARGE_BEAM_Z, LARGE_POST_RADIUS)
        for first, hooks, size, scale, mask in ((MEDIUM_FISH, medium_hooks(face), MEDIUM_HOOK_SIZE, MEDIUM_FISH_SCALE, medium_mask), (LARGE_FISH, large_hooks(face), LARGE_HOOK_SIZE, LARGE_FISH_SCALE, large_mask)):
            for slot, point in enumerate(hooks):
                for stage in range(FISH_STAGES * FISH_STYLES):
                    tiles[fish_index(index, slot, stage, first, len(hooks))] = paint_hook_fish_tile(icons, face, slot, stage, point, size, scale, mask)
        for first, meat_first, hooks, size, scale, mask in ((MEDIUM_FISH, MEDIUM_MEAT, medium_hooks(face), MEDIUM_HOOK_SIZE, MEDIUM_FISH_SCALE, medium_mask),
                                                            (LARGE_FISH, LARGE_MEAT, large_hooks(face), LARGE_HOOK_SIZE, LARGE_FISH_SCALE, large_mask)):
            for slot, point in enumerate(hooks):
                for stage in range(FISH_STAGES):
                    meat = FISH_STAGES * FISH_STYLES + stage
                    tiles[fish_index(index, slot, stage, meat_first, len(hooks))] = paint_hook_fish_tile(icons, face, slot, meat, point, size, scale, mask)
    for face_index, face in enumerate(FACES):
        for part in range(2):
            tiles[chamber_index(face_index, part)] = paint_chamber(face, part)
            for kind in FLUE_KINDS:
                tiles[chamber_entry_index(kind, face_index, part)] = paint_chamber_entry(kind, face, part)
        tiles[CHAMBER_HAM + face_index] = paint_chamber_ham(face)
    tiles[PALLET] = pzart.extract_sprites(game / "media/texturepacks/Tiles2x.pack", {PALLET_SPRITE})[PALLET_SPRITE]
    for level, layers in enumerate(PALLET_LEVELS):
        tiles[PALLET_STACK + level] = paint_pallet_stack(icons, layers)
    return tiles


def lua_tiles():
    chamber = [tile_name(chamber_index(face, part)) for face in range(len(FACES)) for part in range(2)]
    stations = [tile_name(base + face) for base in (TUB, FRAME, MEDIUM_BEAM, LARGE_BEAM) for face in range(len(FACES))] + chamber
    beams = [tile_name(base + face) for base in (MEDIUM_BEAM, LARGE_BEAM) for face in range(len(FACES))] + chamber
    return {
        "SHEETS": [{"prefix": tileset + "_", "tiles": COLUMNS * rows} for tileset, rows in zip(TILESETS, SHEET_ROWS)],
        "FIRST_SHEET_SIZE": FIRST_SHEET_SIZE,
        "FACE_COUNT": len(FACES),
        "STATIONS": stations,
        "OUTDOOR": {name: True for name in beams},
        "TUB": TUB,
        "TUB_FILLED": TUB_FILLED,
        "TUB_WEIGHTED": TUB_WEIGHTED,
        "FRAME": FRAME,
        # Every station that hangs fish: its first sprite, its first hanging fish sprite and its stacks.
        "HANGERS": {
            "frame": {"base": FRAME, "fishSprite": FISH, "meatSprite": FRAME_MEAT, "stacks": len(SLOTS)},
            "medium": {"base": MEDIUM_BEAM, "fishSprite": MEDIUM_FISH, "meatSprite": MEDIUM_MEAT, "stacks": MEDIUM_HOOKS},
            "large": {"base": LARGE_BEAM, "fishSprite": LARGE_FISH, "meatSprite": LARGE_MEAT, "stacks": LARGE_HOOKS},
            # Closed: nothing hangs in sight. Its facings are two tiles apart, so it lists both firsts.
            "chamber": {"base": CHAMBER, "bases": [chamber_index(face, 0) for face in range(len(FACES))], "stacks": CHAMBER_STACKS,
                        "closed": True},
        },
        # Where a joined Firebox's flue enters the chamber: Pipe then Stones, each face, each part.
        "CHAMBER_ENTRY": CHAMBER_ENTRY,
        # The ham by the door while finished stacks wait inside: one per face, on the door's tile.
        "CHAMBER_HAM": CHAMBER_HAM,
        "PALLET": tile_name(PALLET),
        "PALLET_STACKS": [tile_name(PALLET_STACK + level) for level in range(len(PALLET_LEVELS))],
        "DRYING_STAGES": FISH_STAGES,
        "STYLES": dict({name: style for style, name in enumerate(STYLE_NAMES)}, MEAT=MEAT_STYLE),
    }


def main():
    game = Path(sys.argv[1]) if len(sys.argv) > 1 else GAME
    media = Path(__file__).resolve().parent.parent / "42" / "media"
    pzart.write_lua_tiles(media, "TraditionalPreservationFishMeat", lua_tiles(), "tools/build_tileset.py")
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)
    (media / "textures").mkdir(parents=True, exist_ok=True)

    tiles = build_tiles(game)
    pzart.write_pack(media / "texturepacks" / f"{NAME}.pack", tiles, NAME, tile_name, PAGE_SIZE)
    pzart.write_tiles(media / f"{NAME}.tiles", [(tileset, COLUMNS, rows) for tileset, rows in zip(TILESETS, SHEET_ROWS)], TILE_PROPS)
    write_textures(media / "textures", game)
    write_fish_models(media, game)

    tub = tiles[TUB].copy()
    tub.alpha_composite(tiles[TUB_WEIGHTED])
    pzart.write_build_icon(tub, media / "textures" / "Item_SaltingTub.png")
    frame = tiles[FRAME].copy()
    for slot in range(len(SLOTS)):
        frame.alpha_composite(tiles[fish_index(0, slot, FISH_STAGES - 1)])
    pzart.write_build_icon(frame, media / "textures" / "Item_DryingFrame.png")
    for name, beam, first, hooks in (("Medium", MEDIUM_BEAM, MEDIUM_FISH, MEDIUM_HOOKS), ("Large", LARGE_BEAM, LARGE_FISH, LARGE_HOOKS)):
        icon = tiles[beam].copy()
        for slot in range(hooks):
            icon.alpha_composite(tiles[fish_index(0, slot, FISH_STAGES - 1, first, hooks)])
        pzart.write_build_icon(icon, media / "textures" / f"Item_DryingBeam{name}.png")
    pallet = tiles[PALLET].copy()
    pallet.alpha_composite(tiles[PALLET_STACK + len(PALLET_LEVELS) - 1])
    pzart.write_build_icon(pallet, media / "textures" / "Item_StockfishPallet.png")
    pzart.write_build_icon(chamber_icon(tiles), media / "textures" / "Item_SmokehouseChamber.png")
    # The mod list shows the large beam, which is `icon` in mod.info.
    # Its posts run off the bottom, so the fish stay big enough to read.
    pzart.write_mod_icon(icon, media.parent / "icon.png", keep=MOD_ICON_KEEP)
    print(f"wrote {NAME}.pack and {NAME}.tiles to {media}")


if __name__ == "__main__":
    main()
