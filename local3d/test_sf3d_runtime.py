"""Controle rapide que Stable Fast 3D est importable sans charger ses poids.

Aucun telechargement ; aucun jeton Hugging Face necessaire.
"""
from __future__ import annotations

import pathlib
import sys


def main() -> int:
    repo = pathlib.Path(__file__).resolve().parent / "stable-fast-3d"
    if not (repo / "sf3d" / "system.py").is_file():
        print("ECHEC : code SF3D absent. Relance installer_sf3d.cmd.")
        return 1
    sys.path.insert(0, str(repo))

    try:
        import torch
        import numpy
        import texture_baker
        import uv_unwrapper
        from sf3d.system import SF3D
        import rembg
    except Exception as exc:
        print("ECHEC : import SF3D impossible :", type(exc).__name__, str(exc))
        return 2

    print("PyTorch :", torch.__version__, "(CUDA", torch.version.cuda, ")")
    print("NumPy :", numpy.__version__)
    print("GPU :", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "non detecte")
    print("Modules natifs : texture_baker et uv_unwrapper charges")
    print("Moteur :", SF3D.__name__, "- charge sans poids IA")
    print("MINO SF3D : TEST D IMPORT REUSSI")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
