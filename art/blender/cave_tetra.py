"""Blind cave tetra (Astyanax mexicanus, the cave form).

What makes it one: no eyes at all, only smooth skin where they would be; no colour either, a
pinkish white all over that the blood shows through, pinker at the gills and along the back;
otherwise an ordinary deep-bodied tetra, with the small extra fin (the adipose) between the
dorsal and the tail.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("cave_tetra")
PINK, PALE, GILL = srgb(0.96, 0.74, 0.72), srgb(0.98, 0.9, 0.88), srgb(0.9, 0.5, 0.52)
FIN = (PALE[0], PALE[1], PALE[2], 0.7)


def skin(t, up, side):
    if 0.16 < t < 0.2 and abs(up) < 0.7:
        return GILL
    return PINK if up > 0.55 else PALE


STATIONS = [(-1.0, 0.035, 0.05, 0.0), (-0.9, 0.1, 0.14, 0.0), (-0.6, 0.15, 0.27, 0.0), (-0.25, 0.16, 0.31, 0.0),
            (0.2, 0.12, 0.24, 0.0), (0.6, 0.065, 0.13, 0.0), (0.82, 0.04, 0.1, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, PALE, PALE, eyes=False, eye_at=-0.82, tail=(0.42, 0.6), dorsal=(-0.2, 0.15, 0.3),
           anal=(0.1, 0.55, 0.2), pectoral=0.18)
# the adipose fin: a small flag between the dorsal and the tail
kit.fin([(0.0, kit.top(0.45) - 0.01, 0.42), (0.0, kit.top(0.5) - 0.01, 0.5)], [(0.0, kit.top(0.45) + 0.07, 0.5), (0.0, kit.top(0.5) + 0.05, 0.56)],
        lambda u, v: FIN, rows=2, thick=0.015)
kit.finish(sys.argv[sys.argv.index("--") + 1])
