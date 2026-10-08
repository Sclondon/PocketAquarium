"""Axolotl (Ambystoma mexicanum), the pink one with dark eyes that everybody knows.

What makes it one: a broad flat head with a wide mouth that looks like a smile and small eyes
with no lids, set far apart; three feathery gills standing out behind the head on each side,
red; a long body and a longer tail with a fin running right round it and up the back; four
small legs, four toes in front and five behind.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import leg, one

kit = Kit("axolotl")
PINK, PALE, GILL, FRILL, MOUTH = srgb(0.98, 0.76, 0.78), srgb(1.0, 0.9, 0.9), srgb(0.85, 0.2, 0.3), srgb(0.95, 0.45, 0.5), srgb(0.8, 0.45, 0.5)
FIN = (PALE[0], PALE[1], PALE[2], 0.75)


def skin(t, up, side):
    # the smile: a line round the front of the head, just under halfway up
    if t < 0.13 and -0.35 < up < -0.1:
        return MOUTH
    return PALE if up < -0.4 else PINK


# it stands on the bottom: belly a little off it, feet at y = 0
STATIONS = [(-1.05, 0.21, 0.07, 0.22), (-0.95, 0.28, 0.12, 0.23), (-0.75, 0.28, 0.14, 0.24), (-0.55, 0.2, 0.14, 0.24),
            (-0.2, 0.19, 0.16, 0.24), (0.2, 0.16, 0.15, 0.24), (0.6, 0.09, 0.13, 0.25), (1.0, 0.045, 0.09, 0.26), (1.3, 0.02, 0.04, 0.26)]
kit.body(STATIONS, 14, skin, rows=37, squareness=2.3)
# the fin: up the back from the shoulders, round the tip of the tail and back along under it
for sign in (1.0, -1.0):
    root, rim = [], []
    for i in range(11):
        u = i / 10.0
        z = (-0.35 if sign > 0 else 0.3) + (1.65 if sign > 0 else 1.0) * u
        edge = kit.top(z) if sign > 0 else kit.bottom(z)
        root.append((0.0, edge - sign * 0.02, z))
        rim.append((0.0, edge + sign * (0.05 + 0.13 * math.sin(math.pi * u) ** 0.6), z + 0.04))
    kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.02, wave=0.02)
for sx in (-1.0, 1.0):
    # three gills, each a stalk with a feathery frill along the back of it
    for k in range(3):
        base = (sx * 0.2, 0.3 + 0.02 * k, -0.62 + 0.03 * k)
        lift = (0.42, 0.26, 0.08)[k]
        tip = (sx * (0.52 - 0.04 * k), 0.3 + lift, -0.45 + 0.12 * k)
        kit.tube([base, tip], [0.035, 0.015], one(GILL), around=5, line=0.6)
        root = [tuple(base[j] + (tip[j] - base[j]) * u for j in range(3)) for u in (0.15, 0.5, 0.95)]
        rim = [(p[0], p[1] - 0.02, p[2] + 0.13) for p in root]
        kit.fin(root, rim, lambda u, v: FRILL, rows=2, thick=0.02, line=0.5)
    kit.eye((sx * 0.2, 0.33, -0.92), (sx * 0.6, 0.6, -0.5), 0.04, srgb(0.1, 0.08, 0.1))
    leg(kit, (sx * 0.17, 0.2, -0.4), (sx * 0.32, 0.14, -0.42), (sx * 0.36, 0.02, -0.5), 0.05, PINK, toes=4, spread=0.08)
    leg(kit, (sx * 0.14, 0.2, 0.25), (sx * 0.3, 0.14, 0.3), (sx * 0.34, 0.02, 0.2), 0.05, PINK, toes=5, spread=0.08)
kit.finish(sys.argv[sys.argv.index("--") + 1])
