#!/usr/bin/env python3
"""Generate Apple Watch screenshots matching WatchMainView big-button design.

Layout (VStack, centered):
  - System time "10:09" (top-right)
  - Timer text (teal, bold)
  - "since last" label (white 50%)
  - Big circular teal button with 3D cigarette icon
  - TODAY + count

Watch resolution: 396x484 (Series 9 45mm). Pure black bg per HIG.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

WIDTH, HEIGHT = 396, 484

# Colors — HIG: pure black background blends with Watch bezel
BRONZE_TEXT = (220, 175, 55) # Saturated bronze for timer text
BRONZE = (196, 154, 60)     # Button color matching app icon
BRONZE_GLOW = (196, 154, 60, 26)  # bronze at 10% opacity
BG = (0, 0, 0)              # Pure black per HIG
WHITE = (255, 255, 255)
WHITE_50 = (128, 128, 128)  # .white.opacity(0.5)
WHITE_40 = (102, 102, 102)  # .white.opacity(0.4)
GOLD_BAND = (212, 165, 32)  # Gold band between body and filter

FONT = "/System/Library/Fonts/SFCompact.ttf"

# Button dimensions (in pixels at 2x)
BTN_R = 95      # Main button radius
GLOW_R = 105    # Glow ring radius


def f(size):
    """SF Compact font at given size."""
    try:
        return ImageFont.truetype(FONT, size)
    except Exception:
        return ImageFont.load_default()


def center_text(draw, text, fnt, y, color):
    """Draw centered text, return (x, y, width, height)."""
    bb = draw.textbbox((0, 0), text, font=fnt)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    x = (WIDTH - w) // 2
    draw.text((x, y), text, fill=color, font=fnt)
    return x, y, w, h


def draw_circle(img, cx, cy, radius, color):
    """Draw filled anti-aliased circle using RGBA overlay."""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        fill=color
    )
    img.paste(Image.alpha_composite(
        img.convert("RGBA"), overlay
    ).convert("RGB"))


def draw_cigarette_3d(draw, cx, cy, cig_h):
    """Draw 3D cigarette icon matching CigaretteIcon.swift."""
    cig_tip_w = int(cig_h * 0.8)
    cig_body_w = int(cig_h * 3)
    cig_filter_w = int(cig_h * 1.4)
    cig_w = cig_tip_w + cig_body_w + cig_filter_w
    cig_x = cx - cig_w // 2
    cig_y = cy - cig_h // 2

    def grad_rect(x1, y1, x2, y2, top_c, bot_c):
        h = y2 - y1
        for row in range(h):
            t = row / max(h - 1, 1)
            r = int(top_c[0] + (bot_c[0] - top_c[0]) * t)
            g = int(top_c[1] + (bot_c[1] - top_c[1]) * t)
            b = int(top_c[2] + (bot_c[2] - top_c[2]) * t)
            draw.line([(x1, y1 + row), (x2, y1 + row)], fill=(r, g, b))

    x = cig_x

    # Burning tip — dark ember matching app icon
    grad_rect(x, cig_y, x + cig_tip_w, cig_y + cig_h // 2,
              (200, 100, 30), (139, 48, 16))
    grad_rect(x, cig_y + cig_h // 2, x + cig_tip_w, cig_y + cig_h,
              (139, 48, 16), (80, 20, 5))

    # Yellow hotspot on tip (top portion)
    hot_h = cig_h // 3
    for row in range(hot_h):
        alpha = 0.4 * (1 - row / max(hot_h - 1, 1))
        r = int(255 * alpha + 255 * (1 - alpha))
        g = int(204 * alpha + min(220 - row * 8, 220) * (1 - alpha))
        b = int(0 * alpha + 60 * (1 - alpha))
        draw.line([(x + 2, cig_y + row), (x + cig_tip_w - 2, cig_y + row)],
                  fill=(r, g, b))

    x += cig_tip_w

    # White body — cylindrical shading (highlight top, shadow bottom)
    grad_rect(x, cig_y, x + cig_body_w, cig_y + cig_h,
              (250, 250, 240), (200, 200, 200))
    x += cig_body_w

    # Gold band between body and filter (matching app icon)
    band_w = max(int(cig_h * 0.12), 2)
    draw.rectangle([x - 1, cig_y, x + band_w, cig_y + cig_h],
                   fill=GOLD_BAND)

    # Golden filter — matching app icon bronze tone
    grad_rect(x, cig_y, x + cig_filter_w, cig_y + cig_h,
              (200, 160, 96), (160, 120, 48))
    for i in range(3):
        ly = cig_y + 3 + i * (cig_h // 4)
        draw.line([(x + 2, ly), (x + cig_filter_w - 2, ly)],
                  fill=(160, 110, 60), width=1)


def draw_tip_glow(img, cx, cy, cig_h):
    """Draw orange glow behind the cigarette tip."""
    cig_tip_w = int(cig_h * 0.8)
    cig_w = int(cig_h * 0.8 + cig_h * 3 + cig_h * 1.4)
    tip_cx = cx - cig_w // 2 + cig_tip_w // 2
    glow_r = int(cig_h * 0.9)

    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    # Radial glow approximation with concentric circles
    for i in range(glow_r, 0, -1):
        alpha = int(60 * (i / glow_r))
        d.ellipse(
            [tip_cx - i, cy - i, tip_cx + i, cy + i],
            fill=(255, 107, 0, alpha)
        )
    img_rgba = Image.alpha_composite(img.convert("RGBA"), overlay)
    img.paste(img_rgba.convert("RGB"))


def draw_watch(texts):
    """Render Watch screen with big circular button design."""
    img = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(img)

    f_sys = f(15)
    f_timer = f(28)
    f_since = f(11)
    f_today_lbl = f(11)
    f_today_num = f(28)

    # System time "10:09" — top right
    draw.text((316, 16), "10:09", fill=WHITE, font=f(15))

    # Layout calculation
    cx = WIDTH // 2  # center x
    spacing = 6

    h_timer = draw.textbbox((0, 0), texts["timer"], font=f_timer)[3]
    h_since = draw.textbbox((0, 0), texts["since"], font=f_since)[3]

    # Timer area starts at y=52
    timer_y = 52
    center_text(draw, texts["timer"], f_timer, timer_y, BRONZE_TEXT)
    since_y = timer_y + h_timer + 2
    center_text(draw, texts["since"], f_since, since_y, WHITE_50)

    # Big button center
    btn_cy = 230

    # Glow ring (bronze at 15% on black)
    glow_overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    glow_draw.ellipse(
        [cx - GLOW_R, btn_cy - GLOW_R, cx + GLOW_R, btn_cy + GLOW_R],
        fill=BRONZE_GLOW
    )
    img = Image.alpha_composite(img.convert("RGBA"), glow_overlay).convert("RGB")
    draw = ImageDraw.Draw(img)

    # Dark circle background for spiral button
    draw.ellipse(
        [cx - BTN_R, btn_cy - BTN_R, cx + BTN_R, btn_cy + BTN_R],
        fill=(8, 8, 8)
    )

    # Bronze spiral dots (Archimedean spiral, 2 turns, 18 dots)
    n_dots = 18
    r_start, r_end = 15, 82
    theta_end = 4 * math.pi
    spiral_overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(spiral_overlay)
    for i in range(n_dots):
        theta = i * theta_end / (n_dots - 1)
        r = r_start + (r_end - r_start) * theta / theta_end
        dx = cx + r * math.cos(theta)
        dy = btn_cy + r * math.sin(theta)
        sz = 5 + 5 * i / (n_dots - 1)
        alpha = int(255 * (0.4 + 0.6 * i / (n_dots - 1)))
        sd.ellipse(
            [dx - sz / 2, dy - sz / 2, dx + sz / 2, dy + sz / 2],
            fill=(*BRONZE, alpha)
        )
    img = Image.alpha_composite(img.convert("RGBA"), spiral_overlay).convert("RGB")
    draw = ImageDraw.Draw(img)

    # 3D cigarette icon centered in button
    cig_h = 28
    draw_tip_glow(img, cx, btn_cy, cig_h)
    draw = ImageDraw.Draw(img)  # refresh draw after PIL composite
    draw_cigarette_3d(draw, cx, btn_cy, cig_h)

    # Drop shadow under cigarette (subtle)
    cig_w = int(cig_h * 0.8 + cig_h * 3 + cig_h * 1.4)
    shadow_y = btn_cy + cig_h // 2 + 4
    for i in range(4, 0, -1):
        alpha = 15 * i
        overlay_s = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ds = ImageDraw.Draw(overlay_s)
        ds.ellipse(
            [cx - cig_w // 2 + 5, shadow_y - i,
             cx + cig_w // 2 - 5, shadow_y + i],
            fill=(0, 0, 0, alpha)
        )
        img = Image.alpha_composite(img.convert("RGBA"), overlay_s).convert("RGB")
    draw = ImageDraw.Draw(img)

    # TODAY + count
    today_y = 375
    bb_lbl = draw.textbbox((0, 0), texts["today"], font=f_today_lbl)
    bb_num = draw.textbbox((0, 0), texts["count"], font=f_today_num)
    lbl_w = bb_lbl[2] - bb_lbl[0]
    lbl_h = bb_lbl[3] - bb_lbl[1]
    num_w = bb_num[2] - bb_num[0]
    num_h = bb_num[3] - bb_num[1]
    gap = 6
    total_w = lbl_w + gap + num_w
    sx = (WIDTH - total_w) // 2
    draw.text((sx, today_y + num_h - lbl_h), texts["today"],
              fill=WHITE_40, font=f_today_lbl)
    draw.text((sx + lbl_w + gap, today_y), texts["count"],
              fill=WHITE, font=f_today_num)

    return img


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "watch_screenshots")
    os.makedirs(out_dir, exist_ok=True)

    configs = {
        "watch_en_main.png": {
            "timer": "2h 34m", "since": "since last",
            "today": "TODAY", "count": "5",
        },
        "watch_en_logged.png": {
            "timer": "0m 12s", "since": "since last",
            "today": "TODAY", "count": "6",
        },
        "watch_ru_main.png": {
            "timer": "2ч 34м", "since": "с последней",
            "today": "СЕГОДНЯ", "count": "5",
        },
        "watch_ru_logged.png": {
            "timer": "0м 12с", "since": "с последней",
            "today": "СЕГОДНЯ", "count": "6",
        },
        "watch_uk_main.png": {
            "timer": "2г 34хв", "since": "з останньої",
            "today": "СЬОГОДНІ", "count": "5",
        },
        "watch_uk_logged.png": {
            "timer": "0хв 12с", "since": "з останньої",
            "today": "СЬОГОДНІ", "count": "6",
        },
    }

    for name, texts in configs.items():
        img = draw_watch(texts)
        path = os.path.join(out_dir, name)
        img.save(path, "PNG")
        print(f"Saved: {path}")

    print(f"\nDone: {len(configs)} screenshots.")


if __name__ == "__main__":
    main()
