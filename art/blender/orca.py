"""Orca (Orcinus orca).

What makes it one: black above and white below, with the white coming up in a lobe behind the
flipper; an oval white patch behind and above each eye; a grey saddle behind the dorsal fin; a
tall straight dorsal fin; round paddle flippers; a blunt round head with no beak; and flukes
that lie flat, because it is a whale.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("orca")
BLACK, WHITE, SADDLE = srgb(0.05, 0.05, 0.07), srgb(0.97, 0.97, 0.96), srgb(0.45, 0.47, 0.5)


def skin(t, up, side):
    # the eye patch, the belly with its lobe up the flank, and the saddle
    if ((t - 0.19) / 0.07) ** 2 + ((up - 0.28) / 0.16) ** 2 < 1.0:
        return WHITE
    if up < -0.45 or ((t - 0.66) / 0.13) ** 2 + ((up + 0.4) / 0.42) ** 2 < 1.0:
        return WHITE
    if ((t - 0.57) / 0.08) ** 2 + ((up - 0.62) / 0.24) ** 2 < 1.0:
        return SADDLE
    return BLACK


STATIONS = [(-1.1, 0.12, 0.12, -0.02), (-0.95, 0.24, 0.24, 0.0), (-0.6, 0.31, 0.33, 0.01), (-0.1, 0.31, 0.34, 0.01),
            (0.4, 0.2, 0.24, 0.02), (0.75, 0.09, 0.11, 0.02), (0.95, 0.05, 0.06, 0.02)]
plain_fish(kit, STATIONS, skin, BLACK, BLACK, srgb(0.1, 0.1, 0.12), eye=0.035, eye_at=-0.88, tail=(0.42, 0.45),
           dorsal=(-0.3, 0.0, 0.6), anal=(0.0, 0.0, 0.0), pectoral=0.34, flukes=True, pelvics=False, around=28, rows=61, thick=0.05)
kit.finish(sys.argv[sys.argv.index("--") + 1])
