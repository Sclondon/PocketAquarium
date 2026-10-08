"""Pea puffer (Carinotetraodon travancoricus), the dwarf puffer.

What makes it one: a fish the size and shape of a pea with a tail; big eyes that move one at a
time, set high; a small beak of a mouth; yellow-green above with dark green-black blotches,
and a clean white belly; small clear fins set far back, which it hovers on like a helicopter.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("pea_puffer")
GREEN, BLOTCH, WHITE = srgb(0.72, 0.72, 0.2), srgb(0.12, 0.2, 0.1), srgb(0.98, 0.97, 0.9)
FIN = (0.8, 0.85, 0.6, 0.6)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.2:
        return WHITE
    return BLOTCH if chance(int(t * 9.0), int(up * 4.0) + side) < 0.38 else GREEN


STATIONS = [(-0.75, 0.08, 0.09, 0.0), (-0.65, 0.2, 0.2, 0.0), (-0.35, 0.33, 0.33, 0.0), (0.05, 0.34, 0.33, 0.0),
            (0.4, 0.2, 0.2, 0.01), (0.62, 0.08, 0.09, 0.02), (0.75, 0.05, 0.07, 0.02)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.95, 0.75, 0.3), eye=0.13, eye_at=-0.5, tail=(0.3, 0.0),
           dorsal=(0.25, 0.5, 0.14), anal=(0.3, 0.52, 0.12), pectoral=0.16)
kit.finish(sys.argv[sys.argv.index("--") + 1])
