"""Guppy (Poecilia reticulata), a fancy male.

What makes it one: a small olive-silver fish, most of whose colour is in a tail as big as the
rest of him: a wide fan, orange shading to yellow at the edge, with dark spots; a dorsal fin
that trails like a flag; a mouth that turns up.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("guppy")
BACK, SIDE, BELLY, ORANGE, GOLD, SPOT = srgb(0.4, 0.5, 0.42), srgb(0.72, 0.78, 0.66), srgb(0.92, 0.92, 0.85), srgb(0.95, 0.5, 0.2), srgb(1.0, 0.85, 0.3), srgb(0.12, 0.1, 0.1)


def skin(t, up, side):
    if t > 0.6:
        return ORANGE
    if up > 0.5:
        return BACK
    return BELLY if up < -0.55 else SIDE


STATIONS = [(-0.9, 0.04, 0.05, 0.03), (-0.8, 0.1, 0.12, 0.02), (-0.5, 0.15, 0.2, 0.0), (-0.1, 0.15, 0.21, 0.0),
            (0.3, 0.1, 0.15, 0.0), (0.55, 0.06, 0.1, 0.0), (0.7, 0.045, 0.09, 0.0)]
plain_fish(kit, STATIONS, skin, ORANGE, GOLD, srgb(0.9, 0.85, 0.6), eye=0.07, eye_at=-0.74, tail=(0.75, 0.0),
           dorsal=(-0.1, 0.25, 0.3), anal=(0.1, 0.35, 0.14), pectoral=0.15)
# spots on the tail: a few dark discs, as thin fins standing just clear of it
for y, z in ((0.18, 1.0), (-0.12, 1.1), (0.02, 1.25), (-0.25, 0.95)):
    for sx in (-1.0, 1.0):
        kit.eye((sx * 0.018, y, z), (sx, 0.0, 0.0), 0.05, SPOT, pupil=SPOT, glint=SPOT)
kit.finish(sys.argv[sys.argv.index("--") + 1])
