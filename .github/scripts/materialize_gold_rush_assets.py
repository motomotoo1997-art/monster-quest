#!/usr/bin/env python3
from __future__ import annotations

import base64
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAYLOAD_DIR = ROOT / ".gold-rush-payloads"

ASSETS = {
    "defenses": (
        PAYLOAD_DIR / "defenses.png.b64",
        ROOT / "gold-rush-roguelike/assets/sprites/defenses/defenses.png",
        (960, 320),
    ),
    "boss_views": (
        PAYLOAD_DIR / "boss_views.png.b64",
        ROOT / "gold-rush-roguelike/assets/sprites/enemies/boss_views.png",
        (1024, 213),
    ),
}


def png_size(data: bytes) -> tuple[int, int]:
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("payload is not a PNG")
    if data[12:16] != b"IHDR":
        raise ValueError("PNG has no IHDR at expected offset")
    return struct.unpack(">II", data[16:24])


def main() -> int:
    wrote = 0
    for name, (payload, target, expected_size) in ASSETS.items():
        if not payload.exists():
            print(f"skip {name}: no payload")
            continue
        raw = base64.b64decode("".join(payload.read_text(encoding="ascii").split()), validate=True)
        actual_size = png_size(raw)
        if actual_size != expected_size:
            raise SystemExit(
                f"{name}: expected PNG size {expected_size}, got {actual_size}"
            )
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        print(f"materialized {name}: {target.relative_to(ROOT)} ({len(raw)} bytes)")
        wrote += 1
    print(f"materialized {wrote} Gold Rush payload(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
