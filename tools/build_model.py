#!/usr/bin/env python3
"""Builds the Stockfish Bale's ground model (42/media/Models_X/StockfishBale.glb), its texture and its icon.

The bale is seven stockfish in three layers, heads and tails alternating as they were packed, held by two twine
bands. Each fish is a flat slab swept along PROFILE. Units are metres, Y up, base on the ground; its in-game size is
the `scale` of the StockfishBaleGround model in 42/media/scripts/TraditionalPreservationFishMeat.txt. The glb writer is
FuelBarrel's (tools/build_model.py there): FuelBarrel isn't TP, so the two can't share it through pzart.

The texture: the fish's skin on the left (FISH_U, along the fish), its edges and neck cut in a strip, the twine on
the right. The icon stacks the Cold Dried fish icon (build_tileset's headless_icon and stage_icon) under a band.

Usage: python3 tools/build_model.py [path/to/ProjectZomboid/projectzomboid]
Needs Pillow and numpy. Rerun after editing the tables below.
"""
import json
import math
import random
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from build_tileset import DONE_COLD_FISH, FISH_STAGES, FRESH_COLD_FISH, GAME, fish_stage, headless_icon, long_axis, read_icons, stage_icon

# (share of the length from the neck, half width, thickness), in metres for a fish of FISH_LENGTH.
PROFILE = [
    (0.0, 0.050, 0.022), (0.1, 0.058, 0.026), (0.25, 0.060, 0.026), (0.45, 0.052, 0.022), (0.65, 0.035, 0.016),
    (0.8, 0.018, 0.010), (0.88, 0.012, 0.006), (0.94, 0.030, 0.004), (1.0, 0.045, 0.003),
]
FISH_LENGTH = 0.55
LAYER_HEIGHT = 0.022  # a little under a fish's thickness, so the layers sit into each other
# Each layer's fish across the bale (z of its middle); heads alternate fish by fish and layer by layer.
LAYERS = [(-0.1, 0.0, 0.1), (-0.05, 0.05), (-0.05, 0.05)]
FISH_TURN = 5  # degrees, at most, each way
FISH_SHIFT = 0.02  # metres along the bale, at most, each way
BANDS = (-0.12, 0.12)  # x of each band
BAND_WIDTH, BAND_THICKNESS, BAND_SLACK = 0.022, 0.004, 0.006
BAND_SEGMENTS = 32
BAND_SQUARENESS = 0.35  # the band's corners: 1 is an ellipse, smaller is squarer
LIFT = 0.004  # the whole bale, so the band under it clears the ground

FISH_U, EDGE_U, BAND_U = (0.0, 0.7), (0.7, 0.8), (0.82, 1.0)
NECK_UV = (0.75, 0.1)
TEXTURE_SIZE, SAVED_TEXTURE_SIZE = 256, 128
GAIN = 1.6  # the game lights models darker than icons
SKIN = DONE_COLD_FISH["colour"]
BACK, BELLY, EDGE = (0.62, 0.66, 0.70), (1.08, 1.06, 1.0), (0.7, 0.68, 0.64)
FLESH = (214, 196, 160)
TWINE, TWINE_DARK = (176, 146, 98), (118, 92, 58)
TWINE_TWISTS = 18  # dark twists along the whole band
ICON_FISH = "Fish_Walleye"  # the same fish as the Cold Dried icon
ICON_STACK = (-3, 0, 3)  # pixels across the fish for each copy, back to front
ICON_STACK_LIGHT = (0.7, 0.85, 1.0)
ICON_BAND = 3.5  # pixels wide
ICON_BAND_SHIFT = 0  # pixels along the fish from its middle


class Mesh:
    def __init__(self):
        self.positions, self.normals, self.uvs, self.indices = [], [], [], []

    def vertex(self, position, normal, uv):
        self.positions.append(position)
        self.normals.append(normal)
        self.uvs.append(uv)
        return len(self.positions) - 1

    def quad(self, a, b, c, d):
        self.indices += [a, b, c, a, c, d]

    def flat_quad(self, corners, uvs, inside):
        """Four corners in order round the face, with its own normal, turned to face away from a point inside."""
        p = [np.array(c, dtype=float) for c in corners]
        normal = np.cross(p[1] - p[0], p[3] - p[0])
        if np.dot(normal, sum(p) / 4 - np.array(inside)) < 0:
            corners, uvs, normal = corners[::-1], uvs[::-1], -normal
        normal = tuple((normal / (np.linalg.norm(normal) or 1)).tolist())
        self.quad(*[self.vertex(tuple(c), normal, uv) for c, uv in zip(corners, uvs)])


def place(x, z, centre, direction, turn):
    """A point of a fish lying along +x (neck at 0) moved to its spot in the bale."""
    x = (x - FISH_LENGTH / 2) * direction
    c, s = math.cos(turn), math.sin(turn)
    return x * c - z * s + centre[0], x * s + z * c + centre[1]


def add_fish(mesh, centre, y, direction, turn):
    stations = []
    for share, half, thick in PROFILE:
        x = share * FISH_LENGTH
        u = FISH_U[0] + (FISH_U[1] - FISH_U[0]) * share
        left, right = place(x, -half, centre, direction, turn), place(x, half, centre, direction, turn)
        stations.append((left, right, y + LIFT, y + LIFT + thick, u, half))
    widest = max(half for _, half, _ in PROFILE)
    edge_u = sum(EDGE_U) / 2
    for (l0, r0, b0, t0, u0, h0), (l1, r1, b1, t1, u1, h1) in zip(stations, stations[1:]):
        mx, mz = place((u0 + u1) / 2 / FISH_U[1] * FISH_LENGTH, 0.0, centre, direction, turn)
        inside = (mx, (b0 + t0) / 2, mz)
        # Top and bottom: v runs across the fish, so the back's dark and the belly's light follow its taper.
        v0, v1 = 0.5 - h0 / widest / 2, 0.5 - h1 / widest / 2
        uv = [(u0, v0), (u1, v1), (u1, 1 - v1), (u0, 1 - v0)]
        for level0, level1 in ((t0, t1), (b0, b1)):
            mesh.flat_quad([(l0[0], level0, l0[1]), (l1[0], level1, l1[1]), (r1[0], level1, r1[1]), (r0[0], level0, r0[1])], uv, inside)
        for a, b in ((l0, l1), (r0, r1)):
            side = [(a[0], b0, a[1]), (a[0], t0, a[1]), (b[0], t1, b[1]), (b[0], b1, b[1])]
            mesh.flat_quad(side, [(edge_u, 0.2), (edge_u, 0.25), (edge_u, 0.3), (edge_u, 0.35)], inside)
    l0, r0, b0, t0, _, _ = stations[0]
    nx, nz = place(0.05 * FISH_LENGTH, 0.0, centre, direction, turn)
    neck = [(l0[0], b0, l0[1]), (r0[0], b0, r0[1]), (r0[0], t0, r0[1]), (l0[0], t0, l0[1])]
    mesh.flat_quad(neck, [NECK_UV] * 4, (nx, (b0 + t0) / 2, nz))


def add_band(mesh, x, top, half):
    """A twine band round the bale at x: a flat strip on a rounded rectangle, with its two edges."""
    centre = top / 2 + LIFT
    a, b = half + BAND_SLACK, top / 2 + BAND_SLACK
    rings = []
    for i in range(BAND_SEGMENTS + 1):
        angle = 2 * math.pi * i / BAND_SEGMENTS
        c, s = math.cos(angle), math.sin(angle)
        z = a * math.copysign(abs(c) ** BAND_SQUARENESS, c)
        y = centre + b * math.copysign(abs(s) ** BAND_SQUARENESS, s)
        normal = np.array([0.0, (y - centre) / b ** 2, z / a ** 2])
        normal /= np.linalg.norm(normal)
        rings.append((z, y, normal))
    u0, u1 = BAND_U
    for (z0, y0, n0), (z1, y1, n1), i in zip(rings, rings[1:], range(BAND_SEGMENTS)):
        v0, v1 = i / BAND_SEGMENTS, (i + 1) / BAND_SEGMENTS
        o0, o1 = n0 * BAND_THICKNESS, n1 * BAND_THICKNESS
        outer = [(x - BAND_WIDTH / 2, y0 + o0[1], z0 + o0[2]), (x - BAND_WIDTH / 2, y1 + o1[1], z1 + o1[2]),
                 (x + BAND_WIDTH / 2, y1 + o1[1], z1 + o1[2]), (x + BAND_WIDTH / 2, y0 + o0[1], z0 + o0[2])]
        normals = [tuple(n0.tolist()), tuple(n1.tolist()), tuple(n1.tolist()), tuple(n0.tolist())]
        uvs = [(u0, v0), (u0, v1), (u1, v1), (u1, v0)]
        # Smooth normals round the loop: wind the strip to face the way they point.
        p = [np.array(c) for c in outer]
        if np.dot(np.cross(p[1] - p[0], p[3] - p[0]), n0 + n1) < 0:
            outer, normals, uvs = outer[::-1], normals[::-1], uvs[::-1]
        mesh.quad(*[mesh.vertex(c, n, uv) for c, n, uv in zip(outer, normals, uvs)])
        for side in (x - BAND_WIDTH / 2, x + BAND_WIDTH / 2):
            edge = [(side, y0, z0), (side, y0 + o0[1], z0 + o0[2]), (side, y1 + o1[1], z1 + o1[2]), (side, y1, z1)]
            mesh.flat_quad(edge, [(u0, v0), (u0, v0), (u0, v1), (u0, v1)], (x, y0, z0))


def build_mesh():
    mesh = Mesh()
    rng = random.Random("bale")
    top, half = 0.0, 0.0
    for layer, row in enumerate(LAYERS):
        y = layer * LAYER_HEIGHT
        for index, z in enumerate(row):
            direction = 1 if (index + layer) % 2 == 0 else -1
            turn = math.radians(rng.uniform(-FISH_TURN, FISH_TURN))
            add_fish(mesh, (rng.uniform(-FISH_SHIFT, FISH_SHIFT), z), y, direction, turn)
            half = max(half, abs(z) + max(h for _, h, _ in PROFILE))
        top = y + max(t for _, _, t in PROFILE)
    for x in BANDS:
        add_band(mesh, x, top, half)
    return mesh


def bright(colour, gain=GAIN):
    """Scales a colour, keeping its hue if it would pass the maximum."""
    scaled = [c * gain for c in colour]
    limit = min(1.0, 255 / max(scaled))
    return tuple(int(c * limit) for c in scaled) + (255,)


def paint_texture():
    size = TEXTURE_SIZE
    image = Image.new("RGBA", (size, size), bright(SKIN))
    pixels = image.load()
    rng = random.Random("bale skin")
    fish_right = int(FISH_U[1] * size)
    for y in range(size):
        across = y / (size - 1)
        # The back down one side, the belly the other, a faint lateral line between.
        shade = [b + (l - b) * across for b, l in zip(BACK, BELLY)]
        line = 0.88 if abs(across - 0.42) < 0.012 else 1.0
        for x in range(fish_right):
            grain = 1 + rng.uniform(-0.05, 0.05)
            pixels[x, y] = bright([c * s * line * grain for c, s in zip(SKIN, shade)])
    draw = ImageDraw.Draw(image)
    draw.rectangle([fish_right, 0, int(EDGE_U[1] * size), size], fill=bright([c * e for c, e in zip(SKIN, EDGE)]))
    nu, nv = NECK_UV
    draw.rectangle([int((nu - 0.03) * size), int((nv - 0.06) * size), int((nu + 0.03) * size), int((nv + 0.06) * size)], fill=bright(FLESH))
    band_left = int(BAND_U[0] * size)
    draw.rectangle([band_left, 0, size, size], fill=bright(TWINE))
    step = size / TWINE_TWISTS
    for i in range(TWINE_TWISTS + 1):
        y = int(i * step)
        draw.line([(band_left, y), (size, y + step / 2)], fill=bright(TWINE_DARK), width=3)
    image = image.filter(ImageFilter.GaussianBlur(1.0))
    return image.resize((SAVED_TEXTURE_SIZE, SAVED_TEXTURE_SIZE), Image.BOX)


def paint_icon(game):
    """Three Cold Dried fish stacked, as the series' own icon draws one, with a twine band across their middle.
    Drawn at icon size, pixel by pixel, so it stays as crisp as the fish icons beside it."""
    icons = read_icons(game)
    fish = stage_icon(headless_icon(icons[f"Item_{ICON_FISH}"], ICON_FISH), *fish_stage(FISH_STAGES - 1, FRESH_COLD_FISH, DONE_COLD_FISH), 0)
    angle = math.radians(long_axis(fish))
    across = (-math.sin(angle), math.cos(angle))
    icon = Image.new("RGBA", fish.size, (0, 0, 0, 0))
    for step, light in zip(ICON_STACK, ICON_STACK_LIGHT):
        layer = fish.point(lambda v, light=light: int(v * light)) if light < 1 else fish
        layer.putalpha(fish.getchannel("A"))
        icon.alpha_composite(layer, (round(across[0] * step), round(across[1] * step)))
    solid = [(x, y) for x in range(icon.width) for y in range(icon.height) if icon.getpixel((x, y))[3] > 128]
    cx = sum(x for x, _ in solid) / len(solid) + ICON_BAND_SHIFT * math.cos(angle)
    cy = sum(y for _, y in solid) / len(solid) + ICON_BAND_SHIFT * math.sin(angle)
    for x, y in solid:
        # Distance along the fish from the band's line, which runs across them through the middle.
        along = (x - cx) * math.cos(angle) + (y - cy) * math.sin(angle)
        if abs(along) <= ICON_BAND / 2:
            twist = (round((x - cx) * across[0] + (y - cy) * across[1]) + round(along)) % 3 == 0
            edge = abs(along) > ICON_BAND / 2 - 1
            icon.putpixel((x, y), (TWINE_DARK if twist or edge else TWINE) + (255,))
    return icon


def write_glb(path, mesh):
    positions = np.array(mesh.positions, dtype="<f4")
    normals = np.array(mesh.normals, dtype="<f4")
    uvs = np.array(mesh.uvs, dtype="<f4")
    indices = np.array(mesh.indices, dtype="<u2")

    chunks, views, accessors = bytearray(), [], []

    def add(array, kind, component, target, bounds=False):
        offset = len(chunks)
        chunks.extend(array.tobytes())
        chunks.extend(b"\0" * (-len(chunks) % 4))
        views.append({"buffer": 0, "byteOffset": offset, "byteLength": array.nbytes, "target": target})
        accessor = {"bufferView": len(views) - 1, "componentType": component, "count": len(array), "type": kind}
        if bounds:
            accessor["min"] = array.min(axis=0).tolist()
            accessor["max"] = array.max(axis=0).tolist()
        accessors.append(accessor)
        return len(accessors) - 1

    primitive = {
        "attributes": {
            "POSITION": add(positions, "VEC3", 5126, 34962, bounds=True),
            "NORMAL": add(normals, "VEC3", 5126, 34962),
            "TEXCOORD_0": add(uvs, "VEC2", 5126, 34962),
        },
        "indices": add(indices, "SCALAR", 5123, 34963),
    }
    document = {
        "asset": {"version": "2.0", "generator": "TraditionalPreservationFishMeat build_model.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "Bale"}],
        "meshes": [{"name": "Bale", "primitives": [primitive]}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(chunks)}],
    }
    text = json.dumps(document, separators=(",", ":")).encode("utf8")
    text += b" " * (-len(text) % 4)
    total = 12 + 8 + len(text) + 8 + len(chunks)
    with open(path, "wb") as out:
        out.write(struct.pack("<4sII", b"glTF", 2, total))
        out.write(struct.pack("<I4s", len(text), b"JSON") + text)
        out.write(struct.pack("<I4s", len(chunks), b"BIN\0") + bytes(chunks))


def main():
    game = Path(sys.argv[1]) if len(sys.argv) > 1 else GAME
    media = Path(__file__).resolve().parent.parent / "42" / "media"
    (media / "Models_X").mkdir(parents=True, exist_ok=True)
    write_glb(media / "Models_X" / "StockfishBale.glb", build_mesh())
    paint_texture().save(media / "textures" / "StockfishBaleModel.png")
    paint_icon(game).save(media / "textures" / "Item_StockfishBale.png")
    print(f"wrote the bale's model, texture and icon to {media}")


if __name__ == "__main__":
    main()
