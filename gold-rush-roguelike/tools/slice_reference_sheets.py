#!/usr/bin/env python3
"""Extract transparent sprite islands from concept-art sheets.

The background remover is intentionally conservative: only near-uniform,
low-chroma pixels connected to the image border are made transparent. This
keeps white/gold highlights inside sprites intact.

Usage:
  python tools/slice_reference_sheets.py \
    --input assets/source/sheet.jpeg \
    --output assets/sprites/generated/foo \
    --prefix foo
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter, ImageOps


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--threshold", type=int, default=34,
                        help="RGB distance from sampled border background")
    parser.add_argument("--max-chroma", type=int, default=42,
                        help="Maximum channel spread for a removable bg pixel")
    parser.add_argument("--min-area", type=int, default=900,
                        help="Reject connected foreground islands smaller than this")
    parser.add_argument("--padding", type=int, default=16)
    parser.add_argument("--feather", type=float, default=1.0,
                        help="Alpha feather radius in pixels")
    parser.add_argument("--canvas", type=int, default=0,
                        help="Square output size; 0 chooses one shared family size")
    return parser.parse_args()


def median(values: list[int]) -> int:
    values = sorted(values)
    return values[len(values) // 2]


def sample_border_background(rgb: Image.Image) -> tuple[int, int, int]:
    w, h = rgb.size
    stride = max(1, min(w, h) // 96)
    samples: list[tuple[int, int, int]] = []
    for x in range(0, w, stride):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, h - 1)))
    for y in range(0, h, stride):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((w - 1, y)))
    return tuple(median([p[i] for p in samples]) for i in range(3))  # type: ignore[return-value]


def background_candidate(pixel: tuple[int, int, int], bg: tuple[int, int, int],
                         threshold: int, max_chroma: int) -> bool:
    chroma = max(pixel) - min(pixel)
    distance = max(abs(pixel[i] - bg[i]) for i in range(3))
    return chroma <= max_chroma and distance <= threshold


def edge_connected_background(rgb: Image.Image, threshold: int,
                              max_chroma: int) -> Image.Image:
    w, h = rgb.size
    bg = sample_border_background(rgb)
    mask = Image.new("L", (w, h), 0)
    visited = bytearray(w * h)
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        visited[idx] = 1
        if background_candidate(rgb.getpixel((x, y)), bg, threshold, max_chroma):
            q.append((x, y))
            mask.putpixel((x, y), 255)

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while q:
        x, y = q.popleft()
        if x > 0:
            push(x - 1, y)
        if x + 1 < w:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y + 1 < h:
            push(x, y + 1)
    return mask


def foreground_mask(source: Image.Image, threshold: int, max_chroma: int,
                    feather: float) -> Image.Image:
    rgb = source.convert("RGB")
    bg_mask = edge_connected_background(rgb, threshold, max_chroma)
    alpha = ImageOps.invert(bg_mask)
    if feather > 0:
        softened = alpha.filter(ImageFilter.GaussianBlur(feather))
        # Preserve opaque interiors while softening only the silhouette boundary.
        alpha = ImageChops.lighter(alpha, softened.point(lambda p: 255 if p > 245 else p))
    return alpha


def connected_components(mask: Image.Image, min_area: int) -> list[tuple[int, int, int, int]]:
    binary = mask.point(lambda p: 255 if p >= 64 else 0)
    w, h = binary.size
    px = binary.load()
    seen = bytearray(w * h)
    boxes: list[tuple[int, int, int, int]] = []

    for y0 in range(h):
        for x0 in range(w):
            idx = y0 * w + x0
            if seen[idx] or px[x0, y0] == 0:
                continue
            seen[idx] = 1
            q = deque([(x0, y0)])
            area = 0
            min_x = max_x = x0
            min_y = max_y = y0
            while q:
                x, y = q.popleft()
                area += 1
                min_x, max_x = min(min_x, x), max(max_x, x)
                min_y, max_y = min(min_y, y), max(max_y, y)
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    nidx = ny * w + nx
                    if seen[nidx] or px[nx, ny] == 0:
                        continue
                    seen[nidx] = 1
                    q.append((nx, ny))
            if area >= min_area:
                boxes.append((min_x, min_y, max_x + 1, max_y + 1))

    boxes.sort(key=lambda b: (b[1], b[0]))
    return boxes


def choose_canvas(boxes: list[tuple[int, int, int, int]], padding: int,
                  requested: int) -> int:
    if requested > 0:
        return requested
    max_dim = max(max(x1 - x0, y1 - y0) for x0, y0, x1, y1 in boxes)
    size = max_dim + padding * 2
    # Round up to a multiple of 16 for atlas-friendly frame sizes.
    return ((size + 15) // 16) * 16


def main() -> int:
    args = parse_args()
    source = Image.open(args.input).convert("RGBA")
    alpha = foreground_mask(source, args.threshold, args.max_chroma, args.feather)
    source.putalpha(alpha)
    boxes = connected_components(alpha, args.min_area)
    if not boxes:
        raise SystemExit("No foreground sprites found; adjust --threshold/--min-area")

    args.output.mkdir(parents=True, exist_ok=True)
    canvas_size = choose_canvas(boxes, args.padding, args.canvas)
    metadata: dict[str, object] = {
        "source": str(args.input),
        "prefix": args.prefix,
        "canvas_size": [canvas_size, canvas_size],
        "anchor": "bottom-center",
        "sprites": [],
    }
    preview = Image.new("RGBA", (canvas_size * len(boxes), canvas_size), (0, 0, 0, 0))

    for index, box in enumerate(boxes, 1):
        cut = source.crop(box)
        cut_alpha = cut.getchannel("A")
        tight = cut_alpha.getbbox()
        if tight is None:
            continue
        cut = cut.crop(tight)
        if cut.width > canvas_size - args.padding * 2 or cut.height > canvas_size - args.padding * 2:
            scale = min((canvas_size - args.padding * 2) / cut.width,
                        (canvas_size - args.padding * 2) / cut.height)
            cut = cut.resize((max(1, round(cut.width * scale)),
                              max(1, round(cut.height * scale))), Image.Resampling.LANCZOS)

        frame = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        x = (canvas_size - cut.width) // 2
        y = canvas_size - args.padding - cut.height
        frame.alpha_composite(cut, (x, y))
        name = f"{args.prefix}_{index:02d}.png"
        frame.save(args.output / name)
        preview.alpha_composite(frame, (canvas_size * (index - 1), 0))
        metadata["sprites"].append({
            "file": name,
            "source_box": list(box),
            "anchor_px": [canvas_size // 2, canvas_size - args.padding],
        })

    preview.save(args.output / f"{args.prefix}_contact.png")
    (args.output / f"{args.prefix}.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    print(f"Extracted {len(metadata['sprites'])} sprites to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
