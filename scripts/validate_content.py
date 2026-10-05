#!/usr/bin/env python3
"""Validates FortiumAIAcademy/Content/course.json against what the app expects.

Run after every content edit:  python3 scripts/validate_content.py
"""
import json
import re
import sys
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "FortiumAIAcademy" / "Content" / "course.json"
KINDS = {"text", "tip", "steps", "example", "compare", "tryIt", "warning", "screenshot"}
REQUIRED = {
    "text": ["body"], "tip": ["body"], "warning": ["body"], "steps": ["items"],
    "example": ["prompt"], "compare": ["bad", "good"], "tryIt": ["body"], "screenshot": ["image"],
}
errors = []
missing_shots = []
SHOTS_DIR = PATH.parent / "Screenshots"


def err(where, msg):
    errors.append(f"{where}: {msg}")


course = json.loads(PATH.read_text())
for key in ("version", "title", "sections"):
    if key not in course:
        err("course", f"missing '{key}'")

section_ids, lesson_ids = set(), set()
for s in course.get("sections", []):
    sid = s.get("id", "?")
    for key, typ in (("id", str), ("title", str), ("subtitle", str), ("icon", str),
                     ("color", str), ("isFree", bool), ("lessons", list)):
        if not isinstance(s.get(key), typ):
            err(f"section {sid}", f"'{key}' must be {typ.__name__}")
    if sid in section_ids:
        err(f"section {sid}", "duplicate id")
    section_ids.add(sid)
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", s.get("color", "")):
        err(f"section {sid}", "color must look like #RRGGBB")
    if not s.get("lessons"):
        err(f"section {sid}", "has no lessons")

    for l in s.get("lessons", []):
        lid = f"{sid}/{l.get('id', '?')}"
        for key, typ in (("id", str), ("title", str), ("summary", str), ("minutes", int),
                         ("cards", list), ("quiz", list)):
            if not isinstance(l.get(key), typ):
                err(lid, f"'{key}' must be {typ.__name__}")
        if l.get("id") in lesson_ids:
            err(lid, "duplicate lesson id")
        lesson_ids.add(l.get("id"))
        if not l.get("cards"):
            err(lid, "has no cards")

        for i, c in enumerate(l.get("cards", [])):
            where = f"{lid} card {i + 1}"
            kind = c.get("kind")
            if kind not in KINDS:
                err(where, f"unknown kind '{kind}'")
                continue
            if not c.get("title"):
                err(where, "missing title")
            for field in REQUIRED[kind]:
                if not c.get(field):
                    err(where, f"'{kind}' card needs '{field}'")
            if "items" in c and not all(isinstance(x, str) for x in c["items"]):
                err(where, "items must be strings")
            if kind == "screenshot" and c.get("image"):
                if not (SHOTS_DIR / c["image"]).exists():
                    missing_shots.append(f"{c['image']:34} {lid}")
                for h in c.get("highlights", []):
                    vals = [h.get(k) for k in ("x", "y", "w", "h")]
                    if not all(isinstance(v, (int, float)) and 0 <= v <= 1 for v in vals):
                        err(where, "highlight x/y/w/h must be numbers between 0 and 1")
                    elif h["x"] + h["w"] > 1.001 or h["y"] + h["h"] > 1.001:
                        err(where, "highlight extends past the edge of the image")

        for i, q in enumerate(l.get("quiz", [])):
            where = f"{lid} quiz {i + 1}"
            opts = q.get("options", [])
            if len(opts) < 2:
                err(where, "needs at least 2 options")
            if not isinstance(q.get("answer"), int) or not 0 <= q["answer"] < len(opts):
                err(where, "answer index out of range")
            if len(set(opts)) != len(opts):
                err(where, "duplicate options")
            if not q.get("question") or not q.get("explanation"):
                err(where, "missing question or explanation")

if not any(s.get("isFree") for s in course.get("sections", [])):
    err("course", "at least one section should be free")

if errors:
    print(f"✗ {len(errors)} problem(s) in {PATH.name}:")
    for e in errors:
        print("  -", e)
    sys.exit(1)

if missing_shots:
    print(f"! {len(missing_shots)} screenshot(s) not added yet (hidden in App Store builds):")
    for m in missing_shots:
        print("    ", m)

lessons = sum(len(s["lessons"]) for s in course["sections"])
questions = sum(len(l["quiz"]) for s in course["sections"] for l in s["lessons"])
print(f"✓ {PATH.name} OK — {len(course['sections'])} sections, {lessons} lessons, {questions} quiz questions")
