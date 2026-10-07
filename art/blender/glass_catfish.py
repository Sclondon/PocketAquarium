"""Glass catfish (Kryptopterus vitreolus).

What makes it a glass catfish and has to survive the cartooning:
  a body you can see through: the spine and its ribs show as a dark line with a comb under it
  a silver sac just behind the head, which is the only solid-looking part (it holds the organs)
  a body pressed flat from side to side, deepest at the sac and tapering evenly to the tail
  an anal fin that runs from behind the sac nearly to the tail, low and even
  no dorsal fin to speak of: one tiny ray
  a deeply forked tail
  two long barbels pointing forward from the upper lip
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("glass_catfish")


def glass(r, g, b, a):
    c = srgb(r, g, b)
    return (c[0], c[1], c[2], a)


CLEAR = glass(0.62, 0.80, 0.86, 0.35)
SPINE = srgb(0.16, 0.20, 0.26)
SAC = srgb(0.86, 0.90, 0.94)
HEAD = srgb(0.55, 0.66, 0.72)
FIN = glass(0.70, 0.86, 0.92, 0.45)
EDGE = glass(0.90, 0.96, 1.0, 0.7)
IRIS = srgb(0.85, 0.88, 0.92)

STATIONS = [
    (-1.10, 0.03, 0.04, 0.03),
    (-1.00, 0.075, 0.11, 0.02),
    (-0.80, 0.105, 0.21, 0.0),
    (-0.55, 0.105, 0.25, -0.01),
    (-0.2, 0.09, 0.22, 0.0),
    (0.2, 0.07, 0.17, 0.01),
    (0.6, 0.045, 0.11, 0.02),
    (0.9, 0.028, 0.07, 0.02),
]


def skin(t, up, side):
    if t < 0.13:
        return HEAD
    # the sac: silver, on the lower half just behind the head
    if t < 0.32 and up < 0.25:
        return SAC
    # the spine, and the ribs hanging from it like the teeth of a comb
    if 0.5 < up < 0.6 and t > 0.13:
        return SPINE
    if -0.45 < up < 0.5 and t > 0.32 and int(t * 34.0) % 2 == 0:
        return SPINE
    return CLEAR


kit.body(STATIONS, 16, skin, rows=35, squareness=2.4)

# the tail: deeply forked
N = 13
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    a = (0.5 - u) * 2.2
    root.append((0.0, 0.02 + math.sin(a) * 0.055, 0.9))
    reach = 0.5 * (1.0 - 0.7 * (1.0 - abs(2.0 * u - 1.0)) ** 1.4)
    rim.append((0.0, 0.02 + math.sin(a) * reach * 1.1, 0.9 + math.cos(a) * reach))
kit.fin(root, rim, lambda u, v: EDGE if v > 0.75 else FIN, rows=4, thick=0.02)

# the anal fin: the long, low one that it swims by, rippling
N = 15
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = -0.5 + 1.32 * u
    root.append((0.0, kit.bottom(z) + 0.02, z))
    rim.append((0.0, kit.bottom(z) - 0.16 * math.sin(math.pi * (0.08 + 0.84 * u)) ** 0.5, z + 0.05))
kit.fin(root, rim, lambda u, v: EDGE if v > 0.7 else FIN, rows=3, thick=0.02, wave=0.03)

# the dorsal fin: one small ray
root = [(0.0, kit.top(z) - 0.02, z) for z in (-0.5, -0.46)]
rim = [(0.0, kit.top(-0.48) + 0.1, -0.42), (0.0, kit.top(-0.46) + 0.09, -0.4)]
kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.015)

for sx in (-1.0, 1.0):
    # a pectoral fin, behind the head
    at = (kit.side(-0.85, sx), -0.05, -0.85)
    root = [(at[0], at[1] + dy, at[2]) for dy in (-0.03, 0.0, 0.03)]
    rim = [(at[0] + sx * 0.12, at[1] - 0.12, at[2] + 0.12), (at[0] + sx * 0.18, at[1] - 0.04, at[2] + 0.2), (at[0] + sx * 0.12, at[1] + 0.04, at[2] + 0.18)]
    kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.015)
    # a barbel: long, forward and out from the upper lip
    base = (sx * 0.04, 0.05, -1.08)
    root = [(base[0], base[1] - 0.008, base[2]), (base[0], base[1] + 0.008, base[2])]
    rim = [(base[0] + sx * 0.22, base[1] + 0.1, base[2] - 0.55), (base[0] + sx * 0.22, base[1] + 0.108, base[2] - 0.55)]
    kit.fin(root, rim, lambda u, v: SPINE, rows=4, thick=0.014, line=0.35)
    kit.eye((kit.side(-0.98, sx, 0.95), 0.05, -0.98), (sx, 0.1, -0.2), 0.05, IRIS)

kit.finish(sys.argv[sys.argv.index("--") + 1])
