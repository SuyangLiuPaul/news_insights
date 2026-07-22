"""Generates the News Insights app icon: an open book (the app's own
Bible-verse motif, reused from the auto_stories icon on article cards)
with a small globe emblem at the spine, on a warm amber gradient.

v2 — smoother bezier-curved pages, a diagonal gradient background for
depth, and a soft drop shadow, replacing the flat trapezoid/solid-fill
v1 which read as too plain/blocky for an app icon.

Outputs:
  icon.png            — full icon (background + foreground), 1024x1024
  icon_foreground.png — foreground only, transparent bg, for Android
                        adaptive icons (kept within the ~66% safe zone)

Run: python3 generate_icon.py
"""

from PIL import Image, ImageDraw, ImageFilter

SCALE = 4
SIZE = 1024 * SCALE

# Gradient endpoints — lighter gold top-left to a deeper goldenrod-brown
# bottom-right, both close to the app's amber seed (0xFFB8860B) so the
# icon still reads as "the same amber" at a glance, just with depth.
GRAD_TOP = (214, 160, 40)
GRAD_BOTTOM = (139, 101, 20)
WHITE = (255, 253, 248, 255)  # warm off-white, matches the app's cream surface
SHADOW = (90, 63, 10, 90)


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
    return mask


def diagonal_gradient(size, top_color, bottom_color):
    # Gradients have no fine detail to preserve, so compute at a small
    # resolution (cheap, pure-Python loop) and let LANCZOS upscaling
    # do the smoothing — avoids a multi-million-iteration Python loop
    # at full 4x-supersampled size.
    small = 256
    grad = Image.new("RGB", (small, small))
    px = grad.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * small)
            r = int(top_color[0] + (bottom_color[0] - top_color[0]) * t)
            g = int(top_color[1] + (bottom_color[1] - top_color[1]) * t)
            b = int(top_color[2] + (bottom_color[2] - top_color[2]) * t)
            px[x, y] = (r, g, b)
    return grad.resize((size, size), Image.BICUBIC)


def quad_bezier(p0, p1, p2, steps=40):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts


def open_book_path(cx, half_width, spine_top, spine_bottom, outer_top, outer_bottom, curl):
    """One page's outline, curved (not flat) along both the top and
    bottom edges via quadratic beziers, mirrored for left/right."""

    def page(sign):
        near_x = cx
        far_x = cx + sign * half_width
        # Top edge: spine -> outer, curving slightly upward (page lifts).
        top_ctrl = (cx + sign * half_width * 0.5, spine_top - curl)
        top_edge = quad_bezier((near_x, spine_top), top_ctrl, (far_x, outer_top))
        # Bottom edge: outer -> spine, curving slightly (page droops).
        bottom_ctrl = (cx + sign * half_width * 0.5, spine_bottom + curl * 0.6)
        bottom_edge = quad_bezier((far_x, outer_bottom), bottom_ctrl, (near_x, spine_bottom))
        return top_edge + bottom_edge

    return page(1), page(-1)


def globe(draw, cx, cy, r, color, line_color):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    lw = max(3, int(r * 0.14))
    draw.line([(cx - r, cy), (cx + r, cy)], fill=line_color, width=lw)


def build(foreground_only: bool) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    if not foreground_only:
        radius = int(SIZE * 0.225)
        grad = diagonal_gradient(SIZE, GRAD_TOP, GRAD_BOTTOM).convert("RGBA")
        mask = rounded_mask(SIZE, radius)
        bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        bg.paste(grad, (0, 0), mask)
        img = Image.alpha_composite(img, bg)

    cx = SIZE // 2
    half_width = int(SIZE * 0.315)
    spine_top = int(SIZE * 0.395)
    spine_bottom = int(SIZE * 0.735)
    outer_top = int(SIZE * 0.445)
    outer_bottom = int(SIZE * 0.715)
    curl = SIZE * 0.028

    # Soft drop shadow beneath the book for depth.
    if not foreground_only:
        shadow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow_layer)
        right, left = open_book_path(
            cx, half_width, spine_top + 18, spine_bottom + 18,
            outer_top + 18, outer_bottom + 18, curl,
        )
        sd.polygon(right, fill=SHADOW)
        sd.polygon(left, fill=SHADOW)
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=SIZE * 0.012))
        img = Image.alpha_composite(img, shadow_layer)

    fg_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg_layer)
    right, left = open_book_path(cx, half_width, spine_top, spine_bottom, outer_top, outer_bottom, curl)
    d.polygon(right, fill=WHITE)
    d.polygon(left, fill=WHITE)

    globe_r = int(SIZE * 0.1)
    globe_cy = int(SIZE * 0.275)
    globe(d, cx, globe_cy, globe_r, WHITE, GRAD_BOTTOM)

    img = Image.alpha_composite(img, fg_layer)
    return img


def save_downscaled(img: Image.Image, path: str, out_size: int = 1024):
    img.resize((out_size, out_size), Image.LANCZOS).save(path)


if __name__ == "__main__":
    full = build(foreground_only=False)
    save_downscaled(full, "icon.png")

    fg = build(foreground_only=True)
    save_downscaled(fg, "icon_foreground.png")

    print("Wrote icon.png and icon_foreground.png")
