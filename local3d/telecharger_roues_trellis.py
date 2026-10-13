"""Telecharge UNIQUEMENT deux roues natives TRELLIS precompilees pour CPython 3.10.

Origine : Comfy3D_Pre_Builds (MrForExample), build Windows torch2.5.1/cu124.
Verifie que ce sont des archives wheel ZIP et que la taille correspond aux fichiers
inspects sur GitHub. Ne lance aucun code telecharge.
"""
from __future__ import annotations

import pathlib
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent
TARGET = ROOT / "trellis_lab" / "wheels"
BASE = (
    "https://raw.githubusercontent.com/MrForExample/Comfy3D_Pre_Builds/main/"
    "_Build_Wheels/_Wheels_win_py310_torch2.5.1_cu124/"
)
WHEELS = {
    "nvdiffrast-0.3.3-py3-none-any.whl": 143_556,
    "vox2seq-0.0.0-cp310-cp310-win_amd64.whl": 107_378,
}


def verify(filename: pathlib.Path, expected: int) -> None:
    got = filename.stat().st_size
    if got != expected:
        raise ValueError(f"{filename.name} : taille inattendue {got} (attendu {expected})")
    if not zipfile.is_zipfile(filename):
        raise ValueError(f"{filename.name} n'est pas un fichier wheel/ZIP.")
    with zipfile.ZipFile(filename) as zf:
        if zf.testzip() is not None:
            raise ValueError(f"Archive corrompue : {filename}")


def main() -> None:
    TARGET.mkdir(parents=True, exist_ok=True)
    for name, size in WHEELS.items():
        destination = TARGET / name
        if destination.exists():
            verify(destination, size)
            print("Deja telecharge et verifie :", name, flush=True)
            continue

        print("Telechargement depuis GitHub :", name, flush=True)
        tmp = destination.with_suffix(destination.suffix + ".partial")
        try:
            with urllib.request.urlopen(BASE + name, timeout=60) as response:
                with open(tmp, "wb") as out:
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        out.write(chunk)
            verify(tmp, size)
            tmp.replace(destination)
        finally:
            if tmp.exists():
                tmp.unlink()
        print("Wheel valide :", destination, flush=True)

    print("MINO TRELLIS : ROUES NATIVES RECUPEREES ET VERIFIEES")
    print("Ces binaires communautaires seront installes uniquement dans trellis_lab/.venv.")


if __name__ == "__main__":
    main()
