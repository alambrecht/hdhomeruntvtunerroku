#!/usr/bin/env python3
"""Draws the channel icon and splash screens into images/. Needs Pillow and a bold TrueType font.

Same artwork as the Android app's banner: a TV with rabbit-ear antenna on dark blue-gray.
Run from the project root:  python3 tools/make_images.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BACKGROUND = "#1B2633"
LIGHT = "#E8EEF5"
ACCENT = "#3D8BFD"
FONTS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
]
OUT = Path(__file__).resolve().parent.parent / "images"
SUPERSAMPLE = 4


def font(size):
    for path in FONTS:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def draw_tv(d, cx, top, s):
    """TV from the Android banner (viewport x 90..230, y 22..148), scaled by s, centered on cx."""
    def p(x, y):
        return (cx + (x - 160) * s, top + (y - 22) * s)

    width = round(5 * s)
    d.line([p(160, 52), p(132, 22)], fill=LIGHT, width=width)
    d.line([p(160, 52), p(188, 22)], fill=LIGHT, width=width)
    d.rounded_rectangle([p(90, 52), p(230, 148)], radius=10 * s, fill=LIGHT)
    d.rounded_rectangle([p(102, 60), p(218, 134)], radius=4 * s, fill=ACCENT)
    d.polygon([p(150, 84), p(150, 110), p(173, 97)], fill=LIGHT)  # play glyph, as in the adaptive icon


def render(name, width, height, tv_height, text_size, gap):
    w, h = width * SUPERSAMPLE, height * SUPERSAMPLE
    img = Image.new("RGB", (w, h), BACKGROUND)
    d = ImageDraw.Draw(img)

    s = tv_height * SUPERSAMPLE / 126  # artwork is 126 units tall
    f = font(text_size * SUPERSAMPLE)
    text = "HDHR TV"
    tx0, ty0, tx1, ty1 = d.textbbox((0, 0), text, font=f)
    block = 126 * s + gap * SUPERSAMPLE + (ty1 - ty0)
    top = (h - block) / 2

    draw_tv(d, w / 2, top, s)
    d.text(((w - (tx1 - tx0)) / 2 - tx0, top + 126 * s + gap * SUPERSAMPLE - ty0), text, font=f, fill=LIGHT)

    img.resize((width, height), Image.LANCZOS).save(OUT / name, optimize=True)
    print(f"images/{name}  {width}x{height}")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    render("icon_fhd.png", 540, 405, 200, 64, 28)
    render("icon_hd.png", 290, 218, 108, 34, 15)
    render("splash_fhd.png", 1920, 1080, 380, 96, 56)
    render("splash_hd.png", 1280, 720, 253, 64, 37)
