"""Goldfish (Carassius auratus), a common one.

What makes it one: a deep, thick-set body, orange-gold all over and paler under the belly; a
long dorsal fin along most of the back; a tail forked into two rounded lobes; a small mouth
with no barbels (a koi has them); big scales.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("goldfish")
BACK, GOLD, BELLY, FIN, EDGE = srgb(0.92, 0.4, 0.08), srgb(1.0, 0.58, 0.12), srgb(1.0, 0.82, 0.5), srgb(1.0, 0.55, 0.15), srgb(1.0, 0.9, 0.6)


def skin(t, up, side):
    if up > 0.6:
        return BACK
    return BELLY if up < -0.6 else GOLD


STATIONS = [(-0.9, 0.06, 0.07, 0.0), (-0.78, 0.16, 0.19, 0.0), (-0.45, 0.25, 0.34, 0.0), (0.0, 0.26, 0.36, 0.0),
            (0.4, 0.17, 0.25, 0.0), (0.65, 0.09, 0.14, 0.0), (0.8, 0.06, 0.11, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, EDGE, srgb(0.95, 0.9, 0.7), eye=0.08, eye_at=-0.7, tail=(0.6, 0.45),
           dorsal=(-0.45, 0.45, 0.24), anal=(0.25, 0.55, 0.18), pectoral=0.22)
kit.finish(sys.argv[sys.argv.index("--") + 1])
