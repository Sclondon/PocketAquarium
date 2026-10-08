"""Shell-dwelling cichlid (Neolamprologus multifasciatus), the smallest cichlid there is.

What makes it one: a small, slim, big-headed fish; pale tan with many thin dark bars from back
to belly; a pale blue eye; long dorsal fin with a blue-white edge; a rounded tail, barred too.
It lives in an empty snail shell, and keeps house.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import plain_fish

kit = Kit("shell_dweller")
TAN, BAR, PALE, EDGE = srgb(0.82, 0.72, 0.56), srgb(0.36, 0.28, 0.22), srgb(0.95, 0.92, 0.84), srgb(0.7, 0.86, 1.0)


def skin(t, up, side):
    if up < -0.7:
        return PALE
    return BAR if t > 0.2 and int(t * 26.0) % 2 == 0 else TAN


STATIONS = [(-0.95, 0.05, 0.06, 0.0), (-0.82, 0.13, 0.16, 0.0), (-0.55, 0.16, 0.22, 0.0), (-0.1, 0.15, 0.21, 0.0),
            (0.35, 0.11, 0.16, 0.0), (0.65, 0.06, 0.11, 0.0), (0.8, 0.04, 0.09, 0.0)]
plain_fish(kit, STATIONS, skin, TAN, EDGE, srgb(0.6, 0.8, 1.0), eye=0.08, eye_at=-0.76, tail=(0.34, 0.05),
           dorsal=(-0.5, 0.5, 0.17), anal=(0.15, 0.5, 0.14), pectoral=0.17)
kit.finish(sys.argv[sys.argv.index("--") + 1])
