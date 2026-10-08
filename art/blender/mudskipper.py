"""Mudskipper (Periophthalmus barbarus).

What makes it one: a fish that lives out of the water: eyes on top of its head, standing up
like a frog's, close together, which it pulls down to wet them; pectoral fins like arms, with
an elbow, which it walks on; a first dorsal fin like a sail, which it raises at rivals, edged
in blue; a long tapering body, mud brown with pale blue speckles; a mouth that turns down.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import fork_tail, one

kit = Kit("mudskipper")
MUD, DARK, BELLY, SPECK, SAIL, BLUE = srgb(0.5, 0.4, 0.28), srgb(0.3, 0.23, 0.16), srgb(0.86, 0.8, 0.66), srgb(0.5, 0.8, 0.95), srgb(0.36, 0.3, 0.26), srgb(0.2, 0.55, 1.0)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.4:
        return BELLY
    if chance(int(t * 30.0), int(up * 5.0) + side) < 0.16:
        return SPECK
    return DARK if int(t * 9.0) % 3 == 0 and up > 0.3 else MUD


# propped up at the front on its arms, tail on the ground
STATIONS = [(-1.0, 0.1, 0.09, 0.34), (-0.85, 0.2, 0.17, 0.34), (-0.6, 0.2, 0.19, 0.3), (-0.2, 0.17, 0.16, 0.24),
            (0.3, 0.12, 0.12, 0.17), (0.7, 0.07, 0.09, 0.12), (0.95, 0.04, 0.07, 0.1)]
kit.body(STATIONS, 14, skin, rows=31)
fork_tail(kit, 0.93, 0.1, 0.06, 0.35, 0.0, lambda u, v: DARK if v > 0.7 else MUD)
# the sail: tall, at the front of the back, edged in blue
root = [(0.0, kit.top(z) - 0.02, z) for z in (-0.5, -0.4, -0.3, -0.2, -0.1)]
rim = [(0.0, kit.top(-0.5) + 0.3, -0.52), (0.0, kit.top(-0.4) + 0.42, -0.36), (0.0, kit.top(-0.3) + 0.4, -0.2),
       (0.0, kit.top(-0.2) + 0.28, -0.06), (0.0, kit.top(-0.1) + 0.05, 0.0)]
kit.fin(root, rim, lambda u, v: BLUE if v > 0.8 else SAIL, rows=4, thick=0.02)
# the second dorsal fin, long and low
root = [(0.0, kit.top(z) - 0.02, z) for z in (0.15, 0.35, 0.55, 0.75)]
rim = [(0.0, kit.top(0.15) + 0.12, 0.2), (0.0, kit.top(0.35) + 0.14, 0.42), (0.0, kit.top(0.55) + 0.12, 0.64), (0.0, kit.top(0.75) + 0.03, 0.8)]
kit.fin(root, rim, lambda u, v: BLUE if v > 0.75 else SAIL, rows=2, thick=0.02)
for sx in (-1.0, 1.0):
    # eyes on top, close together, each in a bump of its own
    kit.blob((sx * 0.085, 0.56, -0.82), (0.085, 0.1, 0.09), one(MUD), around=8, rows=5)
    kit.eye((sx * 0.15, 0.6, -0.86), (sx, 0.3, -0.5), 0.065, srgb(0.85, 0.75, 0.4))
    # an arm: out from behind the gills to an elbow, down to the ground, and a fan of a hand
    elbow = (sx * 0.36, 0.2, -0.55)
    wrist = (sx * 0.4, 0.03, -0.72)
    kit.tube([(sx * 0.17, 0.28, -0.6), elbow, wrist], [0.07, 0.06, 0.045], one(MUD), around=6, line=0.8)
    hand_root = [(wrist[0] - sx * 0.03, 0.03, wrist[2]), (wrist[0] + sx * 0.03, 0.03, wrist[2])]
    hand_rim = [(wrist[0] - sx * 0.06, 0.012, wrist[2] - 0.2), (wrist[0] + sx * 0.14, 0.012, wrist[2] - 0.16)]
    kit.fin(hand_root, hand_rim, lambda u, v: DARK, rows=2, thick=0.02, line=0.5)
kit.finish(sys.argv[sys.argv.index("--") + 1])
