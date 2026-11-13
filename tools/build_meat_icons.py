#!/usr/bin/env python3
"""Paints the fat and salted meat icons of Traditional Preservation (Fish & Meat) into 42/media/textures.

Raw Pork Fat, Beef Suet and Mutton Fat are vanilla's loin icons pulled towards a fat colour, Tallow is vanilla's
Lard block yellowed, and the pots of fat are vanilla's full pots with the soup recoloured; Potted Meat's pots and
crocks are painted the same way, the Hot Smoked fish and meat (5c), and Cold Smoked fish and Dry Cured meat (5d). Cracklings use vanilla's
Pork Rinds icon as it is. Kept apart from build_tileset.py so the fish art doesn't rebuild with it.

Usage: python3 tools/build_meat_icons.py [path/to/ProjectZomboid/projectzomboid]
Needs Pillow. Rerun after editing the colours below.
"""
import os
import random
import sys
from pathlib import Path

from PIL import Image, ImageOps

sys.path.insert(0, str(Path(os.environ.get("TPCORE", Path(__file__).resolve().parents[2] / "TraditionalPreservationCore")) / "tools"))
import pzart  # noqa: E402

GAME = Path.home() / ".local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
# Our icon: the vanilla icon it starts from, the colour it is pulled towards, how far, and whether it is mirrored
# (so two fats from one loin don't look alike).
FATS = {
    "PorkFat": ("Item_PorkLoin", (250, 226, 214), 0.8, False),
    "BeefSuet": ("Item_BeefLoin", (255, 244, 200), 0.9, False),
    "MuttonFat": ("Item_PorkLoin", (240, 238, 226), 0.9, True),
    "Tallow": ("Item_Lard", (246, 230, 170), 0.6, False),
}
# Charque's stages (phases 3b and 3c), one icon per cut in MEAT_CUTS' order: Salt Packed is the cut dusted towards
# salt, Salt Cured darkened towards cured red-brown.
# Pork, Pork Chop and the Leg of Pork came with phase 6a; the leg starts from vanilla's Ham.
CUTS = {"Beef": "Item_BeefLoin", "Steak": "Item_Steak", "Mutton": "Item_Mutton", "Venison": "Item_Venison",
        "Pork": "Item_PorkLoin", "PorkChop": "Item_Porkchop", "Leg": "Item_Ham",
        # Poultry and rabbit (0.4.34): hot smoke only, but every stage lists every cut.
        "ChickenLeg": "Item_Chicken", "ChickenWing": "Item_ChickenWing", "ChickenFillet": "Item_ChickenFilet",
        "ChickenWhole": "Item_ChickenWhole", "TurkeyLeg": "Item_TurkeyLeg", "TurkeyWing": "Item_TurkeyWing",
        "TurkeyFillet": "Item_TurkeyFilet", "TurkeyWhole": "Item_TurkeyWhole", "Rabbit": "Item_Rabbitmeat"}
# The raw Leg of Pork (6a): vanilla's Ham icon, and its ground model's texture, pulled back to raw pork pink.
RAW_LEG = ((226, 150, 140), 0.7)
SALTED = {"SaltPacked": ((236, 232, 224), 0.35), "SaltCured": ((128, 54, 44), 0.45),
          # Charque (phase 3c) dark and dry, as its last hanging stage; soaked it is paler but never red again.
          "Charque": ((78, 40, 26), 0.85), "SoakedCharque": ((138, 82, 64), 0.6)}
# Hot Smoked (5c): meat is the cut pulled to a smoked mahogany; fish is our own Salt Dried icons (build_tileset.py's,
# whole, gutted and half for every species) pulled to the gold of hot smoked fish skin.
HOT_MEAT = ((122, 64, 34), 0.8)
HOT_FISH = ((204, 136, 56), 0.55)
HOT_FISH_STAGES = {"Dried_": "HotSmoked_", "DriedGutted_": "HotSmokedGutted_", "DriedHalf_": "HotSmokedHalf_"}
# Cold Smoked (5d): fish to a darker smoky bronze than hot smoking's gold; Dry Cured meat to a deep burgundy, darker
# and redder than charque's brown.
COLD_FISH = ((140, 88, 48), 0.6)
COLD_FISH_STAGES = {"Dried_": "ColdSmoked_", "DriedGutted_": "ColdSmokedGutted_", "DriedHalf_": "ColdSmokedHalf_"}
DRY_CURED = ((96, 34, 34), 0.85)
# The pots of fat: vanilla's full pot, with the soup's reds turned to melting fat.
POTS = {"PotOfFat": "Item_PotFull", "PotForgedFat": "Item_Pot_Forged_Stew"}
FAT_IN_POT = (244, 232, 196)
# Potted Meat (phase 4): the same pots with brown meat in the fat, and vanilla's clay jars (a Clay Pot shares the
# unglazed jar's icon) with the dark of the mouth turned to set white fat, as Dairy's yogurt jars are painted.
MEAT_POTS = {"PotOfMeatInFat": "Item_PotFull", "PotForgedMeatInFat": "Item_Pot_Forged_Stew"}
MEAT_IN_FAT = (150, 92, 60)
CROCKS = {"PottedMeat_Clay": "Item_ClayJar_Fired", "PottedMeat_Glazed": "Item_ClayJar_Glazed_Fired"}
SET_FAT = (240, 234, 212)
# Blood (0.4.36): vanilla's sausage, loaf and bread slices pulled to the near-black of cooked blood, with oat and fat
# flecks on the pudding; a raw link a dark red, cooked (the game's _Cooked icon) nearly black. Their ground models
# are vanilla's meshes with the same textures pulled the same way.
RAW_BLOOD = ((112, 30, 32), 0.85)
COOKED_BLOOD = ((46, 20, 22), 0.9)
# Smoked Blood Sausage (0.4.37): darker and browner than the boiled link, the smoke's dry tan over cooked blood.
SMOKED_BLOOD = ((40, 26, 16), 0.93)
BLOOD_ICONS = {"BloodSausage": ("Item_Sausage", RAW_BLOOD, False), "BloodSausage_Cooked": ("Item_Sausage", COOKED_BLOOD, False),
               "BloodSausageSlice": ("Item_SalamiSlices", COOKED_BLOOD, True),
               "SmokedBloodSausage": ("Item_Sausage", SMOKED_BLOOD, False),
               "SmokedBloodSausageSlice": ("Item_SalamiSlices", SMOKED_BLOOD, True),
               "BlackPudding": ("Item_Bread", COOKED_BLOOD, True), "BlackPuddingSlice": ("Item_BreadSlices", COOKED_BLOOD, True)}
BLOOD_MODELS = {"BloodSausageRawModel": ("SausageRaw", False), "BloodSausageModel": ("SausageCooked", False),
                "BloodSausageSliceModel": ("Salami", True), "BlackPuddingModel": ("Bread", True),
                "SmokedBloodSausageModel": ("SausageCooked", False), "SmokedBloodSausageSliceModel": ("Salami", True),
                "BlackPuddingSlicesModel": ("CheeseSandwich_PeanutButterSandwich_BreadSlices", True)}
FLECK = (214, 202, 176)
OUTLINE_BELOW = 70  # pixels with no channel above this are the icon's outline and stay as they are
# Vanilla's icons are spread over these packs.
ICON_PACKS = ["UI2.pack", "UI.pack"]


def pull(image, colour, amount):
    """Pulls an icon towards one colour, keeping its light and dark and its outline."""
    image = image.convert("RGBA")
    result = image.copy()
    for x in range(image.width):
        for y in range(image.height):
            r, g, b, a = image.getpixel((x, y))
            light = (r * 0.3 + g * 0.59 + b * 0.11) / 255
            if a == 0 or max(r, g, b) < OUTLINE_BELOW:
                continue
            shade = 0.7 + light * 0.5
            tinted = [min(255, int(c * shade)) for c in colour]
            result.putpixel((x, y), tuple(int(old + (new - old) * amount) for old, new in zip((r, g, b), tinted)) + (a,))
    return result


def is_soup(r, g, b):
    """The soup in vanilla's pots is the only warm, red-brown part; the pots are grey."""
    return r > 60 and r > g * 1.18 and r > b * 1.25


def fat_pot(image, colour=FAT_IN_POT):
    image = image.convert("RGBA")
    result = image.copy()
    for x in range(image.width):
        for y in range(image.height):
            r, g, b, a = image.getpixel((x, y))
            if a and is_soup(r, g, b):
                shade = 0.7 + r / 255 * 0.4
                result.putpixel((x, y), tuple(min(255, int(c * shade)) for c in colour) + (a,))
    return result


def meat_pot(image):
    """The pot of fat with lumps of meat in it: 3-pixel cells, about half of them meat, the same each build."""
    fat, meat = fat_pot(image), fat_pot(image, MEAT_IN_FAT)
    result = fat.copy()
    lumps = random.Random(42)
    cells = {}
    for x in range(image.width):
        for y in range(image.height):
            cell = ((x + (y // 3) % 2) // 3, y // 3)
            if cell not in cells:
                cells[cell] = lumps.random() < 0.5
            if cells[cell]:
                result.putpixel((x, y), meat.getpixel((x, y)))
    return result


def crock(image):
    """A vanilla clay jar with set fat filling its mouth: the dark inside of the mouth turned white (the region and
    the darkness test are Dairy's clay_jar_icon)."""
    icon = image.convert("RGBA").copy()
    pixels = icon.load()
    for y in range(3, 12):
        for x in range(19, 29):
            r, g, b, a = pixels[x, y]
            if a > 128 and 120 <= r + g + b < 260:
                shade = 1.0 - 0.025 * (y - 3) - 0.01 * (x - 19)
                pixels[x, y] = tuple(min(255, int(c * shade)) for c in SET_FAT) + (255,)
    return icon


def flecks(image, share=0.07):
    """Pale oat and fat flecks over an icon's inside, the same each build."""
    image = image.convert("RGBA").copy()
    pixels = image.load()
    dots = random.Random(7)
    for x in range(image.width):
        for y in range(image.height):
            r, g, b, a = pixels[x, y]
            inside = all(0 <= x + dx < image.width and 0 <= y + dy < image.height and pixels[x + dx, y + dy][3] > 128
                         for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)))
            if inside and dots.random() < share:
                shade = 0.8 + dots.random() * 0.2
                pixels[x, y] = tuple(int(c * shade) for c in FLECK) + (a,)
    return image


def read_icons(game, wanted):
    """Each wanted icon from the first pack that has it. Stops the build if one is in none."""
    icons = {}
    for pack in ICON_PACKS:
        for name in sorted(wanted - icons.keys()):
            try:
                icons.update(pzart.extract_sprites(game / "media/texturepacks" / pack, {name}))
            except SystemExit:
                pass  # not in this pack
    if wanted - icons.keys():
        raise SystemExit(f"icons not found in {ICON_PACKS}: {sorted(wanted - icons.keys())}")
    return icons


def main():
    game = Path(sys.argv[1]) if len(sys.argv) > 1 else GAME
    folder = Path(__file__).resolve().parent.parent / "42" / "media" / "textures"
    wanted = ({source for source, _, _, _ in FATS.values()} | set(POTS.values()) | set(CUTS.values())
              | set(CROCKS.values()) | {source for source, _, _ in BLOOD_ICONS.values()})
    icons = read_icons(game, wanted)
    for name, (source, colour, amount, mirrored) in FATS.items():
        icon = ImageOps.mirror(icons[source]) if mirrored else icons[source]
        pull(icon, colour, amount).save(folder / f"Item_{name}.png")
    for stage, (colour, amount) in SALTED.items():
        for cut, source in CUTS.items():
            pull(icons[source], colour, amount).save(folder / f"Item_{stage}_{cut}.png")
    # A dish lists Soaked Charque by its stand-in, which needs the stage's own icon (the beef's).
    pull(icons[CUTS["Beef"]], *SALTED["SoakedCharque"]).save(folder / "Item_SoakedCharque.png")
    for cut, source in CUTS.items():
        pull(icons[source], *HOT_MEAT).save(folder / f"Item_HotSmoked_{cut}.png")
    # The stage's own icon (the beef's), for its dish stand-in as Soaked Charque's.
    pull(icons[CUTS["Beef"]], *HOT_MEAT).save(folder / "Item_HotSmokedMeat.png")
    for cut, source in CUTS.items():
        pull(icons[source], *DRY_CURED).save(folder / f"Item_DryCured_{cut}.png")
    pull(icons[CUTS["Beef"]], *DRY_CURED).save(folder / "Item_DryCuredMeat.png")
    for path in sorted(folder.glob("Item_Dried*_*.png")):
        stage, species = path.stem[len("Item_"):].split("_", 1)
        pull(Image.open(path), *HOT_FISH).save(folder / f"Item_{HOT_FISH_STAGES[stage + '_']}{species}.png")
        pull(Image.open(path), *COLD_FISH).save(folder / f"Item_{COLD_FISH_STAGES[stage + '_']}{species}.png")
    pull(Image.open(folder / "Item_SaltDriedFish.png"), *HOT_FISH).save(folder / "Item_HotSmokedFish.png")
    pull(Image.open(folder / "Item_SaltDriedFish.png"), *COLD_FISH).save(folder / "Item_ColdSmokedFish.png")
    pull(icons[CUTS["Leg"]], *RAW_LEG).save(folder / "Item_LegOfPork.png")
    pull(Image.open(game / "media/textures/WorldItems/Ham.png"), *RAW_LEG).save(folder / "LegOfPorkModel.png")
    for name, source in POTS.items():
        fat_pot(icons[source]).save(folder / f"Item_{name}.png")
    for name, source in MEAT_POTS.items():
        meat_pot(icons[source]).save(folder / f"Item_{name}.png")
    for name, source in CROCKS.items():
        crock(icons[source]).save(folder / f"Item_{name}.png")
    for name, (source, (colour, amount), flecked) in BLOOD_ICONS.items():
        icon = pull(icons[source], colour, amount)
        (flecks(icon) if flecked else icon).save(folder / f"Item_{name}.png")
    for name, (source, flecked) in BLOOD_MODELS.items():
        colour = RAW_BLOOD if name == "BloodSausageRawModel" else SMOKED_BLOOD if name.startswith("Smoked") else COOKED_BLOOD
        texture = pull(Image.open(game / f"media/textures/WorldItems/{source}.png"), *colour)
        (flecks(texture, 0.05) if flecked else texture).save(folder / f"{name}.png")


if __name__ == "__main__":
    main()
