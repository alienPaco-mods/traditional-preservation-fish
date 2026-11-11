#!/usr/bin/env python3
"""Paints the fat and salted meat icons of Traditional Preservation (Fish & Meat) into 42/media/textures.

Raw Pork Fat, Beef Suet and Mutton Fat are vanilla's loin icons pulled towards a fat colour, Tallow is vanilla's
Lard block yellowed, and the pots of fat are vanilla's full pots with the soup recoloured. Cracklings use vanilla's
Pork Rinds icon as it is. Kept apart from build_tileset.py so the fish art doesn't rebuild with it.

Usage: python3 tools/build_meat_icons.py [path/to/ProjectZomboid/projectzomboid]
Needs Pillow. Rerun after editing the colours below.
"""
import os
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
# Charque's stages (phase 3b), one icon per cut in MEAT_CUTS' order: Salt Packed is the cut dusted towards salt,
# Salt Cured darkened towards cured red-brown.
CUTS = {"Beef": "Item_BeefLoin", "Steak": "Item_Steak", "Mutton": "Item_Mutton", "Venison": "Item_Venison"}
SALTED = {"SaltPacked": ((236, 232, 224), 0.35), "SaltCured": ((128, 54, 44), 0.45)}
# The pots of fat: vanilla's full pot, with the soup's reds turned to melting fat.
POTS = {"PotOfFat": "Item_PotFull", "PotForgedFat": "Item_Pot_Forged_Stew"}
FAT_IN_POT = (244, 232, 196)
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


def fat_pot(image):
    image = image.convert("RGBA")
    result = image.copy()
    for x in range(image.width):
        for y in range(image.height):
            r, g, b, a = image.getpixel((x, y))
            if a and is_soup(r, g, b):
                shade = 0.7 + r / 255 * 0.4
                result.putpixel((x, y), tuple(min(255, int(c * shade)) for c in FAT_IN_POT) + (a,))
    return result


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
    wanted = {source for source, _, _, _ in FATS.values()} | set(POTS.values()) | set(CUTS.values())
    icons = read_icons(game, wanted)
    for name, (source, colour, amount, mirrored) in FATS.items():
        icon = ImageOps.mirror(icons[source]) if mirrored else icons[source]
        pull(icon, colour, amount).save(folder / f"Item_{name}.png")
    for stage, (colour, amount) in SALTED.items():
        for cut, source in CUTS.items():
            pull(icons[source], colour, amount).save(folder / f"Item_{stage}_{cut}.png")
    for name, source in POTS.items():
        fat_pot(icons[source]).save(folder / f"Item_{name}.png")


if __name__ == "__main__":
    main()
