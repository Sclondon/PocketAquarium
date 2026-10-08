"""Sandfish skink (Scincus scincus).

What makes it one: built to swim through sand: a snout like a shovel, a body as smooth as
glass, short strong legs it folds flat when it dives, and a short tail; pale gold, with broad
soft brown bands across the back, and white underneath; small eyes, low on the head.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import lizard

kit = Kit("sandfish")
GOLD, BAND, WHITE, LEG = srgb(0.95, 0.78, 0.42), srgb(0.6, 0.4, 0.22), srgb(0.98, 0.95, 0.88), srgb(0.9, 0.74, 0.44)


def skin(t, up, side):
    if up < -0.2:
        return WHITE
    return BAND if 0.2 < t < 0.9 and int(t * 20.0) % 3 == 0 else GOLD


# the snout is a wedge: wide and thin at the tip
STATIONS = [(-1.1, 0.1, 0.02, 0.1), (-0.95, 0.17, 0.07, 0.13), (-0.7, 0.19, 0.11, 0.15), (-0.3, 0.2, 0.13, 0.16),
            (0.2, 0.19, 0.13, 0.16), (0.55, 0.13, 0.1, 0.14), (0.85, 0.07, 0.06, 0.1), (1.05, 0.02, 0.02, 0.07)]
lizard(kit, STATIONS, skin, LEG, WHITE, srgb(0.2, 0.15, 0.1), eye=0.045, eye_z=-0.88, shoulders=-0.55, hips=0.3, reach=0.2)
kit.finish(sys.argv[sys.argv.index("--") + 1])
