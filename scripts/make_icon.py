"""Generates the 1024x1024 app icon (no alpha, as App Store requires)."""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # draw at 2x, downsample for smooth edges
img = Image.new("RGB", (S, S))
top, bottom = (30, 43, 58), (74, 108, 140)
px = img.load()
for y in range(S):
    for x in range(S):
        t = (x + y) / (2 * S)
        px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))

def sparkle(cx, cy, r, waist=0.22, points=4, rot=0):
    pts = []
    for i in range(points * 2):
        a = rot + math.pi * i / points - math.pi / 2
        rr = r if i % 2 == 0 else r * waist
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts

glow = Image.new("RGB", (S, S), (0, 0, 0))
ImageDraw.Draw(glow).polygon(sparkle(S * 0.47, S * 0.53, S * 0.36), fill=(120, 95, 50))
glow = glow.filter(ImageFilter.GaussianBlur(S * 0.06))
img = Image.composite(Image.new("RGB", (S, S), (217, 183, 121)), img, glow.convert("L").point(lambda v: int(v * 0.55)))

d = ImageDraw.Draw(img)
d.polygon(sparkle(S * 0.47, S * 0.53, S * 0.33), fill=(217, 183, 121))
d.polygon(sparkle(S * 0.47, S * 0.53, S * 0.20, waist=0.18), fill=(240, 216, 168))
d.polygon(sparkle(S * 0.76, S * 0.25, S * 0.11), fill=(240, 216, 168))
d.polygon(sparkle(S * 0.24, S * 0.22, S * 0.055), fill=(168, 189, 209))

img.resize((1024, 1024), Image.LANCZOS).save("FortiumAIAcademy/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("icon written")
