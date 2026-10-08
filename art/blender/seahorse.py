"""Lined seahorse (Hippocampus erectus).

What makes it one: it swims upright: a head like a horse's, bent down at right angles to the
neck, with a long tube of a snout and a little crown on top; a body in bony rings, with a
round belly; a tail that curls forward and holds on to things; one small fin on its back,
which is all it swims with, and a tiny one behind each cheek; yellow-brown, with fine pale
lines along the neck and back.

Built standing up, facing forward (-z): the game does not tip it over to swim.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one

kit = Kit("seahorse")
BODY, LINE, RIDGE, FIN = srgb(0.85, 0.62, 0.2), srgb(0.98, 0.9, 0.6), srgb(0.55, 0.36, 0.12), srgb(0.95, 0.85, 0.55)


def rings(t, k):
    # bony rings all the way down, with a pale line between
    return RIDGE if int(t * 44.0) % 4 == 0 else (LINE if k in (0, 8) and t < 0.5 else BODY)


# from the crown, down the neck, out round the belly, and into the curl of the tail
path = [(0.0, 1.0, -0.1), (0.0, 0.86, 0.0), (0.0, 0.62, 0.1), (0.0, 0.36, 0.1), (0.0, 0.1, -0.02), (0.0, -0.18, -0.02),
        (0.0, -0.45, 0.1), (0.0, -0.68, 0.14)]
radii = [0.12, 0.14, 0.15, 0.2, 0.24, 0.17, 0.11, 0.08]
for i in range(1, 12):
    a = i / 11.0 * 3.6
    r = 0.24 * (1.0 - i / 14.0)
    path.append((0.0, -0.78 - math.sin(a) * r, 0.14 - (1.0 - math.cos(a)) * r))
    radii.append(0.075 * (1.0 - i / 12.5))
kit.tube(path, radii, rings, around=9)
# the head: a lump at the top, bent forward, and the long snout
kit.blob((0.0, 1.03, -0.28), (0.13, 0.15, 0.22), lambda t, up: BODY, around=10, rows=6)
kit.tube([(0.0, 0.99, -0.45), (0.0, 0.95, -0.72), (0.0, 0.94, -0.88)], [0.07, 0.055, 0.06], one(BODY), around=7)
# the crown
kit.tube([(0.0, 1.14, -0.16), (0.0, 1.27, -0.12)], [0.06, 0.035], one(RIDGE), around=5, line=0.6)
# the fin on its back
root = [(0.0, y, 0.24 + 0.05 * math.sin((0.5 - y) * 3.0)) for y in (0.5, 0.38, 0.26, 0.14)]
rim = [(0.0, p[1] + 0.02, p[2] + 0.2) for p in root]
kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.02)
for sx in (-1.0, 1.0):
    kit.eye((sx * 0.125, 1.07, -0.34), (sx, 0.1, -0.2), 0.055, srgb(0.95, 0.8, 0.3))
    kit.fin([(sx * 0.12, 0.98, -0.2), (sx * 0.12, 0.9, -0.2)], [(sx * 0.24, 1.0, -0.14), (sx * 0.24, 0.9, -0.12)], lambda u, v: FIN, rows=2, thick=0.015)
kit.finish(sys.argv[sys.argv.index("--") + 1])
