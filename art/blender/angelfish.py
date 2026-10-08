"""Freshwater angelfish (Pterophyllum scalare).

What makes it one: a body like a disc on edge, taller than it is long once the fins are
counted: a dorsal and an anal fin that sweep back like sails, each longer than the body is
deep; pelvic fins that are two long stiff threads hanging straight down; silver, with four
black bars from top to bottom, the first through the eye; a small pointed mouth.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import fork_tail, one

kit = Kit("angelfish")
SILVER, BAR, BACK, FIN = srgb(0.9, 0.9, 0.84), srgb(0.1, 0.1, 0.12), srgb(0.72, 0.72, 0.66), srgb(0.84, 0.84, 0.74)


def skin(t, up, side):
    if 0.1 < t < 0.17 or 0.36 < t < 0.44 or 0.62 < t < 0.7 or t > 0.93:
        return BAR
    return BACK if up > 0.8 else SILVER


STATIONS = [(-0.75, 0.04, 0.05, 0.0), (-0.65, 0.09, 0.2, 0.0), (-0.4, 0.13, 0.45, 0.0), (-0.05, 0.13, 0.52, 0.0),
            (0.3, 0.1, 0.4, 0.0), (0.5, 0.05, 0.14, 0.0), (0.62, 0.035, 0.1, 0.0)]
kit.body(STATIONS, 16, skin, rows=29, squareness=2.4)
web = lambda u, v: BAR if 0.35 < u < 0.55 else FIN
fork_tail(kit, 0.6, 0.0, 0.09, 0.42, 0.25, lambda u, v: FIN)
# the sails: dorsal up and back, anal down and back
for sign in (1.0, -1.0):
    root, rim = [], []
    for i in range(7):
        u = i / 6.0
        z = -0.3 + 0.75 * u
        edge = kit.top(z) if sign > 0 else kit.bottom(z)
        root.append((0.0, edge - sign * 0.03, z))
        rise = 0.1 + 0.8 * (1.0 - abs(u - 0.35) / 0.65) ** 1.5 if u > 0.05 else 0.05
        rim.append((0.0, edge + sign * rise, z + 0.15 + 0.55 * (1.0 - abs(u - 0.35) / 0.65)))
    kit.fin(root, rim, web, rows=4, thick=0.025)
for sx in (-1.0, 1.0):
    # the pelvic threads
    base = (sx * 0.04, kit.bottom(-0.35) + 0.03, -0.35)
    kit.fin([(base[0], base[1], base[2] - 0.012), (base[0], base[1], base[2] + 0.012)],
            [(base[0] + sx * 0.05, base[1] - 0.8, base[2] + 0.2), (base[0] + sx * 0.05, base[1] - 0.8, base[2] + 0.21)], lambda u, v: FIN, rows=4, thick=0.016, line=0.4)
    at = (kit.side(-0.42, sx), -0.05, -0.42)
    kit.fin([(at[0], at[1] + dy, at[2]) for dy in (-0.04, 0.0, 0.04)],
            [(at[0] + sx * 0.1, at[1] - 0.14, at[2] + 0.16), (at[0] + sx * 0.15, at[1], at[2] + 0.22), (at[0] + sx * 0.1, at[1] + 0.1, at[2] + 0.18)], lambda u, v: FIN, rows=2, thick=0.015)
    kit.eye((kit.side(-0.6, sx, 0.95), 0.07, -0.6), (sx, 0.1, -0.2), 0.065, srgb(0.9, 0.3, 0.15))
kit.finish(sys.argv[sys.argv.index("--") + 1])
