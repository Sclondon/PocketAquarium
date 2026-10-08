"""Chinese fire-bellied newt (Cynops orientalis).

What makes it one: a small newt, black-brown and smooth above; underneath, from chin to tail,
bright orange-red with black blotches, which is a warning; a rounded snout; a tail flattened
from side to side like an oar, as long as the body; four thin legs.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import leg

kit = Kit("fire_newt")
BLACK, FIRE, BLOTCH = srgb(0.1, 0.08, 0.07), srgb(0.98, 0.42, 0.08), srgb(0.08, 0.06, 0.05)


def skin(t, up, side):
    if up < -0.2:
        return BLOTCH if (int(t * 17.0) * 7 + side) % 5 == 0 else FIRE
    return BLACK


STATIONS = [(-1.05, 0.07, 0.04, 0.16), (-0.92, 0.14, 0.08, 0.17), (-0.72, 0.13, 0.09, 0.17), (-0.4, 0.14, 0.1, 0.17),
            (0.1, 0.13, 0.1, 0.17), (0.4, 0.07, 0.09, 0.17), (0.9, 0.03, 0.1, 0.17), (1.25, 0.012, 0.04, 0.17)]
kit.body(STATIONS, 12, skin, rows=41, squareness=2.1)
for sx in (-1.0, 1.0):
    kit.eye((sx * 0.11, 0.22, -0.92), (sx, 0.5, -0.3), 0.04, srgb(0.7, 0.55, 0.25))
    leg(kit, (sx * 0.11, 0.15, -0.55), (sx * 0.24, 0.11, -0.57), (sx * 0.28, 0.015, -0.66), 0.03, BLACK, toes=4, toe_colour=FIRE, spread=0.06)
    leg(kit, (sx * 0.1, 0.15, 0.2), (sx * 0.23, 0.11, 0.24), (sx * 0.27, 0.015, 0.16), 0.03, BLACK, toes=5, toe_colour=FIRE, spread=0.06)
kit.finish(sys.argv[sys.argv.index("--") + 1])
