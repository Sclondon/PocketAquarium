"""Black ghost knifefish (Apteronotus albifrons).

What makes it one: the shape of a knife blade: deep at the head, tapering to a point, with no
dorsal fin and no proper tail, only a small tip; one long fin along the whole underside, which
ripples, and which is all it swims with, forward or backward alike; black all over, with a
white blaze down the nose and two white rings round the tail.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("knifefish")
BLACK, WHITE = srgb(0.05, 0.05, 0.07), srgb(0.96, 0.96, 0.92)
FIN = srgb(0.12, 0.12, 0.16)


def skin(t, up, side):
    if t < 0.16 and up > 0.8:
        return WHITE
    if 0.84 < t < 0.87 or 0.92 < t < 0.95:
        return WHITE
    return BLACK


STATIONS = [(-1.1, 0.04, 0.05, 0.05), (-1.0, 0.1, 0.14, 0.03), (-0.75, 0.14, 0.27, 0.0), (-0.3, 0.13, 0.27, 0.0),
            (0.2, 0.1, 0.2, 0.02), (0.7, 0.06, 0.11, 0.05), (1.05, 0.03, 0.05, 0.08), (1.25, 0.015, 0.025, 0.09)]
kit.body(STATIONS, 14, skin, rows=41)
# the one long fin underneath, rippling from the throat to the tail
N = 21
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = -0.75 + 1.9 * u
    root.append((0.0, kit.bottom(z) + 0.02, z))
    rim.append((0.0, kit.bottom(z) - 0.17 * math.sin(math.pi * (0.06 + 0.9 * u)) ** 0.5, z + 0.03))
kit.fin(root, rim, lambda u, v: FIN, rows=3, thick=0.02, wave=0.06)
# the tip of the tail
kit.fin([(0.0, 0.11, 1.24), (0.0, 0.07, 1.24)], [(0.0, 0.15, 1.36), (0.0, 0.03, 1.36)], lambda u, v: WHITE if v > 0.6 else BLACK, rows=2, thick=0.015)
for sx in (-1.0, 1.0):
    at = (kit.side(-0.8, sx), 0.0, -0.8)
    root = [(at[0], at[1] + dy, at[2]) for dy in (-0.04, 0.0, 0.04)]
    rim = [(at[0] + sx * 0.12, at[1] - 0.12, at[2] + 0.14), (at[0] + sx * 0.18, at[1], at[2] + 0.2), (at[0] + sx * 0.12, at[1] + 0.1, at[2] + 0.16)]
    kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.015)
    kit.eye((kit.side(-1.0, sx, 0.95), 0.07, -1.0), (sx, 0.1, -0.2), 0.035, srgb(0.3, 0.3, 0.35))
kit.finish(sys.argv[sys.argv.index("--") + 1])
