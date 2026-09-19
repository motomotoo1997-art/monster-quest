#!/usr/bin/env python3
from __future__ import annotations

import base64
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "gold-rush-roguelike"
PAYLOAD_DIR = ROOT / ".gold-rush-payloads"

ASSETS = {
    "prospector": (PROJECT / "assets/sprites/player/prospector.png", (576, 192)),
    "enemies": (PROJECT / "assets/sprites/enemies/enemies.png", (1280, 320)),
    "defenses": (PROJECT / "assets/sprites/defenses/defenses.png", (960, 320)),
    "boss_views": (PROJECT / "assets/sprites/enemies/boss_views.png", (1024, 213)),
}

REPLACEMENTS = {
    "res://assets/sprites/player/prospector.webp": "res://assets/sprites/player/prospector.png",
    "res://assets/sprites/enemies/enemies.webp": "res://assets/sprites/enemies/enemies.png",
    "res://assets/sprites/defenses/defenses.webp": "res://assets/sprites/defenses/defenses.png",
    "res://assets/sprites/enemies/boss_views.webp": "res://assets/sprites/enemies/boss_views.png",
}


def png_size(data: bytes) -> tuple[int, int]:
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("file is not a PNG")
    if data[12:16] != b"IHDR":
        raise ValueError("PNG has no IHDR at expected offset")
    return struct.unpack(">II", data[16:24])


def payload_text(name: str) -> str | None:
    direct = PAYLOAD_DIR / f"{name}.png.b64"
    if direct.exists():
        return direct.read_text(encoding="ascii")
    parts = sorted(PAYLOAD_DIR.glob(f"{name}.png.b64.part*"))
    if not parts:
        return None
    return "".join(part.read_text(encoding="ascii") for part in parts)


def materialize_missing_assets() -> None:
    for name, (target, expected_size) in ASSETS.items():
        if target.exists():
            continue
        encoded = payload_text(name)
        if encoded is None:
            raise SystemExit(f"missing {name}: no PNG and no staged payload")
        raw = base64.b64decode("".join(encoded.split()), validate=True)
        actual_size = png_size(raw)
        if actual_size != expected_size:
            raise SystemExit(f"{name}: expected {expected_size}, got {actual_size}")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        print(f"materialized {name}: {target.relative_to(ROOT)} ({len(raw)} bytes)")


def validate_assets() -> None:
    for name, (target, expected_size) in ASSETS.items():
        if not target.exists():
            raise SystemExit(f"missing PNG atlas: {target.relative_to(ROOT)}")
        raw = target.read_bytes()
        actual_size = png_size(raw)
        if actual_size != expected_size:
            raise SystemExit(f"{name}: expected {expected_size}, got {actual_size}")
        print(f"validated {name}: {actual_size[0]}x{actual_size[1]}, {len(raw)} bytes")


def switch_scenes_to_png() -> int:
    changed = 0
    for scene in sorted((PROJECT / "scenes").rglob("*.tscn")):
        text = scene.read_text(encoding="utf-8")
        updated = text
        for old, new in REPLACEMENTS.items():
            updated = updated.replace(old, new)
        if updated != text:
            scene.write_text(updated, encoding="utf-8", newline="\n")
            print(f"updated scene: {scene.relative_to(ROOT)}")
            changed += 1
    return changed


def remove_corrupt_webp() -> int:
    removed = 0
    for relative in (
        "assets/sprites/player/prospector.webp",
        "assets/sprites/enemies/enemies.webp",
        "assets/sprites/defenses/defenses.webp",
        "assets/sprites/enemies/boss_views.webp",
    ):
        path = PROJECT / relative
        if path.exists():
            path.unlink()
            print(f"removed corrupt atlas: {path.relative_to(ROOT)}")
            removed += 1
    return removed


def main() -> int:
    materialize_missing_assets()
    validate_assets()
    changed = switch_scenes_to_png()
    removed = remove_corrupt_webp()
    print(f"Gold Rush asset migration ready: {changed} scene(s) updated, {removed} WebP removed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
