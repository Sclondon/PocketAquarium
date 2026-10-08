"""Clownfish (Amphiprion ocellaris).

What makes it one: bright orange, with three white bars, each edged in a thin line of black:
one behind the eye, one across the middle that bulges forward, one at the root of the tail;
rounded fins, all edged in black; a rounded tail; it waddles more than it swims.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("clownfish")
ORANGE, WHITE, BLACK = srgb(1.0, 0.48, 0.08), srgb(0.97, 0.97, 0.95), srgb(0.06, 0.05, 0.05)


def skin(t, up, side):
    for a, b in ((0.17, 0.25), (0.47, 0.58), (0.86, 0.93)):
        if a < t < b:
            return WHITE
        if a - 0.025 < t < b + 0.025:
            return BLACK
    return ORANGE


STATIONS = [(-0.85, 0.06, 0.07, 0.0), (-0.74, 0.14, 0.18, 0.0), (-0.45, 0.18, 0.28, 0.0), (-0.05, 0.18, 0.29, 0.0),
            (0.35, 0.12, 0.2, 0.0), (0.6, 0.07, 0.13, 0.0), (0.72, 0.05, 0.11, 0.0)]
plain_fish(kit, STATIONS, skin, ORANGE, BLACK, srgb(0.95, 0.6, 0.2), eye=0.07, eye_at=-0.68, tail=(0.36, 0.05),
           dorsal=(-0.4, 0.45, 0.17), anal=(0.15, 0.5, 0.15), pectoral=0.2)
kit.finish(sys.argv[sys.argv.index("--") + 1])
