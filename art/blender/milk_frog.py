"""Amazon milk frog (Trachycephalus resinifictrix).

What makes it one: a big tree frog, pale blue-grey with broad chocolate-brown bands across the
body and round the legs; gold eyes with a black cross in them; very large round pads on the
ends of its toes, blue-tinged, which it climbs glass with.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import frog

kit = Kit("milk_frog")
PALE, BROWN, BELLY, PAD = srgb(0.74, 0.82, 0.86), srgb(0.32, 0.2, 0.14), srgb(0.92, 0.94, 0.92), srgb(0.55, 0.75, 0.9)


def skin(t, up, side):
    if up < -0.3:
        return BELLY
    return BROWN if 0.25 < t < 0.42 or 0.6 < t < 0.78 or t < 0.08 else PALE


STATIONS = [(-0.85, 0.14, 0.08, 0.4), (-0.7, 0.3, 0.16, 0.42), (-0.35, 0.36, 0.22, 0.4), (0.05, 0.36, 0.23, 0.35),
            (0.4, 0.25, 0.18, 0.28), (0.6, 0.1, 0.09, 0.24)]
frog(kit, STATIONS, skin, BROWN, PAD, srgb(0.9, 0.75, 0.3), eye=0.11)
kit.finish(sys.argv[sys.argv.index("--") + 1])
