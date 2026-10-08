"""Blue-tongued skink (Tiliqua scincoides).

What makes it one: a heavy sausage of a lizard with a big wedge of a head and legs far too
small for it; smooth overlapping scales; grey-tan with broad dark brown bands across the back
and tail; and a tongue that is cobalt blue, which it sticks out, flat and wide, at anything
that worries it.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import lizard

kit = Kit("blue_tongue")
TAN, BAND, BELLY, BLUE, LEG = srgb(0.72, 0.64, 0.5), srgb(0.3, 0.2, 0.14), srgb(0.9, 0.86, 0.74), srgb(0.1, 0.25, 0.9), srgb(0.62, 0.54, 0.42)


def skin(t, up, side):
    if up < -0.4:
        return BELLY
    return BAND if t > 0.24 and int(t * 18.0) % 3 == 0 else TAN


STATIONS = [(-1.2, 0.09, 0.05, 0.2), (-1.05, 0.22, 0.12, 0.21), (-0.85, 0.24, 0.15, 0.22), (-0.65, 0.2, 0.15, 0.22),
            (-0.2, 0.27, 0.19, 0.22), (0.3, 0.26, 0.18, 0.21), (0.6, 0.17, 0.13, 0.18), (0.95, 0.09, 0.08, 0.13), (1.2, 0.02, 0.02, 0.1)]
lizard(kit, STATIONS, skin, LEG, TAN, srgb(0.5, 0.35, 0.2), eye=0.05, eye_z=-0.95, shoulders=-0.55, hips=0.4, reach=0.2)
# the tongue: out, flat and wide
kit.fin([(-0.06, 0.18, -1.22), (0.06, 0.18, -1.22)], [(-0.08, 0.14, -1.42), (0.08, 0.14, -1.42)], lambda u, v: BLUE, rows=2, thick=0.03, line=0.6)
kit.finish(sys.argv[sys.argv.index("--") + 1])
