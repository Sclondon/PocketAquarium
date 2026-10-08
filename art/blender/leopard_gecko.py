"""Leopard gecko (Eublepharis macularius).

What makes it one: a big triangular head with real eyelids (most geckos have none) and a
smiling mouth; yellow, fading to white underneath, covered with black spots; a fat tail,
ringed with bumps, where it keeps its fat, banded black and white; plain toes with no sticky
pads, so it walks and does not climb glass.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import lizard

kit = Kit("leopard_gecko")
YELLOW, WHITE, BLACK, LILAC, LEG = srgb(0.96, 0.8, 0.26), srgb(0.98, 0.95, 0.86), srgb(0.1, 0.08, 0.08), srgb(0.8, 0.7, 0.82), srgb(0.95, 0.86, 0.6)


def chance(a, b):
    return (abs(a * 127.1 + b * 311.7) * 0.618 * 97.0) % 1.0


def skin(t, up, side):
    if up < -0.4:
        return WHITE
    if t > 0.62:
        # the tail: bands, and spots on the pale ones
        return BLACK if int(t * 22.0) % 3 == 0 else LILAC
    if up > -0.1 and chance(int(t * 40.0), int(up * 6.0) + side * 3) < 0.3:
        return BLACK
    return YELLOW


# head, neck, body, and a tail that swells before it tapers
STATIONS = [(-1.25, 0.05, 0.04, 0.2), (-1.1, 0.2, 0.1, 0.22), (-0.9, 0.24, 0.13, 0.23), (-0.7, 0.14, 0.1, 0.22),
            (-0.4, 0.2, 0.13, 0.2), (0.0, 0.22, 0.14, 0.2), (0.3, 0.14, 0.1, 0.19), (0.55, 0.17, 0.13, 0.17),
            (0.85, 0.15, 0.12, 0.15), (1.15, 0.06, 0.05, 0.1), (1.3, 0.02, 0.02, 0.08)]
lizard(kit, STATIONS, skin, LEG, WHITE, srgb(0.75, 0.72, 0.6), eye=0.075, eye_z=-0.98, shoulders=-0.5, hips=0.2)
kit.finish(sys.argv[sys.argv.index("--") + 1])
