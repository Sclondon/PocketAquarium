"""Atlantic bluefin tuna (Thunnus thynnus).

What makes it one: a torpedo: deepest a third of the way back and tapering to a wrist no
thicker than a thumb, with a keel on each side of it; a tail like a crescent moon, stiff and
tall; dark blue-black above, silver on the sides, white below; a row of small yellow finlets
from the second dorsal and the anal fin back to the tail; fins it folds into grooves at speed.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("tuna")
BLUE, SILVER, WHITE, FIN, YELLOW = srgb(0.06, 0.13, 0.35), srgb(0.66, 0.74, 0.82), srgb(0.95, 0.96, 0.98), srgb(0.12, 0.18, 0.4), srgb(1.0, 0.85, 0.2)


def skin(t, up, side):
    if up > 0.4:
        return BLUE
    return WHITE if up < -0.5 else SILVER


STATIONS = [(-1.05, 0.04, 0.05, 0.0), (-0.9, 0.14, 0.17, 0.0), (-0.5, 0.25, 0.32, 0.0), (0.0, 0.24, 0.31, 0.0),
            (0.5, 0.13, 0.17, 0.0), (0.8, 0.04, 0.05, 0.0), (0.92, 0.03, 0.045, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.9, 0.9, 0.8), eye=0.06, eye_at=-0.85, tail=(0.5, 0.85),
           dorsal=(-0.35, -0.05, 0.3), anal=(0.25, 0.45, 0.24), pectoral=0.3, thick=0.03)
# the second dorsal fin, tall and narrow, and the finlets above and below
kit.fin([(0.0, kit.top(z) - 0.02, z) for z in (0.2, 0.3, 0.4)], [(0.0, kit.top(0.2) + 0.1, 0.3), (0.0, kit.top(0.3) + 0.34, 0.5), (0.0, kit.top(0.4) + 0.04, 0.48)],
        lambda u, v: FIN, rows=3, thick=0.03)
for i in range(5):
    z = 0.5 + i * 0.07
    for sign in (1.0, -1.0):
        edge = kit.top(z) if sign > 0 else kit.bottom(z)
        kit.fin([(0.0, edge - sign * 0.01, z), (0.0, edge - sign * 0.01, z + 0.04)], [(0.0, edge + sign * 0.07, z + 0.05), (0.0, edge + sign * 0.02, z + 0.07)],
                lambda u, v: YELLOW, rows=1, thick=0.02, line=0.5)
kit.finish(sys.argv[sys.argv.index("--") + 1])
