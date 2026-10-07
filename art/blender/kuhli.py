"""Kuhli loach (Pangio kuhlii).

What makes it a kuhli and has to survive the cartooning:
  a body like an eel's: ten times as long as it is deep, the same depth nearly all the way
  a dozen or so broad dark bars on salmon pink, the bars wider than the gaps, a pale belly
  a small head with the eyes set high, and a dark bar through each eye
  barbels round a mouth on the underside: three pairs, short
  a small dorsal fin set far back, past the middle; a small rounded tail
  no visible scales
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("kuhli")

BAR = srgb(0.20, 0.10, 0.07)
PINK = srgb(0.95, 0.62, 0.42)
BELLY = srgb(0.98, 0.82, 0.68)
FIN = srgb(0.86, 0.70, 0.52)
EDGE = srgb(0.97, 0.88, 0.74)
IRIS = srgb(0.92, 0.75, 0.40)

STATIONS = [
    (-1.15, 0.03, 0.03, -0.01),
    (-1.05, 0.065, 0.07, 0.0),
    (-0.85, 0.08, 0.095, 0.0),
    (-0.4, 0.085, 0.105, 0.0),
    (0.1, 0.085, 0.105, 0.0),
    (0.6, 0.075, 0.10, 0.0),
    (0.9, 0.05, 0.085, 0.0),
    (1.05, 0.03, 0.07, 0.0),
]


def skin(t, up, side):
    if up < -0.6:
        return BELLY
    # thirteen bars, each wider than the gap after it; the first runs through the eye
    along = t * 13.0
    return BAR if (along - math.floor(along)) < 0.62 else PINK


kit.body(STATIONS, 12, skin, rows=53, squareness=2.0)


def plain(u, v):
    return EDGE if v > 0.7 else FIN


# the tail: small and round
N = 9
root, rim = [], []
for i in range(N):
    a = (0.5 - i / (N - 1)) * 2.6
    root.append((0.0, math.sin(a) * 0.06, 1.05))
    rim.append((0.0, math.sin(a) * 0.17, 1.05 + 0.08 + math.cos(a) * 0.2))
kit.fin(root, rim, plain, rows=3, thick=0.02)

# the dorsal fin: small, and well past the middle
root = [(0.0, kit.top(z) - 0.02, z) for z in (0.35, 0.45, 0.55, 0.65)]
rim = [(0.0, kit.top(0.4) + 0.05, 0.42), (0.0, kit.top(0.5) + 0.12, 0.56), (0.0, kit.top(0.6) + 0.11, 0.68), (0.0, kit.top(0.65) + 0.03, 0.72)]
kit.fin(root, rim, plain, rows=2, thick=0.02)

# the anal fin, under it and a little further back
root = [(0.0, kit.bottom(z) + 0.02, z) for z in (0.6, 0.7, 0.8)]
rim = [(0.0, kit.bottom(0.65) - 0.06, 0.68), (0.0, kit.bottom(0.75) - 0.09, 0.8), (0.0, kit.bottom(0.8) - 0.03, 0.86)]
kit.fin(root, rim, plain, rows=2, thick=0.02)

for sx in (-1.0, 1.0):
    # a pectoral fin, low behind the head
    at = (kit.side(-0.82, sx), kit.bottom(-0.82) + 0.05, -0.82)
    root = [(at[0], at[1] + dy, at[2]) for dy in (-0.02, 0.0, 0.02)]
    rim = [(at[0] + sx * 0.1, at[1] - 0.08, at[2] + 0.1), (at[0] + sx * 0.14, at[1] - 0.05, at[2] + 0.14), (at[0] + sx * 0.1, at[1], at[2] + 0.15)]
    kit.fin(root, rim, plain, rows=2, thick=0.015)
    # three barbels a side, round the mouth
    for k, (dy, dz, out) in enumerate(((-0.05, -0.05, 0.03), (-0.07, 0.0, 0.05), (-0.06, 0.04, 0.07))):
        base = (sx * 0.03, kit.bottom(-1.08) + 0.02, -1.1 + k * 0.03)
        root = [(base[0], base[1], base[2] - 0.008), (base[0], base[1], base[2] + 0.008)]
        rim = [(base[0] + sx * out, base[1] + dy, base[2] + dz - 0.004), (base[0] + sx * out, base[1] + dy, base[2] + dz + 0.004)]
        kit.fin(root, rim, lambda u, v: EDGE, rows=2, thick=0.012, line=0.4)
    kit.eye((kit.side(-1.0, sx, 0.9), kit.top(-1.0) - 0.035, -1.0), (sx, 0.5, -0.1), 0.035, IRIS)

kit.finish(sys.argv[sys.argv.index("--") + 1])
