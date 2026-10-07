"""Sparkling gourami (Trichopsis pumila).

What makes it a sparkling gourami and has to survive the cartooning:
  a small, slim fish with a pointed head and a mouth turned a little up
  a tail shaped like a spade: rounded, coming to a soft point in the middle
  ventral fins that are single long threads, which it feels its way about with
  a dark stripe along the middle of the flank, with a broken row of dark blotches over it
  rows of blue-green spangles along the body that catch the light (they are what it is
  named for), and more of them on the fins
  fins edged in red, with a thin blue line outside the red
  a bright blue eye
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("sparkling_gourami")

BACK = srgb(0.42, 0.30, 0.18)
SIDE = srgb(0.72, 0.56, 0.36)
BELLY = srgb(0.90, 0.80, 0.62)
STRIPE = srgb(0.20, 0.13, 0.10)
SPANGLE = srgb(0.25, 0.90, 0.85)
FIN = srgb(0.62, 0.50, 0.40)
RED = srgb(0.85, 0.22, 0.16)
BLUE = srgb(0.30, 0.60, 0.98)
IRIS = srgb(0.25, 0.55, 1.0)

STATIONS = [
    (-1.05, 0.03, 0.04, 0.06),
    (-0.95, 0.08, 0.11, 0.04),
    (-0.75, 0.14, 0.21, 0.02),
    (-0.45, 0.17, 0.27, 0.01),
    (-0.1, 0.165, 0.27, 0.01),
    (0.3, 0.13, 0.22, 0.01),
    (0.6, 0.09, 0.16, 0.01),
    (0.8, 0.055, 0.12, 0.01),
]


def chance(a, b):
    """The same answer every time for the same face, between 0 and 1."""
    return (math.sin(a * 127.1 + b * 311.7) * 43758.5453) % 1.0


def skin(t, up, side):
    row = int(t * 30.0)
    if up > 0.78:
        return BACK
    if up < -0.72:
        return BELLY
    if 0.1 < up < 0.3 and t > 0.1:
        return STRIPE
    if 0.5 < up < 0.6 and row % 3 == 0 and t > 0.15:
        return STRIPE
    # spangles, scattered in rows above and below the stripe
    if t > 0.18 and chance(row, round(up * 6.0)) < 0.3:
        return SPANGLE
    return SIDE


kit.body(STATIONS, 16, skin, rows=31)


def webbing(u, v):
    if v > 0.9:
        return BLUE
    if v > 0.72:
        return RED
    return SPANGLE if chance(round(u * 11.0), round(v * 5.0) + 40.0) < 0.22 else FIN


# the tail: a spade
N = 13
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    a = (0.5 - u) * 2.5
    root.append((0.0, 0.01 + math.sin(a) * 0.09, 0.8))
    reach = 0.42 + 0.2 * (1.0 - abs(2.0 * u - 1.0)) ** 2.0
    rim.append((0.0, 0.01 + math.sin(a) * reach * 0.75, 0.8 + math.cos(a) * reach))
kit.fin(root, rim, webbing, rows=5, wave=0.02)

# the dorsal fin: short at the root, tall, and pointed at the back
root = [(0.0, kit.top(z) - 0.03, z) for z in (0.0, 0.1, 0.2, 0.3, 0.4)]
rim = [(0.0, kit.top(0.05) + 0.08, 0.06), (0.0, kit.top(0.15) + 0.22, 0.24), (0.0, kit.top(0.25) + 0.36, 0.46),
       (0.0, kit.top(0.35) + 0.3, 0.62), (0.0, kit.top(0.4) + 0.05, 0.56)]
kit.fin(root, rim, webbing, rows=4)

# the anal fin: long, from the belly to the tail, deepest at the back
N = 9
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = -0.35 + 1.1 * u
    root.append((0.0, kit.bottom(z) + 0.03, z))
    rim.append((0.0, kit.bottom(z) - 0.1 - 0.22 * u ** 0.7, z + 0.06 + 0.1 * u))
kit.fin(root, rim, webbing, rows=4, wave=0.02)

for sx in (-1.0, 1.0):
    # a ventral fin: one long thread
    base = (sx * 0.05, kit.bottom(-0.6) + 0.03, -0.6)
    root = [(base[0], base[1], base[2] - 0.012), (base[0], base[1], base[2] + 0.012)]
    rim = [(base[0] + sx * 0.12, base[1] - 0.5, base[2] + 0.3), (base[0] + sx * 0.12, base[1] - 0.5, base[2] + 0.31)]
    kit.fin(root, rim, lambda u, v: BLUE if v > 0.8 else RED, rows=4, thick=0.016, line=0.4)
    # a pectoral fin: small and clear
    at = (kit.side(-0.68, sx), -0.03, -0.68)
    root = [(at[0], at[1] + dy, at[2]) for dy in (-0.04, 0.0, 0.04)]
    rim = [(at[0] + sx * 0.1, at[1] - 0.1, at[2] + 0.14), (at[0] + sx * 0.15, at[1], at[2] + 0.2), (at[0] + sx * 0.1, at[1] + 0.08, at[2] + 0.16)]
    kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.015)
    kit.eye((kit.side(-0.9, sx, 0.95), kit.top(-0.9) - 0.09, -0.9), (sx, 0.12, -0.2), 0.07, IRIS)

kit.finish(sys.argv[sys.argv.index("--") + 1])
