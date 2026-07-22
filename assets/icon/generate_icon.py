"""Generates the News Insights app icon: an open book (the app's own
Bible-verse motif, reused from the auto_stories icon on article cards)
with a small globe emblem at the spine, on the app's amber seed color.
Drawn at 4x supersampling for clean anti-aliased edges, then downscaled.

Outputs:
  icon.png            — full icon (background + foreground), 1024x1024
  icon_foreground.png — foreground only, transparent bg, for Android
                        adaptive icons (kept within the ~66% safe zone)

Run: python3 generate_icon.py
"""

from PIL import Image, ImageDraw

SCALE = 4
SIZE = 1024 * SCALE

SEED = (184, 134, 11, 255)  # 0xFFB8860B — the app's amber seed color
WHITE = (255, 253, 248, 255)  # warm off-white, matches the app's cream surface


def rounded_square(draw, size, fill):
    radius = int(size * 0.225)  # iOS-like squircle proportion
    draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=fill)


def open_book(draw, cx, half_width, top_y, bottom_y, spine_peak, color):
    """Two trapezoid 'pages' meeting at a center spine, peaking upward
    at the spine (classic open-book silhouette). Bold, gap-free
    silhouette — no internal detail — so it still reads at 16px."""
    left = [
        (cx, spine_peak),
        (cx, bottom_y),
        (cx - half_width, bottom_y + int(0.06 * half_width)),
        (cx - half_width, top_y),
    ]
    right = [
        (cx, spine_peak),
        (cx, bottom_y),
        (cx + half_width, bottom_y + int(0.06 * half_width)),
        (cx + half_width, top_y),
    ]
    draw.polygon(left, fill=color)
    draw.polygon(right, fill=color)


def globe_dot(draw, cx, cy, r, color, line_color):
    """Minimal world accent: a solid dot with a single equator band —
    no meridian detail, which is what turned to noise at small sizes."""
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    lw = max(3, int(r * 0.16))
    draw.line([(cx - r, cy), (cx + r, cy)], fill=line_color, width=lw)


def build(foreground_only: bool) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if not foreground_only:
        rounded_square(d, SIZE, SEED)

    cx = SIZE // 2
    book_half_w = int(SIZE * 0.315)
    book_top = int(SIZE * 0.44)
    book_bottom = int(SIZE * 0.735)
    spine_peak = int(SIZE * 0.395)
    open_book(d, cx, book_half_w, book_top, book_bottom, spine_peak, WHITE)

    globe_r = int(SIZE * 0.1)
    globe_cy = int(SIZE * 0.275)
    globe_dot(d, cx, globe_cy, globe_r, WHITE, SEED)

    return img


def save_downscaled(img: Image.Image, path: str, out_size: int = 1024):
    img.resize((out_size, out_size), Image.LANCZOS).save(path)


if __name__ == "__main__":
    full = build(foreground_only=False)
    save_downscaled(full, "icon.png")

    fg = build(foreground_only=True)
    save_downscaled(fg, "icon_foreground.png")

    print("Wrote icon.png and icon_foreground.png")
