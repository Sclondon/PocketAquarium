"""Amano shrimp (Caridina multidentata).

What makes it one: bigger than a cherry shrimp and clear as glass, grey-green, with a row of
dark red-brown dots and dashes along each side and a pale line down the back; always busy.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fishkit import Kit, srgb
from shapes import shrimp

kit = Kit("amano_shrimp")
c = srgb(0.62, 0.7, 0.62)
CLEAR, DOT, LINE, LEG = (c[0], c[1], c[2], 0.5), srgb(0.36, 0.14, 0.1), srgb(0.9, 0.9, 0.8), srgb(0.6, 0.66, 0.6)


def shell(t, k):
    if k in (2, 3):
        return LINE
    if k in (0, 5) and int(t * 22.0) % 2 == 0:
        return DOT
    return CLEAR


shrimp(kit, shell, LEG, LEG, srgb(0.05, 0.05, 0.05), size=1.1)
kit.finish(sys.argv[sys.argv.index("--") + 1])
