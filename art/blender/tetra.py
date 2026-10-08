"""Neon tetra (Paracheirodon innesi).

What makes it one: a sliver of a fish; a stripe of electric blue-green from the eye to the
adipose fin, which shines; under it, from the middle of the body to the tail, a stripe of red;
an olive back, a silver belly, clear fins.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("tetra")
BACK, RED, BELLY = srgb(0.3, 0.34, 0.28), srgb(0.9, 0.16, 0.14), srgb(0.9, 0.92, 0.9)
b = srgb(0.15, 0.8, 1.0)
NEON = (b[0], b[1], b[2], 1.0, 0.55)
FIN = (0.85, 0.9, 0.9, 0.55)


def skin(t, up, side):
    if 0.5 < up < 0.6 and 0.08 < t < 0.75:
        return NEON
    if up > 0.6:
        return BACK
    if -0.6 < up <= 0.5 and t > 0.45:
        return RED
    return BELLY


STATIONS = [(-0.9, 0.035, 0.045, 0.0), (-0.8, 0.085, 0.11, 0.0), (-0.5, 0.12, 0.19, 0.0), (-0.1, 0.12, 0.2, 0.0),
            (0.35, 0.085, 0.14, 0.0), (0.65, 0.045, 0.085, 0.0), (0.8, 0.03, 0.07, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.85, 0.9, 0.9), eye=0.075, eye_at=-0.76, tail=(0.36, 0.6),
           dorsal=(-0.1, 0.2, 0.2), anal=(0.1, 0.5, 0.15), pectoral=0.14)
kit.finish(sys.argv[sys.argv.index("--") + 1])
