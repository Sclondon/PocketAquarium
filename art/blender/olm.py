"""Olm (Proteus anguinus), the cave salamander.

What makes it one: it has never seen light and has no colour: skin the pink-white of a person's
who has never been outdoors; no eyes (they are under the skin); a long flat snout like a
spoon; a body like an eel's, a hand long; three small feathery gills on each side of the neck,
red, the only colour it has; legs like matchsticks, with three toes in front and two behind;
a flattened tail with a low fin.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import leg, one

kit = Kit("olm")
SKIN, PALE, GILL = srgb(0.98, 0.84, 0.82), srgb(1.0, 0.94, 0.92), srgb(0.9, 0.25, 0.3)
FIN = (PALE[0], PALE[1], PALE[2], 0.7)

STATIONS = [(-1.3, 0.07, 0.025, 0.14), (-1.15, 0.11, 0.05, 0.15), (-0.95, 0.1, 0.07, 0.16), (-0.6, 0.085, 0.08, 0.16),
            (0.0, 0.085, 0.085, 0.16), (0.5, 0.075, 0.08, 0.16), (0.9, 0.04, 0.085, 0.16), (1.25, 0.012, 0.04, 0.16)]
kit.body(STATIONS, 10, lambda t, up, side: PALE if up < -0.3 else SKIN, rows=41, squareness=2.1)
for sign in (1.0, -1.0):
    root, rim = [], []
    for i in range(7):
        z = 0.4 + 0.85 * i / 6.0
        edge = kit.top(z) if sign > 0 else kit.bottom(z)
        root.append((0.0, edge - sign * 0.01, z))
        rim.append((0.0, edge + sign * 0.07 * math.sin(math.pi * i / 6.0) ** 0.5, z + 0.03))
    kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.015)
for sx in (-1.0, 1.0):
    for k in range(3):
        base = (sx * 0.09, 0.19, -0.9 + 0.03 * k)
        tip = (sx * (0.24 - 0.03 * k), 0.26 + 0.07 * (2 - k), -0.82 + 0.06 * k)
        kit.tube([base, tip], [0.022, 0.01], one(GILL), around=4, line=0.5)
        kit.fin([base, tip], [(base[0], base[1] - 0.01, base[2] + 0.07), (tip[0], tip[1] - 0.01, tip[2] + 0.07)], lambda u, v: GILL, rows=1, thick=0.012, line=0.4)
    leg(kit, (sx * 0.07, 0.13, -0.7), (sx * 0.17, 0.1, -0.72), (sx * 0.2, 0.015, -0.78), 0.025, SKIN, toes=3, spread=0.05)
    leg(kit, (sx * 0.06, 0.13, 0.35), (sx * 0.15, 0.1, 0.38), (sx * 0.18, 0.015, 0.33), 0.025, SKIN, toes=2, spread=0.05)
kit.finish(sys.argv[sys.argv.index("--") + 1])
