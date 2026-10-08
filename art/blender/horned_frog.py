"""Argentine horned frog (Ceratophrys ornata), the "Pacman" frog.

What makes it one: nearly a ball, and most of the ball is mouth, which runs right round the
front of it; a point of skin like a horn over each eye; bright green, with big dark red-brown
blotches edged in black, and a cream belly; short legs it hardly uses.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import frog, one

kit = Kit("horned_frog")
GREEN, BLOTCH, CREAM, MOUTH, LEG = srgb(0.42, 0.72, 0.16), srgb(0.36, 0.14, 0.08), srgb(0.95, 0.9, 0.7), srgb(0.2, 0.1, 0.08), srgb(0.5, 0.62, 0.2)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.45:
        return CREAM
    # the mouth: a dark line round the front half, just under the middle
    if t < 0.5 and -0.3 < up < 0.0:
        return MOUTH
    if up > 0.0 and chance(int(t * 7.0), int(up * 3.0) + side * 2) < 0.4:
        return BLOTCH
    return GREEN


STATIONS = [(-0.85, 0.3, 0.14, 0.33), (-0.7, 0.5, 0.26, 0.36), (-0.3, 0.58, 0.34, 0.37), (0.15, 0.55, 0.33, 0.36),
            (0.5, 0.36, 0.24, 0.3), (0.7, 0.14, 0.1, 0.24)]
frog(kit, STATIONS, skin, LEG, CREAM, srgb(0.85, 0.6, 0.2), eye=0.1, eye_z=-0.5, wide=0.7)
# the horns: a point over each eye
for sx in (-1.0, 1.0):
    kit.tube([(sx * 0.34, 0.76, -0.5), (sx * 0.4, 0.95, -0.46)], [0.07, 0.01], one(GREEN), around=5, line=0.7)
kit.finish(sys.argv[sys.argv.index("--") + 1])
