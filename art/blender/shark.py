"""Blacktip reef shark (Carcharhinus melanopterus).

What makes it one: the shark shape: a pointed snout with the mouth underneath, five gill slits,
a tall first dorsal fin, long pectoral fins held out like wings, and a tail whose top lobe is
much the longer; grey-brown above and white below, with a sharp line between; and a black tip
on every fin, the dorsal's set off by a pale band under it.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("shark")
GREY, WHITE, BLACK, GILL = srgb(0.5, 0.52, 0.52), srgb(0.96, 0.96, 0.95), srgb(0.07, 0.07, 0.08), srgb(0.3, 0.32, 0.33)


def skin(t, up, side):
    if up < -0.1:
        return WHITE
    if 0.2 < t < 0.3 and -0.1 < up < 0.5 and int(t * 60.0) % 2 == 0:
        return GILL
    return GREY


STATIONS = [(-1.2, 0.03, 0.03, 0.0), (-1.05, 0.13, 0.1, 0.0), (-0.75, 0.21, 0.2, 0.01), (-0.3, 0.22, 0.24, 0.02),
            (0.25, 0.16, 0.19, 0.02), (0.7, 0.08, 0.1, 0.03), (0.98, 0.04, 0.06, 0.05)]
kit.body(STATIONS, 16, skin, rows=37, squareness=2.1)
tip = lambda u, v: BLACK if v > 0.72 else (WHITE if v > 0.6 else GREY)
# the tail: the top lobe long and swept, the bottom one short
kit.fin([(0.0, 0.09, 0.96), (0.0, 0.05, 0.98), (0.0, 0.01, 0.96)], [(0.0, 0.62, 1.5), (0.0, 0.16, 1.2), (0.0, -0.22, 1.18)], tip, rows=4, thick=0.04)
# the dorsal fin, and the small second one
kit.fin([(0.0, kit.top(z) - 0.03, z) for z in (-0.4, -0.25, -0.1)], [(0.0, kit.top(-0.4) + 0.12, -0.3), (0.0, kit.top(-0.25) + 0.42, -0.02), (0.0, kit.top(-0.1) + 0.04, 0.06)],
        tip, rows=4, thick=0.05)
kit.fin([(0.0, kit.top(z) - 0.02, z) for z in (0.5, 0.6)], [(0.0, kit.top(0.5) + 0.12, 0.64), (0.0, kit.top(0.6) + 0.02, 0.7)], tip, rows=2, thick=0.03)
kit.fin([(0.0, kit.bottom(z) + 0.02, z) for z in (0.5, 0.6)], [(0.0, kit.bottom(0.5) - 0.1, 0.66), (0.0, kit.bottom(0.6) - 0.02, 0.7)], tip, rows=2, thick=0.03)
for sx in (-1.0, 1.0):
    at = (kit.side(-0.55, sx, 0.8), -0.12, -0.55)
    kit.fin([(at[0], at[1], at[2] - 0.1), (at[0], at[1], at[2]), (at[0], at[1], at[2] + 0.12)],
            [(at[0] + sx * 0.3, at[1] - 0.2, at[2] + 0.2), (at[0] + sx * 0.5, at[1] - 0.3, at[2] + 0.42), (at[0] + sx * 0.12, at[1] - 0.06, at[2] + 0.3)], tip, rows=4, thick=0.04)
    kit.eye((kit.side(-1.0, sx, 0.96), 0.03, -1.0), (sx, 0.1, -0.2), 0.04, srgb(0.8, 0.8, 0.7))
kit.finish(sys.argv[sys.argv.index("--") + 1])
