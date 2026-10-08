"""Celestial pearl danio (Danio margaritatus), the galaxy rasbora.

What makes it one: a very small, stocky fish; deep blue-black sides scattered with round pearly
spots, like stars; a red-orange belly; fins striped red and black, with a clear edge.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("pearl_danio")
NIGHT, PEARL, RED, BLACK = srgb(0.1, 0.18, 0.32), srgb(0.98, 0.92, 0.72), srgb(0.9, 0.3, 0.12), srgb(0.06, 0.06, 0.08)
CLEAR = (0.9, 0.9, 0.85, 0.6)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.55 and t > 0.15:
        return RED
    return PEARL if t > 0.2 and chance(int(t * 26.0), int(up * 6.0) + side) < 0.22 else NIGHT


STATIONS = [(-0.9, 0.04, 0.05, 0.0), (-0.8, 0.1, 0.13, 0.0), (-0.5, 0.15, 0.24, 0.0), (-0.1, 0.16, 0.26, 0.0),
            (0.35, 0.11, 0.19, 0.0), (0.65, 0.06, 0.12, 0.0), (0.8, 0.04, 0.1, 0.0)]
plain_fish(kit, STATIONS, skin, RED, BLACK, srgb(0.9, 0.8, 0.5), eye=0.07, eye_at=-0.75, tail=(0.36, 0.45),
           dorsal=(0.0, 0.3, 0.24), anal=(0.15, 0.45, 0.2), pectoral=0.15)
kit.finish(sys.argv[sys.argv.index("--") + 1])
