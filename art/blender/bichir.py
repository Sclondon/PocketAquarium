"""Senegal bichir (Polypterus senegalus), the "dinosaur eel".

What makes it one: a long grey-olive body like a snake's, armoured in hard diamond scales; a
row of eight to ten separate little fins down its back, each a flag on its own spine, in place
of one dorsal fin; a broad flat head with two short tubes for nostrils sticking out in front;
pectoral fins like fleshy paddles on stalks, which it props itself up and walks on; a rounded
tail; a pale belly.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one

kit = Kit("bichir")
OLIVE, DARK, BELLY, FIN = srgb(0.5, 0.52, 0.4), srgb(0.36, 0.38, 0.3), srgb(0.9, 0.88, 0.76), srgb(0.6, 0.6, 0.48)


def skin(t, up, side):
    if up < -0.4:
        return BELLY
    # diamond scales, as a faint chequer
    return DARK if (int(t * 44.0) + int((up + 1.0) * 4.0)) % 2 == 0 and up > 0.2 else OLIVE


STATIONS = [(-1.25, 0.1, 0.05, 0.12), (-1.1, 0.17, 0.09, 0.13), (-0.9, 0.16, 0.11, 0.14), (-0.5, 0.14, 0.13, 0.14),
            (0.2, 0.13, 0.13, 0.14), (0.8, 0.09, 0.11, 0.14), (1.15, 0.04, 0.09, 0.14)]
kit.body(STATIONS, 12, skin, rows=47, squareness=2.2)
# the finlets: a row of small flags down the back
for i in range(9):
    z = -0.2 + i * 0.14
    kit.fin([(0.0, kit.top(z) - 0.01, z), (0.0, kit.top(z + 0.07) - 0.01, z + 0.07)],
            [(0.0, kit.top(z) + 0.1, z + 0.05), (0.0, kit.top(z + 0.07) + 0.05, z + 0.12)], lambda u, v: FIN, rows=1, thick=0.015, line=0.5)
# the tail: rounded, running into the last of the back
N = 9
root, rim = [], []
for i in range(N):
    a = (0.5 - i / (N - 1)) * 2.8
    root.append((0.0, 0.14 + math.sin(a) * 0.08, 1.13))
    rim.append((0.0, 0.14 + math.sin(a) * 0.2, 1.13 + 0.1 + math.cos(a) * 0.22))
kit.fin(root, rim, lambda u, v: FIN, rows=3, thick=0.02)
for sx in (-1.0, 1.0):
    # nostril tubes
    kit.tube([(sx * 0.05, 0.13, -1.27), (sx * 0.06, 0.14, -1.37)], [0.014, 0.012], one(DARK), around=4, line=0.4)
    # a pectoral fin: a fleshy stalk, and a fan on the end of it, down to the ground
    stalk = (sx * 0.3, 0.06, -0.86)
    kit.tube([(sx * 0.14, 0.12, -0.85), stalk], [0.05, 0.04], one(OLIVE), around=5, line=0.7)
    kit.fin([(stalk[0], 0.09, stalk[2] - 0.02), (stalk[0], 0.03, stalk[2] + 0.02)],
            [(stalk[0] + sx * 0.16, 0.14, stalk[2] + 0.08), (stalk[0] + sx * 0.14, 0.01, stalk[2] + 0.16)], lambda u, v: FIN, rows=2, thick=0.02)
    kit.eye((sx * 0.14, 0.2, -1.08), (sx, 0.6, -0.2), 0.035, srgb(0.85, 0.75, 0.4))
kit.finish(sys.argv[sys.argv.index("--") + 1])
