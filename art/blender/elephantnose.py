"""Peters' elephantnose fish (Gnathonemus petersii).

What makes it one: the "trunk", which is really its chin, a long finger of flesh that curves
down and forward from under the mouth, and which it feels in the sand with; a dark brown-black
body, flat-sided, with two pale bars that cross it between the dorsal and anal fins; those two
fins set far back and the same size, one over the other; a very thin wrist before a small
forked tail. (It finds its way, and its food, with a weak electric field.)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one, plain_fish

kit = Kit("elephantnose")
DARK, BAR, FIN = srgb(0.16, 0.12, 0.14), srgb(0.8, 0.74, 0.62), srgb(0.24, 0.18, 0.2)


def skin(t, up, side):
    return BAR if (0.52 < t < 0.56 or 0.68 < t < 0.72) and abs(up) < 0.9 else DARK


STATIONS = [(-0.9, 0.05, 0.06, 0.02), (-0.78, 0.1, 0.14, 0.02), (-0.45, 0.13, 0.26, 0.0), (0.0, 0.13, 0.28, 0.0),
            (0.4, 0.09, 0.2, 0.0), (0.62, 0.035, 0.06, 0.0), (0.78, 0.025, 0.05, 0.0)]
plain_fish(kit, STATIONS, skin, FIN, FIN, srgb(0.5, 0.45, 0.4), eye=0.05, eye_at=-0.74, tail=(0.34, 0.75),
           dorsal=(0.12, 0.55, 0.2), anal=(0.12, 0.55, 0.2), pectoral=0.18)
# the trunk: from under the mouth, forward and down
kit.tube([(0.0, -0.04, -0.86), (0.0, -0.1, -1.05), (0.0, -0.2, -1.2), (0.0, -0.3, -1.27)], [0.045, 0.04, 0.032, 0.022], one(DARK), around=6)
kit.finish(sys.argv[sys.argv.index("--") + 1])
