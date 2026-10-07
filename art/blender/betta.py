"""Betta (Betta splendens), a long-finned male of the kind sold everywhere.

What makes it a betta and has to survive the cartooning:
  a slim body about four times as long as it is deep, deepest a third of the way back
  a mouth that turns up, for taking food and air at the surface
  a tail as long as the body is deep three times over, spreading to half a circle
  a dorsal fin set well back, over the rear half of the body only
  an anal fin from the middle of the belly to the tail, longest at the back
  two ventral fins like long ribbons, under the throat
  small round pectoral fins, kept moving
  a body that stays deep right to the tail (no narrow wrist before it)

Run by tools/build_models.sh:  blender -b --python art/blender/betta.py -- OUT_DIR
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("betta")

BACK = srgb(0.30, 0.03, 0.10)
SIDE = srgb(0.80, 0.10, 0.20)
BELLY = srgb(0.93, 0.36, 0.38)
GILL = srgb(0.42, 0.03, 0.12)
FIN = srgb(0.36, 0.16, 0.72)
FIN_ROOT = srgb(0.62, 0.10, 0.36)
EDGE = srgb(0.30, 0.78, 0.95)
IRIS = srgb(0.98, 0.86, 0.45)

# z, half-width, half-height, y-centre: nose to tail
STATIONS = [
    (-1.10, 0.035, 0.04, 0.10),
    (-1.00, 0.10, 0.12, 0.075),
    (-0.82, 0.17, 0.23, 0.035),
    (-0.55, 0.21, 0.31, 0.02),
    (-0.25, 0.215, 0.33, 0.02),
    (0.10, 0.19, 0.30, 0.02),
    (0.45, 0.13, 0.23, 0.02),
    (0.72, 0.085, 0.17, 0.02),
    (0.90, 0.05, 0.14, 0.02),
]


def skin(t, up, side):
    # the gill cover: one dark band behind the head
    if 0.17 < t < 0.21 and -0.55 < up < 0.75:
        return GILL
    if up > 0.72:
        return BACK
    if up < -0.6 and t < 0.75:
        return BELLY
    return SIDE


ring = kit.body(STATIONS, 16, skin, rows=28)


def top(z):
    hw, hh, yc = ring(z)
    return yc + hh


def bottom(z):
    hw, hh, yc = ring(z)
    return yc - hh


def webbing(u, v):
    """A fin's colours: the body's red at the root, violet through the middle, a pale edge."""
    if v > 0.82:
        return EDGE
    return FIN_ROOT if v < 0.2 else FIN


# the tail: from the end of the body, half a circle and a little more, drooping as it goes
N = 15
tail_root, tail_rim = [], []
for i in range(N):
    u = i / (N - 1)
    a = (0.5 - u) * 3.5
    tail_root.append((0.0, 0.02 + math.sin(a) * 0.11, 0.86 + (1.0 - abs(math.sin(a))) * 0.02))
    reach = 0.9 * (1.0 - 0.06 * math.cos(a * 5.0))
    tail_rim.append((0.0, 0.02 + math.sin(a) * reach - 0.12 * abs(math.cos(a)) * reach, 0.86 + math.cos(a) * reach))
kit.fin(tail_root, tail_rim, webbing, rows=7, wave=0.05)

# the dorsal fin: over the rear half, rising and sweeping back
N = 9
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = 0.05 + 0.55 * u
    root.append((0.0, top(z) - 0.03, z))
    rim.append((0.0, top(z) + 0.12 + 0.62 * math.sin(math.pi * u ** 0.6), z + 0.1 + 0.16 * u))
kit.fin(root, rim, webbing, rows=5, wave=0.04)

# the anal fin: from the middle of the belly to the tail, longest at the back
N = 11
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = -0.3 + 0.98 * u
    root.append((0.0, bottom(z) + 0.03, z))
    rim.append((0.0, bottom(z) - 0.14 - 0.5 * math.sin(math.pi * (0.15 + 0.7 * u) ** 1.6), z + 0.04 + 0.14 * u))
kit.fin(root, rim, webbing, rows=5, wave=0.04)

for sx in (-1.0, 1.0):
    # a ventral fin: a long ribbon from under the throat, trailing down and back
    zs = (-0.66, -0.6, -0.54)
    root = [(sx * 0.07, bottom(z) + 0.04, z) for z in zs]
    rim = [(sx * 0.16, bottom(-0.6) - 0.62, -0.2), (sx * 0.17, bottom(-0.6) - 0.74, -0.08), (sx * 0.16, bottom(-0.6) - 0.6, -0.06)]
    kit.fin(root, rim, lambda u, v: EDGE if v > 0.8 else FIN_ROOT, rows=5, thick=0.025)
    # a pectoral fin: small and round, out from behind the gill cover
    hw, hh, yc = ring(-0.66)
    at = (sx * hw * 0.92, yc - hh * 0.25, -0.66)
    root, rim = [], []
    for i in range(5):
        a = (i / 4.0 - 0.5) * 1.7
        root.append((at[0], at[1] + math.sin(a) * 0.05, at[2] + 0.02))
        rim.append((at[0] + sx * 0.2, at[1] + math.sin(a) * 0.19 - 0.03, at[2] + 0.1 + math.cos(a) * 0.2))
    kit.fin(root, rim, lambda u, v: EDGE if v > 0.75 else FIN, rows=3, thick=0.02)
    # an eye, a little bigger than life
    hw, hh, yc = ring(-0.93)
    kit.eye((sx * (hw * 0.93), yc + hh * 0.3, -0.93), (sx, 0.12, -0.25), 0.085, IRIS)

kit.finish(sys.argv[sys.argv.index("--") + 1])
