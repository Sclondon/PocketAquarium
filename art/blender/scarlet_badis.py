"""Scarlet badis (Dario dario).

What makes it one: no bigger than a thumbnail; a male is bright red with seven or so vertical
bars of pale blue-silver along his sides; a long dorsal fin that runs most of his back, red
edged in pale blue; pelvic fins long and blue-white, which he shows off with.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("scarlet_badis")
RED, BAR, BLUE = srgb(0.88, 0.14, 0.1), srgb(0.75, 0.86, 0.95), srgb(0.55, 0.8, 1.0)


def skin(t, up, side):
    if t < 0.2:
        return RED
    return BAR if int(t * 16.0) % 2 == 0 and abs(up) < 0.8 else RED


STATIONS = [(-0.9, 0.04, 0.05, 0.0), (-0.8, 0.11, 0.14, 0.0), (-0.5, 0.16, 0.25, 0.0), (-0.1, 0.16, 0.26, 0.0),
            (0.35, 0.12, 0.2, 0.0), (0.65, 0.07, 0.14, 0.0), (0.8, 0.045, 0.11, 0.0)]
plain_fish(kit, STATIONS, skin, RED, BLUE, srgb(0.95, 0.6, 0.3), eye=0.075, eye_at=-0.74, tail=(0.34, 0.1),
           dorsal=(-0.45, 0.5, 0.2), anal=(0.1, 0.5, 0.18), pectoral=0.15)
kit.finish(sys.argv[sys.argv.index("--") + 1])
