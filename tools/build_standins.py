#!/usr/bin/env python3
"""Writes 42/media/scripts/TraditionalPreservationFishMeat_Standins.txt: the dish stand-ins by stage and animal.

A dish's ingredient list stores item types, and vanilla names the dish from them (ISAddItemInRecipe.checkName: each
type's FoodType and EvolvedRecipeName). Each meat stage is one item for every animal, so after a piece goes in, its
entry is swapped for the stand-in of its stage and animal (F.standinFor, TraditionalPreservationFishMeatEvolved.lua),
which carries vanilla's food type and name for that animal: a stew with hot smoked venison reads "Venison Stew".
Only the pairs the game can make are written. Rerun after editing the tables, then add the names to ItemName.json.

Usage: python3 tools/build_standins.py
"""
from pathlib import Path

# Vanilla's FoodType and dish name for each animal (MEAT_ANIMALS in TraditionalPreservationFishMeat.lua).
ANIMALS = {
    "Beef": ("Beef", "Beef"), "Mutton": ("Meat", "Mutton"), "Venison": ("Venison", "Venison"),
    "Pork": ("Meat", "Pork"), "Chicken": ("Poultry", "Chicken"), "Turkey": ("Poultry", "Turkey"),
    "Rabbit": ("Game", "Rabbit"),
}
# The icon each animal's stand-in shows: its stage's icon for a cut of it (build_meat_icons.py's names).
ICON_CUTS = {"Beef": "Beef", "Mutton": "Mutton", "Venison": "Venison", "Pork": "Pork", "Chicken": "ChickenLeg",
             "Turkey": "TurkeyLeg", "Rabbit": "Rabbit"}
# Stage: (icon prefix, or a fixed icon for slices; the animals that stage can hold). Hot smoked pork is vanilla's Ham.
# ColdSmokedMeat is no item of its own: dry cured meat with its smoke (not modData.airDried), named apart in a dish.
STAGES = {
    "HotSmokedMeat": ("HotSmoked_", ["Beef", "Mutton", "Venison", "Chicken", "Turkey", "Rabbit"]),
    "DryCuredMeat": ("DryCured_", ["Beef", "Mutton", "Venison", "Pork"]),
    "SoakedCharque": ("SoakedCharque_", ["Beef", "Mutton", "Venison"]),
    "HotSmokedMeatSlice": ("HamSlices", ["Beef", "Mutton", "Venison"]),
    "DryCuredMeatSlice": ("HamSlices", ["Beef", "Mutton", "Venison", "Pork"]),
    "ColdSmokedMeat": ("DryCured_", ["Beef", "Mutton", "Venison", "Pork"]),
    "ColdSmokedMeatSlice": ("HamSlices", ["Beef", "Mutton", "Venison", "Pork"]),
}


def main():
    out = ["/* Written by tools/build_standins.py: don't edit by hand. Dish stand-ins by stage and animal. */",
           "module TraditionalPreservationFishMeat", "{", "    imports", "    {", "        Base,", "    }", ""]
    for stage, (icon, animals) in STAGES.items():
        for animal in animals:
            food_type, name = ANIMALS[animal]
            item_icon = icon + ICON_CUTS[animal] if icon.endswith("_") else icon
            out += [f"    item {stage}Ingredient_{animal}", "    {", "        DisplayCategory = Food,",
                    "        ItemType = base:food,", "        Weight = 0.1,", f"        Icon = {item_icon},",
                    f"        FoodType = {food_type},", f"        EvolvedRecipeName = {name},", "    }", ""]
    out.append("}")
    path = Path(__file__).resolve().parent.parent / "42/media/scripts/TraditionalPreservationFishMeat_Standins.txt"
    path.write_text("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
