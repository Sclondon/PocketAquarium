"""Pinecone fish (Monocentris japonica).

What makes it one: a short, deep, armoured fish, yellow, every scale a plate outlined in black,
so it looks like a pine cone or a pineapple; thick spines along the back instead of a fin; a
blunt head with a big eye; and a light: a patch on each side of the lower jaw where glowing
bacteria live, which shines blue-green in the dark.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one, plain_fish

kit = Kit("pinecone_fish")
YELLOW, BLACK, PALE = srgb(0.98, 0.8, 0.2), srgb(0.08, 0.07, 0.05), srgb(0.98, 0.92, 0.6)
g = srgb(0.3, 1.0, 0.8)
GLOW = (g[0], g[1], g[2], 1.0, 0.9)


def skin(t, up, side):
    # the light, on the lower jaw
    if t < 0.1 and -0.75 < up < -0.3:
        return GLOW
    # the net of black between the plates: every third row round, and every third ring along
    if t > 0.14 and (int(t * 30.0) % 3 == 0 or round(up * 5.0) % 2 == 0 and int(t * 30.0) % 3 == 1):
        return BLACK
    return YELLOW


STATIONS = [(-0.85, 0.1, 0.12, 0.0), (-0.75, 0.2, 0.26, 0.0), (-0.45, 0.27, 0.42, 0.0), (0.0, 0.27, 0.44, 0.0),
            (0.4, 0.17, 0.28, 0.0), (0.62, 0.07, 0.11, 0.0), (0.75, 0.05, 0.09, 0.0)]
plain_fish(kit, STATIONS, skin, PALE, YELLOW, srgb(0.9, 0.85, 0.6), eye=0.11, eye_at=-0.62, tail=(0.34, 0.35),
           dorsal=(0.2, 0.5, 0.16), anal=(0.25, 0.5, 0.13), pectoral=0.2, around=16, rows=31)
# the spines along the back, leaning this way and that
for i, z in enumerate((-0.4, -0.25, -0.1, 0.05)):
    lean = 0.07 if i % 2 == 0 else -0.07
    kit.tube([(0.0, kit.top(z) - 0.02, z), (lean, kit.top(z) + 0.2, z + 0.06)], [0.035, 0.008], one(PALE), around=5, line=0.6)
kit.finish(sys.argv[sys.argv.index("--") + 1])
