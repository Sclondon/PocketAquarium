"""Marbled hatchetfish (Carnegiella strigata).

What makes it a hatchetfish and has to survive the cartooning:
  the shape of a hatchet's head: a dead straight back, and a chest that drops into a deep,
  sharp keel under the front half, then rises steeply to a slim tail
  pressed very flat from side to side
  long pectoral fins set high, like wings, which it does very nearly fly with
  a small mouth right at the top, turned up, for taking insects off the surface
  marbling: dark wavy bands slanting down and back across a silver flank, and a gold line
  from the eye to the tail along the top
  a forked tail; a small dorsal fin far back; a long anal fin under the tail
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb

kit = Kit("hatchetfish")

BACK = srgb(0.34, 0.30, 0.20)
GOLD = srgb(0.90, 0.74, 0.34)
SILVER = srgb(0.86, 0.87, 0.84)
MARBLE = srgb(0.20, 0.16, 0.14)
FIN = srgb(0.80, 0.82, 0.78)
EDGE = srgb(0.96, 0.96, 0.92)
IRIS = srgb(0.92, 0.90, 0.80)

# the back stays at one height, so the centre drops as the body deepens
TOP = 0.16


def station(z, hw, hh):
    return (z, hw, hh, TOP - hh)


STATIONS = [
    station(-0.95, 0.03, 0.04),
    station(-0.85, 0.07, 0.14),
    station(-0.65, 0.095, 0.33),
    station(-0.40, 0.10, 0.45),
    station(-0.15, 0.095, 0.44),
    station(0.10, 0.08, 0.30),
    station(0.35, 0.06, 0.17),
    station(0.60, 0.04, 0.10),
    station(0.80, 0.03, 0.075),
]


def skin(t, up, side):
    if up > 0.86:
        return BACK
    if up > 0.66:
        return GOLD
    # marbling: bands that slant down and back, broken up so no two are alike
    band = t * 7.0 + (1.0 - up) * 2.2
    if up < 0.55 and (band - math.floor(band)) < 0.38 and math.sin(t * 23.0 + up * 5.0) > -0.55:
        return MARBLE
    return SILVER


kit.body(STATIONS, 16, skin, rows=33, squareness=2.6)

# the tail: forked
N = 11
root, rim = [], []
mid_y = TOP - 0.075
for i in range(N):
    u = i / (N - 1)
    a = (0.5 - u) * 2.1
    root.append((0.0, mid_y + math.sin(a) * 0.06, 0.8))
    reach = 0.42 * (1.0 - 0.6 * (1.0 - abs(2.0 * u - 1.0)) ** 1.3)
    rim.append((0.0, mid_y + math.sin(a) * reach * 1.1, 0.8 + math.cos(a) * reach))
kit.fin(root, rim, lambda u, v: EDGE if v > 0.75 else FIN, rows=3, thick=0.02)

# the dorsal fin: small and far back
root = [(0.0, TOP - 0.02, z) for z in (0.3, 0.4, 0.5)]
rim = [(0.0, TOP + 0.1, 0.42), (0.0, TOP + 0.15, 0.55), (0.0, TOP + 0.04, 0.6)]
kit.fin(root, rim, lambda u, v: FIN, rows=2, thick=0.02)

# the anal fin: long, under the rise to the tail
N = 7
root, rim = [], []
for i in range(N):
    u = i / (N - 1)
    z = 0.05 + 0.65 * u
    root.append((0.0, kit.bottom(z) + 0.02, z))
    rim.append((0.0, kit.bottom(z) - 0.13 * (1.0 - 0.6 * u), z + 0.08))
kit.fin(root, rim, lambda u, v: EDGE if v > 0.7 else FIN, rows=2, thick=0.02)

for sx in (-1.0, 1.0):
    # a pectoral fin: long, high on the side, swept up and back like a wing
    at = (kit.side(-0.62, sx), TOP - 0.14, -0.62)
    root = [(at[0], at[1] + dy, at[2] + dz) for dy, dz in ((-0.04, 0.0), (-0.01, 0.01), (0.02, 0.03))]
    rim = [(at[0] + sx * 0.3, at[1] - 0.1, at[2] + 0.42), (at[0] + sx * 0.42, at[1] + 0.12, at[2] + 0.62), (at[0] + sx * 0.24, at[1] + 0.2, at[2] + 0.5)]
    kit.fin(root, rim, lambda u, v: EDGE if v > 0.8 else FIN, rows=4, thick=0.02)
    kit.eye((kit.side(-0.83, sx, 0.95), TOP - 0.11, -0.83), (sx, 0.15, -0.2), 0.065, IRIS)

kit.finish(sys.argv[sys.argv.index("--") + 1])
