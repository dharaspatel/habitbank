"""Regenerate the PNG assets used by flutter_launcher_icons + flutter_native_splash.

Requires `cairosvg` and `Pillow`:

    pip install cairosvg pillow

Outputs to ../assets/ relative to this script.
"""

import io
import os

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "logo.svg")
OUT = os.path.join(ROOT, "assets")
os.makedirs(OUT, exist_ok=True)


def write_logo_png() -> None:
    cairosvg.svg2png(url=SRC, write_to=os.path.join(OUT, "logo.png"),
                     output_width=1024)


def write_app_icon() -> None:
    """1024×1024 white-bg square with the logo inset by ~18%."""
    target = 1024
    inset = int(target * 0.18)
    logo_w = target - inset * 2
    buf = io.BytesIO()
    cairosvg.svg2png(url=SRC, write_to=buf, output_width=logo_w)
    buf.seek(0)
    logo = Image.open(buf).convert("RGBA")
    canvas = Image.new("RGBA", (target, target), (255, 255, 255, 255))
    x = (target - logo.width) // 2
    y = (target - logo.height) // 2
    canvas.alpha_composite(logo, (x, y))
    canvas.convert("RGB").save(os.path.join(OUT, "icon.png"), "PNG")


def write_splash() -> None:
    cairosvg.svg2png(url=SRC, write_to=os.path.join(OUT, "splash.png"),
                     output_width=1200)


if __name__ == "__main__":
    write_logo_png()
    write_app_icon()
    write_splash()
    print("Wrote logo.png, icon.png, splash.png to", OUT)
