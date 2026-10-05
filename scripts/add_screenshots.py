#!/usr/bin/env python3
"""Copies screenshots into the app, resized so the app stays small.

Usage:  python3 scripts/add_screenshots.py ~/Desktop/claude-shots
Files must be named as in SCREENSHOTS.md (e.g. claude-new-chat.png).
Requires Pillow:  pip3 install pillow
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "FortiumAIAcademy" / "Content" / "Screenshots"
COURSE = ROOT / "FortiumAIAcademy" / "Content" / "course.json"
MAX_PHONE_WIDTH = 900    # tall phone screenshots
MAX_WIDE_WIDTH = 1600    # web / desktop screenshots

expected = {
    card["image"]
    for s in json.loads(COURSE.read_text())["sections"]
    for l in s["lessons"]
    for card in l["cards"]
    if card.get("kind") == "screenshot"
}

if len(sys.argv) != 2:
    sys.exit(__doc__)
src = Path(sys.argv[1]).expanduser()
DEST.mkdir(parents=True, exist_ok=True)

added, unknown = [], []
for path in sorted(src.iterdir()):
    if path.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        continue
    name = path.stem + ".png"
    if name not in expected:
        unknown.append(path.name)
        continue
    image = Image.open(path).convert("RGB")
    limit = MAX_PHONE_WIDTH if image.height > image.width else MAX_WIDE_WIDTH
    if image.width > limit:
        image = image.resize((limit, round(image.height * limit / image.width)), Image.LANCZOS)
    image.save(DEST / name, optimize=True)  # metadata (e.g. location) is not copied
    added.append(f"{name} ({image.width}x{image.height}, {(DEST / name).stat().st_size // 1024} KB)")

print(f"Added {len(added)} screenshot(s):")
for a in added:
    print("  ✓", a)
if unknown:
    print("Skipped (name doesn't match SCREENSHOTS.md):", ", ".join(unknown))
missing = sorted(expected - {p.name for p in DEST.glob("*.png")})
print(f"{len(missing)} still missing." + ("" if not missing else " Next up: " + ", ".join(missing[:5])))
