"""Prepare MINO's existing idle artwork for Stable Fast 3D.

Source: assets/mino-idle.webp (original character, full body, transparent).
Output: local3d/inputs/mino_reference.png, centered 1024x1024 RGBA.

No image generation, online service or changes to the original.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "mino-idle.webp"
OUTPUT = ROOT / "local3d" / "inputs" / "mino_reference.png"
CANVAS_SIZE = 1024
SUBJECT_MAX = 870


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(f"Illustration absente : {SOURCE}")
    with Image.open(SOURCE) as opened:
        original = opened.convert("RGBA")

    alpha = original.getchannel("A")
    if alpha.getextrema()[0] == 255:
        raise ValueError(
            "Cette image est opaque : detourage requis avant Stable Fast 3D."
        )
    # Count fine edge pixels but exclude compression noise from the bbox.
    mask = alpha.point(lambda a: 255 if a > 5 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Illustration totalement transparente.")

    cropped = original.crop(bounds)
    factor = min(SUBJECT_MAX / cropped.width, SUBJECT_MAX / cropped.height)
    size = (
        max(1, round(cropped.width * factor)),
        max(1, round(cropped.height * factor)),
    )
    resized = cropped.resize(size, resample=Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    pos = ((CANVAS_SIZE - size[0]) // 2, (CANVAS_SIZE - size[1]) // 2)
    canvas.alpha_composite(resized, dest=pos)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT, format="PNG", optimize=True)

    print("MINO : illustration de reference preparee.")
    print("Source :", SOURCE)
    print("Expression : yeux ouverts, bouche fermee")
    print("Image PNG transparente :", OUTPUT)
    print("Dimensions :", f"{CANVAS_SIZE} x {CANVAS_SIZE}")
    print("Image originale inchangee.")
    print("Etape suivante : generer_sf3d.cmd local3d\\inputs\\mino_reference.png")


if __name__ == "__main__":
    main()
