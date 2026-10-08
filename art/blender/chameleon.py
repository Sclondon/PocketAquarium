"""Veiled chameleon (Chamaeleo calyptratus).

What makes it one: the casque: a tall bony helmet on the back of its head, like a shark's fin;
eyes in cones that swivel one at a time; a body flattened from side to side like a leaf, with a
ridge of small spines down the back and a fringe under the chin; green, banded with yellow and
teal; feet like tongs, two toes against three, for gripping twigs; a tail it coils like a
watch spring.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one

kit = Kit("chameleon")
GREEN, YELLOW, TEAL, BELLY = srgb(0.3, 0.72, 0.25), srgb(0.95, 0.85, 0.3), srgb(0.15, 0.6, 0.6), srgb(0.75, 0.9, 0.6)


def skin(t, up, side):
    if up < -0.75:
        return BELLY
    band = int(t * 14.0) % 4
    return YELLOW if band == 1 else (TEAL if band == 3 else GREEN)


# tall and thin: it stands well clear of the ground on its legs
STATIONS = [(-1.0, 0.05, 0.06, 0.5), (-0.85, 0.11, 0.15, 0.52), (-0.6, 0.12, 0.2, 0.54), (-0.2, 0.14, 0.3, 0.56),
            (0.25, 0.13, 0.28, 0.56), (0.6, 0.07, 0.14, 0.54), (0.85, 0.045, 0.08, 0.5)]
kit.body(STATIONS, 12, skin, rows=29, squareness=2.6)
# the casque
kit.fin([(0.0, kit.top(z) - 0.02, z) for z in (-0.85, -0.72, -0.6)], [(0.0, kit.top(-0.85) + 0.08, -0.82), (0.0, kit.top(-0.72) + 0.42, -0.6), (0.0, kit.top(-0.6) + 0.1, -0.52)],
        lambda u, v: YELLOW if v > 0.7 else GREEN, rows=3, thick=0.07, line=1.0)
# the tail: down from the rump and round in a coil
path, radii = [(0.0, 0.5, 0.83)], [0.045]
for i in range(1, 15):
    a = i / 14.0 * 5.2
    r = 0.26 * (1.0 - i / 18.0)
    path.append((0.0, 0.26 + math.cos(a) * r, 1.05 + math.sin(a) * r * 0.9 - 0.1))
    radii.append(0.045 * (1.0 - i / 17.0))
kit.tube(path, radii, lambda t, k: TEAL if int(t * 12.0) % 2 == 0 else GREEN, around=6)
for sx in (-1.0, 1.0):
    # an eye in a cone
    kit.blob((sx * 0.1, 0.6, -0.82), (0.07, 0.09, 0.09), one(GREEN), around=8, rows=5)
    kit.eye((sx * 0.165, 0.6, -0.82), (sx, 0.0, -0.1), 0.035, srgb(0.1, 0.1, 0.1))
    # legs: straight down, with a foot like a pair of tongs
    for z, lean in ((-0.45, -0.1), (0.3, 0.1)):
        hw, hh, yc = kit.ring(z)
        knee = (sx * (hw + 0.1), 0.28, z + lean)
        foot = (sx * (hw + 0.04), 0.03, z + lean * 1.6)
        kit.tube([(sx * hw * 0.7, yc - hh * 0.5, z), knee, foot], [0.045, 0.035, 0.03], one(GREEN), around=5, line=0.7)
        for dz in (-0.07, 0.07):
            kit.tube([foot, (foot[0], 0.012, foot[2] + dz)], [0.028, 0.02], one(TEAL), around=4, line=0.5)
kit.finish(sys.argv[sys.argv.index("--") + 1])
