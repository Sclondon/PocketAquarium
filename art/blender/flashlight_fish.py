"""Flashlight fish (Anomalops katoptron).

What makes it one: a small, stout, black fish with a row of pale dots along its side; and under
each eye a bean-shaped organ full of glowing bacteria, the brightest light any fish carries,
blue-white, which it turns over to blink; two dorsal fins and a forked tail, edged in pale blue.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("flashlight_fish")
BLACK, DOT, EDGE = srgb(0.05, 0.05, 0.08), srgb(0.6, 0.7, 0.8), srgb(0.5, 0.75, 1.0)
g = srgb(0.7, 0.95, 1.0)
GLOW = (g[0], g[1], g[2], 1.0, 1.0)


def skin(t, up, side):
    # the light, under the eye
    if 0.1 < t < 0.24 and -0.25 < up < 0.25:
        return GLOW
    if 0.5 < up < 0.6 and t > 0.3 and int(t * 28.0) % 2 == 0:
        return DOT
    return BLACK


STATIONS = [(-0.85, 0.06, 0.08, 0.0), (-0.75, 0.14, 0.2, 0.0), (-0.45, 0.18, 0.3, 0.0), (0.0, 0.17, 0.29, 0.0),
            (0.4, 0.1, 0.18, 0.0), (0.65, 0.05, 0.09, 0.0), (0.78, 0.035, 0.07, 0.0)]
plain_fish(kit, STATIONS, skin, BLACK, EDGE, srgb(0.2, 0.2, 0.25), eye=0.08, eye_at=-0.6, tail=(0.36, 0.7),
           dorsal=(-0.1, 0.4, 0.2), anal=(0.2, 0.5, 0.16), pectoral=0.17)
kit.finish(sys.argv[sys.argv.index("--") + 1])
