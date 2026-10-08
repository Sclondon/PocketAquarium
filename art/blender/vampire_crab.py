"""Vampire crab (Geosesarma dennerle).

What makes it one: a small land crab with a square shell, deep purple, paler on the back; bright
yellow eyes on short stalks, which are what it is named for; purple claws, one a little bigger;
four walking legs a side, jointed and pointed.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import one

kit = Kit("vampire_crab")
PURPLE, PALE, CLAW, EYE = srgb(0.36, 0.12, 0.5), srgb(0.72, 0.6, 0.8), srgb(0.55, 0.25, 0.7), srgb(1.0, 0.85, 0.1)

# the shell: wide, squarish, and low; it walks sideways, but faces -z like everything else
kit.blob((0.0, 0.34, 0.0), (0.55, 0.2, 0.45), lambda t, up: PALE if up > 0.5 and 0.25 < t < 0.75 else PURPLE, around=12, rows=8)
for sx in (-1.0, 1.0):
    # eyes on stalks, at the front corners
    kit.tube([(sx * 0.25, 0.42, -0.4), (sx * 0.28, 0.6, -0.46)], [0.035, 0.03], one(PURPLE), around=5, line=0.6)
    kit.blob((sx * 0.28, 0.64, -0.47), (0.06, 0.06, 0.06), one(EYE), around=6, rows=4, part=3.0)
    # a claw: an arm out and forward, and a fat hand with two fingers
    big = 1.25 if sx > 0 else 1.0
    kit.tube([(sx * 0.4, 0.3, -0.3), (sx * 0.62, 0.26, -0.5), (sx * 0.5, 0.22, -0.72)], [0.07, 0.07, 0.06], one(CLAW), around=6, line=0.8)
    kit.blob((sx * 0.45, 0.22, -0.84), (0.1 * big, 0.11 * big, 0.16 * big), one(CLAW), around=8, rows=5)
    kit.tube([(sx * 0.45, 0.28, -0.95), (sx * 0.4, 0.3, -1.12 * big)], [0.045, 0.012], one(PALE), around=5, line=0.6)
    kit.tube([(sx * 0.45, 0.17, -0.95), (sx * 0.42, 0.16, -1.1 * big)], [0.04, 0.012], one(PALE), around=5, line=0.6)
    # four legs: out, up to a knee, and down to a point
    for k in range(4):
        a = -0.5 + k * 0.42
        out = (sx * math.cos(a), math.sin(a))
        hip = (sx * 0.42, 0.3, a * 0.5)
        knee = (out[0] * 0.95, 0.46, out[1] * 0.75 + a * 0.2)
        foot = (out[0] * 1.2, 0.0, out[1] * 0.95 + a * 0.2)
        kit.tube([hip, knee, foot], [0.06, 0.045, 0.012], one(PURPLE), around=5, line=0.7)
kit.finish(sys.argv[sys.argv.index("--") + 1])
