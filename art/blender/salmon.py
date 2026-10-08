"""Sockeye salmon (Oncorhynchus nerka), as it is at sea.

What makes it one: the plain shape every fish is drawn from: slim, pointed at both ends, with a
small head; steel blue-green on the back, bright silver on the sides, white below; fine black
speckles along the back; a small fleshy fin (the adipose) between the dorsal and the tail,
which only salmon and their kin have; a tail forked a little.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("salmon")
BACK, SILVER, WHITE, SPECK, FIN = srgb(0.12, 0.3, 0.42), srgb(0.78, 0.84, 0.9), srgb(0.97, 0.98, 0.99), srgb(0.05, 0.08, 0.1), srgb(0.35, 0.45, 0.55)


def skin(t, up, side):
    if up > 0.5:
        return SPECK if (int(t * 50.0) * 3 + side) % 7 == 0 else BACK
    return WHITE if up < -0.55 else SILVER


STATIONS = [(-1.1, 0.04, 0.05, 0.0), (-0.95, 0.1, 0.13, 0.0), (-0.55, 0.17, 0.24, 0.0), (0.0, 0.17, 0.25, 0.0),
            (0.5, 0.11, 0.17, 0.0), (0.8, 0.055, 0.09, 0.0), (0.95, 0.04, 0.08, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.9, 0.9, 0.8), eye=0.055, eye_at=-0.92, tail=(0.42, 0.4),
           dorsal=(-0.15, 0.2, 0.22), anal=(0.35, 0.6, 0.16), pectoral=0.2)
kit.fin([(0.0, kit.top(0.55) - 0.01, 0.52), (0.0, kit.top(0.6) - 0.01, 0.6)], [(0.0, kit.top(0.55) + 0.07, 0.6), (0.0, kit.top(0.6) + 0.05, 0.66)],
        lambda u, v: FIN, rows=2, thick=0.02)
kit.finish(sys.argv[sys.argv.index("--") + 1])
