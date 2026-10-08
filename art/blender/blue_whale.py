"""Blue whale (Balaenoptera musculus).

What makes it one: long and slim for a whale, with a broad flat head shaped like a gothic arch
from above; blue-grey, mottled with paler blotches; a paler underside, pleated from chin to
navel in long grooves; a dorsal fin so small and so far back you could miss it; long narrow
flippers; flukes that lie flat.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("blue_whale")
BLUE, MOTTLE, BELLY, GROOVE = srgb(0.26, 0.42, 0.58), srgb(0.36, 0.52, 0.67),srgb(0.76, 0.84, 0.9), srgb(0.5, 0.6, 0.7)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.3:
        # the grooves, along the front half of the underside
        return GROOVE if t < 0.55 and round(up * 14.0) % 2 == 0 else BELLY
    return MOTTLE if chance(int(t * 60.0), int(up * 9.0) + side) < 0.14 else BLUE


STATIONS = [(-1.4, 0.1, 0.05, -0.04), (-1.2, 0.24, 0.14, -0.02), (-0.8, 0.28, 0.24, 0.0), (-0.2, 0.26, 0.25, 0.0),
            (0.5, 0.17, 0.18, 0.01), (1.0, 0.07, 0.09, 0.02), (1.25, 0.04, 0.05, 0.02)]
plain_fish(kit, STATIONS, skin, BLUE, BLUE, srgb(0.1, 0.12, 0.15), eye=0.03, eye_at=-1.0, tail=(0.4, 0.4),
           dorsal=(0.7, 0.85, 0.07), anal=(0.0, 0.0, 0.0), pectoral=0.3, flukes=True, pelvics=False, around=28, rows=61, thick=0.05)
kit.finish(sys.argv[sys.argv.index("--") + 1])
