"""Рисует thumbnail.png (144×144) для каждого модуля: звёзды, планета, подпись SA+.
Запуск: python3 -I tools/make-thumbnails.py   (нужен Pillow)
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SIZE = 144

MODS = {
    "space-age-plus-core": {"color": (120, 170, 255), "label": "CORE", "moon_of": None, "ring": True},
    "space-age-plus-debris": {"color": (150, 150, 160), "label": "DEBRIS", "moon_of": None, "debris": True},
    "space-age-plus-solaris": {"color": (255, 140, 50), "label": "SOLARIS", "moon_of": None, "glow": (255, 200, 80)},
    "space-age-plus-echaris": {"color": (170, 150, 255), "label": "ECHARIS", "moon_of": (90, 80, 70)},
    "space-age-plus-aquara": {"color": (60, 160, 230), "label": "AQUARA", "moon_of": (110, 140, 60)},
    "space-age-plus-nivar": {"color": (200, 230, 255), "label": "NIVAR", "moon_of": (90, 110, 150)},
}


def font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def sphere(draw_img, cx, cy, r, color, light=(-0.45, -0.45)):
    px = draw_img.load()
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            dx, dy = (x - cx) / r, (y - cy) / r
            d2 = dx * dx + dy * dy
            if d2 > 1 or not (0 <= x < SIZE and 0 <= y < SIZE):
                continue
            dz = math.sqrt(1 - d2)
            shade = max(0.15, -(dx * light[0] + dy * light[1]) * 0.6 + dz * 0.7)
            px[x, y] = tuple(min(255, int(c * shade)) for c in color) + (255,)


def make(name, cfg):
    rnd = random.Random(name)
    img = Image.new("RGBA", (SIZE, SIZE), (8, 10, 22, 255))
    draw = ImageDraw.Draw(img)
    for _ in range(90):
        x, y = rnd.randrange(SIZE), rnd.randrange(SIZE)
        b = rnd.randrange(90, 255)
        draw.point((x, y), fill=(b, b, b, 255))
    if cfg.get("glow"):
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(glow).ellipse((22, 18, 122, 118), fill=cfg["glow"] + (170,))
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(14)))
    if cfg.get("moon_of"):
        sphere(img, 112, 28, 26, cfg["moon_of"])
    sphere(img, 70, 68, 38, cfg["color"])
    draw = ImageDraw.Draw(img)
    if cfg.get("ring"):
        draw.ellipse((18, 56, 122, 82), outline=(220, 220, 255, 255), width=2)
    if cfg.get("debris"):
        for _ in range(14):
            x, y = rnd.randrange(10, 134), rnd.randrange(10, 120)
            s = rnd.randrange(2, 6)
            draw.polygon([(x, y), (x + s, y + 1), (x + s - 1, y + s), (x - 1, y + s - 1)], fill=(170, 160, 150, 255))
    draw.rectangle((0, 112, SIZE, SIZE), fill=(0, 0, 0, 170))
    big = font(20)
    draw.text((7, 116), "SA+", font=big, fill=(255, 210, 90, 255))
    x = 7 + draw.textlength("SA+", font=big) + 6
    small = font(12)
    while draw.textlength(cfg["label"], font=small) > SIZE - x - 4 and small.size > 8:
        small = font(small.size - 1)
    draw.text((x, 122), cfg["label"], font=small, fill=(235, 235, 245, 255))
    img.convert("RGB").save(ROOT / name / "thumbnail.png", optimize=True)


for mod_name, mod_cfg in MODS.items():
    make(mod_name, mod_cfg)
    print("written", mod_name + "/thumbnail.png")
