"""Glass frog (Hyalinobatrachium fleischmanni).

What makes it one: a small, delicate tree frog, lime green and a little see-through above, with
pale yellow spots; eyes that face forward, gold with a dark pupil; and underneath, no colour at
all: skin like glass, through which you can see its heart (red) and its insides (white).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import frog

kit = Kit("glass_frog")
g = srgb(0.62, 0.88, 0.3)
GREEN, SPOT, HEART, GUT = (g[0], g[1], g[2], 0.85), srgb(0.95, 0.95, 0.5), srgb(0.9, 0.1, 0.12), srgb(0.96, 0.96, 0.9)
c = srgb(0.8, 0.95, 0.75)
GLASS = (c[0], c[1], c[2], 0.35)
LIMB = (g[0], g[1], g[2], 0.7)


def skin(t, up, side):
    if up < -0.3:
        # the glass belly: the heart, a little forward of the middle, and the gut behind it
        if 0.32 < t < 0.44 and up < -0.75:
            return HEART
        if 0.48 < t < 0.75 and up < -0.75:
            return GUT
        return GLASS
    return SPOT if (int(t * 15.0) * 5 + int(up * 4.0) + side) % 7 == 0 else GREEN


STATIONS = [(-0.8, 0.11, 0.06, 0.36), (-0.66, 0.24, 0.12, 0.38), (-0.35, 0.27, 0.16, 0.36), (0.05, 0.26, 0.17, 0.32),
            (0.38, 0.18, 0.13, 0.26), (0.55, 0.08, 0.07, 0.22)]
frog(kit, STATIONS, skin, LIMB, SPOT, srgb(0.95, 0.85, 0.4), eye=0.1, eye_z=-0.58)
kit.finish(sys.argv[sys.argv.index("--") + 1])
